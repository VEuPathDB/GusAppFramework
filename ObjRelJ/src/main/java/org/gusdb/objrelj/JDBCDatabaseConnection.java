package org.gusdb.objrelj;

import java.math.BigDecimal;
import java.rmi.RemoteException;
import java.sql.Clob;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.Hashtable;
import java.util.Vector;

/**
 * JDBCDatabaseConnection.java
 *
 * An implementation of DatabaseConnectionI that connects directly to a 
 * GUS database instance and uses JDBC to retrieve and submit objects.
 *
 * @author Sharon Diskin, Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class JDBCDatabaseConnection implements DatabaseConnectionI {

    // ------------------------------------------------------------------
    // Static variables
    // ------------------------------------------------------------------

    // JC: temporary
    //
    protected static boolean DEBUG = true;

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    /**
     * JDBC connection
     */
    private Connection conn = null;  // JC: think about using connection pools to support multithreaded apps.

    /**
     * Core.UserInfo.user_id that corresponds to <code>gusUse</code>
     */
    private long gusUserId;

    /**
     * Version of SQLutils compatible with the database referenced by <code>jdbcUrl</code>
     */
    private SQLutilsI sqlUtils;

    // JC: this should go in sqlUtils
    //    private int maxSQLBuffer = 250; //the maximum number of values to put in an SQL IN clause

    // JC: There were a bunch of undocumented global attributes here that were not being used.
    //     It's not clear what all of them are:
    //       -globalNoVersion (turn off versioning completely)
    //       -globalDeleteEvidence (when either row to which the Evidence refers is deleted)
    //       -globalDeleteSimilarity (when either row to which the Similarity refers is deleted)
    //       -readOnly
    //       -defaultCommit (?)
    //       -autocommit (i.e., commit every time submit() is called?)
    //       -getRollback
    
    // ------------------------------------------------------------------
    // Constructors
    // ------------------------------------------------------------------

    /**
     * Constructor.
     *
     * @param utils         SQLutils object that's compatible with the database being used.
     * @param jdbcUrl       JDBC URL for a GUS-compliant database.
     * @param jdbcUser      Username with which to log into the database.
     * @param jdbcPassword  Password for <code>dbUser</code>
     */
    public JDBCDatabaseConnection(SQLutilsI utils, String jdbcUrl, String jdbcUser, String jdbcPassword) {
	this.sqlUtils = utils;

        // Establish the connection that will be used thereafter.
        try {
	    System.out.println("JDBCDatabaseConnection: attempting to get connection, url: " + jdbcUrl + " user: " + jdbcUser + " pass: " + jdbcPassword);
            conn = DriverManager.getConnection(jdbcUrl, jdbcUser, jdbcPassword);
        } 
	catch (Throwable t) { 
	    t.printStackTrace(); 
	}
    }

    // ------------------------------------------------------------------
    // Public methods
    // ------------------------------------------------------------------

    @Override
    public SQLutilsI getSqlUtils() { return sqlUtils; }

    @Override
    public long setCurrentUser(String user, String password) 
    {
	long newUserId = -1;

        try {
            Statement stmt = conn.createStatement();
            System.err.println("JDBCDatabaseConnection: opening connection with user " + user + " and pw " + password);
	    String sql = makeCheckUserSQL(user, password);
            ResultSet res = stmt.executeQuery(sql);
	    
	    // JC: ignores multiple rows
	    //
            while (res.next()) {
                newUserId = res.getLong("user_id");
            }

            res.close();
            stmt.close();
        } 
	catch (SQLException e) {
            e.printStackTrace(); 
        }

	if (newUserId >= 0) {
	    this.gusUserId = newUserId;
	}

        return newUserId;
    }

    @Override
    public long getCurrentUserId() { return this.gusUserId; }

    @Override
    public void retrieveGUSRow(GUSRow gusRow, String clobAtt, Long start, Long end) 
	throws GUSObjectNotUniqueException 
    {
	int numReturned = 0;
	Hashtable<String,CacheRange> specialCases = null;

	GUSTable table = gusRow.getTable();
	String pkName = table.getPrimaryKeyName();
	long pkValue = gusRow.getPrimaryKeyValue();

	if (clobAtt != null) {
	    specialCases = new Hashtable<>();
	    specialCases.put(clobAtt, new CacheRange(start, end, null));
	    System.err.println("retrieveGUSRow: adding " + clobAtt + " start=" + start + " end=" + end + " to specialCases");
	}
	try {

	    // JC: In Oracle it's OK to do a 'select *' even if <code>clobAtt != null</code>
	    // because the CLOB value itself won't be returned, only a pointer to the CLOB
	    // value.  However, I don't think there's any guarantee that other JDBC
	    // implementations will behave the same way.  The safe thing to do is to remove
	    // the column completely from the select statement.
	    //
	    Statement stmt = conn.createStatement();
	    String sql = "select * from " + table.getSchemaName() + "." + table.getTableName()  + 
		" where " + pkName + " = " + pkValue;
	    if (DEBUG) System.err.println("JDBCDatabaseConnection: retrieveGUSRow, sql = '" + sql + "'");

	    ResultSet res = stmt.executeQuery(sql);

	    while (res.next()) {
		++numReturned;
		Hashtable<String,Object> rowHash = createHashtableFromResultSet(res);
		gusRow.setAttributesFromHashtable(rowHash, specialCases);
	    }
	    res.close();
	    stmt.close();
	} catch (Exception e) {
	    System.err.println(e.getMessage());
	    e.printStackTrace(); 
	}
	if (numReturned != 1) {
	    throw new GUSObjectNotUniqueException("Found " + numReturned + " rows in " + table.getSchemaName() + "." + 
						  table.getTableName() + " with id=" + pkValue);
	}
	
    }

    @Override
    public Long getParentPk(GUSRow child, GUSTable parentTable, String childAtt)
	throws RemoteException, GUSNoSuchRelationException, GUSObjectNotUniqueException{
	GUSTable childTable = child.getTable();
	String childSchema = childTable.getSchemaName();
	String childTableName = childTable.getTableName();
	String primaryKeyName = childTable.getPrimaryKeyName();
	Long primaryKeyValue = Long.valueOf(child.getPrimaryKeyValue());
	Long parentPk = null;

	String sql = "select " + childAtt + " from " + childSchema + "." + childTableName + 
	    " where " + primaryKeyName + " = " + primaryKeyValue;

	try {
	    Statement stmt = conn.createStatement();
	    ResultSet res = stmt.executeQuery(sql);
	    while (res.next()){
	        parentPk = Long.valueOf(res.getLong(childAtt));
	    }
	}
	catch (Exception e){
	    System.err.println(e.getMessage());
	    e.printStackTrace();
	}
	return parentPk;
    }

    @Override
    public Vector<Hashtable<String,Object>> retrieveGUSRowsFromQuery(GUSTable table, String query)
    {
	Vector<Hashtable<String,Object>> objs = new Vector<>();

	try {
	    Statement stmt = conn.createStatement();
	    ResultSet res = stmt.executeQuery(query);

	    while(res.next()) {
		GUSRow obj = GUSRow.createGUSRow(table);
		Hashtable<String,Object> rowHash = createHashtableFromResultSet(res);
		objs.add(rowHash);
		//obj.setAttributesFromHashtable(rowHash, null);
		//objs.add(obj);
	    }
	    res.close();
	    stmt.close();
	}
	catch (Exception e) {
	    System.err.println(e.getMessage());
	    e.printStackTrace(); 
	}
        return objs;
    }

    @Override
    public Vector<Hashtable<String,Object>> runSqlQuery(String query) {
	Vector<Hashtable<String,Object>> objs = new Vector<>();
	System.err.println("JDBCDatabaseConnection: runnning sql query " + query);
	try {
	    Statement stmt = conn.createStatement();
	    ResultSet res = stmt.executeQuery(query);
	    ResultSetMetaData rsmd = res.getMetaData();
	    int numCols = rsmd.getColumnCount();
	    String colNames[] = new String[numCols];
	    boolean colIsClob[] = new boolean[numCols];

	    for(int i = 0;i < numCols;++i) {
		colNames[i] = rsmd.getColumnLabel(i+1);
		colIsClob[i] = (rsmd.getColumnType(i+1) == Types.CLOB);
	    }

	    // Returns everything as an Object.  CLOB values require special handling.
	    //dtb: why?
	    while(res.next()) {
		Hashtable<String,Object> h = new Hashtable<>();

		for(int i = 0;i < numCols;++i) {

		    //Clob value
		    //		    if (colIsClob[i]) {
		    //	Clob clobval = res.getClob(i+1);
		    //	if (clobval != null) {
		    //	    long clobLen = clobval.length();
		    //	    String sval = clobval.getSubString(1, (int)clobLen);
		    //	    h.put(colNames[i].toLowerCase(), sval);
		    //	}
		    // } 
		    
		    // All others returned as Objects.  Note numbers are intialized as BigDecimals.
		    // else {
			Object sval = res.getObject(i+1);
			
			if (sval != null) {
			    h.put(colNames[i].toLowerCase(), sval);
			}
			//	    }
		}
		objs.add(h);
	    }
	    res.close();
	    stmt.close();
	}
	catch (Exception e) {
	    System.err.println(e.getMessage());
	    e.printStackTrace(); 
	}
        return objs;
    }

    // JC: work remains to be done here
    // Note: if the submit fails due to an SQL exception we should report the 
    // exception (either directly or as a string) in the SubmitResult object.

    // This transaction is committed immediately after being executed, or rolled
    // back if it fails.

    @Override
    public SubmitResult submitGUSRow(GUSRow obj)
    {

	// This should all be wrapped in a single transaction so can be 
	// rolled back if need be.  Here we assume a simple update/delete.

	Statement stmt = null;
	
	// Insert, update, or delete statement
	//
	String sql = null;
	
	boolean isInsert = false;
	boolean isDelete = false;
	boolean isUpdate = false;
	
	GUSTable table = obj.getTable();
	String owner = table.getSchemaName();
	String tname = table.getTableName();
	String pkName = table.getPrimaryKeyName();
	    
	// New primary key value for an insert
	int nextId = -1;
	    
	// New primary key values for insertnbb
	Vector<Long> pkeys = null;

	try {
	    stmt = conn.createStatement();
	    
	    // Should first check if have write permissions!...SJD
	    
	    // JC: Can do so using getCurrentUserId() although we should probably 
	    // change this method to getCurrentUserInfo() so we can check the group 
	    // permissions too
	    
	    // INSERT
	    //
	    if (obj.getPrimaryKeyValue() == -1) {  
		isInsert = true;

		// Query database for new primary key value
		
		// JC: There are many places where the code could be sped up; 
		// caching the Statement for the following is one example.
		
		
		String idSql = sqlUtils.makeNewIdSQL(table);

		ResultSet rs1 = null;
		
		rs1 = stmt.executeQuery(idSql);

		if (rs1.next()) {
		    nextId = rs1.getInt(1);
		    System.err.println("preparing to submit new entry with id " + nextId);
		}
		
		if (nextId < 0) {
		    SubmitResult badSr = new SubmitResult(false,0,0,0,null); // submit failed
		    badSr.setMessage("Unable to retrieve a valid new primary key to insert this row");
		    return badSr;
		}
		
		sql = sqlUtils.makeInsertSQL(owner, tname, pkName, nextId, obj.getAttributeValues());

	    }    
	    
	    // DELETE
	    //
	    else if (obj.isDeleted()) {
		isDelete = true;
		
		// JC: This is more complicated than you think; if a new object has
		// been marked for deletion then our first task must be to determine
		// *which* object in the database is to be deleted (if a unique object
		// can be determined without the primary key value.)  The simplest 
		// way to do this is to preface the deletion with a call to retrieveGUSRow.
		// However, for now we'll keep it simple and fail if the object to be
		// deleted is new.
		
		if (obj.getPrimaryKeyValue() == -1){
		    return new SubmitResult(false,0,0,0,null);  // submit failed
		}
		
		sql = sqlUtils.makeDeleteSQL(owner, tname, pkName, obj.getPrimaryKeyValue());
	    }
	    
	    // UPDATE
	    //
	    else if (obj.hasChangedAtts()) {
		isUpdate = true;
		
		// JC: As above we'll keep things simple for now by requiring that an
		// object first be retrieved from the database before it can be updated.
		
		// DTB: Not sure how to find an object without using its primary key, without
		//      using object-specific methods.

		if (obj.getPrimaryKeyValue() == -1){
		    SubmitResult badSr = new SubmitResult(false,0,0,0,null);  // submit failed
		    badSr.setMessage("attempting to use an update statement on a newly created object");
		    return badSr;
		}
		//DTB: change signature;
		sql = sqlUtils.makeUpdateSQL(owner, tname, pkName, obj.getPrimaryKeyValue(), obj.getAttributeValues());//CurrentAttVals(), obj.getInitialAttVals());
	    }
	    
	    // NO CHANGE
	    //
	    else {
		SubmitResult sr = new SubmitResult(true,0,0,0,null);  // submit succeeded; no change needed
		sr.setMessage("no changes were made");
		return sr;
	    }
	    
	    if (sql == null) { 
		SubmitResult badSr = new SubmitResult(false,0,0,0,null);  // submit failed
		badSr.setMessage("could not create an SQL statement for submitting this object.");
		return badSr;
	    }
	} catch (Exception sqle) {
	    System.err.println(sqle.getMessage());
	    sqle.printStackTrace();
	    // REMEMBER TO ROLLBACK !! SJD
	    SubmitResult badSr = new SubmitResult(false,0,0,0,null); // submit failed
	    badSr.setMessage("SQLException: " +sqle.getMessage());
	    rollback();
	    return badSr;
	}
	    
	// SJD Still to add...version the row if versionable!!
	// JC: applies to both updates and deletes
	
	boolean success = false;
	int rowsInserted = 0;
	int rowsUpdated = 0;
	int rowsDeleted = 0;
	int rowsAffected = 0;
	
	try {
	    System.out.println("JDBCDatabaseConnection.submitGUSRow: executing " + sql); 
	    rowsAffected += stmt.executeUpdate(sql);
	    System.out.println("JDBCDatabaseConnection.submitGUSRow: affected " + rowsAffected + " rows.");
	    stmt.close();
	    success = true;
	    
	    if (isInsert) {
		rowsInserted += rowsAffected;
		pkeys = new Vector<Long>();
		pkeys.addElement(Long.valueOf(nextId));
	    } else if (isUpdate) {
		rowsUpdated += rowsAffected;
	    } else if (isDelete) {
		rowsDeleted += rowsAffected;
	    }
	    
	    
	    
	} catch (SQLException sqle) {
	    // REMEMBER TO ROLLBACK !! SJD
	    System.err.println(sqle.getMessage());
	    sqle.printStackTrace();
	    SubmitResult badSr = new SubmitResult(false,0,0,0,null); // submit failed
	    badSr.setMessage("SQLException: " + sqle.getMessage());
	    rollback();
	    return badSr;
	}

	return new SubmitResult(success, rowsInserted, rowsUpdated, rowsDeleted, pkeys);
    }
    
    @Override
    public boolean commit(){
	boolean result = false;
	try {
	    
	    Statement commitStmt = conn.createStatement();
	    result = commitStmt.execute(sqlUtils.makeTransactionSQL(false, "commit"));
	}
	catch (Exception e){
	    e.printStackTrace();
	    System.err.println(e.getMessage());
	}
	return result;
    }

	//this is the old way of retrieving parent...will probably want to delete it soon
    @Override
    public GUSRow retrieveParent(GUSRow child, String owner, String tname, String childAtt)
	throws GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	GUSRow parent = null;

	// First check that such a relationship does in fact exist
	
	GUSTable childTable = child.getTable();
	GUSTableRelation rel = childTable.getParentRelation(owner, tname, childAtt);

	if (rel == null) { 
	    throw new GUSNoSuchRelationException("No relation between " + childTable + "." + childAtt + 
						 " and " + owner + "." + tname);
	}

	Object parentPk = child.get_Attribute(childAtt);
	long parentPkLong = -1;

	if (parentPk instanceof Long) {
	    parentPkLong = ((Long)parentPk).longValue();
	} else if (parentPk instanceof Integer) {
	    parentPkLong = ((Integer)parentPk).longValue();
	} else if (parentPk instanceof Short) {
	    parentPkLong = ((Short)parentPk).longValue();
	} else if (parentPk instanceof BigDecimal) {
	    parentPkLong = ((BigDecimal)parentPk).longValue();
	} else {
	    throw new IllegalArgumentException("JDBCDatabaseConnection: primary key of " + child + " = " + parentPk);
	}
	
	if (parentPk != null) {
	    //DTB:  put "childTable" for compiling purposes.  This is likely broken if we decided to keep this method!
	    //	    parent = this.retrieveGUSRow(childTable, parentPkLong, null, null, null);
	}

	return parent;
    }

    // JC: The following code is an optimization and needs some work.  In
    // particular the information about whether the database/user is allowed
    // to create temp. tables (and what SQL should be used for doing so)
    // should probably be encapsulated in the SQLutils object.

    //to fix in this method after nye:
    //better name for temp table, configurable as whether to create temp table (not everyone has privileges)
    //fix query where exception being thrown

    /*
    public GUSRow[] retrieveParentsForAllGUSRows(Vector children, String parentOwner, String parentTable, String childAtt) 
    {
	Hashtable parentHash = new Hashtable();
	GUSRow thisChild = null;
	int childSize = childGUSRows.size();
	GUSRow firstChild = (GUSRow)childObjects.elementAt(0);
	GUSTable firstChildTable = firstChild.getTable();
	String childTableOwner = firstChildTable.getSchemaName();
	String childTableName = firstChildTable.getTableName();
	GUSTable parentTableObject = GUSTable.getTableByName(parentTableOwner, parentTableName);
	String childPKName = firstChildTable.getPrimaryKeyName();
	String parentPKName = parentTableObject.getPrimaryKeyName();
	GUSTableRelation gtr = firstChildTable.getParentRelation(parentTableOwner, parentTableName);
	String childFKName = foreignKey;
	
	try{
	    //set autocommit false so the temptable isn't automatically added to db
	    conn.setAutoCommit(false);
	    	    
	    //Create Temporary table to store the child primary keys and their parents foreign keys
	    String tempTableString = "CREATE GLOBAL TEMPORARY TABLE TempChild (" + 
		childPKName + " INTEGER, " + 
		childFKName + " INTEGER)";
	    
	    System.out.println ("JDBC: submitting query " + tempTableString);
	
	    Statement tempTableStatement = conn.createStatement();
	    tempTableStatement.executeUpdate(tempTableString);
	    
	    tempTableStatement.close();//check if this kills the temp table
	    
	    int childSoFar = 0;
	    String childQuery = null;
	    
	    //Insert into temporary table the appropriate keys; do not exceed size of query buffer (i.e.250 items)
	    while (childSoFar < childSize){
		childQuery = "INSERT INTO TempChild SELECT " + childPKName + ", " + childFKName + " FROM " +
		    childTableOwner + "." + childTableName + " WHERE " + childPKName + " IN (";
		
		thisChild = (GUSRow)childObjects.elementAt(childSoFar);
		childQuery +=   thisChild.get(childPKName) ;
				
		int thisIteration = Math.min(maxSQLBuffer, childSize - childSoFar);
		for (int i = 1; i < thisIteration; i ++){
		    
		    thisChild = (GUSRow)childObjects.elementAt(i + childSoFar);
		    childQuery += ", "  +  thisChild.get(childPKName) ;
		}
		Statement tempInsertStatement = conn.createStatement();
		childQuery += ")";
		System.out.println ("executing query: " + childQuery);
		tempInsertStatement.executeUpdate(childQuery);
		tempInsertStatement.close();
		childSoFar += maxSQLBuffer;
	    }
	    
	    //Join temporary table with parent table to get all parent rows
	    String selectParents = "SELECT * FROM TempChild t INNER JOIN " + parentTableOwner + "." + parentTableName + " p " +
		" ON t." + childFKName + "=" + "p." + parentPKName;
	    
	    try{  
		Statement tempJoinStatement = conn.createStatement();
		System.out.println ("join statement is " + selectParents);
		ResultSet res = tempJoinStatement.executeQuery(selectParents);
		while(res.next()){
		    if (hasSequence){
			
			System.out.println ("JDBC: PARENT HAS SEQUENCE, handling now");
			
			GUSRow gusObj = (GUSRow)createObject(parentTableOwner, parentTableName);
			Clob longSeq = res.getClob("sequence");    
			//			gusObj.setBounds(new Long(1), new Long(longSeq.length())); //for now
			//		gusObj.setCache(longSeq);
			initObject(gusObj, res);
			
			Long pk = new Long(gusObj.getPrimaryKeyValue());
			parentHash.put(pk, gusObj);
		    }
		    else{
			GUSRow gusObj = createObject(parentTableOwner, parentTableName);
			initObject(gusObj, res);

			Long pk = new Long(gusObj.getPrimaryKeyValue());
			parentHash.put(pk, gusObj);
		    }
		}
		res.close();
		tempJoinStatement.close();
	    }catch (Exception e){
		e.printStackTrace(); 
		System.err.println(e.getMessage());
		System.out.println("Dropping temporary table");
		try {
		    Statement drop = conn.createStatement();
		    drop.executeUpdate("Drop Table TempChild");
		    drop.close();
		}
		catch (Exception e1){
		    e1.printStackTrace(); 
		    System.err.println(e1.getMessage());
		}
	    }
	     
	    GUSRow childG;
	    GUSRow parentG;
	    Long myParentsPk;
	    
	    //To each child add the appropriate parent GUSRow
	    for (int i = 0; i < childSize; i ++){
		childG = (GUSRow)childObjects.elementAt(i);
		Object pk = (childG.get(childFKName));
		//NEED TO FIX THIS ONCE LONG/INT ISSUES RESOLVED FOR PK/FK NAMES
		if (pk instanceof Long){
		    myParentsPk = (Long)pk;
		}
		else{
		    myParentsPk = new Long(((Integer)pk).intValue());
		}
		  
		parentG = (GUSRow)parentHash.get(myParentsPk);
		childG.addParent(parentG);
	    }
	    Statement drop = conn.createStatement();
	    drop.executeUpdate("Drop Table TempChild");
	    drop.close();
	    conn.setAutoCommit(true);
	}

	catch (Exception e){
	    e.printStackTrace(); 
	    System.err.println(e.getMessage());
	    System.out.println("Dropping temporary table");
	    try {
		Statement drop = conn.createStatement();
		drop.executeUpdate("Drop Table TempChild");
		drop.close();
	    }
	    catch (Exception e2){
		e2.printStackTrace(); 
		System.err.println(e2.getMessage());
	    }
	}
    }
    */

    // JC: For now, here's a simple (i.e., totally non-optimized) version of the method

    @Override
    public GUSRow[] retrieveParentsForAllGUSRows(Vector children, String parentOwner, String parentTable, String childAtt) 
	throws GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	int nChildren = children.size();
	GUSRow parents[] = new GUSRow[nChildren];

	for (int i = 0;i < nChildren;++i) {
	    GUSRow child = (GUSRow)children.elementAt(i);
	    parents[i] = retrieveParent(child, parentOwner, parentTable, childAtt);
	}

	return parents;
    }

    @Override
    public GUSRow retrieveChild(GUSRow parent, String owner, String tname, String childAtt)
	throws GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	Vector kids = retrieveChildren_aux(parent, owner, tname, childAtt);
	int nKids = (kids == null) ? 0 : kids.size();
	if (nKids != 1) {
	    throw new GUSObjectNotUniqueException("Found " + nKids + " rows in " + owner + "." + tname +
						  " where " + childAtt + " references " + parent);
	}
	return (GUSRow)(kids.elementAt(0));
    }
    
    @Override
    public Vector retrieveChildren(GUSRow parent, String owner, String tname, String childAtt)
	throws GUSNoSuchRelationException
    {
      return retrieveChildren_aux(parent, owner, tname, childAtt);
    }

    @Override
    public void close() {
        try {
            conn.close();
        } catch (SQLException e) {
	    e.printStackTrace(); 
	}
    }

    @Override
    public String getSubmitDate(){
	return sqlUtils.getSubmitDate();
    }
    
    // ------------------------------------------------------------------
    // Protected methods
    // ------------------------------------------------------------------

    /**
     * makeCheckUserSQL: Returns SQL to check if valid user
     */
    protected String makeCheckUserSQL(String user, String password) {
        StringBuffer sql = new StringBuffer("SELECT u.user_id from CORE.USERINFO u\n");
        sql.append("WHERE u.login = '" + user + "'\n");
        sql.append("  AND u.password = '" + password + "'\n");
        return sql.toString();
    }
    
    /**
     * Helper method for retrieveChild and retrieveChildren;
     */
    protected Vector<Hashtable<String,Object>> retrieveChildren_aux(GUSRow parent, String owner, String tname, String childAtt)
	throws GUSNoSuchRelationException
    {
	// First check that such a relationship does in fact exist

	GUSTable parentTable = parent.getTable();
	GUSTableRelation rel = parentTable.getChildRelation(owner, tname, childAtt);

	if (rel == null) { 
	    throw new GUSNoSuchRelationException("No relation between " + parentTable + 
						 " and " + owner + "." + tname + "." + childAtt);
	}

	long parentPkVal = parent.getPrimaryKeyValue();
	String sql = "select * from " + owner + "." + tname + " where " + childAtt + " = " + parentPkVal;
	//DTB:  put "parentTable" for compiling purposes.  This is likely broken if we decided to keep this method!
	Vector<Hashtable<String,Object>> kids = retrieveGUSRowsFromQuery(parentTable, sql);
	return kids;
    }

    // JC: The following method probably needs adding to the public interface
    // so that the GUSServer can support the behavior documented when retrieveGUSRow
    // is called on a cached object, but the clob range is different from what
    // has been cached.

    /**
     * Generic method to retrieve a subsequence of a CLOB-valued column as
     * a String.  This is probably not the most efficient way to handle CLOB 
     * values, particularly if we are going to later convert them into 
     * BioJava SymbolLists (i.e., for DNA and protein sequences).  However,
     * it's no worse than what we had here before, and is no longer specific
     * to the DoTS.NASequence table
     */
    protected String getSubStringFromClob(GUSTable table, long pk, String clobAtt, Long start, Long end) 
	throws GUSObjectNotUniqueException
    {
	String pkName = table.getPrimaryKeyName();
	int numRows = 0;
	String subseq = null;

	try {
	    Statement stmt = conn.createStatement();
	    String sql = "select " + clobAtt + " from " + table.getSchemaName() + "." + table.getTableName() + " where " + pkName + " = " + pk;
	    if (DEBUG) System.err.println("JDBCDatabaseConnection: getSubStringFromClob, sql = '" + sql + "'");
	    ResultSet res = stmt.executeQuery(sql);

	    while (res.next()) {
		++numRows;
		Clob clobval = res.getClob(clobAtt);
		if (DEBUG) System.err.println("JDBCDatabaseConnection: getSubStringFromClob, clob = " + clobval);

		if (clobval != null) {
		    long clobLen = clobval.length();
		    long clobStart = (start == null) ? 1 : start.longValue();
		    long clobEnd = (end == null) ? clobLen : end.longValue();

		    // JC: Does this coercion mean that the method will fail if we request
		    // too much sequence?  Perhaps this method will have to be rewritten to
		    // return a stream or some other datatype instead of a String.
		    //
		    int subseqLen = (int)(clobEnd - clobStart + 1);
		    subseq = clobval.getSubString(clobStart, subseqLen);
		}
	    }
	    res.close();
	    stmt.close();
	} 
	catch (Exception e) {
	    e.getMessage();
	    e.printStackTrace(); 
	}

	if (numRows != 1) {
	    throw new GUSObjectNotUniqueException("Found " + numRows + " rows in " + table.getSchemaName() +"." + table.getTableName() + 
						  " with " + pkName + "=" + pk);
	}

	return subseq;
    }

    // ------------------------------------------------------------------
    // Private methods
    // ------------------------------------------------------------------

    /**
     * Rolls back all transactions since the last 'commit'.
     */
    private void rollback(){
	
	try{
	    Statement stmt = conn.createStatement();
	    stmt.execute(sqlUtils.makeTransactionSQL(false, "rollback"));
	}
	catch (SQLException e){
	    System.err.println(e.getMessage());
	    e.printStackTrace();
	}
    }


    /**
     * Given a ResultSet, return a Hashtable representing its current row (that is, the row to 
     * which the ResultSet's 'cursor' is pointing.)  The keys of the Hashtable are the column
     * names of the ResultSet's table (all lower case) and the value of each key is the value 
     * in the row for the column.
     */
    private Hashtable<String,Object> createHashtableFromResultSet(ResultSet rs){

	Hashtable<String,Object> rowHash = new Hashtable<>();
	
	try {
	    ResultSetMetaData rsmd = rs.getMetaData();
	    for (int i = 1; i <= rsmd.getColumnCount(); i++){
		String columnName = rsmd.getColumnName(i);

		Object value = rs.getObject(columnName);
		if (value != null){

		    rowHash.put(columnName.toLowerCase(), value);
		}
	    }
	}
	catch (Exception e){
	    System.err.println(e.getMessage());
	    e.printStackTrace();
	}
	return rowHash;
    }



    // JC: This might be a candidate for a "hand_edited" method in the BLATAlignment object
    //     or it could just go in the application itself.
    /*
    public static String makeBlatAlignmentQuery(Long targetPk, Long start, Long end) {
	String query = "select * from DoTS.BLATAlignment " +
	    "where target_na_sequence_id = " + targetPk.toString() + 
	    " and target_start <= " + end.toString() + 
	    " and target_end >= " + start.toString();
	return query;
    }
    */

    // JC: This BioJava-dependent code should also be moved elsewhere, perhaps 
    // into the hand_edited code

    // import org.biojava.bio.*;
    // import org.biojava.bio.seq.*;
    // import org.biojava.bio.seq.io.*;
    // import org.biojava.bio.symbol.*;

    //	SymbolList dna = null;
    //	FiniteAlphabet dnaAlphabet = DNATools.getDNA();
    //  dna = DNATools.createDNA(sequence.getSubString((long)1, (int)sequence.length()));
    
} //JDBCDatabaseConnection

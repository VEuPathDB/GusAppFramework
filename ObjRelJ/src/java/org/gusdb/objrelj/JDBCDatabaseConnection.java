package org.gusdb.objrelj;

import java.lang.reflect.*;
import java.math.*;
import java.io.*;
import java.util.*;
import java.rmi.*;
import java.rmi.server.*;
import java.sql.*;

import oracle.jdbc.driver.*;
import oracle.sql.*; 

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

    private String jdbcUrl;
    private String jdbcUser;
    private String jdbcPassword;

    /**
     * Username of current GUS user
     */
    private String gusUser;

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
	this.jdbcUrl = jdbcUrl;
	this.jdbcUser = jdbcUser;
	this.jdbcPassword = jdbcPassword;

        // Establish the connection that will be used thereafter.
        try {
            conn = DriverManager.getConnection(jdbcUrl, jdbcUser, jdbcPassword);
        } 
	catch (Throwable t) { 
	    t.printStackTrace(); 
	}
    }

    // ------------------------------------------------------------------
    // Public methods
    // ------------------------------------------------------------------

    public SQLutilsI getSqlUtils() { return sqlUtils; }

    public long setCurrentUser(String user, String password) 
    {
	long newUserId = -1;

        try {
            Statement stmt = conn.createStatement();
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

    public long getCurrentUserId() { return this.gusUserId; }

    public GUSRow retrieveObject(String owner, String tname, long pk, String clobAtt, Long start, Long end) 
	throws GUSObjectNotUniqueException 
    {
	GUSTable table = GUSTable.getTableByName(owner, tname);
	String pkName = table.getPrimaryKeyName();
	GUSRow obj = null;
	int numReturned = 0;
	
	try {

	    // JC: In Oracle it's OK to do a 'select *' even if <code>clobAtt != null</code>
	    // because the CLOB value itself won't be returned, only a pointer to the CLOB
	    // value.  However, I don't think there's any guarantee that other JDBC
	    // implementations will behave the same way.  The safe thing to do is to remove
	    // the column completely from the select statement.
	    //
	    Statement stmt = conn.createStatement();
	    String sql = "select * from " + owner + "." + table  + " where " + pkName + " = " + pk;
	    ResultSet res = stmt.executeQuery(sql);

	    while (res.next()) {
		++numReturned;
		obj = GUSRow.createObject(owner, tname);
		obj.setAttributesFromResultSet(res);
	    }
	    
	    res.close();
	    stmt.close();
	} catch (Exception e) {
	    System.err.println(e.getMessage());
	    e.printStackTrace(); 
	}

	if (numReturned != 1) {
	    throw new GUSObjectNotUniqueException("Found " + numReturned + " rows in " + owner + "." + 
						  tname + " with id=" + pk);
	}

	// Store cached CLOB value in the object
	//
	if (clobAtt != null) {
	    String clobSubSeq = getSubStringFromClob(owner, tname, pk, clobAtt, start, end);

	    // JC: need generic CLOB caching functionality in the GUSRow subclasses
	    
	}
	
        return obj;
    }

    public Vector retrieveObjectsFromQuery(String owner, String tname, String query)
    {
	Vector objs = new Vector();

	System.err.println("query = " + query);

	try {
	    Statement stmt = conn.createStatement();
	    ResultSet res = stmt.executeQuery(query);

	    while(res.next()) {
		GUSRow obj = GUSRow.createObject(owner, tname);
		System.err.println("created object = " + obj);
		obj.setAttributesFromResultSet(res);
		System.err.println("after setAtts = " + obj);
		objs.add(obj);
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

    public SubmitResult submitObject(GUSRow obj)
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
	String owner = table.getOwnerName();
	String tname = table.getTableName();
	String pkName = table.getPrimaryKeyName();
	    
	// New primary key value for an insert
	int nextId = -1;
	    
	// New primary key values for insert
	Vector pkeys = null;

	try {
	    stmt = conn.createStatement();
	    
	    // Should first check if have write permissions!...SJD
	    
	    // JC: Can do so using getCurrentUserId() although we should probably 
	    // change this method to getCurrentUserInfo() so we can check the group 
	    // permissions too
	    
	    // INSERT
	    //
	    if (obj.isNew() || !obj.isDeleted()) {
		isInsert = true;
		
		// Query database for new primary key value
		
		// JC: There are many places where the code could be sped up; 
		// caching the Statement for the following is one example.
		
		String idSql = sqlUtils.makeNewIdSQL(table);
		ResultSet rs1 = null;
		
		rs1 = stmt.executeQuery(idSql);
		if (rs1.next()) {
		    nextId = rs1.getInt(1);
		}
	    
		if (nextId < 0) {
		    return new SubmitResult(false,0,0,0,null); // submit failed
		}
		
		sql = sqlUtils.makeInsertSQL(owner, tname, pkName, nextId, obj.getCurrentAttVals());
	    }    
	    
	    // DELETE
	    //
	    else if (obj.isDeleted()) {
		isDelete = true;
		
		// JC: This is more complicated than you think; if a new object has
		// been marked for deletion then our first task must be to determine
		// *which* object in the database is to be deleted (if a unique object
		// can be determined without the primary key value.)  The simplest 
		// way to do this is to preface the deletion with a call to retrieveObject.
		// However, for now we'll keep it simple and fail if the object to be
		// deleted is new.
		
		if (obj.isNew()) {
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
		
		if (obj.isNew()) {
		    return new SubmitResult(false,0,0,0,null);  // submit failed
		}
		
		sql = sqlUtils.makeUpdateSQL(owner, tname, pkName, obj.getPrimaryKeyValue(), obj.getCurrentAttVals(), obj.getInitialAttVals());
	    }
	    
	    // NO CHANGE
	    //
	    else {
		return new SubmitResult(true,0,0,0,null);  // submit succeeded; no change needed
	    }
	    
	    if (sql == null) { 
		return new SubmitResult(false,0,0,0,null);  // submit failed
	    }
	} catch (SQLException sqle) {
	    // REMEMBER TO ROLLBACK !! SJD
	    return new SubmitResult(false,0,0,0,null); // submit failed
	}
	    
	// SJD Still to add...version the row if versionable!!
	// JC: applies to both updates and deletes
	
	boolean success = false;
	int rowsInserted = 0;
	int rowsUpdated = 0;
	int rowsDeleted = 0;
	int rowsAffected = 0;
	
	try {
	    rowsAffected += stmt.executeUpdate(sql);
	    stmt.close();
	    success = true;
	    
	    if (isInsert) {
		rowsInserted += rowsAffected;
		pkeys = new Vector();
		pkeys.addElement(new Long(nextId));
	    } else if (isUpdate) {
		rowsUpdated += rowsAffected;
	    } else if (isDelete) {
		rowsDeleted += rowsAffected;
	    }
	    
	} catch (SQLException sqle) {
	    // REMEMBER TO ROLLBACK !! SJD
	    return new SubmitResult(false,0,0,0,null); // submit failed
	}

	return new SubmitResult(success, rowsInserted, rowsUpdated, rowsDeleted, pkeys);
    }

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

	Long parentPk = (Long)child.get(childAtt);
	
	if (parentPk != null) {
	    parent = this.retrieveObject(owner, tname, parentPk.longValue(), null, null, null);
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
    public GUSRow[] retrieveParentsForAllObjects(Vector children, String parentOwner, String parentTable, String childAtt) 
    {
	Hashtable parentHash = new Hashtable();
	GUSRow thisChild = null;
	int childSize = childObjects.size();
	GUSRow firstChild = (GUSRow)childObjects.elementAt(0);
	GUSTable firstChildTable = firstChild.getTable();
	String childTableOwner = firstChildTable.getOwnerName();
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

    public GUSRow[] retrieveParentsForAllObjects(Vector children, String parentOwner, String parentTable, String childAtt) 
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
    
    public Vector retrieveChildren(GUSRow parent, String owner, String tname, String childAtt)
	throws GUSNoSuchRelationException
    {
	try {
	    return retrieveChildren_aux(parent, owner, tname, childAtt);
	} catch (GUSObjectNotUniqueException nue) {
	    
	    // This should *never* happen; retrieveChildren_aux should only throw
	    // an exception if told to expect a unique
	    return null;
	}
    }

    public void close() {
        try {
            conn.close();
        } catch (SQLException e) {
	    e.printStackTrace(); 
	}
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
    protected Vector retrieveChildren_aux(GUSRow parent, String owner, String tname, String childAtt)
	throws GUSNoSuchRelationException, GUSObjectNotUniqueException
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
	Vector kids = retrieveObjectsFromQuery(owner, tname, sql);
	return kids;
    }

    // JC: The following method probably needs adding to the public interface
    // so that the GUSServer can support the behavior documented when retrieveObject
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
    protected String getSubStringFromClob(String owner, String tname, long pk, String clobAtt, Long start, Long end) 
	throws GUSObjectNotUniqueException
    {
	GUSTable table = GUSTable.getTableByName(owner, tname);
	String pkName = table.getPrimaryKeyName();
	int numRows = 0;
	String subseq = null;

	try {
	    Statement stmt = conn.createStatement();
	    String sql = "select " + clobAtt + " from " + owner + "." + tname + " where " + pkName + " = " + pk;
	    ResultSet res = stmt.executeQuery(sql);

	    while (res.next()) {
		++numRows;
		Clob clobval = res.getClob(clobAtt);

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
	    throw new GUSObjectNotUniqueException("Found " + numRows + " rows in " + owner +"." + tname + 
						  " with " + pkName + "=" + pk);
	}

	return subseq;
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




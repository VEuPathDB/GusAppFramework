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

import org.biojava.bio.*;
import org.biojava.bio.seq.*;
import org.biojava.bio.seq.io.*;
import org.biojava.bio.symbol.*;

/**
 * JDBCDatabaseConnection.java
 *
 * An implementation of DatabaseConnectionI that connects directly to a GUS
 * database instance and uses JDBC to retrieve and submit objects.
 *
 * @author Sharon Diskin, Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class JDBCDatabaseConnection implements DatabaseConnectionI {

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    /**
     * JDBC Connection.
     */
    private Connection conn = null;    // JC: think about using connection pools to support multithreaded apps.

    /*
     * User data
     */
    private String user;                     
    private String password;
    
    /**
     * Cache
     */
    private GUSObjectCache cache;

    /**
     * Default values for standard attributes (e.g., group_id, user_id, etc.)
     */ 
    private Hashtable defaults;

    /**
     * Version of SQLutils appropriate for the current database.
     */
    private SQLutilsI sqlUtils;

    // JC: this should go in sqlUtils
    private int maxSQLBuffer = 250; //the maximum number of values to put in an SQL IN clause

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
     * @param jdbcUrl
     * @param dbUser
     * @param dbPassword
     */
    public GUS_JDBC_Server(String jdbcUrl, String dbUser, String dbPassword) {
        this.defaults = new Hashtable();
        this.setDefaultValues();
	this.cache = new GUSObjectCache();
	this.sqlUtils = new OracleSQLutils();  // JC: oracle-specific

        // Establish the connection that will be used thereafter.
        try {
	    // JC: oracle-specific

            // Load the Oracle JDBC driver
            DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver());
            conn = DriverManager.getConnection(jdbcUrl, dbUser, dbPassword);
        } 
	catch (Throwable t) { 
	    t.printStackTrace(); 
	}
    }

    // ------------------------------------------------------------------
    // Public methods
    // ------------------------------------------------------------------

    /**
     * Close the underlying JDBC connection and free any resources
     * associated with this object.
     */
    public void closeConnection() {
        try {
            conn.close();
            if (cache != null){ cache.clear(); }
	    this.defaults = null;
	    this.cache = null;
        } catch (SQLException e) {
	    e.printStackTrace(); 
	}
    }

    /**
     * Checks the GUS_JDBC object cache for the object with the given
     * primary key and returns it; returns null if object is not in cache
     */
    public GUSRow checkCache(String c_owner, String c_table, long key){
	
 	System.out.println ("checking cache for " + c_owner + "." + c_table + "_" + key);
	GUSRow newObj = null;
	try {
	    newObj = cache.get(c_owner, c_table, key);
	}
	catch (Exception e){
	    e.printStackTrace();
	    System.out.println(e.getMessage());
	}
	if (newObj == null){ System.out.println ("this object was not in the cache"); }
	return newObj;
    }

    /**
     * createObject: Creates and returns a new instance of the specified class.
     */
    public GUSRow createObject(String table_owner, String table_name) 
        throws ClassNotFoundException, 
               InstantiationException, IllegalAccessException, NullPointerException,
	       NoSuchMethodException, InvocationTargetException
    {
        Class c = Class.forName(GUSRow.MODEL_PACKAGE + "." + table_owner + "." + table_name);
	
	GUSRow newObj = (GUSRow)c.newInstance();
	return (GUSRow)newObj;
    }

    
    public void initObject(GUSRow gusObj, ResultSet res) {

	try{
	    gusObj.setAttributesFromResultSet(res);
	}
	catch (Exception e){
	    System.out.println (e.getMessage());
	    e.printStackTrace();
	}
    }
	
    /**
     * submitObject: Submits the given object to the database. If object has 
     * any children, will submit them as well (if they are updated...)
     */
  


    public int checkValidUser(String username, String password){
        int userid = 0;
        try{
            Statement stmt = conn.createStatement();
            String sql = makeCheckUserSQL(username, password);
            ResultSet res = stmt.executeQuery(sql);
            while(res.next()){
                userid = res.getInt("user_id");
            }
            res.close();
            stmt.close();
        }catch (SQLException e){
            // throw invalid user exception...
            e.printStackTrace(); 
        }
     
        return userid;
    }

    public GUSRow getObject(String table_owner, String table_name, long pk) {

        // check the cache (once it is implemented)
        // if not in cache, retrieve from db - here just always retrieves from DB...
	GUSRow newObj = checkCache(table_owner, table_name, pk);
	if (newObj == null){

	    GUSTable tempTable = GUSTable.getTableByName(table_owner, table_name);
	    String pk_name = tempTable.getPrimaryKeyName();
	    newObj = getGeneralObject (table_owner, table_name, pk_name, pk); 
	}
	
	//put in cache
	
        return newObj;
    }
    
    public SymbolList getSubSequence(Long start, Long end, long pk) {

	
	String table_owner = "DoTS";
	String table_name = "NASequence";
	GUSTable tempTable = GUSTable.getTableByName(table_owner, table_name);
	String pk_name = tempTable.getPrimaryKeyName();
	SymbolList dna = null;
	FiniteAlphabet dnaAlphabet = DNATools.getDNA();
	
	try{
	    Statement stmt = conn.createStatement();
	    String sql = "select * from " + table_owner + "." + table_name  + " where " + pk_name + " = " + pk;
	    
	    System.out.println("JDBC:  Executing " + sql);
	    ResultSet res = stmt.executeQuery(sql);
	    System.out.println ("query executed");
	    while(res.next()){
		
		Clob sequence = res.getClob("sequence");		    
		if ((start == null) && (end == null)){
		    //retrieve whole sequence
		    dna = DNATools.createDNA(sequence.getSubString((long)1, (int)sequence.length()));
		}
		else {
		    System.out.println ("retrieving specified subsequence");
		    dna = DNATools.createDNA(sequence.getSubString(start.longValue(), 
								   (int) (end.longValue() - start.longValue() + 1)));
		    //retrieve specified part of subsequence
		}
	    }
	    res.close();
	    stmt.close();
	}catch (Exception e){
	    e.getMessage();
	    e.printStackTrace(); 
	}
	return dna;
    }
 
    /**
     *Returns a vector of GUSRows retrieve by the given query
     */
    Vector getGusRowsFromQuery(String query, String table_owner, String table_name)
    {
	//dtb: for now passing in owner and name but maybe later figure out a way to avoid this?
	//might make method more flexible
	
	Vector gusObjs = new Vector();
	try{
	    Statement stmt = conn.createStatement();
	    ResultSet res = stmt.executeQuery(query);
	    while(res.next()){
		
		GUSRow gusObj = createObject(table_owner, table_name);
		initObject(gusObj, res);
		gusObjs.add(gusObj);
	    }
	    res.close();
	    stmt.close();
	}catch (Exception e){
	    e.printStackTrace(); 
	    System.err.println(e.getMessage());
	}
	// put the object in the cache!!
        return gusObjs;
    }

    
    //to fix in this method after nye:
    //better name for temp table, configurable as whether to create temp table (not everyone has privileges)
    //fix query where exception being thrown

    //given a vector of gusRows, gets the specified parent GUSRow for each child in the vector and adds
    //it to the the child's 'parent' table
    public void getParentsForAllObjects(Vector childObjects, String parentTableOwner, String parentTableName, String foreignKey, 
					boolean hasSequence) {
	
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
	    	    
	    /*Statement dropone = conn.createStatement();
	      dropone.executeUpdate("Drop TABLE TempChild");
	      dropone.close();
	    */
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
  

    /**
     *Retrieve the given NASequence.  
     * @param cacheSequence set to true to cache the raw sequence data 
     *                      in the NASequence GUSRow object
     * @param subSeqStart   If not null, the starting position of the sequence to retrieve
     *                      If null, retrieve the whole sequence
     * @param subSeqEnd     If not null, the end position of the sequence to retrieve
     */
    
    public GUSRow getGUSRow(String table_owner, String table_name, long pk, boolean cacheSequence, Long subSeqStart, Long subSeqEnd) {
	//for now does all the work by itself
	//later try to use getGeneralObject?
	
	GUSRow newSeq = (GUSRow)checkCache(table_owner, table_name, pk);
	if (newSeq == null){
	    GUSTable tempTable = GUSTable.getTableByName(table_owner, table_name);
	    String pk_name = tempTable.getPrimaryKeyName();
	    
	    try{
		Statement stmt = conn.createStatement();
		
		String sql = "select * from " + table_owner + "." + table_name  + " where " + pk_name + " = " + pk; 
		
		System.out.println("JDBC:  Executing " + sql);
		ResultSet res = stmt.executeQuery(sql);
		
		while(res.next()){

		    newSeq = (GUSRow)createObject(table_owner, table_name);
		    
		    Clob longSeq = res.getClob("sequence");    
		    if ((subSeqStart == null) && (subSeqEnd == null)){

			if (cacheSequence == true){
			    //	    newSeq.setBounds(new Long(1), new Long(longSeq.length())); //for now
			    //	    newSeq.setCache(longSeq);
			}
			else{
//			    newSeq.setBounds(new Long(1), new Long(longSeq.length())); //for now
			    //  System.out.println("JDBC: calling setbounds where cache is false and values null");
			}
		    }
		    else {
			//	newSeq.setBounds(subSeqStart, subSeqEnd);
			//			newSeq.setCache(longSeq);
			
			initObject(newSeq, res);
		
			/*	if  (newSeq instanceof cbil.gus.Objects.GUS30.DoTS.VirtualSequence){
			    
			    String blatAlignmentQuery = sqlUtils.makeBlatAlignmentQuery(pk, subSeqStart, subSeqEnd);
			    Vector myAlignments = getGusRowsFromQuery(blatAlignmentQuery, "DoTS", "BLATAlignment");
			    if (myAlignments.size() > 0){
				getParentsForAllObjects(myAlignments, "DoTS", "Assembly", "query_na_sequence_id", true);
			     }
			    			    
			    getParentsForAllObjects(myAlignments, "DoTS", "BLATAlignmentQuality", "blat_alignment_quality_id", false);
			    for (int i = 0; i < myAlignments.size(); ++i) {
				newSeq.addChild((GUSRow)myAlignments.elementAt(i));
			    }
			    }*/
		    }
		    
		    
		}
		res.close();
		stmt.close();
	    }catch (Exception e){
		e.getMessage();
		e.printStackTrace(); 
	    }
	}
	// put the object in the cache
	return newSeq;
    }
    
    /**
     *Performs simple retrieve query on a primary or foreign key column..
     *Used by getObject, getChild, getParent, etc.
     */
    public GUSRow getGeneralObject (String owner, String table, String key_column_name, long key_number) {
	GUSRow gusObj = null;
	
	try{
	    Statement stmt = conn.createStatement();
	    
	    String sql = "select * from " +owner + "." + table  + " where " + key_column_name + " = " + key_number; 
	    
	    System.out.println("JDBC:  Executing " + sql);
	    ResultSet res = stmt.executeQuery(sql);
	    
	    while(res.next()){
		
		gusObj = createObject(owner, table);
		initObject(gusObj, res);
	    }
	    
	    res.close();
	    stmt.close();
	}catch (Exception e){
	    e.getMessage();
	    e.printStackTrace(); 
	}
	// put the object in the cache
	return gusObj;
    }
    
    public Vector getAllObjects(String table_owner, String table_name)
    {
        // always retrieves from DB
        
        Vector gusObjs = new Vector();
        try{
            Statement stmt = conn.createStatement();
            String sql = "select * from " + table_owner + "." + table_name; 
            ResultSet res = stmt.executeQuery(sql);
	    while(res.next()) {
		
		GUSRow gusObj = createObject(table_owner, table_name);
		initObject(gusObj, res);

                
		gusObjs.add(gusObj);
            }
            res.close();
            stmt.close();
        } catch (Exception e){
            e.printStackTrace(); 
	    System.err.println(e.getMessage());
        }
        // put the object in the cache!!
        return gusObjs;
    }

    //throw exception if not unique...although this may never happen dtb
    public GUSRow getParent(GUSRow child_row, String parent_table_owner, String parent_table_name, String childAtt)
    {
	
	GUSTableRelation this_parent = child_row.getTable().getParentRelation(parent_table_owner, parent_table_name);
	GUSRow parent = null;
	
	Long parent_pk = (Long)child_row.get(this_parent.getChildAtt());
	
	if (!(parent_pk == null)){
	    
	    parent = getGeneralObject(parent_table_owner, parent_table_name,  
				      this_parent.getParentAtt(), parent_pk.longValue());
	}
	else{
	    //throw exception
	}
	//put in cache
	return parent;
    }
    
    //throw exception if not unique
    public GUSRow getChild(GUSRow parent_row, String child_table_owner, String child_table_name, String childAtt)
    {
	GUSTableRelation this_child = parent_row.getTable().getChildRelation(child_table_owner, child_table_name, childAtt);
	
	// JC: should be doing a select - this is not correct
	//GUSRow child = getGeneralObject(child_table_owner, child_table_name, this_child.getChildAtt(), fk.longValue());
	//return child;
	
	return null;
    }
    
    
    
    public Vector getChildren(GUSRow parent_row, String child_table_owner, String child_table_name, String childAtt) {
	
	Vector children = new Vector();
	GUSTableRelation this_child = parent_row.getTable().getChildRelation(child_table_owner, child_table_name, childAtt);
	try {
	    
	    Statement stmt = conn.createStatement();
	    String sql = "select * from " + child_table_owner + "." + child_table_name + 
		" where " + this_child.getChildAtt() + " = " + fk.toString(); 
	    ResultSet res = stmt.executeQuery(sql);   
	    while(res.next()){
		GUSRow gusChild = createObject(child_table_owner, child_table_name);
		initObject(gusChild, res);

		children.add(gusChild);
	    }
	    res.close();
	    stmt.close();
	}
	catch (Exception e){
	    e.printStackTrace();
	    System.err.println(e.getMessage());
	}
	return children;
    }


    public int submitObject(GUSRow obj) throws SQLException {
	if (!obj.isDeleted()){
		cache.add(obj);
	}
	//need to handle if cache contains max # of objects
	
	
	
	// This should all be wrapped in a single transaction so can be 
	// rolled back if need be.  Here assumes simple update/delete.
	Statement stmt = conn.createStatement();
	String sql = null;  //check if ok

	GUSTable g_table = obj.getTable();
	String owner_name = g_table.getOwnerName();
	String table_name = g_table.getTableName();
	String pk_name = g_table.getPrimaryKeyName();
	
	int rowcount = 0;
	
	// Should first check if have write permissions!...SJD
	if (obj.isNew()){
	    
	    System.out.println ("JDBC: Inserting new object");
	    
	    ResultSet res2 = null;
	    // INSERT
            // First try to insert using the Oracle sequence to generate pk.
            Integer pk = new Integer(-9999);
            Statement stmt2 = conn.createStatement();
	    String sql2;
	    //	    String sql2 = sqlUtils.makeIdSeqSQL(owner, table_name);
	    //  try{
            //    ResultSet res2 = stmt2.executeQuery(sql2);
            //    while(res2.next()){
            //        pk = new Integer(res2.getInt("NEXTVAL"));
            //    }  
            //    res2.close();
            //   stmt2.close();
	    // } catch (SQLException e) {
	    //	 System.err.println("ERROR" + sql2.toString());
            //    e.printStackTrace();
	    // TEMPORARY WHILE SEQUENCES MISSING FROM DB!
	    try{
		sql2 = sqlUtils.makeNewIdSQL(g_table);
		res2 = stmt2.executeQuery(sql2);
		while(res2.next()){
		    pk = new Integer(res2.getInt("pk_val"));
		}
	    }
	    catch (SQLException e){  
		res2.close();
		stmt2.close();
	    }
	    res2.close();
	    stmt2.close();
	    
	    sql = sqlUtils.makeInsertSQL(owner_name, table_name, pk_name, pk, obj.getCurrentAttVals(), this.defaults);
            
        }    
	
	else if (obj.isDeleted()){     
	    System.out.println("JDBC: deleting object");// DELETE
            Long pk = new Long(obj.getPrimaryKeyValue());
            sql  = sqlUtils.makeDeleteSQL(owner_name, table_name, pk_name, pk);
        }
        else if (obj.hasChangedAtts()){     // UPDATE
	    System.out.println("JDBC: Object has changed attributes, SQLUpdate");
	    Long pk = new Long(obj.getPrimaryKeyValue());
	    //modified 9-11-02 dtb
	    sql = sqlUtils.makeUpdateSQL(owner_name, table_name, pk_name, pk, obj.getCurrentAttVals(),
					 obj.getInitialAttVals());
	    
	    //  sql  = sqlUtils.makeUpdateSQL(owner, table_name, pk_name, pk, obj.getAttValues());
        }
	else {
	    //temporary, later if object has been modified, throw exception
	    System.out.println ("Object has not been modified; not submitting to database");
	}
	
	//        System.err.println("JDBC: " + sql.toString());
        
        // SJD Still to add...version the row if versionable!!
        
        if (!(sql == null)){
	    try {
	        rowcount += stmt.executeUpdate(sql.toString());
		
		
		stmt.close();
	    } catch (SQLException e) {
		System.err.println("Error " + sql.toString());
		e.printStackTrace();
		//REMEBER TO ROLLBACK !! SJD
	    }
	}
        
        // Rewriting: If this object has children, call submit parts...  SJD
	
	return rowcount;  //need to change to return the (possibly) updated obj.
	
    }

    // ------------------------------------------------------------------
    // DEFAULT VALUES FOR SHARED COLUMNS
    // ------------------------------------------------------------------
    
    protected void setDefaultValues() {
	
	// JC: Could we put all this stuff in a new instance of GUSRow?  I think this
	// is called the "prototype" OO design pattern.  Another problem here is that
	// these values (Integer vs. Long) depend on the database and so should not
	// be hardcoded.
	
	defaults.put("modification_date", "SYSDATE");  //should move elsewhere perhaps.
	
	// by default all permissions set to 1 except other_write
	//
	setDefaultUserRead(new Integer(1));
	setDefaultUserWrite(new Integer(1));
	setDefaultGroupRead(new Integer(1));
	setDefaultGroupWrite(new Integer(1));
	setDefaultOtherRead(new Integer(1));
	setDefaultOtherWrite(new Integer(0));
	
	// not setting DefaultRowUserId - this depends on login information
	
	setDefaultRowGroupId(new Integer(0));
	setDefaultRowProjectId(new Integer(0));
	setDefaultRowAlgInvocationId(new Integer(1));
    }
    
    // modification_date
    public String getDefaultModificationDate() { return (String)(defaults.get("modification_date")); }
    
    // user_read
    public void setDefaultUserRead(Integer d) { defaults.put("user_read", d);  }
    public Integer getDefaultUserRead() { return (Integer)(defaults.get("user_read")); }
    
    // user_write
    public void setDefaultUserWrite(Integer d) { defaults.put("user_write", d); }
    public Integer getDefaultUserWrite() { return (Integer)(defaults.get("user_write")); }
    
    // group_read
    public void setDefaultGroupRead(Integer d) { defaults.put("group_read", d);  }
    public Integer getDefaultGroupRead() { return (Integer)(defaults.get("group_read")); }
    
    // group_write
    public void setDefaultGroupWrite(Integer d) { defaults.put("group_write", d); }
    public Integer getDefaultGroupWrite() { return (Integer)(defaults.get("group_write")); }
    
    // other_read
    public void setDefaultOtherRead(Integer d) { defaults.put("other_read", d);  }
    public Integer getDefaultOtherRead() { return (Integer)(defaults.get("other_read")); }
    
    // other_write
    public void setDefaultOtherWrite(Integer d) { defaults.put("other_write", d); }
    public Integer getDefaultOtherWrite() { return (Integer)(defaults.get("other_write")); }
    
    // row_user_id
    public void setDefaultRowUserId(Integer d) { defaults.put("row_user_id", d);  }
    public Integer getDefaultRowUserId() { return (Integer)(defaults.get("row_user_id")); }
    
    // row_group_id
    public void setDefaultRowGroupId(Integer d) { defaults.put("row_group_id", d);  }
    public Integer getDefaultRowGroupId() { return (Integer)(defaults.get("row_group_id")); }
    
    // row_project_id
    public void setDefaultRowProjectId(Integer d) { defaults.put("row_project_id", d);  }
    public Integer getDefaultRowProjectId() { return (Integer)(defaults.get("row_project_id")); }
    
    // row_alg_invocation_id
    public void setDefaultRowAlgInvocationId(Integer d) { defaults.put("row_alg_invocation_id", d); }
    public Integer getDefaultRowAlgInvocationId() { return (Integer)(defaults.get("row_alg_invocation_id")); }

    // ------------------------------------------------------------------
    // Miscellaneous - these methods were moved here temporarily from the old sqlUtils
    // ------------------------------------------------------------------
    
    // JC: could this be done using the object layer itself?  i.e., retrieve the
    // core.UserInfo object with username = ? and then compare the passwords.

    /**
     * makeCheckUserSQL: Returns SQL to check if valid user
     */
    public static String makeCheckUserSQL(String username, String password) {
        StringBuffer sql = new StringBuffer("SELECT u.user_id from CORE.USERINFO u\n");
        sql.append("WHERE u.login = '" + username + "'\n");
        sql.append("  AND u.password = '" + password + "'\n");
        
        return sql.toString();
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
    
} //JDBCDatabaseConnection




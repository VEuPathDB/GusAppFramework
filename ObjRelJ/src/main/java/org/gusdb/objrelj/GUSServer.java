package org.gusdb.objrelj;

import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.List;
import java.util.Vector;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;
import java.util.logging.StreamHandler;

/**
 * GUSServer.java
 *
 * A generic implementation of ServerI that uses an instance of 
 * DatabaseConnectionI to perform all of its database access.
 * That instance may in fact be a RemoteDatabaseConnectionI, i.e.
 * a database connection that is accessed over RMI.
 *
 * Created: Wed May 15 12:02:00 2002
 *
 * @author Sharon Diskin, Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class GUSServer implements ServerI {

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    /**
     * Object used to produce database connections.
     */
    protected DatabaseDriverI driver;

    /**
     * Stores all the active sessions; maps from sessionId to Session.
     */
    protected Hashtable sessions = new Hashtable();

    // ------------------------------------------------------------------
    // Session inner class
    // ------------------------------------------------------------------

    /**
     * Inner class that stores information on a single session
     */
    class Session {

	/**
	 * GUS login/username.
	 */
        String user;

	/**
	 * GUS password for <code>user</code>.
	 */
        String password;

	/**
	 * Unique session ID used by the client to identify itself.
	 */
        String session;

	/**
	 * List to keep track of the operations performed in this session.
	 */
        List history = new ArrayList();

	/**
	 * When the session was first established.
	 */
        java.util.Date opened;

	/**
	 * Date that the most recent action was added to the history.
	 */
	java.util.Date lastUsed;

	/**
	 * The object used to do all the database access.
	 */
	DatabaseConnectionI conn;

	/**
	 * Object factory for this session.
	 */
	GUSRowFactory factory;

	/**
	 * Default values for standard attributes (e.g., group_id, user_id, etc.)
	 * for newly-created objects.
	 */ 
	Hashtable defaults;
    
	/**
	 * Logger from java.util.logging package.
	 */
	protected Logger logger; 
	
	/**
	 * Constructor
	 *
	 * @param conn     GUS database connection.
	 * @param user     GUS login/username.
	 * @param password GUS password.
	 * @param session  Unique (and hopefully hard-to-guess) ID for the new session.
	 */
        Session(DatabaseConnectionI conn, String user, String password, String session) 
        {
	    this.logger = Logger.getLogger("org.gusdb.objrelj.GUSServer.Session");
	    this.logger.setLevel(Level.INFO);
	    StreamHandler logHandler = new StreamHandler(System.out, new SimpleFormatter());
	    this.logger.addHandler(logHandler);
	    defaults = new Hashtable();
            this.user = user;
            this.password = password;
            this.session = session;
            this.conn = conn;
	    this.factory = new GUSRowFactory();
            opened = new java.util.Date();
            history.add(opened.toString() + ": Connection opened");
        }

	/**
	 * Add a timestamped entry to the session history.
	 */
	protected void addToHistory(String item) {
	    java.util.Date now = new java.util.Date();
	    String nowStr = now.toString();
	    String newItem = nowStr + ": " + item;
	    history.add(newItem);
	    this.lastUsed = now;
	    logger.fine(newItem);
	}

	// JC: Need to consider synchronization issues here?

	/**
	 * Free the resources associated with this Session.
	 */
	protected void destroy() {
	    try {
		this.conn.close();
	    } catch (RemoteException re) {}
	    this.history = null;
	    this.factory = null;
	}

	// ------------------------------------------------------------------
	// DEFAULT VALUES FOR SHARED COLUMNS
	// ------------------------------------------------------------------
	
	// DTB:  Took out 'initDefaultValues' method that duplicates Perl DbiDatabase
	// functionality; it initialized these default values with hardcoded values.
	// For right now, it is the responsibility of the client using the object layer
	// to set default values on its Session (through its GUSServer); later, we will
	// probably use java object layer plugins to do this.

	//DTB: This returns "SYSDATE" in Oracle; but there is a data type conflict
	//since it returns as a String and we handle this as Date.  For now will
	//just return new Date();
	/*public String getDefaultModificationDate() { 
	    String date = "";
	    try{
		date = conn.getSubmitDate();
	    }
	    catch(RemoteException e){
		e.printStackTrace();
	    }
	    return date;
	}*/
	
	public java.sql.Date getDefaultModificationDate(){
	    java.util.Date currentDate = new java.util.Date();
	    long ms = currentDate.getTime();
	    return new java.sql.Date(ms);
	}

	// user_read
	public void setDefaultUserRead(Boolean d) { defaults.put("user_read", d);  }
	public Boolean getDefaultUserRead() { return (Boolean)(defaults.get("user_read")); }
	
	// user_write
	public void setDefaultUserWrite(Boolean d) { defaults.put("user_write", d); }
	public Boolean getDefaultUserWrite() { return (Boolean)(defaults.get("user_write")); }
	
	// group_read
	public void setDefaultGroupRead(Boolean d) { defaults.put("group_read", d);  }
	public Boolean getDefaultGroupRead() { return (Boolean)(defaults.get("group_read")); }
	
	// group_write
	public void setDefaultGroupWrite(Boolean d) { defaults.put("group_write", d); }
	public Boolean getDefaultGroupWrite() { return (Boolean)(defaults.get("group_write")); }
	
	// other_read
	public void setDefaultOtherRead(Boolean d) { defaults.put("other_read", d);  }
	public Boolean getDefaultOtherRead() { return (Boolean)(defaults.get("other_read")); }
	
	// other_write
	public void setDefaultOtherWrite(Boolean d) { defaults.put("other_write", d); }
	public Boolean getDefaultOtherWrite() { return (Boolean)(defaults.get("other_write")); }
	
	// row_user_id
	public void setDefaultRowUserId(Long d) { defaults.put("row_user_id", d);  }
	public Long getDefaultRowUserId() { return (Long)(defaults.get("row_user_id")); }
	
	// row_group_id
	public void setDefaultRowGroupId(Short d) { defaults.put("row_group_id", d);  }
	public Short getDefaultRowGroupId() { return (Short)(defaults.get("row_group_id")); }
	
	// row_project_id
	public void setDefaultRowProjectId(Short d) { defaults.put("row_project_id", d);  }
	public Short getDefaultRowProjectId() { return (Short)(defaults.get("row_project_id")); }
	
	// row_alg_invocation_id
	public void setDefaultRowAlgInvocationId(Long d) { defaults.put("row_alg_invocation_id", d); }
	public Long getDefaultRowAlgInvocationId() { return (Long)(defaults.get("row_alg_invocation_id")); }

    } //Session

    // ------------------------------------------------------------------
    // Constructors
    // ------------------------------------------------------------------

    /**
     * Constructor
     *
     * @param driver   Object through which connections to a database are made.
     */
    public GUSServer(DatabaseDriverI driver) {
	this.driver = driver;
    }

    // ------------------------------------------------------------------
    // ServerI
    // ------------------------------------------------------------------
    
    @Override
    public String openConnection(String user, String password) throws GUSInvalidLoginException
    {
	String session = null;
	DatabaseConnectionI conn = null;
	try {
	    conn = driver.getConnection(user, password);
	}
	catch (GUSInvalidLoginException e){
	    System.out.println(e.getMessage());
	    e.printStackTrace();
	}
	if (conn != null) {
	    long suff = (new java.util.Date()).getTime();
	    // JC: This is not guaranteed to be unique, although it probably will be
	    session = user + "_" + suff;
	    
	    Session s = new Session(conn, user, password, session);
	    sessions.put(session, s);
	}
	return session;
    }
    
    @Override
    public void closeConnection(String session) 
	throws GUSNoConnectionException 
    {
        Session s = getSession(session);
	sessions.remove(s);
	s.destroy();
    }

    @Override
    public List getSessionHistory(String session) 
	throws GUSNoConnectionException
    {
        Session s = getSession(session);
	return new ArrayList(s.history);
    }
    
    @Override
    public GUSRow retrieveGUSRow(String session, GUSTable table, long pkValue, boolean retrieveEager) 
	throws GUSNoConnectionException, GUSObjectNotUniqueException
    {
	return this.retrieveGUSRow(session, table, pkValue, retrieveEager, null,null,null);
    }
    
    @Override
    public GUSRow retrieveGUSRow(String session, GUSTable table, long pkValue, boolean retrieveEager,
				 String clobAtt, Long start, Long end) 
        throws GUSNoConnectionException, GUSObjectNotUniqueException
    {
        Session s = getSession(session);
	
	// Check the factory first

	GUSRow gusRow = null;

	boolean gusRowInFactory = s.factory.contains(table.getSchemaName(), table.getTableName(), pkValue);
	if (!gusRowInFactory){
	    gusRow = GUSRow.createGUSRow(table);
	    try{
		gusRow.setPrimaryKeyValue(new Long(pkValue));
	    }
	    catch (Exception e){
		e.printStackTrace();
	    }
	    s.factory.add(gusRow);
	    gusRow.setServer(this);
	    gusRow.setSessionId(session);
	    gusRow.setIsEager(retrieveEager);
	    
	    if (retrieveEager){  
		try {
		    s.conn.retrieveGUSRow(gusRow, clobAtt, start, end);
		}
		catch (RemoteException e) {}
		//DTB: throw exception?  used to only add gusrow to factory here if it wasn't null...
		//but with new way of doing things will never be null
		s.factory.add(gusRow); 
		s.addToHistory("retrieveGUSRow: retrieved from db - " + gusRow);
	    }
	    else { //return lazy object
		s.addToHistory("retrieveGUSRow: returned empty GUSRow - " + gusRow);
	    }
	} 
	else { //object was in the factory; it may be lazy
	    gusRow = s.factory.get(table.getSchemaName(), table.getTableName(), pkValue);
	    if (!gusRow.isEager() && retrieveEager){
		try{
		    gusRow.retrieve();
		}
		catch (Exception e){
		    System.err.println(e.getMessage());
		    e.printStackTrace();
		}
		s.addToHistory("retrieveGUSRow: retrieved existing unretrieved GUSRow - " + gusRow);
	    }
	    else{ //return whatever's in there.

		// If the requested CLOB substring differs from that stored in the 
		// factoryd object then we have to query the database to retrieve
		// the requested substring.
		//
		if (clobAtt != null) {
		    // JC: to do
		}
		
		s.addToHistory("retrieveGUSRow: retrieved from factory - " + gusRow);
	    }
	}
	return gusRow;
    }

    @Override
    public Vector retrieveAllGUSRows(String session, GUSTable table) 
        throws GUSNoConnectionException
    {
        Session s = getSession(session);
	try {
	    SQLutilsI sqlUtils = s.conn.getSqlUtils();
	    String selectSql = sqlUtils.makeSelectAllRowsSQL(table.getSchemaName(), table.getTableName());
	    return retrieveGUSRowsFromQuery(session, table, selectSql);
	} catch (RemoteException re) {}

	return null;
    }
    
    @Override
    public Vector retrieveGUSRowsFromQuery(String session, GUSTable table, String query)
	throws GUSNoConnectionException
    {
        Session s = getSession(session);
        Vector returnedRows = null;
	Vector gusRows = new Vector();
	try {
	    returnedRows = s.conn.retrieveGUSRowsFromQuery(table, query);
	} catch (RemoteException re) {}

	int nRows = (returnedRows == null) ? 0 : returnedRows.size();
	int numNew = 0;  // Number of objects not already in the factory

	// See whether any of the objects are already in the factory
	// 
	for (int i = 0;i < nRows;++i) {
	    Hashtable rowHash = (Hashtable)returnedRows.elementAt(i);
	    GUSRow gusRow = GUSRow.createGUSRow(table);
	    gusRow.setServer(this);
	    gusRow.setSessionId(session);
	    gusRow.setIsEager(true);
	    gusRow.setAttributesFromHashtable(rowHash, null);
	    
	    GUSRow co = s.factory.get(gusRow);

	    // This object is not new; it should be returned in place of row
	    // 
	    if (co != null) {
		gusRows.addElement(co);
	    } 
	    
	    // This object is new and should be cached
	    //
	    else {
		s.factory.add(gusRow);
		numNew++;
		gusRows.addElement(gusRow);
	    }
	}

	s.addToHistory("retrieveGUSRowsFromQuery: selected " + nRows + " rows from " + table.getSchemaName() + 
		       "." + table.getTableName() + ", of which " + numNew + " are not in the factory.");
        return gusRows;
    }

    @Override
    public Vector runSqlQuery(String session, String sql) 
	throws GUSNoConnectionException 
    {
        Session s = getSession(session);
        Vector objs = null;
	try {
	    objs = s.conn.runSqlQuery(sql);
	} catch (RemoteException re) {}

	return objs;
    }


    @Override
    public SubmitResult submitGUSRow(String session, GUSRow obj, boolean deepSubmit, boolean startTransaction) 
        throws GUSNoConnectionException
    {
	SubmitResult sr = new SubmitResult(true, 0, 0, 0, new Vector());
	Session s = getSession(session);
	//TO DO - this doesn't check if submit_aux correctly submitted
		
	this.submitGUSRow_aux(s, obj, deepSubmit, sr);
	//GUSRow now has a pk value, put in factory.
	//DTB: running the "get" check every time...will that slow
	//things down if submitting a bunch of objects?
	
	s.addToHistory("submitGUSRow: submitted " + obj + ", deep submit = " + deepSubmit);
	if (startTransaction == true){
	    try {
		s.conn.commit();
	    }
	    catch (RemoteException e){
		e.printStackTrace();
		System.err.println(e.getMessage());
	    }
	}
	return sr;

    }

    @Override
    public GUSRow createGUSRow(String session, GUSTable table) 
        throws GUSNoConnectionException 
    {
	Session s = getSession(session);
	GUSRow newObj = GUSRow.createGUSRow(table);

	
	// TO DO - set these when creating the object or upon submit?

       	/*	Enumeration e = s.defaults.keys();
		while (e.hasMoreElements()) {
		String key = (String)(e.nextElement());
		Object value = s.defaults.get(key);
		newObj.set(key, value);
		}*/

	s.addToHistory("createGUSRow: created new object " + newObj);
        return newObj;
    }

    @Override
    public GUSRow retrieveParent(String sessionId, GUSRow child, GUSTable parentTable, String childAtt)
    throws GUSNoConnectionException, GUSNoSuchRelationException, GUSObjectNotUniqueException{
	Session s = getSession(sessionId);
	GUSRow parent = null;
	try{
	    Long parentPk = s.conn.getParentPk(child, parentTable, childAtt);
	    if (parentPk != null){
		parent = GUSRow.createGUSRow(parentTable);
		
		parent.setPrimaryKeyValue(parentPk);
		parent = retrieveGUSRow(sessionId, parentTable, parentPk.longValue(), true);
		parent.setIsEager(true);
	    }
	}
	catch (Exception e){
	    e.printStackTrace();
	}
	
	return parent;
    }

    // JC: retrieveParent, retrieveChild, and retrieveChildren should be 
    // rewritten to y on retrieveGUSRow and retrieveGUSRowsFromQuery
    // (with some post-processing to make the setChild/setParent calls)
	//dtb:  this is the way we used to do it...don't delete just yet
    @Override
    public GUSRow retrieveParent(String session, GUSRow row, String owner, String tname, String childAtt)
	throws GUSNoConnectionException, GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	Session s = getSession(session);
	GUSRow parent = null;
	try {
	    parent = s.conn.retrieveParent(row, owner, tname, childAtt);
	} catch (RemoteException re) {}

	GUSRow obj = s.factory.get(parent);

	if (obj != null) { 
	    parent = obj;
	} else {
	    s.factory.add(parent);
	}

	s.addToHistory("retrieveParent: retrieved parent row " + parent + " for child row " + row);

	// TO DO: make sure this works even if the parent-child relationship has already
	// been established.
	//row.setParent(parent);
	//	parent.addChild(row);
        return parent;
    }

    @Override
    public GUSRow[] retrieveParentsForAllGUSRows(String session, Vector children, String parentOwner, 
						 String parentName, String childAtt)
	throws GUSNoConnectionException, GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	GUSRow parents[] = null;
	Session s = getSession(session);

	try {
	    parents = s.conn.retrieveParentsForAllGUSRows(children, parentOwner, parentName, childAtt);
	}
	catch (RemoteException re) {}
	int nc = (children == null) ? 0 : children.size();

	if (parents != null) {
	    int np = parents.length;

	    for (int i = 0;i < np;++i) {
		GUSRow obj = s.factory.get(parents[i]);
		
		if (obj != null) {
		    parents[i] = obj;
		} else {
		    s.factory.add(parents[i]);
		}

		// Can't be sure that the correspondence is correct unless the correct
		// number of parents were retrieved, namely one for each child
		//
		//if (nc == np) {
		    //GUSRow child = (GUSRow)(children.elementAt(i));
		    //		    child.addParent(parents[i]);
		    //		    parents[i].addChild(child);
		//}
	    }
	}

	s.addToHistory("retrieveParentsForAllGUSRows: retrieved " + parents.length + " " + 
		       parentOwner + "." + parentName + " object(s) for " + nc + " child row(s)");
	return parents;
    }

     @Override
    public GUSRow retrieveChild(String session,  GUSRow row, String owner, String tname, String childAtt)
         throws GUSNoConnectionException, GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	Session s = getSession(session);
	GUSRow child = null;
	try {
	    child = s.conn.retrieveChild(row, owner, tname, childAtt);
	} catch (RemoteException re) {}
	GUSRow obj = s.factory.get(child);

	if (obj != null) { 
	    child = obj;
	} else {
	    s.factory.add(child);
	}

	s.addToHistory("retrieveChild: retrieved child " + child + " for parent " + row + ", childAtt=" + childAtt);

	// TO DO: make sure this works even if the parent-child relationship has already
	// been established.
	//	row.addChild(child);
	//	child.addParent(row);
        return child;
    }

    @Override
    public Vector retrieveChildren(String session, GUSRow row, String owner, String tname, String childAtt) 
	throws GUSNoConnectionException, GUSNoSuchRelationException
    {
	Session s = getSession(session);
        Vector children = null;
	try {
	    children = s.conn.retrieveChildren(row, owner, tname, childAtt);
	} catch (RemoteException re) {}
	int nc = (children == null) ? 0 : children.size();
	int numNew = 0;  // Number of objects not already in the factory

	for (int i = 0;i < nc;++i) {
	    GUSRow child = (GUSRow)(children.elementAt(i));
	    GUSRow co = s.factory.get(child);

	    // This object is not new; it should be returned in place of child
	    // 
	    if (co != null) {
		children.setElementAt(co, i);
		//		row.addChild(co);
		//		co.addParent(row);
	    } 

	    // This object is new and should be factoryd
	    //
	    else {
		s.factory.add(child);
		numNew++;
		//		row.addChild(child);
		//		child.addParent(row);
	    }

	}

	s.addToHistory("retrieveChildren: retrieved " + nc + " child rows for " + row + ", childAtt=" + 
		       owner + "." + tname + "." + childAtt + ", of which " + numNew + " are not in the factory");
	return children;
    }
    
    public java.sql.Date getDefaultModificationDate(String sessionName) throws GUSNoConnectionException { 
	Session session = getSession(sessionName);
	return session.getDefaultModificationDate();
    }

    // TO DO - add this restriction to other setters

    /**
     * Must be called only after opening a connection to the database.
     */
    public void setDefaultUserRead(String sessionName, Boolean d) throws GUSNoConnectionException {
	Session session = getSession(sessionName);
	session.setDefaultUserRead(d);
    }
    public Boolean getDefaultUserRead(String sessionName) throws GUSNoConnectionException {
	Session session = getSession(sessionName);
	return session.getDefaultUserRead();
    }
    public void setDefaultUserWrite(String sessionName, Boolean d) throws GUSNoConnectionException { 
	Session session = getSession(sessionName);
	session.setDefaultUserWrite(d);
    }
    public Boolean getDefaultUserWrite(String sessionName) throws GUSNoConnectionException {
	Session session = getSession(sessionName);
	return session.getDefaultUserWrite();
    }
    public void setDefaultGroupRead(String sessionName, Boolean d) throws GUSNoConnectionException { 
	Session session = getSession(sessionName);
	session.setDefaultGroupRead(d);
    }
    public Boolean getDefaultGroupRead(String sessionName) throws GUSNoConnectionException { 
	Session session = getSession(sessionName);
	return session.getDefaultGroupRead();
    }
    public void setDefaultGroupWrite(String sessionName, Boolean d) throws GUSNoConnectionException {
	Session session = getSession(sessionName);
	session.setDefaultGroupWrite(d);
    }
    public Boolean getDefaultGroupWrite(String sessionName) throws GUSNoConnectionException { 
	Session session = getSession(sessionName);
	return session.getDefaultGroupWrite();
    }
    public void setDefaultOtherRead(String sessionName, Boolean d) throws GUSNoConnectionException { 
	Session session = getSession(sessionName);
	session.setDefaultOtherRead(d);
    }
    public Boolean getDefaultOtherRead(String sessionName) throws GUSNoConnectionException {
	Session session = getSession(sessionName);
	return session.getDefaultOtherRead();
    }
    public void setDefaultOtherWrite(String sessionName, Boolean d) throws GUSNoConnectionException { 
	Session session = getSession(sessionName);
	session.setDefaultOtherWrite(d);
    }
    public Boolean getDefaultOtherWrite(String sessionName) throws GUSNoConnectionException {
	Session session = getSession(sessionName);
	return session.getDefaultOtherWrite();
    }
    public void setDefaultRowUserId(String sessionName, Long d) throws GUSNoConnectionException {
	Session session = getSession(sessionName);
	session.setDefaultRowUserId(d);
    }
    public Long getDefaultRowUserId(String sessionName) throws GUSNoConnectionException {
	Session session = getSession(sessionName);
	return session.getDefaultRowUserId();
    }
    public void setDefaultRowGroupId(String sessionName, Short d) throws GUSNoConnectionException {
	Session session = getSession(sessionName);
	session.setDefaultRowGroupId(d);
    }
    public Short getDefaultRowGroupId(String sessionName) throws GUSNoConnectionException {
	Session session = getSession(sessionName);
	return session.getDefaultRowGroupId();
    }
    public void setDefaultRowProjectId(String sessionName, Short d) throws GUSNoConnectionException { 
	Session session = getSession(sessionName);
	session.setDefaultRowProjectId(d);
    }
    public Short getDefaultRowProjectId(String sessionName) throws GUSNoConnectionException { 
	Session session = getSession(sessionName);
	return session.getDefaultRowProjectId();
    }
    public void setDefaultRowAlgInvocationId(String sessionName, Long d) throws GUSNoConnectionException {
	Session session = getSession(sessionName);
	session.setDefaultRowAlgInvocationId(d);
    }
    public Long getDefaultRowAlgInvocationId(String sessionName) throws GUSNoConnectionException {
	Session session = getSession(sessionName);
	return session.getDefaultRowAlgInvocationId();
    }
    


    // ------------------------------------------------------------------
    // Protected methods
    // ------------------------------------------------------------------

    /**
     * Get the named Session object.
     *
     * @param session   A session ID returned by <code>openConnection</code>
     * @return The object that represents the session, if it is still valid.
     */
    protected Session getSession(String session) throws GUSNoConnectionException 
    {
	Session s = (Session)sessions.get(session);
	if (s == null) throw new GUSNoConnectionException("No connection for " + session);
	return s;
    }

    /**
     * Helper method for submitGUSRow.  It updates the SubmitResult in place to 
     * indicate the actions that it has performed.  Also sets default overhead
     * attributes for a GUSRow, and sets the primary key attribute for the GUSRow
     * if it is newly created (using the primary key in the submit result.)
     *
     * @return Whether the submit succeeded
     */
    protected boolean submitGUSRow_aux(Session s, GUSRow gusRow, boolean deepSubmit, SubmitResult sr) {
	
	//Default attributes are Session specific, so set them here.
	SubmitResult sres = null;
	if (gusRow.isDeleted()){
	    
	    submitGUSRowChildren(s, gusRow, sr);
	    gusRow.removeFromParents();
	    try {
		sres = s.conn.submitGUSRow(gusRow);
	    }
	    catch (Exception e) {
		System.err.println(e.getMessage());
		e.printStackTrace();
		return false;
	    }
	}
	else{
	    
	    setDefaultAttributes(s, gusRow);
	    
	    //Make sure all parents have foreign key values
	    try {
		gusRow.submitNewParents(sr);
		
		// First submit the gusRow itself
		//
		sres = s.conn.submitGUSRow(gusRow);
	    } catch (Exception e) {
		System.err.println(e.getMessage());
		e.printStackTrace();
		return false;
	    }
	    sr.update(sres);

	    if (!sr.submitSucceeded()) {
		return false;
	    }
	    
	    if (gusRow.isEager == false){
		gusRow.setIsEager(true);
		
		Vector newPks = sres.getNewPrimaryKeys();
		Long newPk = (Long)newPks.elementAt(0);
		//		System.out.println("GUSServer.submitGUSRow_aux: setting pk attribute");
		//	System.out.println("att name is : " + gusRow.getTable().getPrimaryKeyName() + " and value is " + newPk);
		try{
		    gusRow.setPrimaryKeyValue(newPk);
		}
		catch (Exception e) {
		    e.printStackTrace();
		    System.err.println(e.getMessage());
		}
	    }
	    gusRow.syncAttsWithDb();
	    if (s.factory.get(gusRow) == null){
		s.factory.add(gusRow);
	    }
	    if (sr.submitSucceeded && deepSubmit) {
		submitGUSRowChildren(s, gusRow, sr);
	    }
	}
	return true;
    }
    
    protected boolean submitGUSRowChildren(Session s, GUSRow gusRow, SubmitResult sr){

	Hashtable allChildren = gusRow.getAllChildren(); 
	Enumeration childKeys = allChildren.keys();
	while (childKeys.hasMoreElements()){
	    String nextChildKey = (String)childKeys.nextElement();
	    
	    Vector nextChildList = (Vector)allChildren.get(nextChildKey);
		
	    for (int i = 0; i < nextChildList.size(); i++){
		
		GUSRow nextChild = (GUSRow)nextChildList.elementAt(i);
		// Abort as soon as a submit fails
		//
		if (!submitGUSRow_aux(s, nextChild, true, sr)) {
		    
		    return false;
		}
	    }
	}
	return true;
    }
    
    // ------------------------------------------------------------------
    // Private Methods
    // ------------------------------------------------------------------
    
    /**
     * Set default attributes for this GUSRow if they haven't been set already.
     * ModificationDate is always set regardless of if it has been already.
     */
    private void setDefaultAttributes(Session s, GUSRow gr){
	try{
	    
	    gr.set_Attribute("modification_date", s.getDefaultModificationDate());
	    
	    //attributes (non-foreign key values)
	    Boolean userRead = (Boolean)gr.get_Attribute("user_read");
	    if (userRead == null){
		gr.set_Attribute("user_read", s.getDefaultUserRead());
	    }
	    
	    Boolean userWrite = (Boolean)gr.get_Attribute("user_write");
	    if (userWrite == null){
		gr.set_Attribute("user_write", s.getDefaultUserWrite());
	    }
	    
	    Boolean groupRead = (Boolean)gr.get_Attribute("group_read");
	    if (groupRead == null){
		gr.set_Attribute("group_read", s.getDefaultGroupRead());
	    }
	    
	    Boolean groupWrite = (Boolean)gr.get_Attribute("group_write");
	    if (groupWrite == null){
		gr.set_Attribute("group_write", s.getDefaultGroupWrite());
	    }
	    
	    Boolean otherRead = (Boolean)gr.get_Attribute("other_read");
	    if (otherRead == null){
		gr.set_Attribute("other_read", s.getDefaultOtherRead());
	    }
	    
	    Boolean otherWrite = (Boolean)gr.get_Attribute("other_write");
	    if (otherWrite == null){
		gr.set_Attribute("other_write", s.getDefaultOtherWrite());
	    }
	    
	    //Foreign keys:  get values from session and create objects
	    GUSRow rowUserId = (GUSRow)gr.get_Attribute("row_user_id");
	    if (rowUserId == null){
		gr.set_OverheadAttribute("Core", "UserInfo", "row_user_id", s.getDefaultRowUserId().longValue());
	    }
	    
	    GUSRow rowProjectId = (GUSRow)gr.get_Attribute("row_project_id");
	    if (rowProjectId == null){
		gr.set_OverheadAttribute("Core", "ProjectInfo", "row_project_id", s.getDefaultRowProjectId().longValue());
	    }
	    
	    GUSRow rowGroupId = (GUSRow)gr.get_Attribute("row_group_id");
	    if (rowGroupId == null){
		gr.set_OverheadAttribute("Core", "GroupInfo", "row_group_id", s.getDefaultRowGroupId().longValue());
	    }
	    
	    GUSRow rowAlgInvocationId = (GUSRow)gr.get_Attribute("row_alg_invocation_id");
	    if (rowAlgInvocationId == null){
		gr.set_OverheadAttribute("Core", "AlgorithmInvocation", "row_alg_invocation_id", 
					 s.getDefaultRowAlgInvocationId().longValue());
	    }
	}
	catch (Exception e){
	    System.err.println(e.getMessage());
	    e.printStackTrace();
	}

    }

} //GUSServer



package org.gusdb.objrelj;

import java.util.*;
import java.util.logging.*;
import java.lang.*;
import java.rmi.*;
import java.sql.*;
import oracle.sql.*;

import org.biojava.bio.*;
import org.biojava.bio.seq.*;
import org.biojava.bio.seq.io.*;
import org.biojava.bio.symbol.*;

import org.gusdb.objrelj.*;

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
	 * Object cache for this session.
	 */
	ObjectCache cache;

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

            this.user = user;
            this.password = password;
            this.session = session;
            this.conn = conn;
	    this.initDefaultValues();
	    this.cache = new ObjectCache();
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
	    this.cache = null;
	}

	// ------------------------------------------------------------------
	// DEFAULT VALUES FOR SHARED COLUMNS
	// ------------------------------------------------------------------

	/**
	 * Set default attribute values for any new GUSRow objects created in this session.
	 */
	protected void initDefaultValues() {
	    this.defaults = new Hashtable();
	    
	    // JC: Could we put all this stuff in a new instance of GUSRow instead of 
	    // a Hashtable?  I think this is called the "prototype" OO design pattern.
	    // The problem here is that these values (Integer vs. Long) depend on the 
	    // database and so should not be hardcoded (or, if they are to be hardcoded,
	    // it would be better to make them part of the generated code.)
	    
	    defaults.put("modification_date", "SYSDATE");  //should move elsewhere perhaps.
	    
	    // by default all permissions set to 1 except other_write
	    //
	    Short s0 = new Short((short)0);
	    Short s1 = new Short((short)1);

	    setDefaultUserRead(s1);
	    setDefaultUserWrite(s1);
	    setDefaultGroupRead(s1);
	    setDefaultGroupWrite(s1);
	    setDefaultOtherRead(s1);
	    setDefaultOtherWrite(s0);
	    setDefaultRowGroupId(s0);
	    setDefaultRowProjectId(s0);
	    setDefaultRowAlgInvocationId(new Long(1));

	    try {
		setDefaultRowUserId(new Long(this.conn.getCurrentUserId()));
	    } catch (RemoteException re) {}
	}

	// JC: either these methods need to be duplicated in GUSServer proper, or 
	// the session needs to be turned into a first-class object.  It's not
	// crucial, however, since the application can always set these shared
	// columns manually.
    
	// modification_date
	public String getDefaultModificationDate() { return (String)(defaults.get("modification_date")); }
	
	// user_read
	public void setDefaultUserRead(Short d) { defaults.put("user_read", d);  }
	public Short getDefaultUserRead() { return (Short)(defaults.get("user_read")); }
	
	// user_write
	public void setDefaultUserWrite(Short d) { defaults.put("user_write", d); }
	public Short getDefaultUserWrite() { return (Short)(defaults.get("user_write")); }
	
	// group_read
	public void setDefaultGroupRead(Short d) { defaults.put("group_read", d);  }
	public Short getDefaultGroupRead() { return (Short)(defaults.get("group_read")); }
	
	// group_write
	public void setDefaultGroupWrite(Short d) { defaults.put("group_write", d); }
	public Short getDefaultGroupWrite() { return (Short)(defaults.get("group_write")); }
	
	// other_read
	public void setDefaultOtherRead(Short d) { defaults.put("other_read", d);  }
	public Short getDefaultOtherRead() { return (Short)(defaults.get("other_read")); }
	
	// other_write
	public void setDefaultOtherWrite(Short d) { defaults.put("other_write", d); }
	public Short getDefaultOtherWrite() { return (Short)(defaults.get("other_write")); }
	
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
    
    public void closeConnection(String session) 
	throws GUSNoConnectionException 
    {
        Session s = getSession(session);
	sessions.remove(s);
	s.destroy();
    }

    public List getSessionHistory(String session) 
	throws GUSNoConnectionException
    {
        Session s = getSession(session);
	return new ArrayList(s.history);
    }
    
    public GUSRow retrieveObject(String session, String owner, String tname, long pk) 
	throws GUSNoConnectionException, GUSObjectNotUniqueException
    {
	return this.retrieveObject(session,owner,tname,pk,null,null,null);
    }

    public Vector retrieveAllObjects(String session, String owner, String tname) 
        throws GUSNoConnectionException
    {
        Session s = getSession(session);
	try {
	    SQLutilsI sqlUtils = s.conn.getSqlUtils();
	    String selectSql = sqlUtils.makeSelectAllRowsSQL(owner, tname);
	    return retrieveObjectsFromQuery(session, owner, tname, selectSql);
	} catch (RemoteException re) {}

	return null;
    }
    
    public Vector retrieveObjectsFromQuery(String session, String owner, String tname, String query)
	throws GUSNoConnectionException
    {
        Session s = getSession(session);
        Vector objs = null;
	try {
	    objs = s.conn.retrieveObjectsFromQuery(owner, tname, query);
	} catch (RemoteException re) {}

	int nRows = (objs == null) ? 0 : objs.size();
	int numNew = 0;  // Number of objects not already in the cache

	// See whether any of the objects are already in the cache
	// 
	for (int i = 0;i < nRows;++i) {
	    GUSRow row = (GUSRow)(objs.elementAt(i));
	    GUSRow co = s.cache.get(row);

	    // This object is not new; it should be returned in place of row
	    // 
	    if (co != null) {
		objs.setElementAt(co, i);
	    } 

	    // This object is new and should be cached
	    //
	    else {
		s.cache.add(row);
		numNew++;
	    }
	}

	s.addToHistory("retrieveObjectsFromQuery: selected " + nRows + " rows from " + owner + "." + tname + 
		       ", of which " + numNew + " are not in the cache.");
        return objs;
    }

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

    public GUSRow retrieveObject(String session, String owner, String tname, long pk, String clobAtt, Long start, Long end) 
        throws GUSNoConnectionException, GUSObjectNotUniqueException
    {
        Session s = getSession(session);
	GUSRow obj = null;
	
	// Check the cache first
	//
	obj = s.cache.get(owner, tname, pk);

	// Otherwise query the database
	//
	if (obj == null) {
	    try {
		obj = s.conn.retrieveObject(owner, tname, pk, clobAtt, start, end);
	    }
	    catch (RemoteException e) {}

	    if (obj != null) { s.cache.add(obj); }
	    s.addToHistory("retrieveObject: retrieved from db - " + obj);
	} else {

	    // If the requested CLOB substring differs from that stored in the 
	    // cached object then we have to query the database to retrieve
	    // the requested substring.
	    //
	    if (clobAtt != null) {
		// JC: to do
	    }

	    s.addToHistory("retrieveObject: retrieved from cache - " + obj);
	}

	return obj;
    }

    public SubmitResult submitObject(String session, GUSRow obj, boolean deepSubmit) 
        throws GUSNoConnectionException
    {
	SubmitResult sr = new SubmitResult(true, 0, 0, 0, new Vector());
	Session s = getSession(session);
	this.submitObject_aux(s, obj, deepSubmit, sr);
        s.addToHistory("submitObject: submitted " + obj + ", deep submit = " + deepSubmit);
	return sr;

    }

    public GUSRow createObject(String session, String owner, String tname) 
        throws GUSNoConnectionException 
    {
	Session s = getSession(session);
	GUSRow newObj = GUSRow.createObject(owner, tname);

	// Set default properties for the session
	//
	Enumeration e = s.defaults.keys();
	while (e.hasMoreElements()) {
	    String key = (String)(e.nextElement());
	    Object value = s.defaults.get(key);
	    newObj.set(key, value);
	}

	s.addToHistory("createObject: created new object " + newObj);
        return newObj;
    }

    // JC: retrieveParent, retrieveChild, and retrieveChildren should be 
    // rewritten to rely on retrieveObject and retrieveObjectsFromQuery
    // (with some post-processing to make the setChild/setParent calls)
	    
    public GUSRow retrieveParent(String session, GUSRow row, String owner, String tname, String childAtt)
	throws GUSNoConnectionException, GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	Session s = getSession(session);
	GUSRow parent = null;
	try {
	    parent = s.conn.retrieveParent(row, owner, tname, childAtt);
	} catch (RemoteException re) {}

	GUSRow obj = s.cache.get(parent);

	if (obj != null) { 
	    parent = obj;
	} else {
	    s.cache.add(parent);
	}

	s.addToHistory("retrieveParent: retrieved parent row " + parent + " for child row " + row);

	// TO DO: make sure this works even if the parent-child relationship has already
	// been established.
	row.addParent(parent);
	parent.addChild(row);
        return parent;
    }

    public GUSRow[] retrieveParentsForAllObjects(String session, Vector children, String parentOwner, 
						 String parentName, String childAtt)
	throws GUSNoConnectionException, GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	GUSRow parents[] = null;
	Session s = getSession(session);

	try {
	    parents = s.conn.retrieveParentsForAllObjects(children, parentOwner, parentName, childAtt);
	}
	catch (RemoteException re) {}
	int nc = (children == null) ? 0 : children.size();

	if (parents != null) {
	    int np = parents.length;

	    for (int i = 0;i < np;++i) {
		GUSRow obj = s.cache.get(parents[i]);
		
		if (obj != null) {
		    parents[i] = obj;
		} else {
		    s.cache.add(parents[i]);
		}

		// Can't be sure that the correspondence is correct unless the correct
		// number of parents were retrieved, namely one for each child
		//
		if (nc == np) {
		    GUSRow child = (GUSRow)(children.elementAt(i));
		    child.addParent(parents[i]);
		    parents[i].addChild(child);
		}
	    }
	}

	s.addToHistory("retrieveParentsForAllObjects: retrieved " + parents.length + " " + 
		       parentOwner + "." + parentName + " object(s) for " + nc + " child row(s)");
	return parents;
    }

     public GUSRow retrieveChild(String session,  GUSRow row, String owner, String tname, String childAtt)
         throws GUSNoConnectionException, GUSNoSuchRelationException, GUSObjectNotUniqueException
    {
	Session s = getSession(session);
	GUSRow child = null;
	try {
	    child = s.conn.retrieveChild(row, owner, tname, childAtt);
	} catch (RemoteException re) {}
	GUSRow obj = s.cache.get(child);

	if (obj != null) { 
	    child = obj;
	} else {
	    s.cache.add(child);
	}

	s.addToHistory("retrieveChild: retrieved child " + child + " for parent " + row + ", childAtt=" + childAtt);

	// TO DO: make sure this works even if the parent-child relationship has already
	// been established.
	row.addChild(child);
	child.addParent(row);
        return child;
    }

    public Vector retrieveChildren(String session, GUSRow row, String owner, String tname, String childAtt) 
	throws GUSNoConnectionException, GUSNoSuchRelationException
    {
	Session s = getSession(session);
        Vector children = null;
	try {
	    children = s.conn.retrieveChildren(row, owner, tname, childAtt);
	} catch (RemoteException re) {}
	int nc = (children == null) ? 0 : children.size();
	int numNew = 0;  // Number of objects not already in the cache

	for (int i = 0;i < nc;++i) {
	    GUSRow child = (GUSRow)(children.elementAt(i));
	    GUSRow co = s.cache.get(child);

	    // This object is not new; it should be returned in place of child
	    // 
	    if (co != null) {
		children.setElementAt(co, i);
		row.addChild(co);
		co.addParent(row);
	    } 

	    // This object is new and should be cached
	    //
	    else {
		s.cache.add(child);
		numNew++;
		row.addChild(child);
		child.addParent(row);
	    }

	}

	s.addToHistory("retrieveChildren: retrieved " + nc + " child rows for " + row + ", childAtt=" + 
		       owner + "." + tname + "." + childAtt + ", of which " + numNew + " are not in the cache");
	return children;
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
     * Helper method for submitObject.  It updates the SubmitResult in place to 
     * indicate the actions that it has performed.
     *
     * @return Whether the submit succeeded
     */
    protected boolean submitObject_aux(Session s, GUSRow obj, boolean deepSubmit, SubmitResult sr) {
	
	// First submit the object itself
	//
	SubmitResult sres = null;
	try {
	    sres = s.conn.submitObject(obj);
	} catch (RemoteException re) {
	    return false;
	}

	sr.update(sres);

	if (!sr.submitSucceeded()) {
	    return false;
	}

	// Update the object to reflect the fact that it is now up-to-date
	// with respect to the database.

	// JC: to do

	// If the submit succeeded and deepSubmit == true then we
	// must also submit the object's children.
	//
	if (sr.submitSucceeded && deepSubmit) {
	    Vector kids = obj.getAllChildren();
	    Iterator e = kids.iterator();

	    while (e.hasNext()) {
		GUSRow kid = (GUSRow)(e.next());

		// Abort as soon as a submit fails
		//
		if (!submitObject_aux(s, obj, deepSubmit, sr)) {
		    return false;
		}

		// JC: Update parent/child relationships based on results
		// of submit.  Need to be careful since we're in the
		// middle of an iteration.

		// JC: to do
	    }
	}
	return true; // succeeded
    }

} //GUSServer

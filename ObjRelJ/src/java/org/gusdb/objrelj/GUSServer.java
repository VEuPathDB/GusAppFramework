package org.gusdb.objrelj;

import java.util.*;
import java.lang.*;
import java.rmi.*;
import java.rmi.server.*;
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
 * a <b>remote</b> object.
 *
 * Created: Wed May 15 12:02:00 2002
 *
 * @author Sharon Diskin, Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class Server implements ServerI {

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------
    
    // JC: replace this with system-wide debugging/logging mechanism
    //
    protected boolean debug = true;

    /**
     * Stores all the active sessions; maps from sessionId to Session.
     */
    protected Hashtable sessions = new Hashtable();

    /**
     * JDBC connection info.
     */ 
    protected String jdbcUrl;
    protected String jdbcUser;
    protected String jdbcPassword;

    // ------------------------------------------------------------------
    // Session inner class
    // ------------------------------------------------------------------

    /**
     * Inner class that stores information on a single session
     */
    class Session {

	/**
	 * Database login/username.
	 */
        String user;

	/**
	 * Password for <code>user</code>.
	 */
        String password;

	/**
	 * Unique session ID used by the client to identify itself.
	 */
        String session;

	/**
	 * The value from core.UserInfo.user_id that corresponds to
	 * <code>user</code>.  Only set if valid login information has
	 * been provided.
	 */
        int userid;

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
        GUS_JDBC_Server conn;
	
	/**
	 * Constructor
	 *
	 * @param user     Database login/username.
	 * @param password Database password.
	 * @param session  Unique (and hopefully hard-to-guess) ID for the new session.
	 */
        Session (String jdbcUrl, String jdbcUser, String jdbcPassword, String user, String password, String session) 
            throws RemoteException, GUSNoConnectionException
        {
            this.user = user;
            this.password = password;
            this.session = session;
            conn = new GUS_JDBC_Server(jdbcUrl, jdbcUser, jdbcPassword);
            opened = new java.util.Date();
            history.add(opened.toString() + ": Connection opened");       
            this.userid = conn.checkValidUser(this.user, this.password);

            if (this.userid <= 0) {
                conn.closeConnection();
                throw new GUSInvalidLoginException("Invalid username/password!");
            } else {
                conn.setDefaultRowUserId(new Integer(this.userid));
            }
        }

	protected void addToHistory(String item) {
	    java.util.Date now = new java.util.Date();
	    String nowStr = now.toString();
	    String newItem = nowStr + ": " + item;
	    history.add(newItem);
	    this.lastUsed = now;
	    if (debug) System.err.println(newItem);
	}

    } //Session

    // ------------------------------------------------------------------
    // Constructors
    // ------------------------------------------------------------------

    /**
     * Constructor
     */
    public GUSServer(String jdbcUrl, String jdbcUser, String jdbcPassword) throws RemoteException {
        super();
	this.jdbcUrl = jdbcUrl;
	this.jdbcUser = jdbcUser;
	this.jdbcPassword = jdbcPassword;
    }

    // ------------------------------------------------------------------
    // ServerI
    // ------------------------------------------------------------------

    public String openConnection(String user, String password) throws RemoteException, GUSInvalidLoginException
    {
	long suff = (new java.util.Date()).getTime();
	// JC: This is not guaranteed to be unique, although it probably will be
	String session = user + "_" + suff;
	Session s = new Session(jdbcUrl, jdbcUser, jdbcPassword, user, password, session);
	sessions.put(session, s);
	return session;
    }

    public void closeConnection(String session) throws RemoteException, GUSNoConnectionException {
        Session s = getSession(session);
        s.conn.closeConnection();
        sessions.remove(s);
    }

    public List getSessionHistory(String session) throws RemoteException, GUSNoConnectionException
    {
        Session s = getSession(session);
	return new ArrayList(s.history);
    }
    
    public GUSRow retrieveObject(String session, String owner, String tname, long pk) 
        throws RemoteException, GUSNoConnectionException
    {
        Session s = getSession(session);
	GUSRow obj = null;

	try {
	     obj = s.conn.getObject(owner, tname, pk);
	}
	catch (Exception e) {
	    e.printStackTrace();
	}

	s.addToHistory("retrieveObject: retrieved " + obj);
	return obj;
    }

    public Vector retrieveAllObjects(String session, String owner, String tname) 
        throws RemoteException, GUSNoConnectionException
    {
        Session s = getSession(session);
        Vector objs = s.conn.getAllObjects(owner, tname);

	int nRows = (objs == null) ? 0 : objs.size();
	s.addToHistory("retrieveAllObjects: retrieved " + nRows + " rows from " + owner + "." + tname);
        return objs;
    }
    
    public Vector retrieveGusRowsFromQuery(String session, String query, String owner, String tname)
	throws RemoteException, GUSNoConnectionException
    {
	Session s = getSession(session);
	Vector gusRows = null;
	try {
	    gusRows = s.conn.getGusRowsFromQuery(query, owner, tname);
	}
	catch (Exception e) {
	    e.printStackTrace();
	}

	int nRows = (gusRows == null) ? 0 : gusRows.size();
	s.addToHistory("retrieveGusRowsFromQuery: retrieved " + nRows + " from " + owner + "." + tname + ", sql='" + query + "'");
	return gusRows;
    }

    public GUSRow retrieveObject(String session, String owner, String tname, long pk, String clobAtt, Long start, Long end) 
        throws RemoteException, GUSNoConnectionException
    {
	Session s = getSession(session);
	GUSRow obj = null;

	try {
	    obj = s.conn.getGUSRow(owner, tname, pk, false, start, end);
	}
	catch (Exception e){
	    e.printStackTrace();
	}

	s.addToHistory("retrieveObject: retrieved " + obj + ", cached " + clobAtt + " start=" + start + " end=" + end);
	return obj;
    }

    public int submitObject(String session, GUSRow obj) 
        throws RemoteException, GUSNoConnectionException, SQLException
    {
	Session s = getSession(session);
        int rowcount = s.conn.submitObject(obj);

        s.addToHistory("submitObject: submitted " + obj + ", updated/inserted " + rowcount + " row(s)");
	return rowcount;
    }

    public GUSRow createObject(String session, String owner, String tname) 
        throws RemoteException, GUSNoConnectionException 
    {
	Session s = getSession(session);
	GUSRow obj = null;
        try{
	    obj = s.conn.createObject(owner, tname);
	}
	catch (Exception e){
	    e.printStackTrace();
	    System.err.println(e.getMessage());
	}

	s.addToHistory("createObject: created new object " + obj);
        return obj;
    }
	    
    public GUSRow retrieveParent(String session,  GUSRow row, String owner, String tname, String childAtt)
	  throws RemoteException, GUSNoConnectionException
    {
	Session s = getSession(session);
	GUSRow parent = s.conn.getParent(row, owner, tname, childAtt);

	s.addToHistory("retrieveParent: retrieved parent row " + parent + " for child row " + row);
        return parent;
    }

    // JC: this won't work over RMI because it requires call-by-reference semantics
    /*
    public void retrieveParentsForAllObjects(String session, Vector children, String parentOwner, 
					     String parentName, String childAtt)
	throws RemoteException, GUSNoConnectionException
    {
	Session s = getSession(session);

	try {
	    s.conn.getParentsForAllObjects(children, parentOwner, parentName, fkName, hasSequence);
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
	
	s.addToHistory("retrieveParentsForAllObjects: retrieved " + parentOwner + "." + parentName + 
		       " objects for " + nc + " child row(s)");
    }
    */

     public GUSRow retrieveChild(String session,  GUSRow row, String owner, String tname, String childAtt)
         throws RemoteException, GUSNoConnectionException 
    {
	Session s = getSession(session);
	GUSRow child = s.conn.getChild(row, owner, tname, childAtt );
	s.addToHistory("retrieveChild: retrieved child " + child + " for parent " + row + ", childAtt=" + childAtt);
        return child;
    }

    public Vector retrieveChildren(String session, GUSRow row, String owner, String tname, String childAtt) 
	throws RemoteException, GUSNoConnectionException
    {
	Session s = getSession(session);
        Vector children = s.conn.getChildren(row, owner, tname, childAtt);

	int nc = (children == null) ? 0 : children.size();
	s.addToHistory("retrieveChildren: retrieved " + nc + " child rows for " + row + ", childAtt=" + 
		       owner + "." + tname + "." + childAtt);
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

    // ------------------------------------------------------------------
    // main()
    // ------------------------------------------------------------------

    /**
     * A trivial GUSServer daemon; creates a GUSServer instance and binds it
     * in the local RMIRegistry.
     */
    public static void main(String[] args) 
    {
        try {
	    // JC: hack - hard-coded JDBC connection info.
            GUSServer server = new GUSServer("jdbc:oracle:thin:@nemesis:1521:gus", "gusreadonly", "s7fp4erv");
            String name = System.getProperty("gusservername", "GUSServer_1") ;
            Naming.rebind(name, server);
            System.out.println(name + " is bound in RMIRegistry and ready to serve.");
        } 
        catch ( Exception e ) {
            System.err.println(e);
            System.err.println("Usage: java [-Dgusservername=<name>] org.gusdb.objrelj.GUSServer");
            System.exit(1); // Force exit because there may be hanging RMI threads.
        }
    }

} // GUSServer

package org.gusdb.objrelj;

/**
 * DatabaseConnectionI.java
 *
 * An API that describes the minimum functionality required of a 
 * GUS database connection by the Java object layer.  Note that
 * the methods in this interface are very similar to those that 
 * appear in <code>GUSServerI</code>.  However, the methods 
 * described in this interface are not required to implement the 
 * caching behavior described in <code>GUSServerI</code>.
 *
 * @author Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public interface DatabaseConnectionI {

    /**
     * Retrieve a single object from the database, and only retrieve as much of the
     * specified CLOB value as indicated by <code>start</code> and <code>end</code>, 
     * if <code>clobAtt != null</code>.
     */
    public GUSRow retrieveObject(String owner, String tname, long pk, String clobAtt, Long start, Long end);

    /**
     * Retrieve a set of GUSRow objects using an SQL query.
     */
    public Vector retrieveGusRowsFromQuery(String owner, String tname, String query);

    /**
     * Submit a <b>single</b> object to the database.
     */
    public SubmitResult submitObject(GUSRow obj);

    /**
     * Retrieve a row (parent) referenced by another.
     */
    public GUSRow retrieveParent(GUSRow row, String owner, String tname, String childAtt);
	
    /**
     * Retrieve all the parent rows for a set of child rows.
     */
    public GUSRow[] retrieveParentsForAllObjects(Vector children, String parentOwner, String parentName, String childAtt);

    /**
     * Retrieve the single row in a given table (child) that references a specified row (the parent.)
     */
    public GUSRow retrieveChild(GUSRow row, String owner, String tname, String childAtt);
	
    /**
     * Retrieve all rows in a given table (children) that reference a specified row (the parent).
     */
    public Vector retrieveChildren(GUSRow row, String owner, String tname, String childAtt);

} // DatabaseConnectionI

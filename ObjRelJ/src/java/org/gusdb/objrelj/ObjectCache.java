package org.gusdb.objrelj;

import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

/**
 * ObjectCache.java
 *
 * Used by the GUS_JDBC_Server to cache GUS objects, using their Java 
 * class name and primary key value as a unique key.  Also currently 
 * used in GUSRow to store each row's parent and child objects.
 *
 * Created: Tues June 14 12:56:00 2002
 *
 * @author Sharon Diskin, Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class ObjectCache implements java.io.Serializable {

    private static final long serialVersionUID = 1L;

    // ------------------------------------------------------------------
    // Static variables
    // ------------------------------------------------------------------

    static private int DEFAULT_MAX_OBJECTS = 10000;

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    /**
     * A Hashtable of <code>GUSRow</code> objects, keyed by Java 
     * class name + primary key value.
     */
    private Hashtable<String, GUSRow> objects;

    /**
     * Maximum number of unique objects that can be stored in the object 
     * cache; an exception will be raised if an attempt is made to store 
     * more than this number of objects.  If set to < 0, then there is
     * no limit on the number of objects.
     */
    private int maxObjects;

    // ------------------------------------------------------------------
    // Constructors
    // ------------------------------------------------------------------

    /**
     * Constructor
     *
     * @param mo   Maximum number of objects that can be stored in the cache.
     */
    public ObjectCache(int mo) {
	this.objects = new Hashtable<>();
	this.maxObjects = mo;
    } 
    
    /**
     * JavaBean constructor.
     */
    public ObjectCache() {
	this(DEFAULT_MAX_OBJECTS);
    }

    // ------------------------------------------------------------------
    // Public methods
    // ------------------------------------------------------------------

    /**
     * @return The number of unique objects currently stored in the cache.
     */
    public int getNumObjs() {
	return this.objects.size();
    }
    
    /**
     * Change the maximum number of objects that can be stored.
     * 
     * @param mo  New maximum number of objects.
     */
    public void setMaxObjects( int mo ) {
	if (mo > getNumObjs()) {
	    throw new IllegalArgumentException("ObjectCache: setMaxObjects called with value greater than getNumObjs()");
	} 
	this.maxObjects = mo;
    }
    
    /**
     * @return The current maximum number of objects.
     */
    public int getMaxObjects() {
	return this.maxObjects;
    }
    
    /**
     * Clear the cache.
     */
    public void clear() {
	this.objects.clear();
    }
    
    /**
     * Add a single GUSRow object to the cache.
     * 
     * @param obj   GUSRow object to add to the cache.
     */
    public void add(GUSRow obj) {
	if ((this.maxObjects > 0) && (getNumObjs() + 1 > this.maxObjects)) {
	    throw new IllegalArgumentException("ObjectCache: cache is full");
	}	String key = getKey(obj);
	System.out.println("adding object with key " + key + " to cache");
	this.objects.put(key, obj);
    }

    /**
     * Retrieve a single GUSRow object from the cache.
     *
     * @param owner    Owner of the table of the object to retrieve.
     * @param tname    Table of the object to retrieve.
     * @param pk       Primary key value of the object to retrieve.
     * @return The requested object, if in the cache, null otherwise.
     */
    public GUSRow get(String owner, String tname, long pk) {
	String obj_key = getKey(owner, tname, pk);
	System.err.println("attempting to retrieve object with key " + obj_key + " from cache");
	return objects.get(obj_key);
    }
    
    /**
     * Retrieve a single GUSRow object from the cache.
     *
     * @param obj  An object with the same owner, table name, and primary key as the one to retrieve.
     * @return The requested object, if in the cache, null otherwise.
     */
    public GUSRow get(GUSRow obj) {
	if (obj == null) return null;
	String obj_key = getKey(obj);
	return objects.get(obj_key);
    }
    
    /**
     * @return A Vector containing all the GUSRow objects in the cache.
     */
    public Vector<GUSRow> getAll () {
	Enumeration<GUSRow> all = objects.elements();
	int n = objects.size();
	Vector<GUSRow> v = new Vector<>(n);

	while (all.hasMoreElements()) {
	    GUSRow row = all.nextElement();
	    v.addElement(row);
	}
	return v;
    }

    /**
     * Check whether the specified GUSRow is in the cache.
     *
     * @param owner    Owner of the table of the object to check for.
     * @param tname    Table of the object to check for.
     * @param pk       Primary key value of the object to check for.
     * @return true iff the requested object is in the cache.
     */
    public boolean contains(String owner, String tname, long pk) {
	return (this.get(owner, tname, pk) != null);
    }

    /**
     * Check whether the cache already contains a GUSRow object with
     * the same owner, table name, and primary key as the supplied
     * argument.
     *
     * @param obj  An object with the same owner, table name, and primary key as the one to check for.
     * @returns true iff the cache contains such an object.
     */
    public boolean contains(GUSRow obj) {
	System.err.println("ObjectCache.contains: beginning method");
	String obj_key = this.getKey(obj);
	System.err.println("ObjectCache.contains: searching for object in cache with key " + obj_key);
	return (this.get(obj) != null);
    }

    // JC: Generally methods like the following (i.e., remove) will return a 
    // boolean or integer, to let you know if (or how many) objects were 
    // actually removed.

    /**
     * Remove a GUSRow from the cache.
     *
     * @param owner    Owner of the table of the object to remove.
     * @param tname    Table of the object to remove.
     * @param pk       Primary key value of the object to remove.
     * @return The object that was removed from the cache.
     */    
    public GUSRow remove(String owner, String tname, long pk) {
	String obj_key = this.getKey(owner, tname, pk);
	return this.objects.remove(obj_key);
    }
    
    /**
     * Remove a GUSRow from the cache.
     *
     * @param obj  An object with the same owner, table name, and primary key as the one to remove.
     */
    public GUSRow remove(GUSRow obj){
	String obj_key = this.getKey(obj);
	return this.objects.remove(obj_key);
    }

    // ------------------------------------------------------------------
    // Protected methods
    // ------------------------------------------------------------------

    /**
     * @param owner    Owner of the GUSRow's table.
     * @param tname    The GUSRow's table.
     * @param pk       The primary key value of the GUSRow.
     * @return The key used to identify the specified object in the hashtable.
     */
    protected String getKey(String owner, String tname, long pk) {
	String prefix = (owner == null) ? "" : (owner + ".");
	return prefix + tname + "_" + pk;
    }

    /**
     * @param obj   A GUSRow object.
     * @return The key used to identify <code>obj</code> in the hashtable.
     */
    protected String getKey(GUSRow obj) {
	GUSTable t = obj.getTable();
	return getKey(t.getSchemaName(), t.getTableName(), obj.getPrimaryKeyValue());
    }

} //ObjectCache
















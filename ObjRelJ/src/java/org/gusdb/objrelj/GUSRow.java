package org.gusdb.objrelj;

import java.util.*;
import java.lang.*;
import java.io.*;
import java.sql.*;
import java.math.*;

/**
 * GUSRow.java
 *
 * Represents a single row in a GUS table.
 *
 * This is the class that should be subclassed by all GUS objects.
 * It handles the parent-child relationships (i.e., the relational
 * foreign key constraints) and is meant to be the Java analog of
 * the Perl object layer's DBIRow and RelationalRow packages.  One
 * significant difference with the Perl object layer, however, is
 * that in the Java object layer all of the actual database 
 * communication is handled by the GUSServer class, rather than the 
 * individual GUS objects.
 *
 * Created: Tues April 16 12:56:00 2002
 *
 * @author Sharon Diskin, Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$ 
 */
public abstract class GUSRow implements java.io.Serializable {

    // ------------------------------------------------------------------
    // Static variables
    // ------------------------------------------------------------------

    /**
     * The Java package in which the "model" classes (i.e., those that correspond
     * to the tables in the database) of the Java object layer reside.
     */
    public static String MODEL_PACKAGE = "org.gusdb.model";      // perhaps should have config file!

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    // JC: make sure that the attribute names really are all-lowercase

    /**
     * The original values for the attributes of the row.  The attribute names
     * are in all-lowercase.
     */
    protected Hashtable initialAttVals = new Hashtable();

    /**
     * The current values for the attributes of the row.  The attribute names
     * are in all-lowercase.
     */
    protected Hashtable currentAttVals = new Hashtable();

    /**
     * The unique primary key of the row, i.e., the value stored in the 
     * attribute named by <code>table.getPrimaryKeyName()</code>
     */ 
    protected Long id;

    /**
     * "Facts" are rows that provide support for the existence of this row
     * in the database.  For example, if this row assigns a particular activity
     * to a gene, a "fact" supporting that assignment might be a row that 
     * represents the publication where this activity was first reported.  In
     * the database, the dots.Evidence table is used to associate facts with 
     * other rows in the database, so the contents of this hash table actually
     * reflect the contents of the Evidence table (i.e., all those rows in 
     * Evidence that have <b>this</b> row as their target.
     */
    protected Hashtable currentFacts = new Hashtable();
    
    /**
     * Facts that have been associated with this object but have not yet been
     * written into the database.
     *
     * @see currentFacts
     */
    protected Hashtable newFacts = new Hashtable();

    /**
     * Whether this row has been marked for deletion.
     */
    protected boolean isDeleted;

    /**
     * Whether this row is newly created (i.e., versus having been retrieved from the db.)
     */
    // JC: Is this redundant?  Isn't a row "new" iff it has no primary key value.
    protected boolean isNew;

    /**
     * Whether any of the attributes of the row have been updated; the updated values
     * themselves are stored in <code>currentAttVals</code>.
     */
    protected boolean hasChangedAtts;

    // JC: See if we can replace these ObjectCaches with something lighter-weight
    //     might also considering not initializing these variables until we have some
    //     children or parents to store.

    /**
     * Children of this row, i.e., rows that reference it.
     */
    protected ObjectCache children = new ObjectCache();

    /**
     * Parents of this row, i.e., rows that it references.
     */
    protected ObjectCache parents = new ObjectCache();

    // ------------------------------------------------------------------
    // Constructors
    // ------------------------------------------------------------------

    /**
     * Constructor
     */
    public GUSRow() {
	this.isNew = true;       // will be set to false if setAttributesFromResultSet called
	this.isDeleted = false;
	this.hasChangedAtts = false;
    }

    // ------------------------------------------------------------------
    // Static methods
    // ------------------------------------------------------------------

    /**
     * Create a new object of the specified class.
     */
    public static GUSRow createObject(String owner, String tname) {
	String rowClassName = GUSRow.MODEL_PACKAGE + "." + owner + "." + tname;
	try {
	    Class rowClass = Class.forName(rowClassName);
	    return (GUSRow)rowClass.newInstance();
	} 
	catch (ClassNotFoundException cnfe) {
	    cnfe.printStackTrace(System.err);
	}
	catch (InstantiationException ie) {
	    ie.printStackTrace(System.err);
	}
	catch (IllegalAccessException iae) {
	    iae.printStackTrace(System.err);
	}

	return null;
    }

    // ------------------------------------------------------------------
    // Abstract methods
    // ------------------------------------------------------------------

    /**
     * @return The table in which this row belongs.
     */
    public abstract GUSTable getTable();

    /**
     * A helper method needed because <code>setAttributesFromResultSet</code>
     * must have package scope.
     *
     * @param res           The result set that contains values for this row.
     * @param specialCases  Hashtable that specifies special-case handling for one or
     *                      more of the row's CLOB or BLOB columns.  Indexed by attribute
     *                      name, it contains a null value if the corresponding CLOB or BLOB
     *                      attribute should not be retrieved at all.  Otherwise it contains
     *                      an object of type CacheRange that specifies which part of the 
     *                      CLOB or BLOB to cache locally.  May be null if there are no 
     *                      special cases (i.e., all CLOBs and BLOBs should be retrieved in
     *                      their entirety.)
     */
    protected abstract void setAttributesFromResultSet_aux(ResultSet res, Hashtable specialCases);

    // ------------------------------------------------------------------
    // Public methods
    // ------------------------------------------------------------------
    
    /**
     * Set an attribute to a particular value.  Note that this only affects 
     * <code>currentAttVals</code>, not <code>initialAttVals</code>, until the row
     * is written to the database.  The original values are retained so that
     * we know which attributes have changed and must be updated, in the case
     * of an SQL update.
     *
     * @param key   The name of the attribute to be changed.
     * @param val   The new value for the attribute named by <code>key</code>.
     */
    public void set( String key, Object val ) { 
	String lcKey = key.toLowerCase();

	try {

	    // To indicate a null value we remove the key from the 
	    // currentAttVals hashtable.
	    //
	    if (val == null) {
		currentAttVals.remove(lcKey);
	    }
	    else {

		// If the attribute being set is the primary key column we throw
		// an exception, since the primary key value shouldn't be set by
		// users in the public interface.
		//
		if (lcKey.equals(getTable().getPrimaryKeyName())) {
		    throw new IllegalArgumentException("Not allowed to change primary key value using set()");
		} 
		else {
		    this.currentAttVals.put(lcKey, val);
		    this.hasChangedAtts = true;
		}
	    }
	}

	// JC: Do we want to fail silently here?
	catch ( NullPointerException e ) {}
    }

    /**
     * Get the <I>current</I> value of an attribute.
     *
     * JC: If used on a CLOB/BLOB value, this method will ONLY return the cached portion of the LOB.
     *
     * @param key   The name of the attribute to get.
     * @return The requested attribute value.
     */
    public Object get( String key ) {
	return currentAttVals.get(key.toLowerCase());
    }

    /**
     * @return Whether any of this row's attributes have been changed from their initial values.
     */
    public boolean hasChangedAtts() {
	return hasChangedAtts;
    }

    /**
     * @return Whether this row is new, i.e., has not yet been connected
     * with a row in the database via its <code>id</code>.
     */
    public boolean isNew() {
	return this.isNew;
    }

    /**
     * @return The unique primary key value for the row.  Will return
     * -1 iff <code>isNew()</code>.
     */
    public long getPrimaryKeyValue() {
	return (id == null) ? -1 : id.longValue();
    }
    
    /**
     * Add a child to this row.
     *
     * @param c  The child row.
     */
    public void addChild(GUSRow c){
	// TO DO:
	//  check that this is a valid child (using GUSTableRelations in table)
	//  set the referencing attribute in the child row, if:
	//    1. this row has a valid id (primary key)
	//    2. it does not already point to this row
	//  have a useful return value
	this.children.add(c);
    }  
    
    // JC: shouldn't this be setParent, not addParent?

    /**
     * Add a parent for this row.
     *
     * @param c  The parent row.
     */
    public void addParent(GUSRow c){
	// TO DO:
	// same as above, more or less
	this.parents.add(c);
    }

    // JC: Note that all of these get methods only operate on the child and
    // parent objects that have been cached in the row (versus those that may
    // exist in the database.)  Should we rename these methods to make this
    // clearer?

    /**
     * @return A Vector containing all of the child GUSRow objects that have been
     * added to this object so far.  Does not query the database.
     */
    public Vector getAllChildren(){
	return children.getAll();
    }

    // JC: why does this method (and the next) take the primary key as an argument?
    // JC: this can't be correct because before an object has been submitted to the
    // database it won't have a primary key value.

    /**
     * Retrieve a unique child of this row.  (i.e., the sole row from the specified
     * table that references this row.)  Will throw an exception if the specified 
     * table contains multiple rows that reference this one.  Does not query the
     * database.
     *
     * @param cowner   The owner of the child table.
     * @param cname    Name of the child table
     * @param pk       Primary key of the requested child object.
     * @return The requested child row.
     */
    public GUSRow getChild(String cowner, String cname, long pk) {
	// returns the child represented by the cname.  If does
	// not exist throw exception.  Also, throw exception
	// if has two children with the cname.
	return this.children.get(cowner, cname, pk);
    }

    /**
     * Retrieve the parent of this row.  (i.e., the unique row from the specified table 
     * that is referenced by this row.)  Does not query the database.
     *
     * @param cowner   The owner of the parent table.
     * @param cname    Name of the parent table
     * @param pk       Primary key of the requested parent object.
     * @return The requested parent row.
     */
    public GUSRow getParent(String cowner, String cname, long pk) {
	//returns the GUSRow parent Object.
	GUSRow pars = this.parents.get(cowner, cname, pk);
	return pars;
    }

    /**
     * @return A Vector containing of the parent GUSRow objects that have been
     * added to this object so far.   Does not query the database.
     */
    public Vector getAllParents(){
	Vector c = parents.getAll();
	return c;
    }
   
    /**
     * Set the deletion status of this row.  If set to <code>true</code>
     * when the row is next submitted to the database, it will be deleted.
     * 
     * @param d   Whether to delete this row the next time it is submitted.
     */
    public void setDeleted(boolean d){
        isDeleted = d;
    }

    /**
     * @return Whether this row is to be deleted the next time it is submitted
     * to the database.
     */
    public boolean isDeleted(){
        return this.isDeleted;
    }

    /**
     * Dump the current values of this row's attributes in XML.  Does not chase
     * foreign key references.
     *
     * @return An XML string that represents the row.
     */
    public String toXML() {
        StringBuffer xml = new StringBuffer();
        xml.append("<" + this.getTable().getTableName() + ">\n");
	toXML_aux(xml);
        return xml.toString();
    }
    
    /**
     * Dump the current values of this row's attributes in XML.  Also allows
     * one to set the row's "xml_id" and "parent" XML attributes.
     * 
     * @param xml_id      Value for the XML attribute 'xml_id'
     * @param parent_ids  Values for the XML attribute 'parent'
     * @return An XML string that represents the row.
     */
    public String toXML(int xml_id, int[] parent_ids) {
        StringBuffer xml = new StringBuffer();
        // Depending on xml_id and parent_ids, add appropriate elements
        xml.append("<" + this.getTable().getTableName() + " ");
        if (xml_id != -1) {
            xml.append("xml_id=\"" + xml_id + "\" ");
        }
        
	int nParents = (parent_ids == null) ? 0 : parent_ids.length;
        for (int i=0; i < nParents; i++) {
            xml.append("parent=\"" + parent_ids[i] + "\" ");
        }
        xml.append(">\n");
        toXML_aux(xml);
        return xml.toString();
    }

    // ------------------------------------------------------------------
    // Package-scoped methods
    // ------------------------------------------------------------------

    // JC: These methods are inherently unsafe, so access is restricted to
    // other classes in the package.

    Hashtable getInitialAttVals() { return this.initialAttVals; }
    Hashtable getCurrentAttVals() { return this.currentAttVals; }
  
    /**
     * Called (by the factory object that creates new rows) to set the attributes
     * of a row based on a single row in an SQL result set, retrieved from the 
     * database using JDBC.
     *
     * @param res           The result set that contains values for this row.
     * @param specialCases  Hashtable that specifies special-case handling for one or
     *                      more of the row's CLOB or BLOB columns.  Indexed by attribute
     *                      name, it contains a null value if the corresponding CLOB or BLOB
     *                      attribute should not be retrieved at all.  Otherwise it contains
     *                      an object of type CacheRange that specifies which part of the 
     *                      CLOB or BLOB to cache locally.  May be null if there are no
     *                      special cases (i.e., all CLOBs and BLOBs should be retrieved in
     *                      their entirety.)
     */
    void setAttributesFromResultSet(ResultSet res, Hashtable specialCases) {
	this.setAttributesFromResultSet_aux(res, specialCases);
    }

    // ------------------------------------------------------------------
    // Protected methods
    // ------------------------------------------------------------------

    /**
     * Set this row's unique ID.  Requires interaction with the database.
     * Once set it should never change.
     *
     * @param new_id  
     */
    protected void setPrimaryKeyValue(Long newId) {

	// It is illegal to change this row's primary key once it
	// has been set to a non-null value.
	//
	if (this.id != null) {
	    throw new IllegalArgumentException("Row's GusRowId has already been set.");
	}
	id = newId;
    }

    /**
     * Sets the <I>initial</I> value of an attribute to a particular value.
     * Called by a GUSRow subclass to populate <code>initialAttVals</code> with 
     * values from the database when this row is first retrieved from the
     * database.
     *
     * @param key   The name of the attribute to set.
     * @param val   The <I>initial</I> value for the attribute named by <code>key</code>
     */
    protected void setInitial ( String key, Object val ) {
	try {
	    if (val == null) {
		// do nothing; value will not be set
		// i.e., if there is no entry for an attribute in <code>initialAttVals</code>
		// then its value is assumed to be null
	    }
	    else {
		this.initialAttVals.put(key.toLowerCase(), val);

		// JC: If the value being set is the primary key value then
		// we must also update <code>id</code>
	    }
	}
	catch (NullPointerException e) {}
    }

    // JC: can we get rid of this method completely?

    /**
     * Sets the <I>initial</I> values of all the row's attributes.
     *
     * @param vals  Hashtable keyed by lowercase attribute name.
     */
    protected void setInitialAttValues( Hashtable vals ) {
	// needs to check if valid attributes still !! SJD
	this.initialAttVals = vals;
    }

    /**
     * Retrieve a subsequence of the specified CLOB value; throws an
     * Exception if the requested subsequence is not available locally.
     *
     * @param att      The CLOB attribute in question.
     * @param cached   Object that records how much of the CLOB has been cached locally.
     * @param start    Start of subsequence to retrieve, inclusive.
     * @param end      End of subsequence to retrieve, inclusive.
     */
    protected char[] getClobValue(String att, CacheRange cached, long start, long end) {
	char[] value = (char[])this.get(att);
        long cacheStart = 0;
        long cacheEnd = value.length;

	if (cached != null) {
	    if (cached.start != null) {
	        cacheStart = cached.start.longValue();
	    }
	    if (cached.end != null) {
	        cacheEnd = cached.end.longValue();
	    }
        }

        if ((start >= cacheStart) && (start <= cacheEnd) && (end >= cacheStart) && (end <= cacheEnd)) 
        {
	    int localStart = (int)(start - cacheStart);
	    int localEnd = (int)(end - cacheStart);
	    int requestLen = (int)(localEnd - localStart + 1);
	    int ind = 0;

	    char[] result = new char[requestLen];
	    for (int i = localStart; i <= localEnd;++i) {
		result[ind++] = value[i];
	    }
	    
	    return result;
	} else {
	    throw new IllegalArgumentException(this + ": requested CLOB range, " + start + "-" + end + 
					       " is out of range for " + att);
	}
    }

    /**
     * Retrieve a subsequence of the specified BLOB value; throws an
     * Exception if the requested subsequence is not available locally.
     *
     * @param att      The BLOB attribute in question.
     * @param cached   Object that records how much of the BLOB has been cached locally.
     * @param start    Start of subsequence to retrieve.
     * @param end      End of subsequence to retrieve.
     */
    protected byte[] getBlobValue(String att, CacheRange cached, long start, long end) {
	byte[] value = (byte[])this.get(att);
        long cacheStart = 0;
        long cacheEnd = value.length;

	if (cached != null) {
	    if (cached.start != null) {
	        cacheStart = cached.start.longValue();
	    }
	    if (cached.end != null) {
	        cacheEnd = cached.end.longValue();
	    }
        }

        if ((start >= cacheStart) && (start <= cacheEnd) && (end >= cacheStart) && (end <= cacheEnd)) 
        {
	    int localStart = (int)(start - cacheStart);
	    int localEnd = (int)(end - cacheStart);
	    int requestLen = (int)(localEnd - localStart + 1);
	    int ind = 0;

	    byte[] result = new byte[requestLen];
	    for (int i = localStart; i < localEnd;++i) {
		result[ind++] = value[i];
	    }
	    
	    return result;
	} else {
	    throw new IllegalArgumentException(this + ": requested BLOB range, " + start + "-" + end + 
					       " is out of range for " + att);
	}
    }

    /**
     * Set the initial value of a CLOB attribute.
     *
     * @param att            The CLOB attribute in question.
     * @param value          The SQL Clob to use.
     * @param specialCases   Hashtable that specifies which CLOB/BLOB attributes should only be partially retrieved.
     * @return CacheResult object, if only a partial retrieval was performed.
     */
    protected CacheRange setClobInitial(String att, Clob value, Hashtable specialCases) {
	CacheRange result = null;
	Long cacheStart = null;
	Long cacheEnd = null;

	// If the value is null then we simply store the entire value, 
	// regardless of what subsequence was requested by <code>specialCases</code>.
	//
	if (value == null) {
	    // No action required; null will be returned
	} 
	else {

	    // Check whether we've been told to retrieve a specific subsequence
	    //
	    if (specialCases != null) {
		CacheRange whatToCache = (CacheRange)(specialCases.get(att));
		cacheStart = whatToCache.getStart();
		cacheEnd = whatToCache.getEnd();
	    }
	    
	    try {
		long length = value.length();
		long start = (cacheStart == null) ? 0 : cacheStart.longValue();
		long end = (cacheEnd == null) ? length - 1: cacheEnd.longValue();
		boolean isEntireLob = ((start == 0) && (end == (length - 1)));
		
		char[] data = new char[(int)length];
		java.io.Reader r = value.getCharacterStream();
		long offset = 0;

		// Skip to the appropriate location in the stream (start)
		//
		while (offset < start) {
		    long amountSkipped = r.skip(start - offset);
		    offset += amountSkipped;
		}
		
		// Then read the requested range (up to end)
		//
		int arrayPosn = 0;
		while (offset < end) {
		    int amountRead = r.read(data, arrayPosn, (int)(end - offset + 1));
		    if (amountRead == -1) break;
		    arrayPosn += amountRead;
		    offset += amountRead;
		}
		
		if (!isEntireLob) result = new CacheRange(start, end, length);
		setInitial(att, data); 
	    } 
	    catch (SQLException se) {}
	    catch (java.io.IOException ie) {}
	}
	return result;
    }

    /**
     * Set the initial value of a BLOB attribute.
     *
     * @param att            The BLOB attribute in question.
     * @param value          The SQL Blob to use.
     * @param specialCases   Hashtable that specifies which CLOB/BLOB attributes should only be partially retrieved.
     * @return CacheResult object, if only a partial retrieval was performed.
     */
    protected CacheRange setBlobInitial(String att, Blob value, Hashtable specialCases) {
	CacheRange result = null;
	Long cacheStart = null;
	Long cacheEnd = null;

	// If the value is null then we simply store the entire value, 
	// regardless of what subsequence was requested by <code>specialCases</code>.
	//
	if (value == null) {
	    // No action required; null will be returned
	} 
	else {

	    // Check whether we've been told to retrieve a specific subsequence
	    //
	    if (specialCases != null) {
		CacheRange whatToCache = (CacheRange)(specialCases.get(att));
		cacheStart = whatToCache.getStart();
		cacheEnd = whatToCache.getEnd();
	    }
	    
	    try {
		long length = value.length();
		long start = (cacheStart == null) ? 0 : cacheStart.longValue();
		long end = (cacheEnd == null) ? length - 1: cacheEnd.longValue();
		boolean isEntireLob = ((start == 0) && (end == (length - 1)));
		
		byte[] data = new byte[(int)length];
		java.io.InputStream r = value.getBinaryStream();
		long offset = 0;
		
		// Skip to the appropriate location in the stream (start)
		//
		while (offset < start) {
		    long amountSkipped = r.skip(start - offset);
		    offset += amountSkipped;
		}
		
		// Then read the requested range (up to end)
		//
		int arrayPosn = 0;
		while (offset < end) {
		    int amountRead = r.read(data, arrayPosn, (int)(end - offset + 1));
		    if (amountRead == -1) break;
		    arrayPosn += amountRead;
		    offset += amountRead;
		}
		
		if (!isEntireLob) result = new CacheRange(start, end, length);
		setInitial(att, data); 
	    } 
	    catch (SQLException se) {}
	    catch (java.io.IOException ie) {}
	}
	return result;
    }

    /**
     * Check that the specified object is a valid value for given attribute.
     * Throws an exception if not.
     *
     * @param att       Name of one of the attributes in <code>table.getAttributeNames()</code>
     * @param toCheck   The object to check.
     */
    protected void attTypeCheck(String att, Object toCheck)
	throws ClassNotFoundException, InstantiationException, IllegalAccessException, SQLException
    {
	GUSTable table = this.getTable();

	//refactor this after adding length check	
	GUSTableAttribute attInfo = table.getAttributeInfo(att);
	String type = attInfo.getJavaType();
	boolean nullable = attInfo.isNullable();
	
	//check if setting object to null where not allowed
	if (toCheck == null && !nullable) {
	    throw new IllegalArgumentException("GUSRow:  Attempted to set " + att + " as NULL");
	}
	Class c = Class.forName(type);

	//check type, if not null
	if (toCheck != null) {
	    if (!(c.equals(toCheck.getClass()))){
		throw new IllegalArgumentException("GUSRow:  Attempted to set " + att +
						   " (type " + type + ") with invalid type  " +
						   toCheck.getClass().getName() );
	    } 
	}

	checkLength(att, toCheck);	
    }								       

    /**
     * Check that the specified value <code>o</code> is not larger than the 
     * maximum value allowed by the attribute named <code>att</code>.  Assumes
     * that the value is of the type required by the attribute.  Throws an 
     * exception if the value is too large.
     *
     * @param att    The name of one of this row's attributes.
     * @param o      A value of the type appropriate for storing in the attribute <code>att</code>.
     */
    protected void checkLength (String att, Object o) 
	throws ClassNotFoundException, InstantiationException, IllegalAccessException, SQLException
    {
	GUSTable table = this.getTable();
	GUSTableAttribute attInfo = table.getAttributeInfo(att);

	if (o instanceof String){
	    if (((String)o).length() > attInfo.getLength()){

		// JC: should use a debugging/logging facility instead of doing straight printlns
		System.out.println ("your length is " + ((String)o).length() + " correct length is " + attInfo.getLength());
		throw new IllegalArgumentException("GUSRow:  set length of " + att + " too long! ");
	    }
	}
	else if (o instanceof Short || o instanceof Integer || o instanceof Long){
	    String numString = o.toString();
	    //System.out.println("o.toString() produces value " + numString);
	    if (numString.length() > attInfo.getPrecision()){
		throw new IllegalArgumentException("GUSRow:  set precision of " + att + " too big!");
	    }
	}

	// JC: does the maximum length of a clob column get set correctly in GUSTableAttribute?
	// No - needs to be fixed.

	else if (o instanceof Clob){
	    Clob oClob = (Clob)o;
	    if (oClob.length() > attInfo.getLength()){
		throw new IllegalArgumentException("GUSRow:  set length of " + att + "too long!");
	    }
	}
	else if (o instanceof Blob){
	    Blob oBlob = (Blob)o;
	    if (oBlob.length() > attInfo.getLength()){
		throw new IllegalArgumentException("GUSRow:  set length of " + att + "too long!");
	    }
	}
	else if (o instanceof Double){
	    Double p_check = (Double)o; 
	    String sp_check = p_check.toString();
	    if (sp_check.length() > attInfo.getPrecision()){
		throw new IllegalArgumentException("GUSRow:  set precision of " + att + "too big!");
	    }
	    
	    Double d = new Double( (((Double)o).doubleValue() % 1));
	    String sd = d.toString();
	    if (sd.length() > attInfo.getScale()){
		throw new IllegalArgumentException("GUSRow:  set scale of " + att + "too long!");
	    }
	}
	else if (o instanceof Float){
	    Float p_check = (Float)o; 
	    String sp_check = p_check.toString();
	    if (sp_check.length() > attInfo.getPrecision()){
		throw new IllegalArgumentException("GUSRow:  set precision of " + att + "too big!");
	    }
	    
	    Float f = new Float( (((Float)o).floatValue() % 1));
	    String sf = f.toString();
	    if (sf.length() > attInfo.getScale()){
		throw new IllegalArgumentException("GUSRow:  set scale of " + att + "too long!");
	    }
	}
	else if (o instanceof BigDecimal){
	    String bd = (((BigDecimal)o).toString());
	    if (bd.length() > attInfo.getLength()){
		throw new IllegalArgumentException("GUSRow:  set length of " + att + "too long!");
	    }
	}

	//need to check boolean once special cases table is implemented
	//not sure if need to check date; may want to check that on higher level
	//BigDecimal encodes for some floats that have 126 precision and 22 length; 
	//      checking the limiting factor for that one (length)
	//Also, when converting to string does the decimal point count as 1 when checking 
	//length of that string?  If so need to allow 1 more in object's length for some.
    }

    // ------------------------------------------------------------------
    // Private methods
    // ------------------------------------------------------------------

    /**
     * Called from <code>toXML()</code>; prints the attributes of the row
     * into a StringBuffer in XML format.
     *
     * @param xml  XML string to append the object's attributes to.
     * @see toXML
     */
    private void toXML_aux(StringBuffer xml) {
        Enumeration keys = currentAttVals.keys();

        while( keys.hasMoreElements() ) {
            String next = (String)(keys.nextElement());
	    Object nextval = currentAttVals.get(next);
	    String nextstr = nextval.toString();

	    // JC: why don't we print an attribute if its value is -1 or the empty string???
	    //     aren't these perfectly valid values in many attributes?

	    if ( !nextstr.equals("") && !nextstr.equals("-1") ) { 
                xml.append("  <" + next + ">");
		xml.append(nextstr);
		xml.append("</" + next + ">" +  "\n");
            }
        }
        xml.append("</" + this.getTable().getTableName() + ">" + "\n");
    }

    // ------------------------------------------------------------------
    // java.lang.Object
    // ------------------------------------------------------------------

    public String toString() {
	GUSTable table = this.getTable();
	return "[" + table + ":" + id + "]";
    }


} //GUSRow

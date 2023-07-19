package org.gusdb.objrelj;

import java.math.BigDecimal;
import java.sql.Blob;
import java.sql.Clob;
import java.sql.SQLException;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;
import java.util.logging.Logger;

/**
 * GUSRow.java
 *
 * Represents a single row in a GUS table.
 *
 * This is the class that should be subclassed by all GUS objects.
 * It handles the parent-child relationships (i.e., the relational
 * foreign key constraints) and is meant to be the Java analog of
 * the Perl object layer's DBIRow and RelationalRow packages.  
 *
 * An instance of a GUSRow should be created through a GUS object
 * subclass with a ServerI object.  The ServerI object handles all
 * communication between the GUSRow and the database or object cache.
 *
 * Created: Tues April 16 12:56:00 2002
 *
 * @author Sharon Diskin, Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$ 
 */
public abstract class GUSRow implements java.io.Serializable {

    private static final long serialVersionUID = 1L;

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

    /**
     * ServerI object that handles all communication with the database.
     */
    protected ServerI server;

    /**
     * String representing the particular Session with the server to which this GUSRow belongs.
     */
    protected String sessionId;


    /**
     * The current values for the attributes of the row.  The attribute names
     * are in all-lowercase.
     */
    protected Hashtable attributeValues = new Hashtable();


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
     * Whether this row has been retrieved from the database or is newly created.
     */

    protected boolean isEager;
    
    /**
     * Whether any of the attributes of the row have been updated; the updated values
     * themselves are stored in <code>attributeValues</code>.
     */
    protected boolean hasChangedAtts;

    /**
     * A Hashtable of Vectors; each of the contained Vectors holds a list of GUSRows that are all of the same 
     * type.  Each of these GUSRows are those that have foreign keys to this GUSRow.  Children have 
     * protected access through the <code>getChildren()</code> method in this class.  To get individual
     * Vectors of children, use the child accessors in the GUSRow subclasses.
     */
    protected Hashtable children; //DTB update documentation for this

    /**
     * A Vector containing GUSRows that represent all the foreign key rows of this GUSRow, regardless
     * of type.  They have protected access through the <code>getParents()</code> method in this class.
     * To get individual parents, use the parent accessors in the GUSRow subclasses.
     */
    protected Vector parents;


    //TO DO - determine if logger will work when passed over RMI.  
    //Also- Could have each GusTable for specific classes have its own logger
    //and each GUSRow for specific classes access that.

    /**
     * Logger from java.util.logging package.
     */
    protected Logger logger; 

    // ------------------------------------------------------------------
    // Constructors
    // ------------------------------------------------------------------

    /**
     * Constructor
     */
    public GUSRow(){}


    public GUSRow(ServerI server, String sessionId) {
	this.server = server;
	this.sessionId = sessionId;
	this.isEager = false;
	this.isDeleted = false;
	this.hasChangedAtts = false;
	parents = new Vector();
	children = new Hashtable();
    }

    private void initialize(){
	parents = new Vector();
	children = new Hashtable();
    }
    

    // ------------------------------------------------------------------
    // Static methods
    // ------------------------------------------------------------------

    /**
     * Create a new object of the specified class.
     */
    public static GUSRow createGUSRow(GUSTable table) {
	String rowClassName = GUSRow.MODEL_PACKAGE + "." + table.getSchemaName() + "." + table.getTableName();
	try {
	    Class rowClass = Class.forName(rowClassName);
	    GUSRow gr = (GUSRow)rowClass.newInstance();
	    gr.initialize();
	    return gr;
	} 
	catch (ClassNotFoundException cnfe) {
	    cnfe.printStackTrace(System.err);
	}
	catch (InstantiationException ie) {
	    System.err.println("caught instantiation exception");
	    System.err.println(ie.getMessage());
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
    protected abstract void setAttributesFromHashtable_aux(Hashtable rowHash, Hashtable specialCases);

    // ------------------------------------------------------------------
    // Public methods
    // ------------------------------------------------------------------

    protected void setServer(ServerI server){
	this.server = server;
    }
    protected void setSessionId(String session){
	this.sessionId = session;
    }

    public String getSubclassViewTableName(BigDecimal fk, String parentOwner, String parentTable){
	if (fk == null){
	    return null;
	}
	String subclassTable = null;
	try{
	    GUSTable table = GUSTable.getTableByName(parentOwner, parentTable);
	    String parentPkName = table.getPrimaryKeyName();
	    String sqlQuery = "select subclass_view from " + parentOwner + "." + parentTable + "Imp" + 
		" where " + parentPkName + " = " + fk.longValue();

	    Vector result = server.runSqlQuery(sessionId, sqlQuery);
	    
	    Hashtable hashResult = (Hashtable)result.elementAt(0);
	    subclassTable = (String)hashResult.get("subclass_view");
	}
	catch (Exception e){
	    System.err.println(e.getMessage());
	    e.printStackTrace();
	}
	return subclassTable;

    }


    /**
     * If the primary key for this GUSRow is not in the database, no values will be set.
     */
    public void retrieve()
	throws GUSInvalidPrimaryKeyException, GUSNoConnectionException, GUSObjectNotUniqueException{
	long id = getPrimaryKeyValue();
	if (id == -1){
	    throw new GUSInvalidPrimaryKeyException("No primary key set for the object the user is trying to retrieve");
	}
	GUSTable myTable = getTable();
	String schema = myTable.getSchemaName();
	String tName = myTable.getTableName();
	String pkAtt = myTable.getPrimaryKeyName();
	String query = "select * from " + schema + "." + tName + " where " + pkAtt + " = " + id;
	
	Vector result = server.runSqlQuery(sessionId, query);
	
	if (result.size() > 1){
	    throw new GUSObjectNotUniqueException("Found " + result.size() + " rows in " + schema + "." + 
						  tName + " with id=" + id);
	}
	if (result.size() == 1){
	    setIsEager(true);
	    Hashtable rowHash = (Hashtable)result.elementAt(0);
	    setAttributesFromHashtable(rowHash, null);
	}
    }
    
    protected SubmitResult submit_aux(boolean deepSubmit, boolean startTransaction) throws GUSNoConnectionException{
	
	//	Enumeration 
	
        SubmitResult sr = this.server.submitGUSRow(sessionId, this, deepSubmit, startTransaction);
	return sr;
    }

    public SubmitResult submit(boolean deepSubmit) throws GUSNoConnectionException{

	return  submit_aux(deepSubmit, true);
	
    }

    protected void submitNewParents(SubmitResult sr) throws GUSNoConnectionException{
	
	Enumeration allAttributes = attributeValues.keys();
	SubmitResult parentSubmits = null;
	while (allAttributes.hasMoreElements()){
	    String nextAtt = (String)allAttributes.nextElement();
	    GUSRowAttribute gra = (GUSRowAttribute)attributeValues.get(nextAtt);
	    Object value = gra.getCurrentValue();
	    if (value instanceof GUSRow){
		GUSRow nextParent = (GUSRow)value;
		if (nextParent.getPrimaryKeyValue() == -1){
		    parentSubmits = nextParent.submit_aux(false, false);
		    sr.update(parentSubmits);
		}
	    }
	}
    }


    /**
     * @return Whether any of this row's attributes have been changed from their initial values.
     */
    public boolean hasChangedAtts() {
	return hasChangedAtts;
    }

    public boolean isEager(){
	return this.isEager;
    }

    protected void setIsEager(boolean isEager){
	this.isEager = isEager;
    }

    public abstract long getPrimaryKeyValue();

    public String getSessionId(){
	return this.sessionId;
    }
    //test for 
    protected void addChild(GUSRow child, String fkAtt){
	
	String childKey = getUniqueChildKey(child, fkAtt);
	
	Vector thisChildVector = (Vector)children.get(childKey);
	if (thisChildVector == null){
	
	    thisChildVector = new Vector();
	    children.put(childKey, thisChildVector);
	}

	thisChildVector.add(child);
	
    }

    public void setParent(GUSRow newParent, String parentAtt){

	GUSRowAttribute parentGrAtt = (GUSRowAttribute)attributeValues.get(parentAtt);

	if (parentGrAtt != null){
	    GUSRow currentParent = (GUSRow)parentGrAtt.getCurrentValue();

	    if (currentParent != null){

		currentParent.removeChild(this, parentAtt);
	    }
	}
	try{
	    //	    System.err.println("GUSRow.setParent:  setting new parent here.");
	    set_Attribute(parentAtt, newParent);
	}
	catch (Exception e){
	    System.err.println(e.getMessage());
	    e.printStackTrace();
	    //dtb might want to do something with this later or throw it to the calling method.
	}
	if (newParent != null){
	    
	    newParent.addChild(this, parentAtt);
	}
    }
    
    protected GUSRow getParent(String parentAtt, boolean retrieveFromDb) {
	GUSRow parent = null;
	GUSRowAttribute parentGrAtt = (GUSRowAttribute)attributeValues.get(parentAtt);
	
	if (parentGrAtt == null){
	    return null; //child is new or there is no parent in db.
	    //DTB: offline mode?
	}
	parent = (GUSRow)parentGrAtt.getCurrentValue();
	if (retrieveFromDb){
	    if (!parent.isEager()){
		try{
		    parent.retrieve();
		}
		catch (Exception e){
		    System.err.println(e.getMessage());
		    e.printStackTrace();
		}
	    }
	}
	return parent;
    }

    protected void set_ParentRetrieved(String parentAtt, GUSTable parentTable, Long parentPk){
	try{

	    GUSRow parent = null;
	    if (parentPk != null){
		GUSRowAttribute gusRowAttribute = (GUSRowAttribute)attributeValues.get(parentAtt);
		if (gusRowAttribute == null){  //don't overwrite existing parent
		    parent = server.retrieveGUSRow(sessionId, parentTable, parentPk.longValue(), false);
		    parent.addChild(this, parentAtt);
		}
	    }
	    set_Retrieved(parentAtt, parent);
	}
	catch (Exception e){
	    e.printStackTrace();
	}
    }
    
    protected void removeChild(GUSRow child, String childFkToMe){

	GUSTable myTable = getTable();
	GUSTable childTable = child.getTable();
	String childKey = getUniqueChildKey(child, childFkToMe);
	Vector thisChildVector = (Vector)children.get(childKey);
	thisChildVector.remove(child);
    }


    private String getUniqueChildKey(GUSRow child, String childFkToMe){
	
	String childKey;
	GUSTable childTable = child.getTable();
	GUSTable myTable = getTable();
	if (myTable.childHasMultipleFksToMe(childTable.getSchemaName(), childTable.getTableName())){
	    childKey = makeSpecialChildKey(child, childFkToMe);
	}
	else{
	    childKey = getChildKeyForTableOrView(child);
	}
	return childKey;
    }

    //does not remove my parents from me...need to decide if that will mess things up.
    protected void removeFromParents(){

	Enumeration allAttributes = attributeValues.keys();
	//SubmitResult parentSubmits = null;
	while (allAttributes.hasMoreElements()){
	    String nextAtt = (String)allAttributes.nextElement();
	    GUSRowAttribute gra = (GUSRowAttribute)attributeValues.get(nextAtt);
	    Object value = gra.getCurrentValue();
	    if (value instanceof GUSRow){
		GUSRow gusRow = (GUSRow)value;
		gusRow.removeChild(this, nextAtt);
	    }
	}
    }

    protected void set_OverheadAttribute(String schema, String tableName, String attName, long pkValue){
	try{
	    GUSTable table = GUSTable.getTableByName(schema, tableName);
	    GUSRow parentGusRow = server.retrieveGUSRow(sessionId, table, pkValue, false);
	    setParent(parentGusRow, attName);
	}
	catch (Exception e){
	    e.printStackTrace();
	    System.err.println(e.getMessage());
	}
    }


    private String makeSpecialChildKey(GUSRow child, String childFkToMe){
	
	String finalChildTableName = getChildKeyForTableOrView(child);
		
	return finalChildTableName + "_IAmA_" + childFkToMe;
    }


    private String getChildKeyForTableOrView(GUSRow child){
	
	GUSTable childTable = child.getTable();
	
	String finalChildTableName = null;
	if (childTable.isView() == true){
	    
	    String impTableName = childTable.getImpTableName();
	    int impStartsAt = impTableName.lastIndexOf("Imp");
	    finalChildTableName = impTableName.substring(0, impStartsAt).toLowerCase();
	}
	else {
	    finalChildTableName = childTable.getTableName().toLowerCase();
	}
	return finalChildTableName;
    }

    protected Vector getParents(){
	return parents;
    }
    
    protected Vector getChildren(String childAtt, GUSTable childTable, String childFkToMe, boolean localOnly)
	throws GUSNoConnectionException {
	Vector theseChildren = null;
	if (localOnly == true){
	    theseChildren = (Vector)children.get(childAtt);
	}
	else{
	    String query = "select * from " + childTable.getSchemaName() + "." + childTable.getTableName() +
		" where " + childFkToMe + " = " + getPrimaryKeyValue();
	    theseChildren = server.retrieveGUSRowsFromQuery(sessionId, childTable, query);
	} 
	
	return theseChildren;
    }
    
    protected Hashtable getAllChildren(){
	return children;
    }
    

    /**
     * Set the deletion status of this row.  If set to <code>true</code>
     * when the row is next submitted to the database, it will be deleted.
     * 
     * @param d   Whether to delete this row the next time it is submitted.
     */
    public void setDeleted(boolean d){
        
	isDeleted = d;
	Enumeration childKeys = children.keys();
	while (childKeys.hasMoreElements()){
	    String nextChildKey = (String)childKeys.nextElement();

	    Vector nextChildList = (Vector)children.get(nextChildKey);
		
	    for (int i = 0; i < nextChildList.size(); i++){
		    
		GUSRow nextChild = (GUSRow)nextChildList.elementAt(i);

		//will you ever have lazy children?--yes if children are new
		if (nextChild.isEager()){
		    nextChild.setDeleted(d);
		}
	    }
	}
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
    
    public String childrenToXML(){
	String allChildren = "All children for this GUSRow: ";
	Enumeration childKeys = children.keys();
	while (childKeys.hasMoreElements()){
	    String nextChildKey = (String)childKeys.nextElement();
	    Vector nextChildList = (Vector)children.get(nextChildKey);
		
	    for (int i = 0; i < nextChildList.size(); i++){
		    
		GUSRow nextChild = (GUSRow)nextChildList.elementAt(i);
		allChildren = allChildren + nextChild.toXML();
	    }
	}
	return allChildren;
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

    Hashtable getAttributeValues() { return this.attributeValues; }
  
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
    void setAttributesFromHashtable(Hashtable rowHash, Hashtable specialCases) {
	this.setAttributesFromHashtable_aux(rowHash, specialCases);
    }

    // ------------------------------------------------------------------
    // Protected methods
    // ------------------------------------------------------------------

    /**
     * Set an attribute to a particular value.  Note that this only affects 
     * <code>currentValue</code> of the GUSRowAttribute in the GUSRow that represents
     * the attribute, until the row is written to the database.  
     *
     * @param key   The name of the attribute to be changed.
     * @param val   The new value for the attribute named by <code>key</code>.
     */
    protected void set_Attribute( String key, Object val ) { 
	
	if (! (val instanceof GUSRow)){
	    //attTypeCheck(key, val);
	}

	GUSRowAttribute gusRowAttribute = (GUSRowAttribute)attributeValues.get(key);
	if (gusRowAttribute == null){ //parent that hasn't been retrieved yet
	    gusRowAttribute = new GUSRowAttribute(val);
	    attributeValues.put(key, gusRowAttribute);
	}
	gusRowAttribute.setAttributeSetByApp(true);
	gusRowAttribute.setCurrentValue(val);
	this.hasChangedAtts = true;
		
	// If the attribute being set is the primary key column we throw
	// an exception, since the primary key value shouldn't be set by
	// users in the public interface.
	// DTB: changing this restriction -- with even the GUSServer wouldn't
	// be able to set the value.  Is there a way to prevent the client from
	// doing so?
    }

    /**
     * Get the <I>current</I> value of an attribute.  
     *
     * JC: If used on a CLOB/BLOB value, this method will ONLY return the cached portion of the LOB.
     *
     * @param key   The name of the attribute to get.
     * @return The requested attribute value.
     */
    protected Object get_Attribute( String key ) {
	GUSRowAttribute gusRowAttribute = (GUSRowAttribute)attributeValues.get(key);
	if (gusRowAttribute == null){
	    if (isEager == false && attributeValues.get(getTable().getPrimaryKeyName()) != null){
		try{
		    retrieve();
		}
		catch (Exception e){
		    System.err.println(e.getMessage());
		    e.printStackTrace();
		}
		gusRowAttribute = (GUSRowAttribute)attributeValues.get(key);
	    }
	    
	}
	if (gusRowAttribute == null){
	    return null;
	}
	return gusRowAttribute.getCurrentValue();
    }

    /**
     * Set this row's unique ID.  Requires interaction with the database.
     * Once set it should never change.
     *
     * @param new_id  
     */
    protected abstract void setPrimaryKeyValue(Long newId) 
	throws ClassNotFoundException,InstantiationException, IllegalAccessException, SQLException;

    /**
     * Sets the database value of an attribute to a particular value.
     * Called by a GUSRow subclass to initialize <code>attributeValues</code> with 
     * values from the database when this row is first retrieved from the
     * database.  
     *
     * @param key   The name of the attribute to set.
     * @param val   The <I>initial</I> value for the attribute named by <code>key</code>
     */
    protected void set_Retrieved ( String key, Object val ) {
	
 	GUSRowAttribute gusRowAttribute = (GUSRowAttribute)attributeValues.get(key);
	if (gusRowAttribute == null){ //hasn't been set yet, do so with db value

	    gusRowAttribute = new GUSRowAttribute(val);
	    attributeValues.put(key, gusRowAttribute);
	}
	else{
	    gusRowAttribute.setDbValue(val); //populate dbValue but keep currentValue as is
	}

	// JC: If the value being set is the primary key value then
	// we must also update <code>id</code>
	// DTB -- no, this is done in the subclassed objects
    }

    /**
     * Called after a submit to updated the attributes of this GUSRow to 
     * reflect that they are the same as those for the corresponding row
     * in the database.
     */
    protected void syncAttsWithDb(){

	Enumeration allAtts = attributeValues.keys();
	while (allAtts.hasMoreElements()){
	    String nextAtt = (String)allAtts.nextElement();
	    GUSRowAttribute nextGrAtt = (GUSRowAttribute)attributeValues.get(nextAtt);
	    nextGrAtt.syncAttWithDb();
	}
    }

    // JC: can we get rid of this method completely?
    // DTB: when an object is submitted, it needs to have its initial 
    // attribute hashtable updated to reflect what is now in the DB.
    // This method is the only way to do this, so far.


    /**
     * Retrieve a subsequence of the specified CLOB value; throws an
     * Exception if the requested subsequence is not available locally.
     *
     * @param att      The CLOB attribute in question.
     * @param cached   Object that records how much of the CLOB has been cached locally.
     * @param start    Start of subsequence to retrieve in 1-based coordinates, inclusive.
     * @param end      End of subsequence to retrieve in 1-based coordinates, inclusive.
     */
    protected char[] getClobValue(String att, CacheRange cached, long start, long end) {
	char[] value = (char[])this.get_Attribute(att);
        long cacheStart = 1;
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
	    int requestLen = localEnd - localStart + 1;
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
	byte[] value = (byte[])this.get_Attribute(att);
        long cacheStart = 1;
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
	    int requestLen = localEnd - localStart + 1;
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
	    if (specialCases != null) { //dtb-will never be null?
		CacheRange whatToCache = (CacheRange)(specialCases.get(att));
		cacheStart = whatToCache.getStart();  //might be null
		cacheEnd = whatToCache.getEnd();
	    }
	    
	    try {
		long length = value.length();
		long start = (cacheStart == null) ? 1 : cacheStart.longValue();
		long end = (cacheEnd == null) ? length: cacheEnd.longValue();
		boolean isEntireLob = ((start == 1) && (end == length));
		
		long cachedLength = end - start + 1;
		char[] data = new char[(int)cachedLength];
		java.io.Reader r = value.getCharacterStream();
		long offset = 0;

		// 0-based start and end coordinates
		long zeroStart = start - 1;
		long zeroEnd = end - 1;

		// Skip to the appropriate location in the stream (start)
		//
		while (offset < zeroStart) {
		    long amountSkipped = r.skip(zeroStart - offset);
		    offset += amountSkipped;
		}
		
		// Then read the requested range (up to end)
		//
		int arrayPosn = 0;
		while (offset < zeroEnd) {
		    int amountRead = r.read(data, arrayPosn, (int)(zeroEnd - offset + 1));
		    if (amountRead == -1) break;
		    arrayPosn += amountRead;
		    offset += amountRead;
		}
		
		if (!isEntireLob) result = new CacheRange(start, end, length);
		set_Retrieved(att, data); 
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
		long start = (cacheStart == null) ? 1 : cacheStart.longValue();
		long end = (cacheEnd == null) ? length : cacheEnd.longValue();
		boolean isEntireLob = ((start == 0) && (end == length));
		
		byte[] data = new byte[(int)length];
		java.io.InputStream r = value.getBinaryStream();
		long offset = 0;
				
		// 0-based start and end coordinates
		long zeroStart = start - 1;
		long zeroEnd = end - 1;

		// Skip to the appropriate location in the stream (start)
		//
		while (offset < zeroStart) {
		    long amountSkipped = r.skip(zeroStart - offset);
		    offset += amountSkipped;
		}
		
		// Then read the requested range (up to end)
		//
		int arrayPosn = 0;
		while (offset < zeroEnd) {
		    int amountRead = r.read(data, arrayPosn, (int)(zeroEnd - offset + 1));
		    if (amountRead == -1) break;
		    arrayPosn += amountRead;
		    offset += amountRead;
		}
		
		if (!isEntireLob) result = new CacheRange(start, end, length);
		set_Retrieved(att, data); 
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
	if (attInfo == null){
	    throw new IllegalArgumentException("GUSRow: Attempted to set an att " + att + " that is not in this GUSRow's table");
	}
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

    protected boolean intToBool(int input){
	boolean res = (input == 0) ? false : true;
	return res;
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
    protected void checkLength (String att, Object o) throws SQLException {

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
        Enumeration keys = attributeValues.keys();

        while( keys.hasMoreElements() ) {
            String next = (String)(keys.nextElement());
	    GUSRowAttribute nextAttribute = (GUSRowAttribute)attributeValues.get(next);
	    
	    Object nextVal = nextAttribute.getSubmitValue();
	    String nextstr = null;
	    if (nextVal != null){
		nextstr = nextVal.toString();
	    }
	    else {
		nextstr = "NULL";
	    }

	    // JC: why don't we print an attribute if its value is -1 or the empty string???
	    //     aren't these perfectly valid values in many attributes?

	    //	    if ( !nextstr.equals("") && !nextstr.equals("-1") ) { 
                xml.append("  <" + next + ">");
		xml.append(nextstr);
		xml.append("</" + next + ">" +  "\n");
		// }
        }
        xml.append("</" + this.getTable().getTableName() + ">" + "\n");
    }

    // ------------------------------------------------------------------
    // java.lang.Object
    // ------------------------------------------------------------------

    @Override
    public String toString() {
	GUSTable table = this.getTable();
	long id = getPrimaryKeyValue();
	return "[" + table + ":" + id + "]";
    }


} //GUSRow



package org.gusdb.objrelj;

import java.util.Enumeration;
import java.util.Hashtable;

/**
 * GUSTable.java
 *
 * Represents a single GUS table.
 * 
 * This class is the analog of DbiTable in the Perl object layer.
 *
 * Created: Tues April  16:56:00 2002
 *
 * @author Sharon Diskin, Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$ 
 */
public class GUSTable implements java.io.Serializable {

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    private static final long serialVersionUID = 1L;

    /** 
     * Schema/user that owns the table or view (eg. DoTS, SRes, Core, RAD, etc.)
     */
    protected String schemaName;

    /**
     * Name of this table or view, as it appears in core.TableInfo (JC: is this true?)
     */
    protected String tableName;

    /**
     * The ID of this table; corresponds to a value in core.TableInfo.tableId
     */
    protected int tableId;

    /**
     * Type of this table (eg. many-many, controlled vocab, etc.); corresponds
     * to a value in core.TableInfo.tableType
     */
    protected String tableType;

    /**
     * True if the table is actually a view.  Currently in GUS views are only
     * defined on tables whose names end in "Imp".
     */
    protected boolean isView;

    /**
     * Name of the table on which this is a view, if <code>isView == true</code>.
     */
    protected String impTableName;

    /**
     * Array containing the names of the table's attributes, in all-lowercase,
     * <I>in the order that they appear in the underlying relational table</I>. 
     */
    protected String[] attributeNames;

    /**
     * Hash of <code>GUSTableAttribute</code> objects keyed off att_name.
     */
    protected Hashtable attributeInfo;

    /**
     * Name of primary key column/attribute.
     */
    protected String primaryKey;           

    // JC: Oracle-specific

    /**
     * Whether this table has a corresponding Oracle SEQUENCE object named
     * <code>schemaName + "." + tableName + "_SQ"</code> that can be used to
     * generate unique ids for its primary key column.
     */
    protected boolean hasSequence;

    /**
     * Value of is_versioned for this table in core.TableInfo.is_versioned.
     */
    protected boolean isVersioned;

    /**
     * Value of is_updatable for this table in core.TableInfo.is_versioned.
     */
    protected boolean isUpdatable;

    /**
     * A Hashtable of Hashtables; the first is keyed on lowercase parent table
     * name, the second on lowercase child attribute name.  The values in
     * the second hash are GUSTableRelation objects.  They represent the
     * relations between this table and its parents.
     */
    protected Hashtable parentRelations;

    /**
     * A Hashtable of Hashtables; the first is keyed on lowercase child table
     * name, the second on lowercase child attribute name.  The values in
     * the second hash are GUSTableRelation objects.  They represent the
     * relations between this table and its children.
     */
    protected Hashtable childRelations;

    // ------------------------------------------------------------------
    // Constructors
    // ------------------------------------------------------------------

    /**
     * Constructor.
     *
     * @param schema    Schema of the table.
     * @param tname    Name of the table as it appears in core.TableInfo.name
     */
    public GUSTable (String schema, String tname) {
	this.schemaName = schema;
	this.tableName = tname;
        this.childRelations = new Hashtable();
        this.parentRelations = new Hashtable();
        this.attributeInfo = new Hashtable();
    }

    // ------------------------------------------------------------------
    // Static methods
    // ------------------------------------------------------------------

    /**
     * Hashtable that stores the GUSTable instances, indexed by 
     * schema.toLowerCase + "." + table.toLowerCase().
     */
    protected static Hashtable tableHash = new Hashtable();

    /**
     * Method to create new instances of the GUSTable subclasses; ensures that 
     * at most one instance of GUSTable exists for each (schema, name) pair.
     *
     * @param schema Schema in which the table exists.
     * @param tname  Name of the table.
     */
    public static GUSTable getTableByName(String schema, String tname) {
	String lcKey = schema.toLowerCase() + "." + tname.toLowerCase();
	GUSTable t = (GUSTable)(tableHash.get(lcKey));

	if (t == null) {
	    // JC: should have mapping that maps from lowercase database/table name
	    //     to the correct capitalization expected by the object layer
	    //     e.g. dots => DoTS and NASEQUENCE => NASequence
	    
	    String tableClassName = GUSRow.MODEL_PACKAGE + "." + schema + "." + tname + "_Table";

	    try {
		Class tableClass = Class.forName(tableClassName);
		t = (GUSTable)tableClass.newInstance();
		tableHash.put(lcKey, t);
	    } 
	    catch (ClassNotFoundException cnfe) {}
	    catch (InstantiationException ie) {}
	    catch (IllegalAccessException ie) {}
	}

	return t;
    }


    /**
     * Method to create new instances of the GUSTable subclasses; ensures that 
     * at most one instance of GUSTable exists for each (schema, name) pair.
     *
     * @param schemaTableName schema and table name as a single string; expected in 
     * either the format schemaName::tableName or schemaName.TableName.
     */
    public static GUSTable getTableByName(String schemaTableName) throws ClassNotFoundException{
	String schemaName = null;
	String tableName = null;

	int endSchemaName = schemaTableName.indexOf('.');
	if (endSchemaName == -1){
	    endSchemaName = schemaTableName.indexOf(':');
	    if (endSchemaName == -1 || schemaTableName.charAt(endSchemaName + 1) != ':'){
		throw new ClassNotFoundException("GUSTable.getTableByName: table name " + schemaTableName
						 + " not in schema::table or schema.table format");
	    }
	    else {
		schemaName = schemaTableName.substring(0, endSchemaName);
		tableName = schemaTableName.substring(endSchemaName + 2);
	    }
	}
	else {
	    schemaName = schemaTableName.substring(0, endSchemaName);
	    tableName = schemaTableName.substring(endSchemaName + 1);
	}
    
	return getTableByName(schemaName, tableName);
    }
	  


    // ------------------------------------------------------------------
    // Public methods
    // ------------------------------------------------------------------

    // Basic accessor methods
    
    public String getSchemaName() { return this.schemaName; }
    public String getTableName() { return this.tableName; }
    public int getTableId() { return tableId; }
    public String getTableType() { return tableType; }
    public boolean isView() { return this.isView; }
    public String getImpTableName() { return this.impTableName; }
    public String[] getAttributeNames() { return this.attributeNames; }
    public String getPrimaryKeyName() { return this.primaryKey; }
    public boolean hasSequence(){ return this.hasSequence; }
    public boolean isVersioned() { return this.isVersioned; }
    public boolean isUpdatable() { return this.isUpdatable; }

    /**
     * Return schema/type information for a single attribute.
     *
     * @param name   Name of the table attribute/column.
     */
    public GUSTableAttribute getAttributeInfo(String name){
	return (GUSTableAttribute)attributeInfo.get(name.toLowerCase());
    }

    /**
     * Return a relation in which this table is the child.
     */
    public GUSTableRelation getParentRelation(String schema, String tname, String childAtt) {
	String lcKey = schema.toLowerCase() + "." + tname.toLowerCase();
        Hashtable h = (Hashtable)parentRelations.get(lcKey);
	if (h == null) { return null; }
	return (GUSTableRelation)h.get(childAtt.toLowerCase());
    }

    /**
     * Return a relation in which this table is the parent.
     */
    public GUSTableRelation getChildRelation(String schema, String tname, String childAtt) {
	String lcKey = schema.toLowerCase() + "." + tname.toLowerCase();
        Hashtable h = (Hashtable)childRelations.get(lcKey);
	if (h == null) { return null; }
	return (GUSTableRelation)h.get(childAtt.toLowerCase());
    }

    /**
     * @param att   The name of an attribute.
     * @return Whether the named attribute is in the table.
     */
    public boolean isValidAtt(String att) {
        return (getAttributeInfo(att) != null);
    }

    public boolean childHasMultipleFksToMe(String schema, String tname){
	String key = schema.toLowerCase() + "." + tname.toLowerCase();
	Hashtable thisChildInfo = (Hashtable)childRelations.get(key);
	int size = thisChildInfo.size();
	boolean result = (size > 1) ? true : false;
	return result;
    }
						    

    // ------------------------------------------------------------------
    // Protected methods
    // ------------------------------------------------------------------

    /**
     * Add a new child relation to <code>this.childRelations</code>.
     */
    protected void addChildRelation(GUSTableRelation gtr, String schema, String tname, String childAtt) {
	addRelation_aux(this.childRelations, gtr, schema, tname, childAtt);
    }

    /**
     * Add a new parent relation to <code>this.parentRelations</code>.
     */
    protected void addParentRelation(GUSTableRelation gtr, String schema, String tname, String childAtt) {
	addRelation_aux(this.parentRelations, gtr, schema, tname, childAtt);
    }

    /**
     * Helper method for <code>addChildRelation</code> and <code>addParentRelation</code>.
     */
    protected void addRelation_aux(Hashtable h, GUSTableRelation gtr, String schema, String tname, String childAtt) {
	String lcSchema = schema.toLowerCase();
	String lcTable = tname.toLowerCase();
	//String lcAtt = childAtt.toLowerCase();
	String key1 = lcSchema + "." + lcTable;
	Hashtable h1 = (Hashtable)(h.get(key1));
	if (h1 == null) {
	    h1 = new Hashtable();
	    h.put(key1, h1);
	}
	
	//DTB:  this was causing overhead tables to fail when adding DoTS.OrthologExperiment; examine that table
	//for duplicate constraints and then add this in later.
	//	if (h1.put(lcAtt, gtr) != null) {
	//   throw new IllegalArgumentException(this + ": relation already defined when trying to add " + gtr);
	//} 
    }

    // ------------------------------------------------------------------
    // Display/debugging methods
    // ------------------------------------------------------------------
    
    public void displayAttInfo() {
	Enumeration e = attributeInfo.keys();
	while (e.hasMoreElements()){
	    String key = (String)e.nextElement();
	    System.out.println("attribute " + key + ": " + attributeInfo.get(key));
	}
    }
    
    public void displayChildInfo() {
	System.out.println("there are " + childRelations.size() + " child tables");
	Enumeration e = childRelations.keys();
	while (e.hasMoreElements()) {
	    String k1 = (String)(e.nextElement());
	    Hashtable h2 = (Hashtable)(childRelations.get(k1));
	    Enumeration e2 = h2.keys();
	    while (e2.hasMoreElements()) {
		String k2 = (String)(e2.nextElement());
		System.out.println( h2.get(k2));
	    }
	}
    }

    public void displayParentInfo() {
	System.out.println("there are " + parentRelations.size() + " parent tables");
	Enumeration e = parentRelations.keys();
	while (e.hasMoreElements()) {
	    String k1 = (String)(e.nextElement());
	    Hashtable h2 = (Hashtable)(parentRelations.get(k1));
	    Enumeration e2 = h2.keys();
	    while (e2.hasMoreElements()) {
		String k2 = (String)(e2.nextElement());
		System.out.println( h2.get(k2));
	    }
	}
    }

    // ------------------------------------------------------------------
    // java.lang.Object
    // ------------------------------------------------------------------

    @Override
    public String toString() {
	String schema = this.getSchemaName();
	String tname = this.getTableName();
	return schema + "." + tname;
    }

} //GUSTable

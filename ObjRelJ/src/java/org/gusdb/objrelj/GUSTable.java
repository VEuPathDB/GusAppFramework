package org.gusdb.objrelj;

import java.util.*;

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

    /** 
     * Schema/user that owns the table or view (eg. DoTS, SRes, Core, RAD, etc.)
     */
    protected String ownerName;

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
     * <code>ownerName + "." + tableName + "_SQ"</code> that can be used to
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
     * @param owner    Owner of the table.
     * @param tname    Name of the table as it appears in core.TableInfo.name
     */
    public GUSTable( String owner, String tname) {
	this.ownerName = owner;
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
     * owner.toLowerCase + "." + table.toLowerCase().
     */
    protected static Hashtable tableHash = new Hashtable();

    /**
     * The method that must be used to create new instances of the GUSTable
     * subclasses; ensures that at most one instance of GUSTable exists
     * for each (owner, name) pair.
     */
    public static GUSTable getTableByName(String owner, String tname) {
	String lcKey = owner.toLowerCase() + "." + tname.toLowerCase();
	GUSTable t = (GUSTable)(tableHash.get(lcKey));

	if (t == null) {
	    // JC: should have mapping that maps from lowercase database/table name
	    //     to the correct capitalization expected by the object layer
	    //     e.g. dots => DoTS and NASEQUENCE => NASequence
	    
	    String tableClassName = GUSRow.MODEL_PACKAGE + "." + owner + "." + tname + "_Table";
	    Class tableClass = Class.forName(tableClassName);
	    t = (GUSTable)tableClass.newInstance();
	    tableHash.put(lcKey, t);
	}

	return t;
    }

    // ------------------------------------------------------------------
    // Public methods
    // ------------------------------------------------------------------

    // Basic accessor methods
    
    public String getOwnerName() { return this.ownerName; }
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
    public GUSTableRelation getParentRelation(String owner, String tname, String childAtt) {
	String lcKey = owner.toLowerCase() + "." + tname.toLowerCase();
        Hashtable h = (Hashtable)parentRelations.get(lcKey);
	if (h == null) { return null; }
	return (GUSTableRelation)h.get(childAtt.toLowerCase());
    }

    /**
     * Return a relation in which this table is the parent.
     */
    public GUSTableRelation getChildRelation(String owner, String tname, String childAtt) {
	String lcKey = owner.toLowerCase() + "." + tname.toLowerCase();
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
	    String h2 = (Hashtable)e.nextElement();
	    Enumeration e2 = h2.keys();
	    while (e2.hasMoreElements()) {
		String key = (String) e2.nextElement();
		System.out.println( h2.get(key));
	    }
	}
    }

    public void displayParentInfo() {
	System.out.println("there are " + parentRelations.size() + " parent tables");
	Enumeration e = parentRelations.keys();
	while (e.hasMoreElements()) {
	    String h2 = (Hashtable)e.nextElement();
	    Enumeration e2 = h2.keys();
	    while (e2.hasMoreElements()) {
		String key = (String) e2.nextElement();
		System.out.println( h2.get(key));
	    }
	}
    }

} //GUSTable
















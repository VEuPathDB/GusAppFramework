package org.gusdb.objrelj;


/**
 * GUSTableRelation.java
 *
 * Represents a [foreign key] relationship between two GUS tables.
 * 
 * Created: Wed May 22  13:56:00 2002
 *
 * @author Sharon Diskin, Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class GUSTableRelation implements java.io.Serializable {

    private static final long serialVersionUID = 1L;

    // JC: In GUS 3.0 don't we also need to store the parent and child table *owners*?  Yes.

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    // JC: check that these values really are the same as those in core.[DatabaseInfo|TableInfo]

    /**
     * Name of the referenced table's owner, as it appears in core.DatabaseInfo.
     */
    private String parentTableOwner;

    /**
     * Name of the referenced table, as it appears in core.TableInfo.
     */
    private String parentTable;

    /**
     * Name of the referenced attribute; this should be the primary key column of the
     * parent table.
     */
    private String parentAtt;

    /**
     * Name of the referencing table's owner, as it appears in core.DatabaseInfo.
     */
    private String childTableOwner;

    /**
     * Name of the referencing table, as it appears in core.TableInfo.
     */
    private String childTable;

    /**
     * Name of the referencing attribute.
     */
    private String childAtt;

    // ------------------------------------------------------------------
    // Constructors
    // ------------------------------------------------------------------

    /**
     * Constructor
     *
     * @param p_owner  Name of parent (referenced) table's owner.
     * @param p_name   Name of parent (referenced) table.
     * @param pa_name  Name of parent (referenced) attribute.
     *
     * @param c_owner  Name of child (referencing) table's owner.
     * @param c_name   Name of child (referencing) table.
     * @param ca_name  Name of child (referencing) attribute.
     *
     */
    public GUSTableRelation(String p_owner, String p_name, String pa_name, 
			    String c_owner, String c_name, String ca_name ) 
    {
	this.parentTableOwner = p_owner;
	this.parentTable = p_name;
	this.parentAtt = pa_name;

	this.childTableOwner = c_owner;
	this.childTable = c_name;
	this.childAtt = ca_name;
    }

    // ------------------------------------------------------------------
    // Public methods
    // ------------------------------------------------------------------

    // Basic accessor methods

    public String getParentTableOwner() { return this.parentTableOwner; }
    public String getParentTable() { return this.parentTable; }
    public String getParentAtt(){ return this.parentAtt; }

    public String getChildTableOwner(){ return this.childTableOwner; }
    public String getChildTable(){ return this.childTable; }
    public String getChildAtt(){ return this.childAtt; }

    // ------------------------------------------------------------------
    // java.lang.Object
    // ------------------------------------------------------------------

    @Override
    public String toString(){
	return ("[GUSTableRelation: " +
		"parent=" + parentTableOwner + "." + parentTable + "." + parentAtt +
		" child=" + childTableOwner + "." + childTable + "." + childAtt +
		"]");
    }

} //GUSTableRelation

// NOTE for future: 
//   We could really make this more object oriented.  Here I only created
//   the class to simply hold the info in a structured manner. 
// NOTE for past:
//   Buy Microsoft stock.
//

// dtb note: check out Fowler for possible ways to make more oo 

// JC: 
// One thing that comes to mind in this regard is having the
// GUSTableRelation use 2 GUSTables to represent the relationship
// (along with 2 GUSTableAttributes).  However, the problem with that
// approach is that it introduces circular dependencies; you can't
// create the GUSTable object without first creating its
// GUSTableRelations...and you can't create those GUSTableRelations
// without first creating the relevant GUSTables.  This is
// particularly problematic for tables that reference themselves,
// although perhaps the code could be modified to handle this
// correctly.  What we have now is probably fine for now.

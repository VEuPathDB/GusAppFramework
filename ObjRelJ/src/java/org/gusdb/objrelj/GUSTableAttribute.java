package org.gusdb.objrelj;


/**
 * GUSTableAttribute.java
 *
 * Represents a single attribute/column of a GUS table.

 * Created: Tues April  16:56:00 2002
 *
 * @author Sharon Diskin, Dave Barkan, Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class GUSTableAttribute implements java.io.Serializable {

    private static final long serialVersionUID = 1L;

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    /**
     * Name of the attribute/column, in all-lowercase.
     */
    private String name;

    /**
     * The datatype of this attribute, as it would appear in a
     * CREATE TABLE statement for the table.
     */
    private String dbType;    // JC: oracle-specific?

    /**
     * The datatype of this attribute in Java, i.e., the Java Class name.
     */
    private String javaType;

    /**
     * Precision if numeric
     */
    private int precision;

    /**
     * Max. length if string (char/varchar) or CLOB/BLOB data.
     */
    private int length;

    /**
     * Scale if numeric
     */
    private int scale;

    /**
     * Whether this attribute's values need to be quoted when using 
     * them in an SQL statement.
     */
    private boolean isQuoted;   // JC: oracle-specific?

    /**
     * Whether this attribute permits null values in the database.
     */
    private boolean isNullable;

    // ------------------------------------------------------------------
    // Constructors
    // ------------------------------------------------------------------

    /**
     * Constructor used to set all of the attribute properties.
     *
     * @param n            Name.
     * @param dbtype       Database type, e.g. 'varchar(20)'
     * @param javatype     Java type, e.g. String.
     * @param prec         Precision
     * @param len          Length
     * @param sc           Scale
     * @param nulls        Whether nulls allowed
     * @param quote        Whether quoting required.
     */
    public GUSTableAttribute( String n, String dbtype, String javatype, int prec, int len, 
			      int sc, boolean nulls, boolean quote) 
    {
	this.name = n;
        this.dbType = dbtype;
        this.precision = prec;
        this.length = len;
        this.isNullable = nulls;
        this.isQuoted = quote; 
	this.javaType = javatype;
	this.scale = sc;
    }

    // ------------------------------------------------------------------
    // Public methods
    // ------------------------------------------------------------------

    // Basic accessor methods

    public String getName() { return this.name; }
    public String getDbType() { return this.dbType; }
    public String getJavaType() { return this.javaType; }
    public int getPrecision() { return this.precision; }
    public int getLength() { return this.length; }
    public int getScale() { return this.scale; }
    public boolean isQuoted() { return this.isQuoted; }
    public boolean isNullable() { return this.isNullable; }

    // ------------------------------------------------------------------
    // java.lang.Object
    // ------------------------------------------------------------------
   
    @Override
    public String toString(){
	return ( "[GUSTableAttribute: " 
		 + "name=" + this.name 
		 + " type=" + this.dbType 
		 + " length=" + this.length 
		 + " precision=" + this.precision 
		 + " scale=" + this.scale 
		 + " nullable=" + this.isNullable  
		 + " quoted=" + this.isQuoted  
		 + " javatype=" + this.javaType 
		 + "]");
    }

} // GUSTableAttribute

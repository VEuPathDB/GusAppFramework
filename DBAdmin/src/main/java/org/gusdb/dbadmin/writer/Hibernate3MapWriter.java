/*
 * $Id: Hibernate3MapWriter.java 3966 2005-10-28 09:42:07 -0400 (Fri, 28 Oct 2005) msaffitz $
 */
package org.gusdb.dbadmin.writer;

import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.StringTokenizer;
import java.util.TreeMap;
import java.util.TreeSet;

import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.Constraint;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.dbadmin.model.Table;
import org.gusdb.dbadmin.model.VersionTable;

/**
 * A <tt>SchemaWriter</tt> for writing a
 * <a href="http://www.hibernate.org">hibernate</a> (version 3.x) mapping for
 * the GUS schema.
 *
 * Usually called using <tt>dbaDumpSchema</tt> with the
 * <tt>-targetType hbm</tt> argument.
 *
 * @author $Author: msaffitz $
 * @version $Revision: 3966 $
 */
public class Hibernate3MapWriter
extends SchemaWriter
{
    /**
     * The base package for all hibernate generated classes
     * (default: org.gusdb.model).
     */
    String BASE_PKG;

    /**
     * Construct a Hibernate3MapWriter using the default base package.
     */
    public Hibernate3MapWriter()
    {
        this(null);
    }

    /**
     * Construct a Hibernate3MapWriter using the specified base package.
     * @param basePkg the package for all hibernate generated classes
     */
    public Hibernate3MapWriter(String basePkg)
    {
        BASE_PKG = (basePkg == null) ? "org.gusdb.model" : basePkg;
    }

    /**
     * Write the hibernate mapping for the specified database.
     * @param db the database to write
     */
    @Override
    protected void writeDatabase(Database db)
    throws IOException
    {
        oStream.write("<?xml version=\"1.0\"?>\n");
        oStream.write("<!DOCTYPE hibernate-mapping PUBLIC\n");
        indent(oStream, 1);
        oStream.write("\"-//Hibernate/Hibernate Mapping DTD 3.0//EN\"\n");
        indent(oStream, 1);
        oStream.write("\"http://hibernate.sourceforge.net/");
        oStream.write("hibernate-mapping-3.0.dtd\">\n\n");
        oStream.write("<hibernate-mapping");
        oStream.write(" package=\"");
        oStream.write(BASE_PKG);
        oStream.write("\"\n");
        indent(oStream, 2);
        oStream.write(" auto-import=\"false\"");
        oStream.write(" default-cascade=\"save-update\">\n");

	// Uncomment this to create inheritence from a top-level class
	// indent(oStream, 1);
        // oStream.write(" <meta attribute=\"extends\">org.gusdb.model.GusRow</meta>\n");

        indent(oStream, 1);
        for (Iterator<Schema> i = db.getAllSchemas().iterator(); i.hasNext(); ) {
            Schema schema = i.next();
            for (Iterator<? extends Table> j = schema.getTables().iterator(); j.hasNext(); ) {
                Table table = j.next();
                if (!(table instanceof VersionTable) && !isSubclass(table))
                    writeClass(oStream, table);
            }
        }

        oStream.write("</hibernate-mapping>\n");
    }

    /**
     * Write a single class mapping, including subclasses.
     * @param writer the output writer
     * @param table the table to map
     */
    private void writeClass(Writer writer, Table table)
    throws IOException
    {
        writer.write("<class name=\"");
        writer.write(BASE_PKG);
        writer.write(".");
        writer.write(table.getSchema().getName());
        writer.write(".");
        writer.write(table.getName());
        writer.write("\"\n");
        indent(writer, 2);
        writer.write("schema=\"");
        writer.write(table.getSchema().getName());
        writer.write("\" table=\"");
        writer.write(table.getName());
        writer.write("\">\n");
        writer.write("<meta attribute=\"implement-equals\">true</meta>\n");
        writeId(writer, table);
        writeTimestamp(writer, table);
	writeCoreTableInfoIdProperty(writer, table, 1);
        writeProperties(writer, table, 1);
        writeComponents(writer, table, 1);
        writeChildren(writer, table);
        writeSubclasses(writer, table, 1);
        writer.write("</class>\n\n");
    }

    /**
     * Write the properties for a class mapping
     * indented to the specified level.
     * @param writer the output writer
     * @param table the table containing the properties to write
     * @param level the indentation level
     */
    private void writeProperties(Writer writer, Table table, int level)
    throws IOException
    {
        for (Iterator<Column> i = table.getColumnsExcludeSuperclass( true ).iterator(); i.hasNext(); ) {
            Column column = i.next();
            if (isPrimaryKey(column) ||
                    isModificationDate(column) ||
                    isInternal(column) || isPermission(column)) {
                continue;
            } else if (isForeignKey(column)) {
                writeManyToOne(writer, column, level);
            } else {
                writeProperty(writer, column, level);
            }
        }
    }

    /**
     * Write the "static" properties for a class mapping
     * indented to the specified level.
     * @param writer the output writer
     * @param table the table containing the properties to write
     * @param level the indentation level
     */
    private void writeCoreTableInfoIdProperty(Writer writer, Table table, int level)
    throws IOException
    {
	indent(writer, level);
        writer.write("<property name=\"coreTableInfoId\" \n");
	indent(writer, level + 2);
        writer.write("update=\"false\" insert=\"false\" \n");
	indent(writer, level + 2);
	writer.write("lazy=\"false\" access=\"field\" type=\"integer\" >\n");
	indent(writer, level + 1);
	writer.write("<formula>\n");
	indent(writer, level + 2);
	writer.write("( select ti.table_id from core.tableinfo ti, core.databaseinfo di\n");
	String tableNameClause = (table.getSubclasses().isEmpty())
	    ? "ti.name like \'" +  table.getName() + "\'" 
	    : "ti.name like subclass_view" ;
	indent(writer, level + 2);
	writer.write("where " 
		     + tableNameClause
		     +"\n");
	indent(writer, level + 2);
	writer.write("and di.name like '" 
		     + table.getSchema().getName()
		     + "' \n");
	indent(writer, level + 2);
	writer.write("and di.database_id = ti.database_id ) \n" );
	indent(writer, level + 1);
	writer.write("</formula>\n");
	indent(writer, level);
        writer.write("</property>\n");
    }

    /**
     * Write collection mappings for all children of the specified table.
     * 
     * FIXME: RRD 10/14 This code is a mess.  Tried to fix raw types and ran
     * into type conflict problems.  It almost certainly throws ClassCastException
     * when run, but not sure what it's supposed to do so leaving it alone.
     * 
     * @param writer the output writer
     * @param table the parent table
     * @see writeChild(Writer,String,Constraint)
     * @see getCollectionName(Constraint,int)
     */
    private void writeChildren(Writer writer, Table table)
    throws IOException
    {
        if (!(table instanceof GusTable))
            return;

        Collection refs = ((GusTable)table).getReferentialConstraints();
        Map chldrn = new TreeMap();

        /**
         * various naming conflicts require multiple
         * passes over the child tables, the first implementation
         * attempted just had 5 very similar loops, is this better?
         *
         * pass 1: initializtion
         * pass 2: resolve conflicts using pre/suffix
         * pass 3: resolve conflicts using schema name
         * pass 4: resolve conflicts using both previous methods
         * pass 5: write the mappings
         */
        for (int pass = 0; pass < 5; pass++) {
            for (Iterator i = refs.iterator(); i.hasNext(); ) {
                Object next = i.next();
                String name = (pass > 0) ? (String)next :
                    getCollectionName((Constraint)next, pass);
                List l = (List)chldrn.get(name);
                switch (pass) {
                    case 0:
                        chldrn.put(name, (l = new ArrayList()));
                        l.add(next);
                        break;
                    case 1:
                    case 2:
                    case 3:
                        if (l.size() == 1)
                            break;
                        chldrn.remove(name);
                        for (Iterator j = l.iterator(); j.hasNext(); ) {
                            Constraint c = (Constraint)j.next();
                            name = getCollectionName(c, pass);
                            l = (List)chldrn.get(name);
                            if (l == null)
                                chldrn.put(name, (l = new ArrayList()));
                            l.add(c);
                        }
                        break;
                    case 4:
                        writeChild(writer, name, (Constraint)l.get(0));
                        break;
                    default:
                        break;
                }
            }
            refs = (Collection)((Map)((TreeMap)chldrn).clone()).keySet();
        }
    }

    /**
     * Write a collection mapping for a child table.
     * @param writer the output writer
     * @param name the name for the child collection
     * @param c the constraint representing the child relationship
     */
    private void writeChild(Writer writer, String name, Constraint c)
    throws IOException
    {
        Table ct = c.getConstrainedTable();
        indent(writer, 1);
        writer.write("<set name=\"");
        writer.write(name);
        writer.write("\" inverse=\"true\" lazy=\"true\">\n");
        indent(writer, 2);
        writer.write("<key>\n");
        indent(writer, 3);
        writer.write("<column name=\"");
        writer.write(getCollectionKey(c));
        writer.write("\"/>\n");
        indent(writer, 2);
        writer.write("</key>\n");
        indent(writer, 2);
        writer.write("<one-to-many class=\"");
        writer.write(BASE_PKG);
        writer.write(".");
        writer.write(ct.getSchema().getName());
        writer.write(".");
        writer.write(ct.getName());
        writer.write("\"/>\n");
        indent(writer, 1);
        writer.write("</set>\n");
    }

    /**
     * Write the subclass elements for a class mapping.
     *
     * Subclassing is implemented using <tt>&lt;joined-subclass&gt;</tt>,
     * <tt>&lt;union-subclass&gt;</tt> is probably a better choice, but
     * will have to wait for hibernate 3 to become stable.
     *
     * @param writer the output write
     * @param table the superclass table 
     * @param level the indent level
     */
    private void writeSubclasses(Writer writer, Table table, int level)
    throws IOException
    {
        for (Iterator<? extends Table> it = table.getSubclasses().iterator(); it.hasNext(); ) {
            Table sub = it.next();
            Column column = getPrimaryKey(table);
            indent(writer, level);
            writer.write("<joined-subclass\n");
            indent(writer, level + 2);
            writer.write("name=\"");
            writer.write(BASE_PKG);
            writer.write(".");
            writer.write(sub.getSchema().getName());
            writer.write(".");
            writer.write(sub.getName());
            writer.write("\"\n");
            indent(writer, level + 2);
            writer.write("schema=\"");
            writer.write(sub.getSchema().getName());
            writer.write("\"\n");
            indent(writer, level + 2);
            writer.write("extends=\"");
            writer.write(BASE_PKG);
            writer.write(".");
            writer.write(table.getSchema().getName());
            writer.write(".");
            writer.write(table.getName());
            writer.write("\">\n");
            indent(writer, level + 1);
            writer.write("<key>\n");
            indent(writer, level + 2);
            writer.write("<column name=\"");
            writer.write(column.getName());
            writer.write("\"/>\n");
            indent(writer, level + 1);
            writer.write("</key>\n");
	    //writeCoreTableInfoIdProperty(writer, sub , level + 1);
            writeProperties(writer, sub, level + 1);
            writeSubclasses(writer, sub, level + 1);
            indent(writer, level);
            writer.write("</joined-subclass>\n");
        }
    }

    /**
     * Write the id element for a class mapping.
     * @param writer the output writer
     * @param table the table being mapped
     */
    private void writeId(Writer writer, Table table)
    throws IOException
    {
        Column column = getPrimaryKey(table);
        indent(writer, 1);
        writer.write("<id name=\"");
        writer.write(getPropertyName(column));
        writer.write("\" type=\"long\">\n");
        writeColumn(writer, column, 2);
        indent(writer, 2);
        writer.write("<generator class=\"sequence\">\n");
        indent(writer, 3);
        writer.write("<param name=\"sequence\">\n");
        indent(writer, 4);
        writer.write(table.getSchema().getName().toUpperCase());
        writer.write(".");
        writer.write(table.getName().toUpperCase());
        writer.write("_SQ\n");
        indent(writer, 3);
        writer.write("</param>\n");
        indent(writer, 2);
        writer.write("</generator>\n");
        indent(writer, 1);
        writer.write("</id>\n");
    }

    /**
     * Write the timestamp element for a class mapping.
     * @param writer the output writer
     * @param table the table
     */
    private void writeTimestamp(Writer writer, Table table)
    throws IOException
    {
        indent(writer, 1);
        writer.write("<version type=\"timestamp\"");
        writer.write(" name=\"modificationDate\"\n");
        indent(writer, 3);
        writer.write("column=\"MODIFICATION_DATE\"/>\n");
    }

    private void writeComponents(Writer writer, Table table, int level)
    throws IOException
    {
        indent(writer, level);
        writer.write("<component name=\"rowInfo\"\n");
        indent(writer, level + 2);
        writer.write("class=\"");
        writer.write(BASE_PKG);
        writer.write(".Core.RowInfo\">\n");
        if (!hasUnique(table) && !isSubclass(table)) {
            indent(writer, level + 1);
            writer.write("<meta attribute=\"use-in-equals\">");
            writer.write("true</meta>\n");

        }
        for (Iterator<Column> i = table.getColumnsExcludeSuperclass( true ).iterator(); i.hasNext(); ) {
            Column column = i.next();
            if (isInternal(column) || isPermission(column))
                writeProperty(writer, column, level + 1);
        }
        indent(writer, level);
        writer.write("</component>\n");
    }

    /**
     * Write a many-to-one element for a class mapping.
     * @param writer the output writer
     * @param column the column to be mapped
     * @param level the indent level
     */
    private void writeManyToOne(Writer writer, Column column, int level)
    throws IOException
    {
        boolean meta = !hasUnique(column.getTable()) || isUnique(column);
        indent(writer, level);
        writer.write("<many-to-one name=\"");
        writer.write(getPropertyName(column));
        writer.write("\"\n");
        indent(writer, level + 2);
        // Deprecated
        // writer.write("outer-join=\"false\" access=\"field\"\n");
        writer.write("fetch=\"select\" lazy=\"false\" access=\"field\"\n");
        
        indent(writer, level + 2);
        writer.write("class=\"");
        writer.write(getClassName(column));
        writer.write("\">\n");
        if (meta && !isSubclass(column.getTable())) {
            indent(writer, level + 1);
            writer.write("<meta attribute=\"use-in-equals\">");
            writer.write("true</meta>\n");
        }
        writeColumn(writer, column, level + 1);
        indent(writer, level);
        writer.write("</many-to-one>\n");
    }

    /**
     * Write a property element for a class mapping.
     * @param writer the output writer
     * @param column the column to be mapped
     * @param level the indent level
     */
    private void writeProperty(Writer writer, Column column, int level)
    throws IOException
    {
        boolean meta = (!hasUnique(column.getTable()) && !isLarge(column)) ||
            (!isPermission(column) && !isInternal(column) && isUnique(column));
        indent(writer, level);
        writer.write("<property name=\"");
        writer.write(getPropertyName(column));
        writer.write("\" access=\"field\" type=\"");
        writer.write(getType(column));
        writer.write("\">\n");
        if (meta && !isSubclass(column.getTable())) {
            indent(writer, level + 1);
            writer.write("<meta attribute=\"use-in-equals\">");
            writer.write("true</meta>\n");
            indent(writer, level + 1);
            writer.write("<meta attribute=\"use-in-tostring\">");
            writer.write("true</meta>\n");
        }
        writeColumn(writer, column, level + 1);
        indent(writer, level);
        writer.write("</property>\n");
    }

    /**
     * Write a column element for a class mapping
     * @param writer the output writer
     * @param column the column to write
     * @param level the indent level
     */
    private void writeColumn(Writer writer, Column column, int level)
    throws IOException
    {
        indent(writer, level);
        writer.write("<column name=\"");
        writer.write(column.getName());
        writer.write("\"\n");
        indent(writer, level + 2);
        writer.write("not-null=\"");
        writer.write((!column.isNullable() ? "true" : "false"));
        writer.write("\" unique=\"");
        writer.write((isUnique(column) ? "true" : "false"));
        writer.write("\"/>\n");
    }

    /**
     * Search a columns constraints for a foreign key constraint.
     * @param column the column to test
     * @return true if the column contains a foreign key constraint
     */
    private boolean isForeignKey(Column column)
    {
        for (Iterator<Constraint> i = column.getConstraints().iterator(); i.hasNext(); )
            if (i.next().getType().equals(Constraint.ConstraintType.FOREIGN_KEY))
                return true;
        return false;
    }

    /**
     * Search a columns constraints for a primary key constraint.
     * @param column the column to test
     * @return true if the column contains a primary key constraint
     */
    private boolean isPrimaryKey(Column column)
    {
        for (Iterator<Constraint> i = column.getConstraints().iterator(); i.hasNext(); )
            if (i.next().getType().equals(Constraint.ConstraintType.PRIMARY_KEY))
                return true;
        return false;
    }

    /**
     * Test if a column is the "modification_date" column.
     * @param column the column to test
     * @return true if the column name is "modification_date"
     */
    private boolean isModificationDate(Column column)
    {
        return column.getName().equalsIgnoreCase("modification_date");
    }

    /**
     * Test if a column is a permission column.
     * @param column the column to test
     * @return true if the column is a permission column
     */
    private boolean isPermission(Column column)
    {
        String c = column.getName();
        return c.equalsIgnoreCase("user_read")
            || c.equalsIgnoreCase("user_write")
            || c.equalsIgnoreCase("group_read")
            || c.equalsIgnoreCase("group_write")
            || c.equalsIgnoreCase("other_read")
            || c.equalsIgnoreCase("other_write");
    }

    /**
     * Test if a column is an internal column.
     * @param column the column to test
     * @return true if the column is a permission column
     */
    private boolean isInternal(Column column)
    {
        String c = column.getName();
        return c.equalsIgnoreCase("row_user_id")
            || c.equalsIgnoreCase("row_group_id")
            || c.equalsIgnoreCase("row_project_id")
            || c.equalsIgnoreCase("row_alg_invocation_id");
    }

    /**
     * Get the primary key column for a table
     * @param table the table
     * @return the primary key column
     */
    private Column getPrimaryKey(Table table)
    {
        while (table.getSuperclass() != null)
            table = table.getSuperclass();

        for (Iterator<Column> i = table.getColumnsExcludeSuperclass( true ).iterator(); i.hasNext(); ) {
            Column column = i.next();
            if (isPrimaryKey(column))
                return column;
        }

        return null;
    }

    /**
     * Convert the name of the specified column to
     * an appropriate format for a property name.
     * @param column the column to convert
     * @return the converted string
     */
    private String getPropertyName(Column column)
    {
        Table table = column.getTable();
        StringBuffer sb = new StringBuffer(column.getName().length());
        StringTokenizer st = new StringTokenizer(
                                    column.getName().toLowerCase(), "_");
        sb.append(st.nextToken());
        while (st.hasMoreTokens()) {
            String t = st.nextToken();
            if (!t.equals("id") || isPrimaryKey(column)) {
                sb.append(t.substring(0, 1).toUpperCase());
                sb.append(t.substring(1));
            }
        }

        /*
         * special cases for naming conflicts in java
         * this should probably be somewhere more prominent
         * this table has a `new_id' which can't be shortened to `new'
         */
        if (tableNameEquals(table, "MergeSplit") &&
                (sb.toString().equalsIgnoreCase("new") ||
                 sb.toString().equalsIgnoreCase("old"))) {
            sb.append("Id");
        /*
         * these tables have columns names <name> and <name>_id
         * so leave the id suffix
         */
        } else if (tableNameEquals(table, "BibRefType") &&
                sb.toString().equalsIgnoreCase("source")) {
            if (column.getName().toLowerCase().endsWith("id"))
                sb.append("Id");
        } else if ((tableNameEquals(table, "SequenceFeature") ||
                    tableNameEquals(table, "BindingSiteFeature")) &&
                sb.toString().equalsIgnoreCase("model")) {
            if (column.getName().toLowerCase().endsWith("id"))
                sb.append("Id");
        /*
         * this table has a `class' column
         */
        } else if (tableNameEquals(table, "PhenotypeClass") &&
                sb.toString().equalsIgnoreCase("class")) {
            sb.setLength(0);
            sb.append("phenotypeClass");
        /*
         * and this one has an `abstract' column
         */
        } else if (tableNameEquals(table, "Abstract") &&
                sb.toString().equalsIgnoreCase("abstract")) {
            sb.setLength(0);
            sb.append("abst");
        }

        sb.setCharAt(0, Character.toLowerCase(sb.charAt(0)));
        return sb.toString();
    }

    /**
     * Compare (ignoring case) the name of the
     * specified table to the specified string.
     * @param table the table
     * @param name the name
     * @return true if the table name matches
     */
    private boolean tableNameEquals(Table table, String name)
    {
        return name.equalsIgnoreCase(table.getName());
    }

    /**
     * Generate a string appropriate for naming a child collection.
     *
     * For the most part, the child table name is a reasonable name
     * for the corresponding collection, however, in some cases, a child
     * has multiple keys to a parent, or the child table name is not unique
     * across all gus schemas.  This method will, depending on the conflict
     * level specified make some attempt to pre/suffix the child table name
     * with useful information from the constraint, such as the name of the
     * column in the child table used in the constraint, or the schema name
     * of the child table.
     *
     * @param c the constraint representing the child relationship
     * @param conflict the number of conflict resolution methods to attempt
     * @return the generated collection name
     */
    private String getCollectionName(Constraint c, int conflict)
    {
        Set parts = new TreeSet();
        Table table = c.getConstrainedTable();
        StringBuffer sb = new StringBuffer();
        String child = table.getName();
        String key = getPrimaryKey(c.getReferencedTable())
                                .getName().toLowerCase();
        String index = "";
        String column = (c.getConstrainedColumns().iterator().next()).getName().toLowerCase();

        if (conflict > 1)
            sb.append(table.getSchema().getName());

        if (conflict == 1 || conflict > 2) {
            for (StringTokenizer st =
                    new StringTokenizer(key, "_"); st.hasMoreTokens(); )
                parts.add(st.nextToken());

            for (StringTokenizer st =
                    new StringTokenizer(column, "_"); st.hasMoreTokens(); ) {
                String s = st.nextToken();
                try {
                    Integer.parseInt(s);
                    index = s;
                } catch (NumberFormatException ignored) {
                    if (!parts.contains(s)) {
                        sb.append((sb.length() == 0) ? s :
                            s.substring(0, 1).toUpperCase() + s.substring(1));
                        parts.add(s);
                    }
                }
            }
        }

        sb.append(child);
        if (sb.toString().endsWith("nfo")) {
            /* leave it alone */
        } else if (sb.toString().endsWith("sis")) {
            sb.setLength(sb.length() - 2);
            sb.append("es");
        } else if (sb.toString().endsWith("s")) {
            sb.append("es");
        } else if (sb.toString().endsWith("ay") ||
                    sb.toString().endsWith("ey")) {
            sb.append("s");
        } else if (sb.toString().endsWith("y")) {
            sb.setLength(sb.length() - 1);
            sb.append("ies");
        } else {
            sb.append("s");
        }
        sb.append(index);
        return sb.toString();
    }

    /**
     * Get the name of the key element for a collection mapping.
     * @param c the constraint representing the child relationship
     * @return a string to use for the name attribute of the key element
     */
    private String getCollectionKey(Constraint c)
    {
        Column column = c.getReferencedColumns().iterator().next();
        return column.getName();
    }

    /**
     * Get the string representing the hibernate type of a column.
     * @param column the column
     * @return a hibernate type name
     */
    private String getType(Column column)
    { 
        if (isPermission(column)) return "byte";
        if (column.getType() == Column.ColumnType.STRING) return "string";
        if (column.getType() == Column.ColumnType.CHARACTER) return "character";
        if (column.getType() == Column.ColumnType.CLOB) return "clob";
        if (column.getType() == Column.ColumnType.BLOB) return "blob";
        if (column.getType() == Column.ColumnType.DATE) return "date";
        if (column.getType() == Column.ColumnType.FLOAT) return "float";
        if (column.getType() == Column.ColumnType.NUMBER) return "long";
        log.debug("Unknown ColumnType: "+column.getType());
        throw new RuntimeException("Unknown ColumnType");
    }

    /**
     * Determine if a column has a unique constraint
     * @param column the column
     * @return true if the column has a unique constraint, false otherwise
     */
    private boolean isUnique(Column column)
    {
        for (Iterator<Constraint> i = column.getConstraints().iterator(); i.hasNext(); ) {
            Constraint c = i.next();
            if (c.getType().equals(Constraint.ConstraintType.PRIMARY_KEY) ||
                    (c.getType().equals(Constraint.ConstraintType.UNIQUE) &&
                        c.getConstrainedColumns().size() == 1))
                return true;
        }

        return false;
    }

    /**
     * Determine if a column represents a large object (lob)
     * @param column the column
     * @return true if the column is a large object, false otherwise
     */
    private boolean isLarge(Column column)
    {
        return (column.getType() == Column.ColumnType.BLOB ||
                column.getType() == Column.ColumnType.CLOB);
    }

    /**
     * Determine if a table represents a subclass
     * @param table the table
     * @return true if the table is a subclass, false otherwise
     */
    private boolean isSubclass(Table table)
    {
        return (table.getSuperclass() != null);
    }

    /**
     * Determine if a table contains column with a unique constraint
     * @param table the table
     * @return true if the table has a unique column, false otherwise
     */
    private boolean hasUnique(Table table)
    {
        /* cannot use isUnique here, because we specifically
         * want to know if a unique constraint exists, not
         * just if the column is guaranteed unique (for example
         * by a primary key constraint
         */
        for (Iterator<Column> i = table.getColumnsExcludeSuperclass(false).iterator(); i.hasNext(); ) {
            Column c = i.next();
            for (Iterator<Constraint> j = c.getConstraints().iterator(); j.hasNext(); ) {
                Constraint cn = j.next();
                if (cn.getType().equals(Constraint.ConstraintType.UNIQUE) &&
                            cn.getConstrainedColumns().size() == 1)
                    return true;
            }
        }
        return false;
    }

    /**
     * Get the class attribute value of a column
     * @param column the column
     * @return a string representing the class name of a column
     */
    private String getClassName(Column column)
    {
        String name = column.getName();

        if (name.equalsIgnoreCase("row_user_id")) {
            return BASE_PKG + ".Core.UserInfo";
        } else if (name.equalsIgnoreCase("row_group_id")) {
            return BASE_PKG + ".Core.GroupInfo";
        } else if (name.equalsIgnoreCase("row_project_id")) {
            return BASE_PKG + ".Core.ProjectInfo";
        } else if (name.equalsIgnoreCase("row_alg_invocation_id")) {
            return BASE_PKG + ".Core.AlgorithmInvocation";
        }

        for (Iterator<Constraint> i = column.getConstraints().iterator(); i.hasNext(); ) {
            Constraint c = i.next();
            if (c.getType().equals(Constraint.ConstraintType.FOREIGN_KEY)) {
                Table t = c.getReferencedTable();
                return BASE_PKG + '.' +
                    t.getSchema().getName() + '.' + t.getName();
            }
        }

        return "";
    }

    /**
     * Write the necessary spaces to indent a line
     * to the specified level
     * @param writer the output writer
     * @param level the indent level
     */
    private void indent(Writer writer, int level)
    throws IOException
    {
        for (int i = 0; i < level; i++)
            writer.write("    ");
    }

    /**
     * @see org.gusdb.dbadmin.writer.SchemaWriter#setUp()
     */
    @Override
    protected void setUp()
    { }

    /**
     * @see org.gusdb.dbadmin.writer.SchemaWriter#tearDown()
     */
    @Override
    protected void tearDown()
    { }
}

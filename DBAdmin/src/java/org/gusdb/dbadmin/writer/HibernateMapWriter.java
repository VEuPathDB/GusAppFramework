/*
 * Created on Dec 2, 2004
 */
package org.gusdb.dbadmin.writer;

import java.io.File;
import java.io.Writer;
import java.io.IOException;
import java.util.Iterator;
import java.util.StringTokenizer;

import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.ColumnType;
import org.gusdb.dbadmin.model.Constraint;
import org.gusdb.dbadmin.model.ConstraintType;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.dbadmin.model.Table;

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public class HibernateMapWriter
extends SchemaWriter
{
    String basePackage;

    public HibernateMapWriter()
    {
        this(null);
    }

    public HibernateMapWriter(String basePkg)
    {
        basePackage = (basePkg == null) ? "org.gusdb.model" : basePkg;
    }

    protected void writeDatabase(Database db)
    throws IOException
    {
        oStream.write("<?xml version=\"1.0\"?>\n");
        oStream.write("<!DOCTYPE hibernate-mapping PUBLIC\n");
        oStream.write("\t\"-//Hibernate/Hibernate Mapping DTD 2.0//EN\"\n");
        oStream.write("\t\"http://hibernate.sourceforge.net/" +
                     "hibernate-mapping-2.0.dtd\">\n\n");
        oStream.write("<hibernate-mapping>\n");
        for (Iterator i = db.getSchemas().iterator(); i.hasNext(); ) {
            Schema schema = (Schema)i.next();
            for (Iterator j = schema.getTables().iterator(); j.hasNext(); ) {
                Table table = (Table)j.next();
                if (table.getSuperclass() == null)
                    writeClass(oStream, table);
            }
        }
        oStream.write("</hibernate-mapping>\n");
    }

    private void writeClass(Writer writer, Table table)
    throws IOException
    {
        boolean versioned =
                    table.getName().toLowerCase().endsWith("ver");
        writer.write("<class name=\"" + basePackage + "." +
                     table.getSchema().getName() + "." +
                     table.getName() + "\" table=\"" +
                     table.getName() + "\">\n");
        writeId(writer, table, versioned);
        writeDiscriminator(writer, table);
        if (!versioned)
            writeTimestamp(writer, table);
        writeProperties(writer, table);
        writeSubclasses(writer, table);
        writer.write("</class>\n");
    }

    private void writeProperties(Writer writer, Table table)
    throws IOException
    {
        for (Iterator i = table.getColumns().iterator(); i.hasNext(); ) {
            Column column = (Column)i.next();
            if (isPrimaryKey(column) ||
                    isModificationDate(column) || isDiscriminator(column)) {
                continue;
            } else if (isForeignKey(column)) {
                writeFKField(writer, column);
            } else {
                writeProperty(writer, column);
            }
        }
    }

    private void writeSubclasses(Writer writer, Table table)
    throws IOException
    {
        for (Iterator i = table.getSubclasses().iterator(); i.hasNext(); ) {
            Table sub = (Table)i.next();
            writer.write("<subclass name=\"" + basePackage + "." +
                         sub.getSchema().getName() + "." +
                         sub.getName() + "\" discriminator-value=\"" +
                         sub.getName() + "\" extends=\"" +
                         basePackage + "." +
                         table.getSchema().getName() + "." +
                         table.getName() +
                         "\">\n");
            writeProperties(writer, sub);
            writer.write("</subclass>\n");
            writeSubclasses(writer, sub);
        }
    }

    private void writeId(Writer writer, Table table, boolean versioned)
    throws IOException
    {
        for (Iterator i = table.getColumns().iterator(); i.hasNext(); ) {
            Column column = (Column)i.next();
            if (!isPrimaryKey(column) || isModificationDate(column))
                continue;

            if (!versioned) {
                writer.write("\t<id name=\"" + getPropertyName(column) +
                            "\" type=\"long\" column=\"" +
                            column.getName() + "\">\n");
                writer.write("\t\t<generator class=\"sequence\">\n");
                writer.write("\t\t\t<param name=\"sequence\">" +
                            column.getTable().getName().toUpperCase() +
                            "_SQ</param>\n");
                writer.write("\t\t</generator>\n");
                writer.write("\t</id>\n");
            } else {
                writer.write("\t<composite-id>\n");
                writer.write("\t\t<key-property name=\"" +
                            getPropertyName(column) + 
                            "\" type=\"long\" column=\"" +
                            column.getName() + "\"/>\n");
                writer.write("\t\t<key-property name=\"modificationDate\"" +
                            " type=\"timestamp\"" +
                            " column=\"MODIFICATION_DATE\"/>\n");
                writer.write("\t</composite-id>\n");
            }
        }
    }


    private void writeDiscriminator(Writer writer, Table table)
    throws IOException
    {
        writer.write("\t<discriminator column=\"SUBCLASS_VIEW\"" +
                     " type=\"string\"/>\n");
    }

    private void writeTimestamp(Writer writer, Table table)
    throws IOException
    {
        writer.write("\t<timestamp name=\"modificationDate\"" +
                     " column=\"MODIFICATION_DATE\"/>\n");
    }

    private void writeFKField(Writer writer, Column column)
    throws IOException
    {
        writer.write("\t<many-to-one name=\"" + getPropertyName(column) +
                     "\" column=\"" + column.getName() + 
                     "\" not-null=\"" + getNotNullable(column) +
                     "\"\n\t\tclass=\"" + getClassName(column) + "\"/>\n");
    }

    private void writeProperty(Writer writer, Column column)
    throws IOException
    {
        writer.write("\t<property name=\"" + getPropertyName(column) +
                     "\" column=\"" + column.getName() +
                     "\"\n\t\ttype=\"" + getType(column) +
                     "\" not-null=\"" + getNotNullable(column) +
                     "\" unique=\"" + getUnique(column) + "\"/>\n");
    }

    private boolean isForeignKey(Column column )
    {
        for (Iterator i = column.getConstraints().iterator(); i.hasNext(); )
            if (((Constraint)i.next()).getType() == ConstraintType.FOREIGN_KEY)
                return true;
        return false;
    }

    private boolean isPrimaryKey(Column column)
    {
        for (Iterator i = column.getConstraints().iterator(); i.hasNext(); )
            if (((Constraint)i.next()).getType() == ConstraintType.PRIMARY_KEY)
                return true;
        return false;
    }

    private boolean isModificationDate(Column column)
    {
        return new String("modification_date")
                    .equalsIgnoreCase(column.getName());
    }

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

    private boolean isInternal(Column column)
    {
        String c = column.getName();
        return c.equalsIgnoreCase("row_user_id")
            || c.equalsIgnoreCase("row_group_id")
            || c.equalsIgnoreCase("row_project_id")
            || c.equalsIgnoreCase("row_alg_invocation_id");
    }

    private boolean isDiscriminator(Column column)
    {
        return column.getName().equalsIgnoreCase("subclass_view");
    }

    private boolean isTableColumn(String table, Column column)
    {
        Table t = column.getTable();
        return table.equalsIgnoreCase(t.getName())
            || table.concat("Ver").equalsIgnoreCase(t.getName());
    }

    private String getPropertyName(Column column)
    {
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
        if (isTableColumn("MergeSplit", column) &&
                (sb.toString().equalsIgnoreCase("new") ||
                 sb.toString().equalsIgnoreCase("old"))) {
            sb.append("Id");
        /*
         * these tables have columns names <name> and <name>_id
         * so leave the id suffix
         */
        } else if (isTableColumn("BibRefType", column) &&
                sb.toString().equalsIgnoreCase("source")) {
            if (column.getName().toLowerCase().endsWith("id"))
                sb.append("Id");
        } else if ((isTableColumn("SequenceFeature", column) ||
                    isTableColumn("BindingSiteFeature", column)) &&
                sb.toString().equalsIgnoreCase("model")) {
            if (column.getName().toLowerCase().endsWith("id"))
                sb.append("Id");
        /*
         * this table has a `class' column
         */
        } else if (isTableColumn("PhenotypeClass", column) &&
                sb.toString().equalsIgnoreCase("class")) {
            sb.setLength(0);
            sb.append("phenotypeClass");
        /*
         * and this one has an `abstract' column
         */
        } else if (isTableColumn("Abstract", column) &&
                sb.toString().equalsIgnoreCase("abstract")) {
            sb.setLength(0);
            sb.append("abst");
        }

        return sb.toString();
    }

    private String getType(Column column)
    { 
        if ( isPermission(column) ) return "short";
        if ( isInternal(column) ) return "long";
        if ( column.getType() == ColumnType.STRING ) return "string";
        if ( column.getType() == ColumnType.CHARACTER ) return "character";
        if ( column.getType() == ColumnType.CLOB ) return "java.sql.Clob";
        if ( column.getType() == ColumnType.DATE ) return "date";
        if ( column.getType() == ColumnType.FLOAT ) return "float";
        if ( column.getType() == ColumnType.NUMBER ) return "big_decimal";
        log.debug("Unknown ColumnType: "+column.getType());
        throw new RuntimeException("Unknown ColumnType");
    }

    private String getNotNullable(Column column)
    {
        return (!column.isNullable()
            || isInternal(column) || isPermission(column)) ? "true" : "false";
    }

    private String getUnique(Column column)
    {
        for (Iterator i = column.getConstraints().iterator(); i.hasNext(); )
            if (((Constraint)i.next()).getType() == ConstraintType.UNIQUE)
                return "true";

        return "false";
    }

    private String getClassName(Column column)
    {
        for (Iterator i = column.getConstraints().iterator(); i.hasNext(); ) {
            Constraint c = (Constraint)i.next();
            if (c.getType() == ConstraintType.FOREIGN_KEY) {
                Table t = c.getReferencedTable();
                return basePackage + '.' +
                    t.getSchema().getName() + '.' + t.getName();
            }
        }

        return "";
    }

    protected void setUp()
    { }

    /* (non-Javadoc)
     * @see org.gusdb.dbadmin.writer.SchemaWriter#tearDown()
     */
    protected void tearDown()
    { }
}

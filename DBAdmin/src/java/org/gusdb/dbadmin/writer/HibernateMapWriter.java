/*
 * Created on Dec 2, 2004
 * TODO: Review naming capitalization
 */
package org.gusdb.dbadmin.writer;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Iterator;

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
public class HibernateMapWriter extends SchemaWriter {

    File mapDir;
    String basePackage = properties.getProperty("hibernate.basePkg");
	
    protected void writeDatabase(Database db) throws IOException {
	for (Iterator i = db.getSchemas().iterator(); i.hasNext(); ) {
	    Schema schema = (Schema) i.next();
	    File schemaDir = new File(mapDir.getAbsolutePath() + "/" + schema.getName());
	    schemaDir.mkdir();
	    for( Iterator j = schema.getTables().iterator(); j.hasNext(); ) {
		Table table = (Table) j.next();
		FileWriter classWriter = new FileWriter(
							new File(schemaDir.getAbsolutePath() + "/" + table.getName() + ".hbm.xml"));
		writeClass(classWriter, (Table) j.next());
	    }
	}
    }

    private void writeClass(FileWriter writer, Table table) throws IOException {
	writer.write("<?xml version=\"1.0\"?>\n");
	writer.write("<!DOCTYPE hibernate-mapping PUBLIC\n");
	writer.write("\t\"-//Hibernate/Hibernate Mapping DTD 2.0//EN\"\n");
	writer.write("\t\"http://hibernate.sourceforge.net/hibernate-mapping-2.0.dtd\" >\n\n");
		
	writer.write("<hibernate-mapping>\n");
	writer.write("<class name=\"" + basePackage + "." + table.getSchema().getName() + "." +
		     table.getName() + "\" table=\"" + table.getName() + "\">\n");

	writer.flush();
	writeFields(writer, table);
	
	writer.write("</class>\n");
	writer.write("</hibernate-mapping>\n");
	writer.close();
    }
		
    private void writeFields(FileWriter writer, Table table) throws IOException {
	for ( Iterator i = table.getColumns().iterator(); i.hasNext(); ) {
	    Column column = (Column) i.next();
	    if ( isPrimaryKey(column)) { writeIDField(writer, column); }
	    else if ( isForeignKey(column)) { writeFKField(writer, column); }
	    else writeField(writer, column);
	}
    }
	
    private void writeIDField(FileWriter writer, Column column) throws IOException {
	writer.write("\t<id name=\"" + column.getName() + "\" type=\"" + getType(column) +
		     "column=\"" + column.getName() + "\">\n");
	writer.write("\t\t<generator class=\"sequence\">\n");
	writer.write("\t\t\t<param name=\"sequence\">" + column.getTable().getName() + "_SQ</param>\n");
	writer.write("\t\t</generator>\n");
	writer.write("\t</id>\n");
	writer.flush();
    }
	
    private void writeFKField(FileWriter writer, Column column) throws IOException {
	// TODO
    }
	
    private void writeField(FileWriter writer, Column column) throws IOException {
	// TODO
    }
	
    private boolean isForeignKey(Column column ) {
	for ( Iterator i = column.getConstraints().iterator(); i.hasNext(); ) {
	    if ( ((Constraint) i.next()).getType() == ConstraintType.FOREIGN_KEY ) return true;
	}
	return false;
    }
	
	
    private boolean isPrimaryKey(Column column) {
	for ( Iterator i =  column.getConstraints().iterator(); i.hasNext(); ) {
	    if ( ((Constraint) i.next()).getType() == ConstraintType.PRIMARY_KEY ) return true;
	}
	return false;
    }
	
    private String getType(Column column) { 
	if ( column.getType() == ColumnType.STRING ) return "string";
	if ( column.getType() == ColumnType.CHARACTER ) return "character";
	if ( column.getType() == ColumnType.CLOB ) return "java.sql.Clob";
	if ( column.getType() == ColumnType.DATE ) return "date";
	if ( column.getType() == ColumnType.FLOAT ) return "float";
	if ( column.getType() == ColumnType.NUMBER ) return "big_decimal";
	log.debug("Unknown ColumnType: "+column.getType());
	throw new RuntimeException("Unknown ColumnType");
    }
	
    protected void setUp() {
	mapDir = new File(properties.getProperty("hibernate.mapdir"));
	mapDir.mkdirs();
    }

    /* (non-Javadoc)
     * @see org.gusdb.dbadmin.writer.SchemaWriter#tearDown()
     */
    protected void tearDown() {
    }
}

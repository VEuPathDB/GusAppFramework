/*
 *  Created on Nov 19, 2004
 *
 */
package org.gusdb.dbadmin.util;

import java.io.IOException;
import java.io.Writer;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.DatabaseObject;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.GusView;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.dbadmin.model.Table;
import org.gusdb.dbadmin.model.VersionTable;
import org.gusdb.dbadmin.model.VersionView;
import org.gusdb.dbadmin.model.View;

/**
 *@author     msaffitz
 *@created    May 2, 2005
 *@version    $Revision$ $Date$
 */
public class MetadataPopulator {

    private static final Logger log = LogManager.getLogger( MetadataPopulator.class );

    private Writer writer;
	private Database db;
	private String dbVendor;

	private Map<Integer, Schema> schemaIDs        = new HashMap<>();
	private Map<Integer, DatabaseObject> tableAndViewIDs  = new HashMap<>();
	private Set<DatabaseObject> written          = new HashSet<>();

	public MetadataPopulator( Writer writer, Database db, String vendor) {
		this.writer = writer;
		this.db = db;
		this.dbVendor = vendor;

		if ( vendor.compareToIgnoreCase("Oracle") != 0 &&
			 vendor.compareToIgnoreCase("Postgres") != 0) {
			log.error("Unsupported database vendor: '" + vendor + "'");
			throw new RuntimeException("Unsupported Database Vendor: '" + vendor + "'");
		}
	}


	public void writeDatabaseAndTableInfo() throws IOException {
		if (dbVendor.equalsIgnoreCase("Postgres")) {
			writer.write( "BEGIN;\n\n" );
			writer.write( "-- Switch to GUS_W role to make sure all objects are owned by GUS_W\n" );
			writer.write( "SET ROLE GUS_W;\n\n" );
		}
        for ( Schema schema : db.getAllSchemas() ) {
			schemaIDs.put(schemaIDs.size() + 1, schema );
            for (Table table : schema.getTables()) {
                tableAndViewIDs.put(tableAndViewIDs.size() + 1, table);
            }
            for (View view : schema.getViews()) {
                tableAndViewIDs.put(tableAndViewIDs.size() + 1, view);
            }
		}
        for (Schema schema : db.getAllSchemas()) {
            writeDatabaseInfo(schema);
        }
        for (Schema schema : db.getAllSchemas()) {
            for (Table table : schema.getTables()) {
                writeTableInfo(table);
            }
            for (View view : schema.getViews()) {
                writeTableInfo(view);
            }
        }
		fixSequence( "core.databaseinfo_sq", schemaIDs.size() + 1);
		fixSequence( "core.tableinfo_sq", tableAndViewIDs.size() + 1);
		if (dbVendor.equalsIgnoreCase("Postgres")) {
			writer.write( "\nCOMMIT;\n" );
		}
		writer.flush();
	}


	/**
     * @throws IOException if unable to write documentation
     */
	public void writeDatabaseDocumentation() throws IOException {
		// TODO implement me
	}

	public void writeDatabaseVersion( float version ) throws IOException {
		writer.write("INSERT INTO core.databaseversion " + 
			"(database_version_id, version, modification_date, user_read, user_write," + 
			"group_read, group_write, other_read, other_write, row_user_id, " +
			"row_group_id, row_project_id, row_alg_invocation_id) VALUES (" + 
			getSequenceFunction("core.databaseversion_sq", "nextval") + "," + version + ","
			+ getDateFunction() + ",1,1,1,1,1,0,1,1,1,1);\n\n");
	}

	public void writeBootstrapData() throws IOException {
		if (dbVendor.equalsIgnoreCase("Postgres")) {
			writer.write( "BEGIN;\n\n" );
			writer.write( "-- Switch to GUS_W role to make sure all objects are owned by GUS_W\n" );
			writer.write( "SET ROLE GUS_W;\n\n" );
		}
		
		writer.write("INSERT INTO Core.UserInfo VALUES(" + 
		    getSequenceFunction("core.userinfo_sq", "nextval") +
			", 'dba', 'dba', 'Database', 'Administrator', 'unknown', NULL, " + getDateFunction() +
			",1,1,1,1,1,0,1,1,1,1);\n\n");
			
		writer.write("INSERT INTO Core.ProjectInfo (project_id, name, description, release, " +
			"modification_date, user_read, user_write," + 
			"group_read, group_write, other_read, other_write, row_user_id, " +
			"row_group_id, row_project_id, row_alg_invocation_id) " + 
			"VALUES(" + getSequenceFunction("core.projectinfo_sq", "nextval") +
			", 'Database administration', NULL, NULL, " + getDateFunction() +
			",1,1,1,1,1,0,1,1,1,1);\n\n");
			
		writer.write("INSERT INTO Core.GroupInfo VALUES(" + 
		    getSequenceFunction("core.groupinfo_sq", "nextval") +
			", 'dba', NULL, " + getDateFunction() + ",1,1,1,1,1,0,1,1,1,1);\n\n");

		writer.write("INSERT INTO Core.Algorithm VALUES (" +
		    getSequenceFunction("core.algorithm_sq", "nextval")  +
			", 'SQL*PLUS', NULL, " + getDateFunction() + ",1,1,1,1,1,0,1,1,1,1);\n\n");

		writer.write("INSERT INTO Core.AlgorithmImplementation (Algorithm_Implementation_id, " +
			"algorithm_id, version, cvs_revision, cvs_tag, executable, executable_md5, description, " +
			"modification_date, user_read, user_write," + 
			"group_read, group_write, other_read, other_write, row_user_id, " +
			"row_group_id, row_project_id, row_alg_invocation_id) VALUES (" +
			getSequenceFunction("core.algorithmimplementation_sq", "nextval") + ", " + 
			getSequenceFunction("core.algorithm_sq", "currval") +
			", 'unknown', NULL, NULL, NULL, NULL, NULL, " + getDateFunction() +
			",1,1,1,1,1,0,1,1,1,1);\n\n");
			
		writer.write("INSERT INTO Core.AlgorithmInvocation (algorithm_invocation_id, " +
			"algorithm_implementation_id, start_time, end_time, cpus_used, cpu_time, result, " +
			"comment_string, modification_date, user_read, user_write," + 
			"group_read, group_write, other_read, other_write, row_user_id, " +
			"row_group_id, row_project_id, row_alg_invocation_id) VALUES (" +
			getSequenceFunction("core.algorithminvocation_sq", "nextval") + ", " +
			getSequenceFunction("core.algorithminvocation_sq", "currval") + ", " +
			getDateFunction() + ","  +getDateFunction() + ", NULL, NULL, 'Row(s) inserted', NULL, "
			+ getDateFunction() + ",1,1,1,1,1,0,1,1,1,1);\n\n");

		String apktHead = "Insert INTO Core.AlgorithmParamKeyType VALUES(" + 
						getSequenceFunction("core.AlgorithmParamKeyType_SQ", "nextval");
		String apktTail = getDateFunction() + ",1,1,1,1,1,0,1,1,1,1);\n\n";

		writer.write( apktHead + ",'string'," + apktTail);
		writer.write( apktHead +  ",'float'," + apktTail);
		writer.write( apktHead +  ",'int'," + apktTail);
		writer.write( apktHead +  ",'ref'," + apktTail);
		writer.write( apktHead +  ",'boolean'," + apktTail);
		writer.write( apktHead +  ",'date'," + apktTail);
		
		if (dbVendor.equalsIgnoreCase("Postgres")) {
			writer.write( "\nCOMMIT;\n" );
		}
		writer.flush();		
	}
	
	private void writeDatabaseInfo( Schema schema ) throws IOException {
		writer.write( "INSERT INTO core.databaseinfo " );
		writer.write( "(database_id, name, description, modification_date, user_read, " +
			"user_write, group_read, group_write, other_read, other_write, row_user_id, row_group_id, " +
			"row_project_id, row_alg_invocation_id ) VALUES (" );
		writer.write( getSchemaID( schema ) + ", '" + schema.getName() + "', " +
			"'" + schema.getName() + " schema', " + getDateFunction() + ",1,1,1,1,1,0,1,1,1,1);\n" );
		writer.flush();
	}


	private void writeTableInfo( Table table ) throws IOException {
		log.debug( "Writing TableInfo for " + table.getName() );
		if ( written.contains( table ) ) {
			return;
		}
		if ( table.getSuperclass() != null &&
			!written.contains( table.getSuperclass() ) ) {
			writeTableInfo( table.getSuperclass() );
		}
		writer.write( "INSERT INTO core.tableinfo " );
		writer.write( " (table_id, name, table_type, primary_key_column, database_id, is_versioned,  is_view," );
		writer.write( " view_on_table_id, superclass_table_id, is_updatable, modification_date, user_read, " +
			"user_write, group_read, group_write, other_read, other_write, row_user_id, row_group_id, " +
			"row_project_id, row_alg_invocation_id)" );
		writer.flush();
		writer.write( " VALUES (" );
		writer.write( getTableID( table ) + ", '" + table.getName() + "', '" + getTableType( table ) + "', " );
        String pk = ( table instanceof GusTable) ? getPrimaryKey((GusTable) table) : "null";
        writer.write( pk + ", " + getSchemaID( table.getSchema() ) + ", " );

		// IGNORE isVersioned setting as we no longer create version schemas
		writer.write( "0" );
		// if ( table.getClass() == GusTable.class ) {
		//	writer.write( b2i( ( (GusTable) table ).isVersioned() ) + "" );
		// }
		// else {
		//	writer.write( "0" );
		// }

		writer.write(",0,null,");
		if ( table.getSuperclass() != null ) {
			writer.write( "" + getTableID( table.getSuperclass() ) );
		}
		else {
			writer.write( "null" );
		}
		writer.write( ", " + b2i( table.isUpdatable() ) + ", " + getDateFunction() + ", 1,1,1,1,1,0,1,1,1,1);\n" );
		writer.flush();
		written.add( table );
	}


	private void writeTableInfo( View view ) throws IOException {
		log.debug( "Writing TableInfo for " + view.getName() );
		if ( written.contains( view ) ) {
			return;
		}
		if ( view.getSuperclass() != null &&
			!written.contains( view.getSuperclass() ) ) {
			writeTableInfo( view.getSuperclass() );
		}
		writer.write( "INSERT INTO core.tableinfo " );
		writer.write( " (table_id, name, table_type, primary_key_column, database_id, is_versioned,  is_view," );
		writer.write( " view_on_table_id, superclass_table_id, is_updatable, modification_date, user_read, " +
			"user_write, group_read, group_write, other_read, other_write, row_user_id, row_group_id, " +
			"row_project_id, row_alg_invocation_id)" );
		writer.flush();
		writer.write( " VALUES (" );
		writer.write( getViewID( view ) + ", '" + view.getName() + "', '" + getTableType( view ) + "', " );
		String pk = ( view instanceof GusView) ? getPrimaryKey((GusView) view) : "null";
        writer.write( pk + ", " + getSchemaID( view.getSchema() ) + ", " );

		// IGNORE isVersioned setting as we no longer create version schemas
		writer.write( "0" );
		// if ( view.getClass() == GusView.class ) {
		// 	writer.write( b2i( ( (GusView) view ).isVersioned() ) + "" );
		// }
		// else {
		//  writer.write( "0" );
		// }
		writer.write( ", 1, " + getTableID( view.getTable() ) + ", " );
		if ( view.getSuperclass() != null ) {
			writer.write( "" + getViewID( view.getSuperclass() ) );
		}
		else {
			writer.write( "null" );
		}
		writer.write( ", " + b2i( view.getTable().isUpdatable() ) + ", " + getDateFunction() + ", 1,1,1,1,1,0,1,1,1,1);\n" );
		writer.flush();
		written.add( view );
	}

	private void fixSequence ( String name, int start ) throws IOException {
		writer.write( "DROP SEQUENCE " + name + ";\n" );
		writer.write( "CREATE SEQUENCE " + name + " START ");
		if ( dbVendor.compareToIgnoreCase("Oracle") == 0 ) {
		    writer.write(" WITH ");
		}
	        writer.write((start + 1) + ";\n\n");

        // Grants may be lost after dropping sequence. add them back.
        // PostgresWriter doesn't use roles.
		if ( dbVendor.compareToIgnoreCase("Oracle") == 0 ) {
            writer.write( "GRANT SELECT ON " + name + " TO GUS_W;\n" );
        }

		writer.flush();
	}
	
	private String getPrimaryKey( GusTable table ) {
		if ( table.getSuperclass() != null ) {
			return getPrimaryKey( table.getSuperclass() );
		}
		if ( table.getPrimaryKey() != null &&
                !table.getPrimaryKey().getConstrainedColumns().isEmpty()) {
			return "'" + ( (Column) table.getPrimaryKey().getConstrainedColumns().toArray()[0] ).getName() + "'";
		}
		log.error( "Could not find PK for table " + table.getName());
		return "NULL";
	}

	

	private String getPrimaryKey( GusView view ) {
		return getPrimaryKey( view.getTable() );
	}


	private int b2i( boolean bool ) {
		if ( bool ) {
			return 1;
		}
		else {
			return 0;
		}
	}


	private int getSchemaID( Schema schema ) {
		return getID( schemaIDs, schema );
	}


	private int getTableID( Table table ) {
		log.debug( "getting id for table " + table.getName() );
		return getID( tableAndViewIDs, table );
	}


	private int getViewID( View view ) {
		log.debug( "getting id for view " + view.getName() );
		return getID( tableAndViewIDs, view );
	}


	private String getTableType( Table table ) {
		if ( table.getClass() == VersionTable.class ) {
			return "Version";
		}
		else {
			return "Standard";
		}
	}


	private String getTableType( View view ) {
		if ( view.getClass() == VersionView.class ) {
			return "Version";
		}
		else {
			return "Standard";
		}
	}
	
	private String getSequenceFunction(String sequenceName, String function) {
		if ( dbVendor.compareToIgnoreCase("Oracle") == 0 ) {
			return sequenceName + "." + function;
		}
		else if ( dbVendor.compareToIgnoreCase("Postgres") == 0 ) {
			return function + "('" + sequenceName + "')";
		}
		else { 
			log.error("Unknown DB Vendor: '" + dbVendor + "', returning null as sequence function");
			return null;
		}		
	}
	
	private String getDateFunction() {
		if ( dbVendor.compareToIgnoreCase("Oracle") == 0 ) {
			return "sysdate";
		}
		else if ( dbVendor.compareToIgnoreCase("Postgres") == 0 ) {
			return "now()";
		}
		else { 
			log.error("Unknown DB Vendor: '" + dbVendor + "', returning null as date function");
			return null;
		}
	}
	
	private int getID( Map<?,?> map, Object obj ) {
		for ( int i = 1; i < map.size() + 1; i++ ) {
			if ( map.get(i) == obj ) {
				return i;
			}
		}
		//	return addToMap(map, obj);
		log.error( "Object does not exist in map" );
		throw new RuntimeException( "Object does not exist in the map" );
	}

}


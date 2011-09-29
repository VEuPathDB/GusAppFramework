/*
 * Created on Feb 3, 2005
 */
package org.gusdb.dbadmin.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Properties;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.reader.XMLReader;
import org.gusdb.dbadmin.writer.OracleWriter;
import org.gusdb.dbadmin.writer.PostgresWriter;
import org.gusdb.dbadmin.writer.SchemaWriter;

/**
 * @author msaffitz
 * @created May 2, 2005
 * @version $Revision$ $Date: 2005-10-28 10:01:12 -0400 (Fri, 28 Oct
 *          2005) $
 */
public class InstallSchemaTask extends Task {

    private static Log log = LogFactory.getLog( InstallSchemaTask.class );

    private Database   db;
    private Connection conn;

    private String     gusHome;
    private String     schema;
    private boolean    skipRoles = false;
    private String     dbVendor;
    private String     dbDsn;
    private String     dbUsername;
    private String     dbPassword;
    private String     tablespace;

    public void setGusHome( String gusHome ) {
        this.gusHome = gusHome;
    }

    public void setSchema( String schema ) {
        this.schema = schema;
    }

    public void setSkipRoles( String skipRoles ) {
        this.skipRoles = skipRoles != null && skipRoles.equals("true");
    }

    public void execute( ) throws BuildException {
        initialize( );

        XMLReader xr = new XMLReader( schema );
        SchemaWriter dbWriter = null;

        if ( dbVendor.compareToIgnoreCase( "Postgres" ) == 0 ) {
            dbWriter = new PostgresWriter( );
        }
        else if ( dbVendor.compareToIgnoreCase( "Oracle" ) == 0 ) {
            dbWriter = new OracleWriter( );
	    ((OracleWriter)dbWriter).setSkipRoles(skipRoles);
        }
        else {
            log.error( "Unknown DB Vendor: '" + dbVendor + "'" );
            throw new BuildException( "Unknown DB Vendor: '" + dbVendor + "'" );
        }

        log.info( "Reading database from " + schema );
        db = xr.read( );

        FileWriter ddl;
        FileWriter rows;

        convertSubclasses( db );
        DatabaseUtilities.setTablespace( db, this.tablespace );

        try {
            ddl = new FileWriter( gusHome + "/config/SchemaInstall-objects.sql" );
            rows = new FileWriter( gusHome + "/config/SchemaInstall-rows.sql" );

            JDBCStreamWriter rdbms = new JDBCStreamWriter( conn );
            MetadataPopulator mp = new MetadataPopulator( rows, db, dbVendor );

            dbWriter.write( ddl, db );
            dbWriter.write( rdbms, db );

            mp.writeDatabaseAndTableInfo( );
            mp.writeBootstrapData( );
            conditionalWriteVersion(mp, db);
            
            mp = new MetadataPopulator( rdbms, db, dbVendor );

            mp.writeDatabaseAndTableInfo( );
            mp.writeBootstrapData( );
            conditionalWriteVersion(mp, db);

            rows.close( );
            ddl.close( );
            rdbms.close( );
        }
        catch ( IOException e ) {
            throw new BuildException( e );
        }
    }
    
    private void conditionalWriteVersion( MetadataPopulator mp, Database db ) throws IOException {
        if ( db.getVersion() == 0.0f ) {
            log.error("Null version, skipping.  Note:  You will need to manually add a version number to the DB");
        } else {
            mp.writeDatabaseVersion( db.getVersion() );
        }
    }

    private void convertSubclasses( Database db ) {
        ArrayList<GusTable> superClasses = new ArrayList<GusTable>( );

        for ( GusTable table : db.getGusTables( ) ) {
            if ( !table.getSubclasses( ).isEmpty( ) ) {
                superClasses.add( table );
            }
        }
        for ( GusTable table : superClasses ) {
            GusClassHierarchyConverter converter = new GusClassHierarchyConverter( table );

            converter.convert( );
        }
    }

    private void initialize( ) throws BuildException {
        System.setProperty( "XMLDATAFILE", schema );
        System.setProperty( "PROPERTYFILE", gusHome + "/config/gus.config" );

        Properties props = new Properties( );

        try {
            File propertyFile = new File( System.getProperty( "PROPERTYFILE" ) );

            props.load( new FileInputStream( propertyFile ) );
        }
        catch ( IOException e ) {
            log.error( "Unable to get properties from gus.config", e );
            throw new BuildException( "Unable to get properties from gus.config", e );
        }

        this.dbVendor = props.getProperty( "dbVendor" );
        this.dbDsn = props.getProperty( "jdbcDsn" );
        this.dbUsername = props.getProperty( "databaseLogin" );
        this.dbPassword = props.getProperty( "databasePassword" );
        this.tablespace = props.getProperty( "tablespace" );

        try {
            Class.forName( "org.postgresql.Driver" );
            Class.forName( "oracle.jdbc.OracleDriver" );
        }
        catch ( ClassNotFoundException e ) {
            log.fatal( "Unable to locate class", e );
            throw new BuildException( "Unable to locate class", e );
        }
        try {
            conn = DriverManager.getConnection( dbDsn, dbUsername, dbPassword );
        }
        catch ( SQLException e ) {
            log.error( "Unable to connect to database.  DSN='" + dbDsn + "'", e );
            throw new BuildException( "Unable to connect to database", e );
        }
    }

}

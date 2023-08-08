/**
 * $Id$
 * Created on Nov 16, 2004
 */
package org.gusdb.dbadmin.reader;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

import org.apache.commons.digester3.Digester;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.gusdb.dbadmin.model.Constraint;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusColumn;
import org.gusdb.dbadmin.model.GusSchema;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Index;
import org.gusdb.dbadmin.model.Table;
import org.gusdb.dbadmin.model.VersionTable;

/**
 * @author msaffitz
 * @version $Revision$
 */
public class XMLReader extends SchemaReader {

    private static final Logger log = LogManager.getLogger(XMLReader.class);

    private FileInputStream XMLFile;
    private Digester        digester = new Digester( );

    public XMLReader( String schemaSpec ) {
        try {
            XMLFile = new FileInputStream( new File( schemaSpec ) );
        }
        catch ( FileNotFoundException e ) {
            log.error( "Unable to find XML Data File: " + schemaSpec, e );
            throw new RuntimeException( e );
        }
    }

    @Override
    protected Database readDatabase( Database db ) {
        try {
            db = (Database) digester.parse( XMLFile );
            addHousekeeping( db );
            db.resolveReferences( );
            return db;
        }
        catch ( Exception e ) {
            log.error( "Unable to read XML database", e );
            throw new RuntimeException( e );
        }
    }

    private void addHousekeeping( Database db ) {
        for ( Table table : db.getAllTables() ) {
            if ( table.getClass( ) == VersionTable.class ) table.setHousekeepingColumns( verHousekeepingColumns );
            else table.setHousekeepingColumns( housekeepingColumns );
        }
    }

    @Override
    protected void setUp( ) {

        String[] columnAttrs = new String[] { "ref", "name", "nullable", "length", "precision", "type" };
        String[] columnProps = new String[] { "ref", "name", "nullable", "length", "precision" };
        String[] constAttrs = new String[] { "name", "type" };
        String[] constProps = new String[] { "name" };
        String[] indexAttrs = new String[] { "name", "tablespace", "type" };
        String[] indexProps = new String[] { "name", "tablespace" };

        digester.setValidating( false );

        digester.addObjectCreate( "database", Database.class );
        digester.addSetProperties( "database" );

        digester.addObjectCreate( "database/schemas/schema", GusSchema.class );
        digester.addSetProperties( "database/schemas/schema" );
        digester.addSetNext( "database/schemas/schema", "addSchema" );

        digester.addObjectCreate( "database/schemas/schema/tables/table", GusTable.class );
        digester.addSetProperties( "database/schemas/schema/tables/table" );
        digester.addBeanPropertySetter( "database/schemas/schema/tables/table/documentation" );
        digester.addSetNext( "database/schemas/schema/tables/table", "addTable" );

        digester.addObjectCreate( "database/schemas/schema/tables/table/columns/column", GusColumn.class );
        digester.addCallMethod( "database/schemas/schema/tables/table/columns/column", "setType", 1 );
        digester.addCallParam( "database/schemas/schema/tables/table/columns/column", 0, "type" );
        digester.addSetProperties( "database/schemas/schema/tables/table/columns/column", columnAttrs, columnProps );
        digester.addBeanPropertySetter( "database/schemas/schema/tables/table/columns/column/documentation" );
        digester.addSetNext( "database/schemas/schema/tables/table/columns/column", "addColumn" );

        digester.addObjectCreate( "database/schemas/schema/tables/table/subclasses/subclass", GusTable.class );
        digester.addSetProperties( "database/schemas/schema/tables/table/subclasses/subclass" );
        digester.addBeanPropertySetter( "database/schemas/schema/tables/table/documentation" );
        digester.addSetNext( "database/schemas/schema/tables/table/subclasses/subclass", "addSubclass" );

        digester.addObjectCreate( "database/schemas/schema/tables/table/subclasses/subclass/columns/column", GusColumn.class );
        digester.addCallMethod( "database/schemas/schema/tables/table/subclasses/subclass/columns/column", "setType", 1 );
        digester.addCallParam( "database/schemas/schema/tables/table/subclasses/subclass/columns/column", 0, "type" );
        digester.addSetProperties( "database/schemas/schema/tables/table/subclasses/subclass/columns/column", columnAttrs, columnProps );
        digester.addBeanPropertySetter( "database/schemas/schema/tables/table/subclasses/subclass/columns/column/documentation" );
        digester.addSetNext( "database/schemas/schema/tables/table/subclasses/subclass/columns/column", "addColumn" );

        digester.addObjectCreate( "database/schemas/schema/tables/table/indexes/index", Index.class );
        digester.addCallMethod( "database/schemas/schema/tables/table/indexes/index", "setType", 1 );
        digester.addCallParam( "database/schemas/schema/tables/table/indexes/index", 0, "type" );
        digester.addSetProperties( "database/schemas/schema/tables/table/indexes/index", indexAttrs, indexProps );
        digester.addSetNext( "database/schemas/schema/tables/table/indexes/index", "addIndex" );

        digester.addCallMethod( "database/schemas/schema/tables/table/indexes/index/columns/column", "addColumnRef", 1 );
        digester.addCallParam( "database/schemas/schema/tables/table/indexes/index/columns/column", 0, "idref" );

        digester.addObjectCreate( "database/schemas/schema/tables/table/constraints/constraint", Constraint.class );
        digester.addCallMethod( "database/schemas/schema/tables/table/constraints/constraint", "setType", 1 );
        digester.addCallParam( "database/schemas/schema/tables/table/constraints/constraint", 0, "type" );
        digester.addSetProperties( "database/schemas/schema/tables/table/constraints/constraint", constAttrs,constProps );
        digester.addSetNext( "database/schemas/schema/tables/table/constraints/constraint", "addConstraint" );

        digester.addCallMethod("database/schemas/schema/tables/table/constraints/constraint/constrainedColumns/column","addConstrainedColumnRef", 1 );
        digester.addCallParam( "database/schemas/schema/tables/table/constraints/constraint/constrainedColumns/column", 0, "idref" );

        digester.addCallMethod( "database/schemas/schema/tables/table/constraints/constraint/referencedTable","setReferencedTableRef", 1 );
        digester.addCallParam( "database/schemas/schema/tables/table/constraints/constraint/referencedTable", 0, "idref" );

        digester.addCallMethod( "database/schemas/schema/tables/table/constraints/constraint/referencedColumns/column","addReferencedColumnRef", 1 );
        digester.addCallParam( "database/schemas/schema/tables/table/constraints/constraint/referencedColumns/column",0, "idref" );

    }

    @Override
    protected void tearDown( ) {
        try {
            this.XMLFile.close( );
        }
        catch ( IOException e ) {
            log.warn( "Error closing FileInputStream", e );
        }
    }
}

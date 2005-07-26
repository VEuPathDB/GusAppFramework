/**
 * $Id$ Created on Nov 16, 2004
 */
package org.gusdb.dbadmin.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.LineNumberReader;
import java.util.ArrayList;
import java.util.Iterator;

import org.apache.commons.digester.Digester;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.gusdb.dbadmin.model.Category;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.dbadmin.model.SuperCategory;
import org.gusdb.dbadmin.reader.SchemaReader;
import org.xml.sax.SAXException;

/**
 * @author msaffitz
 * @version $Revision: 3092 $
 */
public class CategoryReader {

    protected static final Log log = LogFactory.getLog( SchemaReader.class );

    /**
     * @param db Database to populate
     * @param categoryMapFile CSV map file: category, schema, table
     */
    public static void setCategories( Database db, String categoryMapFile ) {
        try {
            LineNumberReader mapFile = new LineNumberReader( new FileReader( new File( categoryMapFile ) ) );
            String nextLine = mapFile.readLine( );
            while ( nextLine != null ) {
                String[] values = nextLine.split( "," );
                if ( values.length != 3 || values[0] == null || values[1] == null || values[2] == null ) {
                    throw new RuntimeException( "Invalid format: '" + nextLine + "'" );
                }
                Schema schema = db.getSchema( values[1] );
                if ( schema == null ) {
                    log.warn( "Unable to locate schema: '" + values[1] + "'" );
                    nextLine = mapFile.readLine();
                    continue;
                }
                GusTable table = (GusTable) schema.getTable( values[2] );
                if ( table == null ) {
                    log.warn( "Unable to locate table: '" + values[2] + "' in schema: '" + values[1] + "'" );
                    nextLine = mapFile.readLine();
                    continue;
                }
                table.setCategoryRef( values[0] );
                nextLine = mapFile.readLine( );
            }
            mapFile.close( );
            for ( Iterator i = db.getTables( true ).iterator( ); i.hasNext( ); ) {
                ((GusTable) i.next( )).resolveCategoryReference( );
            }
        }
        catch ( FileNotFoundException e ) {
            log.error( "Unable to find map file: '" + categoryMapFile + "'" );
            throw new RuntimeException( e );
        }
        catch ( IOException e ) {
            log.error( "IO Exception reading and parsing map file", e );
            throw new RuntimeException( e );
        }

    }

    public static ArrayList readCategories( String categoryXMLFile ) {
        FileInputStream xmlFile;
        Digester digester = getDigester( );
        ArrayList categories;

        try {
            xmlFile = new FileInputStream( new File( categoryXMLFile ) );
            categories = (ArrayList) digester.parse( xmlFile );
            xmlFile.close( );
        }
        catch ( FileNotFoundException e ) {
            log.error( "Unable to find XML Category File: '" + categoryXMLFile + "'" );
            throw new RuntimeException( e );
        }
        catch ( IOException e ) {
            log.error( "IO Error in reading category file", e );
            throw new RuntimeException( e );
        }
        catch ( SAXException e ) {
            log.error( "Parser Error in reading category file", e );
            throw new RuntimeException( e );
        }

        return categories;
    }

    private static Digester getDigester( ) {
        Digester digester = new Digester( );

        digester.setValidating( false );

        digester.addObjectCreate( "organization", ArrayList.class );
        digester.addSetProperties( "organization" );

        digester.addObjectCreate( "organization/supercategory", SuperCategory.class );
        digester.addSetProperties( "organization/supercategory" );
        digester.addSetNext( "organization/supercategory", "add" );

        digester.addObjectCreate( "organization/supercategory/category", Category.class );
        digester.addSetProperties( "organization/supercategory/category" );
        digester.addSetNext( "organization/supercategory/category", "addCategory" );

        return digester;
    }

}

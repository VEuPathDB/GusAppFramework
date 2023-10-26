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

import org.apache.commons.digester3.Digester;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.gusdb.dbadmin.model.Category;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.dbadmin.model.SuperCategory;
import org.xml.sax.SAXException;

/**
 * @author msaffitz
 * @version $Revision: 3092 $
 */
public class CategoryReader {

    private static final Logger log = LogManager.getLogger( CategoryReader.class );

    /**
     * @param db Database to populate
     * @param categoryMapFile CSV map file: category, schema, table
     */
    public static void setCategories( Database db, String categoryMapFile ) {
        LineNumberReader mapFile = null;
        try {
            mapFile = new LineNumberReader( new FileReader( new File( categoryMapFile ) ) );
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
            for ( GusTable table : db.getGusTables() ) {
                table.resolveCategoryReference( );
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
        finally {
          if (mapFile != null)
            try { mapFile.close(); }
            catch (IOException e) { log.error("Unable to close map file reader", e); }
        }
    }
    
    @SuppressWarnings("unchecked")
    public static ArrayList<SuperCategory> readCategories( String categoryXMLFile ) {
        FileInputStream xmlFile;
        Digester digester = getDigester( );
        ArrayList<SuperCategory> categories;

        try {
            xmlFile = new FileInputStream( new File( categoryXMLFile ) );
            categories = (ArrayList<SuperCategory>) digester.parse( xmlFile );
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

        log.debug("Read " + categories.size() + "supercatgories.");
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

/**
 * $Id$
 */

package org.gusdb.schemabrowser;

import java.util.Iterator;

import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.reader.XMLReader;

import org.gusdb.dbadmin.util.CategoryReader;

/**
 * @author msaffitz
 */
public class DatabaseFactory {

    private Database db;
    private String dbSource;
    private String categorySource;
    private String propFile;

    public String getDatabaseSource() {
        return dbSource;
    }
    
    public void setDatabaseSource(String dbSource) {
        this.dbSource = dbSource;
    }
    
    public String getCategorySource() {
        return categorySource;
    }
    
    public void setCategorySource(String categorySource) {
        this.categorySource = categorySource;
    }
    
    public Database getDatabase( ) {
        if ( db == null ) {
            XMLReader schemaReader = new XMLReader( getDatabaseSource() );
            db = schemaReader.read( );
            db.setSuperCategories(CategoryReader.readCategories( getCategorySource() ));
            for ( Iterator i = db.getTables(true).iterator(); i.hasNext(); ) {
                ((GusTable) i.next()).resolveCategoryReference();
            }
        }
        return db;
    }

    public void setDatabase( Database db ) {
        this.db = db;
    }
    
    public void setPropertyFile(String propFile) {
        System.setProperty("PROPERTYFILE", propFile);
        this.propFile = propFile;
    }
    
    public String getPropertyFile() {
        return this.propFile;
    }
}

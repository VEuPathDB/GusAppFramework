/**
 * $Id:$
 */
package org.gusdb.schemabrowser.dao;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.gusdb.schemabrowser.model.Documentation;
import org.springframework.orm.hibernate.support.HibernateDaoSupport;

/**
 * @author msaffitz
 */
public class DocumentationDAO extends HibernateDaoSupport {

    private Log  log = LogFactory.getLog( HibernateDaoSupport.class );
    private static HashMap docCache = new HashMap();
    
    public DocumentationDAO( ) {
        super( );
    }

    public String getDocumentation( String schema ) {
        if ( getDocumentationObject(schema, null, null ) == null ) return null;
        return getDocumentationObject(schema, null, null).getDocumentation();
    }

    public String getDocumentation( String schema, String table ) {
        if ( getDocumentationObject(schema, table, null ) == null ) return null;
        return getDocumentationObject(schema, table, null).getDocumentation();
    }

    public String getDocumentation( String schema, String table, String attribute ) {
        if ( getDocumentationObject(schema, table, attribute ) == null ) return null;
        return getDocumentationObject(schema, table, attribute).getDocumentation();
    }

    public Documentation getDocumentationObject( String schema, String table, String attribute ) {
        String key = (schema + table + attribute).toLowerCase();
        
        if ( docCache.containsKey( key )) { 
            return (Documentation) docCache.get( key );
        } else {
            return fetchObject( schema, table, attribute);
        }
    }

    /**
     * @param doc Documentation object to be persisted
     */
    public void saveDocumentationObject( Documentation doc ) {
        doc.setCreatedOn(new Date());
        getHibernateTemplate().save(doc);
        cacheObject(doc);
    }
    
    private Documentation fetchObject( String schema, String table, String attribute ) {
        ArrayList values = new ArrayList();
        values.add(schema);
        
        String query = "from Documentation where schemaname = ? ";

        if ( table != null && ! table.equalsIgnoreCase("null") ) {
            query = query.concat(" and tablename = ? ");
            values.add(table);
            if ( attribute != null && ! attribute.equalsIgnoreCase("null") ) {
                query = query.concat( " and attributename = ? ");
                values.add(attribute);
            }
        }
        
        query = query.concat( "order by createdon desc");

        log.debug("running query: " + query + " with '" + values.subList(0,values.size()).toString() + "'");
        
        List docColl = getHibernateTemplate().find(query, values.subList(0,values.size()).toArray() );
        if ( docColl.size() == 0 ) return null;
        cacheObject((Documentation) docColl.get(0));
        return (Documentation) docColl.get(0);
    }
    
    private void cacheObject(Documentation doc) {
        String key = (doc.getSchemaName() + doc.getTableName() + doc.getAttributeName()).toLowerCase();
        log.debug("Caching: '" + key + "'");
        docCache.put(key, doc);
    }

}

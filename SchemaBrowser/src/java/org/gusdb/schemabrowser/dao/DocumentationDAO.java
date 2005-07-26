/**
 * $Id:$
 */
package org.gusdb.schemabrowser.dao;

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
    // TODO REALLY USE STATIC?    
    private static HashMap docCache = new HashMap();
    
    public DocumentationDAO( ) {
        super( );
    }

    public String getDocumentation( String schema ) {
        if ( getDocumentationObject(schema, null, null ) == null ) return null;
        return getDocumentationObject(schema, null, null).getDocumentation();
    }

    public String getDocumentation( String schema, String table ) {
        if ( getDocumentationObject(schema, null, null ) == null ) return null;
        return getDocumentationObject(schema, null, null).getDocumentation();
    }

    public String getDocumentation( String schema, String table, String attribute ) {
        if ( getDocumentationObject(schema, null, null ) == null ) return null;
        return getDocumentationObject(schema, null, null).getDocumentation();
    }

    public Documentation getDocumentationObject( String schema, String table, String attribute ) {
        if ( table == null ) { table = new String(); }
        if ( attribute == null ) { attribute = new String(); }
        String key = schema.toLowerCase() + table.toLowerCase() + attribute.toLowerCase();
        
        if ( docCache.containsKey( key )) { 
            return (Documentation) docCache.get( key );
        } else {
            return fetchObject( schema, table, attribute);
        }
    }

    /**
     * @param doc
     */
    public void saveDocumentationObject( Documentation doc ) {
        doc.setCreatedOn(new Date());
        getHibernateTemplate().save(doc);
        fetchObject( doc.getSchemaName(), doc.getTableName(), doc.getAttributeName() );
    }
    
    private Documentation fetchObject( String schema, String table, String attribute ) {
        return null;
        /*
        String[] values = new String[3];
        String query = "from Documentation where schemaname = ? ";
        values[0] = schema;

        if ( table != null ) {
            query = query.concat(" and tablename = ? ");
            values[1] = table;
            if ( schema != null ) {
                query = query.concat( " and attributename = ?");
                values[2] = attribute;
            }
        }
        query = query.concat( " order by createdon desc");

        List docColl = getHibernateTemplate().find(query, values);
        if ( docColl.size() == 0 ) return null;
        cacheObject((Documentation) docColl.get(0));
        return (Documentation) docColl.get(0);
        */
    }
    
    private void cacheObject(Documentation doc) {
        String key = doc.getSchemaName().toLowerCase() + doc.getTableName().toLowerCase() + 
            doc.getAttributeName().toLowerCase();
        docCache.put(key, doc);
    }

}

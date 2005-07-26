/**
 * 
 */
package org.gusdb.schemabrowser.model;

import java.io.Serializable;
import java.util.Date;

/**
 * @hibernate.class
 * @author msaffitz
 */
public class Documentation implements Serializable {

    private long   id;
    private String schema;
    private String table;
    private String attribute;
    private String documentation;
    private Date   created_on;

    public Documentation( ) {}

    /**
     * @hibernate.id generator-class="native"
     */
    public long getId( ) {
        return this.id;
    }

    public void setId( long id ) {
        this.id = id;
    }

    /**
     * @hibernate.property
     * @return Schema name for this documented object
     */
    public String getSchemaName( ) {
        return this.schema;
    }

    public void setSchemaName( String schema ) {
        this.schema = schema;
    }

    /**
     * @hibernate.property
     * @return Table name for this documented object
     */
    public String getTableName( ) {
        return this.table;
    }

    public void setTableName( String table ) {
        this.table = table;
    }

    /**
     * @hibernate.property
     * @return Column name for this documented object
     */
    public String getAttributeName( ) {
        return this.attribute;
    }

    public void setAttributeName( String attribute ) {
        this.attribute = attribute;
    }

    /**
     * @hibernate.property
     * @return Documentation for this object
     */
    public String getDocumentation( ) {
        return this.documentation;
    }

    public void setDocumentation( String documentation ) {
        this.documentation = documentation;
    }

    /**
     * @hibernate.property
     * @return Date this object was saved
     */
    public Date getCreatedOn( ) {
        return this.created_on;
    }

    public void setCreatedOn( Date created_on ) {
        this.created_on = created_on;
    }

}

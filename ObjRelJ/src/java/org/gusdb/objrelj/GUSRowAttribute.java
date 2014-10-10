package org.gusdb.objrelj;


/**
 * GUSRowAttribute.java
 *
 * Represents an attribute value for a single row in a GUS table.  Cannot be accessed
 * by an application using the GUSRow, but helps the Object Layer track attributes
 * and manage submits.
 *
 * Created: Wed January 7 14:45:00 2004
 *
 * @author Dave Barkan
 */
public class GUSRowAttribute implements java.io.Serializable {

    // ------------------------------------------------------------------
    // Instance Variables
    // ------------------------------------------------------------------

    private static final long serialVersionUID = 1L;

    /**
     * The value of this attribute as it currently exists in the database.  Should be updated
     * when changes are made to the row in the database.
     */
    private Object dbValue;

    /** 
     * The value of this attribute as it is regarded by whatever application is using the GUSRow that 
     * owns it. Will initially be the database value (or null, if it hasn't been retrieved from the database)
     * but will change whenever the application updates it.
     */
    private Object currentValue;


    /**
     * Whether this attribute has been modified by the application using the GUSRow that owns it.
     */
    private boolean attributeSetByApp;

    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------
    
    public GUSRowAttribute(Object value){

	this.dbValue = value;
	this.currentValue = value;
	this.attributeSetByApp = false;

    }
    
    
    // ------------------------------------------------------------------
    // Public Methods
    // ------------------------------------------------------------------
    
    /**
     * Get the value of the attribute in preparation to submit its GUSRow to the database.
     * For right now, just return <code>currentValue</code>.
     */
    public Object getSubmitValue(){
	if (currentValue instanceof GUSRow){  //foreign key attribute
	    //DTB:  Throw exception or return null if pk value == -1?
	    return new Long(((GUSRow)currentValue).getPrimaryKeyValue());
	}
	else{
	    return currentValue;
	}
    }

    public Object getCurrentValue(){
	/*	if (currentValue instanceof GUSRow){  //foreign key attribute
	    
	    return new Long(((GUSRow)currentValue).getPrimaryKeyValue());
	    }*/
	return currentValue;
    }

    protected void setCurrentValue(Object value){
	this.currentValue = value;
    }

    public Object getDbValue(){
	/*	if (dbValue instanceof GUSRow){  //foreign key attribute
	    
	    return new Long(((GUSRow)dbValue).getPrimaryKeyValue());
	    }*/
	return dbValue;

    }

    protected void setDbValue(Object newValue){
	this.dbValue = newValue;
    }

    public void setAttributeSetByApp(boolean attributeSetByApp){
	this.attributeSetByApp = attributeSetByApp;
    }

    public boolean isSetByApp(){
	return attributeSetByApp;
    }

    protected void syncAttWithDb(){
	this.dbValue = this.currentValue;
	this.attributeSetByApp = false;
    }

}

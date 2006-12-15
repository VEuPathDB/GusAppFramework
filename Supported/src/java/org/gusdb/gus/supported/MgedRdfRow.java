package org.gusdb.gus.supported;

import com.hp.hpl.jena.rdf.model.Literal;
import com.hp.hpl.jena.rdf.model.Property;
import com.hp.hpl.jena.rdf.model.RDFNode;
import com.hp.hpl.jena.rdf.model.Resource;
import com.hp.hpl.jena.rdf.model.Statement;
import com.hp.hpl.jena.rdf.model.StmtIterator;

/**
 * Store the Strings which make up an Owl RDF statment as instance variables.  
 * Convert these to the appropriate output strings which can easily be 
 * read into GUS.
 * 
 * @author John Brestelli
 *
 */
public class MgedRdfRow implements GusRdfRow {

    private Statement statement;
	
    private String subject = "";
    private String predicate = "";
    private String object = "";
	
    private String propPredicate = "";
    private String propType = "";
    private String propObject = "";
	
    public MgedRdfRow (Statement statement) {
        this.statement = statement;
    }

    public void parse () {

        Resource  subjectObj   = statement.getSubject();
        Property  predicateObj = statement.getPredicate();
        RDFNode   objectObj    = statement.getObject();

        this.subject  = subjectObj.getLocalName();
        this.predicate = predicateObj.getLocalName();
        this.object = getObjectString(objectObj);
			
        if (this.object == null && objectObj instanceof Resource) {
            Resource r = (Resource) objectObj;
            StmtIterator properties = r.listProperties();

            while (properties.hasNext()) {
                Statement propStatement = properties.nextStatement();
		
                RDFNode propObject = propStatement.getObject();
                Property propPredicate = propStatement.getPredicate();
                
                String propObjString = getObjectString(propObject);
                String propPredString = propPredicate.getLocalName();
		
                parsePropertyStatement(propObjString, propPredString);
            }
        }
    }

    /**
     * The <code>RDFNode</code> object can either be a <code>Resource</code>
     * or a <code>Literal</code>.  Gets the String representation either way.
     * 
     * @param object
     * @return
     *     The String representation of the <code>RDFNode</code>
     */
    private static String getObjectString (RDFNode object) {
        if (object instanceof Resource) {
            Resource r = (Resource) object;
            return r.getLocalName();
        }
        else {
            Literal objectLiteral = (Literal) object;
            return objectLiteral.getValue().toString();
        }
    }


    /**
     * Skip some stuff which definetly won't be read into GUS...
     * 
     * @return
     *     true if it should be written
     */
    public boolean isValid () {
        if(subject == "" || subject == null) {
            return false;
        }

        if(subject.equals("MGEDOntology.owl")) {
            return false;
        }
        if(predicate.equals("class_role") || predicate.equals("class_source") || predicate.equals("unique_identifier") || predicate.equals("synonym")) {
            return false;
        }
        if(predicate.equals("DataRange") && object.equals("oneOf")) {
            return false;
        }
        return true;
    }
	
    /**
     * @return 
     *     Simple String Representation of the object
     */
    public String toString () {
        if(object != null) {
            object = object.replace("\n", "");
        }
		
        return subject + "\t" + predicate + "\t" + object;
    }
	
    /**
     * Based on the RDF type.... create the appropriate output string.
     * 
     * @return
     *     string which can easily be read into GUS
     */
    public String getOutputString () {
        String out;
		
        // If the object is null... that means it is someValuesFrom or hasDataType
        if(object == null || object == "") {
            
            // Change for hasDataType
            if((propType.equals("someValuesFrom") || propType.equals("hasClass")) && propObject.equals("string")) {
                propObject = "hasDataType";
            }
            out = subject + "\t" + propPredicate + "\t" + propObject + "\t" + propType;
        }
        // Need to shift the values around for these...
        else if(predicate.equals("subClassOf") || predicate.equals("domain")) {
            out = subject + "\t" + "" + "\t" + object + "\t" + predicate;
        }
        else if(predicate.equals("comment")) {
            if(object != null) {
                object = object.replace("\n", "");
            }
            out = subject + "\t" + "" + "\t" + object + "\t" + "definition";
        }
        // type is called instanceOf in GUS
        else if(predicate.equals("type")) {
            out = subject + "\t" + "" + "\t" + object + "\t" + "instanceOf";
        }
        // The rest are hasInstance
        else {
            out =  toString() + "\t" + "hasInstance";
        }
        return out;
    }
	
    /**
     * Properties are the strangest things with Jena/owl... (there are several
     * sets of objects and predicates for each statment.)
     * 
     * @param os
     *     one of the property object strings
     * @param ps
     *     oen of the property predicate strings
     */
    public void parsePropertyStatement (String os, String ps) {
        if(propType.equals("oneOf")) {
            propObject = os;
            return;
        }
		
        if(ps.equals("onProperty")) {
            this.propPredicate = os;
        }
        else if (os == null) {
            this.propType = ps;
        }
        else if(os.equals("Restriction")) {}
        else {
            this.propType = ps;
            this.propObject = os;
        }
    }

}

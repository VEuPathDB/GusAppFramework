package org.gusdb.gus.supported;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.Iterator;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.model.IRI;
import org.semanticweb.owlapi.model.OWLAnnotationProperty;
import org.semanticweb.owlapi.model.OWLClassExpression;
import org.semanticweb.owlapi.model.OWLDataFactory;
import org.semanticweb.owlapi.model.OWLEntity;
import org.semanticweb.owlapi.model.OWLObjectPropertyExpression;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyManager;

/** 
 * 	List all the terms in an ontology including ID, label, definition, synonyms, IRI, and whether it is obsoleted
 * 		current used for getting terms from BCGO and creating loading files for BCGO relation database
 *
 *  @author Jie Zheng
 */

public class OntologyVisitor {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
            String inFile = args[0];
            String outFile = inFile + "_terms.txt";		
		
		OWLOntologyManager manager = OWLManager.createOWLOntologyManager();	 
		OWLOntology ont = OntologyManipulator.load(inFile, manager);

        ArrayList<TermObject> termList = getOWLTermInfos(manager, ont);
        Collections.sort(termList);

        try {
        	BufferedWriter out = new BufferedWriter(new FileWriter(outFile));
         	out.write("ID\tName\tDefinition\tSynonyms\tURI\tis obsolete\n");
        	
        	Iterator<TermObject> iterator = termList.iterator(); 
         	while (iterator.hasNext()){
         		out.write(iterator.next().toString()+ "\n");  
         	}
        	
         	out.write("subClassOf\tis a\t\t\trdfs:subClassOf\tfalse\n");
         	
        	out.close();
        	System.out.println("Terms in the ontology listed in the file: " + outFile);
        }
        catch (IOException e) {
        	System.out.println("Exception: " + e.toString());
        }
	}
	
	public static HashSet<String> getTermsIRIStrings (OWLOntologyManager manager, OWLOntology ont) {
		HashSet<String> iriStrs = new HashSet<String> ();
	
	    for (OWLEntity ent : ont.getSignature()) {
	    	IRI iri = ent.getIRI();
	    	iriStrs.add(iri.toString());
	    }
		
		return iriStrs;
	}
	
	public static ArrayList<TermObject> getOWLTermInfos (OWLOntologyManager manager, OWLOntology ont) {
		OWLDataFactory df = manager.getOWLDataFactory();
			
		String idPattern = "^(http://.+[/|#])([A-Za-z_]{2,10}_[0-9]{1,9})$";
		Pattern oboIdPattern = Pattern.compile(idPattern);
		
		ArrayList<TermObject> termObjects = new ArrayList<TermObject> ();
	
	    for (OWLEntity ent : ont.getSignature()) {	    	
	     	if (ent.isOWLClass() || ent.isOWLNamedIndividual() || ent.isOWLObjectProperty()) {	     		
	     		String termIRIstr = ent.getIRI().toString();

	     		// get term id
	     		String termId = termIRIstr;
	     		Matcher m = oboIdPattern.matcher(termIRIstr);
	    		if (m.find()) {
	    			termId = m.group(2);
	    		}
	     		
	    		// get term type: class or individual
	    		String type = "class";
	    		if (ent.isOWLNamedIndividual()) {
	    			type = "individual";
	    		} else if (ent.isOWLObjectProperty()) {
	    			type = "object property";
	    		}
	    		
	    		// get term label
	    		String label = OBOentity.getLabel(ent, ont, df);
	    		label = label.replaceAll("[\t\n\r]", "");
	    		
	    		// get term definition
	    		OWLAnnotationProperty defProp = df.getOWLAnnotationProperty(IRI.create(Config.DEF_AnnotProp));
	    		ArrayList<String> defList = OBOentity.getStringArrayAnnotProps(ent, df, ont, defProp);
	    		
	    		if (defList.size() == 0) {
		    		defProp = df.getOWLAnnotationProperty(IRI.create(Config.EFO_DEF_AnnotProp));
		    		defList = OBOentity.getStringArrayAnnotProps (ent, df, ont, defProp);    		
	    		}	    		
	    		String definition = arrayListToString(defList);

	    		// get synonyms
	    		// Get alternative terms specified by IAO
	    		OWLAnnotationProperty synonymProp = df.getOWLAnnotationProperty(IRI.create(Config.IAO_SYN_AnnotProp));
	    		ArrayList<String> synonymList = OBOentity.getStringArrayAnnotProps(ent, df, ont, synonymProp);
	    		
    			// Get synonyms specified by OBO format
	    		if (synonymList.size() == 0) {
	    			synonymProp = df.getOWLAnnotationProperty(IRI.create(Config.OBO_SYN_AnnotProp));
	    			ArrayList<String> synonymList0 = OBOentity.getStringArrayAnnotProps (ent, df, ont, synonymProp);
	    			synonymList.addAll(synonymList0);
	    			synonymProp = df.getOWLAnnotationProperty(IRI.create(Config.EXACT_SYN_AnnotProp));
	    			ArrayList<String> synonymList1 = OBOentity.getStringArrayAnnotProps (ent, df, ont, synonymProp);
	    			synonymList.addAll(synonymList1);
	    			synonymProp = df.getOWLAnnotationProperty(IRI.create(Config.BROAD_SYN_AnnotProp));
	    			ArrayList<String> synonymList2 = OBOentity.getStringArrayAnnotProps (ent, df, ont, synonymProp);
	    			synonymList.addAll(synonymList2);	    		
	    			synonymProp = df.getOWLAnnotationProperty(IRI.create(Config.NARROW_SYN_AnnotProp));
	    			ArrayList<String> synonymList3 = OBOentity.getStringArrayAnnotProps (ent, df, ont, synonymProp);
	    			synonymList.addAll(synonymList3);    			
	    			synonymProp = df.getOWLAnnotationProperty(IRI.create(Config.RELATE_SYN_AnnotProp));
	    			ArrayList<String> synonymList4 = OBOentity.getStringArrayAnnotProps (ent, df, ont, synonymProp);
	    			synonymList.addAll(synonymList4);
	    		}
	    		
    			// Get synonyms specified by EFO
	    		if (synonymList.size() == 0) {
	    			synonymProp = df.getOWLAnnotationProperty(IRI.create(Config.EFO_SYN_AnnotProp));
	    			ArrayList<String> synonymList1 = OBOentity.getStringArrayAnnotProps (ent, df, ont, synonymProp);
	    			synonymList.addAll(synonymList1);
	    		}
	    			    		
	    		String synonyms = arrayListToStringRemoveLabel(synonymList, label);
	    		
	    		// get term obsolete information
	    		// based on OWL:deprecated annotation
	    		boolean is_obsolete = OBOentity.isObsolete (ent, ont, df);
	    		
	    		// based on whether they are subClass of obsoleteClass defined in old OBO format
	    		if (!is_obsolete && ent.isOWLClass()) {		    		
		    		for (OWLClassExpression supTerm : ent.asOWLClass().getSuperClasses(ont)) {
		    			if (!supTerm.isAnonymous()) {
		    				if(supTerm.asOWLClass().getIRI().toString().equals(Config.OBSOLETE_CLASS)) {
		    					is_obsolete = true;
		    				}
		    			}
		    		}
	    		}    		

	    		// based on whether they are subProperty of obsoleteProperty defined in old OBO format
	    		if (!is_obsolete && ent.isOWLObjectProperty()) {		
	    			for (OWLObjectPropertyExpression supProp : ent.asOWLObjectProperty().getSuperProperties(ont)) {
		    			if (!supProp.isAnonymous()) {
		    				if(supProp.asOWLObjectProperty().getIRI().toString().equals(Config.OBSOLETE_PROP)) {
		    					is_obsolete = true;
		    				}	
		    			}
	    			}
	    		}
	    		
	    		// for old ontology which do not use OWL:deprecated
	    		if (label.toLowerCase().contains("obsolete")) {
	    			is_obsolete = true;
	    		}
	    		
	    		TermObject term = new TermObject(termId, label, definition, termIRIstr, synonyms, is_obsolete, type);
	    		termObjects.add(term);
	     	}
	    }
		
		return termObjects;
	}
	
	public static String arrayListToString(ArrayList<String> list) {
		String listStr = "";
		
		if (list.size() > 0) {
			StringBuilder sb = new StringBuilder();
			int count = 0;
			for (String s : list) {
				s = s.replaceAll("[\t\n\r]", " ");
				sb.append(s);
				count ++;
				if (count < list.size()) {
					sb.append(",");
				}
			}
			listStr = sb.toString();
		}

		return listStr;
	}
	
	public static String arrayListToStringRemoveLabel (ArrayList<String> list, String label) {
		String listStr = "";
		
		if (list.size() > 0) {
			StringBuilder sb = new StringBuilder();
			int count = 0;
			for (String s : list) {
				s = s.replaceAll("[\t\n\r]", " ");
				if (!s.equals(label)) {
					sb.append(s);
				}
				count ++;
				if (!s.equals(label) && count < list.size()) {
					sb.append(",");
				}
			}
			listStr = sb.toString();
		}

		return listStr;
	}
}

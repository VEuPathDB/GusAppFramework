package org.gusdb.gus.supported;


import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.model.ClassExpressionType;
import org.semanticweb.owlapi.model.IRI;
import org.semanticweb.owlapi.model.OWLClass;
import org.semanticweb.owlapi.model.OWLClassExpression;
import org.semanticweb.owlapi.model.OWLIndividual;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyManager;

/**
 * 	Get is-a relation and IDs of its subject and object including both classes and individuals
 * 		used by BCGO database, the is-a axioms will be loaded into relation database
 *
 *  @author Jie Zheng
 */
public class IsA_Axioms {
	public static void main(String[] args) {

		//BIOBANK
		String path = "/home/jbrestel/data/obo/";

            String inFile = args[0];
            String outFile = inFile + "_isA.txt";		

		OWLOntologyManager manager = OWLManager.createOWLOntologyManager();
		OWLOntology ont = OntologyManipulator.load(inFile, manager);

        ArrayList<String> triples = new ArrayList<String>();

		// go through all OWL classes defined in the ontology
		for (OWLClass cs: ont.getClassesInSignature()) {
			// get all super classes of this class
			Set<OWLClassExpression> superClsExps = cs.getSuperClasses(ont);
			for (OWLClassExpression oe : superClsExps) {
				if (oe.getClassExpressionType() == ClassExpressionType.OWL_CLASS) {
					triples.add(getID(cs.getIRI().toString()) + "::::" + getID(oe.asOWLClass().getIRI().toString()));
				}
			}

			// get all named individuals of this class
			Set<OWLIndividual> individuals = cs.getIndividuals(ont);
			for (OWLIndividual ind : individuals) {
				if (ind.isNamed()) {
				 	IRI sIRI = ind.asOWLNamedIndividual().getIRI();
				 	triples.add(getID(sIRI.toString()) + "::::" + getID(cs.getIRI().toString()));
				 	// System.out.println(sIRI.toString() + " is_a " + oIRI.toString());
				}
			}

		}

		// write the results
        try {
        	BufferedWriter out = new BufferedWriter(new FileWriter(outFile));
        	out.write("Subject\tRelation\tObject\n");

        	Collections.sort(triples);
        	Iterator<String> iterator = triples.iterator();
         	while (iterator.hasNext()){
         		String s = iterator.next();
         		String[] splits = s.split("::::");
         		if (splits.length >1) {
         			out.write(splits[0] + "\t" + "subClassOf\t" + splits[1] + "\n");
         		} else {
         			System.out.println(s);
         		}
         	}

        	out.close();
        }
        catch (IOException e) {
        	System.out.println("Exception: " + e.toString());
        }
	}

	public static String getID (String iriStr) {
		String id = iriStr;
		String idPattern = "^(http://.+[/|#])([A-Za-z_]{2,10}_[0-9]{1,9})$";
		Pattern oboIdPattern = Pattern.compile(idPattern);

		Matcher m = oboIdPattern.matcher(iriStr);
		if (m.find()) {
			id = m.group(2);
		} else if (iriStr.startsWith("http://purl.bioontology.org/ontology/")) {
		    id = iriStr.replace("http://purl.bioontology.org/ontology/", "");
		    id = id.replace("/", "_");
		} else if (iriStr.startsWith("http://purl.obolibrary.org/obo/")) {
		    id = iriStr.replace("http://purl.obolibrary.org/obo/", "");	
		} else if (iriStr.lastIndexOf('#') > 0) {
		    int sIndex = iriStr.lastIndexOf('#');
		    if (sIndex < iriStr.length())  id = iriStr.substring(iriStr.lastIndexOf('#')+1);
		}

		return id;
	}
}

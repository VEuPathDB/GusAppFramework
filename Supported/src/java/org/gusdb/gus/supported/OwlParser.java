package org.gusdb.gus.supported;

import com.hp.hpl.jena.rdf.model.ModelFactory;
import com.hp.hpl.jena.rdf.model.Model;
import com.hp.hpl.jena.rdf.model.Statement;
import com.hp.hpl.jena.rdf.model.StmtIterator;
import com.hp.hpl.jena.util.FileManager;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.FileWriter;
import java.io.Writer;

/**
 *  Convert an owl/rdf file into a tab file which can be easily loaded into 
 *  GUS.  Specifically SRes::OntologyTerm and SRes::OntologyRelationship.
 *  The <code>Jena</code> package is used to list all statements in the ontology.
 *  
 * 
 * @author John Brestelli
 *
 */
public class OwlParser {
	
    private static String defaultFileName = "/home/jbrestel/data/RAD_data/MGED_Ontology/MGEDOntology.1.3.1.owl";
    private static String defaultParser = "MgedRdfRow";
	
    private final static boolean debug = false;
	
    private String owlFile;
    private String parserType;
	
    private Writer writer;
	
    public OwlParser (String owlFile, String parserType) {
        if(debug) {
            System.out.println("Creating parser for owl file:  " + owlFile);
            System.out.println("Using Parser:  " + defaultParser);
        }
        this.owlFile = owlFile;
        this.parserType = parserType;
		
        String termsString = owlFile + ".out";
		
        this.writer = openWriter(termsString);
    }
	
    /**
     *  Gets the args which specify the inFile and the parser...Create the OwlParser object and call 
     *  method which does the parsing.  Create the <code>Model</code> Representation of 
     *  the owl file.
     * 
     * @param args 
     *        User can provide the owl file as a command line argument.
     */
    public static void main(String[] args) {
		
        String mgedOwlFile;
        String parserType;
		
        if(debug) {
            mgedOwlFile = defaultFileName;
            parserType = defaultParser;
        }
        else if(args.length == 2) {
            mgedOwlFile = args[0];
            parserType = args[1];
        }
        else {
            throw new IllegalArgumentException("Must provide the rdf file and the parserType");
        }
		
        OwlParser owl = new OwlParser(mgedOwlFile, parserType);

        Model model = owl.getModelFromFile(mgedOwlFile);
        owl.writeTermsAndRelationships(model);

        try {
            owl.writer.close();
        } catch (IOException e) {
            e.printStackTrace();
            System.exit(0);
        }
    }
	
    public GusRdfRow gusRdfFromParserType(Statement s) {
        if(parserType.equals("MgedRdfRow")) {
            return new MgedRdfRow(s);
        }
        // We currently don't have any other parsers
        else {
            throw new IllegalArgumentException("Parser for [" + parserType + "] is not implemented");
        }
    }
	
    /**
     * Read all the statments from the owl file.  Convert them into <code>GusRdfRow</code>
     * objects.
     * 
     * @param owlModel
     *     The Model representation of the owl file.
     */
    private void writeTermsAndRelationships (Model owlModel) {
        StmtIterator si = owlModel.listStatements();
		
        while(si.hasNext()) {

            Statement s = si.nextStatement();

            GusRdfRow gusRdf = gusRdfFromParserType(s);

            gusRdf.parse();

            if (gusRdf.isValid()) {
                writeTermOrRelationship(gusRdf);
            }
            if(!gusRdf.isValid() && debug) {
                System.out.println("Skipping:  " + gusRdf.toString());
            }
        }
    }

    /**
     * Determine which writer to write to.
     * 
     * @param rdf
     *      The row of data to be written.
     */
    private void writeTermOrRelationship (GusRdfRow rdf) {
        String output = rdf.getOutputString();

        try {
            writer.write(output + "\n");
        } catch (IOException e) {
            e.printStackTrace();
            System.exit(0);
        }
    }
	

    /**
     * Read in the model from the File name.  
     * 
     * @throws IllegalArgumentException
     *     If no file is provided
     * @param filename
     *     Full path to the file
     * @return
     *     The model representation of the owl file
     */
    private Model getModelFromFile (String filename) {
        Model model = ModelFactory.createDefaultModel();
        InputStream in = FileManager.get().open(filename);

        if (in == null) {
            throw new IllegalArgumentException("File: [" + filename + "] not found");
        }
        model.read(in, filename);

        return(model);
    }
	
    /**
     * Create a new FileWriter.
     * 
     * @throws IllegalArgumentException
     *     if the filename is null.
     * @param file
     *     Full path to the new File
     * @return
     *     The FileWriter
     */
    public static FileWriter openWriter (String file) {
        if(debug) {
            System.out.println("Creating FileWriter for File:  " + file);
        }
        if (file == null) {
            throw new IllegalArgumentException("File: [" + file + "] not found");
        }
		
        try {
            FileWriter writer = new FileWriter(file);
            return writer;
        } catch (IOException e) {
            System.out.println("Unable to open file for writing:  " + file);
            System.exit(0);
        }
        return(null);
    }
}

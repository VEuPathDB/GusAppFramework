/*
 * Created on 2/25/05
 *
 */
package org.gusdb.dbadmin.util;

import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.reader.SchemaReader;
import org.gusdb.dbadmin.reader.XMLReader;
import org.gusdb.dbadmin.reader.OracleReader;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.OptionGroup;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public class SchemaComparator {

    protected static Log log = LogFactory.getLog(SchemaComparator.class);

    public static void main(String[] args) {
	SchemaReader schemaA;
	SchemaReader schemaB;
	
	System.out.println("Has args: ");
	for ( int i = 0; i < args.length; i++ ) {
	    System.out.println(args[i]);
	}
	
	String cmdName = System.getProperties().getProperty("cmdName");
	
	Options options = declareOptions();
	CommandLine cmdLine = parseOptions(cmdName, options, args);

	if ( cmdLine.hasOption("xmlA") ) {
	    System.out.println("creating xml reader with " + cmdLine.getOptionValue("xmlA") );
	    schemaA = new XMLReader( cmdLine.getOptionValue("xmlA") );
	}
	else {
	    String[] params = cmdLine.getOptionValues("dbA");
	    schemaA = new OracleReader( params[0], params[1], params[2] );
	}

	if ( cmdLine.hasOption("xmlB") ) {
	    schemaB = new XMLReader( cmdLine.getOptionValue("xmlB") );
	}
	else {
	    String[] params = cmdLine.getOptionValues("dbB");
	    schemaB = new OracleReader( params[0], params[1], params[2] );
	}
	
	Database dbA = schemaA.read();
	Database dbB = schemaB.read();

	if ( dbA.equals(dbB) ) {
	    System.out.println("Databases are equal");
	} else {
	    System.out.println("Databases are not equal");
	}
	
    }
    
    private static OptionGroup getSchemaSelection(String prefix) {
	OptionGroup schemaSelection = new OptionGroup();
	schemaSelection.setRequired(true);

	Option xml = new Option("xml" + prefix, 
		     "Use an XML file as the representation of the schema.");
	schemaSelection.addOption(xml);
	
	Option db = new Option("db" + prefix,
		     "Use a database instance for the schema.");
	db.setArgs(3);
	schemaSelection.addOption(db);
	return schemaSelection;
    }

    static Options declareOptions() {
	Options options  = new Options();


	options.addOptionGroup(getSchemaSelection("A"));
	options.addOptionGroup(getSchemaSelection("B"));
       
	Option verbose = new Option("verbose", "Increase verbosity");
	options.addOption(verbose);
	
	return options;
    }

    static CommandLine parseOptions(String cmdName, Options options, 
				    String[] args) {
	CommandLineParser parser = new BasicParser();
	CommandLine cmdLine = null;
	try {
	    cmdLine = parser.parse( options, args );
	} catch ( ParseException e ) {
	    log.error("Parsing failed.", e);
	    System.err.println("");
	    System.err.println("Parsing failed.  Reason: " + e.getMessage() );
	    System.err.println("");
	    usage(cmdName, options);
	}
	
	return cmdLine;
    }

    static void usage(String cmdName, Options options) {
	String newline = System.getProperty( "line.separator" );

	String cmdlineSyntax = cmdName +
	    " [-xmlA file | -dbA dsn username password ] " +
	    " [-xmlB file | -dbB dsn username password ] " +
	    " -verbose";

	String header = newline +
	    "Compares two database schemas, whose source may either " +
	    "be an XML representation, or an actual database instance. " + 
	    "Without -verbose, simply returns whether the two schemas " + 
	    "differ." + newline + newline + "Options: " ;

	String footer = "";

	HelpFormatter formatter = new HelpFormatter();
	formatter.printHelp(75, cmdlineSyntax, header, options, footer);
	System.exit(1);
    }

	
}

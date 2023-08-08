/**
 * Created on 2/25/05 $Id: SchemaComparator.java 3094 2005-07-13 21:31:57Z
 * msaffitz $
 */
package org.gusdb.dbadmin.cmd;

import java.io.FileWriter;
import java.io.IOException;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.reader.XMLReader;
import org.gusdb.dbadmin.util.CategoryReader;
import org.gusdb.dbadmin.writer.XMLWriter;

/**
 * @version $Revision: 3094 $
 * @author msaffitz
 */
public class CategoryPopulator {

    public static void main( String[] args ) throws IOException {

        String cmdName = System.getProperties( ).getProperty( "cmdName" );

        Options options = declareOptions( );
        CommandLine cmdLine = parseOptions( cmdName, options, args );

        XMLReader reader = new XMLReader( cmdLine.getOptionValue( "database" ) );
        Database db = reader.read( );

        db.setSuperCategories( CategoryReader.readCategories( cmdLine.getOptionValue( "orgFile" ) ) );

        CategoryReader.setCategories( db, cmdLine.getOptionValue( "mapFile" ) );

        FileWriter fw = new FileWriter( cmdLine.getOptionValue( "database" ) );
        XMLWriter writer = new XMLWriter( );
        writer.write( fw, db );
    }

    /**
     * Specifies the Options that this utility supports
     * 
     * @return Options supported by this utility
     */
    static Options declareOptions( ) {

        Options options = new Options( );

        Option database = new Option( "database", true, "Path Database XML File" );
        database.setRequired( true );
        options.addOption( database );

        Option orgFile = new Option( "orgFile", true, "Path to Category Organization File" );
        orgFile.setRequired( true );
        options.addOption( orgFile );

        Option mapFile = new Option( "mapFile", true, "Path Category Map File" );
        mapFile.setRequired( true );
        options.addOption( mapFile );

        return options;
    }

    /**
     * Parses the options provided. Either returns the CommandLine for use later
     * or calls usage on an invalid command line and exits.
     * 
     * @param cmdName Name of the executing command
     * @param options Options that the command line supports
     * @param args Arguments passed on the command line
     * @return CommandLine
     * @throws ParseException Caught interally and exists with usage statement
     */
    static CommandLine parseOptions( String cmdName, Options options, String[] args ) {

        CommandLineParser parser = new DefaultParser( );
        CommandLine cmdLine = null;

        try {
            cmdLine = parser.parse( options, args );
        }
        catch ( ParseException e ) {
            System.err.println( "" );
            System.err.println( "Parsing failed.  Reason: " + e.getMessage( ) );
            System.err.println( "" );
            usage( cmdName, options );
        }

        return cmdLine;
    }

    /**
     * Provides a usage statement to STDOUT for the utility
     * 
     * @param cmdName The name of the command executing
     * @param options Command line Options provided to the HelpFormatter
     */

    static void usage( String cmdName, Options options ) {

        String newline = System.getProperty( "line.separator" );
        String cmdlineSyntax = cmdName + " -database file -orgFile file -mapFile file ";
        String header = newline + "Populates a database's categories" + newline + newline + "Options: ";
        String footer = "";
        HelpFormatter formatter = new HelpFormatter( );
        formatter.printHelp( 75, cmdlineSyntax, header, options, footer );
        System.exit( 1 );
    }
}

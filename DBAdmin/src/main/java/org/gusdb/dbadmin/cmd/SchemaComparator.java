/*
 * Created on 2/25/05 $Id$
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
import org.gusdb.dbadmin.util.EqualityReport;

/**
 * A utility for comparing GUS schemas.
 * 
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 * @author msaffitz
 */
public class SchemaComparator {

    /**
     * DOCUMENT ME!
     * 
     * @param args DOCUMENT ME!
     * @throws IOException
     */
    public static void main(String[] args) throws IOException {

        Database leftSchema;
        Database rightSchema;

        String cmdName = System.getProperties().getProperty("cmdName");

        Options options = declareOptions();
        CommandLine cmdLine = parseOptions(cmdName, options, args);

        XMLReader reader = new XMLReader(cmdLine.getOptionValue("leftSource"));
        leftSchema = reader.read();

        reader = new XMLReader(cmdLine.getOptionValue("rightSource"));
        rightSchema = reader.read();

        FileWriter fw = new FileWriter(cmdLine.getOptionValue("report"));
        
        EqualityReport eq = new EqualityReport(leftSchema, rightSchema);
        
        eq.writeReport(fw);
    }

    /**
     * Specifies the Options that this utility supports
     * 
     * @return Options supported by this utility
     */
    static Options declareOptions() {

        Options options = new Options();

        Option leftSource = new Option("leftSource", true,
                "Path to first schema for comparison");
        leftSource.setRequired(true);
        options.addOption(leftSource);

        Option rightSource = new Option("rightSource", true,
                "Path to second schema for comparison");
        rightSource.setRequired(true);
        options.addOption(rightSource);

        Option report = new Option("report", true,
                "Path when report should be created");
        report.setRequired(true);
        options.addOption(report);

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
    static CommandLine parseOptions(String cmdName, Options options,
            String[] args) {

        CommandLineParser parser = new DefaultParser();
        CommandLine cmdLine = null;

        try {
            cmdLine = parser.parse(options, args);
        } catch (ParseException e) {
            System.err.println("");
            System.err.println("Parsing failed.  Reason: " + e.getMessage());
            System.err.println("");
            usage(cmdName, options);
        }

        return cmdLine;
    }

    /**
     * Provides a usage statement to STDOUT for the utility
     * 
     * @param cmdName The name of the command executing
     * @param options Command line Options provided to the HelpFormatter
     */

    static void usage(String cmdName, Options options) {

        String newline = System.getProperty("line.separator");
        String cmdlineSyntax = cmdName + " -leftSource file "
                + " -rightSource file -report file ";
        String header = newline
                + "Compares two database schemas that are represented in the "
                + "GUS XML schema format and creates a report of differences."
                + newline + newline + "Options: ";
        String footer = "";
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp(75, cmdlineSyntax, header, options, footer);
        System.exit(1);
    }
}

package org.gusdb.workflow;

import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;

public class Utilities {
    
    final static String nl = System.getProperty("line.separator");

    static void addOption(Options options, String argName, String desc) {

        Option option = new Option(argName, true, desc);
        option.setRequired(true);
        option.setArgName(argName);

        options.addOption(option);
    }

    static CommandLine parseOptions(String cmdlineSyntax, String cmdDescrip, String usageNotes, Options options,
            String[] args) {

        CommandLineParser parser = new BasicParser();
        CommandLine cmdLine = null;
        try {
            // parse the command line arguments
            cmdLine = parser.parse(options, args);
        } catch (ParseException exp) {
            // oops, something went wrong
            System.err.println("");
            System.err.println("Parsing failed.  Reason: " + exp.getMessage());
            System.err.println("");
            usage(cmdlineSyntax, cmdDescrip, usageNotes, options);
        }

        return cmdLine;
    }
    
    static void usage(String cmdlineSyntax, String cmdDescrip, String usageNotes, Options options) {
        
        String header = nl + cmdDescrip + nl + nl + "Options:";

        // PrintWriter stderr = new PrintWriter(System.err);
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp(75, cmdlineSyntax, header, options, usageNotes);
        System.exit(1);
    }
    
    static void error(String msg) {
        System.err.println(msg);
        System.exit(1);
    }
    
   
}
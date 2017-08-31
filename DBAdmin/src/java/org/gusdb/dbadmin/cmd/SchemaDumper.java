package org.gusdb.dbadmin.cmd;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Properties;

import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.dbadmin.model.Table;
import org.gusdb.dbadmin.reader.OracleReader;
import org.gusdb.dbadmin.reader.SchemaReader;
import org.gusdb.dbadmin.reader.XMLReader;
import org.gusdb.dbadmin.util.CategoryReader;
import org.gusdb.dbadmin.util.DatabaseUtilities;
import org.gusdb.dbadmin.util.GusClassHierarchyConverter;
import org.gusdb.dbadmin.writer.Hibernate3MapWriter;
import org.gusdb.dbadmin.writer.HibernateMapWriter;
import org.gusdb.dbadmin.writer.OracleWriter;
import org.gusdb.dbadmin.writer.PostgresWriter;
import org.gusdb.dbadmin.writer.SchemaWriter;
import org.gusdb.dbadmin.writer.SimpleTextWriter;
import org.gusdb.dbadmin.writer.XMLWriter;

/**
 * A utility to dump a schema, either instatiated in a database or in an XML
 * file, to a text file, either a database format, XML, or simple text.
 * 
 * @version $Revision$ $Date$
 * @author msaffitz
 */
public class SchemaDumper {

    private static Properties properties = new Properties();

    /**
     * Dumps the schema for a specified database.  The source may either be an
     * instatiated databases (specified in gus.config) or an XML file.  The
     * target may either be XML, Text, or DDL for Oracle or PostgreSQL.
     * 
     * @param args Command line arguments
     */
    public static void main(String[] args) {

		readProperties();
		
        String cmdName = System.getProperties().getProperty("cmdName");

        Options options = declareOptions();
        CommandLine cmdLine = parseOptions(cmdName, options, args);

        SchemaReader dbReader = null;
        SchemaWriter dbWriter = null;

        // READ
        if (cmdLine.getOptionValue("sourceType").compareToIgnoreCase("db") == 0) {

			if ( properties.getProperty("dbVendor") == null ) {
				System.err.println("Error.  dbVendor not specified in gus.config");
				System.exit(1);
			}
			
            if (properties.getProperty("dbVendor").equals("Oracle")) {
                dbReader = new OracleReader(properties.getProperty("jdbcDsn"), 
                                            properties.getProperty("databaseLogin"), 
                                            properties.getProperty("databasePassword"));
            } else if (properties.getProperty("dbVendor").equals("Postgres")) {
                // TODO: PostgresReader
                System.err.println("Sorry, A PostgreSQL Reader does not yet exist.");
                System.exit(1);
            } else {
                System.err.println("Unknown DB Vendor");
                System.exit(1);
            }
        } else if (cmdLine.getOptionValue("sourceType").compareToIgnoreCase("xml") == 0) {
            dbReader = new XMLReader(cmdLine.getOptionValue("source"));
        } else {
            System.err.println("Unknown sourceType: " + cmdLine.getOptionValue("sourceType"));
            System.exit(1);
        }

        Database db = dbReader.read();

        // WRITE
        try {

            if (cmdLine.getOptionValue("targetType").compareToIgnoreCase("oracle") == 0) {
                dbWriter = new OracleWriter();
                convertSubclasses(db);
            } else if (cmdLine.getOptionValue("targetType").compareToIgnoreCase("postgres") == 0) {
                dbWriter = new PostgresWriter();
                convertSubclasses(db);
            } else if (cmdLine.getOptionValue("targetType").compareToIgnoreCase("simple") == 0) {
                dbWriter = new SimpleTextWriter();
            } else if (cmdLine.getOptionValue("targetType").compareToIgnoreCase("xml") == 0) {
                dbWriter = new XMLWriter();
            } else if (cmdLine.getOptionValue("targetType").compareToIgnoreCase("hbm") == 0) {
                dbWriter = new HibernateMapWriter(properties.getProperty("hibernate.basePkg"));
            } else if (cmdLine.getOptionValue("targetType").compareToIgnoreCase("hbm3") == 0) {
                dbWriter = new Hibernate3MapWriter(properties.getProperty("hibernate.basePkg"));
            } else {
                System.err.println("Unknown targetType: " + cmdLine.getOptionValue("target"));
                System.exit(1);
            }
            
            if ( cmdLine.getOptionValue("categoryFile") != null && 
                 cmdLine.getOptionValue("categoryMapFile") != null ) {
                db.setSuperCategories( CategoryReader.readCategories( cmdLine.getOptionValue( "categoryFile" ) ) );
                CategoryReader.setCategories(db, cmdLine.getOptionValue("categoryMapFile"));
            }
            if ( cmdLine.getOptionValue("tablespace") != null ) {
                DatabaseUtilities.setTablespace(db, cmdLine.getOptionValue("tablespace"));
            }

            FileWriter fw = new FileWriter(cmdLine.getOptionValue("target"));
            dbWriter.write(fw, db);
        } catch (IOException e) {
            System.out.println("An Error Occured: " + e);
            System.exit(1);
        }
    }

    /**
     * Specifies the Options that this utility supports
     * 
     * @return Options supported by this utility
     */
    private static Options declareOptions() {

        Options options = new Options();
        Option sourceType = new Option("sourceType", true, "Type of source");
        sourceType.setRequired(true);
        options.addOption(sourceType);

        Option inFile = new Option("source", true, "Full path to source XML File");
        inFile.setRequired(false);
        options.addOption(inFile);

        Option targetType = new Option("targetType", true, "Type of target");
        targetType.setRequired(true);
        options.addOption(targetType);

        Option outFile = new Option("target", true, "Full path of output File");
        outFile.setRequired(true);
        options.addOption(outFile);
        
        Option catMapFile = new Option("categoryMapFile", true, "Full path to category mapping file");
        catMapFile.setRequired(false);
        options.addOption(catMapFile);
        
        Option catFile = new Option("categoryFile", true, "Full path to category XML file");
        catFile.setRequired(false);
        options.addOption(catFile);
        
        Option tblSpace = new Option("tablespace", true, "Name of the tablespace to use for all objects");
        tblSpace.setRequired(false);
        options.addOption(tblSpace);

        return options;
    }

    /**
     * Parses the options provided.  Either returns the CommandLine for use
     * later or calls usage on an invalid command line and exits.
     * 
     * @param cmdName Name of the executing command
     * @param options Options that the command line supports
     * @param args Arguments passed on the command line
     * @return CommandLine
     * @throws ParseException Caught interally and exists with usage statement
     */
    private static CommandLine parseOptions(String cmdName, Options options, 
                                            String[] args) {

        CommandLineParser parser = new BasicParser();
        CommandLine cmdLine = null;

        try {
            cmdLine = parser.parse(options, args);

            if (cmdLine.getOptionValue("sourceType").compareToIgnoreCase("db") != 0 && 
                cmdLine.getOptionValue("sourceType").compareToIgnoreCase("xml") != 0) {
                throw new ParseException("Invalid sourceType: " + 
                                         cmdLine.getOptionValue("sourceType"));
            }

            if (cmdLine.getOptionValue("targetType").compareToIgnoreCase("oracle") != 0 && 
                cmdLine.getOptionValue("targetType").compareToIgnoreCase("postgres") != 0 && 
                cmdLine.getOptionValue("targetType").compareToIgnoreCase("simple") != 0 && 
                cmdLine.getOptionValue("targetType").compareToIgnoreCase("xml") != 0 && 
                cmdLine.getOptionValue("targetType").compareToIgnoreCase("xml") != 0 &&
                cmdLine.getOptionValue("targetType").compareToIgnoreCase("hbm") != 0 &&
                cmdLine.getOptionValue("targetType").compareToIgnoreCase("hbm3") != 0) {
                throw new ParseException("Invalid targetType: " + 
                                         cmdLine.getOptionValue("targetType"));
            }

            if (cmdLine.getOptionValue("sourceType").compareToIgnoreCase("xml") == 0 && 
                cmdLine.getOptionValue("source") == null) {
                throw new ParseException("Missing source for XML sourceType");
            }
            
            if ( (cmdLine.getOptionValue("categoryMapFile") != null &&
                  cmdLine.getOptionValue("categoryFile") == null ) ||
                 (cmdLine.getOptionValue("categoryMapFile") == null &&
                  cmdLine.getOptionValue("categoryFile") != null ) ) {
                throw new ParseException("categoryMapFile and categoryFile not properly specified");
            }
                
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
    private static void usage(String cmdName, Options options) {

        String newline = System.getProperty("line.separator");
        String cmdlineSyntax = cmdName + 
                               " -sourceType [db|xml] [-source file]" + 
                               " -targetType [oracle|postgres|simple|xml] -target file" +
                               " [-categoryFile file -categoryMapFile file] [-tablespace name]";
        String header = newline + 
                        "Reads a database (either directly or in XML) and " + 
                        "outputs the schema as XML, DDL, or a simple text " + 
                        "format " + newline + newline + "Options: ";
        String footer = "";
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp(75, cmdlineSyntax, header, options, footer);
        System.exit(1);
    }

    /**
     * Converts subclasses from tables to GUS-style views.
     * 
     * @param db The database on which to perform the conversion
     */
    private static void convertSubclasses(Database db) {
        Collection<Table> superClasses = new HashSet<>();

        for (Iterator<Schema> i = db.getAllSchemas().iterator(); i.hasNext();) {
            Schema schema = i.next();

            for (Iterator<? extends Table> j = schema.getTables().iterator(); j.hasNext();) {
                Table table = j.next();

                if (!table.getSubclasses().isEmpty() && 
                    table.getClass() == GusTable.class) {
                    superClasses.add(table);
                }
            }
        }

        for (Iterator<Table> i = superClasses.iterator(); i.hasNext();) {
            GusClassHierarchyConverter converter = new GusClassHierarchyConverter((GusTable)i.next());
            converter.convert();
        }
    }

    private static void readProperties() {
      File propertyFile;

      try {
        propertyFile = new File(System.getProperty("PROPERTYFILE"));
        properties.load(new FileInputStream(propertyFile));
      } catch (IOException e) {
        throw new RuntimeException(e);
      }
    }

}

package edu.upenn.cbil.magetab;

import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.*;
import static edu.upenn.cbil.magetab.utilities.ApplicationException.*;

import java.io.File;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.PosixParser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.io.Files;

import edu.upenn.cbil.magetab.model.ImageExtension;
import edu.upenn.cbil.magetab.preprocessors.ExcelPreprocessor;
import edu.upenn.cbil.magetab.preprocessors.FactorValuePreprocessor;
import edu.upenn.cbil.magetab.utilities.ApplicationConfiguration;
import edu.upenn.cbil.magetab.utilities.ApplicationException;

/**
 * Entry class for MAGE-TAB converter.  Converts a Excel workbook file containing a MAGE-TAB into
 * an xml file parseable by CBIL GUS 4.0 loaders.  The MAGE-TAB has some slight variations from the
 * MAGE-TAB 1.1. spec (most notably in the area of factor values).
 * @author crisl
 *
 */
public class Converter {
  public static Logger logger = LoggerFactory.getLogger(Converter.class);
  public static File inputFile;
  public static String directoryName;

  /**
   * Invokes the MAGE-TAB conversion.
   * @param args - CLI containing the Excel workbook as an xlsx extension only and several optional
   * options for displaying html, graphml, and performing xsd validation. The -help option provides
   * usage information.
   */
  public static void main(String[] args) {
	logger.info("START - " + Converter.class.getSimpleName());
	Converter converter = new Converter();
	try {
	  new ApplicationConfiguration().applicationSetup();
	  converter.parseCommandLine(args);
	  inputFile = new File(args[0]);
	  converter.convert();
	}
	catch(ApplicationException ae) {
	  logger.error(ae.getMessage(), ae);
	  System.exit(1);
	}
	System.out.println("Processing should be complete.  Look in the new " + directoryName + " directory for output files.");
	logger.info("END - " + Converter.class.getSimpleName());
  }
  
  /**
   * Parses the user's command line input.  Normally the command consists of an executing jar.
   * @param args - Excel workbook and options
   */
  public void parseCommandLine(String[] args) {
    Options options = new Options(); 
    options.addOption(GRAPHML, false, GRAPHML_DESC);
    options.addOption(HTML, false, HTML_DESC);
    options.addOption(VALIDATE, false, VALIDATE_DESC);
    options.addOption(PREFIX, true, PREFIX_DESC);
    options.addOption(IMG_TYPE, true, IMG_TYPE_DESC);
    options.addOption(DOT, true, DOT_DESC);
    options.addOption(HELP, false, HELP_DESC);
    String header = USAGE_HEADER;
    String footer = USAGE_FOOTER;
    CommandLineParser parser = new PosixParser();
    try {
      CommandLine cmd = parser.parse(options, args);
      if(cmd.hasOption(VALIDATE)) {
         switches.put(VALIDATE, true);
      }
      if(cmd.hasOption(GRAPHML)) {
        switches.put(GRAPHML, true);
      }
      if(cmd.hasOption(HTML)) {
        switches.put(HTML, true);
      }
      if(cmd.hasOption(PREFIX)) {
        filePrefix = cmd.getOptionValue(PREFIX);
      }
      if(cmd.hasOption(IMG_TYPE)) {
    	if(ImageExtension.has(cmd.getOptionValue(IMG_TYPE))) {
          imageType = cmd.getOptionValue(IMG_TYPE);
        }
      }
      if(cmd.hasOption(DOT)) {
        graphvizDotPath = cmd.getOptionValue(DOT);
      }
      if(cmd.hasOption(HELP)) {
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp(CMD_INVOCATION, header, options, footer, true);
        System.exit(0);
      }
      if(cmd.getArgs().length < 1) {
        throw new ApplicationException(MISSING_ARG_ERROR);
      }
      if(!EXCEL_EXT.equals(Files.getFileExtension(cmd.getArgs()[0]))) {
        throw new ApplicationException(BAD_EXCEL_ERROR + cmd.getArgs()[0]);
      }
      directoryName = Files.getNameWithoutExtension(cmd.getArgs()[0]);
      if(directoryName.contains(".")) {
    	throw new ApplicationException(DIRECTORY_NAME_ERROR + cmd.getArgs()[0]);
      }
      System.out.println("Results to be delivered to " + directoryName);
    }
    catch(org.apache.commons.cli.ParseException pe) {
      throw new ApplicationException(CMD_PARSE_ERROR, pe);
    }
  }
  
  /**
   * 
   */
  public void convert() {
    createEmptyOutputDirectory();
    ExcelPreprocessor excelPreprocessor = new ExcelPreprocessor(inputFile, directoryName);
    excelPreprocessor.process(IDF);
    String sdrfFileName = excelPreprocessor.process(SDRF);
    FactorValuePreprocessor factorValuePreprocessor = new FactorValuePreprocessor();
    factorValuePreprocessor.process(sdrfFileName);
    new Processor(directoryName).process();
  }
  
  /**
   * The program creates a number of files (idf, sdrf text files, xml output file, graphml, dot, gif,
   * and html files.  To maintain order, all these files are created in a subdirectory named after the
   * name of the Excel workbook file.  If the directory already exists, it is purged of pre-existing
   * files.
   */
  protected void createEmptyOutputDirectory() {
    File directory = new File(directoryName);
    if (!directory.exists()) {
      if (!directory.mkdir()) {
        throw new ApplicationException(DIRECTORY_CREATION_ERROR + directoryName);
      }
    }
    else {
      for (File file : directory.listFiles()) {
        if(!file.delete()) {
          System.err.println("WARNING: A prior file: " + file.getName() + " was not deleted.  Is it open?");
        }
      }
    }
  }
  
}

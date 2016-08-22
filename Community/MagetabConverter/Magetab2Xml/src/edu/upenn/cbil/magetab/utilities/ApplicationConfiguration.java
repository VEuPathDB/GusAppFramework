package edu.upenn.cbil.magetab.utilities;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class ApplicationConfiguration {
  public static Logger logger = LoggerFactory.getLogger(ApplicationConfiguration.class);
  public static String filePrefix;
  public static String filterPrefix;
  public static String graphvizDotPath;
  public static String imageType;
  public static Map<String,Boolean> switches = new HashMap<>();
  public static final String CMD_INVOCATION = "java -jar Magetab2Xml.jar";
  public static final String USAGE_HEADER = "Convert an Excel workbook containing a MAGE-TAB document into an XML document\n" +
                                            "to be used in loading a GUS 4.0 database\n\n";
  public static final String USAGE_FOOTER = "\nPlease report issues at https://redmine.genomics.upenn.edu/projects/gus-4-mage-tab-parser";
  public static final String VALIDATE = "validate";
  public static final String VALIDATE_DESC = "Perform an xml validation of the output";
  public static final String GRAPHML = "graphml";
  public static final String GRAPHML_DESC = "Create a GraphML file";
  public static final String HTML = "html";
  public static final String HTML_DESC = "Create an html file containing an annotated dot graph";
  public static final String HELP = "help";
  public static final String HELP_DESC = "Get usage information";
  public static final String DOT = "dot";
  public static final String DOT_DESC = "Absolute path to the dot executable (defaults to value in application.properties)";
  public static final String PREFIX = "prefix";
  public static final String PREFIX_DESC = "Apply given prefix to output files (defaults to value in application.properties)";
  public static final String IMG_TYPE = "imageType";
  public static final String IMG_TYPE_DESC="Indicate whether graphviz should produce a gif or png image (defaults to value in application.properties)";
  public static final String IDF = "idf";
  public static final String SDRF = "sdrf";
  public static final String EXCEL_EXT = "xlsx";
  public static final String TEXT_EXT = "txt";
  public static final String XML_EXT = "xml";
  public static final String GRAPHML_EXT = "graphml";
  public static final String DOT_EXT = "dot";
  public static final String HTML_EXT = "html";
  public static final String ZIP_EXT = "zip";
  public static final String XSL_EXT = "xsl";
  public static final String HTML_RESOURCES_ARCHIVE = "htmlResources.zip";
  
  public static final String NODE_SEPARATOR = "_";
 
  public void applicationSetup() throws ApplicationException {
    switches.put(GRAPHML, false);
    switches.put(VALIDATE, false);
    switches.put(HTML, false);
    try {
      Properties properties = new Properties();
      logger.debug("START - " + this.getClass().getSimpleName());
      properties.load(ClassLoader.getSystemResourceAsStream("application.properties"));
      filePrefix = (String)properties.get("file.prefix");
      filterPrefix = (String)properties.get("filter.prefix");
      graphvizDotPath = (String)properties.get("graphviz.dot");
      imageType = ((String)properties.get("image.type")).toLowerCase();
      logger.debug("END - " + this.getClass().getSimpleName());
    }
    catch(IOException ioe) {
      throw new ApplicationException(ioe.getMessage());
    }
  }
  
  public static String escapeXml(String s) {
    return s.replaceAll("&", "&amp;").replaceAll(">", "&gt;").replaceAll("<", "&lt;").replaceAll("\"", "&quot;").replaceAll("'", "&apos;");
  }
}

package edu.upenn.cbil.biomatgraph;

import java.io.IOException;
import java.util.Properties;

import org.apache.log4j.PropertyConfigurator;

/**
 * Initial setup of the application.
 * @author crislawrence
 *
 */
public class ApplicationConfiguration {
  public static String databaseUser;
  public static String databasePassword;
  public static String databaseHost;
  public static String databaseSid;
  public static String databasePoolMinSize;
  public static String databasePoolMaxSize;
  public static String filePrefix;
  public static String graphvizDotPath;
  public static final String MATERIAL_ENTITY = "material entity";
  public static final String DATA_ITEM = "data item";
  public static final String MAP_FILE_NAME = "map";


  /**
   * Populates the constants provided by the application.properties file.  Aside from database
   * connection parameters, a path to dot.exe and name prefix for the resulting files must be
   * provided.
   * @throws ApplicationException
   */
  public void applicationSetup() throws ApplicationException {
    try {
      Properties properties = new Properties();
      properties.load(ClassLoader.getSystemResourceAsStream("application.properties"));
      databaseUser = (String)properties.get("database.user");
      databasePassword = (String)properties.get("database.password");
      databaseHost = (String)properties.get("database.host");
      databaseSid = (String)properties.get("database.sid");
      databasePoolMinSize = (String)properties.get("database.poolMinSize");
      databasePoolMaxSize = (String)properties.get("database.poolMaxSize");
      filePrefix = (String)properties.get("file.prefix");
      graphvizDotPath = (String)properties.get("graphviz.dot");
      log4jSetup();
    }
    catch(IOException ioe) {
	  throw new ApplicationException(ioe.getMessage());
	}
  }
	
  /**
   * Sets up the log4j logging based upon the log4j.properties file.
   * @throws ApplicationException
   * @throws IOException
   */
  public void log4jSetup() throws ApplicationException, IOException {
    Properties properties = new Properties();
	properties.load(ClassLoader.getSystemResourceAsStream("log4j.properties"));
	PropertyConfigurator.configure(properties);
  }
}


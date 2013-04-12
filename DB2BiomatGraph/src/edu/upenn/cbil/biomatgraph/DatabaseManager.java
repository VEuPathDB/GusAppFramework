package edu.upenn.cbil.biomatgraph;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import javax.sql.DataSource;

import org.apache.log4j.Logger;


public class DatabaseManager {
  public static Logger logger = Logger.getLogger(DatabaseManager.class);
  public static DataSource dataSource = null;
  
  public static Connection getConnection() {
	  Connection connection = null;
      try {
    	String databaseConnectionUrl = "jdbc:oracle:thin:" +
          "@" + ApplicationConfiguration.databaseHost +
          ":1521:" + ApplicationConfiguration.databaseSid;
    	Class.forName("oracle.jdbc.driver.OracleDriver");
    	logger.debug("Oracle connection Url: " + databaseConnectionUrl);
        connection = DriverManager.getConnection(databaseConnectionUrl, ApplicationConfiguration.databaseUser, ApplicationConfiguration.databasePassword);
        if(connection == null) {
          throw new ApplicationException("Connection to database was not made.");
        }
      }
      catch(ClassNotFoundException cnfe) {
        throw new ApplicationException(cnfe.getMessage());
      }
      catch(SQLException se) {
    	throw new ApplicationException(se.getMessage());
      }
      return connection;
  }
  
  public static void closeAll(ResultSet resultSet, Statement statement, Connection connection) {
	closeResultSet(resultSet);
	closeStatement(statement);
	closeConnection(connection);
  }
  
  public static void closeResultSet(ResultSet resultSet) {
	if(resultSet != null) {
	  try {
		resultSet.close();
	  }
	  catch(SQLException se) {
		throw new ApplicationException("Could not close the database result set: " + se.getMessage());
	  }
	}
  }
  
  public static void closeStatement(Statement statement) {
	if(statement != null) {
	  try {
		statement.close();
	  }
	  catch(SQLException se) {
		throw new ApplicationException("Could not close the database statement: " + se.getMessage());
	  }
	}
  }
  
  public static void closeConnection(Connection connection) {
    if(connection != null) {
      try {
    	connection.close();	
      }
      catch(SQLException se) {
    	throw new ApplicationException("Could not close the database connection: " + se.getMessage());
      }      
    }
  }
  
}

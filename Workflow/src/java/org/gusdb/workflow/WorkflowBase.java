package org.gusdb.workflow;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

public class WorkflowBase {
    public static final String READY = "READY"; // my parents are not done yet  -- default state
    public static final String ON_DECK = "ON_DECK";  //my parents are done, but there is no slot for me
    public static final String FAILED = "FAILED";
    public static final String DONE = "DONE";
    public static final String RUNNING = "RUNNING";
    public static final String WAITING_FOR_PILOT = "WAITING_FOR_PILOT";  // not used yet.
    
    public static final String START = "START";
    public static final String  END = "END";

    final static String nl = System.getProperty("line.separator");

    private Connection dbConnection;
    String homeDir;
    private Properties workflowProps;

    // methods shared by the perl controller and perl step wrapper.
    // any other language implementation would presumably need equivalent code
    public WorkflowBase(String homeDir) {
	this.homeDir = homeDir;
    }

    Connection getDbConnection() throws SQLException, FileNotFoundException, IOException {
	if (dbConnection == null) {
	    DriverManager.registerDriver (new oracle.jdbc.driver.OracleDriver());
	    dbConnection = DriverManager.getConnection(getWorkflowConfig("dbConnectString"),
	            getWorkflowConfig("dbLogin"),
	            getWorkflowConfig("dbPassword"));
	}
	return dbConnection;
    }

    void runSql(String sql) throws SQLException, FileNotFoundException, IOException {
	Statement stmt = getDbConnection().createStatement();
	stmt.executeUpdate(sql);
    }

    ResultSet runSqlQuerySingleRow(String sql) throws SQLException, FileNotFoundException, IOException {
        Statement stmt = getDbConnection().createStatement();
        ResultSet rs = stmt.executeQuery(sql);
        rs.next();
        return rs;
    }

    String getHomeDir() {
	return homeDir;
    }

    String getWorkflowConfig(String key) throws FileNotFoundException, IOException {
        if (workflowProps == null) {
            workflowProps = new Properties();
            workflowProps.load(new FileInputStream(getHomeDir() + "/config/workflow.prop"));
        }
        return workflowProps.getProperty(key);

        /* FIX
    my @properties = 
	(
	 // [name, default, description]
	 ['name', "", ""],
	 ['version', "", ""],
	 ['dbLogin', "", ""],
	 ['dbPassword', "", ""],
	 ['dbConnectString', "", ""],
	 ['workflowXmlFile', "", ""],
	);
	*/
    }

    void error(String msg) {
        Utilities.error(msg);
    }
}

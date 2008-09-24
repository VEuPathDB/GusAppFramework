package org.gusdb.workflow;

import java.sql.Connection;
import java.sql.Statement;

public class WorkflowBase {
    public static final String READY = "READY"; // my parents are not done yet  -- default state
    public static final String ON_DECK = 'ON_DECK';  //my parents are done, but there is no slot for me
    public static final String FAILED = "FAILED";
    public static final String DONE = "DONE";
    public static final String RUNNING = "RUNNING";
    public static final String WAITING_FOR_PILOT = "WAITING_FOR_PILOT";  // not used yet.

    public static final String START = "START";
    public static final String  END = "END";

    Connection dbConnection;

    // methods shared by the perl controller and perl step wrapper.
    // any other language implementation would presumably need equivalent code
    public void WorkflowBase(String homeDir) {
	this.homeDir = homeDir;
    }

    Connection getDbConnection {
	if (dbConnection == null) {
	    DriverManager.registerDriver (new oracle.jdbc.driver.OracleDriver());

	    Connection dbConnection = 
		DriverManager.getConnection(getWorkflowConfig("dbConnectString"),
					    getWorkflowConfig("dbLogin"),
					    getWorkflowConfig("dbPassword"));
	}
	return dbConnection;
    }

    void runSql(String sql) {
	Connection connection = getConnection();
	Statement stmt = connection.createStatement();
	stmt.executeUpdate(sql);
    }

    ResultSet runSqlQuery_single_row(String sql) {
	Statement stmt = getConnection().createStatement();
	return stmt.executeQuery(sql);
    }

    String getHomeDir() {
	return homeDir;
    }

    String getWorkflowConfig(String key) {
	/* FIX
    my @properties = 
	(
	 // [name, default, description]
	 ['name', "", ""],
	 ['version', "", ""],
	 ['dbLogin', "", ""],
	 ['dbPassword', "", ""],
	 ['dbConnectString', "", ""],
	 ['workflowFile', "", ""],
	);

    if (!$self->{workflowConfig}) {
      my $workflowConfigFile = "$self->{homeDir}/config/workflow.prop";
      $self->{workflowConfig} =
	CBIL::Util::PropertySet->new($workflowConfigFile, \@properties);
    }
    return $self->{workflowConfig}->getProp($key);
	*/
	return "";
    }

    void error(String msg) {
	System.err.println(msg);
	System.exit(1);
    }
}

package edu.upenn.cbil.biomatgraph;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;


public class BiomaterialsGraphDAO {
	private static Logger logger = Logger.getLogger(BiomaterialsGraphDAO.class);
	private static Connection connection = null;
	
	public static final String QUERY_NODES_BY_ID = "" +
	  "SELECT p.protocol_app_node_id AS id, p.name AS label, o.name AS node_type " +
	  " FROM study.protocolappnode p, study.studylink sl, study.study s, sres.ontologyterm o " +
	  " WHERE p.protocol_app_node_id=sl.protocol_app_node_id " +
	  "  AND sl.study_id = ? " +
	  "  AND p.type_id = o.ontology_term_id ";
	
	public static final String QUERY_EDGES_BY_ID = "" +
	  "SELECT i.protocol_app_node_id AS node1, p.name AS label, o.protocol_app_node_id AS node2 " +
	  " FROM study.input i, study.output o, study.studylink sl, study.protocol p, study.protocolapp pa " +
	  " WHERE i.protocol_app_id = o.protocol_app_id " +
	  "  AND i.protocol_app_node_id = sl.protocol_app_node_id " +
	  "  AND i.protocol_app_id = pa.protocol_app_id " +
	  "  AND pa.protocol_id = p.protocol_id " +
	  "  AND sl.study_id = ? ";
	
  public static void openConnection() {
	BiomaterialsGraphDAO.connection = DatabaseManager.getConnection();
  }
		  
  public static void closeConnection() {
    DatabaseManager.closeConnection(connection);
	connection = null;
  }
		    
  public static List<Node> getNodes(long id) {
    logger.debug("Starting getNodes for study id: " + id);
	PreparedStatement statement = null;
    ResultSet resultSet = null;
	List<Node> nodes = new ArrayList<Node>();
	  try {
	    statement = connection.prepareStatement(QUERY_NODES_BY_ID);
		logger.debug("Query nodes By Id: " + QUERY_NODES_BY_ID);
		statement.setLong(1, id);
		resultSet = statement.executeQuery();
		while (resultSet.next()) {
		  Node node = new Node();
		  node.setNodeId(resultSet.getLong("id"));
		  node.setLabel(resultSet.getString("label"));
		  node.setType(resultSet.getString("node_type"));
		  logger.debug("Node: " + node);
		  nodes.add(node);
		}
	    logger.debug("Returned " + nodes.size() + " nodes");
		return nodes;
	  }
	  catch(SQLException se) {
	    throw new ApplicationException(se.getMessage());
	  }
	  finally {
	    DatabaseManager.closeAll(resultSet,statement,null);
  	  }
    }
			
  public static List<Edge> getEdges(long id) {
    logger.debug("Starting getNodes for study id: " + id);
	PreparedStatement statement = null;
	ResultSet resultSet = null;
	List<Edge> edges = new ArrayList<Edge>();
	  try {
	    statement = connection.prepareStatement(QUERY_EDGES_BY_ID);
		logger.debug("Query edges By Id: " + QUERY_EDGES_BY_ID);
		statement.setLong(1, id);
		resultSet = statement.executeQuery();
		while (resultSet.next()) {
		  Edge edge = new Edge();
		  edge.setLabel(resultSet.getString("label"));
		  edge.setFromNode(resultSet.getLong("node1"));
		  edge.setToNode(resultSet.getLong("node2"));
		  logger.debug("Edge: " + edge);
		  edges.add(edge);
		}
	    logger.debug("Returned " + edges.size() + " edges");
		return edges;
	  }
	  catch(SQLException se) {
	    throw new ApplicationException(se.getMessage());
	  }
	  finally {
	    DatabaseManager.closeAll(resultSet,statement,null);
  	  }
    }
  
}

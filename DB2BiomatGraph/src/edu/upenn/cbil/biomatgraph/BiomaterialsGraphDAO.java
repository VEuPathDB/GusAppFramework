package edu.upenn.cbil.biomatgraph;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;

import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.ListMultimap;


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
	
  public static final String QUERY_TAXON = "" +
    "SELECT t.name AS taxon " +
    " FROM sres.taxonname t, study.protocolappnode p " +
    " WHERE t.name_class = 'scientific name' " +
    "  AND t.taxon_id = p.taxon_id " +
    "  AND p.protocol_app_node_id = ? ";
	
  public static final String QUERY_MATERIAL_CHAR = "" +
   "SELECT o.name AS name " +
    " FROM sres.ontologyterm o, study.characteristic c " +
   " WHERE o.ontology_term_id = c.ontology_term_id " +
    "  AND c.protocol_app_node_id = ? ";
	
  public static final String QUERY_DATA_URI = "" +
    "SELECT uri FROM study.protocolappnode " +
    "  WHERE protocol_app_node_id = ? ";
	
  public static final String QUERY_PROTOCOL_PARAMS = "" +
    "SELECT pp.name AS name, pap.value AS value, ot.name AS unit_type " +
    " FROM study.protocolparam pp, study.protocolappparam pap, study.protocolapp pa, " +
    "      study.input i, study.output o, sres.ontologyterm ot " +
    " WHERE pp.protocol_param_id = pap.protocol_param_id " +
    "  AND pap.protocol_app_id = pa.protocol_app_id " +
    "  AND pp.unit_type_id = ot.ontology_term_id(+) " +
    "  AND pa.protocol_app_id = i.protocol_app_id " +
    "  AND i.protocol_app_node_id = ? " +
    "  AND pa.protocol_app_id = o.protocol_app_id " +
    "  AND o.protocol_app_node_id = ? ";
  
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
	    node.setTaxon(BiomaterialsGraphDAO.getTaxon(node.getNodeId()));
	    node.setUri(BiomaterialsGraphDAO.getUri(node.getNodeId()));
	    node.setCharacteristics(BiomaterialsGraphDAO.getMaterialChars(node.getNodeId()));
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
  
  protected static String getTaxon(long id) {
    logger.debug("Starting getTaxon for node id: " + id);
	PreparedStatement statement = null;
	ResultSet resultSet = null;
	String taxon = null;
	try {
	  statement = connection.prepareStatement(QUERY_TAXON);
	  logger.debug("Query taxon: " + QUERY_TAXON);
	  statement.setLong(1, id);
	  resultSet = statement.executeQuery();
	  if (resultSet.next()) {
		taxon = resultSet.getString("taxon");
	  }
	  return StringUtils.isEmpty(taxon) ? null : taxon;
	}
    catch(SQLException se) {
      throw new ApplicationException(se.getMessage());
	}
    finally {
      DatabaseManager.closeAll(resultSet,statement,null);
    }
  }
  
  protected static String getUri(long id) {
    logger.debug("Starting getUri for node id: " + id);
	PreparedStatement statement = null;
	ResultSet resultSet = null;
	String uri = null;
	try {
	  statement = connection.prepareStatement(QUERY_DATA_URI);
	  logger.debug("Query uri: " + QUERY_DATA_URI);
	  statement.setLong(1, id);
	  resultSet = statement.executeQuery();
	  if (resultSet.next()) {
		uri = resultSet.getString("uri");
	  }
	  return StringUtils.isEmpty(uri) ? null : uri;
	}
	catch(SQLException se) {
	  throw new ApplicationException(se.getMessage());
	}
    finally {
      DatabaseManager.closeAll(resultSet,statement,null);
    }
  }
  
  protected static List<String> getMaterialChars(long id) {
    logger.debug("Starting getMaterialChars for node id: " + id);
	PreparedStatement statement = null;
	ResultSet resultSet = null;
	List<String> characteristics = new ArrayList<>();
	try {
	  statement = connection.prepareStatement(QUERY_MATERIAL_CHAR);
	  logger.debug("Query material characteristics: " + QUERY_MATERIAL_CHAR);
	  statement.setLong(1, id);
	  resultSet = statement.executeQuery();
	  while(resultSet.next()) {
		String characteristic = resultSet.getString("name");
		if(!StringUtils.isEmpty(characteristic)) {
		  characteristics.add(characteristic);
		}
	  }
	  return characteristics.isEmpty() ? null : characteristics;
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
		  edge.setParams(getProtocolParams(edge.getFromNode(), edge.getToNode()));
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
  
  protected static ListMultimap<String,String> getProtocolParams(long fromId, long toId) {
    logger.debug("Starting getProtocol for node ids: " + fromId + " -> " + toId);
    PreparedStatement statement = null;
	ResultSet resultSet = null;
	ArrayListMultimap<String,String> map = ArrayListMultimap.create();
	try {
	  statement = connection.prepareStatement(QUERY_PROTOCOL_PARAMS);
	  logger.debug("Query uri: " + QUERY_PROTOCOL_PARAMS);
      statement.setLong(1, fromId);
	  statement.setLong(2, toId);
	  resultSet = statement.executeQuery();
	  while(resultSet.next()) {
		String key = resultSet.getString("name");
		String value = resultSet.getString("value");
		String unit = resultSet.getString("unit_type");
		if(StringUtils.isNotEmpty(value)) {
		  map.put(key, value);
		}
		if(StringUtils.isNotEmpty(unit)) {
		  map.put(key, unit);
		}
	  }
	  return map.isEmpty() ? null : map;
	}
	catch(SQLException se) {
	  throw new ApplicationException(se.getMessage());
	}
    finally {
      DatabaseManager.closeAll(resultSet,statement,null);
    }
  }
  
}

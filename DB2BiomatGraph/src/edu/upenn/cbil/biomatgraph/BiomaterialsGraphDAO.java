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
  
  public static final String QUERY_STUDY_NAME_BY_ID = "" +
    "SELECT name FROM study.study WHERE study_id = ?";
  
  public static final String QUERY_NODES_BY_ID = "" +
    "SELECT p.protocol_app_node_id AS id, p.name AS label, " +
    "       p.description AS description, o.name AS node_type " +
    " FROM study.protocolappnode p, study.studylink sl, study.study s, sres.ontologyterm o " +
    " WHERE p.protocol_app_node_id = sl.protocol_app_node_id " +
    "  AND sl.study_id = ? " +
    "  AND sl.study_id = s.study_id " +
    "  AND p.type_id = o.ontology_term_id ";
	
  public static final String QUERY_EDGES_BY_ID = "" +
    "SELECT i.protocol_app_node_id AS node1, p.name AS label, o.protocol_app_node_id AS node2, " +
    "  p.protocol_id AS protocolId, pa.protocol_app_id AS protocolAppId " +
    " FROM study.input i, study.output o, study.studylink sl, study.protocol p, study.protocolapp pa " +
    " WHERE i.protocol_app_id = o.protocol_app_id " +
    "  AND i.protocol_app_node_id = sl.protocol_app_node_id " +
    "  AND i.protocol_app_id = pa.protocol_app_id " +
    "  AND pa.protocol_id = p.protocol_id " +
    "  AND sl.study_id = ? ";
  
  public static final String QUERY_PROTOCOL_SERIES = "" +
    "SELECT order_num AS step, protocol_id AS protocolId " +
    " FROM study.protocolserieslink " +
    " WHERE protocol_series_id = ? "; 
  
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
  
  public static final String QUERY_PROTOCOL_DETAILS = "" +
    "SELECT name, description FROM study.protocol WHERE protocol_id = ? ";
	
  public static final String QUERY_PROTOCOL_PARAMS = "" +
    "SELECT pp.name AS name, pap.value AS value, ot.name AS unit_type " +
    " FROM study.protocolparam pp, study.protocolappparam pap, sres.ontologyterm ot " +
    " WHERE pp.protocol_param_id = pap.protocol_param_id " +
    "  AND pp.unit_type_id = ot.ontology_term_id(+) " +
    "  AND pap.protocol_app_id = ? AND pp.protocol_id = ? ";
  
  public static final String QUERY_PERFORMER = "" +
    "SELECT c.name AS name " +
    " FROM sres.contact c, study.protocolappcontact pc " +
    " WHERE c.contact_id = pc.contact_id " +
    "  AND pc.protocol_app_id = ? AND pc.order_num = ? "; 
  
  public static void openConnection() {
	BiomaterialsGraphDAO.connection = DatabaseManager.getConnection();
  }
		  
  public static void closeConnection() {
    DatabaseManager.closeConnection(connection);
	connection = null;
  }
  
  /**
   * Obtain the name of the study given it's id
   * @param id - study id
   * @return - study name
   */
  public static String getStudyName(long id) {
    logger.debug("START - getStudyName for study id: " + id);
    PreparedStatement statement = null;
    ResultSet resultSet = null;
    String studyName = null;
    try {
      statement = connection.prepareStatement(QUERY_STUDY_NAME_BY_ID);
      logger.debug("Query nodes By Id: " + QUERY_STUDY_NAME_BY_ID);
      statement.setLong(1, id);
      resultSet = statement.executeQuery();
      if(resultSet.next()) {
        studyName = resultSet.getString("name");
      }
      return studyName;
    }
    catch(SQLException se) {
      throw new ApplicationException(se.getMessage());
    }
    finally {
      DatabaseManager.closeAll(resultSet,statement,null);
    }
  }
		    
  /**
   * Obtains a list of Nodes for the provided study id
   * @param id - study id
   * @return - List of Nodes
   */
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
	    node.setDescription(resultSet.getString("description"));
	    String type = resultSet.getString("node_type");
	    node.setType(type);
	    if(ApplicationConfiguration.MATERIAL_ENTITY.equalsIgnoreCase(type)) {
	      node.setTaxon(BiomaterialsGraphDAO.getTaxon(node.getNodeId()));
	      node.setCharacteristics(BiomaterialsGraphDAO.getMaterialChars(node.getNodeId()));
	    }
	    if(ApplicationConfiguration.DATA_ITEM.equalsIgnoreCase(type)) {
	      node.setUri(BiomaterialsGraphDAO.getUri(node.getNodeId()));
	    }
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
  
  /**
   * Returns the taxon for a given node id
   * @param id - node id
   * @return - String representing the taxon
   */
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
  
  /**
   * Obtains the url for a given node id
   * @param id - node id
   * @return - String representing the uri
   */
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
  
  /**
   * Obtain the material characteristics associated with the given node
   * @param id - node id
   * @return - a List of String representations of material characteristcs
   */
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
			
  /**
   * Obtain the edges for a given study id
   * @param id - study id
   * @return - list of partially populated edges (protocol application data not fully in place)
   */
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
	    edge.setProtocolId(resultSet.getLong("protocolId"));
	    edge.setEdgeId(resultSet.getLong("protocolAppId"));
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
  
  /**
   * If an edge describes a protocol series, collect those protocol applications into
   * the applications member of the edge.  The applications list contains a list of
   * protocol applications which are sparsely populated with protocol id and step at this
   * juncture.
   * @param edge - the edge object under evaluation here.
   */
  public static void checkForProtocolSeries(Edge edge) {
    long protocolId = edge.getProtocolId();
    logger.debug("Starting checkForProtocolSeries for protocol id: " + protocolId);
    List<ProtocolApplication> applications = edge.getApplications();
    PreparedStatement statement = null;
    ResultSet resultSet = null;
    try {
      statement = connection.prepareStatement(QUERY_PROTOCOL_SERIES);
      logger.debug("Query for series: " + QUERY_PROTOCOL_SERIES);
      statement.setLong(1, protocolId);
      resultSet = statement.executeQuery();
      while(resultSet.next()) {
        ProtocolApplication application = new ProtocolApplication();
        application.setProtocolApplicationId(resultSet.getLong("protocolId"));
        application.setStep(resultSet.getInt("step"));
        applications.add(application);
      }
    }
    catch(SQLException se) {
      throw new ApplicationException(se.getMessage());
    }
    finally {
      DatabaseManager.closeAll(resultSet,statement,null);
    }
  }
  
  /**
   * Obtain the name and description of the protocol application
   * @param application - the protocol application to which to add the details
   */
  public static void getProtocolDetails(ProtocolApplication application) {
    long protocolId = application.getProtocolApplicationId();
    logger.debug("Starting getProtocolDetails for protocol: " + protocolId);
    PreparedStatement statement = null;
    ResultSet resultSet = null;
    try {
      statement = connection.prepareStatement(QUERY_PROTOCOL_DETAILS);
      logger.debug("Query protocol detail: " + QUERY_PROTOCOL_DETAILS);
      statement.setLong(1, protocolId);
      resultSet = statement.executeQuery();
      if(resultSet.next()) {
        application.setName(resultSet.getString("name"));
        application.setDescription(resultSet.getString("description"));
      }
    }
    catch(SQLException se) {
      throw new ApplicationException(se.getMessage());
    }
    finally {
      DatabaseManager.closeAll(resultSet,statement,null);
    }
  }
  
  /**
   * Obtain the parameter data (formatted as a string: name = value unit) for the given
   * application.
   * @param edgeId - id of the edge holding the application
   * @param application - the application into which the list of parameter data is to be added.
   */
  public static void getProtocolParams(long edgeId, ProtocolApplication application) {
    long protocolId = application.getProtocolApplicationId();
    logger.debug("Starting getProtocolParams for protocol application id: " + protocolId);
    PreparedStatement statement = null;
	ResultSet resultSet = null;
	try {
	  statement = connection.prepareStatement(QUERY_PROTOCOL_PARAMS);
	  logger.debug("Query protocol params: " + QUERY_PROTOCOL_PARAMS);
      statement.setLong(1, edgeId);
	  statement.setLong(2, protocolId);
	  resultSet = statement.executeQuery();
	  while(resultSet.next()) {
		String parameter = resultSet.getString("name");
		String value = resultSet.getString("value");
		String unit = resultSet.getString("unit_type");
		if(StringUtils.isNotEmpty(value)) {
		  parameter += " : " + value;
		  if(StringUtils.isNotEmpty(unit)) {
		    parameter += " " + unit;
		  }
		}
		application.getParameters().add(parameter);
	  }
	}
	catch(SQLException se) {
	  throw new ApplicationException(se.getMessage());
	}
    finally {
      DatabaseManager.closeAll(resultSet,statement,null);
    }
  }
  
  /**
   * Obtain the performer from the database for the given application
   * @param edgeId - id of the edge holding the application
   * @param application - the application to which the performer is to be added.
   */
  public static void getPerformer(long edgeId, ProtocolApplication application) {
    int step = application.getStep();
    logger.debug("Starting getPerformer for step: " + step);
    PreparedStatement statement = null;
    ResultSet resultSet = null;
    try {
      statement = connection.prepareStatement(QUERY_PERFORMER);
      logger.debug("Query performer: " + QUERY_PERFORMER);
      statement.setLong(1, edgeId);
      statement.setLong(2, step);
      resultSet = statement.executeQuery();
      if(resultSet.next()) {
        application.setPerformer(resultSet.getString("name"));
      }
    }
    catch(SQLException se) {
      throw new ApplicationException(se.getMessage());
    }
    finally {
      DatabaseManager.closeAll(resultSet,statement,null);
    }
  }
  
  
  
}

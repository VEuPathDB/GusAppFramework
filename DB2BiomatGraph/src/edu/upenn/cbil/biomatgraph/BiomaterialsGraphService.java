package edu.upenn.cbil.biomatgraph;

import java.util.List;

import org.apache.log4j.Logger;

/**
 * The class provides a set of services used to assemble the biomaterials graph.  Most services
 * simply call the appropriate DAO method in behalf of the invoking method.
 * @author crislawrence
 *
 */
public class BiomaterialsGraphService {

  @SuppressWarnings("unused")
  private static Logger logger = Logger.getLogger(BiomaterialsGraphService.class);
  
  /**
   * Opens or closes the database connection according to the argument provided.
   * @param open - open the connection if true, close otherwise.
   */
  public void manageConnection(boolean open) {
	if(open) {
	  BiomaterialsGraphDAO.openConnection();
	}
	else {
	  BiomaterialsGraphDAO.closeConnection();
    }
  }
  
  /**
   * Retrieve the study name
   * @param studyId - study id
   * @return - name String
   */
  public String getStudyName(long studyId) {
    return BiomaterialsGraphDAO.getStudyName(studyId);
  }
  
  /**
   * Retrieve the study nodes
   * @param studyId - study id
   * @return - list of nodes
   */
  public List<Node> getNodes(long studyId) {
	return BiomaterialsGraphDAO.getNodes(studyId);
  }
  
  /**
   * Retrieve the study edges
   * @param studyId - study id
   * @return - list of edges
   */
  protected List<Edge> getEdges(long studyId) {
	return BiomaterialsGraphDAO.getEdges(studyId);
  }
  
  /**
   * Retrieve the edge data and check whether or not the edge contains a protocol series.  If
   * so, the applications list is populated.  If the applications list is empty, the edge involves
   * only one protocol application a new protocol application is instantiated, populated with
   * the id and added to the empty list.  Then all application are populated, one by one, with
   * the protocol details, parameters and performer.  The parameters are sorted by name to
   * improve legibility.
   * @param studyId - study id
   * @return - list of fully populated edges
   */
  public List<Edge> constructEdgeData(long studyId) {
    List<Edge> edges = BiomaterialsGraphDAO.getEdges(studyId);
    for(Edge edge : edges) {
      BiomaterialsGraphDAO.checkForProtocolSeries(edge);
      long edgeId = edge.getEdgeId();
      if(edge.getApplications().isEmpty()) {
        edge.getApplications().add(new ProtocolApplication(edge.getProtocolId()));
      }
      else if(edge.getApplications().size() == 1) {
        throw new ApplicationException("Shouldn't get 1 app.");
      }
      for(ProtocolApplication application : edge.getApplications()) {
        BiomaterialsGraphDAO.getProtocolDetails(application);
        BiomaterialsGraphDAO.getProtocolParams(edgeId, application);
        ProtocolApplication.sortParametersByName(application.getParameters());
        BiomaterialsGraphDAO.getPerformer(edgeId, application);
      }
    }
    return edges;
  }
  
}

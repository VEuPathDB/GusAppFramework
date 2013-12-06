package edu.upenn.cbil.biomatgraph;

import java.util.List;

import org.apache.log4j.Logger;

public class BiomaterialsGraphService {

  @SuppressWarnings("unused")
  private static Logger logger = Logger.getLogger(BiomaterialsGraphService.class);
  
  public void manageConnection(boolean open) {
	if(open) {
	  BiomaterialsGraphDAO.openConnection();
	}
	else {
	  BiomaterialsGraphDAO.closeConnection();
    }
  }
  
  public String getStudyName(long studyId) {
    return BiomaterialsGraphDAO.getStudyName(studyId);
  }
  
  public List<Node> getNodes(long studyId) {
	return BiomaterialsGraphDAO.getNodes(studyId);
  }
  
  protected List<Edge> getEdges(long studyId) {
	return BiomaterialsGraphDAO.getEdges(studyId);
  }
  
  public List<Edge> constructEdgeData(long studyId) {
    List<Edge> edges = BiomaterialsGraphDAO.getEdges(studyId);
    for(Edge edge : edges) {
      BiomaterialsGraphDAO.checkForProtocolSeries(edge);
      long protocolAppId = edge.getProtocolAppId();
      if(edge.getApplications().isEmpty()) {
        edge.getApplications().add(new ProtocolApplication(edge.getProtocolId()));
      }
      else if(edge.getApplications().size() == 1) {
        throw new ApplicationException("Shouldn't get 1 app.");
      }
      for(ProtocolApplication application : edge.getApplications()) {
        BiomaterialsGraphDAO.getProtocolDetails(application);
        BiomaterialsGraphDAO.getProtocolParams(protocolAppId, application);
        BiomaterialsGraphDAO.getPerformer(protocolAppId, application);
      }
    }
    return edges;
  }
  
}

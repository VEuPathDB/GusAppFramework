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
  
  public List<Edge> getEdges(long studyId) {
	return BiomaterialsGraphDAO.getEdges(studyId);
  }
  
}

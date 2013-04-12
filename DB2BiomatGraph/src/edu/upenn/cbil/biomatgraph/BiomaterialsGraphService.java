package edu.upenn.cbil.biomatgraph;

import java.util.List;

import org.apache.log4j.Logger;

public class BiomaterialsGraphService {
  private static Logger logger = Logger.getLogger(BiomaterialsGraphService.class);
	  
  public void manageConnection(boolean open) {
	if(open) {
	  BiomaterialsGraphDAO.openConnection();
	}
	else {
	  BiomaterialsGraphDAO.closeConnection();
    }
  }
  
  public List<Node> getNodes(long studyId) {
	List<Node> nodes = BiomaterialsGraphDAO.getNodes(studyId);
	return nodes;
  }
  
  public List<Edge> getEdges(long studyId) {
	List<Edge> edges = BiomaterialsGraphDAO.getEdges(studyId);
	return edges;
  }
  
}

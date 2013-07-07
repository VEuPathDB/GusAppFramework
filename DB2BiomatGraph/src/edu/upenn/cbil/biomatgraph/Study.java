package edu.upenn.cbil.biomatgraph;

import java.util.List;

import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.log4j.Logger;

public class Study {
  private long studyId;
  private String studyName;
  private List<Node> nodes;
  private List<Edge> edges;
  public static Logger logger = Logger.getLogger(Study.class);
  
  public final long getStudyId() {
    return studyId;
  }
  public final void setStudyId(long studyId) {
    this.studyId = studyId;
  }
  public final String getStudyName() {
    return studyName;
  }
  public final void setStudyName(String studyName) {
    this.studyName = studyName;
  }
  public final List<Node> getNodes() {
    return nodes;
  }
  public final void setNodes(List<Node> nodes) {
    this.nodes = nodes;
  }
  public final List<Edge> getEdges() {
    return edges;
  }
  public final void setEdges(List<Edge> edges) {
    this.edges = edges;
  }
  
  @Override
  public String toString() {
    return ReflectionToStringBuilder.toString(this);
  }

}

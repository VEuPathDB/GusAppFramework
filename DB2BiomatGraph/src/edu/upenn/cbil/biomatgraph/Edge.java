package edu.upenn.cbil.biomatgraph;

import org.apache.commons.lang.builder.ReflectionToStringBuilder;

public class Edge {
  private String label;
  private long fromNode;
  private long toNode;
  
  public String getLabel() {
	return label;
  }
  public void setLabel(String label) {
	this.label = label;
  }
  public long getFromNode() {
	return fromNode;
  }
  public void setFromNode(long fromNode) {
	this.fromNode = fromNode;
  }
  public long getToNode() {
	return toNode;
  }
  public void setToNode(long toNode) {
	this.toNode = toNode;
  }
  
  public String toString() {
    return ReflectionToStringBuilder.toString(this);
  }
  
}

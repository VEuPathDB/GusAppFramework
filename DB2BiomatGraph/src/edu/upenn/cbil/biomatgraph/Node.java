package edu.upenn.cbil.biomatgraph;

import org.apache.commons.lang.builder.ReflectionToStringBuilder;

public class Node {
  private long nodeId;
  private String label;
  private String type;
  
  public long getNodeId() {
	return nodeId;
  }
  public void setNodeId(long nodeId) {
	this.nodeId = nodeId;
  }
  public String getLabel() {
	return label;
  }
  public void setLabel(String label) {
	this.label = label;
  }
  public String getType() {
	return type;
  }
  public void setType(String type) {
	this.type = type;
  }
  
  public String getColor() {
    String color = "black";
	switch(type) {
      case "data item":
        color = "red";
        break;
      case "material entity":
    	color = "blue";
    	break;
      default:
    }
	return color;
  }
  
  public String toString() {
    return ReflectionToStringBuilder.toString(this);
  }
  
}

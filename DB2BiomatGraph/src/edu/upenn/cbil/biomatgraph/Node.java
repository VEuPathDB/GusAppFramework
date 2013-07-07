package edu.upenn.cbil.biomatgraph;

import java.util.List;

import org.apache.commons.lang.WordUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;

public class Node {
  private long nodeId;
  private String label;
  private String type;
  private String taxon;
  private String uri;
  private List<String> characteristics;
  
  public long getNodeId() {
	return nodeId;
  }
  public void setNodeId(long nodeId) {
	this.nodeId = nodeId;
  }
  public String getLabel() {
	return WordUtils.wrap(label, 15, "\\n", true);
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
  public String getTaxon() {
	return taxon;
  }
  public void setTaxon(String taxon) {
	this.taxon = taxon;
  }
  public String getUri() {
	return uri;
  }
  public void setUri(String uri) {
	this.uri = uri;
  }
  public List<String> getCharacteristics() {
	return characteristics;
  }
  public void setCharacteristics(List<String> characteristics) {
	this.characteristics = characteristics;
  }
  
  public String getColor() {
    String color = "black";
	switch(type) {
      case ApplicationConfiguration.DATA_ITEM:
        color = "red";
        break;
      case ApplicationConfiguration.MATERIAL_ENTITY:
    	color = "blue";
    	break;
      default:
    }
	return color;
  }
  
  @Override
  public String toString() {
    return ReflectionToStringBuilder.toString(this);
  }
  
}

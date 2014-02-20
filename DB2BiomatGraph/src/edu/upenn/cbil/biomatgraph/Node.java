package edu.upenn.cbil.biomatgraph;

import java.util.List;

import org.apache.commons.lang.WordUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;

/**
 * A POJO class to hold all the member elements associated with a node, whether it is a data item
 * or a material entity.
 * @author crislawrence
 *
 */
public class Node {
  private long nodeId;
  private String label;
  private String description;
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
  
  /**
   * The node's label is its name but wrapped so that a particularly long name does
   * not result in a very long oval on the graph.
   * @return
   */
  public String getLabel() {
	return WordUtils.wrap(label, 15, "\\n", true);
  }
  public void setLabel(String label) {
	this.label = label;
  }
  public final String getDescription() {
    return description;
  }
  public final void setDescription(String description) {
    this.description = description;
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
  
  /**
   * Coloring is red for data item nodes and blue for material entity nodes.
   * @return - String indicating color.
   */
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

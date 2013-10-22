package edu.upenn.cbil.magetab.model;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang.WordUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;

import com.google.common.collect.ListMultimap;

/**
* POJO for holding Edge object used in creating the biomaterials graph.
 * @author crisl
 *
 */
public class Edge {
  private List<ProtocolApplication> applications;
  private String label;
  private String fromNode;
  private String toNode;

  public Edge() {
    applications = new ArrayList<>();
  }
 
  /**
   * Getter for edge label (wrapped to fit the tooltip box better)
   * @return - label string
   */
  public String getLabel() {
	return WordUtils.wrap(label, 30, "\\n", true);
  }
  /**
   * Setter for edge label - JDOM2 protocol_app protocol element
   * @param label - label string
   */
  public void setLabel(String label) {
	this.label = label;
  }
  
  /**
   * Getter for edge label (not word wrapped)
   * @return
   */
  public String getName() {
    return label;
  }
  /**
   * Getter for the id of the source node
   * @return - source node id
   */
  public String getFromNode() {
	return fromNode;
  }
  /**
   * Setter for the id of the source node - from JDOM2 protocol_app inputs element
   * @param fromNode - source node id
   */
  public void setFromNode(String fromNode) {
	this.fromNode = fromNode;
  }
  /**
   * Getter for the id of the destination node
   * @return - id of the destination node
   */
  public String getToNode() {
	return toNode;
  }
  /**
   * Setter for the id of the destination node - from JDOM2 protocol_app outputs element
   * @param toNode - id of the destination node
   */
  public void setToNode(String toNode) {
	this.toNode = toNode;
  }

  public final List<ProtocolApplication> getApplications() {
    return applications;
  }

  public final void setApplications(List<ProtocolApplication> applications) {
    this.applications = applications;
  }

  /**
   * Convenient string representation for debugging purposes.
   */
  @Override
  public String toString() {
    return (new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE) {
      protected boolean accept(Field field) {
        return super.accept(field);
      }
    }).toString();
  }
}

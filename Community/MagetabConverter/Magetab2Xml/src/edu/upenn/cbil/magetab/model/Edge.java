package edu.upenn.cbil.magetab.model;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang.WordUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;

/**
* POJO for holding Edge object used in creating the biomaterials graph.
 * @author Cris Lawrence
 *
 */
public class Edge {
  private List<ProtocolApplication> applications;
  private String label;
  private boolean hint;
  private String fromNode;
  private String toNode;

  /**
   * Base constructor to insure proper initial state.
   */
  public Edge() {
    hint = false;
    applications = new ArrayList<>();
  }
 
  /**
   * Getter for edge label (wrapped to fit the tooltip box better)
   * @return - label string
   */
  public String getLabel() {
	return WordUtils.wrap(label, 30, "<br />", true);
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
   * @return - string representing the raw label
   */
  public String getName() {
    return label;
  }
  
  /**
   * Hint that data related to an addition is hidden in the tooltip
   * @return - true if addition data is in the tooltip and false otherwise.
   */
  public final boolean isHint() {
    return hint;
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
    for(ProtocolApplication application : applications) {
      if(application.isLabelFlag()) {
        hint = true;
      }
    }
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

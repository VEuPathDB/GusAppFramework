package edu.upenn.cbil.magetab.model;

import java.lang.reflect.Field;
import java.util.Collection;
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
  private String dbId;
  private String label;
  private boolean addition;
  private String fromNode;
  private String toNode;
  private ListMultimap<String, String> params;
  
  public final String getDbId() {
    return dbId;
  }

  public final void setDbId(String dbId) {
    this.dbId = dbId;
  }

  public final boolean isAddition() {
    return addition;
  }
  
  public final void setAddition(boolean addition) {
    this.addition = addition;
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
  /**
   * Getter for the parameters map
   * @return - parameters map (key is param label and values are parm value and unit)
   */
  public Map<String, Collection<String>> getParams() {
	return  params == null ? null : params.asMap();
  }
  /**
   * Setter for the parameters map - from JDOM2 protocol_app protocol_app_parameters element and the
   * IDF (for units)
   * @param params - parameters map
   */
  public void setParams(ListMultimap<String, String> params) {
	this.params = params;
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

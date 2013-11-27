package edu.upenn.cbil.magetab.model;

import java.lang.reflect.Field;
import java.util.List;

import org.apache.commons.lang.WordUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;

import edu.upenn.cbil.magetab.utilities.ApplicationConfiguration;

/**
 * POJO for holding Node object used in creating the biomaterials graph.
 * @author crisl
 *
 */
public class Node {
  private String id;
  private String dbId;
  private String label;
  private boolean hint;
  private String type;
  private String taxon;
  private String uri;
  private boolean addition;
  private List<String> characteristics;
  public static final String MATERIAL_ENTITY = "material entity";
  public static final String DATA_ITEM = "data item";
  
  public Node() {
    hint = false;
    addition = false;
  }
  
  /**
   * Indicates a node that is an addition to an original MAGE-TAB
   * @return - true if an addition, false otherwise
   */
  public final boolean isAddition() {
    return addition;
  }
  
  public final void setAddition(boolean addition) {
    this.addition = addition;
  }
  
  /**
   * Indicates that the node has an existing database id
   * @return - the db id
   */
  public final String getDbId() {
    return dbId;
  }

  public final void setDbId(String dbId) {
    this.dbId = dbId;
  }

  /**
   * Getter for node id
   * @return - id
   */
  public String getId() {
	return id;
  }
  /**
   * Setter for node id - from JDOM2 protocol_app_node id attribute
   * @param id - id
   */
  public void setId(String id) {
	this.id = id;
  }
  /**
   * Getter for node label (wrapped to fit the tooltip box better)
   * @return - label string
   */
  public String getLabel() {
	return WordUtils.wrap(ApplicationConfiguration.escapeXml(label.replaceAll("_", " ")), 15, "<br />", true);
  }
  /**
   * Setting for node label - from JDOM2 protocol_app_node name element
   * @param label - label string
   */
  public void setLabel(String label) {
	this.label = label;
  }
  /**
   * Hint that data related to an addition is hidden in the tooltip
   * @return - true if addition data is in the tooltip and false otherwise.
   */
  public final boolean isHint() {
    return hint;
  }
  /**
   * Sets the hint that data related to an addition is hidden in the tooltip.  For a node presently,
   * this would be a Database Id.
   * @param hint - true if addition data is present and false otherwise
   */
  public final void setHint(boolean hint) {
    this.hint = hint;
  }

  public static final String getMaterialEntity() {
    return MATERIAL_ENTITY;
  }

  public static final String getDataItem() {
    return DATA_ITEM;
  }

  /**
   * Getter for node type
   * @return - type string
   */
  public String getType() {
	return type;
  }
  /**
   * Setting for node type - from JDOM2 protocol_app_node type element
   * @param type - type string
   */
  public void setType(String type) {
	this.type = type;
  }
  /**
   * Getter for taxon
   * @return - taxon string
   */
  public String getTaxon() {
	return taxon;
  }
  /**
   * Setter for taxon - from JDOM2 protocol_app_node taxon element
   * @param taxon - taxon string
   */
  public void setTaxon(String taxon) {
	this.taxon = taxon;
  }
  /**
   * Getter for uri
   * @return - uri string
   */
  public String getUri() {
	return uri;
  }
  /**
   * Setting for uri - from JDOM2 protocol_app_node uri element
   * @param uri - uri string
   */
  public void setUri(String uri) {
	this.uri = uri;
  }
  /**
   * Getter for node characteristics list
   * @return - list of node characteristics
   */
  public List<String> getCharacteristics() {
	return characteristics;
  }
  /**
   * Setter for node characteristics list - only ontology terms are retrieved.
   * @param characteristics - list of node characteristics
   */
  public void setCharacteristics(List<String> characteristics) {
	this.characteristics = characteristics;
  }
  
  /**
   * Differentiates the data and material nodes by color (red for data and blue for material,
   * black if neither).
   * @return - string representing color
   */
  public String getColor() {
    String color = "black";
    switch(type.toLowerCase()) {
      case DATA_ITEM:
        color = "red";
        break;
      case MATERIAL_ENTITY:
        color = "blue";
        break;
      default:
    }
    return color;
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

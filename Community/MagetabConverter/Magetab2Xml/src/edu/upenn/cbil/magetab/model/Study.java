package edu.upenn.cbil.magetab.model;

import java.lang.reflect.Field;
import java.util.List;

import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;
import org.apache.log4j.Logger;

/**
 * POJO holding Study object to be used for creating a biomaterials graph.
 * @author crisl
 *
 */
public class Study {
  private String studyName;
  private String dbId;
  private List<Node> nodes;
  private List<Edge> edges;
  public static Logger logger = Logger.getLogger(Study.class);

  /**
   * Study Name getter
   * @return - study name string
   */
  public final String getStudyName() {
    return studyName;
  }
  /**
   * Study name setting
   * @param studyName - study name string
   */
  public final void setStudyName(String studyName) {
    this.studyName = studyName;
  }
  /**
   * DB ID getter
   * @return - study db id (-1 if no study db id exists)
   */
  public final String getDbId() {
    return dbId;
  }
  /**
   * DB Id seeting
   * @param dbId - integer representing study db id or -1 for no study db id 
   */
  public final void setDbId(String dbId) {
    this.dbId = dbId;
  }
  /**
   * Getter for study node list
   * @return - node list
   */
  public final List<Node> getNodes() {
    return nodes;
  }
  /**
   * Setter for study node list
   * @param nodes - node list
   */
  public final void setNodes(List<Node> nodes) {
    this.nodes = nodes;
  }
  /**
   * Getting for study edge list
   * @return - edge list
   */
  public final List<Edge> getEdges() {
    return edges;
  }
  /**
   * Setting for study edge list
   * @param edges - edge list
   */
  public final void setEdges(List<Edge> edges) {
    this.edges = edges;
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

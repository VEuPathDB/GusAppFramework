package edu.upenn.cbil.biomatgraph;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang.WordUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;

/**
 * A POJO class to hold all the member elements associated with an edge.
 * @author crislawrence
 *
 */
public class Edge {
  private List<ProtocolApplication> applications;
  private String label;
  private long protocolId;
  private long edgeId;
  private long fromNode;
  private long toNode;
  
  public Edge() {
    applications = new ArrayList<>();
  }
  
  public final List<ProtocolApplication> getApplications() {
    return applications;
  }
  
  /**
   * Since an edge may represent a protocol series, an ordered list of protocol
   * applications is a component of every edge.
   * @param applications
   */
  public final void setApplications(List<ProtocolApplication> applications) {
    this.applications = applications;
  }
  
  /**
   * The edge's label is its name but wrapped so that a particularly long name does
   * does not result in an excessively long line.
   * @return - wrapped label
   */
  public String getLabel() {
	return WordUtils.wrap(label, 30, "\\n", true);
  }
  public void setLabel(String label) {
	this.label = label;
  }
  public final long getProtocolId() {
    return protocolId;
  }
  public final void setProtocolId(long protocolId) {
    this.protocolId = protocolId;
  }
  public final long getEdgeId() {
    return edgeId;
  }
  public final void setEdgeId(long edgeId) {
    this.edgeId = edgeId;
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
 
  @Override
  public String toString() {
    return ReflectionToStringBuilder.toString(this);
  }

}

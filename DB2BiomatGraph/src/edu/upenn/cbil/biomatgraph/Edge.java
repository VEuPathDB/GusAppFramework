package edu.upenn.cbil.biomatgraph;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang.WordUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;

import com.google.common.collect.ListMultimap;

public class Edge {
  private List<ProtocolApplication> applications;
  private String label;
  private long protocolId;
  private long protocolAppId;
  private long fromNode;
  private long toNode;
  
  public Edge() {
    applications = new ArrayList<>();
  }
  
  public final List<ProtocolApplication> getApplications() {
    return applications;
  }
  public final void setApplications(List<ProtocolApplication> applications) {
    this.applications = applications;
  }
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
  public final long getProtocolAppId() {
    return protocolAppId;
  }
  public final void setProtocolAppId(long protocolAppId) {
    this.protocolAppId = protocolAppId;
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

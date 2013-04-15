package edu.upenn.cbil.biomatgraph;

import java.util.Collection;
import java.util.Map;

import org.apache.commons.lang.WordUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;

import com.google.common.collect.ListMultimap;

public class Edge {
  private String label;
  private long fromNode;
  private long toNode;
  private ListMultimap<String, String> params;
  
  public String getLabel() {
	return WordUtils.wrap(label, 30, "\\n", true);
  }
  public void setLabel(String label) {
	this.label = label;
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
  public Map<String, Collection<String>> getParams() {
	return  params == null ? null : params.asMap();
  }
  public void setParams(ListMultimap<String, String> params) {
	this.params = params;
  }
  
  public String toString() {
    return ReflectionToStringBuilder.toString(this);
  }

}

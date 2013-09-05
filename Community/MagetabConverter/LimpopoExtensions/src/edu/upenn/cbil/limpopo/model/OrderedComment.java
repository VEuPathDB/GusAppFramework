package edu.upenn.cbil.limpopo.model;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;

public class OrderedComment {
  public static Logger logger = LoggerFactory.getLogger(OrderedComment.class);
  private String value;
  private Integer order;
  private String comment;
  

  public OrderedComment(String value) {
    this.value = value;
    this.comment = "";
    extractComment();
  }

  public void extractComment() {
    String[] components = value.split(":",2);
    order = Integer.parseInt(components[0]);
    if(components.length == 2) {
      comment = components[1];
    }
  }
  
  public static List<String> orderComments(Set<String> values) {
    Map<Integer,String> comments = new TreeMap<Integer,String>();
    List<String> orderedComments = new ArrayList<String>();
    for(String value : values) {
      if(value.matches("^\\d+:.*")) {
        OrderedComment orderedComment = new OrderedComment(value);
        comments.put(orderedComment.order, orderedComment.comment);
      }
    }
    orderedComments.addAll(comments.values());
    return orderedComments;
  }
  
  public static List<String> retrieveComments(String header, IDF data) {
    List<String> comments = new ArrayList<String>();
    if(data.getComments().get(header) != null) {
      comments = orderComments(data.getComments().get(header));
    }
    if(comments.isEmpty()) comments.add("");
    return comments;
  }
}

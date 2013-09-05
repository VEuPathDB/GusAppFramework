package edu.upenn.cbil.limpopo.utils;

import java.util.Collection;

import org.apache.commons.lang.StringUtils;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.layout.Location;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.layout.SDRFLayout;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.SDRFNode;

import static edu.upenn.cbil.limpopo.utils.AppUtils.*;

public class SDRFUtils {
  public static SDRFLayout layout;
  
  public SDRFUtils(SDRFLayout layout) {
    SDRFUtils.layout = layout;
  }
  
  public static String generateId(SDRFNode node) {
    Collection<Location> locations = layout.getLocationsForNode(node);
    String id = "";
    for(Location location : locations) {
      if(!StringUtils.isEmpty(id)) id += NODE_SEPARATOR;
      id += "R" + location.getLineNumber() + "C" + location.getColumn();
    }
    return id;
  }
  
  public static String parseHeader(String prefix, String header) {
    return header.replaceFirst(prefix + "\\s*\\[(.*)\\]","$1");
  }
  
  public static String parseHeader(String header) {
    return parseHeader("^.*", header);
  }
}

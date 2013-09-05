package edu.upenn.cbil.limpopo.model;

import java.util.ArrayList;
import java.util.List;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.SDRFNode;
import edu.upenn.cbil.limpopo.utils.SDRFUtils;
import static edu.upenn.cbil.limpopo.utils.AppUtils.*;

public class ProtocolObject {
  protected SDRFNode node;
  protected String id;
  protected List<Integer> lines;
  
  public ProtocolObject(SDRFNode node) {
    this.node = node;
    lines = new ArrayList<>();
    id = SDRFUtils.generateId(node);
    String[] locs = id.split(NODE_SEPARATOR);
    for(String loc : locs) {
      lines.add(Integer.parseInt(loc.replaceFirst("^R(.*)C.*$", "$1")));
    }
  }

  public SDRFNode getNode() {
    return node;
  }
  public String getId() {
    return id;
  }
  public List<Integer> getLines() {
    return lines;
  }
  
}

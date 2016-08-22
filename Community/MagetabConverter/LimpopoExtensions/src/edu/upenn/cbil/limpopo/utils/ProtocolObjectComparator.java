package edu.upenn.cbil.limpopo.utils;

import java.util.Comparator;

import edu.upenn.cbil.limpopo.model.ProtocolObject;
import static edu.upenn.cbil.limpopo.utils.AppUtils.*;

public class ProtocolObjectComparator implements Comparator<ProtocolObject> {
  
  public int compare(ProtocolObject obj1, ProtocolObject obj2) {
    int result = 0;
    String id1 = obj1.getId().split(NODE_SEPARATOR)[0];
    String id2 = obj2.getId().split(NODE_SEPARATOR)[0];
    Integer row1 = Integer.parseInt(id1.replaceFirst("^R(\\d*)C\\d+$","$1"));
    Integer col1 = Integer.parseInt(id1.replaceFirst("^R\\d+C(\\d+)$","$1"));
    Integer row2 = Integer.parseInt(id2.replaceFirst("^R(\\d+)C\\d+$","$1"));
    Integer col2 = Integer.parseInt(id2.replaceFirst("^R\\d+C(\\d+)$","$1"));
    result = row1.compareTo(row2);  
    if(result == 0) result = col1.compareTo(col2);
    return result;
  }
}

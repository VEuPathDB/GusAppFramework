package edu.upenn.cbil.magetab.model;

import java.util.Comparator;

/**
 * Comparator for Factor Values based upon position within the original Excel spreadsheet.
 * @author crisl
 *
 */
public class FactorValueComparator implements Comparator<FactorValue> {
	
  /**
   * Factor Value comparison - insures comparison based upon row first and column second. 
   */
  @Override
  public int compare(FactorValue obj1, FactorValue obj2) {
    int result = 0;
    result = obj1.getRow().compareTo(obj2.getRow());  
    if(result == 0) result = obj1.getCol().compareTo(obj2.getCol());
    return result;
  }

}

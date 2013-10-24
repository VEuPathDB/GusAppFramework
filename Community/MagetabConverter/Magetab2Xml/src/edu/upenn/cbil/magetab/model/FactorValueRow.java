package edu.upenn.cbil.magetab.model;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import org.apache.commons.lang.StringUtils;

/**
 * Represents all the factor values contained within one row of the original Excel spreadsheet.
 * @author crisl
 *
 */
public class FactorValueRow {
  private List<FactorValue> factorValues;
  private int row;
  
  /**
   * Internal constructor intended to avoid nulls and insure defined state.
   */
  protected FactorValueRow() {
    factorValues = new ArrayList<>();
    row = -1;
  }
  
  /**
   * Public constructor loads a list of factor value for a row and identifies the row.
   * @param factorValues - array list of factor values all one the same row.
   */
  public FactorValueRow(List<FactorValue> factorValues) {
    this();
    if(factorValues != null && factorValues.size() > 0) {
      this.factorValues = factorValues;
      setRow();
    }
  }
  
  /**
   * Convenience method to determine in a particular row is devoid of factor values.
   * @return - true if no factor values exist of the row, false othewise.
   */
  public boolean isEmpty() {
    return this.factorValues.size() == 0 ? true : false;
  }
  
  /**
   * Getter for the list of factor values inhabiting a particular row.
   * @return - factor value list.
   */
  public List<FactorValue> getFactorValues() {
    return this.factorValues;
  }
  
  /**
   * Getter for the row to which this object refers
   * @return - integer row number
   */
  public int getRow() {
    return this.row;
  }
  
  /**
   * Setter for the row to which this object refers.  Obtained from the first factor value in
   * the row, assuming factor values are present.  Otherwise, the row is left at -1.
   */
  protected void setRow() {
    if(!factorValues.isEmpty()) {
      this.row = factorValues.get(0).getRow();
    }
  }
  

}

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
  private StringBuffer originalData;
  private StringBuffer addedData;
  private StringBuffer allData;
  
  /**
   * Internal constructor intended to avoid nulls and insure defined state.
   */
  protected FactorValueRow() {
    factorValues = new ArrayList<>();
    row = -1;
    originalData = new StringBuffer();
    addedData = new StringBuffer();
    allData = new StringBuffer();
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
  
  /**
   * Getter for the 'stringified' version of all the original factor values on the row.
   * @return - original data
   */
  public String getOriginalData() {
    return originalData != null ? originalData.toString() : "";
  }
  
  /**
   * Getter for the 'stringified' version of all the new factor values on the row.
   * @return - added data
   */
  public String getAddedData() {
    return addedData != null ? addedData.toString() : "";
  }
  
  /**
   * Getter for the 'stringified' version of all the factor values on the row, both new and old.
   * @return - all data
   */
  public String getAllData() {
    return allData != null ? allData.toString() : "";
  }
  
  /**
   * Helper method to condense the given factor value into a string since factor values are
   * compressed into a delimited string in the factor value xml element.
   * @param factorValue - the factor value to be 'stringified'
   * @return - the 'stringified' version of the factor value
   */
  protected String createDataString(FactorValue factorValue) {
    StringBuffer str = new StringBuffer();
    if(str.length() > 0) str.append(";");
    str.append(factorValue.getKey() + "|" + factorValue.getValue());
    if(!StringUtils.isEmpty(factorValue.getTable())) {
      str.append("|" + factorValue.getTable() + "|" + factorValue.getRowId());
    }
    return str.toString();
  }
  
  /**
   * Three distinct 'stringified' versions of a factor value row are created here.  This is
   * done post processing since it is dependent on data obtained from the idf portion of the
   * MAGE-TAB output xml.  One string represents a 'stringified' version of all the factor
   * values on this row.  One string represents a 'stringfied' version of all the new factor
   * values on this row (as determined by the new study factors, if any) and one string
   * represents a 'stringified' version of the original factor values on this row.  Factor
   * values are separated within each string via semicolons.
   * @param addedNames - names of added study factors, if any.
   */
  public void setDataStrings(Set<String> addedNames) {
    for(FactorValue factorValue : factorValues) {
      if(allData.length() > 0) allData.append(";");
      allData.append(createDataString(factorValue));
      if(!addedNames.isEmpty() && addedNames.contains(factorValue.getKey())) {
        if(addedData.length() > 0) addedData.append(";");
        addedData.append(createDataString(factorValue));
      }
      else {
        if(originalData.length() > 0) originalData.append(";");
        originalData.append(createDataString(factorValue));
      }
    }
  }

}

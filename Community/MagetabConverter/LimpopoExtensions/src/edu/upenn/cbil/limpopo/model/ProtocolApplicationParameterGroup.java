package edu.upenn.cbil.limpopo.model;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang.StringUtils;

/**
 * This class is intended to compose parameter strings in the format expected for the xml output.
 * @author crisl
 *
 */
public class ProtocolApplicationParameterGroup {
  private List<ProtocolApplicationParameter> parameters;
  private StringBuffer originalData;
  private StringBuffer addedData;
  private StringBuffer allData;
  
  /**
   * Internal constructor intended to avoid nulls and insure defined state.
   */
  protected ProtocolApplicationParameterGroup() {
    parameters = new ArrayList<>();
    originalData = new StringBuffer();
    addedData = new StringBuffer();
    allData = new StringBuffer();
  }
  
  public ProtocolApplicationParameterGroup(List<ProtocolApplicationParameter> parameters) {
    this();
    if(parameters != null && parameters.size() > 0) {
      this.parameters = parameters;
      setDataStrings();
    }
  }
  
  public final List<ProtocolApplicationParameter> getParameters() {
    return parameters;
  }

  public final String getOriginalData() {
    return originalData != null ? originalData.toString() : "";
  }

  public final void setOriginalData(StringBuffer originalData) {
    this.originalData = originalData;
  }

  public final String getAddedData() {
    return addedData != null ? addedData.toString() : "";
  }

  public final void setAddedData(StringBuffer addedData) {
    this.addedData = addedData;
  }

  public final String getAllData() {
    return allData != null ? allData.toString() : "";
  }

  public final void setAllData(StringBuffer allData) {
    this.allData = allData;
  }

  public boolean isEmpty() {
    return this.parameters.size() == 0 ? true : false;
  }
  
  protected String createDataString(ProtocolApplicationParameter parameter) {
    StringBuffer str = new StringBuffer();
    if(str.length() > 0) str.append(";");
    str.append(parameter.getName() + "|" + parameter.getValue());
    if(StringUtils.isNotEmpty(parameter.getTable()) && StringUtils.isNotEmpty(parameter.getRow())) {
      str.append("|" + parameter.getTable() + "|" + parameter.getRow());
    }
    return str.toString();
  }
  
  protected void setDataStrings() {
    for(ProtocolApplicationParameter parameter : parameters) {
      if(allData.length() > 0) allData.append(";");
      allData.append(createDataString(parameter));
      if(parameter.isAddition()) {
        if(addedData.length() > 0) addedData.append(";");
        addedData.append(createDataString(parameter));
      }
      else {
        if(originalData.length() > 0) originalData.append(";");
        originalData.append(createDataString(parameter));
      }
    }
  }

}

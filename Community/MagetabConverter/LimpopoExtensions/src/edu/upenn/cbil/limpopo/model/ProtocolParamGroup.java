package edu.upenn.cbil.limpopo.model;

import edu.upenn.cbil.limpopo.utils.AppUtils;

/**
 * The collection of parameter associated with a protocol in the IDF.  A convenience
 * method to help distinguish between the addition of an entire parameter group in a
 * protocol (cell highlighted only) and the addition of only a subset of parameters
 * within the group (cell highlighted but added parameters embedded inside <<<param>>>.
 * Needed because additions are subatomic here (viewing an Excel cell as atomic).
 * @author crisl
 *
 */
public class ProtocolParamGroup {
  private String parameterData;
  private boolean addition;
  
  /**
   * Constructor accepts the parameter string for a protocol.  Sets addition flag if
   * the cell is highlighted and there are no parameters embedded inside <<<param>>>
   * tokens.
   * @param parameterData - protocol's parameter data string
   */
  public ProtocolParamGroup(String parameterData) {
    addition = AppUtils.checkForAddition(parameterData) && !AppUtils.checkForInternalAddition(parameterData);
    setParameterData(parameterData);
  }
  
  /**
   * Returns the filtered parameter data for this parameter group.
   * @return - filtered paramter data
   */
  public final String getParameterData() {
    return parameterData;
  }
  
  /**
   * Parameter string data with any and all id/addition tokens removed.
   * @param parameterData - raw parameter data.
   */
  public final void setParameterData(String parameterData) {
    this.parameterData = AppUtils.removeTokens(parameterData);
  }
  
  /**
   * Identifies whether the entire parameter group is an addition
   * @return - true if and only if the entire group is an addition, false otherwise.
   */
  public final boolean isAddition() {
    return addition;
  }
  
}

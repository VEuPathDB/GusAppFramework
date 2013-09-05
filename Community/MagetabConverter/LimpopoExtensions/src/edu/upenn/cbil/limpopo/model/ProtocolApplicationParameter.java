package edu.upenn.cbil.limpopo.model;

import java.util.Map;

import org.apache.commons.lang.StringUtils;
import org.mged.magetab.error.ErrorItem;
import org.mged.magetab.error.ErrorItemFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.attribute.ParameterValueAttribute;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;
import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.limpopo.utils.SDRFUtils;

public class ProtocolApplicationParameter {
  private String name;
  private boolean addition;
  private String value;
  private Map<String,String> comments;
  private String table;
  private String row;
  private static final String PARAMETER_TABLE = "PV Table";
  private static final String PARAMETER_ROW = "PV Row Id";
  
  public ProtocolApplicationParameter() {
    name = "";
  }
  
  /**
   * Instantiates the parameter of a protocol application (edge).  Insures that addition
   * filter scrubs the limpopo data.
   * @param param - limpopo version of the protocol application parameter
   * @throws ConversionException - thrown if table and row comments are not both empty or filled.
   */
  public ProtocolApplicationParameter(ParameterValueAttribute param) throws ConversionException {
    setName(SDRFUtils.parseHeader(param.getAttributeType()));
    // Must check value and not name because headers are not highlighted.
    setAddition(AppUtils.checkForAddition(param.getAttributeValue()));
    setValue(param.getAttributeValue());
    setComments(param.comments);
    if(StringUtils.isNotEmpty(getComments().get(PARAMETER_TABLE)) &&
       StringUtils.isNotEmpty(getComments().get(PARAMETER_ROW))) {
      this.table = getComments().get(PARAMETER_TABLE);
      this.row = getComments().get(PARAMETER_ROW);
     }
     else if(StringUtils.isNotEmpty(getComments().get(PARAMETER_TABLE)) ||
             StringUtils.isNotEmpty(getComments().get(PARAMETER_ROW))) {
       ErrorItemFactory factory = ErrorItemFactory.getErrorItemFactory();
       String msg = "Problem Parameter = " + param.getAttributeType() + "|" + param.getAttributeValue();
       ErrorItem error = factory.generateErrorItem(msg, 7001, this.getClass());
       throw new ConversionException(true, new Exception(msg), error);
     }
    
  }
  
  /**
   * Gets filtered parameter name;
   * @return - filtered name
   */
  public final String getName() {
    return name;
  }

  /**
   * Sets parameter name, removing all id/addition tokens
   * @param type - raw name
   */
  public final void setName(String name) {
    this.name = AppUtils.removeTokens(name);
  }
  
  public final boolean isAddition() {
    return addition;
  }

  public final void setAddition(boolean addition) {
    this.addition = addition;
  }

  /**
   * Gets filtered parameter value
   * @return - filtered value
   */
  public final String getValue() {
    return value;
  }

  /**
   * Sets parameter value, removing all addition tokens
   * @param value - raw value
   */
  public final void setValue(String value) {
    this.value = AppUtils.removeTokens(value);
  }

  /**
   * Get filtered version of parameter comments
   * @return - filtered comments
   */
  public final Map<String, String> getComments() {
    return comments;
  }

  /**
   * Sets the parameter comments with addition tokens filtered out.
   * @param comments - raw comments
   */
  public final void setComments(Map<String, String> comments) {
    this.comments = AppUtils.removeTokens(comments);
  }

  /**
   * Gets the parameter value table, if any
   * @return - table string, if any.  null otherwise
   */
  public final String getTable() {
    return table;
  }

  /**
   * Gets the parameter value table row, if any
   * @return - table row string, if any.  null otherwise.
   */
  public final String getRow() {
    return row;
  }
 
}

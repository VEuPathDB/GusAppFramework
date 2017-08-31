package edu.upenn.cbil.limpopo.model;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;
import org.mged.magetab.error.ErrorItem;
import org.mged.magetab.error.ErrorItemFactory;

import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.limpopo.utils.SDRFUtils;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.attribute.ParameterValueAttribute;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.attribute.UnitAttribute;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;

public class ProtocolApplicationParameter {

  private String name;
  private String protocolName;
  private boolean addition;
  private String value;
  private Map<String,String> comments;
  private String table;
  private String row;
  private OntologyTerm unitType;
  private static List<ProtocolApplicationParameter> parameters = new ArrayList<>();
  private static final String PARAMETER_TABLE = "PV Table";
  private static final String PARAMETER_ROW = "PV Row Id";
  
  /**
   * Constructor initializes fields to protect against NPEs.
   */
  private ProtocolApplicationParameter() {
    name = "";
    protocolName = "";
    value = "";
    table = "";
    row = "";
    addition = false;
  }
  
  /**
   * Instantiates the parameter of a protocol application (edge or part of edge).  Insures that addition
   * filter scrubs the limpopo data.
   * @param protocolName - name of protocol to which the parameter belongs
   * @param param - limpopo version of the protocol application parameter
   * @param protocolAddition - boolean to indicate whether the parent protocol application is itself an addition.
   * @throws ConversionException - thrown if table and row comments are not both empty or filled (SOP 16) or if
   * this parameter matches another in protocol, name, and value but mismatch in table and row data (SOP 21).
   */
  public ProtocolApplicationParameter(String protocolName, ParameterValueAttribute param, boolean protocolAddition) throws ConversionException {
    this();
    setProtocolName(protocolName);
    setName(SDRFUtils.parseHeader(param.getAttributeType()));
    // Must check value and not name because headers are not highlighted.
    if(!protocolAddition) {
      setAddition(AppUtils.checkForAddition(param.getAttributeValue()));
    }
    setValue(param.getAttributeValue());
    UnitAttribute unitAttribute = param.unit;
    if(unitAttribute != null) {
      setUnitType(new OntologyTerm(SDRFUtils.parseHeader(unitAttribute.type), unitAttribute.getAttributeValue(), unitAttribute.termSourceREF));
    }
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
       msg += " from Protocol " + protocolName;
       ErrorItem error = factory.generateErrorItem(msg, 7001, this.getClass());
       throw new ConversionException(true, new Exception(msg), error);
     }
     for(ProtocolApplicationParameter parameter : parameters) {
       if(disjoint(parameter)) {
         ErrorItemFactory factory = ErrorItemFactory.getErrorItemFactory();
         String msg = "Problem Parameter = " + param.getAttributeType() + "|" + param.getAttributeValue();
         msg += " from Protocol " + protocolName;
         ErrorItem error = factory.generateErrorItem(msg, 7002, this.getClass());
         throw new ConversionException(true, new Exception(msg), error);
       }
     }
     parameters.add(this);
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
   * @param name - raw name
   */
  public final void setName(String name) {
    this.name = AppUtils.removeTokens(name);
  }
  
  public String getProtocolName() {
    return protocolName;
  }

  public void setProtocolName(String protocolName) {
    this.protocolName = protocolName;
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
  
  public final OntologyTerm getUnitType() {
    return unitType;
  }

  public final void setUnitType(OntologyTerm unitType) {
    this.unitType = unitType;
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
  
  public final boolean hasTableRowPair() {
    return StringUtils.isNotEmpty(getTable()) && StringUtils.isNotEmpty(getRow());
  }
  
  /**
   * List of all parameters found in the SDRF protocol applications
   * @return - list of protocol application parameter objects
   */
  public static List<ProtocolApplicationParameter> getParameters() {
    return parameters;
  }

  public boolean disjoint(Object obj) {
    boolean disjoint = false;
    if(equals(obj)) {
      ProtocolApplicationParameter that = (ProtocolApplicationParameter) obj;
      disjoint = !that.getTable().equals(getTable()) || !that.getRow().equals(getRow());
    }
    return disjoint;
  }
  
  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ProtocolApplicationParameter) {
      ProtocolApplicationParameter that = (ProtocolApplicationParameter) obj;
      boolean nodesEqual = that.getProtocolName().equals(getProtocolName()) &&
                           that.getName().equals(getName()) &&
                           that.getValue().equals(getValue());
      return nodesEqual;
    }
    else {
      return false;
    }
  }

  @Override
  public int hashCode() {
    return (ProtocolApplicationParameter.class.getName() +
        getProtocolName() + getName() + getValue()).hashCode();
  }

  @Override
  public String toString() {
    return new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE).toString();
  }
 
}

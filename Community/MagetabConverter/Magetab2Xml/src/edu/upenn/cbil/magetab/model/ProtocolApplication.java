package edu.upenn.cbil.magetab.model;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;
import org.jdom2.Element;

import edu.upenn.cbil.limpopo.utils.AppUtils;

public class ProtocolApplication {
  private Protocol protocol;
  private String performer;
  private List<String> parameters;
  private String dbId;
  private boolean addition;
  private boolean labelFlag;
  
  public ProtocolApplication() {
    addition = false;
    labelFlag = false;
  }
  
  public final Protocol getProtocol() {
    return protocol;
  }
  public final void setProtocol(Protocol protocol) {
    this.protocol = protocol;
  }
  public final String getPerformer() {
    return performer;
  }
  public final List<String> getParameters() {
    return parameters;
  }
  public final String getDbId() {
    return dbId;
  }
  public final boolean isAddition() {
    return addition;
  }
  public final boolean isLabelFlag() {
    return labelFlag;
  }
 
  public static List<ProtocolApplication> populate(Element protocolAppElement) {
    int step = 1;
    List<ProtocolApplication> applications = new ArrayList<>();
    List<String> names = Arrays.asList(protocolAppElement.getChildText(AppUtils.PROTOCOL_TAG).split("\\|\\|\\|"));
    for(String name : names) {
      ProtocolApplication application = new ProtocolApplication();
      application.setProtocol(Protocol.getProtocolByName(name));
      if(protocolAppElement.getAttribute(AppUtils.ADDITION_ATTR) != null) {
        application.addition = true;
      }
      application.dbId = protocolAppElement.getAttributeValue("db_id");
      if(application.dbId != null) {
        application.labelFlag = true;
      }
      application.setPerformer(protocolAppElement, step);
      application.setParameters(protocolAppElement, step);
      applications.add(application);
      step++;
    }
    return applications;
  }
  
  /**
   * Assemble performer for display in this protocol application's tooltip, adding the role where
   * it exists.  Surround the performer with an addition class if it is an addition.
   * @param protocolAppElement - element containing the protocol application
   * @param step - integer representing the step in a protocol application series.  A stand-alone
   * protocol application will have a step of 1 only.
   */
  protected void setPerformer(Element protocolAppElement, int step) {
    performer = "";
    List<Element> contactElements = protocolAppElement.getChildren(AppUtils.CONTACT_TAG);
    for(Element contactElement : contactElements) {
      if(Integer.toString(step).equals(contactElement.getAttributeValue(AppUtils.STEP_ATTR))) {
        performer = contactElement.getChild(AppUtils.NAME_TAG).getText();
        if(contactElement.getChild(AppUtils.ROLE_TAG) != null) {
          performer += " - " + contactElement.getChild(AppUtils.ROLE_TAG).getText();
        }
        if(contactElement.getAttribute(AppUtils.ADDITION_ATTR) != null) {
          performer = "<span class='addition'>" + performer + "</span>";
          labelFlag = true;
        }
      }
    }
  }
  
  /**
   * Assemble the parameter list for display in this protocol application's tooltip, using a
   * name = value format and appending any unit type (or default type).  Surround the protocol
   * with an addition class if it is an addition.
   * @param protocolAppElement - element containing the protocol application
   * @param step - integer representing the step in a protocol application series.  A stand-alone
   * protocol application will have a step of 1 only.
   */
  protected void setParameters(Element protocolAppElement, int step) {
    Map<String,String> parameterDefaults = this.protocol.getParameters();
    parameters = new ArrayList<>();
    List<Element> paramElements = protocolAppElement.getChildren(AppUtils.PROTOCOL_APP_PARAMETER_TAG);
    for(Element paramElement : paramElements) {
      if(Integer.toString(step).equals(paramElement.getAttributeValue(AppUtils.STEP_ATTR))) {
        String name = paramElement.getChild(AppUtils.NAME_TAG).getText();
        String parameter = name + " : " + paramElement.getChild(AppUtils.VALUE_TAG).getText();
        Element unitElement = paramElement.getChild(AppUtils.UNIT_TYPE_TAG);
        if(unitElement != null) {
          parameter += " " + unitElement.getText();
        }
        else {
          if(parameterDefaults.containsKey(name)) {
            parameter += " " + parameterDefaults.get(name);
          }
        }
        if(paramElement.getAttribute(AppUtils.ADDITION_ATTR) != null) {
          parameter = "<span class='addition'>" + parameter + "</span>";
          labelFlag = true;
        }
        parameters.add(parameter);
      }
    }
  }
  
  /**
   * Convenient string representation for debugging purposes.
   */
  @Override
  public String toString() {
    return new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE).toString();
  }
  
}

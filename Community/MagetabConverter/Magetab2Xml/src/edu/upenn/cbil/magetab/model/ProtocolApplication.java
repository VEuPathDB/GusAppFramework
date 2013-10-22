package edu.upenn.cbil.magetab.model;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;
import org.jdom2.Attribute;
import org.jdom2.Element;

import edu.upenn.cbil.limpopo.utils.AppUtils;

public class ProtocolApplication {
  private Protocol protocol;
  private List<String> performers;
  private List<String> parameters;
  private String dbId;
  private boolean addition;
  
  public final Protocol getProtocol() {
    return protocol;
  }
  public final void setProtocol(Protocol protocol) {
    this.protocol = protocol;
  }
  public final List<String> getPerformers() {
    return performers;
  }
 
  public final List<String> getParameters() {
    return parameters;
  }

  public final String getDbId() {
    return dbId;
  }
  public final void setDbId(String dbId) {
    this.dbId = dbId;
  }
  public final boolean isAddition() {
    return addition;
  }
  public final void setAddition(boolean addition) {
    this.addition = addition;
  }
  
  public static List<ProtocolApplication> populate(Element protocolAppElement) {
    int step = 1;
    List<ProtocolApplication> applications = new ArrayList<>();
    List<String> names = Arrays.asList(protocolAppElement.getChildText(AppUtils.PROTOCOL_TAG).split(";"));
    for(String name : names) {
      ProtocolApplication application = new ProtocolApplication();
      application.setProtocol(Protocol.getProtocolByName(name));
      Attribute addAttr = protocolAppElement.getAttribute("addition");
      if(addAttr != null) {
        application.setAddition(Boolean.parseBoolean(addAttr.getValue()));
      }
      application.setDbId(protocolAppElement.getAttributeValue("db_id"));
      application.setPerformers(protocolAppElement, step);
      application.setParameters(protocolAppElement, step);
      applications.add(application);
      step++;
    }
    return applications;
  }
  
  protected void setPerformers(Element protocolAppElement, int step) {
    performers = new ArrayList<>();
    Element contactsElement = protocolAppElement.getChild(AppUtils.CONTACTS_TAG);
    if(contactsElement != null && !contactsElement.getChildren().isEmpty()) {
      List<Element> contactElements = contactsElement.getChildren();
      for(Element contactElement : contactElements) {
        if(Integer.toString(step).equals(contactElement.getAttributeValue(AppUtils.STEP_ATTR))) {
          String performer = contactElement.getChild(AppUtils.NAME_TAG).getText();
          if(contactElement.getChild(AppUtils.ROLE_TAG) != null) {
            performer += " - " + contactElement.getChild(AppUtils.ROLE_TAG).getText();
          }
          performers.add(performer);
        }
      }
    }
  }
  
  protected void setParameters(Element protocolAppElement, int step) {
    Map<String,String> parameterDefaults = this.protocol.getParameters();
    parameters = new ArrayList<>();
    Element paramsElement = protocolAppElement.getChild(AppUtils.PROTOCOL_APP_PARAMETERS_TAG);
    if(paramsElement != null && !paramsElement.getChildren().isEmpty()) {
      List<Element> paramElements = paramsElement.getChildren();
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
          parameters.add(parameter);
        }
      }
    }
  }
  
  /**
   * Convenient string representation for debugging purposes.
   */
  @Override
  public String toString() {
    return (new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE) {
      protected boolean accept(Field field) {
        return super.accept(field);
      }
    }).toString();
  }
  
}

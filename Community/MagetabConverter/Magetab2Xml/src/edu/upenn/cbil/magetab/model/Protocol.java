package edu.upenn.cbil.magetab.model;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.jdom2.Document;
import org.jdom2.Element;

import edu.upenn.cbil.limpopo.utils.AppUtils;

public class Protocol {
  private String name;
  private String description;
  private Map<String, String> parameters;
  private static List<Protocol> protocols;
  
  public Protocol() {
    protocols = new ArrayList<>();
  }
  
  public final String getName() {
    return name;
  }
  
  public final void setName(String name) {
    this.name = name;
  }
  
  public final String getDescription() {
    return description;
  }
  
  public final void setDescription(String description) {
    this.description = description;
  }

  public final Map<String, String> getParameters() {
    return parameters;
  }

  public static final List<Protocol> getProtocols() {
    return protocols;
  }
  public static final void setProtocols(List<Protocol> protocols) {
    Protocol.protocols = protocols;
  }
  
  public static void populateProtocolData(Document document) {
    List<Protocol> newProtocols = new ArrayList<>();
    List<Element> protocolElements = document.getRootElement().getChild(AppUtils.IDF_TAG).getChildren(AppUtils.PROTOCOL_TAG);
    for(Element protocolElement : protocolElements) {
      Protocol protocol = new Protocol();
      protocol.setName(protocolElement.getChildText(AppUtils.NAME_TAG));
      protocol.setDescription(protocolElement.getChildText(AppUtils.DESCRIPTION_TAG));
      protocol.setParameters(protocolElement);
      newProtocols.add(protocol);
    }
    Protocol.setProtocols(newProtocols);
  }
  
  protected void setParameters(Element protocolElement) {
    parameters = new HashMap<>();
    Element parametersElement = protocolElement.getChild(AppUtils.PROTOCOL_PARAMETERS_TAG);
    if(parametersElement != null) {
      List<Element> parameterElements = parametersElement.getChildren(AppUtils.PARAM_TAG);
      for(Element parameterElement : parameterElements) {
        if(parameterElement.getChild(AppUtils.UNIT_TYPE_TAG) != null) {
          String key = parameterElement.getChildText(AppUtils.NAME_TAG);
          String value = parameterElement.getChildText(AppUtils.UNIT_TYPE_TAG);
          parameters.put(key, value);
        }
      }
    }
  }
  
  public static Protocol getProtocolByName(String name) {
    for(Protocol protocol : Protocol.getProtocols()) {
      if(name.equalsIgnoreCase(protocol.getName())) {
        return protocol;
      }
    }
    return null;
  }
  
}

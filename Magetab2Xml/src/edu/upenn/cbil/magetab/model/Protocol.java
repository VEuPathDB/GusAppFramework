package edu.upenn.cbil.magetab.model;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang.WordUtils;
import org.jdom2.Document;
import org.jdom2.Element;

import edu.upenn.cbil.limpopo.utils.AppUtils;

public class Protocol {
  private String name;
  private String description;
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
    //return WordUtils.wrap(description, 45, "<br />", true);
    return description;
  }
  public final void setDescription(String description) {
    this.description = description;
  }
  public static final List<Protocol> getProtocols() {
    return protocols;
  }
  public static final void setProtocols(List<Protocol> protocols) {
    Protocol.protocols = protocols;
  }
  
  public static void populateProtocolData(Document document) {
    List<Protocol> protocols = new ArrayList<>();
    List<Element> protocolElements = document.getRootElement().getChild(AppUtils.IDF_TAG).getChildren(AppUtils.PROTOCOL_TAG);
    for(Element protocolElement : protocolElements) {
      Protocol protocol = new Protocol();
      protocol.setName(protocolElement.getChildText(AppUtils.NAME_TAG));
      protocol.setDescription(protocolElement.getChildText(AppUtils.DESCRIPTION_TAG));
      protocols.add(protocol);
    }
    Protocol.setProtocols(protocols);
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

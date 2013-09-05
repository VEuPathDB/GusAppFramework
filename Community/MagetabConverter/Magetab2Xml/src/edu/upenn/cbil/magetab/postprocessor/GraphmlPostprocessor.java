package edu.upenn.cbil.magetab.postprocessor;

import java.io.FileOutputStream;
import java.io.IOException;
import java.util.List;

import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.output.Format;
import org.jdom2.output.XMLOutputter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.upenn.cbil.magetab.utilities.ApplicationException;

public class GraphmlPostprocessor {
  public static Logger logger = LoggerFactory.getLogger(GraphmlPostprocessor.class);
  private String filename;
  
  public GraphmlPostprocessor(String filename) {
    this.filename = filename;
  }
  
  public void create(Document xmlDocument) {
    logger.debug("START - " + getClass().getSimpleName());
    FileOutputStream graphml = null;
    try {
      graphml = new FileOutputStream(filename);
      Document graphmlDoc = process(xmlDocument);
      XMLOutputter xmlOutput = new XMLOutputter();
      xmlOutput.setFormat(Format.getPrettyFormat().setExpandEmptyElements(false));
      xmlOutput.output(graphmlDoc, graphml);
    }
    catch(IOException ioe) {
      throw new ApplicationException(ioe.getMessage());
    }
    logger.debug("END - " + getClass().getSimpleName());
  }
  
  protected Document process(Document xmlDocument) {
    Document graphmlDocument = new Document();
    Element graphml = new Element("graphml");
    graphmlDocument.setRootElement(graphml);
    Element graph = new Element("graph");
    graph.setAttribute("id", "G");
    graph.setAttribute("edgedefault", "directed");
    List<Element> protocolAppNodes = xmlDocument.getRootElement().getChildren("sdrf").get(0).getChildren("protocol_app_node");
    for(Element protocolAppNode : protocolAppNodes) {
      String id = protocolAppNode.getAttributeValue("id");
      String[] idList = id.split(";");
      for(String newId : idList) {
        Element node = new Element("node");
        node.setAttribute("id",newId);
        graph.addContent(node);
      }
    }
    List<Element> protocolApps = xmlDocument.getRootElement().getChildren("sdrf").get(0).getChildren("protocol_app");
    for(Element protocolApp : protocolApps) {
      String[] inputs = protocolApp.getChildren("inputs").get(0).getText().split(";");
      String[] outputs = protocolApp.getChildren("outputs").get(0).getText().split(";");
      for(int i = 0; i < inputs.length; i++) {
        for(int j = 0; j < outputs.length; j++) {
          Element edge = new Element("edge");
          edge.setAttribute("source", inputs[i]);
          edge.setAttribute("target", outputs[j]);
          graph.addContent(edge);
        }
      }
    }
    graphml.addContent(graph);
    return graphmlDocument;
  }
}

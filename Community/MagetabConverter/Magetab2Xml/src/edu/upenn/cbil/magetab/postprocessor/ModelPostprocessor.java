package edu.upenn.cbil.magetab.postprocessor;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;
import org.jdom2.Document;
import org.jdom2.Element;

import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.magetab.model.Edge;
import edu.upenn.cbil.magetab.model.Node;
import edu.upenn.cbil.magetab.model.Protocol;
import edu.upenn.cbil.magetab.model.ProtocolApplication;
import edu.upenn.cbil.magetab.model.Study;

/**
 * Postprocessor that accepts an XML document and converts it into an object graph composed of
 * a Study object and all related Node and Edge objects.  This object graph can be more easily
 * parsed to produce a biomaterials graph.
 * @author Cris Lawrence
 *
 */
public class ModelPostprocessor {
  private Document document;
  public static Logger logger = Logger.getLogger(ModelPostprocessor.class);
  
  /**
   * Constructor the accepts the JDOM2 xml document
   * @param document - JDOM2 xml document
   */
  public ModelPostprocessor(Document document) {
    this.document = document;
  }
  
  /**
   * Creates and returns the complete study object based on the provided xml document.
   * @return - Study object
   */
  public Study process() {
    Study study = new Study();
    Element studyElement = document.getRootElement().getChild(AppUtils.IDF_TAG).getChild(AppUtils.STUDY_TAG);
    study.setStudyName(studyElement.getChildText(AppUtils.NAME_TAG));
    study.setDbId(studyElement.getAttributeValue(AppUtils.DBID_ATTR));
    Protocol.populateProtocolData(document);
    List<Element> protocolAppNodes = document.getRootElement().getChild(AppUtils.SDRF_TAG).getChildren(AppUtils.PROTOCOL_APP_NODE_TAG);
    study.setNodes(populateNodeData(protocolAppNodes));
    List<Element> protocolApps = document.getRootElement().getChild(AppUtils.SDRF_TAG).getChildren(AppUtils.PROTOCOL_APP_TAG);
    study.setEdges(populateEdgeData(protocolApps));
    return study;
  }

  /**
   * Creates a list of nodes associated with the subject study object.  Each node is populated
   * with data needed for the biomaterials graph.
   * @param protocolAppNodes - The list of JDOM2 elements representing protocol application nodes
   * in the xml document.
   * @return - List of nodes
   */
  protected List<Node> populateNodeData(List<Element> protocolAppNodes) {
    List<Node> nodes = new ArrayList<>();
    for(Element protocolAppNode : protocolAppNodes) {
      Node node = new Node();
      node.setId(protocolAppNode.getAttributeValue(AppUtils.ID_ATTR));
      String add = protocolAppNode.getAttributeValue(AppUtils.ADDITION_ATTR);
      if(add != null) {
        node.setAddition(Boolean.parseBoolean(add.trim()));
      }
      node.setDbId(protocolAppNode.getAttributeValue(AppUtils.DBID_ATTR));
      node.setLabel(protocolAppNode.getChildText(AppUtils.NAME_TAG));
      node.setType(protocolAppNode.getChildText(AppUtils.TYPE_TAG));
      node.setTaxon(protocolAppNode.getChildText(AppUtils.TAXON_TAG));
      node.setUri(protocolAppNode.getChildText(AppUtils.URI_TAG));
      List<Element> charElements = protocolAppNode.getChildren(AppUtils.CHARACTERISTIC_TAG);
      List<String> characteristics = new ArrayList<>();
      for(Element charElement : charElements) {
        String value = charElement.getChildText(AppUtils.VALUE_TAG);
        // If a value is present, either the ontology term corresponds to a unit type
        // or there is no ontology term.
        if(StringUtils.isNotEmpty(value)) {
      	  // If a category contains a pipe, the value corresponds to a number having a 
          // unit and the ontology term, which should exist, corresponds to a the unit
          // type.  As such the two are concatenated.
          String category = charElement.getChild(AppUtils.VALUE_TAG).getAttributeValue(AppUtils.CATEGORY_ATTR);
          if(StringUtils.isNotEmpty(category) && category.contains("|")) {
        	String term = charElement.getChildText(AppUtils.ONTOLOGY_TERM_TAG);
            if(StringUtils.isNotEmpty(term)) {
              value += " " + term;
            }
          }
          characteristics.add(value);
        }
        else {
          String term = charElement.getChildText(AppUtils.ONTOLOGY_TERM_TAG);
          if(StringUtils.isNotEmpty(term)) {
            characteristics.add(term);
          }
        }
        characteristics = characteristics.isEmpty() ? null : characteristics; 
        node.setCharacteristics(characteristics);
      }
      nodes.add(node);
    }
    return nodes;
  }
  
  /**
   * Creates a list of edges associated with the subject study object.  Each edge is populated
   * with data needed for the biomaterials graph.
   * @param protocolApps - The list of JDOM2 elements representing protocol edges in the xml
   * document.
   * @return - List of edges
   */
  protected List<Edge> populateEdgeData(List<Element> protocolAppElements) {
    List<Edge> edges = new ArrayList<>();
    for(Element protocolAppElement : protocolAppElements) {
      List<ProtocolApplication> applications = ProtocolApplication.populate(protocolAppElement);
      String[] inputs = protocolAppElement.getChildText(AppUtils.INPUTS_TAG).split(";");
      String[] outputs = protocolAppElement.getChildText(AppUtils.OUTPUTS_TAG).split(";");
      for(String input : inputs) {
        for(String output : outputs) {
          Edge edge = new Edge();
          edge.setLabel(protocolAppElement.getChildText(AppUtils.PROTOCOL_TAG));
          edge.setApplications(applications);
          edge.setFromNode(input);
          edge.setToNode(output);
          edges.add(edge);
        }
      }
    }
    return edges;
  }
  
}

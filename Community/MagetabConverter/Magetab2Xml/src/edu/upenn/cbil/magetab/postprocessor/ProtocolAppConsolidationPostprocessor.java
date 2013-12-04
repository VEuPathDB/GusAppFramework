package edu.upenn.cbil.magetab.postprocessor;

import static edu.upenn.cbil.limpopo.utils.AppUtils.INPUT_TAG;

import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;
import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.output.XMLOutputter;

import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.Multimap;

import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.magetab.utilities.ApplicationException;

public class ProtocolAppConsolidationPostprocessor {
  private Document document;
  public static Logger logger = Logger.getLogger(ProtocolAppConsolidationPostprocessor.class);
  
  public ProtocolAppConsolidationPostprocessor(Document document) {
    this.document = document;
  }
  
  public Document process() {
    Element SDRFElement = document.getRootElement().getChild(AppUtils.SDRF_TAG);
    List<Element> protocolApps = SDRFElement.getChildren(AppUtils.PROTOCOL_APP_TAG);
    Multimap<String,Element> map = partitionByRunNumber(protocolApps);
    Iterator<String> iterator = map.keySet().iterator();
    while(iterator.hasNext()) {
      String runNumber = iterator.next();
      Collection<Element> elements = map.get(runNumber);
      Element prototypeElement = null;
      int prototypeHash = 0;
      Set<String> inputs = new HashSet<>();
      Set<String> outputs = new HashSet<>();
      for(Element element : elements) {
        inputs.add(element.getChildText(AppUtils.INPUT_TAG));
        outputs.add(element.getChildText(AppUtils.OUTPUT_TAG));
        System.out.println("Inside group:" + runNumber + " - # of elements in group is " + elements.size());
        if(prototypeElement == null) {
          prototypeElement = element.clone();
          prototypeHash = createHash(prototypeElement);
          prototypeElement.removeChild(AppUtils.INPUT_TAG);
          prototypeElement.removeChild(AppUtils.OUTPUT_TAG);
        }
        else {
          System.out.println("Prototype hash is " + prototypeHash);
          System.out.println("Element hash is " + createHash(element));
          if(prototypeHash != createHash(element)) {
            throw new ApplicationException("The protocols for location = " + prototypeElement.getAttributeValue(AppUtils.ID_ATTR) + " and location = " + element.getAttributeValue(AppUtils.ID_ATTR) + " cannot be grouped together.  Please corrent the run numbers");
          }
        }
        SDRFElement.removeContent(element);
      }
      for(String input : inputs) {
        prototypeElement.addContent(new Element(AppUtils.INPUT_TAG).setText(input));
      }
      for(String output : outputs) {
        prototypeElement.addContent(new Element(AppUtils.OUTPUT_TAG).setText(output));
      }
      SDRFElement.addContent(prototypeElement);
    }
    return document;
  }

  protected Multimap<String,Element> partitionByRunNumber(List<Element> elements) {
    Multimap<String,Element> map = ArrayListMultimap.create(); 
    for(Element element : elements) {
      String runNumber = element.getAttributeValue(AppUtils.RUN_ATTR);
      if(StringUtils.isNotEmpty(runNumber)) {
        map.put(runNumber, element);
      }
    }
    return map;
  }
  
  protected final int createHash(Element protocolAppElement) {
    Element element = protocolAppElement.clone();
    element.removeAttribute(AppUtils.ID_ATTR);
    element.removeAttribute(AppUtils.DBID_ATTR);
    element.removeAttribute(AppUtils.RUN_ATTR);
    element.removeAttribute(AppUtils.ADDITION_ATTR);
    element.removeChild(AppUtils.INPUT_TAG);
    element.removeChild(AppUtils.OUTPUT_TAG);
    Document document = new Document();
    document.addContent(element);
    XMLOutputter xmlOut = new XMLOutputter();
    return xmlOut.outputString(document).hashCode();
  }

}

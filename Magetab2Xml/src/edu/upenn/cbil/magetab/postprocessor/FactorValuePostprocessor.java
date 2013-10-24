package edu.upenn.cbil.magetab.postprocessor;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import org.jdom2.Document;
import org.jdom2.Element;


import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.magetab.model.FactorValue;
import edu.upenn.cbil.magetab.model.FactorValueRow;
import edu.upenn.cbil.magetab.model.StudyFactor;
import edu.upenn.cbil.magetab.preprocessors.FactorValuePreprocessor;

public class FactorValuePostprocessor {

  public Document process(Document document) {
    if(FactorValuePreprocessor.factorValueMap != null && !FactorValuePreprocessor.factorValueMap.isEmpty()) {
      StudyFactor.populate(document);
      List<Element> nodes = document.getRootElement().getChildren(AppUtils.SDRF_TAG).get(0).getChildren(AppUtils.PROTOCOL_APP_NODE_TAG);
      for(Element node : nodes) {
        String id = node.getAttribute("id").getValue();
        List<Integer> rows = getRows(id);
        Set<FactorValue> factorValues = removeDuplicates(rows);
        boolean isNodeAddition = node.getAttribute(AppUtils.ADDITION_ATTR) != null;
        Element factorValuesElement = new Element(AppUtils.FACTOR_VALUES_TAG);
        for(FactorValue factorValue : factorValues) {
          factorValue.setAddition();
          factorValuesElement.addContent(setFactorValue(factorValue, isNodeAddition));
        }
        node.addContent(factorValuesElement);
      }
    }
    return document;
  }
  
  

  /**
   * Removes duplicate factor values before affixing factor values to a protocol application
   * node.  Duplicates are the result of the way factor values are pre-processed and occur when
   * splits and merges are present in the sdrf.  The same factor value may be on two physical rows of
   * the sdrf, but for splits and merges some of those rows coalesce into a single protocol application
   * node.  So a factor value may be applied multiple times for one node.  The easiest way to correct
   * this problem is to simply create a build a factor value set using the rows ascribed to the
   * parent protocol application node.  This depends on good hashCode and equals override for the
   * factor value class.
   * @param rows - a list of physical rows belonging to a protocol application node
   * @return - the factor values set.
   */
  protected Set<FactorValue> removeDuplicates(List<Integer> rows) {
    Set<FactorValue> factorValues = new LinkedHashSet<>();
    for(Integer row : rows) {
      if(FactorValuePreprocessor.factorValueMap.containsKey(row)) {
        FactorValueRow factorValueRow = FactorValuePreprocessor.factorValueMap.get(row);
        for(FactorValue factorValue : factorValueRow.getFactorValues()) {
          factorValues.add(factorValue);
        }
      }
    }
    return factorValues;
  }
  
  protected List<Integer> getRows(String id) {
    List<Integer> rows = new ArrayList<>();
	String[] locs = id.split(AppUtils.NODE_SEPARATOR);
	for(String loc : locs) {
	  rows.add(Integer.parseInt(loc.replaceFirst("^R(.*)C.*$", "$1")));
	}
	return rows;
  }
  
  /**
   * Builds each individual factor value to apply to the factor values element of the protocol
   * application node portion of the XML.  Since it is not known a priori whether a factor value
   * is an addition or simply part of an additional protocol application node, the status of
   * the parent protocol application node is provided and used to determine whether or not to set
   * the addition attribute for the factor value element.
   * @param factorValue - the factor value object to be turned into an element
   * @param nodeAddition - a boolean flag indicating whether or not the parent node is an addition.
   * @return - a factor value element
   */
  protected Element setFactorValue(FactorValue factorValue, boolean nodeAddition) {
    Element factorValueElement = new Element(AppUtils.FACTOR_VALUE_TAG);
    if(!nodeAddition && factorValue.isAddition()) {
      factorValueElement.setAttribute(AppUtils.ADDITION_ATTR, AppUtils.TRUE);
    }
    factorValueElement.addContent(new Element(AppUtils.NAME_TAG).setText(factorValue.getName()));
    factorValueElement.addContent(new Element(AppUtils.VALUE_TAG).setText(factorValue.getValue()));
    if(factorValue.hasTableRowPair()) {
      factorValueElement.addContent(new Element(AppUtils.TABLE_TAG).setText(factorValue.getTable()));
      factorValueElement.addContent(new Element(AppUtils.ROW_TAG).setText(factorValue.getRowId()));
    }
    return factorValueElement;
  }
}

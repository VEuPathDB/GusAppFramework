package edu.upenn.cbil.magetab.postprocessor;


import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.NODE_SEPARATOR;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.jdom2.Document;
import org.jdom2.Element;

import com.google.common.base.Joiner;

import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.magetab.model.FactorValue;
import edu.upenn.cbil.magetab.model.FactorValueRow;
import edu.upenn.cbil.magetab.model.StudyFactor;
import edu.upenn.cbil.magetab.preprocessors.FactorValuePreprocessor;
import edu.upenn.cbil.magetab.utilities.ApplicationException;

public class FactorValuePostprocessor {
  private List<StudyFactor> studyFactors;

  public Document process(Document document) {
    if(FactorValuePreprocessor.factorValueMap != null && !FactorValuePreprocessor.factorValueMap.isEmpty()) {
      extractStudyFactors(document);
      verifyFactorValueNames();
      populateFactorValueDataStrings();
      List<Element> protocolAppNodes = document.getRootElement().getChildren("sdrf").get(0).getChildren("protocol_app_node");
      for(Element node : protocolAppNodes) {
        String id = node.getAttribute("id").getValue();
        if(node.getAttribute("addition") != null) {
          List<Integer> rows = getRows(id);
          Element factorValueElement = new Element("factor_values");
          StringBuffer allElementText = new StringBuffer();
          for(Integer row : rows) {
            if(FactorValuePreprocessor.factorValueMap.containsKey(row)) {
              FactorValueRow factorValueRow = FactorValuePreprocessor.factorValueMap.get(row);
              if(allElementText.length() > 0) {
                allElementText.append(";");
              }
              allElementText.append(factorValueRow.getAllData());
            } 
          }
          if(allElementText.length() > 0) {
            factorValueElement.setText(removeDuplicates(allElementText.toString()));
            node.addContent(factorValueElement);
          }
        }
        else {
          List<Integer> rows = getRows(id);
          Element factorValueElement = new Element("factor_values");
          Element addedFactorValueElement = new Element("factor_values");
          addedFactorValueElement.setAttribute(AppUtils.ADDITION_ATTR, "true");
          StringBuffer originalElementText = new StringBuffer();
          for(Integer row : rows) {
            if(FactorValuePreprocessor.factorValueMap.containsKey(row)) {
              FactorValueRow factorValueRow = FactorValuePreprocessor.factorValueMap.get(row);
              if(originalElementText.length() > 0) {
                originalElementText.append(";");
              }
              originalElementText.append(factorValueRow.getOriginalData());
            } 
          }
          StringBuffer addedElementText = new StringBuffer();
          for(Integer row : rows) {
            if(FactorValuePreprocessor.factorValueMap.containsKey(row)) {
              FactorValueRow factorValueRow = FactorValuePreprocessor.factorValueMap.get(row);
              if(addedElementText.length() > 0) {
                addedElementText.append(";");
              }
              addedElementText.append(factorValueRow.getAddedData());
            } 
          }
       
          if(addedElementText.length() > 0) {
            addedFactorValueElement.setText(removeDuplicates(addedElementText.toString()));
            node.addContent(addedFactorValueElement);
          }
          if(originalElementText.length() > 0) {
            factorValueElement.setText(removeDuplicates(originalElementText.toString()));
            node.addContent(factorValueElement);
          }
        }
      }
    }
    return document;
  }
  
  protected void extractStudyFactors(Document document) {
	studyFactors = new ArrayList<>();
    List<Element> studyFactorElements = document.getRootElement().getChildren("idf").get(0).getChildren("study_factor");
    for(Element studyFactorElement : studyFactorElements) {
      boolean addition = false;
      if(studyFactorElement.getAttributeValue("addition") != null) {
        addition = true;
      }
      StudyFactor studyFactor = new StudyFactor(studyFactorElement.getChildText("name"),addition);
      studyFactors.add(studyFactor);
    }
  }

  protected void populateFactorValueDataStrings() {
    if(!FactorValuePreprocessor.factorValueMap.isEmpty()) {
      Iterator<Integer> iterator = FactorValuePreprocessor.factorValueMap.keySet().iterator();
      while(iterator.hasNext()) {
        FactorValueRow factorValueRow = FactorValuePreprocessor.factorValueMap.get(iterator.next());
        factorValueRow.setDataStrings(StudyFactor.getAddedNames());
      }
    }
  }
  
  /**
   * Removes duplicate factor values before affixing the factor value text to the protocol application
   * node.  Duplicates are the result of the way factor values are pre-processed and occur when
   * splits and merges are present in the sdrf.  The same factor value may be on two physical rows of
   * the sdrf, but for splits and merges some of those rows coalesce into a single protocol application
   * node.  So a factor value may be applied multiple times for one node.  The easiest way to correct
   * this problem is to simply remove the duplicates once the factor value string is fully 
   * assembled
   * @param str - the original factor value string for a protocol application node
   * @return - the factor values string with duplicates removed.
   */
  protected String removeDuplicates(String str) {
    Set<String> values = new HashSet<>();
    values.addAll(Arrays.asList(str.split(";")));
    Joiner joiner = Joiner.on(";").skipNulls();
    return joiner.join(values);
  }
  
  protected List<Integer> getRows(String id) {
    List<Integer> rows = new ArrayList<>();
	String[] locs = id.split(NODE_SEPARATOR);
	for(String loc : locs) {
	  rows.add(Integer.parseInt(loc.replaceFirst("^R(.*)C.*$", "$1")));
	}
	return rows;
  }
  
  protected void verifyFactorValueNames() {
    if(!FactorValuePreprocessor.factorValueMap.isEmpty()) {
      Iterator<Integer> iterator = FactorValuePreprocessor.factorValueMap.keySet().iterator();
      while(iterator.hasNext()) {
        FactorValueRow factorValueRow = FactorValuePreprocessor.factorValueMap.get(iterator.next());
        List<FactorValue> factorValues = factorValueRow.getFactorValues();
        for(FactorValue factorValue : factorValues) {
          if(!StudyFactor.getNames().contains(factorValue.getKey())) {
            throw new ApplicationException("Factor Value " + factorValue.getKey() + " has no corresponding entry in the IDF study factors.");
          }
        }
      }
    }
  }
  
}

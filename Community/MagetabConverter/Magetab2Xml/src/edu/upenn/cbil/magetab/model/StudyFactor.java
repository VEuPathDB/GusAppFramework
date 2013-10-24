package edu.upenn.cbil.magetab.model;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;
import org.jdom2.Document;
import org.jdom2.Element;

import edu.upenn.cbil.limpopo.utils.AppUtils;

public class StudyFactor {
  private String name;
  private boolean addition;
  private static Set<String> names = new HashSet<>();
  private static Set<String> addedNames = new HashSet<>();
  private static List<StudyFactor> studyFactors = new ArrayList<>();
  
  public StudyFactor(String name, boolean addition) {
    this.name = name;
    names.add(name);
    this.addition = addition;
    if(addition) {
      addedNames.add(name);
    }
  }
  
  public String getName() {
	return name;
  }
  
  public boolean isAddition() {
	return addition;
  }
  
  public static Set<String> getNames() {
    return names;
  }
  
  public static Set<String> getAddedNames() {
    return addedNames;
  }
  
  public static void populate(Document document) {
    List<Element> studyFactorElements = document.getRootElement().getChildren(AppUtils.IDF_TAG).get(0).getChildren(AppUtils.STUDY_FACTOR_TAG);
    for(Element studyFactorElement : studyFactorElements) {
      boolean addition = false;
      if(studyFactorElement.getAttributeValue(AppUtils.ADDITION_ATTR) != null) {
        addition = true;
      }
      StudyFactor studyFactor = new StudyFactor(studyFactorElement.getChildText(AppUtils.NAME_TAG),addition);
      studyFactors.add(studyFactor);
    }
  }
  
  public static StudyFactor getStudyFactorByName(String name) {
    for(StudyFactor studyFactor : studyFactors) {
      System.out.println(studyFactor.getName());
      if(name.equals(studyFactor.getName())) {
        return studyFactor;
      }
    }
    return null;
  }
  
  public String toString() {
    return (new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE) {
      protected boolean accept(Field field) {
        return super.accept(field);
      }
    }).toString();
  }
}

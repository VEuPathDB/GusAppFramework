package edu.upenn.cbil.limpopo.model;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;
import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.limpopo.utils.ListUtils;

public class StudyFactor {
  public static Logger logger = LoggerFactory.getLogger(StudyFactor.class);
  private String name;
  private boolean addition;
  private OntologyTerm type;
  
  public StudyFactor() {
  }
  
  public StudyFactor(String name) {
    this.name = name;
  }
  
  public void setName(String name) {
    this.name = AppUtils.removeTokens(name);
  }
  
  public String getName() {
    return name;
  }
  
  public boolean isAddition() {
    return addition;
  }

  public void setAddition(boolean addition) {
    this.addition = addition;
  }

  public OntologyTerm getType() {
    return type;
  }
  public void setType(OntologyTerm type) {
    this.type = type;
  }
  
  @Override
  public String toString() {
    return ReflectionToStringBuilder.toString(this);
  }
  
  public static List<StudyFactor> populate(IDF data) throws ConversionException {
	logger.debug("START: Populating Study Factors");
	List<StudyFactor> studyFactors = new ArrayList<>();
    Iterator<String> iterator = data.experimentalFactorName.iterator();
    int i = 0;
    while(iterator.hasNext()) {
      StudyFactor studyFactor = new StudyFactor();
      String name = iterator.next();
      studyFactor.setName(name);
      studyFactor.setAddition(AppUtils.checkForAddition(name));
      studyFactor.setType(new OntologyTerm(ListUtils.get(data.experimentalFactorType, i), ListUtils.get(data.experimentalFactorTermSourceREF, i)));  
      studyFactors.add(studyFactor);
      i++;
    }
    logger.debug("END: Populating Study Factors");
    return studyFactors;
  }
  
}

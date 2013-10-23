package edu.upenn.cbil.limpopo.model;

import java.util.List;

import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.upenn.cbil.limpopo.utils.AppUtils;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;

/**
 * Represents the basic components of an IDF Study.  Some components are part of a standard IDF while other components are drawn from
 * comments.  This class is intended as a convenience class to be used when converting a MAGE-TAB into another format.
 * @author Cris Lawrence
 *
 */
public class Study {
  public static Logger logger = LoggerFactory.getLogger(Study.class);
  private String name;
  private String dbId;
  private String description;
  private List<String> pubmedIds;
  private OntologyTerm sourceId;
  private String goal;
  private String approaches;
  private String results;
  private String conclusions;
  private List<String> relatedStudies;
  private List<String> childStudies;
  private static final String GOAL_COMMENT = "Study Goal";
  private static final String APPROACHES_COMMENT = "Study Approaches";
  private static final String RESULTS_COMMENT = "Study Results";
  private static final String CONCLUSIONS_COMMENT = "Study Conclusions";
  
  /**
   * Study constructor.  The study is assumed not to already exist in the database to start with.
   */
  public Study() {
    this.dbId = "";
  }

  /**
   * For use in performing conversions.
   * @return - name: investigation title from IDF
   */
  public final String getName() {
    return name;
  }
  
  /**
   * Investigation Title.  For use in populated the study object.  Any id token is filtered out.
   * @param name - raw investigation title
   */
  public final void setName(String name) {
    this.name = AppUtils.removeTokens(name);
  }

  /**
   * Indicates a study to which additions have been made
   * @return - database id of existing study
   */
  public final String getDbId() {
    return dbId;
  }
  
  /**
   * Database Id of an existing study.
   * @param dbId - id of existing study or -1 if the study does not already exist in the database.
   */
  public final void setDbId(String dbId) {
    this.dbId = dbId;
  }

  /**
   * Experiment Description header.  For use in performing conversions.
   * @return - description: optional experiment description from IDF (may return an empty string)
   */
  public final String getDescription() {
    return description;
  }

  /**
   * Experiment Description header.  For use in populating the study object.
   * @param description - optional investigation description from IDF
   */
  public final void setDescription(String description) {
    this.description = AppUtils.removeTokens(description);
  }

  /**
   * PubMed ID header.  For use in performing conversions.
   * @return - pubmedIds: an optional list of pubmed ids associated with this study (may return an empty list)
   */
  public final List<String> getPubmedIds() {
    return pubmedIds;
  }

  /**
   * PubMed ID header.  For use in populating the study object.
   * @param pubmedIds - optional list of pubmed ids associated with this study
   */
  public final void setPubmedIds(List<String> pubmedIds) {
    this.pubmedIds = pubmedIds;
  }

  /**
   * Ontology term for Investigation Accession/Investigation Accession Term Source REF headers.  For use in performing conversions.
   * @return - sourceId - an optional ontology term for accession associated with this study (may return an empty ontology term)
   */
  public final OntologyTerm getSourceId() {
    return sourceId;
  }

  /**
   * Ontology term for Investigation Accession/Investigation Accession Term Source REF headers.  For use in populating the study object.
   * @param sourceId - an optional ontology term for accession associated with this study
   */
  public final void setSourceId(final OntologyTerm sourceId) {
    this.sourceId = sourceId;
  }

  /**
   * Comment [Study Goal] header.  For use in performing conversions.
   * @return - goal - an optional study goal (may return an empty string)
   */
  public final String getGoal() {
    return goal;
  }

  /**
   * Comment [Study Goal] header.  For use in populating the study object.
   * @param goal - an optional study goal
   */
  public final void setGoal(final String goal) {
    this.goal = AppUtils.removeTokens(goal);
  }

  /**
   * Comment [Study Approaches] header.  For use in performing conversions.
   * @return - approaches: an optional string detailing study approaches (may return an empty string)
   */
  public final String getApproaches() {
    return approaches;
  }

  /**
   * Comment [Study Approaches] header.  For use in populating the study object.
   * @param approaches - an optional string detailing study approaches.
   */
  public final void setApproaches(final String approaches) {
    this.approaches = AppUtils.removeTokens(approaches);
  }

  /**
   * Comment [Study Results] header.  For use in performing conversions.
   * @return - results: an optional string detailing study results (may return an empty string)
   */
  public final String getResults() {
    return results;
  }

  /**
   * Comment [Study Results] header.  For use in populating the study object.
   * @param results - an optional string detailing study results.
   */
  public final void setResults(final String results) {
    this.results = AppUtils.removeTokens(results);
  }

  /**
   * Comment [Study Conclusions] header.  For use in performing conversions.
   * @return - conclusions: an optional string detailing study conclusions (may return an empty string)
   */
  public final String getConclusions() {
    return conclusions;
  }

  /**
   * Comment [Study Conclusions] header.  For use in populating the study object.
   * @param conclusions - an optional string detailing study conclusions.
   */
  public final void setConclusions(final String conclusions) {
    this.conclusions = AppUtils.removeTokens(conclusions);
  }

  public final List<String> getRelatedStudies() {
    return relatedStudies;
  }

  public final void setRelatedStudies(final List<String> relatedStudies) {
    this.relatedStudies = relatedStudies;
  }

  public final List<String> getChildStudies() {
    return childStudies;
  }

  public final void setChildStudies(final List<String> childStudies) {
    this.childStudies = childStudies;
  }

  /**
   * @return - a complete representation of the study using
   *           ReflectionToStringBuilder for debugging purposes.
   */
  public final String toString() {
    return ReflectionToStringBuilder.toString(this);
  }

  /**
   * Populates a study using the data from the IDF portion of a MAGE-TAB and using the IDF object generated by the underlying
   * limpopo software.  Owing to a limpopo oversight, Investigation Accession and Investigation Accession Term Source REF are
   * not captured in the limpopo IDF object as such.  So a pair of custom read handlers create comments for these entities from
   * which the study object is populated.
   * @param data - the limpopo IDF object
   * @return - a populated study object
   * @throws ConversionException - if a problem occurs while generating an ontology term for the investigation accession.
   */
  public static Study populate(IDF data) throws ConversionException {
	logger.debug("START: Populating Study");
    Study study = null;
    String investigationAccessionName = OrderedComment.retrieveComments("Investigation Accession",data).get(0);
    String investigationAccessionRef = OrderedComment.retrieveComments("Investigation Accession Term Source REF",data).get(0);
    study = new Study();
    study.setName(data.investigationTitle);
    study.setDbId(AppUtils.filterIdToken(data.investigationTitle));
    study.setSourceId(new OntologyTerm(investigationAccessionName, investigationAccessionRef));
    study.setDescription(data.experimentDescription);
    study.setPubmedIds(data.pubMedId);
    study.setGoal(OrderedComment.retrieveComments(GOAL_COMMENT, data).get(0));
    study.setApproaches(OrderedComment.retrieveComments(APPROACHES_COMMENT, data).get(0));
    study.setResults(OrderedComment.retrieveComments(RESULTS_COMMENT, data).get(0));
    study.setConclusions(OrderedComment.retrieveComments(CONCLUSIONS_COMMENT, data).get(0));
    logger.debug("END: Populating Study");
    return study;
  }
  
}

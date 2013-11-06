package edu.upenn.cbil.limpopo.conversion;

import java.util.Iterator;
import java.util.List;

import net.sourceforge.fluxion.spi.ServiceProvider;

import org.apache.commons.lang.StringUtils;
import org.jdom2.Attribute;
import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.Namespace;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;
import uk.ac.ebi.arrayexpress2.magetab.handler.idf.IDFConversionHandler;
import edu.upenn.cbil.limpopo.model.Contact;
import edu.upenn.cbil.limpopo.model.ExternalDatabase;
import edu.upenn.cbil.limpopo.model.Protocol;
import edu.upenn.cbil.limpopo.model.ProtocolParam;
import edu.upenn.cbil.limpopo.model.Publication;
import edu.upenn.cbil.limpopo.model.Study;
import edu.upenn.cbil.limpopo.model.StudyDesign;
import edu.upenn.cbil.limpopo.model.StudyFactor;
import edu.upenn.cbil.limpopo.utils.AppUtils;
import static edu.upenn.cbil.limpopo.utils.AppUtils.*;

/**
 * Converts a MAGE-TAB IDF into an XML document that can be used by CBIL to load a
 * GUS 4.0 DB schema.
 * @author Cris Lawrence
 *
 */
@ServiceProvider
public class IDFtoXMLConversionHandler extends IDFConversionHandler<Document> {
  public static Logger logger = LoggerFactory.getLogger(IDFtoXMLConversionHandler.class);

  /**
   * Empty check of whether IDF data is "convertible".
   */
  @Override
  protected boolean canConvertData(IDF data) {
	logger.trace("Inside canConvertData of " + getClass().getSimpleName());
	return true;
  }

  /**
   * As the IDF is parsed, various internal models are populated with data and those models
   * are in turn used the build the xml document.
   * @param data - the IDF data as rendered by Limpopo
   * @param document - the xml document to be constructed
   * @throws ConversionException - results from a failure to populate the internal model used to
   * build the xml document. 
   */
  @Override
  protected void convertData(IDF data, Document document) throws ConversionException {
	logger.debug("START - " + this.getClass().getSimpleName());
	ExternalDatabase.populate(data);
	Namespace xsi = Namespace.getNamespace(SCHEMA_INSTANCE_PREFIX, SCHEMA_INSTANCE_URI);
	Attribute xsdAttribute = new Attribute(SCHEMA_LOCATION, SCHEMA_FILE, xsi);
	Element magetab = new Element(MAGE_TAB_TAG);
	magetab.setAttribute(xsdAttribute);
	document.setRootElement(magetab);
	Element idfElement = new Element(IDF_TAG);
	
    Study study = Study.populate(data);
    idfElement.addContent(assembleStudyElement(study));
    
    List<StudyDesign> studyDesigns = StudyDesign.populate(data);
    Iterator<StudyDesign> studyDesignIterator = studyDesigns.iterator();
    while(studyDesignIterator.hasNext()) {
      StudyDesign studyDesign = studyDesignIterator.next();
      idfElement.addContent(assembleStudyDesignElement(studyDesign));
    }
    
    List<StudyFactor> studyFactors = StudyFactor.populate(data);
    Iterator<StudyFactor> studyFactorIterator = studyFactors.iterator();
    while(studyFactorIterator.hasNext()) {
      StudyFactor studyFactor = studyFactorIterator.next();
      idfElement.addContent(assembleStudyFactorElement(studyFactor));
    }
    
    List<Contact> contacts = Contact.populate(data);
    Iterator<Contact> contactIterator = contacts.iterator();
    while(contactIterator.hasNext()) {
      Contact contact = contactIterator.next();  
      idfElement.addContent(assembleContactElement(contact));
    }
    
    List<Protocol> protocols = Protocol.populate(data);
    Iterator<Protocol> protocolIterator = protocols.iterator();
    while(protocolIterator.hasNext()) {
      Protocol protocol = protocolIterator.next();
      idfElement.addContent(assembleProtocolElement(protocol));
    }
    
    document.getRootElement().addContent(idfElement);
    logger.debug("END - " + this.getClass().getSimpleName());
  }
  
  /**
   * Builds the study portion of the XML document from the data populating the internal Study
   * model.
   * @param study - the populated study object
   * @return - top level element for the study portion of the xml.  Empty elements are discarded.
   * <pre>
   * {@code
   *   <study>
   *     <name>title</name>
   *     <description>description</description>
   *     <pubmedIds>
   *       see assemblePubmedIdElement
   *     </pubmedIds>
   *     <external_database_release>Name|Version</external_database_release>
   *     <source_id>id</source_id>
   *     <goal>goal</goal>
   *     <approaches>approaches</approaches>
   *     <results>results</results>
   *     <conclusions>conclusions</conclusions>
   *    <related_studies>semi-colon separated list of study names; part of FGSS--application specific</related_studies>
   *    <child_studies>semi-colon separated list of study names; for investigations</child_studies>
   *  </study>
   * }
   * </pre>
   */
  protected Element assembleStudyElement(Study study) {
    Element studyElement = new Element(STUDY_TAG);
    if(StringUtils.isNotEmpty(study.getDbId())) {
      studyElement.setAttribute(DBID_ATTR, study.getDbId());
    }
    studyElement.addContent(new Element(NAME_TAG).setText(study.getName()));
    if(!StringUtils.isEmpty(study.getDescription())) {
      studyElement.addContent(new Element(DESCRIPTION_TAG).setText(study.getDescription()));
    }
    List<Publication> publications = study.getPublications();
    if(publications.size() > 0) {
      Element publicationsElement = new Element(PUBMED_IDS_TAG);
      for(Publication publication : publications) {
        publicationsElement.addContent(assemblePubmedIdElement(publication));
      }
      studyElement.addContent(publicationsElement);
    }
    if(!StringUtils.isEmpty(study.getSourceId().getName())) {
      studyElement.addContent(new Element(EXTERNAL_DATABASE_RELEASE_TAG).setText(study.getSourceId().getExternalDatabaseRelease()));
      studyElement.addContent(new Element(SOURCE_ID_TAG).setText(study.getSourceId().getName()));
    }
    if(!StringUtils.isEmpty(study.getGoal())) {
      studyElement.addContent(new Element(GOAL_TAG).setText(study.getGoal()));
    }
    if(!StringUtils.isEmpty(study.getApproaches())) {
      studyElement.addContent(new Element(APPROACHES_TAG).setText(study.getApproaches()));
    }
    if(!StringUtils.isEmpty(study.getResults())) {
      studyElement.addContent(new Element(RESULTS_TAG).setText(study.getResults()));
    }
    if(!StringUtils.isEmpty(study.getConclusions())) {
      studyElement.addContent(new Element(CONCLUSIONS_TAG).setText(study.getConclusions()));
    }
    String relatedStudies = StringUtils.join(study.getRelatedStudies(),";");
    if(!StringUtils.isEmpty(relatedStudies)) {
      studyElement.addContent(new Element(RELATED_STUDIES_TAG).setText(relatedStudies));
    }
    String childStudies = StringUtils.join(study.getChildStudies(),";");
    if(!StringUtils.isEmpty(childStudies)) {
      studyElement.addContent(new Element(CHILD_STUDIES_TAG).setText(childStudies));
    }
    return studyElement;
  }
  
  /**
   * Builds the pubmed id portion of the XML document from the data populating the internal
   * Publication model
   * @param publication - the populated publication object
   * @return - the pubmedId element.  Empty elements are discarded.  Addition attribute is
   * present only if pubmed id is an addition.  
   * <pre>
   * {@code
   *   <pubmed_id addition="true">pubmed id</pubment_id>
   * }
   * </pre>
   */
  protected Element assemblePubmedIdElement(Publication publication) {
    Element element = new Element(AppUtils.PUBMED_ID_TAG).setText(publication.getPubmedId());
    if(publication.isAddition()) {
      element.setAttribute(ADDITION_ATTR, TRUE);
    }
    return element;
  }
  
  
  /**
   * Builds the study design portion of the XML document from the data populating the internal Study
   * design model.
   * @param design - the populated study design object
   * @return - the top level element of the study design portion of the xml.  Empty elements are discarded.
   * Addition attribute is present only if study design is an addition.  
   * <pre>
   * {@code
   *   <study_design addition="true">
   *    <type>type</type>
   *    <type_ext_db_rls>Name|Version</type_ext_db_rls>
   *  </study_design>   
   * }
   * </pre>
   */
  protected Element assembleStudyDesignElement(StudyDesign design) {
    Element element = new Element(AppUtils.STUDY_DESIGN_TAG);
    if(design.isAddition()) {
      element.setAttribute(ADDITION_ATTR, TRUE);
    }
    if(!StringUtils.isEmpty(design.getType().getName())) {
      element.addContent(new Element(TYPE_TAG).setText(design.getType().getName()));
      element.addContent(new Element(TYPE_EXT_DB_RLS_TAG).setText(design.getType().getExternalDatabaseRelease()));
    }
    return element;
  }
  
  /**
   * Builds the study factor portion of the XML document from the data populating the internal Study
   * factor model.
   * @param factor - the populated study factor object
   * @return - the top level element of the study factor portion of the xml.  Empty elements are discarded.
   * Addition attribute is present only if study factor is an addition.  
   * <pre>
   * {@code
   *   <study_factor addition="true">
   *     <name>factor name</name>
   *     <description>description</description>
   *     <type>type</type>
   *     <type_ext_db_rls>Name|Version</type_ext_db_rls>
   *   </study_factor>   
   * }
   * </pre>
   */
  protected Element assembleStudyFactorElement(StudyFactor factor) {
    Element element = new Element(AppUtils.STUDY_FACTOR_TAG);
    if(factor.isAddition()) {
      element.setAttribute(ADDITION_ATTR, TRUE);
    }
    element.addContent(new Element(NAME_TAG).setText(factor.getName()));
    if(!StringUtils.isEmpty(factor.getType().getName())) {
      element.addContent(new Element(TYPE_TAG).setText(factor.getType().getName()));
      element.addContent(new Element(TYPE_EXT_DB_RLS_TAG).setText(factor.getType().getExternalDatabaseRelease()));
    }
    return element;
  }
  
  /**
   * Builds the contact portion of the XML document from the data populating the internal Contact
   * model.
   * @param contact - the populated contact object
   * @return - the top level element of the contact portion of the xml
   */
  protected Element assembleContactElement(Contact contact) {
    Element element = new Element(AppUtils.CONTACT_TAG);
    if(contact.isAddition()) {
      element.setAttribute(ADDITION_ATTR, TRUE);
    }
    element.addContent(new Element(NAME_TAG).setText(contact.getName()));
    if(!StringUtils.isEmpty(contact.getFirstName())) {
      element.addContent(new Element(FIRST_NAME_TAG).setText(contact.getFirstName()));
    }
    if(!StringUtils.isEmpty(contact.getLastName())) {
      element.addContent(new Element(LAST_NAME_TAG).setText(contact.getLastName()));
    }
    if(!StringUtils.isEmpty(contact.getEmail())) {
      element.addContent(new Element(EMAIL_TAG).setText(contact.getEmail()));
    }
    if(!StringUtils.isEmpty(contact.getPhone())) {
      element.addContent(new Element(PHONE_TAG).setText(contact.getPhone()));
    }
    if(!StringUtils.isEmpty(contact.getFax())) {
      element.addContent(new Element(FAX_TAG).setText(contact.getFax()));
    }
    if(!StringUtils.isEmpty(contact.getAddress1())) {
      element.addContent(new Element(ADDRESS1_TAG).setText(contact.getAddress1()));
    }
    if(!StringUtils.isEmpty(contact.getAddress2())) {
      element.addContent(new Element(ADDRESS2_TAG).setText(contact.getAddress2()));
    }
    if(!StringUtils.isEmpty(contact.getCity())) {
      element.addContent(new Element(CITY_TAG).setText(contact.getCity()));
    }
    if(!StringUtils.isEmpty(contact.getState())) {
      element.addContent(new Element(STATE_TAG).setText(contact.getState()));
    }
    if(!StringUtils.isEmpty(contact.getCountry())) {
      element.addContent(new Element(COUNTRY_TAG).setText(contact.getCountry()));
    }
    if(!StringUtils.isEmpty(contact.getZipcode())) {
      element.addContent(new Element(ZIP_CODE_TAG).setText(contact.getZipcode()));
    }
    if(!StringUtils.isEmpty(contact.getAffiliation())) {
      element.addContent(new Element(AFFILIATION_TAG).setText(contact.getAffiliation()));
    }
    if(!StringUtils.isEmpty(contact.getRoles().getName())) {
      element.addContent(new Element(ROLES_TAG).setText(contact.getRoles().getName()));
      element.addContent(new Element(ROLES_EXT_DB_RLS_TAG).setText(contact.getRoles().getExternalDatabaseRelease()));
    }
    return element;
  }
  
  /**
   * Builds the protocol portion of the XML document from the data populating the internal Protocol
   * model.
   * @param protocol - the populated protocol object
   * @return - the top level element of the protocol portion of the xml
   */
  protected Element assembleProtocolElement(Protocol protocol) {
    Element protocolElement = new Element(PROTOCOL_TAG);
    if(protocol.isAddition()) {
      protocolElement.setAttribute(ADDITION_ATTR, TRUE);
    }
    if(StringUtils.isNotEmpty(protocol.getDbId())) {
      protocolElement.setAttribute(DBID_ATTR,  protocol.getDbId());
    }
    protocolElement.addContent(new Element(NAME_TAG).setText(protocol.getName()));
    if(!StringUtils.isEmpty(protocol.getDescription())) {
      protocolElement.addContent(new Element(DESCRIPTION_TAG).setText(protocol.getDescription()));
    }
    if(!StringUtils.isEmpty(protocol.getType().getName())) {
      protocolElement.addContent(new Element(TYPE_TAG).setText(protocol.getType().getName()));
      protocolElement.addContent(new Element(TYPE_EXT_DB_RLS_TAG).setText(protocol.getType().getExternalDatabaseRelease()));
    }
    if(!StringUtils.isEmpty(protocol.getPubmedId())) {
      protocolElement.addContent(new Element(PUBMED_ID_TAG).setText(protocol.getPubmedId()));
    }
    if(!StringUtils.isEmpty(protocol.getIsPrivate())) {
      if("0".equals(protocol.getIsPrivate())) {
        protocolElement.addContent(new Element(ACCESSIBILITY_TAG).setText("1"));
      }
      else {
        protocolElement.addContent(new Element(ACCESSIBILITY_TAG).setText("0"));
      }
    }
    if(!StringUtils.isEmpty(protocol.getSourceId().getName())) {
      protocolElement.addContent(new Element(EXTERNAL_DATABASE_RELEASE_TAG).setText(protocol.getSourceId().getExternalDatabaseRelease()));
      protocolElement.addContent(new Element(SOURCE_ID_TAG).setText(protocol.getSourceId().getName()));
    }
    if(!StringUtils.isEmpty(protocol.getUri())) {
      protocolElement.addContent(new Element(URI_TAG).setText(protocol.getUri()));
    }
    if(!StringUtils.isEmpty(protocol.getContactId())) {
      protocolElement.addContent(new Element(CONTACT_TAG).setText(protocol.getContactId()));
    }
    if(!protocol.getParameters().isEmpty()) {
      Element parametersElement = new Element(PROTOCOL_PARAMETERS_TAG);
      protocolElement.addContent(parametersElement);
      Iterator<ProtocolParam> parameterIterator = protocol.getParameters().iterator();
      while(parameterIterator.hasNext()) {
        ProtocolParam parameter = parameterIterator.next();
        parametersElement.addContent(assembleParameterElement(protocol, parameter));
      }
    }
    return protocolElement;
  }
  
  /**
   * Builds the protocol parameter portion of the XML document from the data populating the internal
   * Protocol Parameter model.
   * @param parameter - the populated protocol parameter object
   * @return - the top level element of the protocol parameter portion of the xml
   */
  protected Element assembleParameterElement(Protocol protocol, ProtocolParam parameter) {
    Element parameterElement = new Element(PARAM_TAG);
    if(parameter.isAddition() && !protocol.isAddition()) {
      parameterElement.setAttribute(ADDITION_ATTR, TRUE);
    }
    parameterElement.addContent(new Element(NAME_TAG).setText(parameter.getName()));
    if(!StringUtils.isEmpty(parameter.getDataType().getName())) {
      parameterElement.addContent(new Element(DATA_TYPE_TAG).setText(parameter.getDataType().getName()));
      parameterElement.addContent(new Element(DATA_TYPE_EXT_DB_RLS_TAG).setText(parameter.getDataType().getExternalDatabaseRelease()));
    }
    if(!StringUtils.isEmpty(parameter.getUnitType().getName())) {
      parameterElement.addContent(new Element(UNIT_TYPE_TAG).setText(parameter.getUnitType().getName()));
      parameterElement.addContent(new Element(UNIT_TYPE_EXT_DB_RLS_TAG).setText(parameter.getUnitType().getExternalDatabaseRelease()));
    }
    if(!StringUtils.isEmpty(parameter.getDefaultValue())) {
      parameterElement.addContent(new Element(DEFAULT_VALUE_TAG).setText(parameter.getDefaultValue()));
    }
    if(!StringUtils.isEmpty(parameter.getUserSpecified())) {
      parameterElement.addContent(new Element(IS_USER_SPECIFIED_TAG).setText(parameter.getUserSpecified()));
    }
    return parameterElement;
  }
}
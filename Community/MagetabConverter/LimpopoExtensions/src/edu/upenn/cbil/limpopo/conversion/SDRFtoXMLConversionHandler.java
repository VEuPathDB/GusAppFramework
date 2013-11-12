package edu.upenn.cbil.limpopo.conversion;

import static edu.upenn.cbil.limpopo.utils.AppUtils.ADDITION_ATTR;
import static edu.upenn.cbil.limpopo.utils.AppUtils.CATEGORY_ATTR;
import static edu.upenn.cbil.limpopo.utils.AppUtils.CHARACTERISTIC_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.CHILD_PROTOCOL_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.CONTACTS_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.CONTACT_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.ROLE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.DESCRIPTION_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.EXTERNAL_DATABASE_RELEASE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.IDF_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.ID_ATTR;
import static edu.upenn.cbil.limpopo.utils.AppUtils.INPUT_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.NAME_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.NODE_CHARACTERISTICS_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.ONTOLOGY_TERM_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.VALUE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.OUTPUT_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.PROTOCOL_APP_DATE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.PROTOCOL_APP_NODE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.PROTOCOL_APP_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.PROTOCOL_APP_PARAMETERS_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.PROTOCOL_APP_PARAMETER_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.STEP_ATTR;
import static edu.upenn.cbil.limpopo.utils.AppUtils.PROTOCOL_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.SDRF_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.TABLE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.ROW_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.TAXON_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.TRUE;
import static edu.upenn.cbil.limpopo.utils.AppUtils.TYPE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.URI_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.UNIT_TYPE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.UNIT_TYPE_EXT_DB_RLS_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.DBID_ATTR;

import java.util.Iterator;
import java.util.List;
import java.util.Set;

import net.sourceforge.fluxion.spi.ServiceProvider;

import org.apache.commons.lang.StringUtils;
import org.jdom2.Document;
import org.jdom2.Element;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.SDRF;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;
import uk.ac.ebi.arrayexpress2.magetab.handler.sdrf.SDRFConversionHandler;
import edu.upenn.cbil.limpopo.model.Characteristic;
import edu.upenn.cbil.limpopo.model.OntologyTerm;
import edu.upenn.cbil.limpopo.model.Performer;
import edu.upenn.cbil.limpopo.model.ProtocolApplication;
import edu.upenn.cbil.limpopo.model.ProtocolApplicationIONode;
import edu.upenn.cbil.limpopo.model.ProtocolApplicationParameter;
import edu.upenn.cbil.limpopo.model.ProtocolSeries;
import edu.upenn.cbil.limpopo.utils.SDRFUtils;


/**
 * Converts a MAGE-TAB SDRF into an XML document that can be used by CBIL to load a
 * GUS 4.0 DB Schema.
 * @author Cris Lawrence
 *
 */
@ServiceProvider
public class SDRFtoXMLConversionHandler  extends SDRFConversionHandler<Document> {
  public static Logger logger = LoggerFactory.getLogger(SDRFtoXMLConversionHandler.class);

  /**
   * Empty check of whether SDRF data is "convertible".
   */
  @Override
  protected boolean canConvertData(SDRF data) {
	logger.trace("Inside canConvertData of " + getClass().getSimpleName());
	return true;
  }

  /**
   * As the SDRF is parsed, various internal models are populated with data and those models
   * are in turn used the build the xml document.
   * @param data - the SDRF data as rendered by Limpopo
   * @param document - the xml document to be constructed
   * @throws ConversionException - results from a failure to populate the internal model used to
   * build the xml document. 
   */
  @Override
  protected void convertData(SDRF data, Document document) throws ConversionException {
	logger.debug("START - " + getClass().getSimpleName());
	SDRFUtils utils = new SDRFUtils(data.getLayout());
	Element sdrfElement = new Element(SDRF_TAG);
	ProtocolApplication.createAllProtocolApplications(data);
	Set<ProtocolApplicationIONode> appNodes = ProtocolApplicationIONode.getApplicationIONodes();
	for(ProtocolApplicationIONode appNode : appNodes) {
	  sdrfElement.addContent(assembleProtocolApplicationNodeElement(appNode));
	}
	for(ProtocolApplication app : ProtocolApplication.getApplications()) {
	  if(app.isTopmost()) {
		sdrfElement.addContent(assembleProtocolApplicationElement(app));
	  }
	}
	amendIDF(document.getRootElement());
	document.getRootElement().addContent(sdrfElement);
    logger.debug("END - " + getClass().getSimpleName());
  }
  
  /**
   * Builds a member of the protocol application node portion of the xml.
   * @param appNode - the protocol application node (i.e., node)
   * @return - the completed protocol application node xml element.  Empty elements are discarded.
   * Addition attribute is present only if protocol application node is an addition.  A database id
   * is present only if needed to clarify database relationships for additions.  Note that
   * factor values are not handled here because CBIL violates the spec.
   * <pre>
   * {@code
   *   <protocol_app_node id="loc" [addition="true"] [db_id="db id"]>
   *     <type>material entity or data type</type>
   *     <subtype>presently unused</subtype>
   *     <name>name</name>
   *     <description>description</description>
   *     <external_database_release>Name|Version</external_database_release>
   *     <source_id>id</source_id> 
   *     <uri>uri</uri>
   *     <taxon>taxon</taxon>
   *     see setNodeCharacteristic  
   *   </protocol_app_node>
   * }
   * </pre>
   */
  protected Element assembleProtocolApplicationNodeElement(ProtocolApplicationIONode appNode) {
    Element nodeElement = new Element(PROTOCOL_APP_NODE_TAG);
    nodeElement.setAttribute(ID_ATTR,appNode.getId());
    if(appNode.isAddition()) {
      nodeElement.setAttribute(ADDITION_ATTR, TRUE);
    }
    if(StringUtils.isNotEmpty(appNode.getDbId())) {
      nodeElement.setAttribute(DBID_ATTR, appNode.getDbId());
    }
    nodeElement.addContent(new Element(TYPE_TAG).setText(appNode.getType()));
    nodeElement.addContent(new Element(NAME_TAG).setText(appNode.getName()));
    if(!StringUtils.isEmpty(appNode.getDescription())) {
      nodeElement.addContent(new Element(DESCRIPTION_TAG).setText(appNode.getDescription()));
    }
    if(!StringUtils.isEmpty(appNode.getTaxon())) {
      nodeElement.addContent(new Element(TAXON_TAG).setText(appNode.getTaxon()));
    }
    if(!StringUtils.isEmpty(appNode.getUri())) {
      nodeElement.addContent(new Element(URI_TAG).setText(appNode.getUri()));
    }
    Element charElement = setNodeCharacteristic(appNode);
    if(charElement != null) {
      nodeElement.addContent(charElement);
    }
    for(Characteristic characteristic : appNode.getCharacteristics()) {
      nodeElement.addContent(setNodeCharacteristic(characteristic));
    }
    return nodeElement;
  }
	
  /**
   * Builds the node characteristics of the protocol application node portion of the XML
   * document from the data populating the internal Protocol Application IO Node model
   * @param appNode - the characteristic object
   * @return - the top level node characteristic element.  Empty elements are discarded.
   * <pre>
   * {@code
   *   <characteristic>
   *     <external_database_release>Name|Version</external_database_release>
   *     <ontology_term category="type">name</ontology_term> 
   *     <value>value</value>
   *   </characteristic>
   * }
   * </pre>
   */
  protected Element setNodeCharacteristic(Characteristic characteristic) {
    String category = characteristic.getCategory();
    String value = characteristic.getValue();
    OntologyTerm term = characteristic.getTerm();
    Element charElement = new Element(CHARACTERISTIC_TAG);
    if(term != null) { 
      Element termElement = new Element(ONTOLOGY_TERM_TAG);
      termElement.setText(term.getName());
      if(StringUtils.isEmpty(value)) {
        termElement.setAttribute(CATEGORY_ATTR, category);
      }
      charElement.addContent(termElement);
      charElement.addContent(new Element(EXTERNAL_DATABASE_RELEASE_TAG).setText(term.getExternalDatabaseRelease()));
    }     
    if(StringUtils.isNotEmpty(value)) {
      Element valueElement = new Element(VALUE_TAG);
      valueElement.addContent(value);
      valueElement.setAttribute(CATEGORY_ATTR, category);
      charElement.addContent(valueElement);
    }
    return charElement;
  }
  
  /**
   * Builds the node characteristic of the protocol application node portion of the XML
   * document from the data populating the internal Protocol Application IO Node model
   * @param appNode - the protocol application IO node (i.e., node)
   * @return - the top level node characteristic element.  Empty elements are discarded.
   * <pre>
   * {@code
   *   <characteristic>
   *     <table>Schema::Table</table>
   *   </characteristic>
   * }
   * </pre>
   */
  protected Element setNodeCharacteristic(ProtocolApplicationIONode appNode) {
    Element charElement = null;
    if(!StringUtils.isEmpty(appNode.getTable())) {
      charElement = new Element(CHARACTERISTIC_TAG);
      charElement.addContent(new Element(TABLE_TAG).setText(appNode.getTable()));
    }
    return charElement;
  }
  
  /**
   * Builds a member of the protocol application portion of the xml.
   * @param app - the protocol application (i.e., edge)
   * @return - the completed protocol application xml element.  Empty elements are discarded.
   * Addition attribute is present only if protocol application is an addition.  A database id
   * is present only if needed to clarify database relationships for additions.
   * <pre>
   * {@code
   *   <protocol_app id="loc" [addition="true"] [db_id="db id"]>
   *     <protocol>name</protocol>
   *     <protocol_app_date>date</protocol_app_date>
   *     <contacts>
   *       see setContact
   *     </contacts>
   *     <protocol_app_parameters>
   *       see setProtocolApplicationParameter  
   *     </protocol_app_parameters>
   *     <inputs>semi-colon separated list of protocol_node ids</inputs>
   *     <outputs>semi-colon separated list of protocol_node ids</outputs>
   *   </protocol_app>
   * }
   * </pre>
   */
  protected Element assembleProtocolApplicationElement(ProtocolApplication app) { 
    int step = 0;
    Element appElement = new Element(PROTOCOL_APP_TAG);
    appElement.setAttribute(ID_ATTR, app.getId());
    if(app.isAddition()) {
      appElement.setAttribute(ADDITION_ATTR, TRUE);
    }
    if(StringUtils.isNotEmpty(app.getDbId())) {
      appElement.setAttribute(DBID_ATTR, app.getDbId());
    }
    appElement.addContent(new Element(PROTOCOL_TAG).setText(app.getName()));
    step = 1;
    for(Performer performer : app.getPerformers()) {
      appElement.addContent(setContact(performer, Integer.toString(step)));
    }
    if(app.hasSubordinate()) {
      for(ProtocolApplication subordinate : app.getSubordinateApps()) {
        step++;
        for(Performer performer : subordinate.getPerformers()) {
          appElement.addContent(setContact(performer, Integer.toString(step)));
        }
      }
    }
    if(StringUtils.isNotEmpty(app.getDate())) {
      appElement.addContent(new Element(PROTOCOL_APP_DATE_TAG).setText(app.getDate()));
    }
    step = 1;
    for(ProtocolApplicationParameter param : app.getParameters()) {
      appElement.addContent(assembleProtocolApplicationParameterElement(param, Integer.toString(step)));
    }
    if(app.hasSubordinate()) {
      for(ProtocolApplication subordinate : app.getSubordinateApps()) {
        step++;
        for(ProtocolApplicationParameter param : subordinate.getParameters()) {
          appElement.addContent(assembleProtocolApplicationParameterElement(param, Integer.toString(step)));
        }
      }
    }
    for(ProtocolApplicationIONode input : app.getInputs()) {
      appElement.addContent(new Element(INPUT_TAG).setText(input.getId()));
    }
    for(ProtocolApplicationIONode output : app.getOutputs()) {
      appElement.addContent(new Element(OUTPUT_TAG).setText(output.getId()));
    }
    return appElement;
  }
  
  /**
   * Builds the performer xml for a protocol application.
   * @param performer - the performer object
   * @param step - integer indicating which step in a protocol application series.  If
   * the protocol application is not part of a series, step will be 1.
   * @return - the completed performer xml element.  Empty elements are discarded.
   * Addition attribute is present only if performer is an addition.  
   * * <pre>
   * {@code
   *   <contact step="#" addition=true">
   *     <name>First Last</name>
   *     <role>Role</role>
   *     <external_database_release>Name|Version</external_database_release>
   *   </contact>
   * }
   * </pre>
   */
  protected Element setContact(Performer performer, String step) {
    Element contactElement = new Element(CONTACT_TAG);
    contactElement.setAttribute(STEP_ATTR, step);
    if(performer.isAddition()) {
      contactElement.setAttribute(ADDITION_ATTR, TRUE);
    }
    contactElement.addContent(new Element(NAME_TAG).setText(performer.getName()));
    if(performer.hasRole()) {
      contactElement.addContent(new Element(ROLE_TAG).setText(performer.getRole().getName()));
      contactElement.addContent(new Element(EXTERNAL_DATABASE_RELEASE_TAG).setText(performer.getRole().getExternalDatabaseRelease()));
    }
    return contactElement;
  }
  
  /**
   * Builds the parameter xml for a protocol application
   * @param param - the protocol application param to be converted into a xml element
   * @param step - integer indicating the step in a protocol application series to which
   * this parameter belongs.  If the protocol application is not part of a series, the
   * step will be 1.
   * @return - the completed parameter xml element.  Empty elements are discarded.  Addition
   * attribute is present only if the parameter is added and the protocol application to
   * which it belong is not added.
   * <pre>
   * {@code
   * <app_param step="#" [addition="true"]>
   *   <name>parameter name</name>
   *   <value>parameter value</value>
   *   <table>Schema::Table</table>
   *   <row_id>row id</row_id>
   *   <unit_type category="parameter category">unit type</unit_type>
   *   <unit_type_ext_db_rls>Name|Version</unit_type_ext_db_rls>
   * </app_param> 
   * }
   * </pre>
   */
  protected Element assembleProtocolApplicationParameterElement(ProtocolApplicationParameter param, String step) {
    Element paramElement = new Element(PROTOCOL_APP_PARAMETER_TAG);
    paramElement.setAttribute(STEP_ATTR, step);
    if(param.isAddition()) {
      paramElement.setAttribute(ADDITION_ATTR, TRUE);
    }
    paramElement.addContent(new Element(NAME_TAG).setText(param.getName()));
    paramElement.addContent(new Element(VALUE_TAG).setText(param.getValue()));
    if(param.hasTableRowPair()) {
      paramElement.addContent(new Element(TABLE_TAG).setText(param.getTable()));
      paramElement.addContent(new Element(ROW_TAG).setText(param.getRow()));
    }
    if(param.getUnitType() != null) {
      Element unitTypeElement = new Element(UNIT_TYPE_TAG).setText(param.getUnitType().getName());
      if(StringUtils.isNotEmpty(param.getUnitType().getCategory())) {
        unitTypeElement.setAttribute(CATEGORY_ATTR, param.getUnitType().getCategory());
      }
      paramElement.addContent(unitTypeElement);
      paramElement.addContent(new Element(UNIT_TYPE_EXT_DB_RLS_TAG).setText(param.getUnitType().getExternalDatabaseRelease()));
    }
    return paramElement;
  }
    
  /**
   * Additional protocols representing a series of protocols as found in the SDRF must be
   * added to the IDF portion of the xml document.
   * @param magetabElement - top level element of the xml document under construction.
   */
  private void amendIDF(Element magetabElement) {
	for(ProtocolSeries series : ProtocolApplication.getSeries()) {
	  ProtocolSeries.adjustAddition(series);
      Element protocolElement = new Element(PROTOCOL_TAG);
      if(series.isAddition()) {
        protocolElement.setAttribute(ADDITION_ATTR, TRUE);
      }
      protocolElement.addContent(new Element(NAME_TAG).setText(series.getName()));
      int step = 1;
      for(ProtocolApplication protocolApplication : series.getProtocolApplications()) {
        Element childProtocolElement = new Element(CHILD_PROTOCOL_TAG).setText(protocolApplication.getName());
        childProtocolElement.setAttribute(STEP_ATTR, Integer.toString(step++));
        protocolElement.addContent(childProtocolElement);
      }
      if(magetabElement.getChild(IDF_TAG) != null) {
        magetabElement.getChild(IDF_TAG).addContent(protocolElement);
      }
	}
  }
}

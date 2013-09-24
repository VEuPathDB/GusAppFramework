package edu.upenn.cbil.limpopo.conversion;

import static edu.upenn.cbil.limpopo.utils.AppUtils.ADDITION_ATTR;
import static edu.upenn.cbil.limpopo.utils.AppUtils.CATEGORY_ATTR;
import static edu.upenn.cbil.limpopo.utils.AppUtils.CHARACTERISTIC_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.CHILD_PROTOCOLS_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.CONTACTS_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.DESCRIPTION_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.EXTERNAL_DATABASE_RELEASE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.IDF_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.ID_ATTR;
import static edu.upenn.cbil.limpopo.utils.AppUtils.INPUTS_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.NAME_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.NODE_CHARACTERISTICS_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.ONTOLOGY_TERM_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.VALUE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.OUTPUTS_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.PROTOCOL_APP_DATE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.PROTOCOL_APP_NODE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.PROTOCOL_APP_PARAMETERS_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.PROTOCOL_APP_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.PROTOCOL_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.SDRF_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.TABLE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.TAXON_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.TRUE;
import static edu.upenn.cbil.limpopo.utils.AppUtils.TYPE_TAG;
import static edu.upenn.cbil.limpopo.utils.AppUtils.URI_TAG;
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
import edu.upenn.cbil.limpopo.model.ProtocolApplicationParameterGroup;
import edu.upenn.cbil.limpopo.model.ProtocolSeries;
import edu.upenn.cbil.limpopo.utils.SDRFUtils;


/**
 * Converts a MAGE-TAB SDRF into an XML document that can be used by CBIL to load a
 * GUS 4.0 DB.
 * @author crisl
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
	  if(!appNode.getTerms().isEmpty() || StringUtils.isNotEmpty(appNode.getTable())) {
	    nodeElement.addContent(setNodeCharacteristics(appNode));
	  }
	  sdrfElement.addContent(nodeElement);
	}
	for(ProtocolApplication app : ProtocolApplication.getApplications()) {
	  if(app.isTopmost()) {
		Element appElement = new Element(PROTOCOL_APP_TAG);
		appElement.setAttribute(ID_ATTR, app.getId());
		if(app.isAddition()) {
          appElement.setAttribute(ADDITION_ATTR, TRUE);
        }
		if(StringUtils.isNotEmpty(app.getDbId())) {
		  appElement.setAttribute(DBID_ATTR, app.getDbId());
		}
		appElement.addContent(new Element(PROTOCOL_TAG).setText(app.getName()));
		/*
		 * It is difficult to know a priori whether there are any performers for a protocol
		 * series.  Empty performers and semicolons are needed to serve a placeholders.
		 * But a protocol series devoid of performers will have an element text composed only of
		 * semicolons.  If such an element appears, it will be discarded.
		 */
		if(!app.getPerformers().isEmpty()) {
		  Element performersElement = setContacts(app);
		  if(!performersElement.getText().matches("^;+$")) { 
		    appElement.addContent(setContacts(app));
		  }
		}
		if(StringUtils.isNotEmpty(app.getDate())) {
		  appElement.addContent(new Element(PROTOCOL_APP_DATE_TAG).setText(app.getDate()));
		}
		ProtocolApplicationParameterGroup group = app.getGroup();
		if(StringUtils.isNotEmpty(group.getAddedData()) && !app.isAddition()) {
		  if(StringUtils.isNotEmpty(group.getOriginalData())) {
		    appElement.addContent(new Element(PROTOCOL_APP_PARAMETERS_TAG).setText(group.getOriginalData()));
		  }
		  Element addedParamsElement = new Element(PROTOCOL_APP_PARAMETERS_TAG).setText(group.getAddedData());
		  addedParamsElement.setAttribute(ADDITION_ATTR, TRUE);
		  appElement.addContent(addedParamsElement);
		}
		else if(StringUtils.isNotEmpty(group.getAllData())) {
		  appElement.addContent(new Element(PROTOCOL_APP_PARAMETERS_TAG).setText(group.getAllData()));
		}
		StringBuffer ids = new StringBuffer();
		for(ProtocolApplicationIONode input : app.getInputs()) {
		  if(ids.length() > 0) ids.append(";");
		  ids.append(input.getId());
		}
		appElement.addContent(new Element(INPUTS_TAG).setText(ids.toString()));
		ids = new StringBuffer();
		for(ProtocolApplicationIONode output : app.getOutputs()) {
	      if(ids.length() > 0) ids.append(";");
		  ids.append(output.getId());
		}
		appElement.addContent(new Element(OUTPUTS_TAG).setText(ids.toString()));
		sdrfElement.addContent(appElement);
	  }
	}
	amendIDF(document.getRootElement());
	document.getRootElement().addContent(sdrfElement);
    logger.debug("END - " + getClass().getSimpleName());
  }

  /**
   * Builds the contacts list of the protocol application portion of the XML document from the
   * data populating the internal Protocol Application model
   * @param app - the protocol application object (i.e., edge)
   * @return - contacts xml element
   */
  protected Element setContacts(ProtocolApplication app) {
    Element contactsElement = new Element(CONTACTS_TAG);
    StringBuffer content = new StringBuffer();
    List<Performer> performers = app.getPerformers();
    Iterator<Performer> iterator = performers.iterator();
    while(iterator.hasNext()) {
      Performer performer = iterator.next();
      content.append(performer.getName());
      if(performer.getRole() != null) {
        content.append("::" + performer.getRole().getName() + "::" + performer.getRole().getExternalDatabaseRelease());
      }
      if(iterator.hasNext()) {
        content.append(";");
      }
    }
    contactsElement.setText(content.toString());
    return contactsElement;
  }
	
  /**
   * Builds the node characteristics of the protocol application node portion of the XML
   * document from the data populating the internal Protocol Application IO Node model
   * @param appNode - the protocol application IO node (i.e., node)
   * @return - the top level node characteristics element
   */
  protected Element setNodeCharacteristics(ProtocolApplicationIONode appNode) {
    Element nodeCharElement = new Element(NODE_CHARACTERISTICS_TAG);
    Iterator<Characteristic> iterator = appNode.getCharacteristics().iterator();
    while(iterator.hasNext()) {
      Characteristic characteristic = iterator.next();
      if(!characteristic.isEmpty()) {
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
        nodeCharElement.addContent(charElement);
      }
    }
    if(!StringUtils.isEmpty(appNode.getTable())) {
      Element charElement = new Element(CHARACTERISTIC_TAG);
      charElement.addContent(new Element(TABLE_TAG).setText(appNode.getTable()));
      nodeCharElement.addContent(charElement);
    }
    return nodeCharElement;
  }
  
  /**
   * Additional protocols representing a series of protocols as found in the SDRF must be
   * added to the IDF portion of the xml document.
   * @param magetabElement - top level element of the xml document under construction
   */
  private void amendIDF(Element magetabElement) {
	for(ProtocolSeries series : ProtocolApplication.getSeries()) {
	  ProtocolSeries.adjustAddition(series);
      Element protocolElement = new Element(PROTOCOL_TAG);
      if(series.isAddition()) {
        protocolElement.setAttribute(ADDITION_ATTR, TRUE);
      }
      protocolElement.addContent(new Element(NAME_TAG).setText(series.getName()));
      protocolElement.addContent(new Element(CHILD_PROTOCOLS_TAG).setText(series.getName()));
      if(magetabElement.getChild(IDF_TAG) != null) {
        magetabElement.getChild(IDF_TAG).addContent(protocolElement);
      }
	}
  }
}

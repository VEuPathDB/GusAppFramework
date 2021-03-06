package edu.upenn.cbil.limpopo.validate;

import java.util.Arrays;
import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import net.sourceforge.fluxion.spi.ServiceProvider;

import org.apache.commons.lang.StringUtils;
import org.mged.magetab.error.ErrorItem;
import org.mged.magetab.error.ErrorItemFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.MAGETABInvestigation;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.SDRF;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.ProtocolApplicationNode;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.SDRFNode;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.attribute.ParameterValueAttribute;
import uk.ac.ebi.arrayexpress2.magetab.exception.ValidateException;
import uk.ac.ebi.arrayexpress2.magetab.handler.MAGETABValidateHandler;
import uk.ac.ebi.arrayexpress2.magetab.handler.listener.HandlerListener;
import edu.upenn.cbil.limpopo.model.Contact;
import edu.upenn.cbil.limpopo.model.Protocol;
import edu.upenn.cbil.limpopo.model.ProtocolApplication;
import edu.upenn.cbil.limpopo.model.ProtocolApplicationIONode;
import edu.upenn.cbil.limpopo.model.ProtocolParam;
import edu.upenn.cbil.limpopo.utils.AppException;
import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.limpopo.utils.ListUtils;

/**
 * Provides validation checks for a number of general items, including checks that require comparing
 * SDRF data against IDF data.
 * @author crisl
 *
 */
@ServiceProvider
public class GeneralValidator extends MAGETABValidateHandler {

  public static Logger logger = LoggerFactory.getLogger(GeneralValidator.class);

  public GeneralValidator() {
    HandlerListener listener = new ValidateHandlerListener();
    addListener(listener);
  }
  
  @Override
  public boolean canValidateData(MAGETABInvestigation investigation) {
    logger.debug("Inside canValidateData of " + this.getClass().getSimpleName());
    return true;
  }
  
  /**
   * Some simple validations and some validation that compare IDF and SDRF
   * SOP 3.  Investigation Title and Experiment Description must both be non-empty.
   * SOP 4.  Experiment Design and Experiment Design Term Source REF must both be non-empty for every Experiment Design.
   * SOP 5.  Experimental Factor Name, Experimental Factor Type and Experimental Factor Term Source REF must all be non-empty
   *         for every Experimental Factor. 
   * SOP 18. The MAGE-TAB should always contain an Assay Name.
   */
  @Override
  public void validateData(MAGETABInvestigation investigation) throws ValidateException {
    logger.debug("START validateData of " + getClass().getSimpleName());
    IDF idf = investigation.IDF;
    SDRF sdrf = investigation.SDRF;
    try {
      /* Test for title present */
      if(idf.investigationTitle.trim().length() == 0) {
        throw new AppException(2001);
      }
      /* Test for description present */
      if(idf.experimentDescription.trim().length() == 0) {
        throw new AppException(2002);
      }
      /* Test for study design ref for each study design present */
      Iterator<String> iterator = idf.experimentalDesign.iterator();
      for(int i = 0; iterator.hasNext(); i++) {
        String ref = ListUtils.get(idf.experimentalDesignTermSourceREF, i);
        if(StringUtils.isEmpty(ref)) throw new AppException(2003);
        iterator.next();
      }
      /* Test for study factor type and type ref for each study factor present */
      iterator = idf.experimentalFactorName.iterator();
      for(int i = 0; iterator.hasNext(); i++) {
        String type = ListUtils.get(idf.experimentalFactorType, i);  
        if(StringUtils.isEmpty(type)) throw new AppException(2004);
        String ref = ListUtils.get(idf.experimentalFactorTermSourceREF, i);  
        if(StringUtils.isEmpty(ref)) throw new AppException(2005);
        iterator.next();
      } 
      validateContactPerformerMatch(idf, sdrf);
      validateProtocolMatch(idf, sdrf);
      validateProtocolParameterMatch(idf, sdrf);
      validateAssayName(sdrf);
    }
    catch (AppException ae) {
      ErrorItemFactory factory = ErrorItemFactory.getErrorItemFactory();
      ErrorItem error = factory.generateErrorItem(ae.getMessage(), ae.getCode(), getClass());
      throw new ValidateException(true, ae, error);
    }
    catch (Exception e) {
      logger.error("Unknown Exception", e);
      ErrorItemFactory factory = ErrorItemFactory.getErrorItemFactory();
      ErrorItem error = factory.generateErrorItem("Unknown exception - see log", 10001, getClass());
      throw new ValidateException(true, e, error);
    }
    logger.debug("END validateData of " + getClass().getSimpleName());
  }
  
  /**
   * Test to insure performer names in SDRF are listed among contacts in IDF
   * @param idf - Needed to collect Contacts
   * @param sdrf - Needed to collect Performers
   * @throws Exception - Code 6001
   * SOP 19. Names listed under Performer in the SDRF should be contacts listed in the IDF. 
   */
  protected void validateContactPerformerMatch(IDF idf, SDRF sdrf) throws AppException {
    Set<String> contactNames = Contact.getContactNames(idf);
    logger.trace("Contact names against which to validate performer names: " + contactNames);
    Set<String> performerNames = ProtocolApplication.getPerformerNames(sdrf);
    logger.trace("Performer names to be validated: " + performerNames);
    if(!contactNames.containsAll(performerNames)) {
      performerNames.removeAll(contactNames);
      throw new AppException("Missing contact(s): " + performerNames.toString(), 6001);
    }
  }
  
  /**
   * Test to insure protocol references in SDRF are listed among protocol names in IDF
   * @param idf
   * @param sdrf
   * @throws AppException
   */
  protected void validateProtocolMatch(IDF idf, SDRF sdrf) throws AppException {
    Set<String> protocolNames = Protocol.getProtocolNames(idf);
    logger.trace("Protocol names against which to validate protocol references: " + protocolNames);
    Set<String> protocolRefs = new HashSet<>();
    Collection<? extends ProtocolApplicationNode> nodes = sdrf.getNodes(ProtocolApplicationNode.class);
    for(ProtocolApplicationNode node : nodes) {
      if(StringUtils.isNotEmpty(node.protocol)) {
        protocolRefs.add(AppUtils.removeTokens(node.protocol));
      }
    }
    logger.trace("Protocol references to be validated: " + protocolRefs);
    if(!protocolNames.containsAll(protocolRefs)) {
      protocolRefs.removeAll(protocolNames);
      String missing = Arrays.asList(protocolRefs.toArray()).toString();
      throw new AppException("Missing protocols - " + missing, 6002);
    }
  }
  
  /**
   * Test to insure protocol reference parameters in SDRF are listed as parameters
   * to the corresponding protocol in IDF.
   * @param idf - needed to collect protocols
   * @param sdrf - needed to collect protocol references
   * @throws AppException - Code 6003
   */
  protected void validateProtocolParameterMatch(IDF idf, SDRF sdrf) throws AppException {
    Map<String,List<ProtocolApplicationNode>> sdrfMap = ProtocolApplication.createProtocolNodeMap(sdrf);
    Map<String,Set<String>> idfMap = ProtocolParam.createParameterNameMap(idf);
    Set<String> protocolNameSet = sdrfMap.keySet();
    Iterator<String> protocolIterator = protocolNameSet.iterator();
    while(protocolIterator.hasNext()) {
      String key = protocolIterator.next();
      Set<String> parameterNames = idfMap.get(key);
      // Cheat to avoid having to add this artificial parameter to the protocols for which it is
      // used in the SDRF.
      if(parameterNames == null) {
        parameterNames = new HashSet<String>();
      }
      parameterNames.add("cbil_run");
      logger.trace("IDF parameter Names for protocol " + key + ": " + parameterNames);
      List<ProtocolApplicationNode> protocolNodes = sdrfMap.get(key);
      for(ProtocolApplicationNode node : protocolNodes) {
        List<ParameterValueAttribute> params = node.parameterValues;
        for(ParameterValueAttribute param : params) {
          logger.trace("SDRF param: " + param.type); 
          if(!parameterNames.contains(param.type)) {
            throw new AppException("Offending parameter - " + param.type, 6003);
          }
        }
      }
    }
  }
  
  /**
   * Test to insure that the MAGE-TAB has an assay name node in the sdrf.
   * @param sdrf - needed to collect nodes to test
   * @throws AppException - Code 6005
   */
  protected void validateAssayName(SDRF sdrf) throws AppException {
    Collection<? extends SDRFNode> nodes = sdrf.getAllNodes();
    boolean foundAssayName = false;
    for(SDRFNode node : nodes) {
     if(ProtocolApplicationIONode.ASSAY_NAME.equals(node.getNodeType())) {
       foundAssayName = true;
       break;
      }
    }
    if(!foundAssayName) {
      throw new AppException(6005);
    }
  }

}


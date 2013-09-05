package edu.upenn.cbil.limpopo.validate;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import net.sourceforge.fluxion.spi.ServiceProvider;

import org.apache.commons.lang.StringUtils;
import org.mged.magetab.error.ErrorItem;
import org.mged.magetab.error.ErrorItemFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;
import uk.ac.ebi.arrayexpress2.magetab.exception.ValidateException;
import uk.ac.ebi.arrayexpress2.magetab.handler.idf.IDFValidateHandler;
import uk.ac.ebi.arrayexpress2.magetab.handler.listener.HandlerListener;
import edu.upenn.cbil.limpopo.model.Protocol;
import edu.upenn.cbil.limpopo.model.ProtocolParam;
import edu.upenn.cbil.limpopo.utils.AppException;
import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.limpopo.utils.ListUtils;

@ServiceProvider
public class ProtocolValidator extends IDFValidateHandler {
  public static Logger logger = LoggerFactory.getLogger(ProtocolValidator.class);
  public static HandlerListener listener;
  
  public ProtocolValidator() {
    listener = new ValidateHandlerListener();
    this.addListener(listener);
  }

  @Override
  protected boolean canValidateData(IDF data) {
	logger.debug("Inside canValidateData of " + getClass().getSimpleName());
    return true;
  }

  /**
   * Some protocol-related validations
   * SOP 10. Protocol Name must be non-empty for every protocol.
   * SOP 11. Comment [Is Private Protocol] should have values 0 or 1.
   * Policy 1. If an element contains a non-empty value for a source_id element,
   *           it must also contain a non-empty value for the corresponding
   *           external_database_release_id element and conversely. 
   * SOP 12. If Comment [Parameter DataType] is non-empty then Comment
   *         [Parameter DataTypeExtDbRls] must be non-empty.
   * SOP 13. If Comment [Parameter UnitType] is non-empty then Comment
   *         [Parameter UnitTypeExtDbRls] must be non-empty.
   * SOP 14. Comment [Parameter Is User Specified] should have values 0 or 1. 
   */
  @Override
  protected void validateData(IDF data) throws ValidateException {
    logger.debug("START validateData of " + getClass().getSimpleName());
    try {
      if(data.protocolName.size() < Protocol.longestAttribute(data)) {
        throw new AppException(4001);
      }
      Map<String,List<String>> comments = Protocol.getComments();
      int limit = data.protocolName.size();
      for(int i = 0; i < limit; i++) {
        String isPrivate = AppUtils.stripAdditionToken(ListUtils.get(comments.get(Protocol.PRIVATE_COMMENT), i));
        if(StringUtils.isEmpty(isPrivate)) {
          throw new AppException(4002);
        }
        else if(!isPrivate.matches("^0|1$")) {
          throw new AppException("Problem Value = " + isPrivate, 4003);
        }
        String extDBRelease = ListUtils.get(comments.get(Protocol.EXT_DB_RLS_COMMENT), i);
        String sourceId = ListUtils.get(comments.get(Protocol.SOURCE_ID_COMMENT), i);
        if(StringUtils.isEmpty(sourceId) && StringUtils.isNotEmpty(extDBRelease) ||
           StringUtils.isNotEmpty(sourceId) && StringUtils.isEmpty(extDBRelease)) {
          throw new AppException("External DB Release = " + extDBRelease + " and Source Id = " + sourceId, 4004);
        }
        if(!data.protocolParameters.isEmpty()
            && !StringUtils.isEmpty(ListUtils.get(data.protocolParameters, i))) {
          List<String> parameterNameList = Arrays.asList(data.protocolParameters.get(i).split(";"));
          List<String> dataTypeNames = ProtocolParam.createSublistFromCommentByIndex(ProtocolParam.DATA_TYPE_COMMENT, data, i);
          List<String> dataTypeRefs =  ProtocolParam.createSublistFromCommentByIndex(ProtocolParam.DATA_TYPE_DB_RLS_COMMENT, data, i);
          List<String> unitTypeNames = ProtocolParam.createSublistFromCommentByIndex(ProtocolParam.UNIT_TYPE_COMMENT, data, i);
          List<String> unitTypeRefs =  ProtocolParam.createSublistFromCommentByIndex(ProtocolParam.UNIT_TYPE_DB_RLS_COMMENT, data, i);
          List<String> userSpecifieds = ProtocolParam.createSublistFromCommentByIndex(ProtocolParam.IS_USER_SPECIFIED_COMMENT, data, i);
          if(dataTypeNames.size() != dataTypeRefs.size()) {
            throw new AppException(5001);
          }
          for(int j = 0; j < dataTypeNames.size(); j++) {
            if(StringUtils.isEmpty(dataTypeNames.get(j)) && StringUtils.isNotEmpty(dataTypeRefs.get(j)) ||
               StringUtils.isNotEmpty(dataTypeNames.get(j)) && StringUtils.isEmpty(dataTypeRefs.get(j))) {
              throw new AppException(5001);
            }
          }
          if(unitTypeNames.size() != unitTypeRefs.size()) {
            throw new AppException(5002);
          }
          for(int j = 0; j < unitTypeNames.size(); j++) {
            if(StringUtils.isEmpty(unitTypeNames.get(j)) && StringUtils.isNotEmpty(unitTypeRefs.get(j)) ||
                StringUtils.isNotEmpty(unitTypeNames.get(j)) && StringUtils.isEmpty(unitTypeRefs.get(j))) {
               throw new AppException(5002);
            }
          }
          if(userSpecifieds.size() != parameterNameList.size()) {
            throw new AppException(5003);
          }
          for(int j = 0; j < parameterNameList.size(); j++) {
            if(!userSpecifieds.get(j).matches("^0|1$")) {
              throw new AppException("Problem Value = " + userSpecifieds.get(j), 5004);
            }
          }
        }
      }
    }
    catch (AppException ae) {
      ErrorItemFactory factory = ErrorItemFactory.getErrorItemFactory();
      ErrorItem error = factory.generateErrorItem(ae.getMessage(), ae.getCode(), this.getClass());
      throw new ValidateException(true, ae, error);
    }
    catch (Exception e) {
      logger.error("Unknown Exception", e);
      ErrorItemFactory factory = ErrorItemFactory.getErrorItemFactory();
      ErrorItem error = factory.generateErrorItem("Unknown exception - see log", 10001, this.getClass());
      throw new ValidateException(true, e, error);
    }
    logger.debug("END validateData of " + getClass().getSimpleName());
  }
}
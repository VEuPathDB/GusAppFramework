package edu.upenn.cbil.limpopo.model;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;
import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.limpopo.utils.ListUtils;

public class ProtocolParam {
  public static Logger logger = LoggerFactory.getLogger(ProtocolParam.class);
  private boolean addition;
  private String name;
  private OntologyTerm dataType;
  private OntologyTerm unitType;
  private String defaultValue;
  private String userSpecified;
  public static final String DATA_TYPE_COMMENT = "Parameter DataType";
  public static final String DATA_TYPE_DB_RLS_COMMENT = "Parameter DataTypeExtDbRls";
  public static final String UNIT_TYPE_COMMENT = "Parameter UnitType";
  public static final String UNIT_TYPE_DB_RLS_COMMENT = "Parameter UnitTypeExtDbRls";
  public static final String DEFAULT_VALUE_COMMENT = "Parameter Default Value";
  public static final String IS_USER_SPECIFIED_COMMENT = "Parameter Is User Specified";
  
  public ProtocolParam() {
    this.addition = false;
  }
  
  public final boolean isAddition() {
    return addition;
  }
  public void setAddition(boolean addition) {
    this.addition = addition;
  }
  public String getName() {
	return name;
  }
  public void setName(String name) {
    this.name = AppUtils.removeTokens(name);
  }
  public OntologyTerm getDataType() {
	return dataType;
  }
  public void setDataType(OntologyTerm dataType) {
	this.dataType = dataType;
  }
  public OntologyTerm getUnitType() {
	return unitType;
 }
  public void setUnitType(OntologyTerm unitType) {
	this.unitType = unitType;
  }
  public String getDefaultValue() {
	return defaultValue;
  }
  public void setDefaultValue(String defaultValue) {
	this.defaultValue = AppUtils.removeTokens(defaultValue);
  }
  public String getUserSpecified() {
	return userSpecified;
  }
  public void setUserSpecified(String userSpecified) {
	this.userSpecified = AppUtils.removeTokens(userSpecified);
  }
  
  public String toString() {
	return ReflectionToStringBuilder.toString(this);
  }
  
  /**
   * Convenience method to obtain a comment list based upon the comment name (key) and, assuming
   * a comment exists at the designated field (index) position, further subdivide the selected
   * comment into a sublist using a semicolon as a delimiter.  If no comment exists at the index
   * position, an empty list is returned. 
   * @param name - the name of the IDF comment
   * @param data - the IDF data
   * @param index - the location within the set of tab separated fields
   * @return - the list of values for the given named IDF comment at the given field location
   */
  public static List<String> createSublistFromCommentByIndex(String name, IDF data, int index) {
	List<String> sublist = new ArrayList<String>();
	List<String> commentList = OrderedComment.retrieveComments(name, data);
	if(commentList.size() > index) {
	  // Strip add/id tokens if present
	  String filtered = AppUtils.removeTokens(commentList.get(index));
	  sublist = Arrays.asList(filtered.split(";"));
	}
	return sublist;
  }
  
  /**
   * Assembles a map relating IDF parameters to their parent IDF protocol for use in
   * validation.  Addition/id tokens are filtered out.
   * @param data - IDF data
   * @return - map relating each IDF protocol to a set of IDF parameters
   */
  public static Map<String, Set<String>> createParameterNameMap(final IDF data) {
    Map<String, Set<String>> map = new HashMap<>();
    Iterator<String> iterator = data.protocolName.iterator();
    for(int i = 0; iterator.hasNext(); i++) {
      String protocolName = AppUtils.removeTokens(iterator.next());
      if(!data.protocolParameters.isEmpty()
        && StringUtils.isNotEmpty(ListUtils.get(data.protocolParameters, i))) {
        Set<String> parameterNames = new HashSet<String>();
        // Strip add/id tokens if present
        String filtered = AppUtils.removeTokens(data.protocolParameters.get(i));
        parameterNames.addAll(Arrays.asList(filtered.split(";")));
        map.put(protocolName, parameterNames);
      }
    }
    return map;
  }
  
  public static List<ProtocolParam> populate(IDF data, int index) throws ConversionException {
	logger.debug("START: Populating Protocol Params");
	List<String> dataTypeNames = createSublistFromCommentByIndex(DATA_TYPE_COMMENT, data, index);
	List<String> dataTypeRefs =  createSublistFromCommentByIndex(DATA_TYPE_DB_RLS_COMMENT, data, index);
	List<String> unitTypeNames =  createSublistFromCommentByIndex(UNIT_TYPE_COMMENT, data, index);
	List<String> unitTypeRefs =  createSublistFromCommentByIndex(UNIT_TYPE_DB_RLS_COMMENT, data, index);
	List<String> defaultValues = createSublistFromCommentByIndex(DEFAULT_VALUE_COMMENT, data, index);
	List<String> userSpecifieds = createSublistFromCommentByIndex(IS_USER_SPECIFIED_COMMENT, data, index);
	    
	List<ProtocolParam> parameters = new ArrayList<>();
	if(!data.protocolParameters.isEmpty()
	    && !StringUtils.isEmpty(ListUtils.get(data.protocolParameters, index))) {
	  List<String> parameterNameList = Arrays.asList(data.protocolParameters.get(index).split(";"));
	  Iterator<String> iterator = parameterNameList.iterator();
	  for(int i = 0; iterator.hasNext(); i++) {
	    String name = iterator.next();
	    ProtocolParam parameter = new ProtocolParam();
	    parameter.setAddition(AppUtils.checkForInternalAddition(name));
	    parameter.setName(name);
	    parameter.setDataType(new OntologyTerm(ListUtils.get(dataTypeNames, i), ListUtils.get(dataTypeRefs, i)));
	    parameter.setUnitType(new OntologyTerm(ListUtils.get(unitTypeNames, i), ListUtils.get(unitTypeRefs, i)));
	    parameter.setDefaultValue(ListUtils.get(defaultValues, i));
	    parameter.setUserSpecified(ListUtils.get(userSpecifieds, i));
	    parameters.add(parameter);
	  }
	}
	logger.debug("END: Populating Protocol Params");
	return parameters;
  }
  
}

package edu.upenn.cbil.limpopo.utils;

import java.io.File;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class AppUtils {
  public static Logger logger = LoggerFactory.getLogger(AppUtils.class);
  
  /**
   * Separators and Tokens
   */
  public static final String NODE_SEPARATOR = "_";
  public static final String ADDED_CELL = "<<add>>";
  public static final String ID_TOKEN = "<id=(.+)>";
  public static final String ADDED_WITHIN_CELL_TOKEN = "<<<(.+)>>>";
  
  /**
   * Schema File - assumes it to be in the parent directory.
   */
  public static final String SCHEMA_FILE = ".." + File.separator + "output.xsd";
  public static final String SCHEMA_LOCATION = "noNamespaceSchemaLocation";
  public static final String SCHEMA_INSTANCE_URI = "http://www.w3.org/2001/XMLSchema-instance";
  public static final String SCHEMA_INSTANCE_PREFIX = "xsi";
  
  /**
   * IDF Tags
   */
  public static final String MAGE_TAB_TAG = "mage-tab";
  public static final String IDF_TAG = "idf";
  public static final String STUDY_TAG = "study";
  public static final String PUBMED_IDS_TAG = "pubmed_ids";
  public static final String SOURCE_ID_TAG = "source_id";
  public static final String GOAL_TAG = "goal";
  public static final String APPROACHES_TAG = "approaches";
  public static final String RESULTS_TAG = "results";
  public static final String CONCLUSIONS_TAG = "conclusions";
  public static final String RELATED_STUDIES_TAG = "related_studies";
  public static final String CHILD_STUDIES_TAG = "child_studies";
  public static final String STUDY_DESIGN_TAG = "study_design";
  public static final String TYPE_EXT_DB_RLS_TAG = "type_ext_db_rls";
  public static final String STUDY_FACTOR_TAG = "study_factor";
  public static final String FIRST_NAME_TAG = "first_name";
  public static final String LAST_NAME_TAG = "last_name";
  public static final String EMAIL_TAG = "email";
  public static final String PHONE_TAG = "phone";
  public static final String FAX_TAG = "fax";
  public static final String ADDRESS1_TAG = "address1";
  public static final String ADDRESS2_TAG = "address2";
  public static final String CITY_TAG = "city";
  public static final String STATE_TAG = "state";
  public static final String COUNTRY_TAG = "country";
  public static final String ZIP_CODE_TAG = "zip_code";
  public static final String AFFILIATION_TAG = "affiliation";
  public static final String ROLES_TAG = "roles";
  public static final String ROLES_EXT_DB_RLS_TAG = "roles_ext_db_rls";
  public static final String PUBMED_ID_TAG = "pubmed_id";
  public static final String ACCESSIBILITY_TAG = "other_read";
  public static final String PROTOCOL_PARAMETERS_TAG = "protocol_parameters";
  public static final String PARAM_TAG = "param";
  public static final String DATA_TYPE_TAG = "data_type";
  public static final String DATA_TYPE_EXT_DB_RLS_TAG = "data_type_ext_db_rls";
  public static final String DEFAULT_VALUE_TAG = "default_value";
  public static final String IS_USER_SPECIFIED_TAG = "is_user_specified";
  public static final String CHILD_PROTOCOLS_TAG = "child_protocols";
  
  /**
   * SRDF Tags
   */
  public static final String SDRF_TAG = "sdrf";
  public static final String PROTOCOL_APP_NODE_TAG = "protocol_app_node";
  public static final String ID_ATTR = "id";
  public static final String TAXON_TAG = "taxon";
  public static final String CONTACTS_TAG = "contacts";
  public static final String ROLE_TAG = "role";
  public static final String PROTOCOL_APP_TAG = "protocol_app";
  public static final String PROTOCOL_APP_DATE_TAG = "protocol_app_date";
  public static final String PROTOCOL_APP_PARAMETERS_TAG = "protocol_app_parameters";
  public static final String PROTOCOL_APP_PARAMETER_TAG = "app_param";  
  public static final String STEP_ATTR = "step";
  public static final String INPUT_TAG = "input";
  public static final String OUTPUT_TAG = "output";
  public static final String NODE_CHARACTERISTICS_TAG = "node_characteristics";
  public static final String CHARACTERISTIC_TAG = "characteristic";
  public static final String ONTOLOGY_TERM_TAG = "ontology_term";
  public static final String CATEGORY_ATTR = "category";
  public static final String TABLE_TAG = "table";
  public static final String ROW_TAG = "row_id";
  public static final String FACTOR_VALUES_TAG = "factor_values";
  public static final String FACTOR_VALUE_TAG = "factor_value";
  
  
  /**
   * Community Tags
   */
  public static final String NAME_TAG = "name";
  public static final String TYPE_TAG = "type";
  public static final String VALUE_TAG = "value";
  public static final String DESCRIPTION_TAG = "description";
  public static final String URI_TAG = "uri";
  public static final String PROTOCOL_TAG = "protocol";
  public static final String CONTACT_TAG = "contact";
  public static final String EXTERNAL_DATABASE_RELEASE_TAG = "external_database_release";
  public static final String UNIT_TYPE_TAG = "unit_type";
  public static final String UNIT_TYPE_EXT_DB_RLS_TAG = "unit_type_ext_db_rls";
  public static final String ADDITION_ATTR = "addition";
  public static final String DBID_ATTR = "db_id";
  
  /**
   * Logging
   */
  public static final String INFO_NO_ID_FOUND = "No id was found: ";
  
  /**
   * Flags
   */
  public static final String TRUE = "true";

  /**
   * Removes the first ADDED_CELL (e.g., <<add>>) token from the provided string
   * @param str - string to be scrubbed
   * @return - string scrubbed of ADDED_CELL token, if any
   */
  public static String stripAdditionToken(String str) {
    String filtered = str;
    if(str != null) {
      filtered = str.replaceFirst(ADDED_CELL, "");
    }
    return filtered;
  }
  
  /**
   * Pulls out any MAGE-TAB value embedded within a ADDED_WITHIN_CELL_TOKEN from the provided
   * string.  Assumes only one token maximum per string.
   * @param str - string containing a MAGE-TAB value, possibly embedded inside a token identifying
   * it as an addition internal to the cell.
   * @return - the MAGE-TAB value with embedded token removed.
   */
  public static String filterInternalAdditionToken(String str) {
    String filtered = str;
    if(StringUtils.isNotEmpty(str)) {
      filtered = str.replaceFirst("^.*" + ADDED_WITHIN_CELL_TOKEN + ".*$", "$1");
    }
    return filtered;
  }
  
  public static String stripInternalAdditionTokens(String str) {
    String stripped = str;
    if(StringUtils.isNotEmpty(str)) {
      stripped = str.replaceAll(ADDED_WITHIN_CELL_TOKEN, "$1");
    }
    return stripped;
  }
  
  
  /**
   * Removes any id token (e.g., <id="(.+)">) from the provided string.  At most, there will be one.
   * @param str - string to be scrubbed
   * @return - string scrubbed of all ID_TOKEN tokens, if any.
   */
  public static String stripIdToken(String str) {
    String filtered = str;
    if(str != null) {
      filtered = str.replaceAll(ID_TOKEN, "");
    }
    return filtered;
  }
  
  public static String filterIdToken(String str) {
    String id = "";
    if(StringUtils.isNotEmpty(str)) {
      id = str.replaceAll("^.*" + ID_TOKEN + ".*$", "$1");
      if(str.equals(id)) {
        id = "";
      }
    }
    return id;
  }
  
  public static Set<String> stripAdditionTokens(Set<String> set) {
    Set<String> filteredSet = new HashSet<>();
    for(String item : set) {
      filteredSet.add(stripAdditionToken(item));
    }
    return filteredSet;
  }
  
  
  /**
   * Removes all addition and/or id tokens from the provided string
   * @param str - the string to be scrubbed of tokens
   * @return - the filtered string.
   */
  public static String removeTokens(String str) {
    String stripped = str;
    if(StringUtils.isNotEmpty(str)) {
      stripped = stripIdToken(stripAdditionToken(stripInternalAdditionTokens(str))).trim();
    }
    return stripped;
  }
  
  
  /**
   * Removes add addition and/or id tokens from the values of the provided map
   * @param map - map containing the values to be filtered
   * @return - map containing the filtered values
   */
  public static Map<String,String> removeTokens(Map<String,String> map) {
    Map<String,String> filteredMap = new LinkedHashMap<>();
    Set<String> keys = map.keySet();
    for(String key : keys) {
      filteredMap.put(key, removeTokens(map.get(key)));
    }
    return filteredMap;
  }
  
  /**
   * Compares the provided string against the same string scrubbed of any tokens.
   * @param str - string to be tested
   * @return - true if tokens are present, false otherwise.
   */
  public static boolean checkForAddition(String str) {
    boolean addition = false;
    String filtered = str;
    if(str != null) {
      filtered = AppUtils.stripAdditionToken(str);
      if(!str.equals(filtered)) {
        addition = true;
      }
    }
    return addition;
  }
  
  public static boolean checkForInternalAddition(String str) {
    boolean addition = false;
    String filtered = str;
    if(str != null) {
      filtered = AppUtils.stripInternalAdditionTokens(str);
      if(!str.equals(filtered)) {
        addition = true;
      }
    }
    return addition;
  }

}

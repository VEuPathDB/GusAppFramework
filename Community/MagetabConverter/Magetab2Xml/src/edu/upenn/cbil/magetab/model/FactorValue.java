package edu.upenn.cbil.magetab.model;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;

import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.magetab.utilities.ApplicationException;

/**
 * The specification for the MAGE-TAB Factor Value runs counter to our use of Factor Value.  Rather
 * than alter Limpopo behavior through handlers to violate the specification, we have opted to
 * handle factor values externally.  MAGE-TAB Factor Values do not have comment fields.  Ours
 * can. 
 * @author Cris Lawrence
 *
 */
public class FactorValue {
  private Integer row;
  private Integer col;
  private String key;
  private String value;
  private String table;
  private String rowId;
  public static final String FACTOR_VALUE = "factorvalue";
  public static final String FACTOR_VALUE_PATTERN = "factor\\s*value\\s*\\[(.*)\\]";
  public static final String COMMENT_PATTERN = "comment\\s*\\[(.*)\\]";
  public static final String FV_TABLE = "Comment [FV Table]";
  public static final String FV_ROW = "Comment [FV Row Id]";
 
  /**
   * For use in matching factor values with the appropriate protocol application nodes in the xml output.
   * @return - the input spreadsheet row containing this factor value
   */
  public Integer getRow() {
	return row;
  }
  
  /**
   * Returns the column in which the factor value's key/value appear in the Excel spreadsheet.
   * @return - the input spreadsheet column containg this factor value key/value
   */
  public Integer getCol() {
	return col;
  }
  
  /**
   * The key to which the factor value data refers.
   * @return - content originally within the Factor Value brackets.
   */
  public String getKey() {
	return key;
  }
  
  /**
   * Sets the factor value key and removes any addition tokens
   * @param key - raw key
   */
  public final void setKey(String key) {
    this.key = AppUtils.removeTokens(key);
  }

  /**
   * The value of this Factor Value.
   * @return - filtered factor value.
   */
  public String getValue() {
	return value;
  }
  
  /**
   * Sets the factor value value and removes any addition tokens.  If an addition token exists, the factor value addition flag is set.
   * @param value - raw value
   */
  public final void setValue(String value) {
    this.value = AppUtils.removeTokens(value);
  }

  /**
   * Comment [FV Table] header.  For use in assembling factor value data string.
   * @return - optional table.
   */
  public String getTable() {
	return table;
  }
  
  /**
   * Sets the factor value table, if any, and removes any addition tokens
   * @param table - raw table
   */
  public final void setTable(String table) {
    this.table = AppUtils.removeTokens(table);
  }

  /**
   * Comment [FV Row Id] header.  For use in assembling factor value data string.
   * @return - optional filtered row id.
   */
  public String getRowId() {
	return rowId;
  }
  
  /**
   * Sets the factor value row id, if any, and reomves any addition tokens
   * @param rowId - raw row id
   */
  public final void setRowId(String rowId) {
    this.rowId = AppUtils.removeTokens(rowId);
  }

  /**
   * return a complete representation of the factor value using
   * ReflectionToStringBuilder for debugging purposes. 
   */
  @Override
  public String toString() {
    return (new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE) {
      protected boolean accept(Field field) {
        return super.accept(field);
      }
   }).toString();
  }
    
  /**
   * A single line of factor value data is parsed using the heading information and the
   * row number in the input document containing the data.  More than one factor value
   * object may be returned.
   * A runtime exception is thrown if a factor value column in invalid or invalid, given its
   * location or if table / row id data are not present in pairs.
   * SOP 17.  For each Experimental Factor in the IDF, at least one of FactorValue [] and the pair
   *          (Comment [FV Table], Comment [FV Row Id]) must have a value. 
   * @param heading - string representing header information for all factor value data for this MAGE-TAB
   * @param data - string representing data for all factor value data for a given row.
   * @param row - the spreadsheet / text document row containing the above factor value data.
   * @return - A list of factor value objects generated from parsing the given row data.
   */
  public static List<FactorValue> parseFactorValues(String heading, String data, int row) {
	List<FactorValue> factorValues = new ArrayList<>();
	String[] headers = heading.split("\t");
	String[] values = data.split("\t");
	for(int i = 0; i < headers.length; i++) {
      if(FactorValue.isExpectedHeader(headers[i], FACTOR_VALUE_PATTERN)) {
    	FactorValue factorValue = new FactorValue();
        factorValue.setKey(FactorValue.getExpectedHeaderContent(headers[i], FACTOR_VALUE_PATTERN));
        if(i < values.length) {
          factorValue.setValue(values[i]);
        }
        factorValue.row = row;
        factorValue.col = i;
        /* 
         * SOP 17. If Comment [FV Row Id] has a value Comment [FV Table]) must have a value
         * and conversely. Moreover FactorValue must be populated. 
         */
        if(headers.length > i + 2 && values.length > i + 2) {
          if(headers[i + 1].startsWith(FV_TABLE) && headers[i + 2].startsWith(FV_ROW)) {
        	factorValue.setTable(values[i + 1].trim());
        	factorValue.setRowId(values[i + 2].trim());
        	if((StringUtils.isNotEmpty(factorValue.getTable()) && StringUtils.isEmpty(factorValue.getRowId())) ||
        	   (StringUtils.isEmpty(factorValue.getTable()) && StringUtils.isNotEmpty(factorValue.getRowId()))) {
        	  throw new ApplicationException("Factor value table / row id must occur in pairs : offending row - " + row);
        	}
        	i += 2;
          }
          else if(!FactorValue.isExpectedHeader(headers[i + 1], FACTOR_VALUE_PATTERN)) {
            System.err.println("Warning:  Bad factor value column or missing factor value table or row column: " + headers[i + 1]);
          }
        }
        factorValues.add(factorValue);
      }
	}
	Collections.sort(factorValues, new FactorValueComparator());
	return factorValues;
  }
  
  public static boolean isExpectedHeader(String header, String headerPattern) {
	Pattern pattern = Pattern.compile(headerPattern, Pattern.CASE_INSENSITIVE);
	Matcher matcher = pattern.matcher(header);
	return matcher.find();
  }
  
  public static String getExpectedHeaderContent(String header, String headerPattern) {
	String content = "";
    Pattern pattern = Pattern.compile(headerPattern, Pattern.CASE_INSENSITIVE);
	Matcher matcher = pattern.matcher(header);
	if(matcher.find()) {
	  content = matcher.group(1);
	}
    return content;
  }
  
}

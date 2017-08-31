package edu.upenn.cbil.limpopo.model;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;

import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.limpopo.utils.SDRFUtils;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.attribute.CharacteristicsAttribute;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.attribute.MaterialTypeAttribute;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;

/**
 * Represents a slightly different definition of characteristic than the one applied in a 
 * MAGE-TAB SDRF.  Characteristics here include typical MAGE-TAB characteristics with the
 * exception of the organism and any material type.
 * @author Cris Lawrence
 *
 */
public class Characteristic {
  private String category;
  private OntologyTerm term;
  private String termAccessionNumber;
  private String value;
  
  
  /**
   * Retrieves a string representing either the heading of a characteristic, the heading of
   * a material type, or if the characteristic value is qualified by a unit type; the
   * concatenation (with a pipe delimiter) of the characteristic heading and the unit type
   * heading.
   * @return - category string
   */
  public String getCategory() {
    return category;
  }
  
  /**
   * Sets the category described under getCategory()
   * @param category - the string to be saved.
   */
  public void setCategory(String category) {
    this.category = category;
  }

  /**
   * Present if a term source ref qualifies a characteristic or material type or a unit type
   * @return - the ontology term representing the term source ref.
   */
  public OntologyTerm getTerm() {
    return term;
  }

  public void setTerm(OntologyTerm term) {
    this.term = term;
  }

  /**
   * Term Accession Number is saved but not currently used.
   * @return - term accession number related to the characteristic.
   */
  public String getTermAccessionNumber() {
    return termAccessionNumber;
  }

  public void setTermAccessionNumber(String termAccessionNumber) {
    this.termAccessionNumber = AppUtils.removeTokens(termAccessionNumber);
  }

  public String getValue() {
    return value;
  }

  public void setValue(String value) {
    this.value = AppUtils.removeTokens(value);
  }

  /**
   * Empty constructor used to guarantee a stable base state.
   */
  public Characteristic() {
    value = "";
    category = "";
    termAccessionNumber = "";
  }
  
  public Characteristic(CharacteristicsAttribute trait) throws ConversionException {
    this();
    // Letting any TermAccessionNumber for unit fall on the floor.
    if(trait.unit != null) {
      category = SDRFUtils.parseHeader(trait.getAttributeType()) + "|" + SDRFUtils.parseHeader(trait.unit.getAttributeType());
      term = new OntologyTerm(SDRFUtils.parseHeader(trait.unit.getAttributeValue()), trait.unit.termSourceREF);
      setValue(trait.getAttributeValue());
    }
    else if(StringUtils.isEmpty(trait.termSourceREF)) {
      category = SDRFUtils.parseHeader(trait.getAttributeType());
      setValue(trait.getAttributeValue());
    }
    else {
      category = SDRFUtils.parseHeader(trait.getAttributeType());
      term = new OntologyTerm(trait.getAttributeValue(), trait.termSourceREF);
    }
    setTermAccessionNumber(trait.termAccessionNumber);
  }
  
  public Characteristic(MaterialTypeAttribute material) throws ConversionException {
    this();
    if(material != null) {
      if(StringUtils.isEmpty(material.termSourceREF)) {
        category = SDRFUtils.parseHeader(material.getAttributeType());
        setValue(material.getAttributeValue());
      }
      else {
        category = SDRFUtils.parseHeader(material.getAttributeType());
        term = new OntologyTerm(material.getAttributeValue(), material.termSourceREF);
      }
    }
  }
  
  @Override
  public String toString() {
    return new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE).toString();
  }

}

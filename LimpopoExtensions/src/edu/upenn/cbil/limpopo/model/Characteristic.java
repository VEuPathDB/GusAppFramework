package edu.upenn.cbil.limpopo.model;

import java.lang.reflect.Field;
import java.util.List;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.attribute.CharacteristicsAttribute;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.attribute.MaterialTypeAttribute;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;
import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.limpopo.utils.SDRFUtils;

public class Characteristic {
  private String category;
  private OntologyTerm term;
  private String termAccessionNumber;
  private String taxon;
  private String value;
  public final static String ORGANISM = "organism";
  
  public String getCategory() {
    return category;
  }

  public void setCategory(String category) {
    this.category = category;
  }

  public OntologyTerm getTerm() {
    return term;
  }

  public void setTerm(OntologyTerm term) {
    this.term = term;
  }

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

  public String getTaxon() {
    return taxon;
  }

  public void setTaxon(String taxon) {
    this.taxon = AppUtils.removeTokens(taxon);
  }
  
  public Characteristic() {
    taxon = "";
    value = "";
    category = "";
    termAccessionNumber = "";
  }
  
  public boolean isEmpty() {
    return StringUtils.isEmpty(value) && StringUtils.isEmpty(category);
  }

  public Characteristic(CharacteristicsAttribute trait) throws ConversionException {
    this();
    if(ORGANISM.equalsIgnoreCase(SDRFUtils.parseHeader(trait.getAttributeType()))) {
      setTaxon(trait.getAttributeValue());
    }
    // Letting any TermAccessionNumber for unit fall on the floor.
    else if(trait.unit != null) {
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
  
  public static String fetchTaxon(List<Characteristic> characteristics) {
    String taxon = "";
    for(Characteristic characteristic : characteristics) {
      if(StringUtils.isNotEmpty(characteristic.getTaxon())) {
        taxon = characteristic.getTaxon();
        break;
      }
    }
    return taxon;
  }
  
  @Override
  public String toString() {
    return (new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE) {
      protected boolean accept(Field field) {
        return super.accept(field);
      }
    }).toString();
  }

}

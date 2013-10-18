package edu.upenn.cbil.limpopo.model;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;
import org.mged.magetab.error.ErrorItem;
import org.mged.magetab.error.ErrorItemFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.upenn.cbil.limpopo.utils.AppUtils;

import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;

/**
 * Ontology term takes a term name and a term reference, finds the equivalent reference in a provided list of external databases, and stores an
 * external database release entity which combines the reference and the external database version for that reference.  Before any ontology
 * term is created, an external database map must be populated.
 * @author Cris Lawrence
 *
 */
public class OntologyTerm {
  public static Logger logger = LoggerFactory.getLogger(OntologyTerm.class);
  private String name;
  private String category;
  private String externalDatabaseRelease;
 
  /**
   * If the term name and term reference are both empty strings, a new ontology term is created with all fields set to empty strings.
   * This is intended as a aid to avoiding NPEs.
   * @param name - The name of the ontology term
   * @param ref - A handle to the external database
   * @throws ConversionException - under two conditions.  Either the external database map needed to successfully compile the ontology term
   * has not been populated or the reference for the term cannot be found in the current external database map.  The program running
   * the conversion should have an error listener attached to the conversion.
   */
  public OntologyTerm(String name, String ref) throws ConversionException {
    category = "";
    try {
	  if(ExternalDatabase.map == null) {
	    throw new Exception("1101");
	  }
      this.name = AppUtils.removeTokens(StringUtils.defaultString(name));
      ref = AppUtils.removeTokens(StringUtils.defaultString(ref));
      this.externalDatabaseRelease = "";
      logger.trace("Term(s) name: " + name + " , Term(s) ref: " + ref);
      if(StringUtils.isNotEmpty(name)) {
        List<String> releases = new ArrayList<>();
        String[] refs = ref.split(";");
        for(String reference : refs) {
          if(!ExternalDatabase.map.containsKey(reference)) {
            throw new Exception("1102:Name = " + name + " Reference = " + reference);
          }
          releases.add(ExternalDatabase.map.get(reference).getRelease());
        } 
        externalDatabaseRelease = StringUtils.join(releases, ";");
      }
    }
    catch (Exception e) {
      ErrorItemFactory factory = ErrorItemFactory.getErrorItemFactory();
      String msg = e.getMessage().split(":").length > 1 ? e.getMessage().split(":")[1] : e.getMessage();
      ErrorItem error = factory.generateErrorItem(msg, Integer.valueOf(e.getMessage().split(":")[0]), this.getClass());
      throw new ConversionException(true, e, error);
    }
  }
  
  /**
   * This constructor adds an optional category.  If the term name and term reference are both empty strings, a new ontology term is created with all fields set to empty strings.
   * This is intended as a aid to avoiding NPEs.
   * @param category - name associated with an SDRF characteristic or parameter attribute (e.g., TimeUnit) 
   * @param name - The name of the ontology term
   * @param ref - A handle to the external database
   * @throws ConversionException - under two conditions.  Either the external database map needed to successfully compile the ontology term
   * has not been populated or the reference for the term cannot be found in the current external database map.  The program running
   * the conversion should have an error listener attached to the conversion.
   */
  public OntologyTerm(String category, String name, String ref) throws ConversionException {
    this(name, ref);
    this.category = category;
  }
  
  /**
   * 
   * @return ontology term name
   */
  public String getName() {
    return name;
  }
  
  /** 
   * @return the ontology term database reference combined with the version of the external database from which the reference is drawn.
   */
  public String getExternalDatabaseRelease() {
    return externalDatabaseRelease;
  }
  
  
  public final String getCategory() {
    return category;
  }

  public final void setCategory(String category) {
    this.category = category;
  }

  public boolean isEmpty() {
    return StringUtils.isEmpty(name);
  }
  
  /**
   * @return a complete representation of the ontology term using ReflectionToStringBuilder for debugging purposes. 
   */
  @Override
  public String toString() {
    return (new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE) {
      protected boolean accept(Field field) {
        return super.accept(field);
      }
    }).toString();
  }
}

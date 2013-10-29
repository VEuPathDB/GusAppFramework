package edu.upenn.cbil.limpopo.model;

import java.lang.reflect.Field;
import java.util.Map;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;

import edu.upenn.cbil.limpopo.utils.AppUtils;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.attribute.PerformerAttribute;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;

/**
 * Represents the information for a protocol application performer indicated in the SDRF.
 * This class is intended as a convenience class to be used when converting a MAGE-TAB
 * into another format.  It is expected that no more than one of these objects will be
 * associated with a protocol application.
 * @author Cris Lawrence
 */
public class Performer {
  private String name;
  private OntologyTerm role;
  private Map<String,String> comments;
  public static final String PERFORMER_ROLE = "Performer Role";
  public static final String PERFORMER_TERM = "Performer Term Source Ref";
  
  public Performer() {
    name = "";
  }
  
  /**
   * Constructs a protocol application performer, populating name and role where
   * provided.  Addition/id tokens are filtered out.
   * @param attribute - limpopo performer attribute
   * @throws ConversionException - thrown if the role ontology term cannot be satisfactorily parsed.
   */
  public Performer(PerformerAttribute attribute) throws ConversionException {
    setName(attribute.getNodeName());
    setComments(attribute.comments);
    if(!getComments().isEmpty() &&
        StringUtils.isNotEmpty(getComments().get(PERFORMER_ROLE)) &&
        StringUtils.isNotEmpty(getComments().get(PERFORMER_TERM))) {
      String performerRole = getComments().get(PERFORMER_ROLE);
      String performerRef = getComments().get(PERFORMER_TERM);
      if(StringUtils.isNotEmpty(performerRole)) {
        role = new OntologyTerm(performerRole, performerRef);
      }
    }
  }
  
  /**
   * Gets filtered performer's name
   * @return - performer's name
   */
  public String getName() {
    return name;
  }
  
  /**
   * Set the performer's name and removes any and all addition tokens
   * @param name - raw name
   */
  public final void setName(String name) {
    this.name = AppUtils.removeTokens(name);
  }

  /**
   * Get's the value for the ontology term - role
   * @return - role
   */
  public OntologyTerm getRole() {
    return role;
  }
  
  /**
   * Helper method to identify whether this performer has been assigned a role ontology term
   * @return - boolean, true if performer has a role, false otherwise
   */
  public boolean hasRole() {
    return role != null && StringUtils.isNotEmpty(role.getName());
  }
  
  /**
   * Gets filtered comments
   * @return - comments
   */
  public final Map<String, String> getComments() {
    return comments;
  }

  /**
   * Set the performer's comments with any and all addition tokens removed.
   * @param comments - raw comments
   */
  public final void setComments(Map<String, String> comments) {
    this.comments = AppUtils.removeTokens(comments);
  }

  /**
   * Helper method for diagnostic use.  Provides a more complete accounting of
   * a performer's field values.
   */
  @Override
  public String toString() {
    return (new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE) {
      protected boolean accept(Field f) {
        return super.accept(f);
      }
    }).toString();
  }

}

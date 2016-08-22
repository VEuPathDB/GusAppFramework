package edu.upenn.cbil.limpopo.model;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;

import com.google.common.collect.Ordering;
import com.google.common.primitives.Ints;

import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.limpopo.utils.ListUtils;


/**
 * Represents the information for a person or a lab indicated in the IDF.  This class is
 * intended as a convenience class to be used when converting a MAGE-TAB into another format.  It
 * is expected that one of more of these objects will be associated with an IDF.
 * @author Cris Lawrence
 */
public class Contact {
  public static Logger logger = LoggerFactory.getLogger(Contact.class);
  private boolean addition; 
  private String name;
  private String firstName;
  private String lastName;
  private String lab;
  private OntologyTerm roles;
  private String email;
  private String phone;
  private String fax;
  private String address1;
  private String address2;
  private String city;
  private String state;
  private String country;
  private String zipcode;
  private String affiliation;
  public static final String LAB_COMMENT = "Lab";
  public static final String ADDRESS2_COMMENT = "Address2";
  public static final String CITY_COMMENT = "City";
  public static final String STATE_COMMENT = "State";
  public static final String COUNTRY_COMMENT = "Country";
  public static final String ZIP_COMMENT = "Zip";

  /**
   * Indicates whether or not this contact represents an addition (as determined by spreadsheet highlighting)
   * @return - true if an addition and false otherwise
   */
  public final boolean isAddition() {
    return addition;
  }
  
  /**
   * Sets the addition flag
   * @param addition - true if addition, false otherwise
   */
  public final void setAddition(boolean addition) {
    this.addition = addition;
  }
  
  /**
   * Provides first name of contact
   * @return - string representing first name of contact.  May be null or empty.
   */
  public final String getFirstName() {
    return firstName;
  }
  
  /**
   * Sets the first name of the contact, removing any addition token.
   * @param firstName - raw first name of contact data (with possible addition token)
   */
  protected final void setFirstName(final String firstName) {
    this.firstName = AppUtils.removeTokens(firstName);
  }
  
  /**
   * Provide last name of contact
   * @return - string representing last name of contact.  May be null of empty.
   */
  public final String getLastName() {
    return lastName;
  }
  
  /**
   * Sets the last name of the contact, removes any addition token.
   * @param lastName - raw last name of contact data (with possible addition token)
   */
  protected final void setLastName(final String lastName) {
    this.lastName = AppUtils.removeTokens(lastName);
  }
  
  /**
   * Provides the laboratory name.
   * @return - string representing the laboratory name.  May be null of empty.
   */
  public final String getLab() {
    return lab;
  }
  
  /**
   * Comment [Lab] header.  Sets the laboratory name of the contact, removing any addition token.
   * @param lab - raw laboratory name data (with possible addition token)
   */
  protected final void setLab(final String lab) {
    this.lab = AppUtils.removeTokens(lab);
  }
  
  public final OntologyTerm getRoles() {
    return roles;
  }
  public final void setRoles(final OntologyTerm roles) {
    this.roles = roles;
  }
  
  /**
   * Provides the contact's email address
   * @return - string representing the contact email.  May be null or empty.
   */
  public final String getEmail() {
    return email;
  }
  
  /**
   * Sets the email address of the contact, removing any addition token.
   * @param email - raw email address data (with possible addition token)
   */
  protected final void setEmail(final String email) {
    this.email = AppUtils.removeTokens(email);
  }
  
  /**
   * Provides the contact's phone number
   * @return - string representing the phone number.  May be null or empty.
   */
  public final String getPhone() {
    return phone;
  }
  
  /**
   * Sets the phone number of the contact, removing any addition token.
   * @param phone - raw phone number data (with possible addition token)
   */
  protected final void setPhone(final String phone) {
    this.phone = AppUtils.removeTokens(phone);
  }
  
  /**
   * Provides the contact's fax number
   * @return - string representing the fax number.  May be null or empty.
   */
  public final String getFax() {
    return fax;
  }
  
  /**
   * Sets the fax number of the contact, removing any addition token.
   * @param fax - raw fax number data (with possible addition token)
   */
  protected final void setFax(final String fax) {
    this.fax = AppUtils.removeTokens(fax);
  }
  
  /**
   * Provides the first line of the contact's street address
   * @return - string representing the street address.  May be null or empty.
   */
  public final String getAddress1() {
    return address1;
  }
  
  /**
   * Sets the first line of the street address of the contact, removing any addition token.
   * @param address1 - raw first line of street address data (with possible addition token)
   */
  public final void setAddress1(final String address1) {
    this.address1 = AppUtils.removeTokens(address1);
  }
  
  /**
   * Comment [Address2] header.  Provides the second line of the contact's street address.
   * @return - string representing the 2nd line of the street address.  May be null or empty.
   */
  public final String getAddress2() {
    return address2;
  }
  
  /**
   * Sets the 2nd line of the street address of the contact, removing any addition token.
   * @param address2 - raw second line of street address data (with possible addition token)
   */
  protected final void setAddress2(final String address2) {
    this.address2 = AppUtils.removeTokens(address2);
  }
  
  /**
   * Comment [City] header.  Provides the contact's city.  
   * @return - string representing the city.  May be null or empty.
   */
  public final String getCity() {
    return city;
  }
  
  /**
   * Sets the contact's city, removing any addition token.
   * @param city - raw city data (with possible addition token)
   */
  protected final void setCity(final String city) {
    this.city = AppUtils.removeTokens(city);
  }
  
  /**
   * Comment [State] header.  Provides the contact's state.
   * @return - string representing the state.  May be null or empty.
   */
  public final String getState() {
    return state;
  }
  
  /**
   * Sets the contact's state, removing any addition token.
   * @param state - raw state data (with possible addition token)
   */
  protected final void setState(final String state) {
    this.state = AppUtils.removeTokens(state);
  }
  
  /**
   * Comment [Country] header.  Provides the contact's country.
   * @return - string representing the country.  May be null or empty.
   */
  public final String getCountry() {
    return country;
  }
  
  /**
   * Sets the contact's country, removing any addition token.
   * @param country - raw country data (with possible addition token)
   */
  protected final void setCountry(final String country) {
    this.country = AppUtils.removeTokens(country);
  }
  
  /**
   * Provides the contact's affiliation.
   * @return - string representing the affiliation.  May be null or empty.
   */
  public final String getAffiliation() {
    return affiliation;
  }
  
  /**
   * Sets the contact's affiliation, removing any addition token.
   * @param affiliation - raw affiliation data (with possible addition token)
   */
  protected final void setAffiliation(final String affiliation) {
    this.affiliation = AppUtils.removeTokens(affiliation);
  }
  
  /**
   * Provides the contact's full name.
   * @return - string containing either first + last name, or last name or lab
   */
  public String getName() {
    return name;
  }
  
  /**
   * Sets the contact's full name using firstName, lastName and lab data.  Addition
   * tokens will be removed if present.
   */
  protected void setName() {
    name = createName(firstName, lastName, lab);
  }
  
  /**
   * Comment [Zip] header.  Provides the contact's postal code.
   * @return - string representing the postal code.  May be null or empty.
   */
  public String getZipcode() {
    return zipcode;
  }
  
  /**
   * Sets the contact's postal code, removing any addition token.
   * @param zipcode - raw postal code (with possible addition token)
   */
  public void setZipcode(String zipcode) {
    this.zipcode = AppUtils.removeTokens(zipcode);
  }

  /**
   * Helper method for diagnostic use.  Provides a more complete accounting of
   * a contact's field values.
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
   * Assembles a full contact name from first name, last name, lab data.  Any addition tokens are
   * removed.
   * @param first - first name (may be empty)
   * @param last - last name (either this or laboratory name must be non-empty)
   * @param lab - laboratory name (either this or last name must be non-empty)
   * @return - the full contact name to be used
   */
  public static final String createName(final String first, final String  last, final String lab) {
    String name = AppUtils.removeTokens(last);
    if(StringUtils.isEmpty(name)) name = lab;
    else if(StringUtils.isNotEmpty(AppUtils.removeTokens(first))) name = first + " " + last;
    return AppUtils.removeTokens(name);
  }

  /**
   * The lists that compose the field for a list of contacts can all be different lengths (e.g.,
   * the last contact may not have a first name and the last two contacts may not have an email
   * address).  Consequently, the list with the highest element count must be identified so that
   * a correct maximum can be set for a looping variable when all the contacts in the IDF are
   * retrieved and used to populate objects of this class.
   * @param data - the IDF data - the method makes use of those lists associated with a contact
   * (hard-coded)
   * @param commentSizes - an int array containing the sizes of all comment lists also incorporated
   * into the set of contact objects.
   * @return - the maximum size of all the input lists (i.e., limpopo fields and comments)
   */
  public static int getLoopLimit(final IDF data, final int... commentSizes) {
    List<Integer> sizes = new ArrayList<>();
    sizes.add(data.personFirstName.size());
    sizes.add(data.personLastName.size());
    sizes.add(data.personRoles.size());
    sizes.add(data.personEmail.size());
    sizes.add(data.personPhone.size());
    sizes.add(data.personFax.size());
    sizes.add(data.personAddress.size());
    sizes.add(data.personAffiliation.size());
    sizes.addAll(Ints.asList(commentSizes));
    return Ordering.<Integer> natural().max(sizes);
  }
  
  /**
   * Assembles a set of contact names from the IDF for validation.  Addition/id tokens are filtered out.
   * @param data - IDF data
   * @return - set of IDF contact names
   */
  public static Set<String> getContactNames(final IDF data) {
    Set<String> contactNames = new HashSet<String>();
    List<String> labs = OrderedComment.retrieveComments(LAB_COMMENT, data);
    int limit = getLoopLimit(data, labs.size());
    for(int i = 0; i < limit; i++) {
      contactNames.add(
       createName(ListUtils.get(data.personFirstName, i),
                  ListUtils.get(data.personLastName, i),
                  ListUtils.get(labs, i))
      );
    }
    return contactNames;
  }

  /**
   * Generates a list of fully populated contact objects from the IDF.  Only the contact
   * last name is checked for an addition token.  If found, that contact is notes as an
   * addition.
   * @param data - IDF data
   * @return - List of contacts acquired from IDF
   * @throws ConversionException - caused by problems with ontology terms.
   */
  public static List<Contact> populate(final IDF data) throws ConversionException {
	logger.debug("START: Populating Contacts");
    List<String> labs = OrderedComment.retrieveComments(LAB_COMMENT, data);
    List<String> addresses2 = OrderedComment.retrieveComments(ADDRESS2_COMMENT, data);
    List<String> cities = OrderedComment.retrieveComments(CITY_COMMENT, data);
    List<String> states = OrderedComment.retrieveComments(STATE_COMMENT,data);
    List<String> countries = OrderedComment.retrieveComments(COUNTRY_COMMENT,data);
    List<String> zipcodes = OrderedComment.retrieveComments(ZIP_COMMENT,data);

    int limit = getLoopLimit(data, labs.size());
    List<Contact> contacts = new ArrayList<>();
    for (int i = 0; i < limit; i++) {
      Contact contact = new Contact();
      contact.setLastName(ListUtils.get(data.personLastName, i));
      contact.setFirstName(ListUtils.get(data.personFirstName, i));
      contact.setLab(ListUtils.get(labs, i));
      contact.setAddition(AppUtils.checkForAddition(ListUtils.get(data.personLastName, i) + ListUtils.get(labs, i)));
      contact.setName();
      contact.setRoles(new OntologyTerm(ListUtils.get(data.personRoles, i), ListUtils.get(data.personRolesTermSourceREF, i)));
      contact.setEmail(ListUtils.get(data.personEmail, i));
      contact.setPhone(ListUtils.get(data.personPhone, i));
      contact.setFax(ListUtils.get(data.personFax, i));
      contact.setAddress1(ListUtils.get(data.personAddress, i));
      contact.setAddress2(ListUtils.get(addresses2, i));
      contact.setCity(ListUtils.get(cities, i));
      contact.setState(ListUtils.get(states, i));
      contact.setCountry(ListUtils.get(countries, i));
      contact.setZipcode(ListUtils.get(zipcodes, i));
      contact.setAffiliation(ListUtils.get(data.personAffiliation, i));
      contacts.add(contact);
    }
    logger.debug("END: Populating Contacts");
    return contacts;
  }

}

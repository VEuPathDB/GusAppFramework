package edu.upenn.cbil.limpopo.validate;

import java.util.List;

import org.apache.commons.lang.StringUtils;
import org.mged.magetab.error.ErrorItem;
import org.mged.magetab.error.ErrorItemFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.upenn.cbil.limpopo.model.Contact;
import edu.upenn.cbil.limpopo.model.OrderedComment;
import edu.upenn.cbil.limpopo.utils.AppException;
import edu.upenn.cbil.limpopo.utils.ListUtils;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;
import uk.ac.ebi.arrayexpress2.magetab.exception.ValidateException;
import uk.ac.ebi.arrayexpress2.magetab.handler.idf.IDFValidateHandler;
import uk.ac.ebi.arrayexpress2.magetab.handler.listener.HandlerListener;
import net.sourceforge.fluxion.spi.ServiceProvider;

@ServiceProvider
public class ContactValidator extends IDFValidateHandler {
  public static Logger logger = LoggerFactory.getLogger(ContactValidator.class);
  public static HandlerListener listener;
  
  public ContactValidator() {
    listener = new ValidateHandlerListener();
    this.addListener(listener);
  }

  @Override
  protected boolean canValidateData(IDF data) {
	logger.debug("Inside canValidateData of " + this.getClass().getSimpleName());
    return true;
  }

  /**
   * Some contact-related validations
   * SOP 6. Comment [Lab] is for contacts that are not people and hence have no first or last name.
   *        For every contact either the pair (Person First Name, Person Last Name) must have
   *        values or Comment [Lab] must have values.
   * SOP 7. If Comment [Address2] is non-empty, then Person Address must be non-empty.
   * SOP 8. Person Affiliation must be non-empty for every contact.
   *        If a contact is an affiliation its affiliation is itself.
   * SOP 9. Person Roles and Person Roles Term Source REF must be non-empty for every contact. 
   * Policies 3.  Comment [Lab] maps to the name tag in the contact element. 
   */
  @Override
  protected void validateData(IDF data) throws ValidateException {
    try {
      logger.debug("START validateData of " + this.getClass().getSimpleName());
      List<String> labs = OrderedComment.retrieveComments(Contact.LAB_COMMENT, data);
      List<String> addresses2 = OrderedComment.retrieveComments(Contact.ADDRESS2_COMMENT, data);
      int limit = Contact.getLoopLimit(data, labs.size());
      for (int i = 0; i < limit; i++) {
        String lastName = ListUtils.get(data.personLastName, i);
        String firstName = ListUtils.get(data.personFirstName, i);
        String lab = ListUtils.get(labs, i);
        if(StringUtils.isEmpty(lastName)) {
          if(StringUtils.isEmpty(lab)) {
            throw new AppException(3001);
          }
        }
        else if(StringUtils.isEmpty(firstName)) {
          throw new AppException(3002);
        }
        if(StringUtils.isNotEmpty(ListUtils.get(addresses2, i)) && StringUtils.isEmpty(ListUtils.get(data.personAddress, i))) {
          throw new AppException(3003);  
        }
        if(StringUtils.isEmpty(ListUtils.get(data.personAffiliation, i))) {
          throw new AppException(3004);
        }
        if(StringUtils.isEmpty(ListUtils.get(data.personRoles, i)) || StringUtils.isEmpty(ListUtils.get(data.personRolesTermSourceREF, i))) {
          throw new AppException(3005);
        }
        String[] roles = ListUtils.get(data.personRoles, i).split(";");
        String[] roleRefs = ListUtils.get(data.personRolesTermSourceREF, i).split(";");
        if(roles.length != roleRefs.length) {
          throw new AppException(3006);
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
    logger.debug("END validateData of " + this.getClass().getSimpleName());
  }
}
package edu.upenn.cbil.magetab;

import java.io.File;
import java.io.IOException;

import org.jdom2.JDOMException;
import org.jdom2.input.SAXBuilder;
import org.jdom2.input.sax.XMLReaders;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.upenn.cbil.magetab.utilities.ApplicationException;

/**
 * Performs a validation of an XML file using an XSD file.  It is assumed that the xsd file
 * is referenced in the xml.
 * @author crisl
 *
 */
public class XMLValidator {
  public static Logger logger = LoggerFactory.getLogger(XMLValidator.class);
  private static final String VALIDATION_ERROR = "Validation with XSD did not succeed";
  
  /**
   * Retrieves the xml version of the mage-tab and validates it against the output.xsd file.
   * Throws a runtime exception in the event of an invalid xml document.
   * @param file - derived mage-tab xml file
   */
  protected void validate(String filename) {
    logger.debug("START - " + this.getClass().getSimpleName());
    File file = new File(filename);
    try {
      SAXBuilder builder = new SAXBuilder(XMLReaders.XSDVALIDATING);
      builder.build(file);
    }
    catch(JDOMException | IOException e ) {
      throw new ApplicationException(VALIDATION_ERROR, e);
    }
    logger.debug("END - " + this.getClass().getSimpleName());
  }
  
}

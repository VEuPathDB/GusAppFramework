package edu.upenn.cbil.magetab.postprocessor;

import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.XML_EXT;
import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.XSL_EXT;
import static edu.upenn.cbil.magetab.utilities.ApplicationException.FILE_WRITE_ERROR;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;

import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.apache.log4j.Logger;
import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.output.Format;
import org.jdom2.output.XMLOutputter;

import com.google.common.base.Charsets;
import com.google.common.io.Files;

import edu.upenn.cbil.magetab.utilities.ApplicationConfiguration;
import edu.upenn.cbil.magetab.utilities.ApplicationException;

/**
 * Postprocessor to filter out the MAGE-TAB additions from the complete MAGE-TAB xml document.
 * @author crisl
 *
 */
public class AdditionFilterPostprocessor {
  private String stylesheetFilename;
  private String filteredXmlFilename;
  private static final String FILTERED = "filtered";
  public static final String FILTER_ERROR = "There was a problem filtering the xml output.";
  public static Logger logger = Logger.getLogger(AdditionFilterPostprocessor.class);
  
  /**
   * Constructor identifies the xml stylesheet file and the location of the filtered xml
   * output.
   * @param directoryName - based on Excel workbook name
   */
  public AdditionFilterPostprocessor(String directoryName) {
    this.stylesheetFilename = ApplicationConfiguration.filterPrefix + "." + XSL_EXT;
    this.filteredXmlFilename = directoryName + File.separator + FILTERED + "." + XML_EXT;
  }
  
  /**
   * Processes the original complete MAGE-TAB xml output into a filtered version via xslt
   * whenever the subject MAGE-TAB contains additions.  Such a MAGE-TAB is identified by
   * a db_id attribute on the study name in the complete xml document.  The filtered 
   * version is stored in the directory passed to the constructor.  The name of the file is
   * filtered.xml.
   * @param document - the complete xml document.
   */
  public void process(Document document) {
    logger.info("START - " + this.getClass().getSimpleName());
    if(isAddition(document)) {
      String filteredOutput = transform(document);
      try {
        Files.write(filteredOutput, new File(filteredXmlFilename), Charsets.UTF_8);
      }
      catch(IOException ioe) {
        throw new ApplicationException(FILE_WRITE_ERROR + filteredXmlFilename, ioe);
      }
    }
    logger.info("END - " + this.getClass().getSimpleName());
  }
  
  /**
   * Helper method to determine whether or not the complete xml document contains
   * additions
   * @param document - the complete xml document.
   * @return - boolean - true for addition, false otherwise
   */
  protected boolean isAddition(Document document) {
    Element studyElement = document.getRootElement().getChild("idf").getChild("study");
    Element titleElement = studyElement.getChild("name");
    return titleElement.getAttribute("db_id") != null ? false : true;
  }
  
  /**
   * Helper method to perform the actual filtering on the original complete xml document.
   * @param document - the complete xml document
   * @return - string representation of the filtered output.
   */
  protected String transform(Document document) {
    XMLOutputter xmlOutput = new XMLOutputter();
    xmlOutput.setFormat(Format.getPrettyFormat().setExpandEmptyElements(true));
    String xmlString = xmlOutput.outputString(document);
    try {
      TransformerFactory factory = TransformerFactory.newInstance();
      Transformer transformer = factory.newTransformer(new StreamSource(stylesheetFilename));
      StreamSource xmlSource = new StreamSource(new ByteArrayInputStream(xmlString.getBytes()));
      ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
      transformer.transform(xmlSource, new StreamResult(outputStream));
      return outputStream.toString();
    }
    catch(TransformerException tex) {
      throw new ApplicationException(FILTER_ERROR, tex);
    }
  }
  
}

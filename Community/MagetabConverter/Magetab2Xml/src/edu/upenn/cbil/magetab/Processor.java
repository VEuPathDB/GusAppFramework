package edu.upenn.cbil.magetab;

import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.*;
import static edu.upenn.cbil.magetab.utilities.ApplicationException.*;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

import org.jdom2.Document;
import org.jdom2.output.Format;
import org.jdom2.output.XMLOutputter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.converter.MAGETABConverter;
import uk.ac.ebi.arrayexpress2.magetab.exception.ParseException;
import uk.ac.ebi.arrayexpress2.magetab.parser.MAGETABParser;
import uk.ac.ebi.arrayexpress2.magetab.validator.MAGETABValidator;
import edu.upenn.cbil.magetab.model.Study;
import edu.upenn.cbil.magetab.postprocessor.AdditionFilterPostprocessor;
import edu.upenn.cbil.magetab.postprocessor.DisplayPostprocessor;
import edu.upenn.cbil.magetab.postprocessor.FactorValuePostprocessor;
import edu.upenn.cbil.magetab.postprocessor.GraphmlPostprocessor;
import edu.upenn.cbil.magetab.postprocessor.ModelPostprocessor;
import edu.upenn.cbil.magetab.postprocessor.PackagingPostprocessor;
import edu.upenn.cbil.magetab.postprocessor.ProtocolAppConsolidationPostprocessor;
import edu.upenn.cbil.magetab.utilities.ApplicationConfiguration;
import edu.upenn.cbil.magetab.utilities.ApplicationException;
import edu.upenn.cbil.magetab.utilities.ErrorListener;

public class Processor {
  public static Logger logger = LoggerFactory.getLogger(Processor.class);
  String directory;
  String idfFilename;
  String sdrfFilename;
  String outputFilename;
  String graphmlFilename;
  
  /**
   * Use the directory argument to create filenames for the idf, sdrf, xml output, and graphml
   * files to be generated.
   * @param directory - name based upon Excel workbook name.
   */
  public Processor(String directory) {
    this.directory = directory;
    idfFilename = directory + File.separator + "idf." + TEXT_EXT;
    sdrfFilename = directory + File.separator + "sdrf." + TEXT_EXT;
    outputFilename = directory + File.separator + ApplicationConfiguration.filePrefix + "." + XML_EXT;
    graphmlFilename = directory + File.separator + ApplicationConfiguration.filePrefix + "." + GRAPHML_EXT;
  }

  public void process() {
    FileOutputStream output = null;
    try {
      Document document = new Document();
      ErrorListener listener = new ErrorListener();
      MAGETABValidator validator = new MAGETABValidator();
      validator.addErrorItemListener(listener);
      MAGETABConverter<Document> converter = new MAGETABConverter<Document>();
      converter.addErrorItemListener(listener);
      MAGETABParser<Document> parser = new MAGETABParser<Document>(validator, converter, document);
      parser.addErrorItemListener(listener);
      output = new FileOutputStream(outputFilename);
      try {
        parser.parse(new File(idfFilename));
      }
      catch(ParseException pe) {
        logger.error(MAGETAB_ERROR, pe);
        throw new ApplicationException(pe.getMessage());
      }
      if(ErrorListener.getErrorCount() > 0) {
        logger.error(MAGETAB_ERROR);
        throw new ApplicationException(MAGETAB_ERROR);
      }
      document = new FactorValuePostprocessor().process(document);
      document = new ProtocolAppConsolidationPostprocessor(document).process();
      XMLOutputter xmlOutput = new XMLOutputter();
      xmlOutput.setFormat(Format.getPrettyFormat().setExpandEmptyElements(true).setEncoding("ISO-8859-1"));
      xmlOutput.output(document, output);
      if(switches.get(VALIDATE)) {
        new XMLValidator().validate(outputFilename);
      }
      if(switches.get(GRAPHML)) {
        new GraphmlPostprocessor(graphmlFilename).create(document);
      }
      if(switches.get(HTML)) {
        Study study = new ModelPostprocessor(document).process();
        new DisplayPostprocessor(directory).process(study);
      }
      new AdditionFilterPostprocessor(directory).process(document);
      new PackagingPostprocessor(directory).process();
    }
    catch(FileNotFoundException fnfe) {
      logger.error(FILE_NOT_FOUND_ERROR + outputFilename, fnfe);
      throw new ApplicationException(FILE_NOT_FOUND_ERROR + outputFilename);
    }
    catch(IOException ioe) {
      logger.error(FILE_IO_ERROR + outputFilename, ioe);
      throw new ApplicationException(FILE_IO_ERROR + outputFilename);
    }
    finally {
      try {
        output.close();
      }
      catch(IOException ioe) {
        logger.warn(FILE_CLOSE_ERROR + outputFilename);
      }
    }
  }

}

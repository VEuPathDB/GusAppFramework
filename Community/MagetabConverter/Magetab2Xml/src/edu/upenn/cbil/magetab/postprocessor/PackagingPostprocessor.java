package edu.upenn.cbil.magetab.postprocessor;

import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.HTML_EXT;
import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.HTML_RESOURCES_ARCHIVE;
import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.XML_EXT;
import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.ZIP_EXT;
import static edu.upenn.cbil.magetab.utilities.ApplicationException.FILE_CLOSE_ERROR;
import static edu.upenn.cbil.magetab.utilities.ApplicationException.FILE_CREATION_ERROR;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import org.apache.commons.compress.archivers.ArchiveEntry;
import org.apache.commons.compress.archivers.ArchiveException;
import org.apache.commons.compress.archivers.ArchiveInputStream;
import org.apache.commons.compress.archivers.ArchiveOutputStream;
import org.apache.commons.compress.archivers.ArchiveStreamFactory;
import org.apache.commons.compress.archivers.zip.ZipArchiveEntry;
import org.apache.commons.compress.utils.IOUtils;
import org.apache.log4j.Logger;

import edu.upenn.cbil.magetab.utilities.ApplicationConfiguration;
import edu.upenn.cbil.magetab.utilities.ApplicationException;

public class PackagingPostprocessor {
  private String imageFilename;
  private String htmlFilename;
  private String xmlFilename;
  private String filteredXmlFilename;
  private String zipFilename;
  private static final String FILTERED = "filtered";
  public static Logger logger = Logger.getLogger(PackagingPostprocessor.class);
  
  public PackagingPostprocessor(String directoryName) {
    this.imageFilename = directoryName + File.separator + ApplicationConfiguration.filePrefix + "." + ApplicationConfiguration.imageType;
    this.htmlFilename = directoryName + File.separator + ApplicationConfiguration.filePrefix + "." + HTML_EXT;
    this.xmlFilename = directoryName + File.separator + ApplicationConfiguration.filePrefix + "." + XML_EXT;
    this.filteredXmlFilename = directoryName + File.separator + FILTERED + "." + XML_EXT;
    this.zipFilename = directoryName + File.separator + ApplicationConfiguration.filePrefix + "." + ZIP_EXT;
  }

  /**
   * Packaging the xml output, a filtered xml output in the case of MAGE-TAB additions,
   * the biomaterials graph, if requested and all the dependencies for the html biomaterials
   * graph into a zip file for portability.
   */
  public void process() {
    OutputStream output = null;
    ArchiveInputStream zipInput = null;
    ArchiveOutputStream zipOutput = null;
    try {
      FileInputStream input = new FileInputStream(HTML_RESOURCES_ARCHIVE);
      zipInput = new ArchiveStreamFactory().createArchiveInputStream(ArchiveStreamFactory.ZIP, input);
      output = new FileOutputStream(new File(zipFilename));
      zipOutput = new ArchiveStreamFactory().createArchiveOutputStream(ArchiveStreamFactory.ZIP, output);
      ArchiveEntry archiveEntry = null;
      while ((archiveEntry = zipInput.getNextEntry()) != null) {
        zipOutput.putArchiveEntry(archiveEntry);
        IOUtils.copy(zipInput, zipOutput, (int) archiveEntry.getSize());
        zipOutput.closeArchiveEntry();
      }
      if(new File(imageFilename).exists()) {
        zipOutput.putArchiveEntry(new ZipArchiveEntry(imageFilename));
        IOUtils.copy(new FileInputStream(new File(imageFilename)), zipOutput);
        zipOutput.closeArchiveEntry();
      }
      if(new File(htmlFilename).exists()) {
        zipOutput.putArchiveEntry(new ZipArchiveEntry(htmlFilename));
        IOUtils.copy(new FileInputStream(new File(htmlFilename)), zipOutput);
        zipOutput.closeArchiveEntry();
      }
      if(new File(xmlFilename).exists()) {
        zipOutput.putArchiveEntry(new ZipArchiveEntry(xmlFilename));
        IOUtils.copy(new FileInputStream(new File(xmlFilename)), zipOutput);
        zipOutput.closeArchiveEntry();
      }
      if(new File(filteredXmlFilename).exists()) {
        zipOutput.putArchiveEntry(new ZipArchiveEntry(filteredXmlFilename));
        IOUtils.copy(new FileInputStream(new File(filteredXmlFilename)), zipOutput);
        zipOutput.closeArchiveEntry();
      }
      zipOutput.finish();
    }
    catch(IOException | ArchiveException e) {
      throw new ApplicationException(FILE_CREATION_ERROR + zipFilename);
    }
    finally {
      if (zipInput != null && zipOutput != null) {
        try {
          zipInput.close();
          zipOutput.close();
        }
        catch(IOException ioe) {
          throw new ApplicationException(FILE_CLOSE_ERROR, ioe);
        }
      }
    }
  }
  
}

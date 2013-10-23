package edu.upenn.cbil.magetab.postprocessor;
// GraphViz.java - a simple API to call dot from Java programs
// Derived from:

/*$Id$*/
/*
 ******************************************************************************
 *                                                                            *
 *              (c) Copyright 2003 Laszlo Szathmary                           *
 *                                                                            *
 * This program is free software; you can redistribute it and/or modify it    *
 * under the terms of the GNU Lesser General Public License as published by   *
 * the Free Software Foundation; either version 2.1 of the License, or        *
 * (at your option) any later version.                                        *
 *                                                                            *
 * This program is distributed in the hope that it will be useful, but        *
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY *
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public    *
 * License for more details.                                                  *
 *                                                                            *
 * You should have received a copy of the GNU Lesser General Public License   *
 * along with this program; if not, write to the Free Software Foundation,    *
 * Inc., 675 Mass Ave, Cambridge, MA 02139, USA.                              *
 *                                                                            *
 ******************************************************************************
 */

import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.DOT_EXT;
import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.HTML_EXT;
import static edu.upenn.cbil.magetab.utilities.ApplicationException.DOT_INTERRUPTION_ERROR;
import static edu.upenn.cbil.magetab.utilities.ApplicationException.FILE_CLOSE_ERROR;
import static edu.upenn.cbil.magetab.utilities.ApplicationException.FILE_CREATION_ERROR;
import static edu.upenn.cbil.magetab.utilities.ApplicationException.FILE_IO_ERROR;
import static edu.upenn.cbil.magetab.utilities.ApplicationException.FILE_READ_ERROR;
import static edu.upenn.cbil.magetab.utilities.ApplicationException.FILE_WRITE_ERROR;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Writer;
import java.nio.charset.Charset;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;

import com.google.common.base.Charsets;
import com.google.common.io.Files;

import edu.upenn.cbil.magetab.Converter;
import edu.upenn.cbil.magetab.model.Edge;
import edu.upenn.cbil.magetab.model.Node;
import edu.upenn.cbil.magetab.model.ProtocolApplication;
import edu.upenn.cbil.magetab.model.Study;
import edu.upenn.cbil.magetab.utilities.ApplicationConfiguration;
import edu.upenn.cbil.magetab.utilities.ApplicationException;
import freemarker.template.Configuration;
import freemarker.template.Template;
import freemarker.template.TemplateException;

/**
 * Postprocessor to render the result of a mage-tab conversion into a html-based biomaterials
 * graph using Graphviz to represent nodes and edges and JS tooltips to provide information
 * relevant to each node/edge.  Based upon Graphviz/Java binding code written by Laszlo
 * Szathmary.
 * @author crisl
 *
 */
public class DisplayPostprocessor {
  private String dotFilename;
  private String imageFilename;
  private String htmlFilename;
  private static final String TEMPLATE_FOLDER = "templates";
  private static final String CONTENT_TEMPLATE = "content.ftl";
  public static Logger logger = Logger.getLogger(DisplayPostprocessor.class);
  
  /**
   * Use the directory name argument to create filenames for the dot, image, html, and zip
   * files to be generated.
   * @param directoryName - based on Excel workbook name
   */
  public DisplayPostprocessor(String directoryName) {
    this.dotFilename = directoryName + File.separator + ApplicationConfiguration.filePrefix + "." + DOT_EXT;
    this.imageFilename = directoryName + File.separator + ApplicationConfiguration.filePrefix + "." + ApplicationConfiguration.imageType;
    this.htmlFilename = directoryName + File.separator + ApplicationConfiguration.filePrefix + "." + HTML_EXT;
  }

  /**
   * Processes a study object into the html based interactive bio-materials graph.  Provides a
   * archived version for portability.
   * @param study - populated study object
   */
  public void process(Study study) {
    logger.info("START - " + getClass().getSimpleName());
    File dotFile = createDotFile(study);
    File mapFile = createImageMapFile(dotFile);
    String map = retrieveMap(mapFile);
    createHtmlFile(study, map);
    logger.info("END - " + getClass().getSimpleName());
  }

  /**
   * Uses the populated study model to assemble a dot file.
   * @param study - populated study object
   * @return - dot file
   */
  protected File createDotFile(Study study) {
    StringBuffer output = new StringBuffer();
    output.append("digraph biomatGraph {\n");
    output.append("graph [rankdir=LR, margin=0.001]\n");
    List<Node> nodes = study.getNodes();
    List<Edge> edges = study.getEdges();
    for(Node node : nodes) {
      String label = "label = \"" + node.getLabel() + "\""; 
      String color = "color = \"" + node.getColor() + "\"";
      String url = "URL = \"node.html?id=" + node.getId() + "&type=" + node.getType() + "\"";    
      if(node.isAddition()) {
        String fillColor = "style = \"filled\", fillcolor = \"yellow\"";
        output.append(node.getId() + " [" + color + ", " + fillColor + ", " + label + ", " + url + ", fontsize=12]\n");
      }
      else {
        output.append(node.getId() + " [" + color + ", " + label + ", " + url + ", fontsize=12]\n");
      }
    }
    for(Edge edge : edges) {
      List<ProtocolApplication> applications = edge.getApplications();
      String label = "label = \"" + edge.getLabel() + "\"";
      String url = "labelURL = \"edge.html?id=" + edge.getFromNode() + edge.getToNode() + "\"";
      if(applications.size() == 1 && applications.get(0).isAddition()) {
        String edgeColor = "color = \"yellow\"";
        output.append(edge.getFromNode() + "->" + edge.getToNode() + "[" + label + ", " + edgeColor + ", " + url + ", fontsize=10]\n");
      }
      else {
        output.append(edge.getFromNode() + "->" + edge.getToNode() + "[" + label + ", " + url + ", fontsize=10]\n");
      }
    }
    output.append("}");
    File file = new File(dotFilename);
    try {
      Files.write(output.toString(), file, Charsets.UTF_8);
    }
    catch(IOException ioe) {
      throw new ApplicationException(FILE_WRITE_ERROR + dotFilename, ioe);
    }
    return file;
  }
  
  /**
   * Uses the dot file to generate a gif to be applied as an image map for the html display.
   * @param dotFile - dot file
   * @return - image map file
   */
  protected File createImageMapFile(File dotFile) {
    String DOT = ApplicationConfiguration.graphvizDotPath;
    File mapFile = null;
    InputStreamReader errorReader = null;
    try {
       File imageFile = new File(imageFilename);
       mapFile = File.createTempFile("map", HTML_EXT);
       Runtime rt = Runtime.getRuntime();
       String[] args = {DOT, "-T" + ApplicationConfiguration.imageType, dotFile.getAbsolutePath(), "-o", imageFile.getAbsolutePath(), "-Tcmapx", "-o", mapFile.getAbsolutePath()};
       System.out.println("Image/Map creation: " + Arrays.asList(args).toString());
       Process p = rt.exec(args);
       p.waitFor();
       errorReader = new InputStreamReader(p.getErrorStream());
       int data;
       String errorMessage = "";
       while((data = errorReader.read()) != -1){
           char c = (char) data;
           errorMessage += c;
       }
       if(StringUtils.isNotEmpty(errorMessage)) {
         throw new ApplicationException("DOT COMMAND ERROR: " + errorMessage);
       }
    }
    catch (IOException ioe) {
      throw new ApplicationException(FILE_IO_ERROR + imageFilename + ", " + mapFile.getName(), ioe);
    }
    catch (InterruptedException ie) {
      throw new ApplicationException(DOT_INTERRUPTION_ERROR, ie);
    }
    finally {
      if(errorReader != null) {
    	try {
          errorReader.close();
    	}
    	catch(IOException ioe) {
    	  ;
    	}
      }
    }
    return mapFile;
  }
   
  /**
   * Retrieve the image map created by the dot file process.
   * @param mapFile - the temporary map file
   * @return - contents of the map file
   */
  protected String retrieveMap(File mapFile) {
    String map = null;
    try {
      map = Files.toString(mapFile, Charset.defaultCharset());
    }
    catch (IOException ioe) {
      throw new ApplicationException(FILE_READ_ERROR + mapFile.getName(), ioe);
   }
   return map;
  }
  
  /**
   * Generate the html display using the image map provided by the dot process and annotated by
   * the study model.  The html page is constructed with the help of Freemarker templates.
   * @param study - populated study model
   * @param map - image map file
   */
  protected void createHtmlFile(Study study, String map) {
    Writer file = null;
    Configuration cfg = new Configuration();
    try {
      cfg.setDirectoryForTemplateLoading(new File(TEMPLATE_FOLDER));
      Template template = cfg.getTemplate(CONTENT_TEMPLATE);
      Map<String, Object> input = new HashMap<String, Object>();
      input.put("gifFileName", imageFilename.substring(imageFilename.lastIndexOf(File.separator) + 1));
      input.put("magetab", ".." + File.separator + Converter.inputFile.getName());
      input.put("studyName", study.getStudyName());
      input.put("studyId", study.getDbId());
      input.put("nodes", study.getNodes());
      input.put("edges", study.getEdges());
      input.put("map", map);
      file = new FileWriter(new File(htmlFilename));
      template.process(input, file);
      file.flush();
    }
    catch (IOException | TemplateException e) {
      throw new ApplicationException(FILE_CREATION_ERROR + htmlFilename, e);
    }
    finally {
      if (file != null) {
        try {
          file.close();
        }
        catch (IOException ioe) {
          throw new ApplicationException(FILE_CLOSE_ERROR, ioe);
        }
      } 
    }
  } 
}


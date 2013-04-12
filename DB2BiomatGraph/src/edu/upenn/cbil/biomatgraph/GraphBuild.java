package edu.upenn.cbil.biomatgraph;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.text.DateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;

import com.google.common.base.Charsets;
import com.google.common.io.Files;

import freemarker.template.Configuration;
import freemarker.template.Template;

public class GraphBuild {
	public static Logger logger = Logger.getLogger(GraphBuild.class);
	public String[] range;

	public static void main(String[] args) {
	  logger.info("Starting at " + DateFormat.getDateTimeInstance().format(new Date()));
	  GraphBuild build = new GraphBuild();
	  new ApplicationConfiguration().applicationSetup();
	  long studyId = 0;
	  try {
	    if(args.length == 0) throw new ApplicationException("No study id was provided.");
		studyId = Integer.parseInt(args[0]);
	  }
	  catch(NumberFormatException nfe) {
	    throw new ApplicationException("The argument provided (" + args[0] + ") was not a valid study id.");
	  }
	  build.createDotFile(studyId);
	  logger.info("Ending at " + DateFormat.getDateTimeInstance().format(new Date()));
	}
	
	protected void createDotFile(long studyId) {
	  StringBuffer output = new StringBuffer();
	  output.append("digraph graphname {\n");
	  BiomaterialsGraphService service = new BiomaterialsGraphService();
	  try {
	    service.manageConnection(true);
	    List<Node> nodes = service.getNodes(studyId);
	    List<Edge> edges = service.getEdges(studyId);
	    for(Node node : nodes) {
	      output.append(node.getNodeId() + " [color = " + node.getColor() + ", label=\"" + node.getLabel() + "\"]\n");
	    }
	    for(Edge edge : edges) {
	      output.append(edge.getFromNode() + "->" + edge.getToNode() + "[label=\"" + edge.getLabel() + "\"]\n");
	    }
	  }
	  finally {
	    service.manageConnection(false);
	  }
	  output.append("}");
	  createImageFile(studyId, output.toString());
	  String dotFileName = ApplicationConfiguration.filePrefix + "_" + studyId + ".dot";
	  try {
	    Files.write(output.toString(), new File(dotFileName), Charsets.UTF_8);
	  }
	  catch(IOException ioe) {
	    throw new ApplicationException("Problem writing to file " + dotFileName);
	  }
    }
	
	protected void createImageFile(long studyId, String output) {
	  GraphViz gv = new GraphViz();
	  File gifFile = new File(ApplicationConfiguration.filePrefix + "_" + studyId + ".gif");
	  gv.writeGraphToFile( gv.getGraph( output, "gif" ), gifFile );
	  createHtmlFile(studyId);
	}
	
	protected void createHtmlFile(long studyId) {
	  Writer file = null;
	  Configuration cfg = new Configuration();

	  try {
	    // Set Directory for templates
	    cfg.setDirectoryForTemplateLoading(new File("templates"));
	    Template template = cfg.getTemplate("content.ftl");
	    Map<String, Object> input = new HashMap<String, Object>();
	    input.put("studyId", studyId);
	    input.put("gifFileName", ApplicationConfiguration.filePrefix + "_" + studyId + ".gif");

	    // File output
	    file = new FileWriter(new File(ApplicationConfiguration.filePrefix + "_" + studyId + ".html"));
	    template.process(input, file);
	    file.flush();

	    // Also write output to console
	    Writer out = new OutputStreamWriter(System.out);
	    template.process(input, out);
	    out.flush();

	  } catch (Exception e) {
	    throw new ApplicationException("Unable to create html file.");
	  } finally {
	    if (file != null) {
	      try {
	        file.close();
	      } catch (Exception e2) {
         }
	   }
	}
  }
}

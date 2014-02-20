package edu.upenn.cbil.biomatgraph;

import java.io.File;
import java.text.DateFormat;
import java.util.Date;

import org.apache.log4j.Logger;

/**
 * This class provides the entry into this program.
 * @author crislawrence
 *
 */
public class GraphBuild {
	public static Logger logger = Logger.getLogger(GraphBuild.class);

	public static void main(String[] args) {
	  logger.info("MAIN START - " + DateFormat.getDateTimeInstance().format(new Date()));
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
	  Study study = build.populateStudy(studyId);
	  Display display = new Display(study);
	  File dotFile = display.createDotFile();
	  File mapFile = display.createImageMapFile(dotFile);
	  String map = display.retrieveMap(mapFile);
	  display.createHtmlFile(map);
	  logger.info("MAIN END - " + DateFormat.getDateTimeInstance().format(new Date()));
	}
	
	protected Study populateStudy(long studyId) {
      BiomaterialsGraphService service = new BiomaterialsGraphService();
      try {
        service.manageConnection(true);
        Study study = new Study();
        study.setStudyId(studyId);
        study.setStudyName(service.getStudyName(studyId));
        study.setNodes(service.getNodes(studyId));
        study.setEdges(service.constructEdgeData(studyId));
        return study;
      }
      finally {
        service.manageConnection(false);
      }
	}
}
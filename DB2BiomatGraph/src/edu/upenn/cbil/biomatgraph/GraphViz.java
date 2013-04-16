package edu.upenn.cbil.biomatgraph;
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

import java.io.File;

import org.apache.log4j.Logger;

public class GraphViz {
   private static String DOT = ApplicationConfiguration.graphvizDotPath;
   public static Logger logger = Logger.getLogger(GraphViz.class);

   public File writeImageMap(File dot, String outputPrefix) {
     logger.info("START - writeImageMap");
     File map = null;
     try {
        File img = new File(outputPrefix + ".gif");
        map = File.createTempFile(ApplicationConfiguration.MAP_FILE_NAME,"html");
        Runtime rt = Runtime.getRuntime();
        String[] args = {DOT, "-Tgif", dot.getAbsolutePath(), "-o", img.getAbsolutePath(), "-Tcmapx", "-o", map.getAbsolutePath()};
        Process p = rt.exec(args);
        p.waitFor();
     }
     catch (java.io.IOException ioe) {
       throw new ApplicationException("Unable to read dot file or create image or map files.");
     }
     catch (java.lang.InterruptedException ie) {
       throw new ApplicationException("The dot program was interrupted.");
     }
     logger.info("END - writeImageMap");
     return map;
   }

}


package edu.upenn.cbil.magetab.preprocessors;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.google.common.base.Charsets;
import com.google.common.base.Joiner;
import com.google.common.collect.Lists;
import com.google.common.io.Files;

import edu.upenn.cbil.magetab.model.FactorValue;
import edu.upenn.cbil.magetab.model.FactorValueRow;
import edu.upenn.cbil.magetab.utilities.ApplicationException;

public class FactorValuePreprocessor {
  public static Map<Integer, FactorValueRow> factorValueMap;

  /**
   * Splits the factor values out from the sdrf file and replaces the original sdrf file
   * with one not having any factor values.  This was done because we add comments like FV Table
   * and FV Row Id associated with a particular factor value.  Factor values in MAGE-TAB do
   * not allow comments.  So we need to handle factor values independently.
   * @param filename - sdrf file
   */
  public void process(String filename) {
    List<String> processedSdrf = new ArrayList<>();
    List<String> factorValueData = new ArrayList<>();
    factorValueMap = new HashMap<>();
    try {
      List<String> lines = Files.readLines(new File(filename), Charsets.UTF_8);
      String[] fields = lines.get(0).split("\\t");
      int startingIndex = -1;
      // Locating in the sdrf file at which column the factor values start to appear.
      for(int i = 0; i < fields.length; i++) {
    	String field = fields[i].replaceAll("\\s*", "");    	
        if(field.startsWith("FactorValue[")) {
          startingIndex = i;
          break;
        }
      }
      // Used Lists.partition to separate out the factor value columns
      if(startingIndex >= 0) {
        for(String line : lines) {
          List<String> items = Arrays.asList(line.split("\\t"));
          List<List<String>> sublists = Lists.partition(items, startingIndex);
          processedSdrf.add(Joiner.on("\t").join(sublists.get(0)));
          factorValueData.add(Joiner.on("\t").join(sublists.get(1)));
        }
        String newSdrf = Joiner.on("\n").join(processedSdrf);
        Files.write(newSdrf, new File(filename), Charsets.UTF_8);
        prepareFactorValueData(factorValueData);
      }
    }
    catch (IOException ioe) {
      throw new ApplicationException("Problem with srdf file.");
    }
  }
  
  /**
   * Assembles the factor value rows into a hash map keyed by row
   * @param factorValueData - the raw factor value data (one string per row) removed from the raw sdrf
   */
  public void prepareFactorValueData(List<String> factorValueData) {
	for(int i = 1; i < factorValueData.size(); i++) {
	  FactorValueRow factorValueRow = new FactorValueRow(FactorValue.parseFactorValues(factorValueData.get(0), factorValueData.get(i), i + 1));
	  if(!factorValueRow.isEmpty()) {
	    factorValueMap.put(factorValueRow.getRow(), factorValueRow);
	  }
	}
  }
}

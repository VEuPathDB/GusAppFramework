package edu.upenn.cbil.limpopo.model;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;
import edu.upenn.cbil.limpopo.model.ExternalDatabase;

public class ExternalDatabase {
  private String name;
  private String link;
  private String version;
  public static Map<String, ExternalDatabase> map;
  public static Logger logger = LoggerFactory.getLogger(ExternalDatabase.class);
  
  public ExternalDatabase(String name, String link, String version) {
    this.name = name;
    this.link = link;
    this.version = version;
  }
  
  public String getName() {
    return name;
  }
  public void setName(String name) {
    this.name = name;
  }
  public String getLink() {
    return link;
  }
  public void setLink(String link) {
    this.link = link;
  }
  public String getVersion() {
    return version;
  }
  public void setVersion(String version) {
    this.version = version;
  }
  
  public String getRelease() {
    return this.name + "|" + this.version;
  }
  
  public String toString() {
    return ReflectionToStringBuilder.toString(this);
  }
  
  public static void populate(IDF data) {
	ExternalDatabase.map = new HashMap<>();
    Iterator<String> iterator = data.termSourceName.iterator();
    logger.debug("termSourceName size: " + data.termSourceName.size());
    logger.debug("termSourceFile size: " + data.termSourceFile.size());
    logger.debug("termSourceVersion size: " + data.termSourceVersion.size());
    int i = 0;
    while(iterator.hasNext()) {
      String name = iterator.next();
      String link = data.termSourceFile.size() > i ? data.termSourceFile.get(i) : "";
      String version = data.termSourceVersion.size() > i ? data.termSourceVersion.get(i) : "";
      ExternalDatabase externalDatabase = new ExternalDatabase(name, link, version);
      logger.debug(externalDatabase.toString());
      ExternalDatabase.map.put(name, externalDatabase);
      i++;
    }
  }
  
}

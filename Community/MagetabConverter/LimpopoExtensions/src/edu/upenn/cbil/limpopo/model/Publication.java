package edu.upenn.cbil.limpopo.model;

import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;
import edu.upenn.cbil.limpopo.utils.AppUtils;

public class Publication {
  public static Logger logger = LoggerFactory.getLogger(Publication.class);
  private boolean addition; 
  private String pubmedId;
  
  public Publication() {
    addition = false;
  }
  
  public final boolean isAddition() {
    return addition;
  }
  public final void setAddition(boolean addition) {
    this.addition = addition;
  }
  public final String getPubmedId() {
    return pubmedId;
  }
  public final void setPubmedId(String pubmedId) {
    this.pubmedId = AppUtils.removeTokens(pubmedId);
  }
  
  public static List<Publication> populate(final IDF data) {
    List<Publication> publications = new ArrayList<>();
    List<String> pubmedIds = data.pubMedId;
    for(String pubmedId : pubmedIds) {
      Publication publication = new Publication();
      publication.setPubmedId(pubmedId);
      if(!pubmedId.equalsIgnoreCase(publication.getPubmedId())) {
        publication.setAddition(true);
      }
      publications.add(publication);
    }
    return publications;
  }
}

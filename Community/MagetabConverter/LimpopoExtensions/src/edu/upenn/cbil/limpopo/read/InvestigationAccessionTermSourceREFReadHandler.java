package edu.upenn.cbil.limpopo.read;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;
import uk.ac.ebi.arrayexpress2.magetab.exception.ParseException;
import uk.ac.ebi.arrayexpress2.magetab.handler.idf.IDFReadHandler;
import net.sourceforge.fluxion.spi.ServiceProvider;

/**
 * Custom read header added to deal with the Investigation Accession source reference term, which
 * was neglected in Limpopo 1.1.2.
 * @author crisl
 *
 */
@ServiceProvider
public class InvestigationAccessionTermSourceREFReadHandler extends IDFReadHandler {
  public static Logger logger = LoggerFactory.getLogger(InvestigationAccessionTermSourceREFReadHandler.class);
  private static final String HEADER = "investigationaccessiontermsourceref";
  private static final String TYPE = "Investigation Accession Term Source REF";
  
  /**
   * Check for the Investigation Accession Term Source REF Header
   */
  @Override
  protected boolean canReadHeader(String header) {
	logger.trace("Inside canReadHeader of " + getClass().getSimpleName() + ". Header: " + header);
	return header.equals(HEADER);
  }

  /**
   * Treating Investigation Accession Term Source REF here as a comment as a workaround so we
   * can take advantage of Limpopo's parsing engine.  The comment is prepended with "0:" to
   * be consistent with the custom way comments are handled here.
   */
  @Override
  protected void readValue(IDF idf, String value, int lineNumber, String... types) throws ParseException {
    logger.trace("Inside readValue of " + getClass().getSimpleName() + ". Value: " + value);
    types = new String[] {TYPE};
    idf.addComment(types[0], "0:" + value);
    idf.getLayout().addCommentLocation(types[0], lineNumber);
  }
	
}
package edu.upenn.cbil.limpopo.read;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.IDF;
import uk.ac.ebi.arrayexpress2.magetab.exception.ParseException;
import uk.ac.ebi.arrayexpress2.magetab.handler.idf.IDFReadHandler;
import net.sourceforge.fluxion.spi.ServiceProvider;

/**
 * Custom read header added to deal with multiple comments belonging to the same type, which was
 * was neglected in Limpopo 1.1.2.  For example, a Comment[Zip] might exist for every contact in the
 * idf.  Limpopo 1.1.2 saves a single comment for a given type (e.g., Zip).  The workaround here
 * was to make each comment unique by pre-pending it with a static count and the semi-colon 
 * separator.
 * @author crisl
 *
 */
@ServiceProvider
public class CommentReadHandler extends IDFReadHandler {
  public static Logger logger = LoggerFactory.getLogger(CommentReadHandler.class);
  private static final String HEADER = "comment";
  private static int counter = 0;
  
  /**
   * Check for Comment header
   */
  @Override
  public boolean canReadHeader(String header) {
    logger.trace("Inside canReadHeader of " + getClass().getSimpleName() + ".  Header: " + header);
    return header.startsWith(HEADER);
  }
  
  /**
   * Customized to overcome Limpopo's 1.1.2 failure to allow multiple comments for the same
   * type.  A static counter is used internally to provide uniqueness.
   */
  @Override
  public void readValue(IDF idf, String value, int lineNumber, String... types) throws ParseException {
    logger.trace("Inside readValue of " + getClass().getSimpleName() + ". Value: " + value);  
    if (types.length == 0) {
      types = new String[] {""};
    }
    idf.addComment(types[0], counter + ":" + value);
    counter++;
    idf.getLayout().addCommentLocation(types[0], lineNumber);
  }

}
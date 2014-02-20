package edu.upenn.cbil.biomatgraph;

/**
 * Class used to re-wrap application exceptions of various types (particularly checked) as
 * a runtime exception so it can bubble up.
 * @author crislawrence
 *
 */
public class ApplicationException extends RuntimeException {

  private static final long serialVersionUID = 1L;

  public ApplicationException() {
    super();
  }
	  
  public ApplicationException(String msg) {
    super(msg);
  }
}
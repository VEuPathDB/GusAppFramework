package edu.upenn.cbil.biomatgraph;

public class ApplicationException extends RuntimeException {

  private static final long serialVersionUID = 1L;

  public ApplicationException() {
    super();
  }
	  
  public ApplicationException(String msg) {
    super(msg);
  }
}
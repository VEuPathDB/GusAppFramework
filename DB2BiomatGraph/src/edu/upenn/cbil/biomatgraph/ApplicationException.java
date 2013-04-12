package edu.upenn.cbil.biomatgraph;

public class ApplicationException extends RuntimeException {

  public ApplicationException() {
    super();
  }
	  
  public ApplicationException(String msg) {
    super(msg);
  }
}
package edu.upenn.cbil.limpopo.utils;

public class AppException extends Exception {
  private static final long serialVersionUID = -1001976752018282622L;
  private Integer code;
 
  public AppException() {
    super("10001");
    this.code = 10001;
  }
  
  public AppException(Integer code) {
    super(code.toString());
    this.code = code;
  }

  public AppException(String msg, Integer code) {
    super(msg);
    this.code = code;
  }

  public AppException(String msg, Integer code, Exception e) {
    super(msg, e);
    this.code = code;
  }
  
  public AppException(Integer code, Exception e) {
    super(e);
    this.code = code;
  }
  
  public Integer getCode() {
    return code;
  }

}


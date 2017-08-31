package edu.upenn.cbil.magetab.utilities;

import org.mged.magetab.error.ErrorItem;

import uk.ac.ebi.arrayexpress2.magetab.listener.ErrorItemListener;

public class ErrorListener implements ErrorItemListener  {
  private static int errorCount = 0;

  @Override
  public void errorOccurred(ErrorItem item) {
    errorCount++;
    if(item != null) {
      String errorType = item.getErrorType() == null ? "NA" : item.getErrorType().toUpperCase();
      String message = item.getMesg() == null ? "NA" : item.getMesg();
      String caller = item.getCaller() == null ? "NA" : item.getCaller();
      String comment = item.getComment() == null ? "NA" : item.getComment();
      System.err.println(errorCount + ". " + errorType + " ERROR: Code - " + item.getErrorCode() + ", Message - " + message);
      System.err.println("Source: " + caller + ", Comment: " + comment);
      System.err.println("");
    }
    else {
      System.err.println("Error thrown, but without information.");
    }
  }

  public static int getErrorCount() {
    return errorCount;
  }

  public static void setErrorCount(int errorCount) {
    ErrorListener.errorCount = errorCount;
  }
  
}

package edu.upenn.cbil.magetab.utilities;

import org.mged.magetab.error.ErrorItem;

import uk.ac.ebi.arrayexpress2.magetab.listener.ErrorItemListener;

public class ErrorListener implements ErrorItemListener  {
  private static int errorCount = 0;

  public void errorOccurred(ErrorItem item) {
    errorCount++;
    System.err.println(errorCount + ". " + item.getErrorType().toUpperCase() + " ERROR: Code - " + item.getErrorCode() + ", Message - " + item.getMesg());
    System.err.println("Source: " + item.getCaller() + ", Comment: " + item.getComment());
    System.err.println("");
  }

  public static int getErrorCount() {
    return errorCount;
  }

  public static void setErrorCount(int errorCount) {
    ErrorListener.errorCount = errorCount;
  }
  
}

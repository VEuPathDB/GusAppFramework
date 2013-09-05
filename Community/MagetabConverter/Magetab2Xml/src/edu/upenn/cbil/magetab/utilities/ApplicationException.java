package edu.upenn.cbil.magetab.utilities;

public class ApplicationException extends RuntimeException {
  private static final long serialVersionUID = 1529721598323901590L;
  public static final String MISSING_ARG_ERROR = "Must provide an Excel workbook name. ";
  public static final String BAD_EXCEL_ERROR = "Excel workbook name must have an xslx extension. ";
  public static final String EXCEL_PARSE_ERROR = "Problems encountered parsing the Excel workbook. ";
  public static final String CMD_PARSE_ERROR = "Command not successfully parsed. ";
  public static final String MAGETAB_ERROR = "One or more MAGE-TAB conversion errors occurred. ";
  public static final String FILE_NOT_FOUND_ERROR = "Unable to locate or create file: ";
  public static final String FILE_IO_ERROR = "Unable to read or write file(s): ";
  public static final String FILE_CLOSE_ERROR = "Unable to close stream for file: ";
  public static final String DIRECTORY_CREATION_ERROR = "Unable to create directory: ";
  public static final String FILE_READ_ERROR = "Unable to read from file: ";
  public static final String FILE_WRITE_ERROR = "Unable to write to file: ";
  public static final String FILE_NON_EXISTANT_ERROR = "File does not exist: ";
  public static final String FILE_CREATION_ERROR = "Unable to create file: ";
  public static final String DOT_INTERRUPTION_ERROR = "DOT file processing was interrupted.";
  
  public ApplicationException() {
    super();
  }

  public ApplicationException(String msg) {
    super(msg);
  }

  public ApplicationException(String msg, Exception e) {
    super(msg, e);
  }

}

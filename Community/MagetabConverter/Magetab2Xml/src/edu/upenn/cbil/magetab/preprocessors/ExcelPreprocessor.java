package edu.upenn.cbil.magetab.preprocessors;

import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.IDF;
import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.SDRF;
import static edu.upenn.cbil.magetab.utilities.ApplicationConfiguration.TEXT_EXT;
import static edu.upenn.cbil.magetab.utilities.ApplicationException.EXCEL_PARSE_ERROR;

import java.awt.Color;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import org.apache.commons.lang.StringUtils;
import org.apache.poi.openxml4j.exceptions.InvalidFormatException;
import org.apache.poi.openxml4j.opc.OPCPackage;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFCell;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFColor;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.magetab.utilities.ApplicationConfiguration;
import edu.upenn.cbil.magetab.utilities.ApplicationException;

/**
 * Renders the idf and sdrf worksheets on a mage-tab Excel workbook into idf and sdrf text files
 * respectively.  It should be noted that everything is treated as a string.  The workbook fields
 * should be set up that way.  Otherwise, an entry for MAGE-TAB Version, for example, could be
 * represented as 1.09999999999 rather than 1.1.  It is too late to repair these issues at this
 * stage.
 * @author crisl
 *
 */
public class ExcelPreprocessor {
  private File workbookFile;
  private String directoryName;
  public static Logger logger = LoggerFactory.getLogger(ExcelPreprocessor.class);
  public static final String SDRF_FILE_IDF_FIELD = "SDRF File";
  public static final String UNHANDLED_TYPE = "Unhandled cell type: ";
  public static final String FILE_CLOSE_FAILURE = "Could not close the preprocess file. ";
  
  /**
   * ExcelPreprocessor constructor.  The baseFilename is used as a basis for
   * the idf and sdrf text file names.  The expectation is that the baseFilename will be
   * the simple workbook name normally.
   * @param workbookFile - path to workbook xlsx file
   * @param baseFilename - base name upon which idf and sdrf text filenames are built.
   */
  public ExcelPreprocessor(File workbookFile, String directoryName) {
    this.directoryName = directoryName;
    this.workbookFile = workbookFile;
  }
  
  /**
   * Renders the individual worksheets of the Excel workbook into text files.  The
   * expected worksheets are labeled idf or sdrf.  The convention is to create
   * idf and sdrf text files in the format 'baseFilename_idf|sdrf.txt' where the
   * baseFilename is the original workbook name sans extension.
   * @param type - idf or sdrf
   * @return - the name of the idf or sdrf text file processed.
   * @throws ApplicationException
   */
  public String process(String type) {
    String textFilename = directoryName + File.separator + type + "." + TEXT_EXT;
    BufferedWriter writer = null;
    try {
      writer = new BufferedWriter(new FileWriter(new File(textFilename)));
      OPCPackage opcPackage = OPCPackage.open(workbookFile);
      XSSFWorkbook workbook = new XSSFWorkbook(opcPackage);
      int sheetIndex = findSheet(workbook, type);
      Sheet sheet = workbook.getSheetAt(sheetIndex);
      int rows = sheet.getLastRowNum() + 1;
      for(int i = 0; i < rows; i++) {  
        Row row = sheet.getRow(i); 
        if(row != null) {
          StringBuffer line = new StringBuffer();
          int cols = sheet.getRow(i).getLastCellNum();
          for(int j = 0; j < cols; j++) {
            Cell cell = row.getCell(j);
            String value = getCellValue(cell);
            if(j != 0 ) line.append("\t");
            line.append(value);
          }
          //System.out.println("Line " + (i) + ":" + line);
          if(IDF.equalsIgnoreCase(type) && line.toString().equals(SDRF_FILE_IDF_FIELD)) {
            line.append("\t" + SDRF + "." + TEXT_EXT);
          }
          writer.write(line.toString().trim());
          writer.newLine();
        }
      }
    }
    catch(InvalidFormatException | IOException ex) {
      throw new ApplicationException(EXCEL_PARSE_ERROR, ex);
    }
    finally {
      try {
        if(writer != null) writer.close();
      }
      catch(IOException ioe) {
        logger.error(FILE_CLOSE_FAILURE, ioe);
      }  
    }
    return textFilename;
  }
  
  /**
   * Locate the sheet defined by type (idf or sdrf expected)
   * @param workbook - Excel workbook object
   * @param type - idf or sdrf string
   * @return - appropriate worksheet
   */
  protected int findSheet(XSSFWorkbook workbook, String type) {
    int index = -1;
    int n = workbook.getNumberOfSheets();
    for(int i = 0; i < n; i++) {
      if(workbook.getSheetName(i).equalsIgnoreCase(type)) {
        index = i;
      }
    }
    return index;
  }
  
  /**
   * Fetch string rendering of the value of a given cell
   * @param cell - cell object
   * @return - string value of cell object.  Empty if the cell type cannot be determined.
   */
  protected String getCellValue(Cell cell) {
    String value = "";
    if(cell != null) {
      switch (cell.getCellType()) {
        case Cell.CELL_TYPE_STRING:
          value = cell.getStringCellValue();
          break;
        case Cell.CELL_TYPE_NUMERIC:
          cell.setCellType(Cell.CELL_TYPE_STRING);
          value = cell.getStringCellValue();
          break;
        case Cell.CELL_TYPE_BOOLEAN:
          value = String.valueOf(cell.getBooleanCellValue());
          break;
        case Cell.CELL_TYPE_BLANK: 
          break;
        default:
          logger.warn(UNHANDLED_TYPE + cell.getCellType());
          break;
      }
      if(isAddition((XSSFCell)cell) && StringUtils.isNotEmpty(value)) {
        value = AppUtils.ADDED_CELL + value;
      }
    }
    return value;
  }
  
  /**
   * Determines what cells constitute additions based upon yellow highlighting on the Excel
   * spreadsheet.  Highlighting into IDF or SDRF headers is disallowed and throws a Runtime
   * Exception
   * @param cell - the cell to check for addition highlighting
   * @return - whether or not the cell constitutes an addition
   */
  protected boolean isAddition(XSSFCell cell) {
	boolean addition = false;
	XSSFCellStyle style = cell.getCellStyle();
	XSSFColor color = style.getFillForegroundColorColor();
    if(color != null) {
      String hexCode = "0x" + color.getARGBHex().substring(2);
      Color awtColor = Color.decode(hexCode); 
      if(awtColor.equals(Color.YELLOW)) {
        if(ApplicationConfiguration.IDF.equalsIgnoreCase(cell.getSheet().getSheetName()) && cell.getColumnIndex() == 0) {
          throw new ApplicationException("Highlighting is not permitted in IDF headers (Check row " + (cell.getRowIndex() + 1) + " ).  Please correct and resubmit.");
        }
        if(ApplicationConfiguration.SDRF.equalsIgnoreCase(cell.getSheet().getSheetName()) && cell.getRowIndex() == 0) {
          throw new ApplicationException("Highlighting is not permitted in SDRF headers (Check col " + (cell.getColumnIndex() + 1) + " ).  Please correct and resubmit.");
        }
        addition = true;
      }
    }
	return addition;
  }
  
}

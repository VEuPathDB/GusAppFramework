/*
 * Created on Oct 26, 2004
 */
package org.gusdb.dbadmin.reader;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.Properties;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.HousekeepingColumn;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.dbadmin.util.DatabaseValidator;

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public abstract class SchemaReader {
	
	protected final Log log = LogFactory.getLog(SchemaReader.class);
	protected Properties properties = new Properties();
	
	protected ArrayList<HousekeepingColumn> housekeepingColumns = new ArrayList<HousekeepingColumn>();
	protected ArrayList<HousekeepingColumn> verHousekeepingColumns = new ArrayList<HousekeepingColumn>();
	
	public final Database read() {
		Database db = new Database();
		return doRead(db);
	}
	
	public final Database read(Database db) {
		return doRead(db);
	}
		
	private final Database doRead(Database db) {
		readProperties();
		initHousekeeping();
		setUp();
		log.info("Reading Database");
		db = readDatabase(db);
		tearDown();
		if ( ! DatabaseValidator.validate(db, true, false) ) {
			log.warn("Invalid database read");
		}
		return db;
	}
	
	protected boolean valid(GusTable table) throws Exception {
		return true;
		//check in here for nulls (documentation)
		// constraint without ref columns
		//
	}
	
	protected abstract Database readDatabase(Database db);
	protected abstract void setUp();
	protected abstract void tearDown();
	
	protected final void readProperties() {
		File propertyFile;

		log.debug("Reading properties");
		try {
			propertyFile = new File(System.getProperty("PROPERTYFILE"));
			properties.load(new FileInputStream(propertyFile));
			System.setProperty("SEQUENCE_START", properties.getProperty("sequenceStart"));
		} catch (IOException e) {
		    log.error("Could not initialize SchemaReader due to "+e);
		    throw new RuntimeException(e);
		}
	}
	
	protected Column getColumn(Collection columns, String name ) {
		if ( name == null ) return null;
		if ( columns == null ) return null;
		for (Iterator i = columns.iterator(); i.hasNext(); ) {
			Column col = (Column) i.next();
			if ( col.getName().compareToIgnoreCase(name) == 0 ) {
				return col;
			}
		}
		return null;
	}
	
	protected Schema getSchema(Database db, String name ) {
		if ( name == null ) return null;
		if ( db == null ) return null;
        for ( Schema sch : db.getAllSchemas() ) {
			if ( sch.getName().compareToIgnoreCase(name) == 0 ) {
				return sch;
			}
		}
		return null;
	}
	
	private void initHousekeeping() {
		String housekeepingList = properties.getProperty("housekeepingColumns");
		String housekeepingVerList = properties.getProperty("housekeepingColumnsVer");
		
		String[] housekeepingCols = housekeepingList.split(",");
		initHousekeeping(housekeepingColumns, housekeepingCols);
		String[] housekeepingVerCols = housekeepingVerList.split(",");
		initHousekeeping(verHousekeepingColumns, housekeepingVerCols);
		
	}
	
	private void initHousekeeping(Collection array, String[] housekeepingCols) {
		for ( int i = 0; i<housekeepingCols.length; i++ ) {
			String columnSpec = properties.getProperty("hkspec."+housekeepingCols[i]);
			String[] columnSpecs = columnSpec.split(",", 4);
			HousekeepingColumn column = new HousekeepingColumn();
			column.setName(housekeepingCols[i]);
			column.setType(Column.ColumnType.valueOf(columnSpecs[0].toUpperCase()));
			column.setLength((new Integer(columnSpecs[1])).intValue());
			column.setPrecision((new Integer(columnSpecs[2])).intValue());
			array.add(column);			
		}
	}
	
}

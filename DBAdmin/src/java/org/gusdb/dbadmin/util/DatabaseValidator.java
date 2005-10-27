/*
 *  Created on 2/25/05
 *
 */
package org.gusdb.dbadmin.util;

import java.util.Iterator;

import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.dbadmin.model.GusSchema;
import org.gusdb.dbadmin.model.Table;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.Constraint;
import org.gusdb.dbadmin.model.GusColumn;
import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.Index;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;


/**
 *@author     msaffitz
 *@created    April 29, 2005
 *@version    $Revision$ $Date$
 */
public class DatabaseValidator {

	protected final static Log log  = LogFactory.getLog( DatabaseValidator.class );


	/**
	 *  Runs all checks agains the supplied database.
	 *
	 *@param  db  The database to be validated
	 *@return     False if any check failed
	 */

	public static boolean validate( Database db ) {
		return DatabaseValidator.validate( db, true, false );
	}


	/**
	 *  Runs all checks against the database.
	 *
	 *@param  db     The database to be validated
	 *@param  fatal  If false, non-fatal checks will be ignored
	 *@param  fix    If true, attempt to fix errors
	 *@return        If fatal is false, false if any check failed. Otherwise false
	 *      if any fatal check failed.
	 */

	public static boolean validate( Database db, boolean fatal, boolean fix ) {
		log.info( "Validating Database: '" + db.getName() + "'" );

		boolean valid  = true;

		valid = DatabaseValidator.fkSizeCompatability( db, fix ) || fatal;
		valid = DatabaseValidator.identifierLengths( db );

		return valid;
	}


	/**
	 *  Checks the provided database to ensure that all columns with foreign key
	 *  constraints are of a compatible type and size to the constrained column.
	 *
	 *@param  db  Description of the Parameter
	 *@param  fix If true, attempt to fix
	 *@return     Description of the Return Value
	 */
	public static boolean fkSizeCompatability( Database db, boolean fix ) {
		boolean valid = true;

        for ( GusSchema schema : db.getGusSchemas() ) {
			log.debug( "Checking FK Compatability for Schema '" + schema.getName() + "'" );
			for ( GusTable table : schema.getTables() ) {
				valid = checkFkCompatabilityTo( table, fix );
			}
		}
		return valid;
	}


	public static boolean identifierLengths( Database db ) {
		int length = 30;
		log.debug("Checking to make sure all identifiers are less than " + 
			length + " characters");		
		
		boolean valid = true;
		
        for ( GusSchema schema : db.getGusSchemas() ) {
			valid = checkLength(schema.getName(), length);
			for ( GusTable table : schema.getTables() ) {
				valid = checkLength(table.getName(), length);
				if ( table.getPrimaryKey() != null ) {
					valid = checkLength(table.getPrimaryKey().getName() , length );
				}
				
				if ( table.getClass() == GusTable.class ) {
					for ( Iterator k = ((GusTable)table).getConstraints().iterator(); k.hasNext(); ) {
						Constraint con = (Constraint) k.next();
						valid = checkLength(con.getName(), length);
					}
					for ( Iterator k = ((GusTable)table).getIndexs().iterator(); k.hasNext(); ) {
						Index index = (Index) k.next();
						valid = checkLength(index.getName(), length);
					}
				}
                for ( Column col : table.getColumnsExcludeSuperclass(false) ) {
					valid = checkLength(col.getName(), length);
				}
			}
		}
			
		return valid;
	}
	
	
	

	private static boolean checkFkCompatabilityTo( GusTable table, boolean fix ) {
		log.debug( "Checking FK Compatability against '" + table.getName() + "'" );

		boolean valid  = true;

		for ( Iterator i = table.getReferentialConstraints().iterator(); i.hasNext();  ) {
			Constraint c        = (Constraint) i.next();

			Object[] refCol  = c.getReferencedColumns().toArray();
			Object[] conCol  = c.getConstrainedColumns().toArray();
		
			if ( refCol.length != conCol.length ) {
				log.warn( "'" + table.getName() + "' has a different number of constrained and " +
					"referenced columns.  Can't compare, returning false" );
				return false;
			}

			for ( int j = 0; j < refCol.length; j++ ) {
				valid = checkFkCompatabilityBetween( (GusColumn) conCol[j], (GusColumn) refCol[j], fix );
			}
		}
		return true;
	}


	private static boolean checkFkCompatabilityBetween( GusColumn source, GusColumn target, boolean fix ) {
		String msg  = "differs between '" + source.getName() + "' (from '" +
			source.getTable().getName() + "') and '" + target.getName() + "' (from '" +
			target.getTable().getName() + "')";

		if ( source.getType() != target.getType() ) {
			log.warn( "Type " + msg );
			if ( fix ) {
				source.setType(target.getType());
				log.warn( "  Type Fixed" );
			} else {
				return false;
			}
		}
		if ( source.getLength() < target.getLength() ) {
			log.warn( "Length " + msg );
			if ( fix ) {
				source.setLength(target.getLength());
				log.warn("  Length Fixed");
			} else {
				return false;
			}
		}
		if ( source.getPrecision() < target.getPrecision() ) {
			log.warn( "Precision " + msg );
			if ( fix ) {
				source.setPrecision(target.getPrecision());
				log.warn("  Precision Fixed");
			} else {
				return false;
			}
		}
		return true;
	}

	private static boolean checkLength(String str, int maxSize) {
		if ( str == null ||
			 str.length() < maxSize + 1 ) return true;
		log.error("The identifier '" + str + "' is longer than " + maxSize);
		return false;
	}

}



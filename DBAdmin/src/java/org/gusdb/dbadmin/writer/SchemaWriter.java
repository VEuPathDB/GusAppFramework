/*
 * Created on Oct 28, 2004
 */
package org.gusdb.dbadmin.writer;

import java.io.IOException;
import java.io.Writer;
import java.util.Properties;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.util.DatabaseValidator;

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public abstract class SchemaWriter {
	
    protected final Log log = LogFactory.getLog(SchemaWriter.class);
    protected Properties properties = new Properties();
    protected Writer oStream;
	
    public final void write(Writer oStream, Database db) throws IOException {
		this.oStream = oStream;
		setUp();
		if ( ! DatabaseValidator.validate(db, true, true) ) {
			log.error("Database is invalid.  Refusing to write");
			tearDown();
			throw new RuntimeException("Invalid Database-- Refusing to write");
		}
		log.info("Writing Database");
		writeDatabase(db);
		oStream.flush();
		tearDown();
    }
	
    protected abstract void writeDatabase(Database db) throws IOException;
    protected abstract void setUp();
    protected abstract void tearDown();
	
}

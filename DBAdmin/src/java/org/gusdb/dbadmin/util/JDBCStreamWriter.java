/*
 *  Created on Jan 25, 2005
 */
package org.gusdb.dbadmin.util;

import java.io.IOException;
import java.io.Writer;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Iterator;

/**
 *@author     msaffitz
 *@created    April 29, 2005
 *@version    $Revision$ $Date$
 */
public class JDBCStreamWriter extends Writer {

	private Connection connection;
	private String currentBuf;
	private ArrayList sts          = new ArrayList();


	public JDBCStreamWriter( Connection connection ) {
		this.connection = connection;
	}


	@Override
  public void write( char[] cbuf, int off, int len ) throws IOException {
		if ( currentBuf == null ) {
			currentBuf = new String();
		}
		currentBuf = currentBuf.concat( String.copyValueOf( cbuf, off, len ) );
	}


	/**
	 *@exception  IOException
	 *@see                     java.io.Writer#flush()
	 */
	@Override
  public void flush() throws IOException {
		extractStatements();

		for ( Iterator i = sts.iterator(); i.hasNext();  ) {

		String sql  = (String) i.next();

			try {
			Statement st  = connection.createStatement();

				st.execute( sql );
				st.close();
			}
			catch ( SQLException e ) {
				throw new IOException( "Error executing SQL: '" + sql +
					"' Error: " + e.getLocalizedMessage() );
			}
		}
		sts = new ArrayList();
	}


	/**
	 *@exception  IOException
	 *@see                     java.io.Writer#close()
	 */
	@Override
  public void close() throws IOException {
		flush();
		try {
			connection.close();
		}
		catch ( SQLException e ) {
			throw new IOException( e.getLocalizedMessage() );
		}
	}


	private void extractStatements() {
		int sIndex         = 0;
		boolean inComment  = false;

		for ( int i = 0; i < currentBuf.length() && sIndex < currentBuf.length(); i++ ) {

			// Ignore all comments starting with --
			if ( currentBuf.charAt( i ) == '-' &&
				currentBuf.charAt( i + 1 ) == '-' ) {
				inComment = true;
			}
			// New line terminates a comment
			else if ( inComment &&
				Character.getType( currentBuf.charAt( i ) ) == Character.CONTROL ) {
				inComment = false;
				sIndex = i + 1;
			}
			// If we're not in a comment, and we reach a semi-colon, then extract the statement
			else if ( !inComment &&
				currentBuf.charAt( i ) == ';' ) {
				sts.add( currentBuf.substring( sIndex, i ) );
				sIndex = i + 1;
			}
		}

		// Done extracting.  Flush statements from buffer
		if ( sIndex >= currentBuf.length() ) {
			currentBuf = new String();
		}
		else {
			currentBuf = currentBuf.substring( sIndex );
		}
	}

}


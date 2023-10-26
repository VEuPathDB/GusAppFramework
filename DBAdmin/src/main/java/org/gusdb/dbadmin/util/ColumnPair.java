/*
 *  Created on Oct 28, 2004
 *  $Id$
 */
package org.gusdb.dbadmin.util;

/**
 *@author     msaffitz
 *@created    May 24, 2005
 *@version    $Revision$ $Date$
 */
public class ColumnPair {

	private String viewName;
	private String tableName;
	
	public ColumnPair( String viewName, String tableName ) {
		this.viewName  = viewName;
		this.tableName = tableName;
	}
	
	public ColumnPair() {
	}
	
	public String getViewName() {
		return viewName;
	}
	
	public void setViewName( String viewName ) {
		this.viewName = viewName;
	}
	
	public String getTableName() {
		return tableName;
	}
	
	public void setTableName( String tableName ) {
		this.tableName = tableName;
	}
}


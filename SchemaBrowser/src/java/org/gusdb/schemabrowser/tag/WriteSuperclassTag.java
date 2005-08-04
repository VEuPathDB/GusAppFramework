/**
 * 
 */
package org.gusdb.schemabrowser.tag;

import java.io.IOException;

import javax.servlet.jsp.JspWriter;

import org.gusdb.dbadmin.model.GusTable;

/**
 * @author msaffitz
 *
 */
public class WriteSuperclassTag extends TableCellWriter {

    /* (non-Javadoc)
     * @see org.gusdb.schemabrowser.tag.TableCellWriter#writeCell(javax.servlet.jsp.JspWriter)
     */
    protected void writeCell( JspWriter out ) throws IOException {
       GusTable Ltable = (GusTable) table;
        
        if ( Ltable.getSuperclass() == null ) return;
       
       out.print("<a href=\"table.htm?schema=" + Ltable.getSuperclass().getSchema().getName() );
       out.print("&table=" + Ltable.getSuperclass().getName() + "\">");
       out.print(Ltable.getSuperclass().getSchema().getName() + "::");
       out.println(Ltable.getSuperclass().getName() + "</a>");
    }

}

/**
 * 
 */
package org.gusdb.schemabrowser.tag;

import java.io.IOException;

import javax.servlet.jsp.JspWriter;


/**
 * @author msaffitz
 *
 */
public class WriteActionTag extends TableCellWriter {

    /* (non-Javadoc)
     * @see org.gusdb.schemabrowser.tag.TableCellWriter#writeCell(javax.servlet.jsp.JspWriter)
     */
    protected void writeCell( JspWriter out ) throws IOException {
       
        out.print("<a href=\"table.htm?schema=" + table.getSchema().getName() + "&table=");
        out.println(table.getName() + "\">View Table</a> | ");

        out.print("<a href=\"#" + table.getSchema().getName() + table.getName() + "\" ");
        out.print("onClick=\"Toggle.display('" + table.getSchema().getName()+ "::");
        out.println(table.getName() + "');\">View Documentation</a> | ");
        
        out.print("<a href=\"edit/edit.htm?schema=" + table.getSchema().getName() + "&table=");
        out.println(table.getName() + "\">Edit</a>");
    }

}

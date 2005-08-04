/**
 * 
 */
package org.gusdb.schemabrowser.tag;

import java.io.IOException;

import javax.servlet.jsp.JspWriter;
import javax.servlet.jsp.tagext.TagSupport;

import org.gusdb.dbadmin.model.Table;

/**
 * @author msaffitz
 */
public abstract class TableCellWriter extends TagSupport {

    protected Table table = null;

    public void setTable( Table table ) {
        this.table = table;
    }

    public Table getTable( ) {
        return this.table;
    }

    public int doStartTag( ) {
        try {
            JspWriter out = pageContext.getOut( );
            out.println("<td>");
            writeCell(out);
            out.println("</td>");
        }
        catch ( IOException ex ) {
            throw new Error( "Error writing table cell" );
        }
        return SKIP_BODY;
    }

    public int doEndTag( ) {
        return SKIP_BODY;
    }

    abstract protected void writeCell(JspWriter out) throws IOException;

}

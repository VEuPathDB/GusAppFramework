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
public class WriteCategoryTag extends TableCellWriter {

    /* (non-Javadoc)
     * @see org.gusdb.schemabrowser.tag.TableCellWriter#writeCell(javax.servlet.jsp.JspWriter)
     */
    protected void writeCell( JspWriter out ) throws IOException {
        GusTable Ltable = (GusTable) getTable();
        if ( Ltable.getCategory() == null ) return;
       
       out.print("<a href=\"categoryList.htm#c:" + Ltable.getCategory().getName() + "\">" );
       out.print(Ltable.getCategory().getName() + "</a>");
    }

}

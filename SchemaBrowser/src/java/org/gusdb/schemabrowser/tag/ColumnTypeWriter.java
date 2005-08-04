/**
 * 
 */
package org.gusdb.schemabrowser.tag;

import java.util.Iterator;

import javax.servlet.jsp.JspWriter;
import javax.servlet.jsp.tagext.TagSupport;

import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.ColumnType;
import org.gusdb.dbadmin.model.Constraint;
import org.gusdb.dbadmin.model.ConstraintType;

/**
 * @author msaffitz
 */
public class ColumnTypeWriter extends TagSupport {

    private Column column = null;

    public void setColumn( Column column ) {
        this.column = column;
    }

    public Column getColumn( ) {
        return this.column;
    }

    public int doStartTag( ) {
        try {
            JspWriter out = pageContext.getOut( );
            out.println( writeType( getColumn( ) ) );
        }
        catch ( Exception ex ) {
            throw new Error( "All is not well in the world." );
        }
        return SKIP_BODY;
    }

    public int doEndTag( ) {
        return SKIP_BODY;
    }

    private String writeType( Column column ) {
        String trueType = writeTrueType( column );
        if ( !column.getConstraints( ).isEmpty( ) ) {
            for ( Iterator i = column.getConstraints( ).iterator( ); i.hasNext( ); ) {
                Constraint cons = (Constraint) i.next( );

                if ( cons.getType( ) == ConstraintType.FOREIGN_KEY ) {
                    return writeRefType( cons ) + "(<small>" + trueType + "</small>)";
                }
                if ( cons.getType( ) == ConstraintType.PRIMARY_KEY ) {
                    return trueType;
                }
            }
        }
        return trueType;
    }

    private String writeTrueType( Column column ) {
        String type = column.getType( ).toString( );

        if ( column.getType( ) == ColumnType.STRING || column.getType( ) == ColumnType.CHARACTER ) {
            type = type + "(" + column.getLength( ) + ") ";
        }
        if ( column.getType( ) == ColumnType.NUMBER && column.getLength( ) != 0 ) {
            type = type + "(" + column.getLength( ) + "," + column.getPrecision( ) + ") ";
        }
        return type;
    }

    private String writeRefType( Constraint cons ) {
        String result = "<a href=\"table.htm?schema=" + cons.getReferencedTable( ).getSchema( ).getName( ) + "&table="
                + cons.getReferencedTable( ).getName( ) + "\">"
                + cons.getReferencedTable( ).getSchema( ).getName( ) + "::" + cons.getReferencedTable( ).getName( )
                + "</a> ";
        return result;
    }

}

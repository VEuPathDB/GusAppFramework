package org.gusdb.dbadmin.model;

import java.util.ArrayList;
import java.util.List;
import java.util.TreeSet;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * @version $Revision$ $Date: 2005-06-16 16:35:04 -0400 (Thu, 16 Jun
 *          2005) $
 * @author msaffitz
 */
public class Database extends DatabaseObject {

    private static final Logger log = LogManager.getLogger( Database.class );

    private float                    version;
    private int                      patchLevel;
    private TreeSet<Schema>     schema          = new TreeSet<>( );
    private ArrayList<SuperCategory> superCategories = new ArrayList<SuperCategory>( );

    public TreeSet<Schema> getAllSchemas( ) {
        return schema;
    }

    public TreeSet<GusSchema> getGusSchemas( ) {
        TreeSet<GusSchema> gusSchemas = new TreeSet<GusSchema>( );
        for ( Schema s : getAllSchemas( ) ) {
            if ( s.getClass( ) == GusSchema.class ) {
                gusSchemas.add( (GusSchema) s );
            }
        }
        return gusSchemas;
    }

    public void addSchema( Schema schema ) {
        log.debug( "Adding schema " + schema.getName( ) );

        if ( !this.schema.contains( schema ) ) {
            this.schema.add( schema );
            schema.setDatabase( this );
        }
    }

    public void removeSchema( Schema schema ) {
        boolean removed = this.schema.remove( schema );
        if ( removed ) schema.setDatabase( (Database) null );
    }

    public Schema getSchema( String name ) {
        if ( name == null ) return null;

        for ( Schema s : getAllSchemas( ) ) {
            if ( s.getName( ).compareToIgnoreCase( name ) == 0 ) {
                return s;
            }
        }
        return null;
    }

    public float getVersion( ) {
        return version;
    }

    public void setVersion( float version ) {
        this.version = version;
    }

    public int getPatchLevel( ) {
        return patchLevel;
    }

    public void setPatchLevel( int patchLevel ) {
        this.patchLevel = patchLevel;
    }    
    
    public ArrayList<SuperCategory> getSuperCategories( ) {
        return this.superCategories;
    }

    public Category getCategory( String name ) {
        for ( Category cat : getCategories( ) ) {
            if ( cat.getName( ) != null && cat.getName( ).equalsIgnoreCase( name ) ) return cat;
        }
        return null;
    }

    public ArrayList<Category> getCategories( ) {
        ArrayList<Category> categories = new ArrayList<Category>( );
        for ( SuperCategory superCat : getSuperCategories( ) ) {
            categories.addAll( superCat.getCategories( ) );
        }
        return categories;
    }

    public void setSuperCategories( ArrayList<SuperCategory> superCategories ) {
        for ( SuperCategory s : getSuperCategories( ) ) {
            removeSuperCategory( s );
        }
        for ( SuperCategory s : getSuperCategories( ) ) {
            addSuperCategory( s );
        }
    }

    public void addSuperCategory( SuperCategory superCategory ) {
        if ( !this.superCategories.contains( superCategory ) ) {
            this.superCategories.add( superCategory );
            superCategory.setDatabase( this );
        }
    }

    public void removeSuperCategory( SuperCategory superCategory ) {
        boolean removed = this.superCategories.remove( superCategory );
        if ( removed ) superCategory.setDatabase( (Database) null );
    }

    public ArrayList<Table> getAllTables( ) {
        ArrayList<Table> tables = new ArrayList<>( );
        for ( Schema s : getAllSchemas( ) ) {
            tables.addAll( s.getTables( ) );
        }
        return tables;
    }

    public List<GusTable> getGusTables( ) {
        ArrayList<GusTable> tables = new ArrayList<GusTable>( );
        getGusSchemas()
          .forEach(schema -> schema.getTables().stream()
              .map(t -> (GusTable)t)
              .forEach(tables::add));
        return tables;
    }

    public Table getTableFromRef( String ref ) {
      String[] path = ref.split( "/" );
      if ( path.length != 2 ) {
          log.error( "Invalid table ref: " + ref );
          throw new RuntimeException( "Invalid table ref" );
      }
      Table table = getSchema( path[0] ).getTable( path[1] );
      if ( table == null ) {
          log.error( "Unable to find table for ref: " + ref );
          throw new RuntimeException( "Invalid table ref" );
      }
      log.debug( "Resolved: " + table.getName( ) );
      return table;
    }

    public Column getColumnFromRef( String ref ) {
      String[] path = ref.split( "/" );

      if ( path.length != 3 ) {
          log.error( "Invalid column ref: '" + ref + "'" );
          throw new RuntimeException( "Invalid column ref" );
      }
      try {
          Schema schema = getSchema( path[0] );
          Table table = schema.getTable( path[1] );
          Column column = table.getColumn( path[2] );

          if ( column == null ) {
              throw new NullPointerException( "No column found. Table: '" + table.getName( ) + "', Column: '"
                      + path[2] + "'" );
          }
          log.debug( "Resolved Column: '" + column.getName( ) + "'" );
          return column;
      }
      catch ( NullPointerException e ) {
          log.error( "Unable to parse ref: '" + ref + "'" );
          throw new RuntimeException( e );
      }
    }

    public void resolveReferences( ) {
        log.info( "Resolving Database References" );

        for ( GusSchema schema : getGusSchemas( ) ) {
            schema.resolveReferences( this );
        }
    }

    @Override
    public boolean equals( Object o ) {
        if (!(o instanceof Database)) return false;
        Database d = (Database)o;
        if ( version != d.getVersion() ) return false;
        return super.equals( d );
    }
}

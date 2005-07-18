/*
 * Created on Oct 26, 2004
 * TODO: null documentation
 */
package org.gusdb.dbadmin.reader;

import java.sql.Clob;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;

import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.ColumnType;
import org.gusdb.dbadmin.model.Constraint;
import org.gusdb.dbadmin.model.ConstraintType;
import org.gusdb.dbadmin.model.Database;
import org.gusdb.dbadmin.model.GusColumn;
import org.gusdb.dbadmin.model.GusSchema;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.HousekeepingColumn;
import org.gusdb.dbadmin.model.Index;
import org.gusdb.dbadmin.model.IndexType;
import org.gusdb.dbadmin.model.Schema;
import org.gusdb.dbadmin.model.Table;


/**
 * The OracleReader class connects to an existing Oracle database and uses the
 * system tables to generate the internal instantiation  of a Database.
 * Connection details are specified in an external properties file.  The
 * existing GUS instance may either be read in  full (by calling read()), or
 * a subset of the existing instance may be read by calling read(Database db)
 * with a partially populated db. The db may contain schemas or tables, in
 * which case only those objects will be instatiated, plus all relevant
 * supporting objects (indexes, etc.) which are self contained (i.e. don't
 * reference other objects).
 * 
 * <p>
 * The OracleReader class is implement by first building the rough  structure
 * of the database, consisting of the database, schemas, and columns.  Once
 * this rough structure is generated, the relevant metadata and supporting
 * objects are added (i.e. documentation, indexes, constraints). Finally, a
 * last pass is conducted to collapse multiple tables into GUS table
 * hierarchies (i.e. super and subclasses), and to remove housekeeping
 * columns.
 * </p>
 * 
 * <p>
 * This class is a specialization of the SchemaReader class, which provides
 * the public interface for OracleReader, and ensures that the setUp,
 * tearDown, and validation methods are called at the appropriate times.
 * </p>
 * 
 * @version $Revision$ $Date$
 * @author msaffitz
 * @see SchemaReader
 */
public class OracleReader
    extends SchemaReader {

    private Connection connection;
    private String CORE;
    private Collection housekeepingColumns = new HashSet();
    private Collection generatedIndexes = new HashSet();
    private Collection versionedTables = new HashSet();

    //    private Collection versionedViews      = new HashSet();
    private HashSet superClasses = new HashSet();
    private HashSet subClasses = new HashSet();
    private String dsn;
    private String username;
    private String password;

    /**
     * Creates a new OracleReader object.
     * 
     * @param dsn DOCUMENT ME!
     * @param username DOCUMENT ME!
     * @param password DOCUMENT ME!
     */
    public OracleReader(String dsn, String username, String password) {
        this.dsn = dsn;
        this.username = username;
        this.password = password;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param db DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    protected Database readDatabase(Database db) {
        log.info("Reading database: " + db.getName());
        addSchemas(db);
        addIndexes(db);
        addRemoteConstraints(db);
        log.info("Populating database: " + db.getName());
        populate(db);
        log.info("Adding Versioning: " + db.getName());

        for (Iterator i = versionedTables.iterator(); i.hasNext();) {
            ((GusTable)i.next()).setVersioned(true);
        }

        return db;
    }

    /////////////// DATABASE BUILD METHODS

    /**
     * DOCUMENT ME!
     * 
     * @param db DOCUMENT ME!
     */
    private void addSchemas(Database db) {
        log.debug("adding schemas to database: " + db.getName());

        if (db.getSchemas().size() == 0) {
            log.debug("getting all schemas (from property file) for database: " + 
                      db.getName());

            String[] schemas = properties.getProperty("gusSchemas").split(",");

            for (int i = 0; i < schemas.length; i++) {

                GusSchema schema = new GusSchema();
                schema.setName(schemas[i]);
                db.addSchema(schema);
            }
        }

        for (Iterator i = db.getSchemas().iterator(); i.hasNext();) {

            Schema schema = (Schema)i.next();

            if (schema.getClass() == GusSchema.class) {
                addTables((GusSchema)schema);
            }
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param schema DOCUMENT ME!
     * @throws RuntimeException DOCUMENT ME!
     */
    private void addTables(GusSchema schema) {
        log.debug("adding tables to schema: " + schema.getName());

        if (schema.getTables().size() == 0) {

            Statement st = null;
            ResultSet rs = null;

            try {

                st = connection.createStatement();
                rs = st.executeQuery(
                                       "SELECT table_name, tablespace_name FROM all_tables WHERE owner=upper('" + 
                                       schema.getName() + "')");

                while (rs.next()) {

                    GusTable table = new GusTable();
                    table.setName(rs.getString("table_name"));
                    table.setTablespace(rs.getString("tablespace_name"));
                    schema.addTable(table);

                    if (isImplementation(table)) {
                        table.setName(table.getName().substring(0, 
                                                                table.getName()
                             .length() - 3));
                        superClasses.add(table);
                        addSubclasses(table);
                    }
                }
            } catch (SQLException e) {
                log.error("Error querying for all tables: " + e);
                throw new RuntimeException(e);
            } finally {
                if (rs != null)
                    try { rs.close(); } catch (SQLException ignored) { }
                if (st != null)
                    try { st.close(); } catch (SQLException ignored) { }
            }

        }

        for (Iterator i = schema.getTables().iterator(); i.hasNext();) {

            GusTable table = (GusTable)i.next();

            if (table.getClass() == GusTable.class) {
                addColumns(table);
                addLocalConstraints(table);
            }
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @throws RuntimeException DOCUMENT ME!
     */
    private void addSubclasses(GusTable table) {
        log.debug("adding subclasses to table: " + table.getName());

        Statement st = null;
        ResultSet rs = null;

        try {

            st = connection.createStatement();
            rs = st.executeQuery(
                                   "SELECT subt.name FROM core.tableinfo subt, core.tableinfo supert, " + 
                                   "core.databaseinfo d " + 
                                   "WHERE upper(d.name)=upper('" + 
                                   table.getSchema().getName() + "')  " + 
                                   "AND d.database_id=supert.database_id " + 
                                   "AND upper(supert.name)=upper('" + 
                                   table.getName() + "') AND " + 
                                   "supert.table_id=subt.superclass_table_id");

            while (rs.next()) {

                GusTable subclass = new GusTable();
                subclass.setName(rs.getString("name"));
                subclass.setTablespace(table.getTablespace());
                subclass.setSchema(table.getSchema());
                subClasses.add(subclass);
                table.addSubclass(subclass);
            }
        } catch (SQLException e) {
            log.error("Error querying for subclasses: " + e);
            throw new RuntimeException(e);
        } finally {
            if (rs != null)
                try { rs.close(); } catch (SQLException ignored) { }
            if (st != null)
                try { st.close(); } catch (SQLException ignored) { }
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     */
    private void addColumns(GusTable table) {
        addColumns(table, false);

        if (!table.getSubclasses().isEmpty()) {

            for (Iterator i = table.getSubclasses().iterator(); i.hasNext();) {
                addColumns((GusTable)i.next(), true);
            }
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @param okSubclass DOCUMENT ME!
     * @throws RuntimeException DOCUMENT ME!
     */
    private void addColumns(GusTable table, boolean okSubclass) {
        log.debug("adding columns to table: " + table.getName());

        if (!okSubclass && isSubclass(table)) {

            return;
        }

        Statement st = null;
        ResultSet rs = null;

        try {

            st = connection.createStatement();
            String table_name = table.getName();
            rs = st.executeQuery(
                                   "SELECT column_name, data_type, data_length, data_scale, data_precision, nullable " + 
                                   "FROM all_tab_cols WHERE owner=upper('" + 
                                   table.getSchema().getName() + "') " + 
                                   "and table_name=upper('" + table_name + 
                                   "') ORDER BY column_id ASC");

            while (rs.next()) {

                if (isHousekeeping(rs.getString("column_name"))) {
                    table.setHousekeeping(true);

                    continue;
                }

                if (isSubclass(table) && 
                    isSuperclassColumn(rs.getString("column_name"), 
                                       (GusTable)table))

                    continue;

                GusColumn col = new GusColumn();
                col.setName(rs.getString("column_name"));
                col.setType(getColumnType(rs.getString("data_type")));
                col.setNullable(stringToBoolean(rs.getString("nullable")));

                int length = getColumnLength(col.getType(), 
                                             rs.getInt("data_length"), 
                                             rs.getInt("data_precision"));
                col.setLength(length);
                col.setPrecision(rs.getInt("data_scale"));

                //   if ( isSubclass(table) ) {
                //      col.setImpName(getImpName(table, col.getName()));
                //   }
                if (table.isHousekeeping()) {

                    if (table.getClass() == GusTable.class) {
                        table.setHousekeepingColumns(verHousekeepingColumns);
                    } else {
                        table.setHousekeepingColumns(housekeepingColumns);
                    }
                }

                table.addColumn(col);
            }
        } catch (SQLException e) {
            log.error("Error querying for all columns: " + e);
            throw new RuntimeException(e);
        } finally {
            if (rs != null)
                try { rs.close(); } catch (SQLException ignored) { }
            if (st != null)
                try { st.close(); } catch (SQLException ignored) { }
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param index DOCUMENT ME!
     * @throws RuntimeException DOCUMENT ME!
     */
    private void addColumns(Index index) {
        log.debug("adding columns to index " + index.getName());

        Collection columns = index.getTable().getColumns();
        Statement st = null;
        ResultSet rs = null;

        try {

            st = connection.createStatement();
            rs = st.executeQuery(
                                   "SELECT column_name, table_name FROM all_ind_columns WHERE index_owner=upper('" + 
                                   index.getTable().getSchema().getName() + 
                                   "') AND " + "index_name=upper('" + 
                                   index.getName() + 
                                   "') ORDER BY column_position ASC");

            while (rs.next()) {

                if (!isHousekeeping(rs.getString("column_name"))) {

                    GusColumn col = (GusColumn)getColumn(columns, 
                                                         rs.getString(
                                                                 "column_name"));

                    if (col != null) {
                        index.addColumn(col);
                    } else {

                        if (rs.getString("table_name").endsWith("IMP")) {
                            log.warn("Index against a generic column " + 
                                     rs.getString("column_name") + " in " + 
                                     "index " + index.getName() + 
                                     ".  Skipped.");
                            index.getTable().removeIndex(index);

                            return;
                        } else {
                            log.error("Unable to locate bean column for column in database (" + 
                                      index.getName() + " " + 
                                      rs.getString("column_name") + ")");
                            throw new RuntimeException("Invalid internal database state");
                        }
                    }
                } else {
                    log.warn("Index against a housekeeping column " + 
                             rs.getString("column_name") + " in " + 
                             "index " + index.getName() + ".  Skipped.");
                    index.getTable().removeIndex(index);

                    return;
                }
            }

            if (generatedIndexes.contains(index)) {
                index.setName(null);
            }
        } catch (SQLException e) {
            log.error("Error querying for index columns: " + e);
            throw new RuntimeException(e);
        } finally {
            if (rs != null)
                try { rs.close(); } catch (SQLException ignored) { }
            if (st != null)
                try { st.close(); } catch (SQLException ignored) { }
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param constraint DOCUMENT ME!
     * @throws RuntimeException DOCUMENT ME!
     */
    private void addColumns(Constraint constraint) {
        log.debug("adding columns to constraint " + constraint.getName());

        Statement st = null;
        ResultSet rs = null;

        try {

            st = connection.createStatement();
            String table_name = constraint.getConstrainedTable().getName();

            if (isSuperclass((GusTable)constraint.getConstrainedTable())) {
                table_name += "IMP";
            }

            rs = st.executeQuery(
                                   "SELECT column_name FROM all_cons_columns WHERE owner=upper('" + 
                                   constraint.getConstrainedTable().getSchema()
                      .getName() + "') AND " + "constraint_name=upper('" + 
                                   constraint.getName() + 
                                   "') AND table_name=" + "upper('" + 
                                   table_name + "') ORDER BY position ASC");

            while (rs.next()) {

                if (!isHousekeeping(rs.getString("column_name"))) {

                    GusColumn col = (GusColumn)constraint.getConstrainedTable()
                              .getColumn(rs.getString("column_name"));

                    if (col != null) {
                        constraint.addConstrainedColumn(col);
                    } else {
                        log.error("Unable to locate bean column for column in database (" + 
                                  constraint.getName() + " " + 
                                  rs.getString("column_name") + " " + 
                                  constraint.getConstrainedTable().getName() + 
                                  ")");
                        throw new RuntimeException("Invalid internal database state");
                    }
                } else {
                    log.debug("Skipping housekeeping column: " + 
                              rs.getString("column_name"));
                }
            }
        } catch (SQLException e) {
            log.error("Error querying for constraint columns: " + e);
            throw new RuntimeException(e);
        } finally {
            if (rs != null)
                try { rs.close(); } catch (SQLException ignored) { }
            if (st != null)
                try { st.close(); } catch (SQLException ignored) { }
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param db DOCUMENT ME!
     */
    private void addIndexes(Database db) {
        log.debug("adding indexes to database " + db.getName());

        for (Iterator i = db.getSchemas().iterator(); i.hasNext();) {

            Schema schema = (Schema)i.next();

            if (schema.getClass() == GusSchema.class) {
                addIndexes((GusSchema)schema);
            }
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param schema DOCUMENT ME!
     * @throws RuntimeException DOCUMENT ME!
     */
    private void addIndexes(GusSchema schema) {
        log.debug("adding indexes to schema: " + schema.getName());

        Statement st = null;
        ResultSet rs = null;

        try {

            st = connection.createStatement();
            rs = st.executeQuery(
                                   "SELECT index_name, tablespace_name, table_name, table_owner, index_type, " + 
                                   "generated FROM all_indexes WHERE owner=upper('" + 
                                   schema.getName() + "')");

            while (rs.next()) {

                // TODO: review generated handling
                if (rs.getString("generated").equals("Y"))

                    continue;

                log.debug("found index " + rs.getString("index_name"));

                Index ind = new Index();
                ind.setName(rs.getString("index_name"));
                ind.setTablespace(rs.getString("tablespace_name"));
                ind.setType(getIndexType(rs.getString("index_type")));

                if (rs.getString("generated").equals("Y")) {
                    generatedIndexes.add(ind);
                }

                GusSchema table_owner = (GusSchema)getSchema(schema.getDatabase(), 
                                                             rs.getString(
                                                                     "table_owner"));
                String table_name = rs.getString("table_name");

                if (isSuperclass(rs.getString("table_name"), 
                                 table_owner.getName())) {
                    table_name = table_name.substring(0, 
                                                      table_name.length() - 3);
                }

                GusTable table = (GusTable)table_owner.getTable(table_name);

                if (table == null) {
                    log.error("Unable to located table for index " + 
                              ind.getName());
                }

                ind.setTable(table);
                addColumns(ind);
            }
        } catch (SQLException e) {
            log.error("Error querying for index attributes: " + e);
            throw new RuntimeException(e);
        } finally {
            if (rs != null)
                try { rs.close(); } catch (SQLException ignored) { }
            if (st != null)
                try { st.close(); } catch (SQLException ignored) { }
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @throws RuntimeException DOCUMENT ME!
     */
    private void addLocalConstraints(GusTable table) {
        log.debug("adding local constraints to table: " + 
                  table.getSchema().getName() + "." + table.getName());

        Statement st = null;
        ResultSet rs = null;

        try {

            st = connection.createStatement();
            String table_name = table.getName();

            if (isSuperclass(table)) {
                table_name += "IMP";
            }

            rs = st.executeQuery(
                                   "SELECT constraint_name, constraint_type FROM all_constraints WHERE " + 
                                   "table_name=upper('" + table_name + 
                                   "') AND owner=upper('" + 
                                   table.getSchema().getName() + "') " + 
                                   "AND (constraint_type = 'P' OR constraint_type = 'U')");

            while (rs.next()) {

                Constraint cons = new Constraint();
                cons.setName(rs.getString("constraint_name"));
                cons.setType(getConstraintType(rs.getString("constraint_type")));
                table.addConstraint(cons);
                addColumns(cons);
            }
        } catch (SQLException e) {
            log.error("Error querying for local constriants " + e);
            throw new RuntimeException(e);
        } finally {
            if (rs != null)
                try { rs.close(); } catch (SQLException ignored) { }
            if (st != null)
                try { st.close(); } catch (SQLException ignored) { }
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param db DOCUMENT ME!
     */
    private void addRemoteConstraints(Database db) {

        for (Iterator i = db.getSchemas().iterator(); i.hasNext();) {

            Schema schema = (Schema)i.next();

            for (Iterator j = schema.getTables().iterator(); j.hasNext();) {

                Table table = (Table)j.next();

                if (table.getClass() == GusTable.class) {
                    addRemoteConstraints((GusTable)table);
                }
            }
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @throws RuntimeException DOCUMENT ME!
     */
    private void addRemoteConstraints(GusTable table) {
        log.debug("adding remote constraints to table: " + table.getName());

        Statement st = null;
        ResultSet rs = null;

        try {

            st = connection.createStatement();
            String table_name = table.getName();

            if (isSuperclass(table)) {
                table_name += "IMP";
            }

            rs = st.executeQuery(
                                   "SELECT constraint_name, constraint_type, r_owner, r_constraint_name " + 
                                   "FROM all_constraints WHERE table_name=upper('" + 
                                   table_name + "') " + "AND owner=upper('" + 
                                   table.getSchema().getName() + 
                                   "') AND constraint_type='R'");

            while (rs.next()) {

                Constraint cons = new Constraint();
                cons.setName(rs.getString("constraint_name"));
                cons.setType(getConstraintType(rs.getString("constraint_type")));
                cons.setConstrainedTable(table);

                GusSchema r_owner = (GusSchema)table.getSchema().getDatabase().getSchema(rs.getString(
                                                                                                 "r_owner"));
				
																								 
				if ( r_owner == null ) {
					log.error("Could not find Schema: '" + rs.getString("r_owner") +
							  "' in constraint '" + cons.getName() + "'");
				}
																								 
				cons.setReferencedTable(getTableFromSchemaConstraint(r_owner, 
                                                                     rs.getString(
                                                                             "r_constraint_name")));

                Constraint r_constraint = cons.getReferencedTable().getConstraint(rs.getString(
                                                                                          "r_constraint_name"));
                Collection r_columns = r_constraint.getConstrainedColumns();

                for (Iterator i = r_columns.iterator(); i.hasNext();) {

                    GusColumn col = (GusColumn)i.next();
                    cons.addReferencedColumn(col);
                }

                table.addConstraint(cons);
                addColumns(cons);
            }
        } catch (SQLException e) {
            log.error("Error querying for local constriants " + e);
            throw new RuntimeException(e);
        } finally {
            if (rs != null)
                try { rs.close(); } catch (SQLException ignored) { }
            if (st != null)
                try { st.close(); } catch (SQLException ignored) { }
        }
    }

    /////////////// DATABASE POPULATE METHODS

    /**
     * DOCUMENT ME!
     * 
     * @param db DOCUMENT ME!
     */
    private void populate(Database db) {

        for (Iterator i = db.getSchemas().iterator(); i.hasNext();) {

            Schema schema = (Schema)i.next();

            if (schema.getClass() == GusSchema.class) {
                populate((GusSchema)schema);
            }
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param schema DOCUMENT ME!
     * @throws RuntimeException DOCUMENT ME!
     */
    private void populate(GusSchema schema) {
        log.debug("populating schema: " + schema.getName());

        if (schema.getName() == null)
            log.warn("About to populate a gus schema without a name");

        Statement st = null;
        ResultSet rs = null;

        try {

            st = connection.createStatement();
            rs = st.executeQuery(
                                   "SELECT description FROM " + CORE + 
                                   ".databaseinfo WHERE " + 
                                   "UPPER(name)=upper('" + schema.getName() + 
                                   "')");

            if (!rs.next()) {
                log.error("databaseinfo row doesn't exist for " + 
                          schema.getName());
            } else {
                schema.setDocumentation(rs.getString("description"));
            }

        } catch (SQLException e) {
            log.error("Error querying for Schema attributes: " + e);
            throw new RuntimeException(e);
        } finally {
            if (rs != null)
                try { rs.close(); } catch (SQLException ignored) { }
            if (st != null)
                try { st.close(); } catch (SQLException ignored) { }
        }

        for (Iterator i = schema.getTables().iterator(); i.hasNext();) {
            populate((GusTable)i.next());
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @throws RuntimeException DOCUMENT ME!
     */
    private void populate(GusTable table) {
        log.debug("populating table: " + table.getName());

        if (table.getName() == null)
            log.warn("About to populate a gus table without a name");

        Statement st = null;
        ResultSet rs = null;

        try {

            st = connection.createStatement();
            rs = st.executeQuery(
                                   "SELECT t.is_updatable, d.html_documentation, is_versioned, t.name FROM " + 
                                   CORE + ".tableinfo t LEFT JOIN " + CORE + 
                                   ".databasedocumentation d ON t.table_id=d.table_id WHERE UPPER(t.name)=" + 
                                   "upper('" + table.getName() + 
                                   "') AND d.attribute_name IS NULL");

            if (!rs.next()) {
                log.error("tableinfo row doesn't exist for " + 
                          table.getName());
            } else {

                // This is needed to set the proper case on the table name
                table.setName(rs.getString("name"));
                table.setUpdatable(rs.getBoolean("is_updatable"));
                table.setDocumentation(getStringFromClob(rs.getClob("html_documentation")));

                if (rs.getBoolean("is_versioned")) {
                    versionedTables.add(table);
                }
            }

        } catch (SQLException e) {
            log.error("Error querying for Table attributes: " + e);
            throw new RuntimeException(e);
        } finally {
            if (rs != null)
                try { rs.close(); } catch (SQLException ignored) { }
            if (st != null)
                try { st.close(); } catch (SQLException ignored) { }
        }

        for (Iterator i = table.getColumns(false).iterator(); i.hasNext();) {
            populate((GusColumn)i.next());
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param column DOCUMENT ME!
     * @throws RuntimeException DOCUMENT ME!
     */
    private void populate(GusColumn column) {
        log.debug("populating column: " + column.getName());

        if (column.getName() == null)
            log.warn("About to populate a column without a name");

        Statement st = null;
        ResultSet rs = null;

        try {

            st = connection.createStatement();
            rs = st.executeQuery(
                                   "SELECT d.html_documentation FROM " + 
                                   CORE + ".tableinfo t, " + CORE + 
                                   ".databasedocumentation d " + 
                                   "WHERE d.table_id=t.table_id AND upper(t.name)=upper('" + 
                                   column.getTable().getName() + "') AND " + 
                                   "upper(d.attribute_name)=upper('" + 
                                   column.getName() + "')");

            if (rs.next()) {
                column.setDocumentation(getStringFromClob(rs.getClob("html_documentation")));
            }
        } catch (SQLException e) {
            log.error("Error querying for column documentation: " + e);
            throw new RuntimeException(e);
        } finally {
            if (rs != null)
                try { rs.close(); } catch (SQLException ignored) { }
            if (st != null)
                try { st.close(); } catch (SQLException ignored) { }
        }
    }

    /////////////// HELPER METHODS

    /**
     * DOCUMENT ME!
     * 
     * @param schema DOCUMENT ME!
     * @param consName DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    private GusTable getTableFromSchemaConstraint(GusSchema schema, 
                                                  String consName) {

        for (Iterator i = schema.getTables().iterator(); i.hasNext();) {

            GusTable table = (GusTable)i.next();

            if (table.getConstraint(consName) != null) {

                return table;
            }
        }

        return null;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param tables DOCUMENT ME!
     * @param name DOCUMENT ME!
     * @param owner DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    private GusTable getTableFromCollection(Collection tables, String name, 
                                            String owner) {

        for (Iterator i = tables.iterator(); i.hasNext();) {

            GusTable table = (GusTable)i.next();

            if (table.getName().compareToIgnoreCase(name) == 0 && 
                table.getSchema().getName().compareToIgnoreCase(owner) == 0) {

                return table;
            }
        }

        return null;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param clob DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    private String getStringFromClob(Clob clob) {

        if (clob == null)

            return null;

        try {

            return clob.getSubString(1, (int)clob.length());
        } catch (SQLException e) {
            log.error("Error getting string from clob, returing null", e);

            return null;
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param name DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    private boolean isHousekeeping(String name) {

        if (getColumn(housekeepingColumns, name) == null)

            return false;

        return true;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param string DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    private boolean stringToBoolean(String string) {

        if (string.compareToIgnoreCase("Y") == 0)

            return true;

        if (string.compareToIgnoreCase("N") == 0)

            return false;

        log.warn("Unable to convert " + string + 
                 " to boolean, returning false");

        return false;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param name DOCUMENT ME!
     * @param owner DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    private boolean isSuperclass(String name, String owner) {

        if (name.endsWith("IMP")) {
            name = name.substring(0, name.length() - 3);
        }

        if (getTableFromCollection(superClasses, name, owner) != null)

            return true;

        return false;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    private boolean isSuperclass(GusTable table) {

        return isSuperclass(table.getName(), table.getSchema().getName());
    }

    /**
     * DOCUMENT ME!
     * 
     * @param name DOCUMENT ME!
     * @param owner DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    private boolean isSubclass(String name, String owner) {

        if (getTableFromCollection(subClasses, name, owner) != null)

            return true;

        return false;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    private boolean isSubclass(GusTable table) {

        return isSubclass(table.getName(), table.getSchema().getName());
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    private boolean isImplementation(GusTable table) {

        return isImplementation(table.getName());
    }

    /**
     * DOCUMENT ME!
     * 
     * @param name DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    private boolean isImplementation(String name) {

        if (name.toUpperCase().endsWith("IMP"))

            return true;

        return false;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param name DOCUMENT ME!
     * @param subclass DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    private boolean isSuperclassColumn(String name, GusTable subclass) {

        GusTable superclass = (GusTable)subclass.getSuperclass();

        for (Iterator i = superclass.getColumns(false).iterator();
             i.hasNext();) {

            if (((Column)i.next()).getName().compareToIgnoreCase(name) == 0)

                return true;
        }

        return false;
    }
 
    /**
     * DOCUMENT ME!
     * 
     * @param type DOCUMENT ME!
     * @param length DOCUMENT ME!
     * @param precision DOCUMENT ME!
     * @return DOCUMENT ME! 
     */
    private int getColumnLength(ColumnType type, int length, int precision) {

        if (type == ColumnType.STRING ||
			type == ColumnType.CHARACTER ) {
            return length;
        }

        return precision;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param oracleType DOCUMENT ME!
     * @return DOCUMENT ME! 
     * @throws RuntimeException DOCUMENT ME!
     */
    private ColumnType getColumnType(String oracleType) {
        oracleType = oracleType.toUpperCase();

        if (oracleType.equals("CHAR"))
            return ColumnType.CHARACTER;
        else if (oracleType.equals("CLOB"))
            return ColumnType.CLOB;
        else if (oracleType.equals("DATE"))
            return ColumnType.DATE;
        else if (oracleType.equals("FLOAT"))
            return ColumnType.FLOAT;
        else if (oracleType.equals("NUMBER"))
            return ColumnType.NUMBER;
        else if (oracleType.equals("VARCHAR2"))
            return ColumnType.STRING;
        else if (oracleType.equals("UNDEFINED")) {
            log.error("Undefined column type-- check for invalid view");
            return ColumnType.UNDEFINED;
        } else {
            log.error("Unknown column type: " + oracleType);
            throw new RuntimeException("Unknown column type: " + oracleType);
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param oracleType DOCUMENT ME!
     * @return DOCUMENT ME! 
     * @throws RuntimeException DOCUMENT ME!
     */
    private IndexType getIndexType(String oracleType) {
        oracleType = oracleType.toUpperCase();

        if (oracleType.equals("NORMAL"))

            return IndexType.NORMAL;
        else if (oracleType.equals("BITMAP"))

            return IndexType.BITMAP;
        else {
            log.error("Unkown index type: " + oracleType);
            throw new RuntimeException("Unknown index type: " + oracleType);
        }
    }

    /**
     * DOCUMENT ME!
     * 
     * @param oracleType DOCUMENT ME!
     * @return DOCUMENT ME! 
     * @throws RuntimeException DOCUMENT ME!
     */
    private ConstraintType getConstraintType(String oracleType) {
        oracleType = oracleType.toUpperCase();

        if (oracleType.equals("U"))

            return ConstraintType.UNIQUE;
        else if (oracleType.equals("R"))

            return ConstraintType.FOREIGN_KEY;
        else if (oracleType.equals("P"))

            return ConstraintType.PRIMARY_KEY;
        else {
            log.error("Unkown constraint type: " + oracleType);
            throw new RuntimeException("Unknown constraint type: " + 
                                       oracleType);
        }
    }

    /////////////// SCHEMA READER IMPLEMENTATION METHODS

    /**
     * DOCUMENT ME!
     * @throws RuntimeException DOCUMENT ME!
     */
    protected void setUp() {

        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            log.debug("Connecting to " + this.dsn);
            connection = DriverManager.getConnection(this.dsn, this.username, 
                                                     this.password);
        } catch (ClassNotFoundException e) {
            log.error("Could not load Oracle driver-- make sure the jar has been supplied");
            throw new RuntimeException(e);
        }
         catch (SQLException e) {
            log.error("Could not connect to database with DSN: " + this.dsn + 
                      " due to " + e);
            throw new RuntimeException(e);
        }

        CORE = properties.getProperty("coreSchemaName").toUpperCase();

        if (CORE == null) {
            log.warn("Assuming CORE is the core schema name");
            CORE = "CORE";
        }

        log.debug("Getting housekeeping columns");

        String[] housekeepingCols = properties.getProperty(
                                            "housekeepingColumns").split(",");

        for (int i = 0; i < housekeepingCols.length; i++) {

            HousekeepingColumn col = new HousekeepingColumn();
            col.setName(housekeepingCols[i]);
            housekeepingColumns.add(col);
        }
    }

    /**
     * DOCUMENT ME!
     */
    protected void tearDown() {

        try {
            connection.close();
        } catch (Exception e) {
            log.warn("Error closing connection: " + e);
        }
    }
}

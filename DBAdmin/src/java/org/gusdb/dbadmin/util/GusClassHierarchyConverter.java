package org.gusdb.dbadmin.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Properties;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.gusdb.dbadmin.model.Column;
import org.gusdb.dbadmin.model.ColumnType;
import org.gusdb.dbadmin.model.Constraint;
import org.gusdb.dbadmin.model.GusColumn;
import org.gusdb.dbadmin.model.GusSchema;
import org.gusdb.dbadmin.model.GusTable;
import org.gusdb.dbadmin.model.GusView;
import org.gusdb.dbadmin.model.HousekeepingColumn;
import org.gusdb.dbadmin.model.Index;


/**
 * Utility to convert from more traditional object based subclassing (i.e.
 * each table only has the attributes specific to that table and "inherits"
 * the  attributes specified by the superclass) to the GUS-based subclassing
 * system in which the super and sub classes are views on an implementation
 * table that contains all attributes.
 * 
 * @version $Revision$ $Date$
 * @author Mike Saffitz
 */
public class GusClassHierarchyConverter {

    private GusTable superClassTable;
    private Collection subClassTables;
    private GusView superClassView;
    private Collection subClassViews;
    private GusTable impTable = new GusTable();
    private Collection superClassColumns;
    private Collection impGenericColumns;
    private Collection housekeepingColumns = new ArrayList();
    private Collection verHousekeepingColumns = new ArrayList();
    private Properties properties = new Properties();
    private final Log log = LogFactory.getLog(GusClassHierarchyConverter.class);

    /**
     * Prepares to converts the given superclass into a GUSClassHierarchy,
     * consisting of an implementation table, superclass views, and subclass
     * views.
     * 
     * <p>
     * Begins by constructing the Imp table (without columns), adding
     * housekeeping columns, and setting various attributes such as  the
     * schema, tablespace, and so on.
     * </p>
     * 
     * @param superClassTable  Superclass Table to be converted.
     */
    public GusClassHierarchyConverter(GusTable superClassTable) {
        readProperties();
        initHousekeeping();
        this.superClassTable = superClassTable;
        subClassTables = superClassTable.getSubclasss();
        impTable = new GusTable();
        impTable.setName(superClassTable.getName() + "Imp");
        impTable.setHousekeeping(superClassTable.isHousekeeping());
        impTable.setSchema((GusSchema)superClassTable.getSchema());
        impTable.setTablespace(superClassTable.getTablespace());
        impTable.setUpdatable(superClassTable.isUpdatable());
        impTable.setSchema(superClassTable.getSchema());
        impTable.setVersioned(superClassTable.isVersioned());

        if (impTable.getVersionTable() != null) {
            impTable.getVersionTable().setHousekeepingColumns(
                    verHousekeepingColumns);
        }

        superClassTable.setSchema(null);
    }

    /**
     * Description of the Method
     * 
     * @throws RuntimeException DOCUMENT ME!
     */
    public void convert() {
        log.debug("Converting Hierarchy for table  " + 
                  superClassTable.getName());
        superClassColumns = superClassTable.getColumns(true);

        if (subClassTables.isEmpty()) {
            log.error("There are no subclasses for this table " + 
                      superClassTable.getName());

            return;
        }

        impGenericColumns = coalesceGenericColumns(subClassTables);

        for (Iterator i = superClassColumns.iterator(); i.hasNext();) {

            Column oldCol = (Column)i.next();

            if (oldCol.getClass() == GusColumn.class) {

                GusColumn newCol = (GusColumn)((GusColumn)oldCol).clone();
                impTable.addColumn(newCol);
            } else if (oldCol.getClass() == HousekeepingColumn.class) {

                HousekeepingColumn newCol = (HousekeepingColumn)((HousekeepingColumn)oldCol).clone();
                impTable.addHousekeepingColumn(newCol);
            } else {
                throw new RuntimeException("Unknown Column type: " + 
                                           oldCol.getClass());
            }
        }

        for (Iterator i = impGenericColumns.iterator(); i.hasNext();) {
            impTable.addColumn((GusColumn)i.next());
        }

        superClassView = buildSuperClassView();
        subClassViews = buildSubClassViews();

        GusSchema parentSchema = (GusSchema)impTable.getSchema();
        parentSchema.addView(superClassView);
        superClassView.setTable(impTable);

        for (Iterator i = subClassViews.iterator(); i.hasNext();) {

            GusView subClassView = (GusView)i.next();
            parentSchema.addView(subClassView);
            subClassView.setTable(impTable);
            subClassView.setSuperclass(superClassView);
        }

        // TODO fix constrgaints
        for (int i = 0; i < subClassTables.size(); i++) {
            ((GusTable)subClassTables.toArray()[i]).setSchema(null);
        }

        log.debug("Converting constraints for Table: '" + 
                  impTable.getName() + "'");

        // TODO build rules
        Object[] pKAndUniqueConstraints = superClassTable.getConstraints().toArray();

        for (int i = 0; i < pKAndUniqueConstraints.length; i++) {

            Object[] conColumns = ((Constraint)pKAndUniqueConstraints[i]).getConstrainedColumns()
                                     .toArray();

            for (int j = 0; j < conColumns.length; j++) {
                log.debug("Moving constraint: '" + 
                          ((Constraint)pKAndUniqueConstraints[i]).getName() + 
                          "' to impTable: '" + impTable.getName() + "'");
                ((Constraint)pKAndUniqueConstraints[i]).removeConstrainedColumn(
                        (GusColumn)conColumns[j]);
                ((Constraint)pKAndUniqueConstraints[i]).addConstrainedColumn(
                        (GusColumn)impTable.getColumn(((GusColumn)conColumns[j]).getName()));
            }

            ((Constraint)pKAndUniqueConstraints[i]).setConstrainedTable(
                    impTable);
        }

        Object[] fKConstraints = superClassTable.getReferentialConstraints().toArray();

        for (int i = 0; i < fKConstraints.length; i++) {

            Object[] refColumns = ((Constraint)fKConstraints[i]).getReferencedColumns()
                            .toArray();

            for (int j = 0; j < refColumns.length; j++) {
                ((Constraint)fKConstraints[i]).removeReferencedColumn(
                        (GusColumn)refColumns[j]);
                ((Constraint)fKConstraints[i]).addReferencedColumn(
                        (GusColumn)impTable.getColumn(((GusColumn)refColumns[j]).getName()));
            }

            ((Constraint)fKConstraints[i]).setReferencedTable(impTable);
        }

        log.debug("Converting indexes for Table: " + impTable.getName() + 
                  "'");

        Object[] indexes = superClassTable.getIndexs().toArray();

        for (int i = 0; i < indexes.length; i++) {

            Object[] indColumns = ((Index)indexes[i]).getColumns().toArray();

            for (int j = 0; j < indColumns.length; j++) {
                ((Index)indexes[i]).removeColumn((GusColumn)indColumns[j]);
                ((Index)indexes[i]).addColumn(
                        (GusColumn)impTable.getColumn(((GusColumn)indColumns[j]).getName()));
            }

            ((Index)indexes[i]).setTable(impTable);
        }
    }

    /**
     * Gets the views attribute of the GusClassHierarchyConverter object
     * 
     * @return The views value
     */
    public Collection getViews() {

        Collection views = getSubClassViews();
        views.add(getSuperClassView());

        return views;
    }

    /**
     * Gets the superClassView attribute of the GusClassHierarchyConverter
     * object
     * 
     * @return The superClassView value
     */
    public GusView getSuperClassView() {

        return superClassView;
    }

    /**
     * Gets the subClassViews attribute of the GusClassHierarchyConverter
     * object
     * 
     * @return The subClassViews value
     */
    public Collection getSubClassViews() {

        return subClassViews;
    }

    /**
     * Gets the impTable attribute of the GusClassHierarchyConverter object
     * 
     * @return The impTable value
     */
    public GusTable getImpTable() {

        return impTable;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param tables DOCUMENT ME!
     * @return DOCUMENT ME!
     */
    private Collection coalesceGenericColumns(Collection tables) {

        HashMap columnCounts = new HashMap();
        columnCounts.put(ColumnType.CHARACTER, new Integer(0));
        columnCounts.put(ColumnType.CLOB, new Integer(0));
        columnCounts.put(ColumnType.DATE, new Integer(0));
        columnCounts.put(ColumnType.FLOAT, new Integer(0));
        columnCounts.put(ColumnType.NUMBER, new Integer(0));
        columnCounts.put(ColumnType.STRING, new Integer(0));

        HashMap columnSizes = new HashMap();
        columnSizes.put(ColumnType.CHARACTER + "L", new Integer(0));
        columnSizes.put(ColumnType.NUMBER + "L", new Integer(0));
        columnSizes.put(ColumnType.NUMBER + "P", new Integer(0));
        columnSizes.put(ColumnType.STRING + "L", new Integer(0));

        Collection newColumns = new HashSet();

        for (Iterator i = tables.iterator(); i.hasNext();) {

            GusTable t = (GusTable)i.next();

            for (Iterator j = columnCounts.keySet().iterator(); j.hasNext();) {

                ColumnType type = (ColumnType)j.next();
                columnCounts.put(type, 
                                 new Integer(Math.max(((Integer)columnCounts.get(
                                                               type)).intValue(), 
                                                      getMaxColumnType(t, type))));
            }

            for (Iterator j = columnSizes.keySet().iterator(); j.hasNext();) {

                String key = (String)j.next();
                ColumnType type = ColumnType.getInstance(key.substring(0, 
                                                                       key.length() - 1));
                String sizeType = key.substring(key.length() - 1);

                if ((Integer)columnSizes.get(type + sizeType) != null) {
                    columnSizes.put(type + sizeType, 
                                    new Integer(Math.max(((Integer)columnSizes.get(
                                                                  type + sizeType)).intValue(), 
                                                         getLargestColumnLength(
                                                                 t, type, 
                                                                 sizeType))));
                }
            }
        }

        for (Iterator i = columnCounts.keySet().iterator(); i.hasNext();) {

            ColumnType type = (ColumnType)i.next();

            for (int j = 0;
                 j < ((Integer)columnCounts.get(type)).intValue();
                 j++) {

                GusColumn newColumn = new GusColumn();
                newColumn.setName(type.toString() + new Integer(j + 1));
                newColumn.setType(type);
                newColumn.setNullable(true);

                if (columnSizes.containsKey(type + "L")) {
                    newColumn.setLength(((Integer)columnSizes.get(type + "L")).intValue());
                }

                if (columnSizes.containsKey(type + "P")) {
                    newColumn.setPrecision(((Integer)columnSizes.get(
                                                    type + "P")).intValue());
                }

                newColumns.add(newColumn);
            }
        }

        return newColumns;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @param type DOCUMENT ME!
     * @return DOCUMENT ME!
     */
    private int getMaxColumnType(GusTable table, ColumnType type) {

        int count = 0;

        for (Iterator i = table.getColumns(false).iterator(); i.hasNext();) {

            if (((GusColumn)i.next()).getType() == type) {
                count++;
            }
        }

        return count;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @param type DOCUMENT ME!
     * @param subType DOCUMENT ME!
     * @return DOCUMENT ME!
     * @throws RuntimeException DOCUMENT ME!
     */
    private int getLargestColumnLength(GusTable table, ColumnType type, 
                                       String subType) {

        int size = 0;

        for (Iterator i = table.getColumns(false).iterator(); i.hasNext();) {

            GusColumn c = (GusColumn)i.next();

            if (c.getType() == type) {

                if (subType.equals("L")) {
                    size = Math.max(size, c.getLength());
                } else if (subType.equals("P")) {
                    size = Math.max(size, c.getPrecision());
                } else {
                    throw new RuntimeException("Unknown subType: " + 
                                               subType);
                }
            }
        }

        return size;
    }

    /**
     * Using the internal Implementation table, creates a new Superclass view.
     * 
     * @return The Superclass View based on the ImpTable
     */
    private GusView buildSuperClassView() {
        log.debug("Building superClassView for ImpTable: '" + 
                  impTable.getName() + "'");

        GusView superClassView = new GusView();
        String sql = "SELECT ";
        String verSql;
        boolean first = true;

        // Superclass Columns
        for (Iterator i = superClassColumns.iterator(); i.hasNext();) {

            Column column = (Column)i.next();

            if (column.getClass() == GusColumn.class) {

                if (!first)
                    sql = sql.concat(", ");

                first = false;
                sql = sql.concat(column.getName());
                superClassView.addColumn(new ColumnPair(column.getName(), 
                                                        column.getName()));
            }
        }

        // Housekeeping Columns and complete for the Version View
        if (impTable.isVersioned()) {
            superClassView.setVersioned(true);
            verSql = sql.concat(" ");

            for (Iterator i = verHousekeepingColumns.iterator(); i.hasNext();) {

                Column column = (Column)i.next();
                verSql = verSql.concat(", " + column.getName());
                superClassView.getVersionView().addColumn(new ColumnPair(column.getName(), 
                                                                         column.getName()));
            }

            verSql = verSql.concat(
                             " FROM " + 
                             impTable.getVersionTable().getSchema().getName() + 
                             "." + impTable.getVersionTable().getName() + 
                             ";");
            superClassView.getVersionView().setSql(verSql);
        }

        // Housekeeping Columns and complete for the Standard View
        for (Iterator i = housekeepingColumns.iterator(); i.hasNext();) {

            Column column = (Column)i.next();
            sql = sql.concat(", " + column.getName());
            superClassView.addColumn(new ColumnPair(column.getName(), 
                                                    column.getName()));
        }

        sql = sql.concat(" FROM " + impTable.getSchema().getName() + "." + 
                         impTable.getName() + ";");
        superClassView.setSql(sql);
        superClassView.setName(superClassTable.getName());
        log.debug("Done building superClassView");

        return superClassView;
    }

    /**
     * Using the Superclass provided at construction, iteratively calls {@link
     * buildSubClassView} on each subClassTable to assemble the complete set
     * of Subclass Views.
     * 
     * @return Collection of Subclass views for the internal Superclass
     */
    private Collection buildSubClassViews() {
        log.debug("Building subClassViews for ImpTable: '" + 
                  impTable.getName() + "'");

        Collection subClassViews = new HashSet();

        for (Iterator i = subClassTables.iterator(); i.hasNext();) {
            subClassViews.add(buildSubClassView((GusTable)i.next()));
        }

        log.debug("Done building subClassViews");

        return subClassViews;
    }

    /**
     * DOCUMENT ME!
     * 
     * @param table DOCUMENT ME!
     * @return DOCUMENT ME!
     */
    private GusView buildSubClassView(GusTable table) {
        log.debug("Building subClassView from table: '" + table.getName() + 
                  "'");

        GusView subClass = new GusView();
        String sql = "SELECT ";
        String verSql;
        boolean first = true;

        for (Iterator i = superClassColumns.iterator(); i.hasNext();) {

            Column column = (Column)i.next();

            if (column.getClass() == GusColumn.class) {

                if (!first)
                    sql = sql.concat(", ");

                first = false;
                sql = sql.concat(column.getName());
                subClass.addColumn(new ColumnPair(column.getName(), 
                                                  column.getName()));
            }
        }

        HashMap columnCounts = new HashMap();

        for (Iterator i = table.getColumns(false).iterator(); i.hasNext();) {

            GusColumn column = (GusColumn)i.next();

            if (!columnCounts.containsKey(column.getType())) {
                columnCounts.put(column.getType(), new Integer(1));
            }

            int columnCount = ((Integer)columnCounts.get(column.getType())).intValue();
            sql = sql.concat(", " + column.getType().toString() + 
                             columnCount);
            sql = sql.concat(" AS " + column.getName());
            subClass.addColumn(new ColumnPair(column.getName(), 
                                              column.getType().toString() + columnCount));
            columnCounts.put(column.getType(), new Integer(columnCount + 1));
        }

        if (impTable.isVersioned()) {
            subClass.setVersioned(true);
            verSql = sql.concat(" ");

            for (Iterator i = verHousekeepingColumns.iterator(); i.hasNext();) {

                Column column = (Column)i.next();
                verSql = verSql.concat(", " + column.getName());
                subClass.getVersionView().addColumn(new ColumnPair(column.getName(), 
                                                                   column.getName()));
            }

            verSql = verSql.concat(
                             " FROM " + 
                             impTable.getVersionTable().getSchema().getName() + 
                             "." + impTable.getVersionTable().getName() + 
                             " ");
            verSql = verSql.concat(
                             " WHERE subclass_view='" + table.getName() + 
                             "';");
            subClass.getVersionView().setSql(verSql);
        }

        for (Iterator i = housekeepingColumns.iterator(); i.hasNext();) {

            Column column = (Column)i.next();
            sql = sql.concat(", " + column.getName());
            subClass.addColumn(new ColumnPair(column.getName(), 
                                              column.getName()));
        }

        sql = sql.concat(" FROM " + impTable.getSchema().getName() + "." + 
                         impTable.getName() + " ");
        sql = sql.concat(" WHERE subclass_view='" + table.getName() + "';");
        subClass.setSql(sql);
        subClass.setName(table.getName());
        log.debug("Done building subClassView.");

        return subClass;
    }

    /**
     * DOCUMENT ME!
     */
    private void initHousekeeping() {

        String housekeepingList = properties.getProperty("housekeepingColumns");
        String housekeepingVerList = properties.getProperty(
                                             "housekeepingColumnsVer");
        String[] housekeepingCols = housekeepingList.split(",");
        initHousekeeping(housekeepingColumns, housekeepingCols);

        String[] housekeepingVerCols = housekeepingVerList.split(",");
        initHousekeeping(verHousekeepingColumns, housekeepingVerCols);
    }

    /**
     * DOCUMENT ME!
     * 
     * @param array DOCUMENT ME!
     * @param housekeepingCols DOCUMENT ME!
     */
    private void initHousekeeping(Collection array, String[] housekeepingCols) {

        for (int i = 0; i < housekeepingCols.length; i++) {

            String columnSpec = properties.getProperty(
                                        "hkspec." + housekeepingCols[i]);
            String[] columnSpecs = columnSpec.split(",", 4);
            HousekeepingColumn column = new HousekeepingColumn();
            column.setName(housekeepingCols[i]);
            column.setType(ColumnType.getInstance(columnSpecs[0]));
            column.setLength((new Integer(columnSpecs[1])).intValue());
            column.setPrecision((new Integer(columnSpecs[2])).intValue());
            array.add(column);
        }
    }

    /**
     * Reads in configuration data from the gus.config propertyfile, specified
     * in the environment.
     */
    private void readProperties() {

        File propertyFile;

        try {
            propertyFile = new File(System.getProperty("PROPERTYFILE"));
            properties.load(new FileInputStream(propertyFile));
            System.setProperty("SEQUENCE_START", 
                               properties.getProperty("sequenceStart"));
        } catch (IOException e) {
            System.err.println("Could not initialize due to " + e);
            System.exit(1);
        }
    }
}


/*                                                                                            */
/* rad3-tables.sql                                                                            */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Feb 17 11:45:57 EST 2004     */
/*                                                                                            */

SET ECHO ON
SPOOL rad3-tables.log

CREATE TABLE @oracle_rad@.ACQUISITION (
    ACQUISITION_ID                     NUMBER(8)                                     NOT NULL,
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    PROTOCOL_ID                        NUMBER(10)                                    NULL,
    CHANNEL_ID                         NUMBER(4)                                     NULL,
    ACQUISITION_DATE                   DATE                                          NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    URI                                VARCHAR2(255)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ACQUISITIONPARAM (
    ACQUISITION_PARAM_ID               NUMBER(5)                                     NOT NULL,
    ACQUISITION_ID                     NUMBER(4)                                     NOT NULL,
    PROTOCOL_PARAM_ID                  NUMBER(10)                                    NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    VALUE                              VARCHAR2(50)                                  NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ANALYSIS (
    ANALYSIS_ID                        NUMBER(8)                                     NOT NULL,
    OPERATOR_ID                        NUMBER(10)                                    NULL,
    PROTOCOL_ID                        NUMBER(8)                                     NOT NULL,
    ANALYSIS_DATE                      DATE                                          NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ANALYSISINPUT (
    ANALYSIS_INPUT_ID                  NUMBER(10)                                    NOT NULL,
    LOGICAL_GROUP_ID                   NUMBER(8)                                     NOT NULL,
    ANALYSIS_ID                        NUMBER(8)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ANALYSISPARAM (
    ANALYSIS_PARAM_ID                  NUMBER(10)                                    NOT NULL,
    ANALYSIS_ID                        NUMBER(8)                                     NOT NULL,
    PROTOCOL_PARAM_ID                  NUMBER(10)                                    NOT NULL,
    VALUE                              VARCHAR2(50)                                  NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ANALYSISQCPARAM (
    ANALYSIS_QC_PARAM_ID               NUMBER(10)                                    NOT NULL,
    ANALYSIS_ID                        NUMBER(8)                                     NOT NULL,
    PROTOCOL_QC_PARAM_ID               NUMBER(10)                                    NOT NULL,
    VALUE                              VARCHAR2(50)                                  NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ANALYSISRESULTIMP (
    ANALYSIS_RESULT_ID                 NUMBER(12)                                    NOT NULL,
    SUBCLASS_VIEW                      VARCHAR2(27)                                  NOT NULL,
    ANALYSIS_ID                        NUMBER(8)                                     NOT NULL,
    TABLE_ID                           NUMBER(5)                                     NULL,
    ROW_ID                             NUMBER(12)                                    NULL,
    SMALLINT1                          NUMBER(5)                                     NULL,
    SMALLINT2                          NUMBER(5)                                     NULL,
    SMALLINT3                          NUMBER(5)                                     NULL,
    INT1                               NUMBER(8)                                     NULL,
    INT2                               NUMBER(8)                                     NULL,
    INT3                               NUMBER(8)                                     NULL,
    INT4                               NUMBER(8)                                     NULL,
    FLOAT1                             FLOAT(126)                                    NULL,
    FLOAT2                             FLOAT(126)                                    NULL,
    FLOAT3                             FLOAT(126)                                    NULL,
    FLOAT4                             FLOAT(126)                                    NULL,
    FLOAT5                             FLOAT(126)                                    NULL,
    FLOAT6                             FLOAT(126)                                    NULL,
    FLOAT7                             FLOAT(126)                                    NULL,
    TINYSTRING1                        VARCHAR2(10)                                  NULL,
    STRING1                            VARCHAR2(200)                                 NULL,
    STRING2                            VARCHAR2(200)                                 NULL,
    STRING3                            VARCHAR2(200)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ARRAY (
    ARRAY_ID                           NUMBER(4)                                     NOT NULL,
    MANUFACTURER_ID                    NUMBER(12)                                    NOT NULL,
    PLATFORM_TYPE_ID                   NUMBER(8)                                     NOT NULL,
    SUBSTRATE_TYPE_ID                  NUMBER(8)                                     NULL,
    PROTOCOL_ID                        NUMBER(12)                                    NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(4)                                     NULL,
    SOURCE_ID                          VARCHAR2(100)                                 NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    VERSION                            VARCHAR2(50)                                  NULL,
    DESCRIPTION                        VARCHAR2(2000)                                NULL,
    ARRAY_DIMENSIONS                   VARCHAR2(50)                                  NULL,
    ELEMENT_DIMENSIONS                 VARCHAR2(50)                                  NULL,
    NUMBER_OF_ELEMENTS                 NUMBER(10)                                    NULL,
    NUM_ARRAY_COLUMNS                  NUMBER(3)                                     NULL,
    NUM_ARRAY_ROWS                     NUMBER(3)                                     NULL,
    NUM_GRID_COLUMNS                   NUMBER(3)                                     NULL,
    NUM_GRID_ROWS                      NUMBER(3)                                     NULL,
    NUM_SUB_COLUMNS                    NUMBER(6)                                     NULL,
    NUM_SUB_ROWS                       NUMBER(6)                                     NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ARRAYANNOTATION (
    ARRAY_ANNOTATION_ID                NUMBER(5)                                     NOT NULL,
    ARRAY_ID                           NUMBER(4)                                     NOT NULL,
    NAME                               VARCHAR2(500)                                 NOT NULL,
    VALUE                              VARCHAR2(100)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ARRAYGROUP (
    ARRAY_GROUP_ID                     NUMBER(8)                                     NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ARRAYGROUPLINK (
    ARRAY_GROUP_LINK_ID                NUMBER(10)                                    NOT NULL,
    ARRAY_GROUP_ID                     NUMBER(8)                                     NOT NULL,
    ARRAY_ID                           NUMBER(5)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ASSAY (
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    ARRAY_ID                           NUMBER(4)                                     NOT NULL,
    PROTOCOL_ID                        NUMBER(10)                                    NULL,
    ASSAY_DATE                         DATE                                          NULL,
    ARRAY_IDENTIFIER                   VARCHAR2(100)                                 NULL,
    ARRAY_BATCH_IDENTIFIER             VARCHAR2(100)                                 NULL,
    OPERATOR_ID                        NUMBER(10)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NULL,
    SOURCE_ID                          VARCHAR2(50)                                  NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ASSAYBIOMATERIAL (
    ASSAY_BIO_MATERIAL_ID              NUMBER(5)                                     NOT NULL,
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    BIO_MATERIAL_ID                    NUMBER(5)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ASSAYCONTROL (
    ASSAY_CONTROL_ID                   NUMBER(8)                                     NOT NULL,
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    CONTROL_ID                         NUMBER(5)                                     NOT NULL,
    VALUE                              VARCHAR2(255)                                 NULL,
    UNIT_TYPE_ID                       NUMBER(10)                                    NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - ASSAYGROUP does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.ASSAYGROUP (
    STUDY_ID                           NUMBER(4)                                     NOT NULL,
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    STUDY_DESIGN_ID                    NUMBER(5)                                     NOT NULL,
    FACTOR_VALUE                       VARCHAR2(100)                                 NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ASSAYLABELEDEXTRACT (
    ASSAY_LABELED_EXTRACT_ID           NUMBER(8)                                     NOT NULL,
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    LABELED_EXTRACT_ID                 NUMBER(8)                                     NOT NULL,
    CHANNEL_ID                         NUMBER(4)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ASSAYPARAM (
    ASSAY_PARAM_ID                     NUMBER(10)                                    NOT NULL,
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    PROTOCOL_PARAM_ID                  NUMBER(10)                                    NOT NULL,
    VALUE                              VARCHAR2(100)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.BIOMATERIALCHARACTERISTIC (
    BIO_MATERIAL_CHARACTERISTIC_ID     NUMBER(5)                                     NOT NULL,
    BIO_MATERIAL_ID                    NUMBER(5)                                     NOT NULL,
    ONTOLOGY_ENTRY_ID                  NUMBER(5)                                     NOT NULL,
    VALUE                              VARCHAR2(100)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.BIOMATERIALIMP (
    BIO_MATERIAL_ID                    NUMBER(8)                                     NOT NULL,
    LABEL_METHOD_ID                    NUMBER(4)                                     NULL,
    TAXON_ID                           NUMBER(10)                                    NULL,
    BIO_SOURCE_PROVIDER_ID             NUMBER(12)                                    NULL,
    BIO_MATERIAL_TYPE_ID               NUMBER(10)                                    NULL,
    SUBCLASS_VIEW                      VARCHAR2(27)                                  NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NULL,
    SOURCE_ID                          VARCHAR2(50)                                  NULL,
    STRING1                            VARCHAR2(100)                                 NULL,
    STRING2                            VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.BIOMATERIALMEASUREMENT (
    BIO_MATERIAL_MEASUREMENT_ID        NUMBER(10)                                    NOT NULL,
    TREATMENT_ID                       NUMBER(10)                                    NOT NULL,
    BIO_MATERIAL_ID                    NUMBER(5)                                     NOT NULL,
    VALUE                              FLOAT(126)                                    NULL,
    UNIT_TYPE_ID                       NUMBER(5)                                     NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.CHANNEL (
    CHANNEL_ID                         NUMBER(4)                                     NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    DEFINITION                         VARCHAR2(500)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.COMPOSITEELEMENTANNOTATION (
    COMPOSITE_ELEMENT_ANNOT_ID         NUMBER(12)                                    NOT NULL,
    COMPOSITE_ELEMENT_ID               NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(500)                                 NOT NULL,
    VALUE                              VARCHAR2(255)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - COMPOSITEELEMENTASSEMBLY_MV does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.COMPOSITEELEMENTASSEMBLY_MV (
    COMPOSITE_ELEMENT_ID               NUMBER(12)                                    NULL,
    ASSEMBLY_NA_SEQUENCE_ID            NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.COMPOSITEELEMENTGUS (
    COMPOSITE_ELEMENT_GUS_ID           NUMBER(12)                                    NOT NULL,
    COMPOSITE_ELEMENT_ID               NUMBER(12)                                    NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    ROW_ID                             NUMBER(12)                                    NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.COMPOSITEELEMENTIMP (
    COMPOSITE_ELEMENT_ID               NUMBER(10)                                    NOT NULL,
    PARENT_ID                          NUMBER(10)                                    NULL,
    ARRAY_ID                           NUMBER(4)                                     NOT NULL,
    SUBCLASS_VIEW                      VARCHAR2(27)                                  NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(4)                                     NULL,
    SOURCE_ID                          VARCHAR2(50)                                  NULL,
    TINYINT1                           NUMBER(3)                                     NULL,
    SMALLINT1                          NUMBER(5)                                     NULL,
    SMALLINT2                          NUMBER(5)                                     NULL,
    CHAR1                              VARCHAR2(5)                                   NULL,
    CHAR2                              VARCHAR2(5)                                   NULL,
    TINYSTRING1                        VARCHAR2(50)                                  NULL,
    TINYSTRING2                        VARCHAR2(50)                                  NULL,
    SMALLSTRING1                       VARCHAR2(100)                                 NULL,
    SMALLSTRING2                       VARCHAR2(100)                                 NULL,
    STRING1                            VARCHAR2(500)                                 NULL,
    STRING2                            VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.COMPOSITEELEMENTRESULTIMP (
    COMPOSITE_ELEMENT_RESULT_ID        NUMBER(10)                                    NOT NULL,
    COMPOSITE_ELEMENT_ID               NUMBER(10)                                    NOT NULL,
    QUANTIFICATION_ID                  NUMBER(8)                                     NOT NULL,
    SUBCLASS_VIEW                      VARCHAR2(27)                                  NOT NULL,
    FLOAT1                             FLOAT(126)                                    NULL,
    FLOAT2                             FLOAT(126)                                    NULL,
    FLOAT3                             FLOAT(126)                                    NULL,
    FLOAT4                             FLOAT(126)                                    NULL,
    INT1                               NUMBER(12)                                    NULL,
    SMALLINT1                          NUMBER(5)                                     NULL,
    SMALLINT2                          NUMBER(5)                                     NULL,
    SMALLINT3                          NUMBER(5)                                     NULL,
    TINYINT1                           NUMBER(3)                                     NULL,
    TINYINT2                           NUMBER(3)                                     NULL,
    TINYINT3                           NUMBER(3)                                     NULL,
    CHAR1                              VARCHAR2(5)                                   NULL,
    CHAR2                              VARCHAR2(5)                                   NULL,
    CHAR3                              VARCHAR2(5)                                   NULL,
    STRING1                            VARCHAR2(500)                                 NULL,
    STRING2                            VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.CONTROL (
    CONTROL_ID                         NUMBER(5)                                     NOT NULL,
    CONTROL_TYPE_ID                    NUMBER(8)                                     NOT NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    ROW_ID                             NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    VALUE                              VARCHAR2(255)                                 NULL,
    UNIT_TYPE_ID                       NUMBER(10)                                    NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ELEMENTANNOTATION (
    ELEMENT_ANNOTATION_ID              NUMBER(10)                                    NOT NULL,
    ELEMENT_ID                         NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    VALUE                              VARCHAR2(500)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - ELEMENTASSEMBLY does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.ELEMENTASSEMBLY (
    ELEMENT_ID                         NUMBER                                        NULL,
    ASSEMBLY_NA_SEQUENCE_ID            NUMBER                                        NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - ELEMENTASSEMBLY7 does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.ELEMENTASSEMBLY7 (
    ELEMENT_ID                         NUMBER(10)                                    NULL,
    ASSEMBLY_NA_SEQUENCE_ID            NUMBER(10)                                    NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ELEMENTIMP (
    ELEMENT_ID                         NUMBER(10)                                    NOT NULL,
    COMPOSITE_ELEMENT_ID               NUMBER(10)                                    NULL,
    ARRAY_ID                           NUMBER(4)                                     NOT NULL,
    ELEMENT_TYPE_ID                    NUMBER(8)                                     NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NULL,
    SOURCE_ID                          VARCHAR2(50)                                  NULL,
    SUBCLASS_VIEW                      VARCHAR2(27)                                  NOT NULL,
    TINYINT1                           NUMBER(3)                                     NULL,
    SMALLINT1                          NUMBER(5)                                     NULL,
    CHAR1                              VARCHAR2(5)                                   NULL,
    CHAR2                              VARCHAR2(5)                                   NULL,
    CHAR3                              VARCHAR2(5)                                   NULL,
    CHAR4                              VARCHAR2(5)                                   NULL,
    CHAR5                              VARCHAR2(5)                                   NULL,
    CHAR6                              VARCHAR2(5)                                   NULL,
    CHAR7                              VARCHAR2(5)                                   NULL,
    TINYSTRING1                        VARCHAR2(50)                                  NULL,
    TINYSTRING2                        VARCHAR2(50)                                  NULL,
    SMALLSTRING1                       VARCHAR2(100)                                 NULL,
    SMALLSTRING2                       VARCHAR2(100)                                 NULL,
    STRING1                            VARCHAR2(500)                                 NULL,
    STRING2                            VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ELEMENTRESULTIMP (
    ELEMENT_RESULT_ID                  NUMBER(10)                                    NOT NULL,
    ELEMENT_ID                         NUMBER(10)                                    NOT NULL,
    COMPOSITE_ELEMENT_RESULT_ID        NUMBER(10)                                    NULL,
    QUANTIFICATION_ID                  NUMBER(8)                                     NOT NULL,
    SUBCLASS_VIEW                      VARCHAR2(27)                                  NOT NULL,
    FOREGROUND                         FLOAT(126)                                    NULL,
    BACKGROUND                         FLOAT(126)                                    NULL,
    FOREGROUND_SD                      FLOAT(126)                                    NULL,
    BACKGROUND_SD                      FLOAT(126)                                    NULL,
    FLOAT1                             FLOAT(126)                                    NULL,
    FLOAT2                             FLOAT(126)                                    NULL,
    FLOAT3                             FLOAT(126)                                    NULL,
    FLOAT4                             FLOAT(126)                                    NULL,
    FLOAT5                             FLOAT(126)                                    NULL,
    FLOAT6                             FLOAT(126)                                    NULL,
    FLOAT7                             FLOAT(126)                                    NULL,
    FLOAT8                             FLOAT(126)                                    NULL,
    FLOAT9                             FLOAT(126)                                    NULL,
    FLOAT10                            FLOAT(126)                                    NULL,
    FLOAT11                            FLOAT(126)                                    NULL,
    FLOAT12                            FLOAT(126)                                    NULL,
    FLOAT13                            FLOAT(126)                                    NULL,
    FLOAT14                            FLOAT(126)                                    NULL,
    INT1                               NUMBER(12)                                    NULL,
    INT2                               NUMBER(12)                                    NULL,
    INT3                               NUMBER(12)                                    NULL,
    INT4                               NUMBER(12)                                    NULL,
    INT5                               NUMBER(12)                                    NULL,
    INT6                               NUMBER(12)                                    NULL,
    INT7                               NUMBER(12)                                    NULL,
    INT8                               NUMBER(12)                                    NULL,
    INT9                               NUMBER(12)                                    NULL,
    INT10                              NUMBER(12)                                    NULL,
    INT11                              NUMBER(12)                                    NULL,
    INT12                              NUMBER(12)                                    NULL,
    INT13                              NUMBER(12)                                    NULL,
    INT14                              NUMBER(12)                                    NULL,
    INT15                              NUMBER(12)                                    NULL,
    TINYINT1                           NUMBER(3)                                     NULL,
    TINYINT2                           NUMBER(3)                                     NULL,
    TINYINT3                           NUMBER(3)                                     NULL,
    SMALLINT1                          NUMBER(5)                                     NULL,
    SMALLINT2                          NUMBER(5)                                     NULL,
    SMALLINT3                          NUMBER(5)                                     NULL,
    CHAR1                              VARCHAR2(5)                                   NULL,
    CHAR2                              VARCHAR2(5)                                   NULL,
    CHAR3                              VARCHAR2(5)                                   NULL,
    CHAR4                              VARCHAR2(5)                                   NULL,
    TINYSTRING1                        VARCHAR2(50)                                  NULL,
    TINYSTRING2                        VARCHAR2(50)                                  NULL,
    TINYSTRING3                        VARCHAR2(50)                                  NULL,
    SMALLSTRING1                       VARCHAR2(100)                                 NULL,
    SMALLSTRING2                       VARCHAR2(100)                                 NULL,
    STRING1                            VARCHAR2(500)                                 NULL,
    STRING2                            VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - GUSLINKTEMP2 does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.GUSLINKTEMP2 (
    COMPOSITE_ELEMENT_ID               NUMBER(10)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    SIMILARITY_ID                      NUMBER(10)                                    NOT NULL,
    NA_FEATURE_ID                      NUMBER(10)                                    NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.INTEGRITYSTATINPUT (
    INTEGRITY_STAT_INPUT_ID            NUMBER(10)                                    NOT NULL,
    INTEGRITY_STATISTIC_ID             NUMBER(8)                                     NOT NULL,
    INPUT_TABLE_ID                     NUMBER(10)                                    NOT NULL,
    INPUT_ROW_ID                       NUMBER(10)                                    NOT NULL,
    ROW_DESIGNATION                    VARCHAR2(200)                                 NULL,
    IS_TRUSTED_INPUT                   NUMBER(1)                                     DEFAULT 0      NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.INTEGRITYSTATISTIC (
    INTEGRITY_STATISTIC_ID             NUMBER(8)                                     NOT NULL,
    STATISTIC_METHOD                   VARCHAR2(200)                                 NOT NULL,
    TRUSTED_INPUT_FORMULA              VARCHAR2(200)                                 NULL,
    VALUE                              VARCHAR2(100)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.LABELMETHOD (
    LABEL_METHOD_ID                    NUMBER(4)                                     NOT NULL,
    PROTOCOL_ID                        NUMBER(10)                                    NOT NULL,
    CHANNEL_ID                         NUMBER(4)                                     NOT NULL,
    LABEL_USED                         VARCHAR2(50)                                  NULL,
    LABEL_METHOD                       VARCHAR2(1000)                                NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.LOGICALGROUP (
    LOGICAL_GROUP_ID                   NUMBER(8)                                     NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    CATEGORY                           VARCHAR2(50)                                  NULL,
    DESCRIPTION                        VARCHAR2(1000)                                NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.LOGICALGROUPLINK (
    LOGICAL_GROUP_LINK_ID              NUMBER(10)                                    NOT NULL,
    LOGICAL_GROUP_ID                   NUMBER(8)                                     NOT NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    ROW_ID                             NUMBER(12)                                    NOT NULL,
    ORDER_NUM                          NUMBER(8)                                     NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.MAGEDOCUMENTATION (
    MAGE_DOCUMENTATION_ID              NUMBER(5)                                     NOT NULL,
    MAGE_ML_ID                         NUMBER(8)                                     NOT NULL,
    TABLE_ID                           NUMBER(10)                                    NOT NULL,
    ROW_ID                             NUMBER(12)                                    NOT NULL,
    MAGE_IDENTIFIER                    VARCHAR2(100)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.MAGE_ML (
    MAGE_ML_ID                         NUMBER(8)                                     NOT NULL,
    MAGE_PACKAGE                       VARCHAR2(100)                                 NOT NULL,
    MAGE_ML                            CLOB                                          NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.ONTOLOGYENTRY (
    ONTOLOGY_ENTRY_ID                  NUMBER(10)                                    NOT NULL,
    PARENT_ID                          NUMBER(10)                                    NULL,
    TABLE_ID                           NUMBER(8)                                     NULL,
    ROW_ID                             NUMBER(12)                                    NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NULL,
    SOURCE_ID                          VARCHAR2(100)                                 NULL,
    URI                                VARCHAR2(500)                                 NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    CATEGORY                           VARCHAR2(100)                                 NOT NULL,
    VALUE                              VARCHAR2(100)                                 NOT NULL,
    DEFINITION                         VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - ONTOLOGYENTRY_OLD does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.ONTOLOGYENTRY_OLD (
    ONTOLOGY_ENTRY_ID                  NUMBER(10)                                    NOT NULL,
    PARENT_ID                          NUMBER(10)                                    NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NULL,
    SOURCE_ID                          VARCHAR2(100)                                 NULL,
    URI                                VARCHAR2(500)                                 NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    CATEGORY                           VARCHAR2(100)                                 NOT NULL,
    VALUE                              VARCHAR2(100)                                 NOT NULL,
    DEFINITION                         VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.PROCESSIMPLEMENTATION (
    PROCESS_IMPLEMENTATION_ID          NUMBER(5)                                     NOT NULL,
    PROCESS_TYPE_ID                    NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.PROCESSIMPLEMENTATIONPARAM (
    PROCESS_IMPLEMETATION_PARAM_ID     NUMBER(5)                                     NOT NULL,
    PROCESS_IMPLEMENTATION_ID          NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    VALUE                              VARCHAR2(100)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.PROCESSINVOCATION (
    PROCESS_INVOCATION_ID              NUMBER(5)                                     NOT NULL,
    PROCESS_IMPLEMENTATION_ID          NUMBER(5)                                     NOT NULL,
    PROCESS_INVOCATION_DATE            DATE                                          NOT NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.PROCESSINVOCATIONPARAM (
    PROCESS_INVOCATION_PARAM_ID        NUMBER(8)                                     NOT NULL,
    PROCESS_INVOCATION_ID              NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    VALUE                              VARCHAR2(100)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - PROCESSINVOCATION_OLD does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.PROCESSINVOCATION_OLD (
    PROCESS_INVOCATION_ID              NUMBER(5)                                     NOT NULL,
    PROCESS_IMPLEMENTATION_ID          NUMBER(5)                                     NOT NULL,
    PROCESS_INVOCATION_DATE            DATE                                          NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.PROCESSINVQUANTIFICATION (
    PROCESS_INV_QUANTIFICATION_ID      NUMBER(8)                                     NOT NULL,
    PROCESS_INVOCATION_ID              NUMBER(5)                                     NOT NULL,
    QUANTIFICATION_ID                  NUMBER(5)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.PROCESSIO (
    PROCESS_IO_ID                      NUMBER(12)                                    NOT NULL,
    PROCESS_INVOCATION_ID              NUMBER(5)                                     NOT NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    INPUT_RESULT_ID                    NUMBER(12)                                    NOT NULL,
    INPUT_ROLE                         VARCHAR2(50)                                  NULL,
    OUTPUT_RESULT_ID                   NUMBER(12)                                    NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.PROCESSIOELEMENT (
    PROCESS_IO_ELEMENT_ID              NUMBER(10)                                    NOT NULL,
    PROCESS_IO_ID                      NUMBER(10)                                    NOT NULL,
    ELEMENT_ID                         NUMBER(8)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - PROCESSIOELEMENT_MV does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.PROCESSIOELEMENT_MV (
    PROCESS_IO_ID                      NUMBER(12)                                    NOT NULL,
    ELEMENT_ID                         NUMBER(10)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - PROCESSIOELEMENT_OLD does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.PROCESSIOELEMENT_OLD (
    PROCESS_IO_ID                      NUMBER(12)                                    NOT NULL,
    ELEMENT_ID                         NUMBER(10)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.PROCESSRESULT (
    PROCESS_RESULT_ID                  NUMBER(12)                                    NOT NULL,
    VALUE                              FLOAT(126)                                    NOT NULL,
    UNIT_TYPE_ID                       NUMBER(5)                                     NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.PROJECTLINK (
    PROJECT_LINK_ID                    NUMBER(10)                                    NOT NULL,
    PROJECT_ID                         NUMBER(3)                                     NOT NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    ID                                 NUMBER(10)                                    NOT NULL,
    CURRENT_VERSION                    VARCHAR2(4)                                   NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.PROTOCOL (
    PROTOCOL_ID                        NUMBER(10)                                    NOT NULL,
    PROTOCOL_TYPE_ID                   NUMBER(10)                                    NOT NULL,
    SOFTWARE_TYPE_ID                   NUMBER(10)                                    NULL,
    HARDWARE_TYPE_ID                   NUMBER(10)                                    NULL,
    BIBLIOGRAPHIC_REFERENCE_ID         NUMBER(10)                                    NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(4)                                     NULL,
    SOURCE_ID                          VARCHAR2(100)                                 NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    URI                                VARCHAR2(100)                                 NULL,
    PROTOCOL_DESCRIPTION               VARCHAR2(4000)                                NULL,
    HARDWARE_DESCRIPTION               VARCHAR2(500)                                 NULL,
    SOFTWARE_DESCRIPTION               VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.PROTOCOLPARAM (
    PROTOCOL_PARAM_ID                  NUMBER(10)                                    NOT NULL,
    PROTOCOL_ID                        NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    DATA_TYPE_ID                       NUMBER(5)                                     NULL,
    UNIT_TYPE_ID                       NUMBER(5)                                     NULL,
    VALUE                              VARCHAR2(100)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.PROTOCOLQCPARAM (
    PROTOCOL_QC_PARAM_ID               NUMBER(5)                                     NOT NULL,
    PROTOCOL_ID                        NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    DATA_TYPE_ID                       NUMBER(5)                                     NULL,
    UNIT_TYPE_ID                       NUMBER(5)                                     NULL,
    VALUE                              VARCHAR2(100)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - PROTOCOL_OLD does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.PROTOCOL_OLD (
    PROTOCOL_ID                        NUMBER(10)                                    NOT NULL,
    PROTOCOL_TYPE_ID                   NUMBER(5)                                     NOT NULL,
    BIBLIOGRAPHIC_REFERENCE_ID         NUMBER(10)                                    NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(4)                                     NULL,
    SOURCE_ID                          VARCHAR2(100)                                 NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    URI                                VARCHAR2(100)                                 NULL,
    PROTOCOL_DESCRIPTION               VARCHAR2(4000)                                NULL,
    HARDWARE_DESCRIPTION               VARCHAR2(500)                                 NULL,
    SOFTWARE_DESCRIPTION               VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.QUANTIFICATION (
    QUANTIFICATION_ID                  NUMBER(8)                                     NOT NULL,
    ACQUISITION_ID                     NUMBER(8)                                     NOT NULL,
    OPERATOR_ID                        NUMBER(10)                                    NULL,
    PROTOCOL_ID                        NUMBER(10)                                    NULL,
    RESULT_TABLE_ID                    NUMBER(5)                                     NULL,
    QUANTIFICATION_DATE                DATE                                          NULL,
    NAME                               VARCHAR2(250)                                 NULL,
    URI                                VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.QUANTIFICATIONPARAM (
    QUANTIFICATION_PARAM_ID            NUMBER(5)                                     NOT NULL,
    QUANTIFICATION_ID                  NUMBER(4)                                     NOT NULL,
    PROTOCOL_PARAM_ID                  NUMBER(10)                                    NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    VALUE                              VARCHAR2(50)                                  NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - QUANTIFICATIONPARAM_OLD does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.QUANTIFICATIONPARAM_OLD (
    QUANTIFICATION_PARAM_ID            NUMBER(5)                                     NOT NULL,
    QUANTIFICATION_ID                  NUMBER(4)                                     NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    VALUE                              VARCHAR2(50)                                  NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - QUANTIFICATION_OLD does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.QUANTIFICATION_OLD (
    QUANTIFICATION_ID                  NUMBER(4)                                     NOT NULL,
    ACQUISITION_ID                     NUMBER(4)                                     NOT NULL,
    OPERATOR_ID                        NUMBER(10)                                    NULL,
    PROTOCOL_ID                        NUMBER(10)                                    NULL,
    QUANTIFICATION_DATE                DATE                                          NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    URI                                VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.RELATEDACQUISITION (
    RELATED_ACQUISITION_ID             NUMBER(4)                                     NOT NULL,
    ACQUISITION_ID                     NUMBER(8)                                     NOT NULL,
    ASSOCIATED_ACQUISITION_ID          NUMBER(8)                                     NOT NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    DESIGNATION                        VARCHAR2(50)                                  NULL,
    ASSOCIATED_DESIGNATION             VARCHAR2(50)                                  NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.RELATEDQUANTIFICATION (
    RELATED_QUANTIFICATION_ID          NUMBER(4)                                     NOT NULL,
    QUANTIFICATION_ID                  NUMBER(8)                                     NOT NULL,
    ASSOCIATED_QUANTIFICATION_ID       NUMBER(8)                                     NOT NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    DESIGNATION                        VARCHAR2(50)                                  NULL,
    ASSOCIATED_DESIGNATION             VARCHAR2(50)                                  NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.STUDY (
    STUDY_ID                           NUMBER(4)                                     NOT NULL,
    CONTACT_ID                         NUMBER(12)                                    NOT NULL,
    BIBLIOGRAPHIC_REFERENCE_ID         NUMBER(10)                                    NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(4)                                     NULL,
    SOURCE_ID                          VARCHAR2(100)                                 NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    DESCRIPTION                        VARCHAR2(4000)                                NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.STUDYASSAY (
    STUDY_ASSAY_ID                     NUMBER(8)                                     NOT NULL,
    STUDY_ID                           NUMBER(5)                                     NOT NULL,
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.STUDYBIOMATERIAL (
    STUDY_BIO_MATERIAL_ID              NUMBER(10)                                    NOT NULL,
    STUDY_ID                           NUMBER(10)                                    NOT NULL,
    BIO_MATERIAL_ID                    NUMBER(10)                                    NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.STUDYDESIGN (
    STUDY_DESIGN_ID                    NUMBER(5)                                     NOT NULL,
    STUDY_ID                           NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.STUDYDESIGNASSAY (
    STUDY_DESIGN_ASSAY_ID              NUMBER(8)                                     NOT NULL,
    STUDY_DESIGN_ID                    NUMBER(5)                                     NOT NULL,
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.STUDYDESIGNDESCRIPTION (
    STUDY_DESIGN_DESCRIPTION_ID        NUMBER(5)                                     NOT NULL,
    STUDY_DESIGN_ID                    NUMBER(5)                                     NOT NULL,
    DESCRIPTION_TYPE                   VARCHAR2(100)                                 NOT NULL,
    DESCRIPTION                        VARCHAR2(4000)                                NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.STUDYDESIGNTYPE (
    STUDY_DESIGN_TYPE_ID               NUMBER(6)                                     NOT NULL,
    STUDY_DESIGN_ID                    NUMBER(5)                                     NOT NULL,
    ONTOLOGY_ENTRY_ID                  NUMBER(8)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - STUDYDESIGN_OLD does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.STUDYDESIGN_OLD (
    STUDY_DESIGN_ID                    NUMBER(5)                                     NOT NULL,
    STUDY_ID                           NUMBER(5)                                     NOT NULL,
    DESCRIPTION                        VARCHAR2(4000)                                NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.STUDYFACTOR (
    STUDY_FACTOR_ID                    NUMBER(5)                                     NOT NULL,
    STUDY_DESIGN_ID                    NUMBER(5)                                     NOT NULL,
    STUDY_FACTOR_TYPE_ID               NUMBER(8)                                     NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.STUDYFACTORVALUE (
    STUDY_FACTOR_VALUE_ID              NUMBER(8)                                     NOT NULL,
    STUDY_FACTOR_ID                    NUMBER(5)                                     NOT NULL,
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    VALUE_ONTOLOGY_ENTRY_ID            NUMBER(10)                                    NULL,
    STRING_VALUE                       VARCHAR2(100)                                 NULL,
    MEASUREMENT_UNIT_OE_ID             NUMBER(10)                                    NULL,
    MEASUREMENT_TYPE                   VARCHAR2(10)                                  NULL,
    MEASUREMENT_KIND                   VARCHAR2(20)                                  NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - STUDYFACTORVALUE_OLD does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.STUDYFACTORVALUE_OLD (
    STUDY_FACTOR_VALUE_ID              NUMBER(8)                                     NOT NULL,
    STUDY_FACTOR_ID                    NUMBER(5)                                     NOT NULL,
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    FACTOR_VALUE                       VARCHAR2(100)                                 NOT NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - TEMP_ARRAYVIEWER_INTENSITY does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.TEMP_ARRAYVIEWER_INTENSITY (
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    DoTS Id                            NUMBER(12)                                    NOT NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NULL,
    ARRAY_ROW                          VARCHAR2(5)                                   NULL,
    ARRAY_COLUMN                       VARCHAR2(5)                                   NULL,
    GRID_ROW                           VARCHAR2(5)                                   NULL,
    GRID_COLUMN                        VARCHAR2(5)                                   NULL,
    SUB_ROW                            VARCHAR2(5)                                   NULL,
    SUB_COLUMN                         VARCHAR2(5)                                   NULL,
    normalized log value               FLOAT(126)                                    NOT NULL,
    CONFIDENCE_LEVEL                   FLOAT(126)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - TEMP_FORMHELP does not appear in core.TableInfo */

CREATE TABLE @oracle_rad@.TEMP_FORMHELP (
    FORM_HELP_ID                       NUMBER(10)                                    NOT NULL,
    FORM_NAME                          VARCHAR2(50)                                  NOT NULL,
    FIELD_NAME                         VARCHAR2(50)                                  NOT NULL,
    ATTRIBUTE_NAME                     VARCHAR2(100)                                 NULL,
    ISMANDATORY                        VARCHAR2(4)                                   NULL,
    DEFINITION                         VARCHAR2(1000)                                NULL,
    EXAMPLES                           VARCHAR2(500)                                 NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.TREATMENT (
    TREATMENT_ID                       NUMBER(10)                                    NOT NULL,
    ORDER_NUM                          NUMBER(3)                                     NOT NULL,
    BIO_MATERIAL_ID                    NUMBER(5)                                     NOT NULL,
    TREATMENT_TYPE_ID                  NUMBER(5)                                     NOT NULL,
    PROTOCOL_ID                        NUMBER(10)                                    NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_rad@.TREATMENTPARAM (
    TREATMENT_PARAM_ID                 NUMBER(10)                                    NOT NULL,
    TREATMENT_ID                       NUMBER(8)                                     NOT NULL,
    PROTOCOL_PARAM_ID                  NUMBER(10)                                    NOT NULL,
    VALUE                              VARCHAR2(100)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
    USER_READ                          NUMBER(1)                                     NOT NULL,
    USER_WRITE                         NUMBER(1)                                     NOT NULL,
    GROUP_READ                         NUMBER(1)                                     NOT NULL,
    GROUP_WRITE                        NUMBER(1)                                     NOT NULL,
    OTHER_READ                         NUMBER(1)                                     NOT NULL,
    OTHER_WRITE                        NUMBER(1)                                     NOT NULL,
    ROW_USER_ID                        NUMBER(12)                                    NOT NULL,
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_radTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );


/* 79 table(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT


/*                                                                                            */
/* rad3ver-tables.sql                                                                         */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Feb 17 11:49:32 EST 2004     */
/*                                                                                            */

SET ECHO ON
SPOOL rad3ver-tables.log

CREATE TABLE @oracle_radver@.ACQUISITIONPARAMVER (
    ACQUISITION_PARAM_ID               NUMBER(5)                                     NOT NULL,
    ACQUISITION_ID                     NUMBER(8)                                     NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ACQUISITIONVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ANALYSISINPUTVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ANALYSISPARAMVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ANALYSISQCPARAMVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ANALYSISRESULTIMPVER (
    ANALYSIS_RESULT_ID                 NUMBER(12)                                    NOT NULL,
    SUBCLASS_VIEW                      VARCHAR2(27)                                  NOT NULL,
    ANALYSIS_ID                        NUMBER(8)                                     NOT NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    ROW_ID                             NUMBER(12)                                    NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ANALYSISVER (
    ANALYSIS_ID                        NUMBER(8)                                     NOT NULL,
    OPERATOR_ID                        NUMBER(10)                                    NULL,
    PROTOCOL_ID                        NUMBER(8)                                     NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ARRAYANNOTATIONVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ARRAYGROUPLINKVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ARRAYGROUPVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ARRAYVER (
    ARRAY_ID                           NUMBER(4)                                     NOT NULL,
    MANUFACTURER_ID                    NUMBER(12)                                    NOT NULL,
    PLATFORM_TYPE_ID                   NUMBER(8)                                     NOT NULL,
    SUBSTRATE_TYPE_ID                  NUMBER(8)                                     NULL,
    PROTOCOL_ID                        NUMBER(12)                                    NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(4)                                     NULL,
    SOURCE_ID                          VARCHAR2(100)                                 NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    VERSION                            VARCHAR2(50)                                  NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ASSAYBIOMATERIALVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

/* WARNING - ASSAYCONTROLVER does not appear in core.TableInfo */

CREATE TABLE @oracle_radver@.ASSAYCONTROLVER (
    ASSAY_CONTROL_ID                   NUMBER(8)                                     NOT NULL,
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    CONTROL_ID                         NUMBER(5)                                     NOT NULL,
    VALUE                              VARCHAR2(255)                                 NULL,
    UNIT_TYPE_OE_ID                    NUMBER(10)                                    NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ASSAYLABELEDEXTRACTVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ASSAYPARAMVER (
    ASSAY_PARAM_ID                     NUMBER(10)                                    NOT NULL,
    ASSAY_ID                           NUMBER(8)                                     NOT NULL,
    PROTOCOL_PARAM_ID                  NUMBER(5)                                     NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ASSAYVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.BIOMATERIALCHARACTERISTICVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.BIOMATERIALIMPVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.BIOMATERIALMEASUREMENTVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.CHANNELVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.COMPOSITEELEMENTANNOTATIONVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.COMPOSITEELEMENTGUSVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.COMPOSITEELEMENTIMPVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.COMPOSITEELEMENTRESULTIMPVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.CONTROLVER (
    CONTROL_ID                         NUMBER(5)                                     NOT NULL,
    CONTROL_TYPE_ID                    NUMBER(8)                                     NOT NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    ROW_ID                             NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    VALUE                              VARCHAR2(255)                                 NULL,
    UNIT_TYPE_OE_ID                    NUMBER(10)                                    NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ELEMENTANNOTATIONVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ELEMENTIMPVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ELEMENTRESULTIMPVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.INTEGRITYSTATINPUTVER (
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
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.INTEGRITYSTATISTICVER (
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
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.LABELMETHODVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.LOGICALGROUPLINKVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.LOGICALGROUPVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.MAGEDOCUMENTATIONVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.MAGE_MLVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.ONTOLOGYENTRYVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.PROCESSIMPLEMENTATIONPARAMVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.PROCESSIMPLEMENTATIONVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.PROCESSINVOCATIONPARAMVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.PROCESSINVOCATIONVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.PROCESSINVQUANTIFICATIONVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.PROCESSIOELEMENTVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.PROCESSIOVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.PROCESSRESULTVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.PROJECTLINKVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.PROTOCOLPARAMVER (
    PROTOCOL_PARAM_ID                  NUMBER(5)                                     NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.PROTOCOLQCPARAMVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.PROTOCOLVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.QUANTIFICATIONPARAMVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.QUANTIFICATIONVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.RELATEDACQUISITIONVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.RELATEDQUANTIFICATIONVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.STUDYASSAYVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.STUDYBIOMATERIALVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.STUDYDESIGNASSAYVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.STUDYDESIGNDESCRIPTIONVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.STUDYDESIGNTYPEVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.STUDYDESIGNVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.STUDYFACTORVALUEVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.STUDYFACTORVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.STUDYVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.TREATMENTPARAMVER (
    TREATMENT_PARAM_ID                 NUMBER(10)                                    NOT NULL,
    TREATMENT_ID                       NUMBER(8)                                     NOT NULL,
    PROTOCOL_PARAM_ID                  NUMBER(5)                                     NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_radver@.TREATMENTVER (
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_radverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );


/* 63 table(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

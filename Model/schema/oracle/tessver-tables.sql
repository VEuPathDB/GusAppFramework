
/*                                                                                            */
/* tessver-tables.sql                                                                         */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 20:48:21 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL tessver-tables.log

CREATE TABLE @oracle_tessver@.ACTIVITYCONDITIONSVER (
    ACTIVITY_CONDITIONS_ID             NUMBER(12)                                    NOT NULL,
    ACTIVITY_ID                        NUMBER(12)                                    NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(12)                                    NULL,
    TAXON_ID                           NUMBER(12)                                    NULL,
    ANATOMY_ID                         NUMBER(12)                                    NULL,
    CELL_TYPE_ID                       NUMBER(12)                                    NULL,
    DEVELOPMENTAL_STAGE_ID             NUMBER(12)                                    NULL,
    DISEASE_ID                         NUMBER(12)                                    NULL,
    PHENOTYPE_ID                       NUMBER(12)                                    NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.ACTIVITYIMPVER (
    ACTIVITY_ID                        NUMBER(12)                                    NOT NULL,
    SUBCLASS_VIEW                      VARCHAR2(32)                                  NOT NULL,
    TYPE_NAME                          VARCHAR2(32)                                  NOT NULL,
    GO_TERM_ID                         NUMBER(12)                                    NULL,
    MOIETY_ID                          NUMBER(12)                                    NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(12)                                    NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    NAME                               VARCHAR2(255)                                 NULL,
    REVIEW_STATUS_ID                   NUMBER(12)                                    NOT NULL,
    STRING1                            VARCHAR2(255)                                 NULL,
    STRING2                            VARCHAR2(255)                                 NULL,
    STRING3                            VARCHAR2(255)                                 NULL,
    STRING4                            VARCHAR2(255)                                 NULL,
    INT1                               NUMBER(12)                                    NULL,
    INT2                               NUMBER(12)                                    NULL,
    INT3                               NUMBER(12)                                    NULL,
    INT4                               NUMBER(12)                                    NULL,
    FLOAT1                             FLOAT(126)                                    NULL,
    FLOAT2                             FLOAT(126)                                    NULL,
    FLOAT3                             FLOAT(126)                                    NULL,
    FLOAT4                             FLOAT(126)                                    NULL,
    CLOB1                              CLOB                                          NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.ACTIVITYINFERENCESOURCEVER (
    ACTIVITY_INFERENCE_SOURCE          NUMBER(12)                                    NOT NULL,
    ACTIVITY_ID                        NUMBER(12)                                    NOT NULL,
    RESULT_GROUP_ID                    NUMBER(12)                                    NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.ANALYSISVER (
    ANALYSIS_ID                        NUMBER(12)                                    NOT NULL,
    POSITIVE_TRAINING_SET_ID           NUMBER(12)                                    NOT NULL,
    NEGATIVE_TRAINING_SET_ID           NUMBER(12)                                    NULL,
    PROTOCOL_ID                        NUMBER(12)                                    NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(12)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(12)                                    NULL,
    MODEL_COUNT                        NUMBER(6)                                     NOT NULL,
    PREDICTION_COUNT                   NUMBER(6)                                     NOT NULL,
    PARAMETER_GROUP_ID                 NUMBER(12)                                    NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.FOOTPRINTMETHODPROTOCOLVER (
    FOOTPRINT_PROTOCOL_ID              NUMBER(12)                                    NOT NULL,
    FOOTPRINT_ID                       NUMBER(12)                                    NOT NULL,
    PROTOCOL_ID                        NUMBER(12)                                    NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.FOOTPRINTVER (
    FOOTPRINT_ID                       NUMBER(12)                                    NOT NULL,
    ACTIVITY_ID                        NUMBER(12)                                    NOT NULL,
    NA_FEATURE_ID                      NUMBER(12)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(12)                                    NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.MODELRESULTVER (
    MODEL_RESULT_ID                    NUMBER(12)                                    NOT NULL,
    SBCG_GRAMMAR_ID                    NUMBER(12)                                    NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(12)                                    NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.MODELVER (
    ACTIVITY_MODEL_ID                  NUMBER(12)                                    NOT NULL,
    ACTIVITY_ID                        NUMBER(12)                                    NOT NULL,
    SBCG_GRAMMAR_ID                    NUMBER(12)                                    NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.MOIETYIMPVER (
    MOIETY_ID                          NUMBER(12)                                    NOT NULL,
    SUBCLASS_VIEW                      VARCHAR2(32)                                  NOT NULL,
    TYPE_NAME                          VARCHAR2(32)                                  NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(12)                                    NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    NAME                               VARCHAR2(255)                                 NULL,
    TAXON_ID                           NUMBER(12)                                    NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(12)                                    NOT NULL,
    STRING1                            VARCHAR2(255)                                 NULL,
    STRING2                            VARCHAR2(255)                                 NULL,
    STRING3                            VARCHAR2(255)                                 NULL,
    STRING4                            VARCHAR2(255)                                 NULL,
    INT1                               NUMBER(12)                                    NULL,
    INT2                               NUMBER(12)                                    NULL,
    INT3                               NUMBER(12)                                    NULL,
    INT4                               NUMBER(12)                                    NULL,
    FLOAT1                             FLOAT(126)                                    NULL,
    FLOAT2                             FLOAT(126)                                    NULL,
    FLOAT3                             FLOAT(126)                                    NULL,
    FLOAT4                             FLOAT(126)                                    NULL,
    CLOB1                              CLOB                                          NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.MOIETYINSTANCEVER (
    MOIETY_INSTANCE_ID                 NUMBER(12)                                    NOT NULL,
    MOIETY_ID                          NUMBER(12)                                    NOT NULL,
    DOGMA_OBJECT_TABLE_ID              NUMBER(12)                                    NOT NULL,
    DOGMA_OBJECT_ID                    NUMBER(12)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(12)                                    NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.MOIETYMEMBERVER (
    MOIETY_MEMBER_ID                   NUMBER(12)                                    NOT NULL,
    WHOLE_MOIETY_ID                    NUMBER(12)                                    NOT NULL,
    PART_MOIETY_ID                     NUMBER(12)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(12)                                    NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    NAME                               VARCHAR2(255)                                 NULL,
    REVIEW_STATUS_ID                   NUMBER(12)                                    NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.MOIETYSYNONYMVER (
    MOIETY_SYNONYM_ID                  NUMBER(12)                                    NOT NULL,
    MOIETY_ID                          NUMBER(12)                                    NOT NULL,
    SYNONYM_TEXT                       VARCHAR2(255)                                 NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(12)                                    NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.MULTINOMIALLABELSETVER (
    MULTINOMIAL_LABEL_SET_ID           NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(20)                                  NOT NULL,
    SIGNATURE                          VARCHAR2(255)                                 NOT NULL,
    IS_INTEGRAL                        NUMBER(1)                                     NOT NULL,
    CARDINALITY                        NUMBER                                        NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.MULTINOMIALLABELVER (
    MULTINOMIAL_LABEL_ID               NUMBER(12)                                    NOT NULL,
    MULTINOMIAL_LABEL_SET_ID           NUMBER(12)                                    NOT NULL,
    ORDINAL                            NUMBER                                        NOT NULL,
    LABEL                              VARCHAR2(32)                                  NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.MULTINOMIALOBSERVATIONSETVER (
    MULTINOMIAL_OBS_SET_ID             NUMBER                                        NOT NULL,
    RECOGNITION_ID                     NUMBER                                        NOT NULL,
    ORDINAL                            NUMBER                                        NOT NULL,
    MULTINOMIAL_LABEL_SET_ID           NUMBER                                        NOT NULL,
    TOTAL_OBSERVATIONS                 NUMBER                                        NOT NULL,
    IS_NORMALIZED                      NUMBER(1)                                     NOT NULL,
    ENTROPY                            FLOAT(126)                                    NOT NULL,
    INFORMATION                        FLOAT(126)                                    NOT NULL,
    CONSENSUS                          CHAR(32)                                      NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.MULTINOMIALOBSERVATIONVER (
    MULTINOMIAL_OBS_ID                 NUMBER(12)                                    NOT NULL,
    MULTINOMIAL_OBS_SET_ID             NUMBER(12)                                    NOT NULL,
    MULTINOMIAL_LABEL_ID               NUMBER(12)                                    NOT NULL,
    OBSERVATION                        FLOAT(126)                                    NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.NOTEVER (
    NOTE_ID                            NUMBER(12)                                    NOT NULL,
    TABLE_ID                           NUMBER(12)                                    NOT NULL,
    ROW_ID                             NUMBER(12)                                    NOT NULL,
    NOTE_CLASS                         VARCHAR2(32)                                  NOT NULL,
    ORDINAL                            NUMBER                                        NOT NULL,
    NOTE_TEXT                          VARCHAR2(4000)                                NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.PARAMETERGROUPVER (
    PARAMETER_GROUP_ID                 NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(255)                                 NOT NULL,
    DESCRIPTION                        CLOB                                          NULL,
    REVIEW_STATUS_ID                   NUMBER(12)                                    NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.PARAMETERSUBGROUPVER (
    PARAMETER_SUBGROUP_ID              NUMBER(12)                                    NOT NULL,
    PARENT_GROUP_ID                    NUMBER(12)                                    NOT NULL,
    CHILD_GROUP_ID                     NUMBER(12)                                    NOT NULL,
    ORDINAL                            NUMBER                                        NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.PARAMETERVALUEVER (
    PARAMETER_VALUE_ID                 NUMBER(12)                                    NOT NULL,
    PARAMETER_GROUP_ID                 NUMBER(12)                                    NOT NULL,
    ORDINAL                            NUMBER                                        NOT NULL,
    NAME                               VARCHAR2(255)                                 NOT NULL,
    TYPE_ID                            NUMBER(12)                                    NULL,
    VALUE                              VARCHAR2(255)                                 NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.PARSERITEMEDGETYPEVER (
    PARSER_ITEM_EDGE_TYPE_ID           NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(16)                                  NOT NULL,
    DESCRIPTION                        CLOB                                          NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.PARSERITEMLINKVER (
    PARSER_ITEM_LINK_ID                NUMBER(12)                                    NOT NULL,
    PARENT_PARSER_ITEM_ID              NUMBER(12)                                    NOT NULL,
    CHILD_PARSER_ITEM_ID               NUMBER(12)                                    NOT NULL,
    PARSER_ITEM_EDGE_TYPE_ID           NUMBER(12)                                    NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.PARSERITEMVER (
    PARSER_ITEM_ID                     NUMBER(12)                                    NOT NULL,
    SBCG_RECOGNITION_ID                NUMBER(12)                                    NOT NULL,
    NA_FEATURE_ID                      NUMBER(12)                                    NULL,
    AA_FEATURE_ID                      NUMBER(12)                                    NULL,
    INSTANCE_COUNT                     NUMBER(6)                                     NOT NULL,
    BEGIN_COORD                        NUMBER(12)                                    NOT NULL,
    END_COORD                          NUMBER(12)                                    NOT NULL,
    IS_REVERSED                        NUMBER(1)                                     NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.PREDICTIONRESULTVER (
    PREDICTION_RESULT_ID               NUMBER(12)                                    NOT NULL,
    SBCG_GRAMMAR_ID                    NUMBER(12)                                    NOT NULL,
    FOOTPRINT_ID                       NUMBER(12)                                    NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(12)                                    NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.SBCGANNOTATIONFILTERTERMVER (
    SCBG_ANNOTATION_FILTER_TERM_ID     NUMBER(12)                                    NOT NULL,
    SBCG_ANNOTATION_FILTER_ID          NUMBER(12)                                    NOT NULL,
    ORDINAL                            NUMBER(4)                                     NOT NULL,
    ATTRIBUTE_NAME                     VARCHAR2(32)                                  NOT NULL,
    SBCG_COMPARISON_TYPE_ID            NUMBER(12)                                    NOT NULL,
    IS_NUMERIC_VALUE                   NUMBER(1)                                     NOT NULL,
    CONSTANT_VALUE                     VARCHAR2(255)                                 NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.SBCGANNOTATIONFILTERVER (
    SBCG_ANNOTATION_FILTER_ID          NUMBER(12)                                    NOT NULL,
    SBCG_RECOG_PATH_EXPRESSION_ID      NUMBER(12)                                    NOT NULL,
    ORDINAL                            NUMBER(6)                                     NOT NULL,
    SBCG_PATH_TERM_REL_TYPE_ID         NUMBER(12)                                    NULL,
    SBCG_STREAM_NAME                   VARCHAR2(32)                                  NULL,
    NUMBER_OF_FILTER_TERMS             NUMBER(3)                                     NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.SBCGANNOTATIONGUIDEVER (
    SBCG_ANNOTATION_GUIDE_ID           NUMBER(12)                                    NOT NULL,
    SBCG_GRAMMAR_ID                    NUMBER(12)                                    NOT NULL,
    SOURCE_CODE                        CLOB                                          NOT NULL,
    TYPE_VALUE                         VARCHAR2(255)                                 NULL,
    CATEGORY_VALUE                     VARCHAR2(255)                                 NULL,
    NAME_VALUE                         VARCHAR2(255)                                 NULL,
    ID_VALUE                           VARCHAR2(255)                                 NULL,
    METHOD_VALUE                       VARCHAR2(255)                                 NULL,
    MODELID_VALUE                      VARCHAR2(255)                                 NULL,
    MODEL_VALUE                        VARCHAR2(255)                                 NULL,
    SCORE_VALUE                        VARCHAR2(255)                                 NULL,
    REVIEWED_VALUE                     VARCHAR2(255)                                 NULL,
    START_VALUE                        VARCHAR2(255)                                 NULL,
    END_VALUE                          VARCHAR2(255)                                 NULL,
    SENSE_VALUE                        VARCHAR2(255)                                 NULL,
    LENGTH_VALUE                       VARCHAR2(255)                                 NULL,
    INDEX_VALUE                        VARCHAR2(255)                                 NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.SBCGCOMPARISONTYPEVER (
    SBCG_COMPARISON_TYPE_ID            NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(32)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.SBCGGRAMMARVER (
    SBCG_GRAMMAR_ID                    NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(255)                                 NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(12)                                    NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    VERSION_STRING                     VARCHAR2(32)                                  NULL,
    VERSION_DESCRIPTION                CLOB                                          NULL,
    SECONDARY_ID                       VARCHAR2(32)                                  NULL,
    BEST_PRACTICE_TEST_COND_ID         NUMBER(12)                                    NULL,
    REVIEW_STATUS_ID                   NUMBER(12)                                    NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.SBCGNONTERMINALVER (
    SBCG_NONTERMINAL_ID                NUMBER(12)                                    NOT NULL,
    SBGC_GRAMMAR_ID                    NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(255)                                 NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.SBCGPATHTERMRELATIONTYPEVER (
    SBCG_PATH_TERM_REL_TYPE_ID         NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(32)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.SBCGPRODUCTIONTYPEVER (
    SBCG_PRODUCTION_TYPE_ID            NUMBER(12)                                    NOT NULL,
    TYPE_NAME                          VARCHAR2(16)                                  NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.SBCGPRODUCTIONVER (
    SBCG_PRODUCTION_ID                 NUMBER(12)                                    NOT NULL,
    SBGC_GRAMMAR_ID                    NUMBER(12)                                    NOT NULL,
    ORDINAL                            NUMBER(12)                                    NOT NULL,
    SOURCE_CODE                        CLOB                                          NOT NULL,
    COMMENT_STRING                     CLOB                                          NULL,
    SBCG_NONTERMINAL_ID                NUMBER(12)                                    NOT NULL,
    LG_PROBABILITY                     FLOAT(126)                                    NOT NULL,
    SBCG_PRODUCTION_TYPE_ID            NUMBER(12)                                    NOT NULL,
    RHS_TERMS_N                        NUMBER(10)                                    NOT NULL,
    SBCG_ANNOTATION_GUIDE_ID           NUMBER(12)                                    NULL,
    SIZE_BOUND_N                       NUMBER(12)                                    NULL,
    SBCG_PATH_BOUND_ID                 NUMBER(12)                                    NULL,
    MINIMAL                            NUMBER(1)                                     NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.SBCGRECOGNITIONIMPVER (
    SBCG_RECOGNITION_ID                NUMBER(12)                                    NOT NULL,
    SUBCLASS_VIEW                      VARCHAR2(32)                                  NOT NULL,
    SBCG_GRAMMAR_ID                    NUMBER(12)                                    NOT NULL,
    SBCG_NONTERMINAL_ID                NUMBER(12)                                    NULL,
    SBCG_STREAM_ID                     NUMBER(12)                                    NULL,
    PARENT_SBCG_RECOGNITION_ID         NUMBER(12)                                    NULL,
    STRING1                            VARCHAR2(255)                                 NULL,
    STRING2                            VARCHAR2(255)                                 NULL,
    STRING3                            VARCHAR2(255)                                 NULL,
    STRING4                            VARCHAR2(255)                                 NULL,
    BOOLEAN1                           NUMBER(1)                                     NULL,
    BOOLEAN2                           NUMBER(1)                                     NULL,
    BOOLEAN3                           NUMBER(1)                                     NULL,
    BOOLEAN4                           NUMBER(1)                                     NULL,
    INT1                               NUMBER                                        NULL,
    INT2                               NUMBER                                        NULL,
    INT3                               NUMBER                                        NULL,
    INT4                               NUMBER                                        NULL,
    FLOAT1                             FLOAT(126)                                    NULL,
    FLOAT2                             FLOAT(126)                                    NULL,
    FLOAT3                             FLOAT(126)                                    NULL,
    FLOAT4                             FLOAT(126)                                    NULL,
    CLOB1                              CLOB                                          NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.SBCGRHSTERMVER (
    SBCG_RHS_TERM_ID                   NUMBER(12)                                    NOT NULL,
    SBCG_PRODUCTION_ID                 NUMBER(12)                                    NOT NULL,
    COMMENT_STRING                     CLOB                                          NULL,
    ORDINAL                            NUMBER(6)                                     NOT NULL,
    SBCG_RECOGNITION_ID                NUMBER(12)                                    NOT NULL,
    COUNT_MIN                          NUMBER(6)                                     NULL,
    COUNT_MAX                          NUMBER(6)                                     NULL,
    COUNT_PROBABILITY                  FLOAT(126)                                    NULL,
    CARDINALITY                        NUMBER(6)                                     NULL,
    CAN_BE_NORMAL                      NUMBER(1)                                     NOT NULL,
    CAN_BE_REVERSED                    NUMBER(1)                                     NOT NULL,
    CAN_OVERLAP                        NUMBER(1)                                     NOT NULL,
    SBCG_ANNOTATION_GUIDE_ID           NUMBER(12)                                    NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.SBCGSTREAMPARAMETERVER (
    SBCG_STREAM_PARAMETER_ID           NUMBER(12)                                    NOT NULL,
    SBCG_STREAM_ID                     NUMBER(12)                                    NOT NULL,
    PARAMETER_NAME                     VARCHAR2(255)                                 NOT NULL,
    TYPE_NAME                          VARCHAR2(32)                                  NOT NULL,
    VALUE                              VARCHAR2(4000)                                NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.SBCGSTREAMVER (
    SBCG_STREAM_ID                     NUMBER(12)                                    NOT NULL,
    SBCG_GRAMMAR_ID                    NUMBER(12)                                    NOT NULL,
    SOURCE_CODE                        CLOB                                          NOT NULL,
    COMMENT_STRING                     CLOB                                          NULL,
    STREAM_NAME                        VARCHAR2(255)                                 NOT NULL,
    PLUGIN_NAME                        VARCHAR2(255)                                 NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.TRAININGSETMEMBERVER (
    TRAINING_SET_MEMBER_ID             NUMBER(12)                                    NOT NULL,
    TRAINING_SET_ID                    NUMBER(12)                                    NOT NULL,
    FOOTPRINT_ID                       NUMBER(12)                                    NOT NULL,
    IS_REDUNDANT                       NUMBER(1)                                     NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_tessver@.TRAININGSETVER (
    TRAINING_SET_ID                    NUMBER(12)                                    NOT NULL,
    ACTIVITY_ID                        NUMBER(12)                                    NULL,
    NAME                               VARCHAR2(255)                                 NOT NULL,
    IS_POSITIVE                        NUMBER(1)                                     NOT NULL,
    IS_TEST                            NUMBER(1)                                     NOT NULL,
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
 TABLESPACE @oracle_tessverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );


/* 39 table(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT


/*                                                                                            */
/* dots-tables.sql                                                                            */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 12:23:38 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL dots-tables.log

CREATE TABLE DoTStest.AACOMMENT (
    AA_COMMENT_ID                      NUMBER(10)                                    NOT NULL,
    AA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    COMMENT_NAME_ID                    NUMBER(4)                                     NULL,
    COMMENT_STRING                     VARCHAR2(4000)                                NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AAENTRY (
    AA_ENTRY_ID                        NUMBER(10)                                    NOT NULL,
    AA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    SOURCE_ID                          VARCHAR2(15)                                  NOT NULL,
    STATUS                             VARCHAR2(12)                                  NULL,
    CREATED_DATE                       DATE                                          NULL,
    CREATED_REL_VER                    NUMBER(5)                                     NULL,
    SEQ_DATE                           DATE                                          NULL,
    SEQ_REL_VER                        NUMBER(5)                                     NULL,
    ANNOT_DATE                         DATE                                          NULL,
    ANNOT_REL_VER                      NUMBER(5)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AAFAMILYEXPERIMENT (
    AA_FAMILY_EXPERIMENT_ID            NUMBER(12)                                    NOT NULL,
    DESCRIPTION                        VARCHAR2(2000)                                NULL,
    AA_ORTHOLOG_EXPERIMENT_ID          NUMBER(12)                                    NULL,
    AA_PARALOG_EXPERIMENT_ID           NUMBER(12)                                    NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AAFEATUREIMP (
    AA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
    AA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    FEATURE_NAME_ID                    NUMBER(10)                                    NULL,
    PARENT_ID                          NUMBER(10)                                    NULL,
    NA_FEATURE_ID                      NUMBER(10)                                    NULL,
    SUBCLASS_VIEW                      VARCHAR2(30)                                  NULL,
    SEQUENCE_ONTOLOGY_ID               NUMBER(10)                                    NULL,
    DESCRIPTION                        VARCHAR2(4000)                                NULL,
    PFAM_ENTRY_ID                      NUMBER(10)                                    NULL,
    MOTIF_AA_SEQUENCE_ID               NUMBER(10)                                    NULL,
    REPEAT_TYPE_ID                     NUMBER(10)                                    NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NULL,
    SOURCE_ID                          VARCHAR2(50)                                  NULL,
    PREDICTION_ALGORITHM_ID            NUMBER(5)                                     NULL,
    IS_PREDICTED                       NUMBER(1)                                     NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
    TINYINT1                           NUMBER(3)                                     NULL,
    TINYINT2                           NUMBER(3)                                     NULL,
    TINYINT3                           NUMBER(3)                                     NULL,
    TINYINT4                           NUMBER(3)                                     NULL,
    TINYINT5                           NUMBER(3)                                     NULL,
    TINYINT6                           NUMBER(3)                                     NULL,
    FLOAT1                             FLOAT(126)                                    NULL,
    FLOAT2                             FLOAT(126)                                    NULL,
    FLOAT3                             FLOAT(126)                                    NULL,
    FLOAT4                             FLOAT(126)                                    NULL,
    FLOAT5                             FLOAT(126)                                    NULL,
    FLOAT6                             FLOAT(126)                                    NULL,
    STRING1                            VARCHAR2(255)                                 NULL,
    STRING2                            VARCHAR2(255)                                 NULL,
    STRING3                            VARCHAR2(255)                                 NULL,
    STRING4                            VARCHAR2(255)                                 NULL,
    STRING5                            VARCHAR2(255)                                 NULL,
    STRING6                            VARCHAR2(4000)                                NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AAGENE (
    AA_GENE_ID                         NUMBER(10)                                    NOT NULL,
    AA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(50)                                  NOT NULL,
    IS_VERIFIED                        NUMBER(1)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AAGENESYNONYM (
    AA_GENE_SYNONYM_ID                 NUMBER(10)                                    NOT NULL,
    AA_GENE_ID                         NUMBER(10)                                    NOT NULL,
    SYNONYM_NAME                       VARCHAR2(50)                                  NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AALOCATION (
    AA_LOCATION_ID                     NUMBER(10)                                    NOT NULL,
    AA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
    START_MIN                          NUMBER(12)                                    NULL,
    START_MAX                          NUMBER(12)                                    NULL,
    END_MIN                            NUMBER(12)                                    NULL,
    END_MAX                            NUMBER(12)                                    NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AAMOTIFGOTERMRULE (
    AA_MOTIF_GO_TERM_RULE_ID           NUMBER(10)                                    NOT NULL,
    AA_MOTIF_GO_TERM_RULE_SET_ID       NUMBER(10)                                    NOT NULL,
    GO_TERM_ID                         NUMBER(10)                                    NOT NULL,
    NUMBER_OF_ANNOTATED_PROTEINS       NUMBER(12)                                    NOT NULL,
    DEFINING                           NUMBER(1)                                     NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
    REVIEWER_ID                        NUMBER(12)                                    NULL,
    CONFIDENCE                         VARCHAR2(10)                                  NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AAMOTIFGOTERMRULESET (
    AA_MOTIF_GO_TERM_RULE_SET_ID       NUMBER(10)                                    NOT NULL,
    AA_SEQUENCE_ID_1                   NUMBER(10)                                    NOT NULL,
    AA_SEQUENCE_ID_2                   NUMBER(10)                                    NULL,
    RULE_TYPE                          VARCHAR2(10)                                  NOT NULL,
    NUMBER_OF_ANNOTATED_PROTEINS       NUMBER(12)                                    NOT NULL,
    P_VALUE_THRESHOLD_MANT             FLOAT(126)                                    NOT NULL,
    P_VALUE_THRESHOLD_EXP              NUMBER(6)                                     NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
    REVIEWER_ID                        NUMBER(12)                                    NULL,
    CONFIDENCE                         VARCHAR2(10)                                  NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AASEQGROUPEXPERIMENTIMP (
    AA_SEQ_GROUP_EXPERIMENT_ID         NUMBER(12)                                    NOT NULL,
    SUBCLASS_VIEW                      VARCHAR2(30)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(2000)                                NULL,
    SEQUENCE_SOURCE                    VARCHAR2(500)                                 NULL,
    PVALUE_MANT                        FLOAT(63)                                     NULL,
    PVALUE_EXP                         NUMBER(12)                                    NULL,
    PERCENT_IDENTITY                   FLOAT(63)                                     NULL,
    PERCENT_MATCH                      FLOAT(63)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AASEQUENCEDBREF (
    AA_SEQUENCE_DB_REF_ID              NUMBER(10)                                    NOT NULL,
    AA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    DB_REF_ID                          NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AASEQUENCEFAMILY (
    AA_SEQUENCE_FAMILY_ID              NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(500)                                 NOT NULL,
    DESCRIPTION                        VARCHAR2(2000)                                NULL,
    AA_FAMILY_EXPERIMENT_ID            NUMBER(12)                                    NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AASEQUENCEGROUPFAMILY (
    AA_SEQUENCE_GROUP_FAMILY_ID        NUMBER(12)                                    NOT NULL,
    AA_SEQUENCE_FAMILY_ID              NUMBER(12)                                    NULL,
    AA_SEQUENCE_GROUP_ID               NUMBER(12)                                    NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AASEQUENCEGROUPIMP (
    AA_SEQUENCE_GROUP_ID               NUMBER(12)                                    NOT NULL,
    SUBCLASS_VIEW                      VARCHAR2(30)                                  NOT NULL,
    NAME                               VARCHAR2(500)                                 NULL,
    DESCRIPTION                        VARCHAR2(2000)                                NULL,
    NUMBER_OF_MEMBERS                  NUMBER(12)                                    NOT NULL,
    MAX_SCORE                          FLOAT(22)                                     NULL,
    MIN_SCORE                          FLOAT(22)                                     NULL,
    MAX_MATCH_IDENTITY                 FLOAT(63)                                     NULL,
    MIN_MATCH_IDENTITY                 FLOAT(63)                                     NULL,
    MAX_MATCH_LENGTH                   NUMBER(12)                                    NULL,
    MIN_MATCH_LENGTH                   NUMBER(12)                                    NULL,
    MAX_PVALUE_MANT                    FLOAT(63)                                     NULL,
    MAX_PVALUE_EXP                     NUMBER(12)                                    NULL,
    MIN_PVALUE_MANT                    FLOAT(63)                                     NULL,
    MIN_PVALUE_EXP                     NUMBER(12)                                    NULL,
    AA_SEQ_GROUP_EXPERIMENT_ID         NUMBER(12)                                    NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AASEQUENCEIMP (
    AA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    SEQUENCE_VERSION                   NUMBER(3)                                     DEFAULT 1     NULL,
    SUBCLASS_VIEW                      VARCHAR2(30)                                  NOT NULL,
    MOLECULAR_WEIGHT                   NUMBER(12)                                    NULL,
    SEQUENCE                           CLOB                                          NULL,
    LENGTH                             NUMBER(12)                                    NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    SOURCE_AA_SEQUENCE_ID              NUMBER(10)                                    NULL,
    TINYINT1                           NUMBER(3)                                     NULL,
    STRING1                            VARCHAR2(255)                                 NULL,
    STRING2                            VARCHAR2(255)                                 NULL,
    STRING3                            VARCHAR2(255)                                 NULL,
    STRING4                            VARCHAR2(255)                                 NULL,
    INT1                               NUMBER(12)                                    NULL,
    INT2                               NUMBER(12)                                    NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AASEQUENCEKEYWORD (
    AA_SEQUENCE_KEYWORD_ID             NUMBER(10)                                    NOT NULL,
    AA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    KEYWORD_ID                         NUMBER(6)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AASEQUENCEORGANELLE (
    AA_SEQUENCE_ORGANELLE_ID           NUMBER(10)                                    NOT NULL,
    AA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    ORGANELLE_ID                       NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AASEQUENCEREF (
    AA_SEQUENCE_REF_ID                 NUMBER(10)                                    NOT NULL,
    AA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    REFERENCE_ID                       NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AASEQUENCESEQUENCEGROUP (
    AA_SEQUENCE_SEQUENCE_GROUP_ID      NUMBER(12)                                    NOT NULL,
    AA_SEQUENCE_ID                     NUMBER(12)                                    NOT NULL,
    AA_SEQUENCE_GROUP_ID               NUMBER(12)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.AASEQUENCETAXON (
    AA_SEQUENCE_TAXON_ID               NUMBER(10)                                    NOT NULL,
    AA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    TAXON_ID                           NUMBER(12)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ALLELE (
    ALLELE_ID                          NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    GENE_ID                            NUMBER(10)                                    NOT NULL,
    IS_WILDTYPE                        NUMBER(1)                                     NULL,
    MUTAGEN_ID                         NUMBER(10)                                    NULL,
    MUTAGENESIS_DESCRIPTION            VARCHAR2(1000)                                NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ALLELECOMPLEMENTATION (
    ALLELE_COMPLEMENTATION_ID          NUMBER(10)                                    NOT NULL,
    ALLELE_ID                          NUMBER(10)                                    NOT NULL,
    COMPLEMENTATION_ID                 NUMBER(10)                                    NOT NULL,
    TYPE                               VARCHAR2(40)                                  NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ALLELEINSTANCE (
    ALLELE_INSTANCE_ID                 NUMBER(10)                                    NOT NULL,
    ALLELE_ID                          NUMBER(10)                                    NOT NULL,
    NA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ALLELEPHENOTYPE (
    ALLELE_PHENOTYPE_ID                NUMBER(10)                                    NOT NULL,
    ALLELE_ID                          NUMBER(10)                                    NOT NULL,
    PHENOTYPE_ID                       NUMBER(10)                                    NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ALLELEPHENOTYPECLASS (
    ALLELE_PHENOTYPE_CLASS_ID          NUMBER(10)                                    NOT NULL,
    ALLELE_ID                          NUMBER(10)                                    NOT NULL,
    PHENOTYPE_CLASS_ID                 NUMBER(10)                                    NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ANATOMYLIBRARY (
    ANATOMY_LIBRARY_ID                 NUMBER(10)                                    NOT NULL,
    ANATOMY_ID                         NUMBER(4)                                     NOT NULL,
    DBEST_LIBRARY_ID                   NUMBER(12)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ANATOMYLOE (
    ANATOMY_LOE_ID                     NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(255)                                 NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ASSEMBLYANATOMYPERCENT (
    ASSEMBLY_ANATOMY_PERCENT_ID        NUMBER(10)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    TAXON_ID                           NUMBER(12)                                    NULL,
    ANATOMY_ID                         NUMBER(4)                                     NOT NULL,
    PERCENT                            FLOAT(126)                                    NOT NULL,
    ANATOMY_ESTS                       NUMBER(5)                                     NOT NULL,
    EST_COUNT                          NUMBER(5)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ASSEMBLYSEQUENCE (
    ASSEMBLY_SEQUENCE_ID               NUMBER(10)                                    NOT NULL,
    ASSEMBLY_NA_SEQUENCE_ID            NUMBER(10)                                    NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    SEQUENCE_START                     NUMBER(12)                                    NOT NULL,
    SEQUENCE_END                       NUMBER(12)                                    NOT NULL,
    QUALITY_START                      NUMBER(12)                                    NULL,
    QUALITY_END                        NUMBER(12)                                    NULL,
    ASSEMBLY_OFFSET                    NUMBER(12)                                    NOT NULL,
    ASSEMBLY_STRAND                    NUMBER(1)                                     NOT NULL,
    GAPPED_SEQUENCE                    CLOB                                          NULL,
    HAVE_PROCESSED                     NUMBER(1)                                     NOT NULL,
    PROCESSED_CATEGORY                 VARCHAR2(50)                                  NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ASSEMBLYSEQUENCESNP (
    ASSEMBLY_SEQUENCE_SNP_ID           NUMBER(10)                                    NOT NULL,
    ASSEMBLY_SEQUENCE_ID               NUMBER(10)                                    NOT NULL,
    ASSEMBLY_SNP_ID                    NUMBER(10)                                    NOT NULL,
    GAPPED_LOCATION                    NUMBER(8)                                     NOT NULL,
    NA_SEQUENCE_LOCATION               NUMBER(8)                                     NULL,
    SEQUENCE_CHARACTER                 CHAR(1)                                       NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ASSEMBLYSNP (
    ASSEMBLY_SNP_ID                    NUMBER(10)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    NUM_A                              NUMBER(8)                                     NOT NULL,
    NUM_C                              NUMBER(8)                                     NOT NULL,
    NUM_G                              NUMBER(8)                                     NOT NULL,
    NUM_T                              NUMBER(8)                                     NOT NULL,
    NUM_OTHER                          NUMBER(8)                                     NOT NULL,
    NUC_1                              CHAR(1)                                       NOT NULL,
    NUC_2                              CHAR(1)                                       NULL,
    NUC_3                              CHAR(1)                                       NULL,
    NUC_4                              CHAR(1)                                       NULL,
    NUM_NUC_1                          NUMBER(8)                                     NOT NULL,
    NUM_NUC_2                          NUMBER(8)                                     NULL,
    NUM_NUC_3                          NUMBER(8)                                     NULL,
    NUM_NUC_4                          NUMBER(8)                                     NULL,
    FRACTION_NUC_1                     FLOAT(22)                                     NOT NULL,
    NUM_DISTINCT_ACGT                  NUMBER(1)                                     NOT NULL,
    ASSEMBLY_DEPTH                     NUMBER(5)                                     NOT NULL,
    ASSEMBLY_POSITION                  NUMBER(8)                                     NOT NULL,
    CONSENSUS_POSITION                 NUMBER(8)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ATTRIBUTION (
    ATTRIBUTION_ID                     NUMBER(10)                                    NOT NULL,
    TABLE_ID                           NUMBER(10)                                    NOT NULL,
    ROW_ID                             NUMBER(10)                                    NOT NULL,
    CONTACT_ID                         NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.BESTSIMILARITYPAIR (
    BEST_SIMILARITY_PAIR_ID            NUMBER                                        NOT NULL,
    SEQUENCE_ID                        NUMBER                                        NOT NULL,
    PAIRED_SEQUENCE_ID                 NUMBER                                        NOT NULL,
    SOURCE_TABLE_ID                    NUMBER                                        NULL,
    PAIRED_SOURCE_TABLE_ID             NUMBER                                        NULL,
    PVALUE_EXP                         NUMBER                                        NULL,
    PVALUE_MANT                        FLOAT(63)                                     NULL,
    SCORE                              FLOAT(63)                                     NULL,
    PERCENT_IDENTITY                   FLOAT(63)                                     NULL,
    PERCENT_MATCH                      FLOAT(63)                                     NULL,
    ORTHOLOG_EXPERIMENT_ID             NUMBER                                        NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.BLATALIGNMENT (
    BLAT_ALIGNMENT_ID                  NUMBER(10)                                    NOT NULL,
    QUERY_NA_SEQUENCE_ID               NUMBER(10)                                    NOT NULL,
    TARGET_NA_SEQUENCE_ID              NUMBER(10)                                    NOT NULL,
    QUERY_TABLE_ID                     NUMBER(5)                                     NULL,
    QUERY_TAXON_ID                     NUMBER(10)                                    NULL,
    QUERY_EXTERNAL_DB_RELEASE_ID       NUMBER(10)                                    NULL,
    TARGET_TABLE_ID                    NUMBER(5)                                     NULL,
    TARGET_TAXON_ID                    NUMBER(10)                                    NULL,
    TARGET_EXTERNAL_DB_RELEASE_ID      NUMBER(10)                                    NULL,
    IS_CONSISTENT                      NUMBER(1)                                     NOT NULL,
    IS_GENOMIC_CONTAMINANT             NUMBER(1)                                     NOT NULL,
    UNALIGNED_3P_BASES                 NUMBER(12)                                    NOT NULL,
    UNALIGNED_5P_BASES                 NUMBER(12)                                    NOT NULL,
    HAS_3P_POLYA                       NUMBER(1)                                     NOT NULL,
    HAS_5P_POLYA                       NUMBER(1)                                     NOT NULL,
    IS_3P_COMPLETE                     NUMBER(1)                                     NOT NULL,
    IS_5P_COMPLETE                     NUMBER(1)                                     NOT NULL,
    PERCENT_IDENTITY                   NUMBER(3)                                     NOT NULL,
    MAX_QUERY_GAP                      NUMBER(12)                                    NOT NULL,
    MAX_TARGET_GAP                     NUMBER(12)                                    NOT NULL,
    NUMBER_OF_SPANS                    NUMBER(5)                                     NOT NULL,
    QUERY_START                        NUMBER(12)                                    NOT NULL,
    QUERY_END                          NUMBER(12)                                    NOT NULL,
    TARGET_START                       NUMBER(12)                                    NOT NULL,
    TARGET_END                         NUMBER(12)                                    NOT NULL,
    IS_REVERSED                        NUMBER(1)                                     NOT NULL,
    QUERY_BASES_ALIGNED                NUMBER(12)                                    NOT NULL,
    REPEAT_BASES_ALIGNED               NUMBER(12)                                    NOT NULL,
    NUM_NS                             NUMBER(12)                                    NOT NULL,
    SCORE                              FLOAT(126)                                    NOT NULL,
    IS_BEST_ALIGNMENT                  NUMBER(1)                                     DEFAULT 0       NOT NULL,
    BLAT_ALIGNMENT_QUALITY_ID          NUMBER(5)                                     NOT NULL,
    BLOCKSIZES                         VARCHAR2(4000)                                NOT NULL,
    QSTARTS                            VARCHAR2(4000)                                NOT NULL,
    TSTARTS                            VARCHAR2(4000)                                NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.BLATALIGNMENTQUALITY (
    BLAT_ALIGNMENT_QUALITY_ID          NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(30)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(4000)                                NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.CLONE (
    CLONE_ID                           NUMBER(10)                                    NOT NULL,
    LIBRARY_ID                         NUMBER(5)                                     NOT NULL,
    IMAGE_ID                           NUMBER(12)                                    NULL,
    DBEST_CLONE_UID                    VARCHAR2(35)                                  NULL,
    WASHU_NAME                         VARCHAR2(12)                                  NULL,
    GDB_ID                             NUMBER(12)                                    NULL,
    MGI_ID                             NUMBER(12)                                    NULL,
    DBEST_LENGTH                       NUMBER(12)                                    NULL,
    WASHU_LENGTH                       NUMBER(12)                                    NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.CLONEINSET (
    CLONE_IN_SET_ID                    NUMBER(10)                                    NOT NULL,
    CLONE_ID                           NUMBER(10)                                    NOT NULL,
    CLONE_SET_ID                       NUMBER(12)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.CLONESET (
    CLONE_SET_ID                       NUMBER(12)                                    NOT NULL,
    CONTACT_ID                         NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(20)                                  NOT NULL,
    EXTERNAL_NAME                      VARCHAR2(30)                                  NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
    CBIL_NAME                          VARCHAR2(36)                                  NULL,
    DATE_IN                            DATE                                          NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.COMMENTNAME (
    COMMENT_NAME_ID                    NUMBER(4)                                     NOT NULL,
    NAME                               VARCHAR2(20)                                  NOT NULL,
    C_CATEGORY                         VARCHAR2(20)                                  NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.COMMENTS (
    COMMENTS_ID                        NUMBER(10)                                    NOT NULL,
    COMMENT_STRING                     CLOB                                          NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.COMPLEMENTATION (
    COMPLEMENTATION_ID                 NUMBER(10)                                    NOT NULL,
    IS_EXTERNAL_REFERENCE              NUMBER(1)                                     NOT NULL,
    ENTITY_NAME                        VARCHAR2(100)                                 NOT NULL,
    TABLE_ID                           NUMBER(10)                                    NULL,
    ENTRY_ID                           NUMBER(10)                                    NULL,
    TAXON_ID                           NUMBER(10)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.COMPLEX (
    COMPLEX_ID                         NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(80)                                  NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
    COMPLEX_TYPE_ID                    NUMBER(10)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    REVIEW_STATUS_ID                   NUMBER(1)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.COMPLEXANATOMY (
    COMPLEX_ANATOMY_ID                 NUMBER(10)                                    NOT NULL,
    COMPLEX_ID                         NUMBER(10)                                    NOT NULL,
    ANATOMY_ID                         NUMBER(4)                                     NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.COMPLEXCOMPONENT (
    COMPLEX_COMPONENT_ID               NUMBER(10)                                    NOT NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    ROW_ID                             NUMBER(10)                                    NOT NULL,
    COMPLEX_ID                         NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.COMPLEXTYPE (
    COMPLEX_TYPE_ID                    NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.CONSISTENTALIGNMENT (
    CONSISTENT_ALIGNMENT_ID            NUMBER(10)                                    NOT NULL,
    SIMILARITY_ID                      NUMBER(10)                                    NOT NULL,
    GENOMIC_NA_SEQUENCE_ID             NUMBER(10)                                    NOT NULL,
    TRANSCRIPT_NA_SEQUENCE_ID          NUMBER(10)                                    NOT NULL,
    IS_3P_COMPLETE                     NUMBER(1)                                     NOT NULL,
    IS_5P_COMPLETE                     NUMBER(1)                                     NOT NULL,
    IS_CONSISTENT                      NUMBER(1)                                     NOT NULL,
    IS_GENOMIC_CONTAMINANT             NUMBER(1)                                     NOT NULL,
    MIN_SPAN_IDENTITY                  NUMBER(3)                                     NOT NULL,
    AVG_IDENTITY                       NUMBER(3)                                     NOT NULL,
    MAX_QUERY_GAP                      NUMBER(12)                                    NOT NULL,
    DOTS_BASES_ALIGNED                 NUMBER(12)                                    NOT NULL,
    NUMBER_OF_SPANS                    NUMBER(5)                                     NOT NULL,
    DOTS_START                         NUMBER(12)                                    NOT NULL,
    DOTS_END                           NUMBER(12)                                    NOT NULL,
    GENOMIC_START                      NUMBER(12)                                    NOT NULL,
    GENOMIC_END                        NUMBER(12)                                    NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.DBREFNAFEATURE (
    DB_REF_NA_FEATURE_ID               NUMBER(10)                                    NOT NULL,
    NA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
    DB_REF_ID                          NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.DBREFNASEQUENCE (
    DB_REF_NA_SEQUENCE_ID              NUMBER(10)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    DB_REF_ID                          NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.DBREFPFAMENTRY (
    DB_REF_PFAM_ENTRY_ID               NUMBER(10)                                    NOT NULL,
    PFAM_ENTRY_ID                      NUMBER(10)                                    NOT NULL,
    DB_REF_ID                          NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.EFFECTORACTIONTYPE (
    EFFECTOR_ACTION_TYPE_ID            NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ENDSEQUENCEPAIRMAP (
    END_SEQUENCE_PAIR_MAP_ID           NUMBER(12)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NOT NULL,
    SOURCE_ID                          VARCHAR2(16)                                  NOT NULL,
    SECONDARY_ID                       VARCHAR2(300)                                 NULL,
    DESCRIPTION                        VARCHAR2(300)                                 NULL,
    TAXON_ID                           NUMBER(12)                                    NULL,
    NA_SEQUENCE_ID_1                   NUMBER(12)                                    NOT NULL,
    NA_SEQUENCE_ID_2                   NUMBER(12)                                    NOT NULL,
    MIN_PRODUCT_LENGTH                 NUMBER                                        NULL,
    MAX_PRODUCT_LENGTH                 NUMBER                                        NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.EPCR (
    EPCR_ID                            NUMBER(12)                                    NOT NULL,
    MAP_TABLE_ID                       NUMBER(5)                                     NOT NULL,
    MAP_ID                             NUMBER(12)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    SEQ_SUBCLASS_VIEW                  VARCHAR2(30)                                  NOT NULL,
    START_POS                          NUMBER(12)                                    NOT NULL,
    STOP_POS                           NUMBER(12)                                    NOT NULL,
    IS_REVERSED                        NUMBER(1)                                     NULL,
    SIMILARITY_ID_1                    NUMBER(12)                                    NULL,
    SIMILARITY_ID_2                    NUMBER(12)                                    NULL,
    SCORE                              FLOAT(126)                                    NULL,
    NUM_MISMATCHES                     NUMBER(1)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.EST (
    EST_ID                             NUMBER(10)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    CLONE_ID                           NUMBER(10)                                    NULL,
    LIBRARY_ID                         NUMBER(5)                                     NOT NULL,
    CONTACT_ID                         NUMBER(12)                                    NOT NULL,
    DBEST_ID_EST                       NUMBER(12)                                    NULL,
    WASHU_ID                           CHAR(15)                                      NULL,
    ACCESSION                          VARCHAR2(20)                                  NULL,
    P_END                              CHAR(1)                                       NULL,
    QUALITY_START                      NUMBER(12)                                    NOT NULL,
    QUALITY_STOP                       NUMBER(12)                                    NULL,
    SEQ_LENGTH                         NUMBER(12)                                    NULL,
    SEQ_PRIMER                         VARCHAR2(128)                                 NULL,
    POSSIBLY_REVERSED                  NUMBER(1)                                     NOT NULL,
    PUTATIVE_FULL_LENGTH_READ          NUMBER(1)                                     NOT NULL,
    TRACE_POOR_QUALITY                 NUMBER(1)                                     NOT NULL,
    POLYA_SIGNAL                       NUMBER(1)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.EVIDENCE (
    EVIDENCE_ID                        NUMBER(10)                                    NOT NULL,
    TARGET_TABLE_ID                    NUMBER(5)                                     NOT NULL,
    TARGET_ID                          NUMBER(10)                                    NOT NULL,
    FACT_TABLE_ID                      NUMBER(5)                                     NOT NULL,
    FACT_ID                            NUMBER(10)                                    NOT NULL,
    ATTRIBUTE_NAME                     VARCHAR2(30)                                  NULL,
    EVIDENCE_GROUP_ID                  NUMBER(12)                                    NOT NULL,
    BEST_EVIDENCE                      NUMBER(1)                                     DEFAULT 0  NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.EXONLOCATION (
    EXON_LOCATION_ID                   NUMBER(10)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NULL,
    START_MIN                          NUMBER(12)                                    NULL,
    START_MAX                          NUMBER(12)                                    NULL,
    END_MIN                            NUMBER(12)                                    NULL,
    END_MAX                            NUMBER(12)                                    NULL,
    ORDER_NUM                          NUMBER(5)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.FAMILY (
    FAMILY_ID                          NUMBER(10)                                    NOT NULL,
    PARENT_FAMILY_ID                   NUMBER(10)                                    NOT NULL,
    HIERARCHY                          NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    TYPE                               VARCHAR2(10)                                  NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.FAMILYGENE (
    FAMILY_GENE_ID                     NUMBER(10)                                    NOT NULL,
    FAMILY_ID                          NUMBER(10)                                    NOT NULL,
    GENE_ID                            NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.FAMILYPROTEIN (
    FAMILY_PROTEIN_ID                  NUMBER(10)                                    NOT NULL,
    PROTEIN_ID                         NUMBER(10)                                    NOT NULL,
    FAMILY_ID                          NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.FEATURENAME (
    FEATURE_NAME_ID                    NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(30)                                  NOT NULL,
    FEATURE_CATEGORY                   VARCHAR2(30)                                  NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.FINGERPRINTCLONE (
    FINGERPRINT_CLONE_ID               NUMBER(12)                                    NOT NULL,
    SOURCE_ID                          VARCHAR2(30)                                  NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NOT NULL,
    IS_SEQUENCED                       VARCHAR2(1)                                   NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.FINGERPRINTCLONECONTIG (
    FINGERPRINT_CLONE_CONTIG_ID        NUMBER(12)                                    NOT NULL,
    FINGERPRINT_CLONE_ID               NUMBER(12)                                    NOT NULL,
    FINGERPRINT_CONTIG_ID              NUMBER(12)                                    NOT NULL,
    CLONE_ORDER_NUM                    NUMBER(8)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.FINGERPRINTCLONEMARKER (
    FINGERPRINT_CLONE_MARKER_ID        NUMBER(12)                                    NOT NULL,
    FINGERPRINT_MAP_ID                 NUMBER(12)                                    NOT NULL,
    FINGERPRINT_CLONE_ID               NUMBER(12)                                    NOT NULL,
    MARKER_TYPE                        VARCHAR2(30)                                  NULL,
    SOURCE_ID                          VARCHAR2(30)                                  NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.FINGERPRINTCONTIG (
    FINGERPRINT_CONTIG_ID              NUMBER(12)                                    NOT NULL,
    FINGERPRINT_MAP_ID                 NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(30)                                  NOT NULL,
    NUMBER_OF_CLONES                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.FINGERPRINTMAP (
    FINGERPRINT_MAP_ID                 NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
    MAP_VERSION                        VARCHAR2(30)                                  NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NOT NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    NUMBER_OF_CLONES                   NUMBER(10)                                    NULL,
    NUMBER_OF_CONTIGS                  NUMBER(10)                                    NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENE (
    GENE_ID                            NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(255)                                 NULL,
    GENE_SYMBOL                        VARCHAR2(50)                                  NULL,
    GENE_CATEGORY_ID                   NUMBER(10)                                    NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NULL,
    REVIEWER_SUMMARY                   VARCHAR2(4000)                                NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENEALIAS (
    GENE_ALIAS_ID                      NUMBER(10)                                    NOT NULL,
    GENE_ID                            NUMBER(10)                                    NULL,
    GENE_ALIAS_NAME                    VARCHAR2(255)                                 NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENECATEGORY (
    GENE_CATEGORY_ID                   NUMBER(10)                                    NOT NULL,
    TERM                               VARCHAR2(80)                                  NOT NULL,
    DEFINITION                         VARCHAR2(255)                                 NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENECHROMOSOMALLOCATION (
    GENE_CHROMOSOMAL_LOCATION_ID       NUMBER(10)                                    NOT NULL,
    GENE_ID                            NUMBER(10)                                    NOT NULL,
    CHROMOSOME                         NUMBER(5)                                     NOT NULL,
    CYTOGENETIC                        VARCHAR2(50)                                  NULL,
    METHOD                             VARCHAR2(255)                                 NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENEFAMILY (
    GENE_FAMILY_ID                     NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(40)                                  NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENEFAMILYRELATION (
    GENE_FAMILY_RELATION_ID            NUMBER(10)                                    NOT NULL,
    GENE_FAMILY_ID                     NUMBER(10)                                    NOT NULL,
    GENE_ID                            NUMBER(10)                                    NOT NULL,
    CONFIDENCE                         NUMBER(3)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENEFEATURESAGETAGLINK (
    GENE_FEATURE_SAGE_TAG_LINK_ID      NUMBER(12)                                    NOT NULL,
    GENOMIC_NA_SEQUENCE_ID             NUMBER(12)                                    NOT NULL,
    GENE_NA_FEATURE_ID                 NUMBER(12)                                    NOT NULL,
    TAG_NA_FEATURE_ID                  NUMBER(12)                                    NOT NULL,
    FIVE_PRIME_TAG_OFFSET              NUMBER(12)                                    NOT NULL,
    THREE_PRIME_TAG_OFFSET             NUMBER(12)                                    NOT NULL,
    SAME_STRAND                        NUMBER(1)                                     NOT NULL,
    EXPERIMENTALLY_VERIFIED            NUMBER(1)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENEFEATURESEQOVERLAP (
    GENE_FEATURE_SEQ_OVERLAP_ID        NUMBER(12)                                    NOT NULL,
    GENE_NA_FEATURE_ID                 NUMBER(12)                                    NOT NULL,
    GENOMIC_NA_SEQUENCE_ID             NUMBER(12)                                    NOT NULL,
    SEQ_NA_SEQUENCE_ID                 NUMBER(12)                                    NULL,
    END_SEQUENCE_PAIR_MAP_ID           NUMBER(12)                                    NULL,
    EPCR_ID                            NUMBER(12)                                    NULL,
    SIMILARITY_ID                      NUMBER(10)                                    NULL,
    BLAT_ALIGNMENT_ID                  NUMBER(12)                                    NULL,
    GENE_OVERLAP                       NUMBER(12)                                    NOT NULL,
    GENE_CODING_OVERLAP                NUMBER(12)                                    NOT NULL,
    GENE_LENGTH                        NUMBER(12)                                    NOT NULL,
    GENE_CODING_LENGTH                 NUMBER(12)                                    NOT NULL,
    SEQUENCE_LENGTH                    NUMBER(12)                                    NOT NULL,
    GENE_NUM_EXONS                     NUMBER(12)                                    NOT NULL,
    GENE_NUM_EXONS_HIT                 NUMBER(12)                                    NOT NULL,
    GENE_PERCENT_COVERED               FLOAT(22)                                     NOT NULL,
    GENE_PERCENT_CODING_COVERED        FLOAT(22)                                     NOT NULL,
    SEQUENCE_PERCENT_COVERED           FLOAT(22)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENEINSTANCE (
    GENE_INSTANCE_ID                   NUMBER(10)                                    NOT NULL,
    GENE_INSTANCE_CATEGORY_ID          NUMBER(3)                                     NOT NULL,
    GENE_ID                            NUMBER(10)                                    NOT NULL,
    NA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
    REVIEWER_SUMMARY                   VARCHAR2(4000)                                NULL,
    IS_REFERENCE                       NUMBER(1)                                     NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENEINSTANCECATEGORY (
    GENE_INSTANCE_CATEGORY_ID          NUMBER(3)                                     NOT NULL,
    NAME                               VARCHAR2(40)                                  NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENESUPERFAMILY (
    GENE_SUPER_FAMILY_ID               NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(40)                                  NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENESUPERFAMILYRELATION (
    GENE_SUPERFAMILY_RELATION_ID       NUMBER(10)                                    NOT NULL,
    GENE_SUPER_FAMILY_ID               NUMBER(10)                                    NOT NULL,
    GENE_FAMILY_ID                     NUMBER(10)                                    NOT NULL,
    CONFIDENCE                         NUMBER(3)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENESYNONYM (
    GENE_SYNONYM_ID                    NUMBER(10)                                    NOT NULL,
    GENE_ID                            NUMBER(10)                                    NOT NULL,
    SYNONYM_NAME                       VARCHAR2(30)                                  NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
    IS_OBSOLETE                        NUMBER(1)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GENETRAPASSEMBLY (
    GENE_TRAP_ASSEMBLY_ID              NUMBER(10)                                    NOT NULL,
    TAG_NA_SEQUENCE_ID                 NUMBER(10)                                    NOT NULL,
    ASSEMBLY_NA_SEQUENCE_ID            NUMBER(10)                                    NOT NULL,
    IS_BEST_MATCH                      NUMBER(1)                                     NOT NULL,
    MATCH_START                        NUMBER(10)                                    NOT NULL,
    MATCH_END                          NUMBER(10)                                    NOT NULL,
    IS_REVERSED                        NUMBER(1)                                     NOT NULL,
    PERCENT_IDENTITY                   FLOAT(63)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GOASSOCIATION (
    GO_ASSOCIATION_ID                  NUMBER(10)                                    NOT NULL,
    TABLE_ID                           NUMBER(10)                                    NOT NULL,
    ROW_ID                             NUMBER(10)                                    NOT NULL,
    GO_TERM_ID                         NUMBER(10)                                    NOT NULL,
    IS_NOT                             NUMBER(1)                                     NULL,
    DEFINING                           NUMBER(1)                                     NOT NULL,
    GO_ASSOCIATION_DATE                DATE                                          NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GOASSOCIATIONINSTANCE (
    GO_ASSOCIATION_INSTANCE_ID         NUMBER(10)                                    NOT NULL,
    GO_ASSOCIATION_ID                  NUMBER(10)                                    NOT NULL,
    GO_ASSOC_INST_LOE_ID               NUMBER(5)                                     NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    IS_NOT                             NUMBER(1)                                     NULL,
    DEFINING                           NUMBER(1)                                     NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
    P_VALUE_RATIO                      FLOAT(126)                                    NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GOASSOCIATIONINSTANCELOE (
    GO_ASSOC_INST_LOE_ID               NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.GOASSOCINSTEVIDCODE (
    GO_ASSOC_INST_EVID_CODE_ID         NUMBER(10)                                    NOT NULL,
    GO_EVIDENCE_CODE_ID                NUMBER(3)                                     NOT NULL,
    GO_ASSOCIATION_INSTANCE_ID         NUMBER(10)                                    NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.INDEXWORD (
    INDEX_WORD_ID                      NUMBER(10)                                    NOT NULL,
    WORD                               VARCHAR2(255)                                 NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.INDEXWORDLINK (
    INDEX_WORD_LINK_ID                 NUMBER(10)                                    NOT NULL,
    INDEX_WORD_ID                      NUMBER(10)                                    NOT NULL,
    TARGET_TABLE_ID                    NUMBER(5)                                     NOT NULL,
    TARGET_ID                          NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.INDEXWORDSIMLINK (
    INDEX_WORD_SIM_LINK_ID             NUMBER(10)                                    NOT NULL,
    TARGET_TABLE_ID                    NUMBER(5)                                     NOT NULL,
    TARGET_ID                          NUMBER(10)                                    NOT NULL,
    SIMILARITY_TABLE_ID                NUMBER(5)                                     NOT NULL,
    INDEX_WORD_ID                      NUMBER(10)                                    NOT NULL,
    BEST_SIMILARITY_ID                 NUMBER(10)                                    NOT NULL,
    BEST_P_VALUE_MANT                  FLOAT(126)                                    NOT NULL,
    BEST_P_VALUE_EXP                   NUMBER(6)                                     NOT NULL,
    BEST_SCORE                         NUMBER(12)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.INTERACTION (
    INTERACTION_ID                     NUMBER(10)                                    NOT NULL,
    INTERACTION_TYPE_ID                NUMBER(5)                                     NOT NULL,
    EFFECTOR_ACTION_TYPE_ID            NUMBER(5)                                     NOT NULL,
    EFFECTOR_ROW_SET_ID                NUMBER(10)                                    NOT NULL,
    TARGET_ROW_SET_ID                  NUMBER(10)                                    NOT NULL,
    HAS_DIRECTION                      NUMBER(1)                                     NOT NULL,
    DIRECTION_IS_KNOWN                 NUMBER(1)                                     NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.INTERACTIONINTERACTIONLOE (
    INTERACTION_INTERACTION_LOE_ID     NUMBER(10)                                    NOT NULL,
    INTERACTION_ID                     NUMBER(10)                                    NOT NULL,
    INTERACTION_LOE_ID                 NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.INTERACTIONLOE (
    INTERACTION_LOE_ID                 NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.INTERACTIONTYPE (
    INTERACTION_TYPE_ID                NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ISEXPRESSED (
    IS_EXPRESSED_ID                    NUMBER(10)                                    NOT NULL,
    ANATOMY_ID                         NUMBER(4)                                     NOT NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    ROW_ID                             NUMBER(10)                                    NOT NULL,
    IS_CONFIRMED                       NUMBER(1)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.KEYWORD (
    KEYWORD_ID                         NUMBER(6)                                     NOT NULL,
    KEYWORD                            VARCHAR2(80)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
    PREFERRED_KEYWORD_ID               NUMBER(6)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.LIBRARY (
    LIBRARY_ID                         NUMBER(5)                                     NOT NULL,
    TAXON_ID                           NUMBER(12)                                    NOT NULL,
    ANATOMY_ID                         NUMBER(4)                                     NULL,
    DBEST_ID                           NUMBER(12)                                    NULL,
    DBEST_NAME                         VARCHAR2(120)                                 NULL,
    IS_IMAGE                           NUMBER(1)                                     NOT NULL,
    IMAGE_ID                           NUMBER(12)                                    NULL,
    GDB_ID                             NUMBER(12)                                    NULL,
    GDB_NAME                           VARCHAR2(100)                                 NULL,
    LLNL_NAME                          VARCHAR2(100)                                 NULL,
    WASHU_NAME                         VARCHAR2(100)                                 NULL,
    TISSUE_TYPE                        VARCHAR2(100)                                 NULL,
    STRAIN                             VARCHAR2(50)                                  NULL,
    CULTIVAR                           VARCHAR2(25)                                  NULL,
    STAGE                              VARCHAR2(100)                                 NULL,
    SEX                                CHAR(1)                                       NULL,
    CELL_TYPE                          VARCHAR2(70)                                  NULL,
    CELL_LINE                          VARCHAR2(70)                                  NULL,
    NORMALIZED                         CHAR(1)                                       NULL,
    VECTOR                             VARCHAR2(70)                                  NULL,
    VECTOR_TYPE                        VARCHAR2(35)                                  NULL,
    HOST                               VARCHAR2(80)                                  NULL,
    RE_1                               VARCHAR2(35)                                  NULL,
    RE_2                               VARCHAR2(35)                                  NULL,
    COMMENT_STRING                     CLOB                                          NULL,
    DBEST_ORGANISM                     VARCHAR2(300)                                 NULL,
    DBEST_ORGAN                        VARCHAR2(300)                                 NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.MERGESPLIT (
    MERGE_SPLIT_ID                     NUMBER(10)                                    NOT NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    OLD_ID                             NUMBER(10)                                    NOT NULL,
    NEW_ID                             NUMBER(10)                                    NOT NULL,
    MERGE_SPLIT_GROUP_ID               NUMBER(12)                                    NOT NULL,
    IS_MERGE                           NUMBER(1)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.MOTIF (
    MOTIF_ID                           NUMBER(10)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NULL,
    SOURCE_ID                          VARCHAR2(15)                                  NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
    MOTIF                              VARCHAR2(255)                                 NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NOT NULL,
    PROBABILITY                        FLOAT(126)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NACOMMENT (
    NA_COMMENT_ID                      NUMBER(10)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    COMMENT_STRING                     CLOB                                          NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NAENTRY (
    NA_ENTRY_ID                        NUMBER(10)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    SOURCE_ID                          VARCHAR2(15)                                  NOT NULL,
    STATUS                             VARCHAR2(12)                                  NULL,
    DIVISION                           VARCHAR2(15)                                  NULL,
    VERSION                            NUMBER(12)                                    NULL,
    NID                                VARCHAR2(15)                                  NULL,
    CREATED_DATE                       DATE                                          NULL,
    CREATED_REL_VER                    NUMBER(5)                                     NULL,
    UPDATE_DATE                        DATE                                          NULL,
    UPDATE_REL_VER                     NUMBER(5)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NAFEATRELATIONSHIPTYPE (
    NA_FEAT_RELATIONSHIP_TYPE_ID       NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(255)                                 NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NAFEATURECOMMENT (
    NA_FEATURE_COMMENT_ID              NUMBER(10)                                    NOT NULL,
    NA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
    COMMENT_STRING                     CLOB                                          NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NAFEATUREIMP (
    NA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NULL,
    SUBCLASS_VIEW                      VARCHAR2(30)                                  NULL,
    NAME                               VARCHAR2(30)                                  NOT NULL,
    SEQUENCE_ONTOLOGY_ID               NUMBER(10)                                    NULL,
    PARENT_ID                          NUMBER(10)                                    NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NULL,
    SOURCE_ID                          VARCHAR2(50)                                  NULL,
    PREDICTION_ALGORITHM_ID            NUMBER(5)                                     NULL,
    IS_PREDICTED                       NUMBER(1)                                     NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NULL,
    INT1                               NUMBER(12)                                    NULL,
    INT2                               NUMBER(12)                                    NULL,
    INT3                               NUMBER(12)                                    NULL,
    INT4                               NUMBER(12)                                    NULL,
    INT5                               NUMBER(12)                                    NULL,
    INT6                               NUMBER(12)                                    NULL,
    TINYINT1                           NUMBER(3)                                     NULL,
    TINYINT2                           NUMBER(3)                                     NULL,
    TINYINT3                           NUMBER(3)                                     NULL,
    TINYINT4                           NUMBER(3)                                     NULL,
    TINYINT5                           NUMBER(3)                                     NULL,
    TINYINT6                           NUMBER(3)                                     NULL,
    FLOAT1                             FLOAT(126)                                    NULL,
    FLOAT2                             FLOAT(126)                                    NULL,
    FLOAT3                             FLOAT(126)                                    NULL,
    FLOAT4                             FLOAT(126)                                    NULL,
    FLOAT5                             FLOAT(126)                                    NULL,
    FLOAT6                             FLOAT(126)                                    NULL,
    TEXT1                              CLOB                                          NULL,
    STRING1                            VARCHAR2(1000)                                NULL,
    STRING2                            VARCHAR2(255)                                 NULL,
    STRING3                            VARCHAR2(255)                                 NULL,
    STRING4                            VARCHAR2(255)                                 NULL,
    STRING5                            VARCHAR2(2000)                                NULL,
    STRING6                            VARCHAR2(255)                                 NULL,
    STRING7                            VARCHAR2(255)                                 NULL,
    STRING8                            VARCHAR2(255)                                 NULL,
    STRING9                            VARCHAR2(1000)                                NULL,
    STRING10                           VARCHAR2(255)                                 NULL,
    STRING11                           VARCHAR2(255)                                 NULL,
    STRING12                           VARCHAR2(255)                                 NULL,
    STRING13                           VARCHAR2(1000)                                NULL,
    STRING14                           VARCHAR2(500)                                 NULL,
    STRING15                           VARCHAR2(255)                                 NULL,
    STRING16                           VARCHAR2(255)                                 NULL,
    STRING17                           VARCHAR2(255)                                 NULL,
    STRING18                           VARCHAR2(255)                                 NULL,
    STRING19                           VARCHAR2(255)                                 NULL,
    STRING20                           VARCHAR2(4000)                                NULL,
    STRING21                           VARCHAR2(255)                                 NULL,
    STRING22                           VARCHAR2(255)                                 NULL,
    STRING23                           VARCHAR2(255)                                 NULL,
    STRING24                           VARCHAR2(255)                                 NULL,
    STRING25                           VARCHAR2(255)                                 NULL,
    STRING26                           VARCHAR2(255)                                 NULL,
    STRING27                           VARCHAR2(255)                                 NULL,
    STRING28                           VARCHAR2(255)                                 NULL,
    STRING29                           VARCHAR2(255)                                 NULL,
    STRING30                           VARCHAR2(255)                                 NULL,
    STRING31                           VARCHAR2(255)                                 NULL,
    STRING32                           VARCHAR2(255)                                 NULL,
    STRING33                           VARCHAR2(255)                                 NULL,
    STRING34                           VARCHAR2(255)                                 NULL,
    STRING35                           VARCHAR2(255)                                 NULL,
    STRING36                           VARCHAR2(255)                                 NULL,
    STRING37                           VARCHAR2(255)                                 NULL,
    STRING38                           VARCHAR2(255)                                 NULL,
    STRING39                           VARCHAR2(255)                                 NULL,
    STRING40                           VARCHAR2(255)                                 NULL,
    STRING41                           VARCHAR2(255)                                 NULL,
    STRING42                           VARCHAR2(255)                                 NULL,
    STRING43                           VARCHAR2(255)                                 NULL,
    STRING44                           VARCHAR2(255)                                 NULL,
    STRING45                           VARCHAR2(255)                                 NULL,
    STRING46                           VARCHAR2(255)                                 NULL,
    STRING47                           VARCHAR2(255)                                 NULL,
    STRING48                           VARCHAR2(255)                                 NULL,
    STRING49                           VARCHAR2(255)                                 NULL,
    STRING50                           VARCHAR2(255)                                 NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NAFEATURENAGENE (
    NA_FEATURE_NA_GENE_ID              NUMBER(10)                                    NOT NULL,
    NA_GENE_ID                         NUMBER(10)                                    NOT NULL,
    NA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NAFEATURENAPROTEIN (
    NA_FEATURE_NA_PROTEIN_ID           NUMBER(10)                                    NOT NULL,
    NA_PROTEIN_ID                      NUMBER(10)                                    NOT NULL,
    NA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NAFEATURENAPT (
    NA_FEATURE_NA_PT_ID                NUMBER(10)                                    NOT NULL,
    NA_PRIMARY_TRANSCRIPT_ID           NUMBER(10)                                    NOT NULL,
    NA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NAFEATURERELATIONSHIP (
    NA_FEATURE_RELATIONSHIP_ID         NUMBER(10)                                    NOT NULL,
    PARENT_NA_FEATURE_ID               NUMBER(10)                                    NOT NULL,
    CHILD_NA_FEATURE_ID                NUMBER(10)                                    NOT NULL,
    NA_FEAT_RELATIONSHIP_TYPE_ID       NUMBER(10)                                    NOT NULL,
    ORDINAL                            NUMBER(10)                                    NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NAGENE (
    NA_GENE_ID                         NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(300)                                 NULL,
    IS_VERIFIED                        NUMBER(1)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NALOCATION (
    NA_LOCATION_ID                     NUMBER(10)                                    NOT NULL,
    NA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
    START_MIN                          NUMBER(12)                                    NULL,
    START_MAX                          NUMBER(12)                                    NULL,
    END_MIN                            NUMBER(12)                                    NULL,
    END_MAX                            NUMBER(12)                                    NULL,
    LOC_ORDER                          NUMBER(12)                                    NULL,
    IS_REVERSED                        NUMBER(3)                                     NULL,
    IS_EXCLUDED                        NUMBER(3)                                     NULL,
    DB_NAME                            VARCHAR2(100)                                 NULL,
    DB_IDENTIFIER                      VARCHAR2(25)                                  NULL,
    LITERAL_SEQUENCE                   VARCHAR2(255)                                 NULL,
    LOCATION_TYPE                      VARCHAR2(50)                                  NULL,
    REMARK                             VARCHAR2(255)                                 NULL,
    DEBUG_FIELD                        VARCHAR2(4000)                                NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NAPRIMARYTRANSCRIPT (
    NA_PRIMARY_TRANSCRIPT_ID           NUMBER(10)                                    NOT NULL,
    NA_GENE_ID                         NUMBER(10)                                    NULL,
    IS_VERIFIED                        NUMBER(1)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NAPROTEIN (
    NA_PROTEIN_ID                      NUMBER(10)                                    NOT NULL,
    NA_PRIMARY_TRANSCRIPT_ID           NUMBER(10)                                    NULL,
    NAME                               VARCHAR2(300)                                 NULL,
    IS_VERIFIED                        NUMBER(1)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NASEQCYTOLOCATION (
    NA_SEQ_CYTO_LOCATION_ID            NUMBER(10)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    CHROMOSOME                         CHAR(2)                                       NOT NULL,
    START_BAND                         VARCHAR2(8)                                   NOT NULL,
    END_BAND                           VARCHAR2(8)                                   NOT NULL,
    METHOD                             VARCHAR2(255)                                 NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NASEQUENCEIMP (
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    SEQUENCE_VERSION                   NUMBER(3)                                     DEFAULT 1     NOT NULL,
    SUBCLASS_VIEW                      VARCHAR2(30)                                  NOT NULL,
    SEQUENCE_TYPE_ID                   NUMBER(4)                                     NOT NULL,
    TAXON_ID                           NUMBER(12)                                    NULL,
    SEQUENCE                           CLOB                                          NULL,
    LENGTH                             NUMBER(12)                                    NULL,
    A_COUNT                            NUMBER(12)                                    NULL,
    C_COUNT                            NUMBER(12)                                    NULL,
    G_COUNT                            NUMBER(12)                                    NULL,
    T_COUNT                            NUMBER(12)                                    NULL,
    OTHER_COUNT                        NUMBER(12)                                    NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NULL,
    SOURCE_NA_SEQUENCE_ID              NUMBER(10)                                    NULL,
    SEQUENCE_PIECE_ID                  NUMBER(10)                                    NULL,
    SEQUENCING_CENTER_CONTACT_ID       NUMBER(10)                                    NULL,
    STRING1                            VARCHAR2(255)                                 NULL,
    STRING2                            VARCHAR2(255)                                 NULL,
    STRING3                            VARCHAR2(255)                                 NULL,
    STRING4                            VARCHAR2(255)                                 NULL,
    STRING5                            VARCHAR2(255)                                 NULL,
    TINYINT1                           NUMBER(3)                                     NULL,
    INT1                               NUMBER(12)                                    NULL,
    INT2                               NUMBER(12)                                    NULL,
    INT3                               NUMBER(12)                                    NULL,
    INT4                               NUMBER(12)                                    NULL,
    INT5                               NUMBER(12)                                    NULL,
    BIT1                               NUMBER(1)                                     NULL,
    CLOB1                              CLOB                                          NULL,
    CLOB2                              CLOB                                          NULL,
    CLOB3                              CLOB                                          NULL,
    CLOB4                              CLOB                                          NULL,
    DATE1                              DATE                                          NULL,
    DATE2                              DATE                                          NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NASEQUENCEKEYWORD (
    NA_SEQUENCE_KEYWORD_ID             NUMBER(10)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    KEYWORD_ID                         NUMBER(6)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NASEQUENCEORGANELLE (
    NA_SEQUENCE_ORGANELLE_ID           NUMBER(10)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    ORGANELLE_ID                       NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NASEQUENCEREF (
    NA_SEQUENCE_REF_ID                 NUMBER(10)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    REFERENCE_ID                       NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.NRDBENTRY (
    NRDB_ENTRY_ID                      NUMBER(10)                                    NOT NULL,
    AA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    GID                                VARCHAR2(255)                                 NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NOT NULL,
    SEQUENCE_VERSION                   NUMBER(3)                                     NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
    TAXON_ID                           NUMBER(12)                                    NULL,
    IS_PREFERRED                       NUMBER(1)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.OPTICALMAP (
    OPTICAL_MAP_ID                     NUMBER(12)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    RESTRICTION_ENZYME                 VARCHAR2(25)                                  NOT NULL,
    CHROMOSOME                         VARCHAR2(25)                                  NOT NULL,
    MAP_NAME                           VARCHAR2(50)                                  NOT NULL,
    CHROMOSOME_ORIENTATION             VARCHAR2(10)                                  NOT NULL,
    TAXON_ID                           NUMBER(12)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.OPTICALMAPALIGNMENT (
    OPTICAL_MAP_ALIGNMENT_ID           NUMBER(12)                                    NOT NULL,
    OPTICAL_MAP_ID                     NUMBER(12)                                    NOT NULL,
    NA_SEQUENCE_ID                     NUMBER(12)                                    NOT NULL,
    SCORE                              FLOAT(22)                                     NULL,
    P_VALUE                            FLOAT(22)                                     NOT NULL,
    START_FRAGMENT                     NUMBER(5)                                     NOT NULL,
    END_FRAGMENT                       NUMBER(5)                                     NOT NULL,
    ALGORITHM_ID                       NUMBER(12)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.OPTICALMAPALIGNMENTSPAN (
    OPTICAL_MAP_ALIGNMENT_SPAN_ID      NUMBER(12)                                    NOT NULL,
    OPTICAL_MAP_ALIGNMENT_ID           NUMBER(12)                                    NOT NULL,
    OPTICAL_MAP_FRAGMENT_ID            NUMBER(12)                                    NULL,
    NA_FEATURE_ID                      NUMBER(12)                                    NULL,
    SCORE                              FLOAT(22)                                     NULL,
    STATE_NAME                         VARCHAR2(25)                                  NULL,
    OPTICAL_MAP_LENGTH                 FLOAT(22)                                     NULL,
    FRAGMENT_LENGTH_KB                 FLOAT(22)                                     NULL,
    ORDER_NUM                          NUMBER(5)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.OPTICALMAPFRAGMENT (
    OPTICAL_MAP_FRAGMENT_ID            NUMBER(12)                                    NOT NULL,
    OPTICAL_MAP_ID                     NUMBER(12)                                    NOT NULL,
    FRAGMENT_LENGTH_KB                 FLOAT(22)                                     NOT NULL,
    FRAGMENT_ORDER                     NUMBER(5)                                     NOT NULL,
    CUMULATIVE_LENGTH_KB               FLOAT(22)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ORGANELLE (
    ORGANELLE_ID                       NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(300)                                 NULL,
    PLASMID_NAME                       VARCHAR2(300)                                 NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.PATHWAY (
    PATHWAY_ID                         NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.PATHWAYINTERACTION (
    PATHWAY_INTERACTION_ID             NUMBER(10)                                    NOT NULL,
    PATHWAY_ID                         NUMBER(10)                                    NOT NULL,
    INTERACTION_ID                     NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.PFAMENTRY (
    PFAM_ENTRY_ID                      NUMBER(10)                                    NOT NULL,
    RELEASE                            VARCHAR2(5)                                   NOT NULL,
    ACCESSION                          VARCHAR2(10)                                  NOT NULL,
    IDENTIFIER                         VARCHAR2(16)                                  NOT NULL,
    DEFINITION                         VARCHAR2(80)                                  NOT NULL,
    AUTHOR                             VARCHAR2(255)                                 NULL,
    ALIGNMENT_METHOD                   VARCHAR2(100)                                 NULL,
    NUMBER_OF_SEQS                     NUMBER(12)                                    NOT NULL,
    COMMENT_STRING                     CLOB                                          NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.PLASMOMAP (
    PLASMOMAP_ID                       NUMBER(12)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NULL,
    SOURCE_ID                          VARCHAR2(15)                                  NOT NULL,
    MARKER_NAME                        VARCHAR2(25)                                  NOT NULL,
    MARKER_SYNONYM                     VARCHAR2(15)                                  NULL,
    ACCESSION                          VARCHAR2(10)                                  NULL,
    CHROMOSOME                         VARCHAR2(2)                                   NOT NULL,
    CENTIMORGANS                       FLOAT(126)                                    NULL,
    FRAMEWORK                          VARCHAR2(15)                                  NULL,
    FORWARD_PRIMER                     VARCHAR2(50)                                  NOT NULL,
    REVERSE_PRIMER                     VARCHAR2(50)                                  NOT NULL,
    PRODUCT_LENGTH                     NUMBER(12)                                    NOT NULL,
    TAXON_ID                           NUMBER(12)                                    NOT NULL,
    CROSS                              VARCHAR2(30)                                  NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.PROJECTLINK (
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.PROTEIN (
    PROTEIN_ID                         NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(255)                                 NULL,
    RNA_ID                             NUMBER(10)                                    NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NULL,
    REVIEWER_SUMMARY                   VARCHAR2(4000)                                NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.PROTEINCATEGORY (
    PROTEIN_CATEGORY_ID                NUMBER(10)                                    NOT NULL,
    TERM                               VARCHAR2(80)                                  NOT NULL,
    DEFINITION                         VARCHAR2(255)                                 NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.PROTEININSTANCE (
    PROTEIN_INSTANCE_ID                NUMBER(10)                                    NOT NULL,
    PROTEIN_INSTANCE_CATEGORY_ID       NUMBER(3)                                     NOT NULL,
    PROTEIN_ID                         NUMBER(10)                                    NOT NULL,
    AA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
    REVIEWER_SUMMARY                   VARCHAR2(4000)                                NULL,
    IS_REFERENCE                       NUMBER(1)                                     NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.PROTEININSTANCECATEGORY (
    PROTEIN_INSTANCE_CATEGORY_ID       NUMBER(3)                                     NOT NULL,
    NAME                               VARCHAR2(40)                                  NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.PROTEINPROPERTY (
    PROTEIN_PROPERTY_ID                NUMBER(10)                                    NOT NULL,
    AA_SEQUENCE_ID                     NUMBER(10)                                    NOT NULL,
    PROTEIN_PROPERTY_TYPE_ID           NUMBER(10)                                    NOT NULL,
    VALUE                              FLOAT(126)                                    NOT NULL,
    VALUE_UNITS                        VARCHAR2(15)                                  NULL,
    PREDICTION_ALGORITHM_ID            NUMBER(5)                                     NULL,
    IS_PREDICTED                       NUMBER(1)                                     NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.PROTEINPROPERTYTYPE (
    PROTEIN_PROPERTY_TYPE_ID           NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.PROTEINPROTEINCATEGORY (
    PROTEIN_PROTEIN_CATEGORY_ID        NUMBER(10)                                    NOT NULL,
    PROTEIN_ID                         NUMBER(10)                                    NOT NULL,
    PROTEIN_CATEGORY_ID                NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.PROTEINSYNONYM (
    PROTEIN_SYNONYM_ID                 NUMBER(18)                                    NOT NULL,
    PROTEIN_ID                         NUMBER(10)                                    NOT NULL,
    SYNONYM_NAME                       VARCHAR2(50)                                  NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.REPEATTYPE (
    REPEAT_TYPE_ID                     NUMBER(10)                                    NOT NULL,
    PARENT_ID                          NUMBER(10)                                    NOT NULL,
    HIERARCHY                          NUMBER(3)                                     NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    EXEMPLAR_NA_SEQUENCE_ID            NUMBER(10)                                    NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.RHMAP (
    RH_MAP_ID                          NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    TAXON_ID                           NUMBER(12)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(12)                                    NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    LAB                                VARCHAR2(200)                                 NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.RHMAPMARKER (
    RH_MAP_MARKER_ID                   NUMBER(12)                                    NOT NULL,
    RH_MARKER_ID                       NUMBER(12)                                    NOT NULL,
    RH_MAP_ID                          NUMBER(12)                                    NOT NULL,
    CHROMOSOME                         VARCHAR2(8)                                   NULL,
    CENTIRAYS                          FLOAT(22)                                     NOT NULL,
    CENTIMORGANS                       FLOAT(22)                                     NULL,
    FRAME_PLACE                        VARCHAR2(2)                                   NULL,
    LOD                                VARCHAR2(10)                                  NULL,
    RH_VECTOR                          VARCHAR2(255)                                 NULL,
    LAB                                VARCHAR2(8)                                   NULL,
    ASSAY                              VARCHAR2(200)                                 NULL,
    PANEL_DESCRIPTION                  VARCHAR2(255)                                 NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.RHMARKER (
    RH_MARKER_ID                       NUMBER(12)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(12)                                    NOT NULL,
    SOURCE_ID                          VARCHAR2(30)                                  NULL,
    NAME                               VARCHAR2(200)                                 NOT NULL,
    PANEL                              VARCHAR2(20)                                  NULL,
    GENBANK_ID                         VARCHAR2(15)                                  NULL,
    FORWARD_PRIMER                     VARCHAR2(50)                                  NULL,
    REVERSE_PRIMER                     VARCHAR2(50)                                  NULL,
    PRODUCT_LENGTH                     NUMBER(12)                                    NULL,
    MARKER_SEQUENCE                    CLOB                                          NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NULL,
    TAXON_ID                           NUMBER(12)                                    NOT NULL,
    TYPE                               VARCHAR2(8)                                   NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.RNA (
    RNA_ID                             NUMBER(10)                                    NOT NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NULL,
    REVIEW_STATUS_ID                   NUMBER(1)                                     NOT NULL,
    GENE_ID                            NUMBER(10)                                    NULL,
    REVIEWER_SUMMARY                   VARCHAR2(4000)                                NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.RNAANATOMY (
    RNA_ANATOMY_ID                     NUMBER(10)                                    NOT NULL,
    ANATOMY_ID                         NUMBER(4)                                     NOT NULL,
    RNA_ID                             NUMBER(10)                                    NOT NULL,
    EST_NUMBER                         NUMBER(6)                                     NULL,
    RAD_CONFIRMED                      NUMBER(1)                                     NOT NULL,
    LITERATURE_CONFIRMED               NUMBER(1)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.RNAANATOMYLOE (
    RNA_ANATOMY_LOE_ID                 NUMBER(10)                                    NOT NULL,
    RNA_ANATOMY_ID                     NUMBER(10)                                    NOT NULL,
    ANATOMY_LOE_ID                     NUMBER(5)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.RNACATEGORY (
    RNA_CATEGORY_ID                    NUMBER(10)                                    NOT NULL,
    TERM                               VARCHAR2(80)                                  NOT NULL,
    DEFINITION                         VARCHAR2(255)                                 NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.RNAFEATUREEXON (
    RNA_FEATURE_EXON_ID                NUMBER(10)                                    NOT NULL,
    RNA_FEATURE_ID                     NUMBER(10)                                    NOT NULL,
    EXON_FEATURE_ID                    NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.RNAICONSTRUCT (
    RNAI_CONSTRUCT_ID                  NUMBER(10)                                    NOT NULL,
    RNA_ID                             NUMBER(10)                                    NOT NULL,
    DESCRIPTION                        VARCHAR2(1000)                                NULL,
    SEQUENCE                           CLOB                                          NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.RNAINSTANCE (
    RNA_INSTANCE_ID                    NUMBER(10)                                    NOT NULL,
    RNA_ID                             NUMBER(10)                                    NOT NULL,
    NA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
    REVIEWER_SUMMARY                   VARCHAR2(4000)                                NULL,
    IS_REFERENCE                       NUMBER(1)                                     NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
    RNA_INSTANCE_CATEGORY_ID           NUMBER(3)                                     NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.RNAINSTANCECATEGORY (
    RNA_INSTANCE_CATEGORY_ID           NUMBER(3)                                     NOT NULL,
    NAME                               VARCHAR2(255)                                 NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.RNAIPHENOTYPE (
    RNAI_PHENOTYPE_ID                  NUMBER(10)                                    NOT NULL,
    RNAI_CONSTRUCT_ID                  NUMBER(10)                                    NOT NULL,
    PHENOTYPE_ID                       NUMBER(10)                                    NOT NULL,
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.RNARNACATEGORY (
    RNA_RNA_CATEGORY_ID                NUMBER(10)                                    NOT NULL,
    RNA_ID                             NUMBER(10)                                    NOT NULL,
    RNA_CATEGORY_ID                    NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ROWSET (
    ROW_SET_ID                         NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.ROWSETMEMBER (
    ROW_SET_MEMBER_ID                  NUMBER(10)                                    NOT NULL,
    ROW_SET_ID                         NUMBER(10)                                    NOT NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    ROW_ID                             NUMBER(10)                                    NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.SECONDARYACCS (
    SECONDARY_ACCS_ID                  NUMBER(10)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NULL,
    AA_ENTRY_ID                        NUMBER(10)                                    NULL,
    NA_ENTRY_ID                        NUMBER(10)                                    NULL,
    SOURCE_ID                          VARCHAR2(15)                                  NOT NULL,
    SECONDARY_ACCS                     VARCHAR2(15)                                  NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.SEQGROUPEXPERIMENTIMP (
    SEQ_GROUP_EXPERIMENT_ID            NUMBER                                        NOT NULL,
    SUBCLASS_VIEW                      VARCHAR2(30)                                  NOT NULL,
    ALGORITHM_ID                       NUMBER                                        NULL,
    DESCRIPTION                        VARCHAR2(2000)                                NULL,
    SEQUENCE_SOURCE                    VARCHAR2(500)                                 NULL,
    PVALUE_MANT                        FLOAT(63)                                     NULL,
    PVALUE_EXP                         NUMBER                                        NULL,
    PERCENT_IDENTITY                   FLOAT(63)                                     NULL,
    PERCENT_MATCH                      FLOAT(63)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.SEQUENCEFAMILY (
    SEQUENCE_FAMILY_ID                 NUMBER                                        NOT NULL,
    NAME                               VARCHAR2(500)                                 NOT NULL,
    DESCRIPTION                        VARCHAR2(2000)                                NULL,
    SEQUENCE_FAMILY_EXPERIMENT_ID      NUMBER                                        NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.SEQUENCEFAMILYEXPERIMENT (
    SEQUENCE_FAMILY_EXPERIMENT_ID      NUMBER                                        NOT NULL,
    DESCRIPTION                        VARCHAR2(2000)                                NULL,
    ORTHOLOG_EXPERIMENT_ID             NUMBER                                        NULL,
    IN_PARALOG_EXPERIMENT_ID           NUMBER                                        NULL,
    OUT_PARALOG_EXPERIMENT_ID          NUMBER                                        NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.SEQUENCEGROUPFAMILY (
    SEQUENCE_GROUP_FAMILY_ID           NUMBER                                        NOT NULL,
    SEQUENCE_FAMILY_ID                 NUMBER                                        NULL,
    SEQUENCE_GROUP_ID                  NUMBER                                        NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.SEQUENCEGROUPIMP (
    SEQUENCE_GROUP_ID                  NUMBER                                        NOT NULL,
    SUBCLASS_VIEW                      VARCHAR2(100)                                 NOT NULL,
    NAME                               VARCHAR2(500)                                 NULL,
    DESCRIPTION                        VARCHAR2(2000)                                NULL,
    NUMBER_OF_MEMBERS                  NUMBER                                        NOT NULL,
    NUMBER_OF_TAXA                     NUMBER                                        NULL,
    MAX_SCORE                          FLOAT(22)                                     NULL,
    MIN_SCORE                          FLOAT(22)                                     NULL,
    MAX_MATCH_IDENTITY                 FLOAT(63)                                     NULL,
    MIN_MATCH_IDENTITY                 FLOAT(63)                                     NULL,
    MAX_PERCENT_MATCH                  FLOAT(63)                                     NULL,
    MIN_PERCENT_MATCH                  FLOAT(63)                                     NULL,
    MAX_PVALUE_MANT                    FLOAT(63)                                     NULL,
    MAX_PVALUE_EXP                     NUMBER                                        NULL,
    MIN_PVALUE_MANT                    FLOAT(63)                                     NULL,
    MIN_PVALUE_EXP                     NUMBER                                        NULL,
    SEQUENCE_GROUP_EXPERIMENT_ID       NUMBER                                        NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.SEQUENCEPIECE (
    SEQUENCE_PIECE_ID                  NUMBER(10)                                    NOT NULL,
    VIRTUAL_NA_SEQUENCE_ID             NUMBER(10)                                    NOT NULL,
    PIECE_NA_SEQUENCE_ID               NUMBER(10)                                    NOT NULL,
    SEQUENCE_ORDER                     NUMBER(5)                                     NOT NULL,
    DISTANCE_FROM_LEFT                 NUMBER(12)                                    NULL,
    UNCERTAINTY                        FLOAT(126)                                    NULL,
    STRAND_ORIENTATION                 VARCHAR2(7)                                   NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.SEQUENCESEQUENCEGROUP (
    SEQUENCE_SEQUENCE_GROUP_ID         NUMBER                                        NOT NULL,
    SEQUENCE_ID                        NUMBER                                        NOT NULL,
    SOURCE_TABLE_ID                    NUMBER                                        NULL,
    SEQUENCE_GROUP_ID                  NUMBER                                        NOT NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.SEQUENCETYPE (
    SEQUENCE_TYPE_ID                   NUMBER(4)                                     NOT NULL,
    NUCLEOTIDE_TYPE                    CHAR(7)                                       NOT NULL,
    SUB_TYPE                           VARCHAR2(20)                                  NULL,
    STRAND                             CHAR(2)                                       NULL,
    HIERARCHY                          NUMBER(3)                                     NOT NULL,
    PARENT_SEQUENCE_TYPE_ID            NUMBER(4)                                     NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.SIMILARITY (
    SIMILARITY_ID                      NUMBER(10)                                    NOT NULL,
    SUBJECT_TABLE_ID                   NUMBER(5)                                     NOT NULL,
    SUBJECT_ID                         NUMBER(10)                                    NOT NULL,
    QUERY_TABLE_ID                     NUMBER(5)                                     NOT NULL,
    QUERY_ID                           NUMBER(10)                                    NOT NULL,
    SCORE                              FLOAT(126)                                    NOT NULL,
    BIT_SCORE_SUMMARY                  FLOAT(126)                                    NULL,
    PVALUE_MANT                        FLOAT(126)                                    NOT NULL,
    PVALUE_EXP                         NUMBER(6)                                     NOT NULL,
    MIN_SUBJECT_START                  NUMBER(12)                                    NOT NULL,
    MAX_SUBJECT_END                    NUMBER(12)                                    NOT NULL,
    MIN_QUERY_START                    NUMBER(12)                                    NOT NULL,
    MAX_QUERY_END                      NUMBER(12)                                    NOT NULL,
    NUMBER_OF_MATCHES                  NUMBER(5)                                     NOT NULL,
    TOTAL_MATCH_LENGTH                 NUMBER(12)                                    NOT NULL,
    NUMBER_IDENTICAL                   NUMBER(12)                                    NOT NULL,
    NUMBER_POSITIVE                    NUMBER(12)                                    NOT NULL,
    IS_REVERSED                        NUMBER(1)                                     NOT NULL,
    READING_FRAME                      NUMBER(3)                                     NULL,
    ALGORITHM_ID                       NUMBER(5)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.SIMILARITYSPAN (
    SIMILARITY_SPAN_ID                 NUMBER(10)                                    NOT NULL,
    SIMILARITY_ID                      NUMBER(10)                                    NOT NULL,
    MATCH_LENGTH                       NUMBER(12)                                    NOT NULL,
    NUMBER_IDENTICAL                   NUMBER(12)                                    NOT NULL,
    NUMBER_POSITIVE                    NUMBER(12)                                    NOT NULL,
    SCORE                              FLOAT(126)                                    NOT NULL,
    BIT_SCORE                          FLOAT(126)                                    NULL,
    PVALUE_MANT                        FLOAT(126)                                    NOT NULL,
    PVALUE_EXP                         NUMBER(6)                                     NOT NULL,
    SUBJECT_START                      NUMBER(12)                                    NULL,
    SUBJECT_END                        NUMBER(12)                                    NULL,
    QUERY_START                        NUMBER(12)                                    NULL,
    QUERY_END                          NUMBER(12)                                    NULL,
    IS_REVERSED                        NUMBER(1)                                     NOT NULL,
    READING_FRAME                      NUMBER(3)                                     NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE DoTStest.TRANSLATEDAAFEATSEG (
    TRANSLATED_AA_FEAT_SEG_ID          NUMBER(10)                                    NOT NULL,
    AA_FEATURE_ID                      NUMBER(10)                                    NOT NULL,
    TRANSLATION_SCORE                  FLOAT(126)                                    NOT NULL,
    START_POS                          NUMBER(12)                                    NOT NULL,
    END_POS                            NUMBER(12)                                    NOT NULL,
    AA_START_POS                       NUMBER(12)                                    NULL,
    AA_END_POS                         NUMBER(12)                                    NULL,
    NUCLEOTIDES_SHIFTED                NUMBER(12)                                    NULL,
    TYPE_OF_SHIFT                      VARCHAR2(20)                                  NULL,
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
 TABLESPACE RAID1
 STORAGE (MAXEXTENTS UNLIMITED );


/* 159 table(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

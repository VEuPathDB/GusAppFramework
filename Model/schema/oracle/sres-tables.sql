
/*                                                                                            */
/* sres-tables.sql                                                                            */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Feb 17 12:43:33 EST 2004     */
/*                                                                                            */

SET ECHO ON
SPOOL sres-tables.log

CREATE TABLE @oracle_sres@.ABSTRACT (
    ABSTRACT_ID                        NUMBER(10)                                    NOT NULL,
    BIBLIOGRAPHIC_REFERENCE_ID         NUMBER(10)                                    NOT NULL,
    ABSTRACT                           CLOB                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.ANATOMY (
    ANATOMY_ID                         NUMBER(4)                                     NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
    HIER_LEVEL                         NUMBER(3)                                     NULL,
    PARENT_ID                          NUMBER(4)                                     NULL,
    SOURCE                             VARCHAR2(20)                                  NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
    LEVEL_1                            VARCHAR2(80)                                  NULL,
    LEVEL_2                            VARCHAR2(80)                                  NULL,
    LEVEL_3                            VARCHAR2(80)                                  NULL,
    LEVEL_4                            VARCHAR2(80)                                  NULL,
    LEVEL_5                            VARCHAR2(80)                                  NULL,
    LEVEL_6                            VARCHAR2(80)                                  NULL,
    LEVEL_7                            VARCHAR2(80)                                  NULL,
    LEVEL_8                            VARCHAR2(80)                                  NULL,
    LEVEL_9                            VARCHAR2(80)                                  NULL,
    LEVEL_10                           VARCHAR2(80)                                  NULL,
    LEVEL_11                           VARCHAR2(80)                                  NULL,
    LEVEL_12                           VARCHAR2(80)                                  NULL,
    LEVEL_13                           VARCHAR2(80)                                  NULL,
    LEVEL_14                           VARCHAR2(80)                                  NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.ANATOMYLINEAGE (
    ANATOMY_LINEAGE_ID                 NUMBER(10)                                    NOT NULL,
    LINEAGE_ID                         NUMBER(2)                                     NOT NULL,
    ANATOMY_ID                         NUMBER(4)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.AUTHOR (
    AUTHOR_ID                          NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(200)                                 NOT NULL,
    FIRST                              VARCHAR2(100)                                 NULL,
    MIDDLE_INITIALS                    VARCHAR2(10)                                  NULL,
    LAST                               VARCHAR2(100)                                 NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.BIBLIOGRAPHICREFERENCE (
    BIBLIOGRAPHIC_REFERENCE_ID         NUMBER(10)                                    NOT NULL,
    BIB_REF_TYPE_ID                    NUMBER(10)                                    NOT NULL,
    TITLE                              VARCHAR2(255)                                 NOT NULL,
    AUTHORS                            VARCHAR2(500)                                 NOT NULL,
    PUBLICATION                        VARCHAR2(255)                                 NULL,
    EDITOR                             VARCHAR2(255)                                 NULL,
    YEAR                               NUMBER(5)                                     NULL,
    VOLUME                             VARCHAR2(100)                                 NULL,
    ISSUE                              VARCHAR2(100)                                 NULL,
    PAGES                              VARCHAR2(100)                                 NULL,
    URI                                VARCHAR2(100)                                 NULL,
    MEDLINE_ID                         VARCHAR2(50)                                  NULL,
    PUBMED_ID                          VARCHAR2(50)                                  NULL,
    CONTACT_ID                         NUMBER(10)                                    NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.BIBREFANNOTATION (
    BIB_REF_ANNOTATION_ID              NUMBER(10)                                    NOT NULL,
    BIBLIOGRAPHIC_REFERENCE_ID         NUMBER(10)                                    NOT NULL,
    ANNOTATION                         VARCHAR2(50)                                  NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.BIBREFAUTHOR (
    BIB_REF_AUTHOR_ID                  NUMBER(10)                                    NOT NULL,
    BIBLIOGRAPHIC_REFERENCE_ID         NUMBER(10)                                    NOT NULL,
    AUTHOR_ID                          NUMBER(10)                                    NOT NULL,
    ORDER_NUM                          NUMBER(5)                                     NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.BIBREFTYPE (
    BIB_REF_TYPE_ID                    NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NULL,
    SOURCE                             VARCHAR2(20)                                  NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NULL,
    SOURCE_ID                          VARCHAR2(255)                                 NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.CONTACT (
    CONTACT_ID                         NUMBER(12)                                    NOT NULL,
    AFFILIATION_ID                     NUMBER(12)                                    NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NULL,
    SOURCE_ID                          VARCHAR2(255)                                 NULL,
    NAME                               VARCHAR2(255)                                 NULL,
    FIRST                              VARCHAR2(255)                                 NULL,
    LAST                               VARCHAR2(255)                                 NULL,
    CITY                               VARCHAR2(255)                                 NULL,
    STATE                              VARCHAR2(255)                                 NULL,
    COUNTRY                            VARCHAR2(255)                                 NULL,
    ZIP                                VARCHAR2(255)                                 NULL,
    ADDRESS1                           VARCHAR2(255)                                 NULL,
    ADDRESS2                           VARCHAR2(255)                                 NULL,
    EMAIL                              VARCHAR2(255)                                 NULL,
    PHONE                              VARCHAR2(255)                                 NULL,
    FAX                                VARCHAR2(255)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.DBREF (
    DB_REF_ID                          NUMBER(10)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(5)                                     NOT NULL,
    PRIMARY_IDENTIFIER                 VARCHAR2(100)                                 NULL,
    LOWERCASE_PRIMARY_IDENTIFIER       VARCHAR2(100)                                 NULL,
    SECONDARY_IDENTIFIER               VARCHAR2(50)                                  NULL,
    LOWERCASE_SECONDARY_IDENTIFIER     VARCHAR2(100)                                 NULL,
    GENE_SYMBOL                        VARCHAR2(50)                                  NULL,
    CHROMOSOME                         VARCHAR2(2)                                   NULL,
    CENTIMORGANS                       NUMBER(22)                                    NULL,
    REMARK                             VARCHAR2(4000)                                NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.DEVELOPMENTALSTAGE (
    DEVELOPMENTAL_STAGE_ID             NUMBER(4)                                     NOT NULL,
    PARENT_ID                          NUMBER(4)                                     NULL,
    TAXON_ID                           NUMBER(12)                                    NULL,
    NAME                               VARCHAR2(100)                                 NULL,
    SOURCE                             VARCHAR2(255)                                 NULL,
    DEFINITION                         VARCHAR2(500)                                 NULL,
    LEVEL_1                            VARCHAR2(50)                                  NULL,
    LEVEL_2                            VARCHAR2(50)                                  NULL,
    LEVEL_3                            VARCHAR2(50)                                  NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.DISEASE (
    DISEASE_ID                         NUMBER(4)                                     NOT NULL,
    PARENT_ID                          NUMBER(4)                                     NULL,
    SOURCE                             VARCHAR2(255)                                 NULL,
    NAME                               VARCHAR2(255)                                 NOT NULL,
    DEFINITION                         VARCHAR2(500)                                 NULL,
    LEVEL_1                            VARCHAR2(255)                                 NULL,
    LEVEL_2                            VARCHAR2(255)                                 NULL,
    LEVEL_3                            VARCHAR2(255)                                 NULL,
    LEVEL_4                            VARCHAR2(255)                                 NULL,
    LEVEL_5                            VARCHAR2(255)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.ECPATHWAY (
    EC_PATHWAY_ID                      NUMBER(12)                                    NOT NULL,
    SOURCE_ID                          VARCHAR2(40)                                  NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(12)                                    NOT NULL,
    DESCRIPTION                        VARCHAR2(400)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.ECPATHWAYENZYMECLASS (
    EC_PATHWAY_ENZYME_CLASS_ID         NUMBER(12)                                    NOT NULL,
    EC_PATHWAY_ID                      NUMBER(12)                                    NOT NULL,
    ENZYME_CLASS_ID                    NUMBER(12)                                    NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.ENZYMECLASS (
    ENZYME_CLASS_ID                    NUMBER(12)                                    NOT NULL,
    DEPTH                              NUMBER(1)                                     NOT NULL,
    EC_NUMBER                          VARCHAR2(16)                                  NOT NULL,
    EC_NUMBER_1                        NUMBER(3)                                     NULL,
    EC_NUMBER_2                        NUMBER(3)                                     NULL,
    EC_NUMBER_3                        NUMBER(3)                                     NULL,
    EC_NUMBER_4                        NUMBER(3)                                     NULL,
    DESCRIPTION                        VARCHAR2(128)                                 NULL,
    PARENT_ID                          NUMBER(12)                                    NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(12)                                    NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.ENZYMECLASSATTRIBUTE (
    ENZYME_CLASS_ATTRIBUTE_ID          NUMBER(12)                                    NOT NULL,
    ENZYME_CLASS_ID                    NUMBER(12)                                    NULL,
    ATTRIBUTE_NAME                     VARCHAR2(32)                                  NOT NULL,
    ATTRIBUTE_VALUE                    VARCHAR2(4000)                                NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.EXTERNALDATABASE (
    EXTERNAL_DATABASE_ID               NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
    LOWERCASE_NAME                     VARCHAR2(80)                                  NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.EXTERNALDATABASEENTRY (
    EXTERNAL_DATABASE_ENTRY_ID         NUMBER(10)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NOT NULL,
    EXTERNAL_PRIMARY_IDENTIFIER        VARCHAR2(255)                                 NULL,
    EXTERNAL_SECONDARY_IDENTIFIER      VARCHAR2(255)                                 NULL,
    NAME                               VARCHAR2(40)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.EXTERNALDATABASEKEYWORD (
    EXTERNAL_DATABASE_KEYWORD_ID       NUMBER(10)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NOT NULL,
    KEYWORD_ID                         NUMBER(6)                                     NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.EXTERNALDATABASELINK (
    EXTERNAL_DATABASE_LINK_ID          NUMBER(10)                                    NOT NULL,
    LINK_TABLE_ID                      NUMBER(5)                                     NOT NULL,
    LINK_PRIMARY_ID                    NUMBER(10)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NOT NULL,
    EXTERNAL_PRIMARY_IDENTIFIER        VARCHAR2(255)                                 NULL,
    EXTERNAL_SECONDARY_IDENTIFIER      VARCHAR2(255)                                 NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.EXTERNALDATABASERELEASE (
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NOT NULL,
    EXTERNAL_DATABASE_ID               NUMBER(10)                                    NOT NULL,
    RELEASE_DATE                       DATE                                          NULL,
    VERSION                            VARCHAR2(255)                                 NOT NULL,
    DOWNLOAD_URL                       VARCHAR2(255)                                 NULL,
    ID_TYPE                            VARCHAR2(255)                                 NULL,
    ID_URL                             VARCHAR2(255)                                 NULL,
    SECONDARY_ID_TYPE                  VARCHAR2(255)                                 NULL,
    SECONDARY_ID_URL                   VARCHAR2(255)                                 NULL,
    DESCRIPTION                        VARCHAR2(4000)                                NULL,
    FILE_NAME                          VARCHAR2(255)                                 NULL,
    FILE_MD5                           VARCHAR2(32)                                  NULL,
    BLAST_FILE                         VARCHAR2(255)                                 NULL,
    BLAST_FILE_MD5                     VARCHAR2(32)                                  NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.GENETICCODE (
    GENETIC_CODE_ID                    NUMBER(10)                                    NOT NULL,
    NCBI_GENETIC_CODE_ID               NUMBER(10)                                    NOT NULL,
    ABBREVIATION                       VARCHAR2(255)                                 NULL,
    NAME                               VARCHAR2(255)                                 NULL,
    CODE                               VARCHAR2(255)                                 NOT NULL,
    STARTS                             VARCHAR2(255)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.GOEVIDENCECODE (
    GO_EVIDENCE_CODE_ID                NUMBER(3)                                     NOT NULL,
    NAME                               VARCHAR2(3)                                   NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.GORELATIONSHIP (
    GO_RELATIONSHIP_ID                 NUMBER(10)                                    NOT NULL,
    PARENT_TERM_ID                     NUMBER(10)                                    NOT NULL,
    CHILD_TERM_ID                      NUMBER(10)                                    NOT NULL,
    GO_RELATIONSHIP_TYPE_ID            NUMBER(10)                                    NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.GORELATIONSHIPTYPE (
    GO_RELATIONSHIP_TYPE_ID            NUMBER(10)                                    NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.GOSYNONYM (
    GO_SYNONYM_ID                      NUMBER(10)                                    NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NOT NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    GO_TERM_ID                         NUMBER(10)                                    NOT NULL,
    TEXT                               VARCHAR2(255)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.GOTERM (
    GO_TERM_ID                         NUMBER(10)                                    NOT NULL,
    GO_ID                              VARCHAR2(32)                                  NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NOT NULL,
    SOURCE_ID                          VARCHAR2(32)                                  NULL,
    NAME                               VARCHAR2(255)                                 NOT NULL,
    DEFINITION                         VARCHAR2(4000)                                NULL,
    COMMENT_STRING                     VARCHAR2(4000)                                NULL,
    MINIMUM_LEVEL                      NUMBER                                        NOT NULL,
    MAXIMUM_LEVEL                      NUMBER                                        NOT NULL,
    NUMBER_OF_LEVELS                   NUMBER                                        NOT NULL,
    ANCESTOR_GO_TERM_ID                NUMBER(10)                                    NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.LINEAGE (
    LINEAGE_ID                         NUMBER(2)                                     NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.MGEDONTOLOGYRELATIONSHIP (
    MGED_ONTOLOGY_RELATIONSHIP_ID      NUMBER(10)                                    NOT NULL,
    SUBJECT_TERM_ID                    NUMBER(10)                                    NOT NULL,
    PREDICATE_TERM_ID                  NUMBER(10)                                    NULL,
    OBJECT_TERM_ID                     NUMBER(10)                                    NOT NULL,
    ONTOLOGY_RELATIONSHIP_TYPE_ID      NUMBER(4)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.MGEDONTOLOGYTERM (
    MGED_ONTOLOGY_TERM_ID              NUMBER(10)                                    NOT NULL,
    ONTOLOGY_TERM_TYPE_ID              NUMBER(5)                                     NOT NULL,
    EXTERNAL_DATABASE_RELEASE_ID       NUMBER(10)                                    NOT NULL,
    SOURCE_ID                          VARCHAR2(255)                                 NOT NULL,
    URI                                VARCHAR2(500)                                 NULL,
    NAME                               VARCHAR2(255)                                 NOT NULL,
    DEFINITION                         VARCHAR2(1000)                                NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.MUTAGEN (
    MUTAGEN_ID                         NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.ONTOLOGYRELATIONSHIPTYPE (
    ONTOLOGY_RELATIONSHIP_TYPE_ID      NUMBER(4)                                     NOT NULL,
    IS_NATIVE                          NUMBER(1)                                     NOT NULL,
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
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL)
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.ONTOLOGYTERMTYPE (
    ONTOLOGY_TERM_TYPE_ID              NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(50)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(100)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.PATOATTRIBUTE (
    PATO_ATTRIBUTE_ID                  NUMBER(8)                                     NOT NULL,
    SOURCE                             VARCHAR2(255)                                 NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    DEFINITION                         VARCHAR2(500)                                 NULL,
    LEVEL_1                            VARCHAR2(50)                                  NULL,
    LEVEL_2                            VARCHAR2(50)                                  NULL,
    LEVEL_3                            VARCHAR2(50)                                  NULL,
    LEVEL_4                            VARCHAR2(50)                                  NULL,
    LEVEL_5                            VARCHAR2(50)                                  NULL,
    LEVEL_6                            VARCHAR2(50)                                  NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.PHENOTYPE (
    PHENOTYPE_ID                       NUMBER(8)                                     NOT NULL,
    PARENT_ID                          NUMBER(8)                                     NULL,
    PATO_ATTRIBUTE_ID                  NUMBER(8)                                     NULL,
    ANATOMY_ID                         NUMBER(4)                                     NULL,
    CELL_TYPE_ID                       NUMBER(4)                                     NULL,
    DEVELOPMENTAL_STAGE_ID             NUMBER(4)                                     NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.PHENOTYPECLASS (
    PHENOTYPE_CLASS_ID                 NUMBER(10)                                    NOT NULL,
    CLASS                              VARCHAR2(100)                                 NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.REFERENCE (
    REFERENCE_ID                       NUMBER(10)                                    NOT NULL,
    DB_REF_ID                          NUMBER(10)                                    NULL,
    POSITION                           VARCHAR2(100)                                 NULL,
    REMARK                             VARCHAR2(100)                                 NULL,
    AUTHOR                             VARCHAR2(255)                                 NULL,
    TITLE                              VARCHAR2(255)                                 NULL,
    JOURNAL_OR_BOOK_NAME               VARCHAR2(255)                                 NULL,
    JOURNAL_VOL                        VARCHAR2(50)                                  NULL,
    JOURNAL_PAGE                       VARCHAR2(50)                                  NULL,
    YEAR                               NUMBER(5)                                     NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.REVIEWSTATUS (
    REVIEW_STATUS_ID                   NUMBER(10)                                    NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.SEQUENCEONTOLOGY (
    SEQUENCE_ONTOLOGY_ID               NUMBER(10)                                    NOT NULL,
    SO_ID                              NUMBER(10)                                    NOT NULL,
    ONTOLOGY_NAME                      VARCHAR2(30)                                  NOT NULL,
    SO_VERSION                         VARCHAR2(255)                                 NOT NULL,
    SO_CVS_VERSION                     VARCHAR2(10)                                  NOT NULL,
    TERM_NAME                          VARCHAR2(255)                                 NOT NULL,
    DEFINITION                         VARCHAR2(255)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.SEQUENCEREFERENCE (
    SEQUENCE_REFERENCE_ID              NUMBER(10)                                    NOT NULL,
    BIBLIOGRAPHIC_REFERENCE_ID         NUMBER(10)                                    NOT NULL,
    POSITION                           VARCHAR2(100)                                 NULL,
    REMARK                             VARCHAR2(100)                                 NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.TAXON (
    TAXON_ID                           NUMBER(10)                                    NOT NULL,
    NCBI_TAX_ID                        NUMBER(10)                                    NULL,
    PARENT_ID                          NUMBER(10)                                    NULL,
    RANK                               VARCHAR2(255)                                 NOT NULL,
    GENETIC_CODE_ID                    NUMBER(10)                                    NULL,
    MITOCHONDRIAL_GENETIC_CODE_ID      NUMBER(10)                                    NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_sres@.TAXONNAME (
    TAXON_NAME_ID                      NUMBER(10)                                    NOT NULL,
    TAXON_ID                           NUMBER(10)                                    NOT NULL,
    NAME                               VARCHAR2(255)                                 NOT NULL,
    UNIQUE_NAME_VARIANT                VARCHAR2(255)                                 NULL,
    NAME_CLASS                         VARCHAR2(255)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_sresTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );


/* 42 table(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

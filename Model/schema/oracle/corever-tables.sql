
/*                                                                                            */
/* corever-tables.sql                                                                         */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Feb 25 10:26:59 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL corever-tables.log

CREATE TABLE @oracle_corever@.ALGORITHMIMPLEMENTATIONVER (
    ALGORITHM_IMPLEMENTATION_ID        NUMBER(5)                                     NOT NULL,
    ALGORITHM_ID                       NUMBER(5)                                     NOT NULL,
    VERSION                            VARCHAR2(10)                                  NULL,
    CVS_REVISION                       VARCHAR2(20)                                  NULL,
    CVS_TAG                            VARCHAR2(100)                                 NULL,
    EXECUTABLE                         VARCHAR2(255)                                 NULL,
    EXECUTABLE_MD5                     VARCHAR2(32)                                  NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.ALGORITHMINVOCATIONVER (
    ALGORITHM_INVOCATION_ID            NUMBER(12)                                    NOT NULL,
    ALGORITHM_IMPLEMENTATION_ID        NUMBER(5)                                     NOT NULL,
    START_TIME                         DATE                                          NOT NULL,
    END_TIME                           DATE                                          NOT NULL,
    MACHINE_ID                         NUMBER(5)                                     NULL,
    CPUS_USED                          NUMBER(5)                                     NULL,
    CPU_TIME                           FLOAT(126)                                    NULL,
    RESULT                             VARCHAR2(255)                                 NOT NULL,
    COMMENT_STRING                     VARCHAR2(255)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.ALGORITHMPARAMKEYTYPEVER (
    ALGORITHM_PARAM_KEY_TYPE_ID        NUMBER(3)                                     NOT NULL,
    TYPE                               VARCHAR2(15)                                  NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.ALGORITHMPARAMKEYVER (
    ALGORITHM_PARAM_KEY_ID             NUMBER(5)                                     NOT NULL,
    ALGORITHM_IMPLEMENTATION_ID        NUMBER(5)                                     NOT NULL,
    ALGORITHM_PARAM_KEY                VARCHAR2(60)                                  NOT NULL,
    ALGORITHM_PARAM_KEY_TYPE_ID        NUMBER(3)                                     NOT NULL,
    IS_LIST_VALUED                     NUMBER(1)                                     NOT NULL,
    DESCRIPTION                        VARCHAR2(512)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.ALGORITHMPARAMVER (
    ALGORITHM_PARAM_ID                 NUMBER(10)                                    NOT NULL,
    ALGORITHM_PARAM_KEY_ID             NUMBER(5)                                     NOT NULL,
    STRING_VALUE                       VARCHAR2(1000)                                NULL,
    FLOAT_VALUE                        FLOAT(126)                                    NULL,
    INT_VALUE                          NUMBER(12)                                    NULL,
    BOOLEAN_VALUE                      NUMBER(1)                                     NULL,
    TABLE_ID_VALUE                     NUMBER(5)                                     NULL,
    ID_VALUE                           NUMBER(10)                                    NULL,
    DATE_VALUE                         DATE                                          NULL,
    IS_DEFAULT                         NUMBER(1)                                     NOT NULL,
    ORDER_NUM                          NUMBER(5)                                     NOT NULL,
    ALGORITHM_INVOCATION_ID            NUMBER(12)                                    NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.ALGORITHMVER (
    ALGORITHM_ID                       NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.CATEGORYVER (
    CATEGORY_ID                        NUMBER(5)                                     NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.DATABASEDOCUMENTATIONVER (
    DATABASE_DOCUMENTATION_ID          NUMBER(10)                                    NOT NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    ATTRIBUTE_NAME                     VARCHAR2(120)                                 NULL,
    HTML_DOCUMENTATION                 CLOB                                          NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.DATABASEINFOVER (
    DATABASE_ID                        NUMBER(5)                                     NOT NULL,
    VERSION                            VARCHAR2(10)                                  NOT NULL,
    NAME                               VARCHAR2(60)                                  NULL,
    DESCRIPTION                        VARCHAR2(500)                                 NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.GENERALDOCUMENTATIONVER (
    GENERAL_DOCUMENTATION_ID           NUMBER(10)                                    NOT NULL,
    DOC                                CLOB                                          NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.GROUPINFOVER (
    GROUP_ID                           NUMBER(3)                                     NOT NULL,
    NAME                               VARCHAR2(30)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.MACHINEVER (
    MACHINE_ID                         NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
    IP_ADDRESS                         VARCHAR2(24)                                  NULL,
    CPUS                               NUMBER(3)                                     NOT NULL,
    MEMORY                             NUMBER(5)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.PROJECTINFOVER (
    PROJECT_ID                         NUMBER(3)                                     NOT NULL,
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
    ROW_GROUP_ID                       NUMBER(12)                                    NOT NULL,
    ROW_PROJECT_ID                     NUMBER(12)                                    NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.TABLECATEGORYVER (
    TABLE_CATEGORY_ID                  NUMBER(5)                                     NOT NULL,
    CATEGORY_ID                        NUMBER(5)                                     NOT NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.TABLEINFOVER (
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(30)                                  NOT NULL,
    TABLE_TYPE                         VARCHAR2(40)                                  NOT NULL,
    PRIMARY_KEY_COLUMN                 VARCHAR2(30)                                  NULL,
    DATABASE_ID                        NUMBER(5)                                     NOT NULL,
    IS_VERSIONED                       NUMBER(1)                                     NOT NULL,
    IS_VIEW                            NUMBER(1)                                     NOT NULL,
    VIEW_ON_TABLE_ID                   NUMBER(5)                                     NULL,
    SUPERCLASS_TABLE_ID                NUMBER(5)                                     NULL,
    IS_UPDATABLE                       NUMBER(1)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.USERDATABASEVER (
    USER_DATABASE_ID                   NUMBER(12)                                    NOT NULL,
    USER_ID                            NUMBER(12)                                    NOT NULL,
    DATABASE_ID                        NUMBER(38)                                    NOT NULL,
    DB_USER_READ                       NUMBER(1)                                     NOT NULL,
    DB_USER_WRITE                      NUMBER(1)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.USERGROUPVER (
    USER_GROUP_ID                      NUMBER(12)                                    NOT NULL,
    USER_ID                            NUMBER(12)                                    NOT NULL,
    GROUP_ID                           NUMBER(3)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.USERINFOVER (
    USER_ID                            NUMBER(12)                                    NOT NULL,
    LOGIN                              VARCHAR2(30)                                  NOT NULL,
    PASSWORD                           VARCHAR2(30)                                  NOT NULL,
    FIRST_NAME                         VARCHAR2(30)                                  NOT NULL,
    LAST_NAME                          VARCHAR2(30)                                  NOT NULL,
    E_MAIL                             VARCHAR2(60)                                  NOT NULL,
    CONTACT_ID                         NUMBER(12)                                    NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.USERPROJECTVER (
    USER_PROJECT_ID                    NUMBER(12)                                    NOT NULL,
    USER_ID                            NUMBER(12)                                    NOT NULL,
    PROJECT_ID                         NUMBER(3)                                     NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.WORKFLOWBLACKBOARDVER (
    WORKFLOW_BLACKBOARD_ID             NUMBER(12)                                    NOT NULL,
    WORKFLOW_ID                        NUMBER(5)                                     NOT NULL,
    WORKFLOW_ALG_INVOCATION_ID         NUMBER(12)                                    NOT NULL,
    EDGE_ID                            NUMBER(10)                                    NOT NULL,
    EDGE_INVOCATION_ID                 NUMBER(12)                                    NULL,
    SET_NAME                           VARCHAR2(80)                                  NULL,
    TABLE_ID                           NUMBER(5)                                     NOT NULL,
    ROW_ID                             NUMBER(10)                                    NOT NULL,
    SECONDARY_TABLE_ID                 NUMBER(5)                                     NULL,
    SECONDARY_ROW_ID                   NUMBER(10)                                    NULL,
    STATUS                             CHAR(1)                                       NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.WORKFLOWEDGESQLVER (
    WORKFLOW_EDGE_SQL_ID               NUMBER(10)                                    NOT NULL,
    WORKFLOW_EDGE_ID                   NUMBER(10)                                    NOT NULL,
    SQL                                CLOB                                          NOT NULL,
    SET_NAME                           VARCHAR2(80)                                  NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.WORKFLOWEDGEVER (
    WORKFLOW_EDGE_ID                   NUMBER(10)                                    NOT NULL,
    WORKFLOW_ID                        NUMBER(5)                                     NOT NULL,
    FROM_WORKFLOW_NODE_ID              NUMBER(10)                                    NOT NULL,
    TO_WORKFLOW_NODE_ID                NUMBER(10)                                    NOT NULL,
    IS_TRUE                            NUMBER(1)                                     NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.WORKFLOWINITVER (
    WORKFLOW_INIT_ID                   NUMBER(12)                                    NOT NULL,
    WORKFLOW_ID                        NUMBER(5)                                     NOT NULL,
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
    ROW_GROUP_ID                       NUMBER(3)                                     NOT NULL,
    ROW_PROJECT_ID                     NUMBER(3)                                     NOT NULL,
    ROW_ALG_INVOCATION_ID              NUMBER(12)                                    NOT NULL,
    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,
    VERSION_DATE                       DATE                                          NULL,
    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL)
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.WORKFLOWNODEIMPVER (
    WORKFLOW_NODE_ID                   NUMBER(10)                                    NOT NULL,
    WORKFLOW_ID                        NUMBER(5)                                     NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
    ALGORITHM_INVOCATION_ID            NUMBER(12)                                    NULL,
    SUBCLASS_VIEW                      VARCHAR2(30)                                  NOT NULL,
    IS_START                           NUMBER(1)                                     NOT NULL,
    IS_AND                             NUMBER(1)                                     NOT NULL,
    TEXT1                              CLOB                                          NULL,
    VCHAR1                             VARCHAR2(255)                                 NULL,
    VCHAR2                             VARCHAR2(255)                                 NULL,
    VCHAR3                             VARCHAR2(255)                                 NULL,
    INT1                               NUMBER(12)                                    NULL,
    INT2                               NUMBER(12)                                    NULL,
    INT3                               NUMBER(12)                                    NULL,
    FLOAT1                             FLOAT(126)                                    NULL,
    FLOAT2                             FLOAT(126)                                    NULL,
    FLOAT3                             FLOAT(126)                                    NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.WORKFLOWSTATUSVER (
    WORKFLOW_STATUS_ID                 NUMBER(12)                                    NOT NULL,
    WORKFLOW_ID                        NUMBER(5)                                     NOT NULL,
    WORKFLOW_ALG_INVOCATION_ID         NUMBER(12)                                    NOT NULL,
    ITEM_TYPE                          VARCHAR2(30)                                  NOT NULL,
    ITEM_ID                            NUMBER(12)                                    NOT NULL,
    ITEM_INVOCATION_ID                 NUMBER(12)                                    NOT NULL,
    RELOAD_WORKFLOW                    NUMBER(1)                                     DEFAULT 0   NOT NULL,
    STATUS                             CHAR(1)                                       NOT NULL,
    START_TIME                         DATE                                          NOT NULL,
    END_TIME                           DATE                                          NULL,
    RETURN_VALUE                       NUMBER(6)                                     NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_corever@.WORKFLOWVER (
    WORKFLOW_ID                        NUMBER(5)                                     NOT NULL,
    DEFAULT_ALG_INVOCATION_ID          NUMBER(12)                                    NOT NULL,
    NAME                               VARCHAR2(80)                                  NOT NULL,
    VERSION                            VARCHAR2(10)                                  NOT NULL,
    DESCRIPTION                        VARCHAR2(255)                                 NULL,
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
 TABLESPACE @oracle_coreverTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );


/* 26 table(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

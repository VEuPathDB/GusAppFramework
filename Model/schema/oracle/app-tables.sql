
/*                                                                                            */
/* app-tables.sql                                                                             */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Feb 17 12:46:24 EST 2004     */
/*                                                                                            */

SET ECHO ON
SPOOL app-tables.log

CREATE TABLE @oracle_app@.APPLICATION (
    APPLICATION_ID                     NUMBER(8)                                     NOT NULL,
    NAME                               VARCHAR2(100)                                 NOT NULL,
    VERSION                            VARCHAR2(100)                                 NOT NULL,
    DESCRIPTION                        VARCHAR2(1000)                                NOT NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_appTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );

CREATE TABLE @oracle_app@.FORMHELP (
    FORM_HELP_ID                       NUMBER(10)                                    NOT NULL,
    APPLICATION_ID                     NUMBER(8)                                     NOT NULL,
    FORM_NAME                          VARCHAR2(50)                                  NOT NULL,
    FIELD_NAME                         VARCHAR2(50)                                  NOT NULL,
    ATTRIBUTE_NAME                     VARCHAR2(100)                                 NULL,
    ISMANDATORY                        VARCHAR2(4)                                   NULL,
    DEFINITION                         VARCHAR2(1000)                                NULL,
    EXAMPLES                           VARCHAR2(500)                                 NULL,
    MODIFICATION_DATE                  DATE                                          NOT NULL,
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
 TABLESPACE @oracle_appTablespace@
 STORAGE (MAXEXTENTS UNLIMITED );


/* 2 table(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

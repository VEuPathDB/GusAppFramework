
/*                                                                                            */
/* core-sequences.sql                                                                         */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 20:42:33 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL core-sequences.log

CREATE SEQUENCE @oracle_core@.ALGORITHMIMPLEMENTATION_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.ALGORITHMINVOCATION_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.ALGORITHMPARAMKEYTYPE_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.ALGORITHMPARAMKEY_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.ALGORITHMPARAM_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.ALGORITHM_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.CATEGORY_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.DATABASEDOCUMENTATION_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.DATABASEINFO_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.GENERALDOCUMENTATION_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.GROUPINFO_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.MACHINE_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.PROJECTINFO_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.TABLECATEGORY_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.TABLEINFO_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.USERDATABASE_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.USERGROUP_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.USERINFO_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.USERPROJECT_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.WORKFLOWBLACKBOARD_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.WORKFLOWEDGESQL_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.WORKFLOWEDGE_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.WORKFLOWINIT_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.WORKFLOWNODEIMP_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.WORKFLOWSTATUS_SQ START WITH 1;
CREATE SEQUENCE @oracle_core@.WORKFLOW_SQ START WITH 1;

/* 26 sequences(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT


/*                                                                                            */
/* core-indexes.sql                                                                           */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 03:53:47 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL core-indexes.log

/* ALGORITHM */


/* ALGORITHMIMPLEMENTATION */
create index @oracle_core@.ALGORITHMIMPLEMENTATION_IND01 on @oracle_core@.ALGORITHMIMPLEMENTATION (ALGORITHM_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* ALGORITHMINVOCATION */
create index @oracle_core@.ALGORITHMINVOCATION_IND01 on @oracle_core@.ALGORITHMINVOCATION (MACHINE_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.ALGORITHMINVOCATION_IND02 on @oracle_core@.ALGORITHMINVOCATION (ALGORITHM_IMPLEMENTATION_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* ALGORITHMPARAM */
create index @oracle_core@.ALGORITHMPARAM_IND01 on @oracle_core@.ALGORITHMPARAM (ALGORITHM_INVOCATION_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.ALGORITHMPARAM_IND02 on @oracle_core@.ALGORITHMPARAM (ALGORITHM_PARAM_KEY_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* ALGORITHMPARAMKEY */
create index @oracle_core@.ALGORITHMPARAMKEY_IND01 on @oracle_core@.ALGORITHMPARAMKEY (ALGORITHM_IMPLEMENTATION_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.ALGORITHMPARAMKEY_IND02 on @oracle_core@.ALGORITHMPARAMKEY (ALGORITHM_PARAM_KEY_TYPE_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* ALGORITHMPARAMKEYTYPE */


/* CATEGORY */


/* DATABASEDOCUMENTATION */
create index @oracle_core@.DATABASEDOCUMENTATION_IND01 on @oracle_core@.DATABASEDOCUMENTATION (TABLE_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* DATABASEINFO */


/* GENERALDOCUMENTATION */


/* GROUPINFO */


/* MACHINE */


/* PROJECTINFO */


/* TABLECATEGORY */
create index @oracle_core@.TABLECATEGORY_IND01 on @oracle_core@.TABLECATEGORY (CATEGORY_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.TABLECATEGORY_IND02 on @oracle_core@.TABLECATEGORY (TABLE_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* TABLEINFO */
create index @oracle_core@.TABLEINFO_IND01 on @oracle_core@.TABLEINFO (DATABASE_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.TABLEINFO_IND02 on @oracle_core@.TABLEINFO (VIEW_ON_TABLE_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.TABLEINFO_IND03 on @oracle_core@.TABLEINFO (SUPERCLASS_TABLE_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* USERDATABASE */
create index @oracle_core@.USERDATABASE_IND01 on @oracle_core@.USERDATABASE (USER_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.USERDATABASE_IND02 on @oracle_core@.USERDATABASE (DATABASE_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* USERGROUP */
create unique index @oracle_core@.SYS_C00173306 on @oracle_core@.USERGROUP (USER_ID,GROUP_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.USERGROUP_IND01 on @oracle_core@.USERGROUP (GROUP_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* USERINFO */
create index @oracle_core@.USERINFO_IND01 on @oracle_core@.USERINFO (CONTACT_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* USERPROJECT */
create unique index @oracle_core@.SYS_C00173307 on @oracle_core@.USERPROJECT (USER_ID,PROJECT_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.USERPROJECT_IND01 on @oracle_core@.USERPROJECT (PROJECT_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* WORKFLOW */
create index @oracle_core@.WORKFLOW_IND01 on @oracle_core@.WORKFLOW (DEFAULT_ALG_INVOCATION_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* WORKFLOWBLACKBOARD */
create index @oracle_core@.WORKFLOWBLACKBOARD_IND01 on @oracle_core@.WORKFLOWBLACKBOARD (WORKFLOW_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.WORKFLOWBLACKBOARD_IND02 on @oracle_core@.WORKFLOWBLACKBOARD (WORKFLOW_ALG_INVOCATION_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.WORKFLOWBLACKBOARD_IND03 on @oracle_core@.WORKFLOWBLACKBOARD (EDGE_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.WORKFLOWBLACKBOARD_IND04 on @oracle_core@.WORKFLOWBLACKBOARD (TABLE_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.WORKFLOWBLACKBOARD_IND05 on @oracle_core@.WORKFLOWBLACKBOARD (SECONDARY_TABLE_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.WORKFLOWBLACKBOARD_IND06 on @oracle_core@.WORKFLOWBLACKBOARD (EDGE_INVOCATION_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* WORKFLOWEDGE */
create index @oracle_core@.WORKFLOWEDGE_IND01 on @oracle_core@.WORKFLOWEDGE (WORKFLOW_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.WORKFLOWEDGE_IND02 on @oracle_core@.WORKFLOWEDGE (TO_WORKFLOW_NODE_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.WORKFLOWEDGE_IND03 on @oracle_core@.WORKFLOWEDGE (FROM_WORKFLOW_NODE_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* WORKFLOWEDGESQL */
create index @oracle_core@.WORKFLOWEDGESQL_IND01 on @oracle_core@.WORKFLOWEDGESQL (WORKFLOW_EDGE_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* WORKFLOWINIT */
create index @oracle_core@.WORKFLOWINIT_IND01 on @oracle_core@.WORKFLOWINIT (WORKFLOW_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.WORKFLOWINIT_IND02 on @oracle_core@.WORKFLOWINIT (TABLE_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* WORKFLOWNODEIMP */
create index @oracle_core@.WORKFLOWNODEIMP_IND01 on @oracle_core@.WORKFLOWNODEIMP (WORKFLOW_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.WORKFLOWNODEIMP_IND02 on @oracle_core@.WORKFLOWNODEIMP (ALGORITHM_INVOCATION_ID)  TABLESPACE @oracle_coreIndexTablespace@;

/* WORKFLOWSTATUS */
create index @oracle_core@.WORKFLOWSTATUS_IND01 on @oracle_core@.WORKFLOWSTATUS (WORKFLOW_ALG_INVOCATION_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.WORKFLOWSTATUS_IND02 on @oracle_core@.WORKFLOWSTATUS (WORKFLOW_ID)  TABLESPACE @oracle_coreIndexTablespace@;
create index @oracle_core@.WORKFLOWSTATUS_IND03 on @oracle_core@.WORKFLOWSTATUS (ITEM_INVOCATION_ID)  TABLESPACE @oracle_coreIndexTablespace@;



/* 38 index(es) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

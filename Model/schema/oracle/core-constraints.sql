
/*                                                                                            */
/* core-constraints.sql                                                                       */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 03:53:47 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL core-constraints.log

/* NON-PRIMARY KEY CONSTRAINTS */

/* ALGORITHM */

/* ALGORITHMIMPLEMENTATION */
alter table @oracle_core@.ALGORITHMIMPLEMENTATION add constraint ALGORITHMIMPLEMENTATION_FK04 foreign key (ALGORITHM_ID) references @oracle_core@.ALGORITHM (ALGORITHM_ID);

/* ALGORITHMINVOCATION */
alter table @oracle_core@.ALGORITHMINVOCATION add constraint ALGORITHMINVOCATION_FK04 foreign key (MACHINE_ID) references @oracle_core@.MACHINE (MACHINE_ID);
alter table @oracle_core@.ALGORITHMINVOCATION add constraint ALGORITHMINVOCATION_FK06 foreign key (ALGORITHM_IMPLEMENTATION_ID) references @oracle_core@.ALGORITHMIMPLEMENTATION (ALGORITHM_IMPLEMENTATION_ID);

/* ALGORITHMPARAM */
alter table @oracle_core@.ALGORITHMPARAM add constraint ALGORITHMPARAM_FK05 foreign key (ALGORITHM_PARAM_KEY_ID) references @oracle_core@.ALGORITHMPARAMKEY (ALGORITHM_PARAM_KEY_ID);
alter table @oracle_core@.ALGORITHMPARAM add constraint ALGORITHMPARAM_FK06 foreign key (ALGORITHM_INVOCATION_ID) references @oracle_core@.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);

/* ALGORITHMPARAMKEY */
alter table @oracle_core@.ALGORITHMPARAMKEY add constraint ALGORITHMPARAMKEY_FK05 foreign key (ALGORITHM_IMPLEMENTATION_ID) references @oracle_core@.ALGORITHMIMPLEMENTATION (ALGORITHM_IMPLEMENTATION_ID);
alter table @oracle_core@.ALGORITHMPARAMKEY add constraint ALGORITHMPARAMKEY_FK06 foreign key (ALGORITHM_PARAM_KEY_TYPE_ID) references @oracle_core@.ALGORITHMPARAMKEYTYPE (ALGORITHM_PARAM_KEY_TYPE_ID);

/* ALGORITHMPARAMKEYTYPE */

/* CATEGORY */

/* DATABASEDOCUMENTATION */
alter table @oracle_core@.DATABASEDOCUMENTATION add constraint DATABASEDOCUMENTATION_FK01 foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* DATABASEINFO */

/* GENERALDOCUMENTATION */

/* GROUPINFO */

/* MACHINE */

/* PROJECTINFO */

/* TABLECATEGORY */
alter table @oracle_core@.TABLECATEGORY add constraint TABLECATEGORY_FK02 foreign key (CATEGORY_ID) references @oracle_core@.CATEGORY (CATEGORY_ID);
alter table @oracle_core@.TABLECATEGORY add constraint TABLECATEGORY_FK03 foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* TABLEINFO */
alter table @oracle_core@.TABLEINFO add constraint TABLEINFO_FK01 foreign key (DATABASE_ID) references @oracle_core@.DATABASEINFO (DATABASE_ID);
alter table @oracle_core@.TABLEINFO add constraint TABLEINFO_FK02 foreign key (VIEW_ON_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_core@.TABLEINFO add constraint TABLEINFO_FK03 foreign key (SUPERCLASS_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* USERDATABASE */
alter table @oracle_core@.USERDATABASE add constraint USERDATABASE_FK05 foreign key (USER_ID) references @oracle_core@.USERINFO (USER_ID);
alter table @oracle_core@.USERDATABASE add constraint USERDATABASE_FK06 foreign key (DATABASE_ID) references @oracle_core@.DATABASEINFO (DATABASE_ID);

/* USERGROUP */
alter table @oracle_core@.USERGROUP add unique (USER_ID,GROUP_ID);
alter table @oracle_core@.USERGROUP add constraint USERGROUP_FK04 foreign key (USER_ID) references @oracle_core@.USERINFO (USER_ID);
alter table @oracle_core@.USERGROUP add constraint USERGROUP_FK05 foreign key (GROUP_ID) references @oracle_core@.GROUPINFO (GROUP_ID);

/* USERINFO */
alter table @oracle_core@.USERINFO add constraint USERINFO_FK01 foreign key (CONTACT_ID) references @oracle_sres@.CONTACT (CONTACT_ID);

/* USERPROJECT */
alter table @oracle_core@.USERPROJECT add unique (USER_ID,PROJECT_ID);
alter table @oracle_core@.USERPROJECT add constraint USERPROJECT_FK05 foreign key (USER_ID) references @oracle_core@.USERINFO (USER_ID);
alter table @oracle_core@.USERPROJECT add constraint USERPROJECT_FK06 foreign key (PROJECT_ID) references @oracle_core@.PROJECTINFO (PROJECT_ID);

/* WORKFLOW */
alter table @oracle_core@.WORKFLOW add constraint WORKFLOW_FK04 foreign key (DEFAULT_ALG_INVOCATION_ID) references @oracle_core@.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);

/* WORKFLOWBLACKBOARD */
alter table @oracle_core@.WORKFLOWBLACKBOARD add constraint WORKFLOWBLACKBOARD_FK01 foreign key (WORKFLOW_ID) references @oracle_core@.WORKFLOW (WORKFLOW_ID);
alter table @oracle_core@.WORKFLOWBLACKBOARD add constraint WORKFLOWBLACKBOARD_FK02 foreign key (WORKFLOW_ALG_INVOCATION_ID) references @oracle_core@.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);
alter table @oracle_core@.WORKFLOWBLACKBOARD add constraint WORKFLOWBLACKBOARD_FK03 foreign key (EDGE_ID) references @oracle_core@.WORKFLOWEDGE (WORKFLOW_EDGE_ID);
alter table @oracle_core@.WORKFLOWBLACKBOARD add constraint WORKFLOWBLACKBOARD_FK04 foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_core@.WORKFLOWBLACKBOARD add constraint WORKFLOWBLACKBOARD_FK05 foreign key (SECONDARY_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_core@.WORKFLOWBLACKBOARD add constraint WORKFLOWBLACKBOARD_FK06 foreign key (EDGE_INVOCATION_ID) references @oracle_core@.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);

/* WORKFLOWEDGE */
alter table @oracle_core@.WORKFLOWEDGE add constraint WORKFLOWEDGE_FK03 foreign key (WORKFLOW_ID) references @oracle_core@.WORKFLOW (WORKFLOW_ID);
alter table @oracle_core@.WORKFLOWEDGE add constraint WORKFLOWEDGE_FK05 foreign key (TO_WORKFLOW_NODE_ID) references @oracle_core@.WORKFLOWNODEIMP (WORKFLOW_NODE_ID);
alter table @oracle_core@.WORKFLOWEDGE add constraint WORKFLOWEDGE_FK06 foreign key (FROM_WORKFLOW_NODE_ID) references @oracle_core@.WORKFLOWNODEIMP (WORKFLOW_NODE_ID);

/* WORKFLOWEDGESQL */
alter table @oracle_core@.WORKFLOWEDGESQL add constraint WORKFLOWEDGESQL_FK04 foreign key (WORKFLOW_EDGE_ID) references @oracle_core@.WORKFLOWEDGE (WORKFLOW_EDGE_ID);

/* WORKFLOWINIT */
alter table @oracle_core@.WORKFLOWINIT add constraint WORKFLOWINIT_FK01 foreign key (WORKFLOW_ID) references @oracle_core@.WORKFLOW (WORKFLOW_ID);
alter table @oracle_core@.WORKFLOWINIT add constraint WORKFLOWINIT_FK02 foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* WORKFLOWNODEIMP */
alter table @oracle_core@.WORKFLOWNODEIMP add constraint WORKFLOWNODEIMP_FK03 foreign key (WORKFLOW_ID) references @oracle_core@.WORKFLOW (WORKFLOW_ID);
alter table @oracle_core@.WORKFLOWNODEIMP add constraint WORKFLOWNODEIMP_FK06 foreign key (ALGORITHM_INVOCATION_ID) references @oracle_core@.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);

/* WORKFLOWSTATUS */
alter table @oracle_core@.WORKFLOWSTATUS add constraint WORKFLOWSTATUS_FK01 foreign key (WORKFLOW_ALG_INVOCATION_ID) references @oracle_core@.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);
alter table @oracle_core@.WORKFLOWSTATUS add constraint WORKFLOWSTATUS_FK02 foreign key (WORKFLOW_ID) references @oracle_core@.WORKFLOW (WORKFLOW_ID);
alter table @oracle_core@.WORKFLOWSTATUS add constraint WORKFLOWSTATUS_FK04 foreign key (ITEM_INVOCATION_ID) references @oracle_core@.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);



/* 40 non-primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT


/*                                                                                            */
/* core-pkey-constraints.sql                                                                  */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 03:53:47 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL core-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table @oracle_core@.ALGORITHM add constraint PK_ALGORITHM primary key (ALGORITHM_ID);
alter table @oracle_core@.ALGORITHMIMPLEMENTATION add constraint PK_ALGORITHMIMPLEMENTATION primary key (ALGORITHM_IMPLEMENTATION_ID);
alter table @oracle_core@.ALGORITHMINVOCATION add constraint PK_ALGORITHMINVOCATION primary key (ALGORITHM_INVOCATION_ID);
alter table @oracle_core@.ALGORITHMPARAM add constraint PK_ALGORITHMPARAM primary key (ALGORITHM_PARAM_ID);
alter table @oracle_core@.ALGORITHMPARAMKEY add constraint PK_ALGORITHMPARAMKEY primary key (ALGORITHM_PARAM_KEY_ID);
alter table @oracle_core@.ALGORITHMPARAMKEYTYPE add constraint PK_ALGORITHMPARAMKEYTYPE primary key (ALGORITHM_PARAM_KEY_TYPE_ID);
alter table @oracle_core@.CATEGORY add constraint PK_CATEGORY primary key (CATEGORY_ID);
alter table @oracle_core@.DATABASEDOCUMENTATION add constraint PK_DATABASEDOCUMENTATION primary key (DATABASE_DOCUMENTATION_ID);
alter table @oracle_core@.DATABASEINFO add constraint PK_DATABASEINFO primary key (DATABASE_ID);
alter table @oracle_core@.GENERALDOCUMENTATION add constraint PK_GENERALDOCUMENTATION primary key (GENERAL_DOCUMENTATION_ID);
alter table @oracle_core@.GROUPINFO add constraint PK_GROUPINFO primary key (GROUP_ID);
alter table @oracle_core@.MACHINE add constraint PK_MACHINE primary key (MACHINE_ID);
alter table @oracle_core@.PROJECTINFO add constraint PK_PROJECTINFO primary key (PROJECT_ID);
alter table @oracle_core@.TABLECATEGORY add constraint PK_TABLECATEGORY primary key (TABLE_CATEGORY_ID);
alter table @oracle_core@.TABLEINFO add constraint PK_TABLEINFO primary key (TABLE_ID);
alter table @oracle_core@.USERDATABASE add constraint PK_USERDATABASE primary key (USER_DATABASE_ID);
alter table @oracle_core@.USERGROUP add constraint PK_USERGROUP primary key (USER_GROUP_ID);
alter table @oracle_core@.USERINFO add constraint PK_USERINFO primary key (USER_ID);
alter table @oracle_core@.USERPROJECT add constraint PK_USERPROJECT primary key (USER_PROJECT_ID);
alter table @oracle_core@.WORKFLOW add constraint PK_WORKFLOW primary key (WORKFLOW_ID);
alter table @oracle_core@.WORKFLOWBLACKBOARD add constraint PK_WORKFLOWBLACKBOARD primary key (WORKFLOW_BLACKBOARD_ID);
alter table @oracle_core@.WORKFLOWEDGE add constraint PK_WORKFLOWEDGE primary key (WORKFLOW_EDGE_ID);
alter table @oracle_core@.WORKFLOWEDGESQL add constraint PK_WORKFLOWEDGESQL primary key (WORKFLOW_EDGE_SQL_ID);
alter table @oracle_core@.WORKFLOWINIT add constraint PK_WORKFLOWINIT primary key (WORKFLOW_INIT_ID);
alter table @oracle_core@.WORKFLOWNODEIMP add constraint PK_WORKFLOWNODEIMP primary key (WORKFLOW_NODE_ID);
alter table @oracle_core@.WORKFLOWSTATUS add constraint PK_WORKFLOWSTATUS primary key (WORKFLOW_STATUS_ID);


/* 26 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

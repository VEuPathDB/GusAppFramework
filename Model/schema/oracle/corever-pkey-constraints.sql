
/*                                                                                            */
/* corever-pkey-constraints.sql                                                               */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 12:22:55 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL corever-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table CoretestVer.ALGORITHMIMPLEMENTATIONVER add constraint PK_ALGORITHMIMPLEMENTATIONVER primary key (ALGORITHM_IMPLEMENTATION_ID,MODIFICATION_DATE);
alter table CoretestVer.ALGORITHMINVOCATIONVER add constraint PK_ALGORITHMINVOCATIONVER primary key (ALGORITHM_INVOCATION_ID,MODIFICATION_DATE);
alter table CoretestVer.ALGORITHMPARAMKEYTYPEVER add constraint PK_ALGORITHMPARAMKEYTYPEVER primary key (ALGORITHM_PARAM_KEY_TYPE_ID,MODIFICATION_DATE);
alter table CoretestVer.ALGORITHMPARAMKEYVER add constraint PK_ALGORITHMPARAMKEYVER primary key (ALGORITHM_PARAM_KEY_ID,MODIFICATION_DATE);
alter table CoretestVer.ALGORITHMPARAMVER add constraint PK_ALGORITHMPARAMVER primary key (ALGORITHM_PARAM_ID,MODIFICATION_DATE);
alter table CoretestVer.ALGORITHMVER add constraint PK_ALGORITHMVER primary key (ALGORITHM_ID,MODIFICATION_DATE);
alter table CoretestVer.CATEGORYVER add constraint PK_CATEGORYVER primary key (CATEGORY_ID,MODIFICATION_DATE);
alter table CoretestVer.DATABASEDOCUMENTATIONVER add constraint PK_DATABASEDOCUMENTATIONVER primary key (DATABASE_DOCUMENTATION_ID,MODIFICATION_DATE);
alter table CoretestVer.GENERALDOCUMENTATIONVER add constraint PK_GENERALDOCUMENTATIONVER primary key (GENERAL_DOCUMENTATION_ID,MODIFICATION_DATE);
alter table CoretestVer.MACHINEVER add constraint PK_MACHINEVER primary key (MACHINE_ID,MODIFICATION_DATE);
alter table CoretestVer.TABLECATEGORYVER add constraint PK_TABLECATEGORYVER primary key (TABLE_CATEGORY_ID,MODIFICATION_DATE);
alter table CoretestVer.USERDATABASEVER add constraint PK_USERDATABASEVER primary key (USER_DATABASE_ID,MODIFICATION_DATE);
alter table CoretestVer.USERGROUPVER add constraint PK_USERGROUPVER primary key (USER_GROUP_ID,MODIFICATION_DATE);
alter table CoretestVer.USERPROJECTVER add constraint PK_USERPROJECTVER primary key (USER_PROJECT_ID,MODIFICATION_DATE);
alter table CoretestVer.WORKFLOWBLACKBOARDVER add constraint PK_WORKFLOWBLACKBOARDVER primary key (WORKFLOW_BLACKBOARD_ID,MODIFICATION_DATE);
alter table CoretestVer.WORKFLOWEDGESQLVER add constraint PK_WORKFLOWEDGESQLVER primary key (WORKFLOW_EDGE_SQL_ID,MODIFICATION_DATE);
alter table CoretestVer.WORKFLOWEDGEVER add constraint PK_WORKFLOWEDGEVER primary key (WORKFLOW_EDGE_ID,MODIFICATION_DATE);
alter table CoretestVer.WORKFLOWINITVER add constraint PK_WORKFLOWINITVER primary key (WORKFLOW_INIT_ID,MODIFICATION_DATE);
alter table CoretestVer.WORKFLOWNODEIMPVER add constraint PK_WORKFLOWNODEIMPVER primary key (WORKFLOW_NODE_ID,MODIFICATION_DATE);
alter table CoretestVer.WORKFLOWSTATUSVER add constraint PK_WORKFLOWSTATUSVER primary key (WORKFLOW_STATUS_ID,MODIFICATION_DATE);
alter table CoretestVer.WORKFLOWVER add constraint PK_WORKFLOWVER primary key (WORKFLOW_ID,MODIFICATION_DATE);


/* 21 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT


/*                                                                                            */
/* core-constraints.sql                                                                       */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 12:22:42 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL core-constraints.log

/* NON-PRIMARY KEY CONSTRAINTS */

/* ALGORITHM */

/* ALGORITHMIMPLEMENTATION */
alter table Coretest.ALGORITHMIMPLEMENTATION add constraint ALGORITHMIMPLEMENTATION_FK04 foreign key (ALGORITHM_ID) references Coretest.ALGORITHM (ALGORITHM_ID);

/* ALGORITHMINVOCATION */
alter table Coretest.ALGORITHMINVOCATION add constraint ALGORITHMINVOCATION_FK04 foreign key (MACHINE_ID) references Coretest.MACHINE (MACHINE_ID);
alter table Coretest.ALGORITHMINVOCATION add constraint ALGORITHMINVOCATION_FK06 foreign key (ALGORITHM_IMPLEMENTATION_ID) references Coretest.ALGORITHMIMPLEMENTATION (ALGORITHM_IMPLEMENTATION_ID);

/* ALGORITHMPARAM */
alter table Coretest.ALGORITHMPARAM add constraint ALGORITHMPARAM_FK05 foreign key (ALGORITHM_PARAM_KEY_ID) references Coretest.ALGORITHMPARAMKEY (ALGORITHM_PARAM_KEY_ID);
alter table Coretest.ALGORITHMPARAM add constraint ALGORITHMPARAM_FK06 foreign key (ALGORITHM_INVOCATION_ID) references Coretest.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);

/* ALGORITHMPARAMKEY */
alter table Coretest.ALGORITHMPARAMKEY add constraint ALGORITHMPARAMKEY_FK05 foreign key (ALGORITHM_IMPLEMENTATION_ID) references Coretest.ALGORITHMIMPLEMENTATION (ALGORITHM_IMPLEMENTATION_ID);
alter table Coretest.ALGORITHMPARAMKEY add constraint ALGORITHMPARAMKEY_FK06 foreign key (ALGORITHM_PARAM_KEY_TYPE_ID) references Coretest.ALGORITHMPARAMKEYTYPE (ALGORITHM_PARAM_KEY_TYPE_ID);

/* ALGORITHMPARAMKEYTYPE */

/* CATEGORY */

/* DATABASEDOCUMENTATION */
alter table Coretest.DATABASEDOCUMENTATION add constraint DATABASEDOCUMENTATION_FK01 foreign key (TABLE_ID) references Coretest.TABLEINFO (TABLE_ID);

/* DATABASEINFO */

/* GENERALDOCUMENTATION */

/* GROUPINFO */

/* MACHINE */

/* PROJECTINFO */

/* TABLECATEGORY */
alter table Coretest.TABLECATEGORY add constraint TABLECATEGORY_FK02 foreign key (CATEGORY_ID) references Coretest.CATEGORY (CATEGORY_ID);
alter table Coretest.TABLECATEGORY add constraint TABLECATEGORY_FK03 foreign key (TABLE_ID) references Coretest.TABLEINFO (TABLE_ID);

/* TABLEINFO */
alter table Coretest.TABLEINFO add constraint TABLEINFO_FK01 foreign key (DATABASE_ID) references Coretest.DATABASEINFO (DATABASE_ID);
alter table Coretest.TABLEINFO add constraint TABLEINFO_FK02 foreign key (VIEW_ON_TABLE_ID) references Coretest.TABLEINFO (TABLE_ID);
alter table Coretest.TABLEINFO add constraint TABLEINFO_FK03 foreign key (SUPERCLASS_TABLE_ID) references Coretest.TABLEINFO (TABLE_ID);

/* USERDATABASE */
alter table Coretest.USERDATABASE add constraint USERDATABASE_FK05 foreign key (USER_ID) references Coretest.USERINFO (USER_ID);
alter table Coretest.USERDATABASE add constraint USERDATABASE_FK06 foreign key (DATABASE_ID) references Coretest.DATABASEINFO (DATABASE_ID);

/* USERGROUP */
alter table Coretest.USERGROUP add unique (USER_ID,GROUP_ID);
alter table Coretest.USERGROUP add constraint USERGROUP_FK04 foreign key (USER_ID) references Coretest.USERINFO (USER_ID);
alter table Coretest.USERGROUP add constraint USERGROUP_FK05 foreign key (GROUP_ID) references Coretest.GROUPINFO (GROUP_ID);

/* USERINFO */
alter table Coretest.USERINFO add constraint USERINFO_FK01 foreign key (CONTACT_ID) references SRestest.CONTACT (CONTACT_ID);

/* USERPROJECT */
alter table Coretest.USERPROJECT add unique (USER_ID,PROJECT_ID);
alter table Coretest.USERPROJECT add constraint USERPROJECT_FK05 foreign key (USER_ID) references Coretest.USERINFO (USER_ID);
alter table Coretest.USERPROJECT add constraint USERPROJECT_FK06 foreign key (PROJECT_ID) references Coretest.PROJECTINFO (PROJECT_ID);

/* WORKFLOW */
alter table Coretest.WORKFLOW add constraint WORKFLOW_FK04 foreign key (DEFAULT_ALG_INVOCATION_ID) references Coretest.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);

/* WORKFLOWBLACKBOARD */
alter table Coretest.WORKFLOWBLACKBOARD add constraint WORKFLOWBLACKBOARD_FK01 foreign key (WORKFLOW_ID) references Coretest.WORKFLOW (WORKFLOW_ID);
alter table Coretest.WORKFLOWBLACKBOARD add constraint WORKFLOWBLACKBOARD_FK02 foreign key (WORKFLOW_ALG_INVOCATION_ID) references Coretest.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);
alter table Coretest.WORKFLOWBLACKBOARD add constraint WORKFLOWBLACKBOARD_FK03 foreign key (EDGE_ID) references Coretest.WORKFLOWEDGE (WORKFLOW_EDGE_ID);
alter table Coretest.WORKFLOWBLACKBOARD add constraint WORKFLOWBLACKBOARD_FK04 foreign key (TABLE_ID) references Coretest.TABLEINFO (TABLE_ID);
alter table Coretest.WORKFLOWBLACKBOARD add constraint WORKFLOWBLACKBOARD_FK05 foreign key (SECONDARY_TABLE_ID) references Coretest.TABLEINFO (TABLE_ID);
alter table Coretest.WORKFLOWBLACKBOARD add constraint WORKFLOWBLACKBOARD_FK06 foreign key (EDGE_INVOCATION_ID) references Coretest.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);

/* WORKFLOWEDGE */
alter table Coretest.WORKFLOWEDGE add constraint WORKFLOWEDGE_FK03 foreign key (WORKFLOW_ID) references Coretest.WORKFLOW (WORKFLOW_ID);
alter table Coretest.WORKFLOWEDGE add constraint WORKFLOWEDGE_FK05 foreign key (TO_WORKFLOW_NODE_ID) references Coretest.WORKFLOWNODEIMP (WORKFLOW_NODE_ID);
alter table Coretest.WORKFLOWEDGE add constraint WORKFLOWEDGE_FK06 foreign key (FROM_WORKFLOW_NODE_ID) references Coretest.WORKFLOWNODEIMP (WORKFLOW_NODE_ID);

/* WORKFLOWEDGESQL */
alter table Coretest.WORKFLOWEDGESQL add constraint WORKFLOWEDGESQL_FK04 foreign key (WORKFLOW_EDGE_ID) references Coretest.WORKFLOWEDGE (WORKFLOW_EDGE_ID);

/* WORKFLOWINIT */
alter table Coretest.WORKFLOWINIT add constraint WORKFLOWINIT_FK01 foreign key (WORKFLOW_ID) references Coretest.WORKFLOW (WORKFLOW_ID);
alter table Coretest.WORKFLOWINIT add constraint WORKFLOWINIT_FK02 foreign key (TABLE_ID) references Coretest.TABLEINFO (TABLE_ID);

/* WORKFLOWNODEIMP */
alter table Coretest.WORKFLOWNODEIMP add constraint WORKFLOWNODEIMP_FK03 foreign key (WORKFLOW_ID) references Coretest.WORKFLOW (WORKFLOW_ID);
alter table Coretest.WORKFLOWNODEIMP add constraint WORKFLOWNODEIMP_FK06 foreign key (ALGORITHM_INVOCATION_ID) references Coretest.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);

/* WORKFLOWSTATUS */
alter table Coretest.WORKFLOWSTATUS add constraint WORKFLOWSTATUS_FK01 foreign key (WORKFLOW_ALG_INVOCATION_ID) references Coretest.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);
alter table Coretest.WORKFLOWSTATUS add constraint WORKFLOWSTATUS_FK02 foreign key (WORKFLOW_ID) references Coretest.WORKFLOW (WORKFLOW_ID);
alter table Coretest.WORKFLOWSTATUS add constraint WORKFLOWSTATUS_FK04 foreign key (ITEM_INVOCATION_ID) references Coretest.ALGORITHMINVOCATION (ALGORITHM_INVOCATION_ID);



/* 40 non-primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

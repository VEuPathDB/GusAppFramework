
/*                                                                                            */
/* core-views.sql                                                                             */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 12:22:41 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL core-views.log

CREATE VIEW Coretest.WORKFLOWCONDITIONALNODE
AS SELECT
  workflow_node_id,
  workflow_id,
  subclass_view,
  name,
  description,
  is_start,
  is_and,
  text1 AS SQL,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id 
 FROM WorkflowNodeImp
 WHERE subclass_view = 'WorkflowConditionalNode'
 WITH CHECK OPTION;

CREATE VIEW Coretest.WORKFLOWNOOPNODE
AS SELECT
  workflow_node_id,
  workflow_id,
  subclass_view,
  name,
  description,
  is_start,
  is_and,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id 
 FROM WorkflowNodeImp
 WHERE subclass_view = 'WorkflowNoOpNode'
 WITH CHECK OPTION;

CREATE VIEW Coretest.WORKFLOWPLUGINNODE
AS SELECT
  workflow_node_id,
  workflow_id,
  subclass_view,
  name,
  description,
  is_start,
  is_and,
  algorithm_invocation_id,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id 
 FROM WorkflowNodeImp
 WHERE subclass_view = 'WorkflowPluginNode'
 WITH CHECK OPTION;

CREATE VIEW Coretest.WORKFLOWSYSTEMNODE
AS SELECT
  workflow_node_id,
  workflow_id,
  subclass_view,
  name,
  description,
  is_start,
  is_and,
  vchar1 AS command,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id 
 FROM WorkflowNodeImp
 WHERE subclass_view = 'WorkflowSystemNode'
 WITH CHECK OPTION;


/* 4 view(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

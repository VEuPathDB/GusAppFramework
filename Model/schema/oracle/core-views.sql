
/*                                                                                            */
/* core-views.sql                                                                             */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Feb 17 11:42:42 EST 2004     */
/*                                                                                            */

SET ECHO ON
SPOOL core-views.log

CREATE VIEW @oracle_core@.WORKFLOWCONDITIONALNODE
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

CREATE VIEW @oracle_core@.WORKFLOWNODE
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
 WHERE subclass_view = 'WorkflowNode'
 WITH CHECK OPTION;

CREATE VIEW @oracle_core@.WORKFLOWNOOPNODE
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

CREATE VIEW @oracle_core@.WORKFLOWPLUGINNODE
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

CREATE VIEW @oracle_core@.WORKFLOWSYSTEMNODE
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


/* 5 view(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

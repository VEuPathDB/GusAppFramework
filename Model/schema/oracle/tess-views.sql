
/*                                                                                            */
/* tess-views.sql                                                                             */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Dec  9 16:13:57 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL tess-views.log

CREATE VIEW @oracle_tess@.ACTIVITY
AS SELECT
  activity_id,
  subclass_view,
  type_name,
  go_term_id,
  moiety_id,
  external_database_release_id,
  source_id,
  name,
  review_status_id,
  /* gus overhead */
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
  from TESS.ActivityImp with check option;

CREATE VIEW @oracle_tess@.ACTIVITYGENEREGULATION
AS SELECT
  activity_id,
  subclass_view,
  type_name,
  go_term_id,
  moiety_id,
  external_database_release_id,
  source_id,
  name,
  review_status_id,
  /* gus overhead */
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
  FROM TESS.ActivityImp WHERE subclass_view = 'ActivityGeneRegulation' WITH CHECK OPTION;

CREATE VIEW @oracle_tess@.ACTIVITYPROTEINDNABINDING
AS SELECT
  activity_id,
  subclass_view,
  type_name,
  go_term_id,
  moiety_id,
  external_database_release_id,
  source_id,
  name,
  review_status_id,
  /* gus overhead */
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
  FROM TESS.ActivityImp WHERE subclass_view = 'ActivityProteinDnaBinding' WITH CHECK OPTION;

CREATE VIEW @oracle_tess@.MODEL
( MODEL_ID,
  SUBCLASS_VIEW,
  NAME,
  EXTERNAL_DATABASE_RELEASE_ID,
  SOURCE_ID,
  VERSION_STRING,
  VERSION_DESCRIPTION,
  SECONDARY_ID,
  BEST_PRACTICE_PARAM_GROUP_ID,
  REVIEW_STATUS_ID,
  MODIFICATION_DATE,
  USER_READ,
  USER_WRITE,
  GROUP_READ,
  GROUP_WRITE,
  OTHER_READ,
  OTHER_WRITE,
  ROW_USER_ID,
  ROW_GROUP_ID,
  ROW_PROJECT_ID,
  ROW_ALG_INVOCATION_ID )
AS SElECT
  model_id,
  subclass_view,
  name,
  external_database_release_id,
  source_id,
  version_string,
  version_description,
  secondary_id,
  best_practice_param_group_id,
  review_status_id,
  /* gus overhead */
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
from TESS.ModelImp;

CREATE VIEW @oracle_tess@.MODELMARKOVCHAIN
AS SELECT
  model_id,
  subclass_view,
  name,
  external_database_release_id,
  source_id,
  version_string,
  version_description,
  secondary_id,
  best_practice_param_group_id,
  review_status_id,
  bool1 AS is_variable_order,
  int1 AS maximum_order,
  /* gus overhead */
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
from TESS.ModelImp where subclass_view = 'ModelMarkovChain' with check option;

CREATE VIEW @oracle_tess@.MODELSBCGGRAMMAR
AS SELECT
  model_id,
  subclass_view,
  name,
  external_database_release_id,
  source_id,
  version_string,
  version_description,
  secondary_id,
  best_practice_param_group_id,
  review_status_id,
  /* gus overhead */
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
from TESS.ModelImp where subclass_view = 'ModelSbcgGrammar' with check option;

CREATE VIEW @oracle_tess@.MOIETY
AS SELECT
  moiety_id,
  subclass_view,
  type_name,
  external_database_release_id,
  source_id,
  name,
  taxon_id,
  review_status_id,
  /* gus overhead */
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
from TESS.MoietyImp where subclass_view = 'TESS::Moiety' with check option;

CREATE VIEW @oracle_tess@.MOIETYCOMPLEX
AS SELECT
  moiety_id,
  subclass_view,
  type_name,
  external_database_release_id,
  source_id,
  name,
  taxon_id,
  review_status_id,
  int1 AS number_of_members,
  /* gus overhead */
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
from TESS.MoietyImp where subclass_view = 'TESS::MoietyComplex' with check option;

CREATE VIEW @oracle_tess@.MOIETYHETERODIMER
AS SELECT
  moiety_id,
  subclass_view,
  type_name,
  external_database_release_id,
  source_id,
  name,
  taxon_id,
  review_status_id,
  /* gus overhead */
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
from TESS.MoietyImp where subclass_view = 'TESS::MoietyHeteroDimer' with check option;

CREATE VIEW @oracle_tess@.MOIETYMONOMER
AS SELECT
  moiety_id,
  subclass_view,
  type_name,
  external_database_release_id,
  source_id,
  name,
  taxon_id,
  review_status_id,
  /* gus overhead */
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
from TESS.MoietyImp where subclass_view = 'TESS::MoietyMonomer' with check option;

CREATE VIEW @oracle_tess@.MOIETYMULTIMER
AS SELECT
  moiety_id,
  subclass_view,
  type_name,
  external_database_release_id,
  source_id,
  name,
  taxon_id,
  review_status_id,
  int1 AS multiplicty,
  /* gus overhead */
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
from TESS.MoietyImp where subclass_view = 'TESS::MoietyMultimer' with check option;

CREATE VIEW @oracle_tess@.SBCGRECOGCONSENSUSSTRING
AS SELECT
  sbcg_recognition_id,
  subclass_view,
  model_id,
  string1 AS value,
  int1 AS mismatches_allowed,
  /* gus overhead */
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
from TESS.SbcgRecognitionImp where subclass_view = 'SbcgRecogConsensusString' with check option;

CREATE VIEW @oracle_tess@.SBCGRECOGGAP
AS SELECT
  sbcg_recognition_id,
  subclass_view,
  model_id,
  /* gus overhead */
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
from TESS.SbcgRecognitionImp where subclass_view = 'SbcgRecogGap' with check option;

CREATE VIEW @oracle_tess@.SBCGRECOGNITION
( SBCG_RECOGNITION_ID,
  SUBCLASS_VIEW,
  MODEL_ID,
  MODIFICATION_DATE,
  USER_READ,
  USER_WRITE,
  GROUP_READ,
  GROUP_WRITE,
  OTHER_READ,
  OTHER_WRITE,
  ROW_USER_ID,
  ROW_GROUP_ID,
  ROW_PROJECT_ID,
  ROW_ALG_INVOCATION_ID )
AS select
  sbcg_recognition_id,
  subclass_view,
  model_id
  ,
    /* GUS overhead */
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
from TESS.SbcgRecognitionImp;

CREATE VIEW @oracle_tess@.SBCGRECOGPATHEXPRESSION
AS SELECT
  sbcg_recognition_id,
  subclass_view,
  model_id,
  int1 AS length,
  boolean1 AS anchor_point_begin,
  boolean2 AS anchor_point_center,
  boolean3 AS anchor_point_end,
  /* gus overhead */
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
From TESS.SbcgRecognitionImp where subclass_view = 'SbcgRecogPathExpression' with check option;

CREATE VIEW @oracle_tess@.SBCGRECOGPOSITION
AS SELECT
  sbcg_recognition_id,
  subclass_view,
  model_id,
  boolean1 AS is_relative,
  int1 AS value,
  /* gus overhead */
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
from TESS.SbcgRecognitionImp where subclass_view = 'SbcgRecogPosition' with check option;

CREATE VIEW @oracle_tess@.SBCGRECOGSTRING
AS SELECT
  sbcg_recognition_id,
  subclass_view,
  model_id,
  string1 AS value,
  int1 AS mismatches_allowed,
  /* gus overhead */
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
from TESS.SbcgRecognitionImp where subclass_view = 'SbcgRecogString' with check option;

CREATE VIEW @oracle_tess@.SBCGRECOGWEIGHTMATRIX
AS SELECT
  sbcg_recognition_id,
  subclass_view,
  model_id,
  int1 AS length,
  int1 AS width,
  float1 AS total_information,
  float2 AS average_information,
  float3 AS maximum_observations,
  float4 AS minimum_observations,
  /* gus overhead */
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
from TESS.SbcgRecognitionImp where subclass_view = 'SbcgRecogWeightMatrix' with check option;


/* 18 view(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

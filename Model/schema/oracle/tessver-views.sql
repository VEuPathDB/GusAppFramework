
/*                                                                                            */
/* tessver-views.sql                                                                          */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 12:29:22 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL tessver-views.log

CREATE VIEW TESStestVer.ACTIVITYGENEREGULATIONVER
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
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
  from TESSVer.ActivityImpVer WHERE subclass_view = 'ActivityGeneRegulation' WITH CHECK OPTION;

CREATE VIEW TESStestVer.ACTIVITYPROTEINDNABINDINGVER
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
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
  from TESSVer.ActivityImpVer WHERE subclass_view = 'ActivityProteinDnaBinding' WITH CHECK OPTION;

CREATE VIEW TESStestVer.ACTIVITYVER
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
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
  from TESSVer.ActivityImpVer with check option;

CREATE VIEW TESStestVer.MOIETYCOMPLEXVER
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
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
from TESSVer.MoietyImpVer where subclass_view = 'TESS::MoietyComplex' with check option;

CREATE VIEW TESStestVer.MOIETYHETERODIMERVER
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
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
from TESSVer.MoietyImpVer where subclass_view = 'TESS::MoietyHeteroDimer' with check option;

CREATE VIEW TESStestVer.MOIETYMONOMERVER
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
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
from TESSVer.MoietyImpVer where subclass_view = 'TESS::MoietyMonomer' with check option;

CREATE VIEW TESStestVer.MOIETYMULTIMERVER
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
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
from TESSVer.MoietyImpVer where subclass_view = 'TESS::MoietyMultimer' with check option;

CREATE VIEW TESStestVer.MOIETYVER
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
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
from TESSVer.MoietyImpVer where subclass_view = 'TESS::Moiety' with check option;

CREATE VIEW TESStestVer.SBCGRECOGCONSENSUSSTRINGVER
AS SELECT
  sbcg_recognition_id,
  subclass_view,
  sbcg_grammar_id,
  string1 AS value,
  int1 AS mismatches_allowed,
  /* gus overhead */
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
from TESSVer.SbcgRecognitionImpVer where subclass_view = 'SbcgRecogConsensusString' with check option;

CREATE VIEW TESStestVer.SBCGRECOGGAPVER
AS SELECT
  sbcg_recognition_id,
  subclass_view,
  sbcg_grammar_id,
  /* gus overhead */
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
from TESSVer.SbcgRecognitionImpVer where subclass_view = 'SbcgRecogGap' with check option;

CREATE VIEW TESStestVer.SBCGRECOGNITIONVER
( SBCG_RECOGNITION_ID,
  SUBCLASS_VIEW,
  SBCG_GRAMMAR_ID,
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
  ROW_ALG_INVOCATION_ID,
  VERSION_ALG_INVOCATION_ID,
  VERSION_DATE,
  VERSION_TRANSACTION_ID )
AS select
  sbcg_recognition_id,
  subclass_view,
  sbcg_grammar_id
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
  ,
    /* version tracking */
        version_alg_invocation_id,
        version_date,
        version_transaction_id
from TESSVer.SbcgRecognitionImpVer;

CREATE VIEW TESStestVer.SBCGRECOGPATHEXPRESSIONVER
AS SELECT
  sbcg_recognition_id,
  subclass_view,
  sbcg_grammar_id,
  int1 AS length,
  boolean1 AS anchor_point_begin,
  boolean2 AS anchor_point_center,
  boolean3 AS anchor_point_end,
  /* gus overhead */
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
from TESSVer.SbcgRecognitionImpVer where subclass_view = 'SbcgRecogPathExpression' with check option;

CREATE VIEW TESStestVer.SBCGRECOGPOSITIONVER
AS SELECT
  sbcg_recognition_id,
  subclass_view,
  sbcg_grammar_id,
  boolean1 AS is_relative,
  int1 AS value,
  /* gus overhead */
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
from TESSVer.SbcgRecognitionImpVer where subclass_view = 'SbcgRecogPosition' with check option;

CREATE VIEW TESStestVer.SBCGRECOGSTRINGVER
AS SELECT
  sbcg_recognition_id,
  subclass_view,
  sbcg_grammar_id,
  string1 AS value,
  int1 AS mismatches_allowed,
  /* gus overhead */
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
from TESSVer.SbcgRecognitionImpVer where subclass_view = 'SbcgRecogString' with check option;

CREATE VIEW TESStestVer.SBCGRECOGWEIGHTMATRIXVER
AS SELECT
  sbcg_recognition_id,
  subclass_view,
  sbcg_grammar_id,
  int1 AS length,
  int1 AS width,
  float1 AS total_information,
  float2 AS average_information,
  float3 AS maximum_observations,
  float4 AS minimum_observations,
  /* gus overhead */
        modification_date AS modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id,
  /* version tracking */
        version_alg_invocation_id AS version_alg_invocation_id,
  version_date,
  version_transaction_id 
from TESSVer.SbcgRecognitionImpVer where subclass_view = 'SbcgRecogWeightMatrix' with check option;


/* 15 view(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

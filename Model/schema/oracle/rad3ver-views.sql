
/*                                                                                            */
/* rad3ver-views.sql                                                                          */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Thu Feb 13 13:30:36 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL rad3ver-views.log

CREATE VIEW @oracle_rad3ver@.AFFYMETRIXCELVER
AS SELECT
  element_result_id,
  element_id,
  composite_element_result_id,
  quantification_id,
  subclass_view,
  foreground AS mean,
  float1 AS stdv,
  int3 AS npixels,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM ElementResultImpVer
WHERE subclass_view = 'AffymetrixCEL'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.AFFYMETRIXMAS4VER
AS SELECT
  composite_element_result_id,
  composite_element_id,
  quantification_id,
  subclass_view,
  tinyint1 AS positive_probe_pairs,
  tinyint2 AS negative_probe_pairs,
  tinyint3 AS num_probe_pairs_used,
  smallint1 AS pairs_in_average,
  float1 AS log_average_ratio,
  float2 AS average_difference,
  string1 AS absolute_call,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM CompositeElementResultImpVer
WHERE subclass_view = 'AffymetrixMAS4'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.AFFYMETRIXMAS5VER
AS SELECT
  composite_element_result_id,
  subclass_view,
  composite_element_id,
  quantification_id,
  float1 AS signal,
  char1 AS detection,
  float2 AS detection_p_value,
  smallint1 AS stat_pairs,
  smallint2 AS stat_pairs_used,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM CompositeElementResultImpVer
WHERE SUBCLASS_VIEW = 'AffymetrixMAS5'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.ARRAYVISIONELEMENTRESULTVER
AS SELECT
  element_result_id,
  subclass_view,
  element_id,
  composite_element_result_id,
  quantification_id,
  foreground,
  background,
  foreground_sd AS sd,
  float1 AS mad,
  float2 AS signal_to_noise,
  float3 AS percent_removed,
  float4 AS percent_replaced,
  float5 AS percent_at_floor,
  float6 AS percent_at_ceiling,
  float7 AS bkg_percent_at_floor,
  float8 AS bkg_percent_at_ceiling,
  tinystring1 AS x,
  tinystring2 AS y,
  tinystring3 AS area,
  tinyint1 AS flag,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM ElementResultImpVer
WHERE subclass_view = 'ArrayVisionElementResult'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.BIOMATERIALVER
AS SELECT
  bio_material_id,
  subclass_view,
  bio_material_type_id,
  external_database_release_id,
  source_id,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM BioMaterialImpVer
WHERE subclass_view = 'BioMaterial'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.BIOSAMPLEVER
AS SELECT
  bio_material_id,
  subclass_view,
  bio_material_type_id,
  external_database_release_id,
  source_id,
  string1 AS name,
  string2 AS description,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM BioMaterialImpVer
WHERE subclass_view = 'BioSample'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.BIOSOURCEVER
( BIO_MATERIAL_ID,
  SUBCLASS_VIEW,
  TAXON_ID,
  BIO_MATERIAL_TYPE_ID,
  BIO_SOURCE_PROVIDER_ID,
  EXTERNAL_DATABASE_RELEASE_ID,
  SOURCE_ID,
  NAME,
  DESCRIPTION,
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
AS SELECT
  bio_material_id,
  subclass_view,
  taxon_id,
  bio_material_type_id,
  bio_source_provider_id,
  external_database_release_id,
  source_id,
  string1 AS name,
  string2 AS description,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id
FROM BioMaterialImpVer
WHERE bio_source_provider_id is not null
AND subclass_view='BioSource'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.COMPOSITEELEMENTRESULTVER
AS SELECT
  composite_element_result_id,
  subclass_view,
  composite_element_id,
  quantification_id,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM CompositeElementResultImpVer
WHERE subclass_view = 'CompositeElementResult'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.COMPOSITEELEMENTVER
AS SELECT
  composite_element_id,
  subclass_view,
  parent_id,
  array_id,
  external_database_release_id,
  source_id,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM CompositeElementImpVer
where subclass_view = 'CompositeElement'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.ELEMENTRESULTVER
AS SELECT
  element_result_id,
  subclass_view,
  element_id,
  composite_element_result_id,
  quantification_id,
  foreground,
  background,
  foreground_sd,
  background_sd,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM ElementResultImpVer
WHERE subclass_view = 'ElementResult'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.ELEMENTVER
AS SELECT
  element_id,
  subclass_view,
  element_type_id,
  composite_element_id,
  array_id,
  external_database_release_id,
  source_id,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM ElementImpVer
WHERE subclass_view = 'Element'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.GEMTOOLSELEMENTRESULTVER
AS SELECT
  element_result_id,
  element_id,
  composite_element_result_id,
  quantification_id,
  subclass_view,
  float1 AS signal,
  float2 AS signal_to_background,
  float3 AS area_percentage,
  tinyint1 AS visual_flag,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM ElementResultImpVer WHERE subclass_view = 'GEMToolsElementResult'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.GENEPIXELEMENTRESULTVER
AS SELECT
  element_result_id,
  element_id,
  composite_element_result_id,
  quantification_id,
  subclass_view,
  foreground_sd,
  background_sd,
  float1 AS spot_diameter,
  float2 AS foreground_mean,
  float3 AS foreground_median,
  float4 AS background_mean,
  float5 AS background_median,
  float6 AS percent_over_bg_plus_one_sd,
  float7 AS percent_over_bg_plus_two_sds,
  float8 AS percent_foreground_saturated,
  float9 AS mean_of_ratios,
  float10 AS median_of_ratios,
  float11 AS ratios_sd,
  smallint1 AS num_foreground_pixels,
  smallint2 AS num_background_pixels,
  tinyint1 AS flag,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM ElementResultImpVer
WHERE subclass_view = 'GenePixElementResult'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.LABELEDEXTRACTVER
( BIO_MATERIAL_ID,
  SUBCLASS_VIEW,
  BIO_MATERIAL_TYPE_ID,
  LABEL_METHOD_ID,
  EXTERNAL_DATABASE_RELEASE_ID,
  SOURCE_ID,
  NAME,
  DESCRIPTION,
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
AS SELECT
  bio_material_id,
  subclass_view,
  bio_material_type_id,
  label_method_id,
  external_database_release_id,
  source_id,
  string1 AS name,
  string2 AS description,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id
FROM BioMaterialImpVer
WHERE LABEL_METHOD_ID is not null
AND SUBCLASS_VIEW = 'LabeledExtract'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.MOIDRESULTVER
AS SELECT
  composite_element_result_id,
  composite_element_id,
  quantification_id,
  subclass_view,
  float1 AS expression,
  float2 AS lower_bound,
  float3 AS upper_bound,
  float4 AS log_p,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM CompositeElementResultImpVer
WHERE subclass_view = 'MOIDResult'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.SAGETAGMAPPINGVER
AS SELECT
  element_id,
  subclass_view,
  array_id,
  composite_element_id,
  external_database_release_id,
  source_id,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM ElementImpVer
WHERE subclass_view = 'SAGETagMapping'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.SAGETAGRESULTVER
AS SELECT
  composite_element_result_id,
  composite_element_id,
  quantification_id,
  subclass_view,
  int1 AS tag_count,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM CompositeElementResultImpVer
WHERE subclass_view = 'SAGETagResult'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.SAGETAGVER
AS SELECT
  composite_element_id,
  subclass_view,
  parent_id,
  array_id,
  tinystring1 AS tag,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM CompositeElementImpVer
WHERE subclass_view = 'SAGETag'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.SCANALYZEELEMENTRESULTVER
AS SELECT
  element_result_id,
  element_id,
  composite_element_result_id,
  quantification_id,
  subclass_view,
  foreground AS i,
  background AS b,
  float1 AS ba,
  int1 AS spix,
  int2 AS bgpix,
  int3 AS top,
  int4 AS left,
  int5 AS bot,
  int6 AS right,
  tinyint1 AS flag,
  float2 AS mrat,
  float3 AS regr,
  float4 AS corr,
  float5 AS lfrat,
  float6 AS gtb1,
  float7 AS gtb2,
  float8 AS edgea,
  float9 AS ksd,
  float10 AS ksp,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM ElementResultImpVer
WHERE subclass_view = 'ScanAlyzeElementResult'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.SHORTOLIGOFAMILYVER
AS SELECT
  composite_element_id,
  subclass_view,
  parent_id,
  array_id,
  external_database_release_id,
  source_id,
  smallstring1 AS name,
  string1 AS description,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM CompositeElementImpVer
WHERE subclass_view = 'ShortOligoFamily'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.SHORTOLIGOVER
AS SELECT
  element_id,
  subclass_view,
  array_id,
  composite_element_id,
  smallstring2 AS name,
  tinystring1 AS x_position,
  tinystring2 AS y_position,
  smallstring1 AS sequence,
  string1 AS description,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM ElementImpVer
WHERE subclass_view = 'ShortOligo'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.SPOTELEMENTRESULTVER
AS SELECT
  element_result_id,
  element_id,
  composite_element_result_id,
  quantification_id,
  subclass_view,
  foreground AS median,
  background AS morph,
  foreground_sd AS iqr,
  float1 AS mean,
  float2 AS bg_median,
  float3 AS bg_mean,
  float4 AS bg_sd,
  float5 AS valley,
  float6 AS morph_erode,
  float7 AS morph_close_open,
  int1 AS area,
  int2 AS perimeter,
  float8 AS circularity,
  tinyint1 AS badspot,
  tinyint2 AS visual_flag,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM ElementResultImpVer
WHERE subclass_view = 'SpotElementResult'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.SPOTFAMILYVER
AS SELECT
  composite_element_id,
  subclass_view,
  parent_id,
  array_id,
  external_database_release_id,
  source_id,
  smallstring1 AS plate_name,
  smallstring2 AS well_location,
  tinyint1 AS pcr_failure_flag,
  string2 AS name,
  string1 AS description,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM CompositeElementImpVer
WHERE subclass_view = 'SpotFamily'
WITH CHECK OPTION;

CREATE VIEW @oracle_rad3ver@.SPOTVER
AS SELECT
  element_id,
  subclass_view,
  array_id,
  element_type_id,
  composite_element_id,
  external_database_release_id,
  source_id,
  char1 AS array_row,
  char2 AS array_column,
  char3 AS grid_row,
  char4 AS grid_column,
  char5 AS sub_row,
  char6 AS sub_column,
  tinyint1 AS sequence_verified,
  tinystring1 AS name,
  string1 AS description,
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
  row_alg_invocation_id,
  version_alg_invocation_id,
  version_date,
  version_transaction_id 
FROM ElementImpVer
WHERE subclass_view = 'Spot'
WITH CHECK OPTION;


/* 24 view(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

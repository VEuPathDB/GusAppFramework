
/*                                                                                            */
/* dots-views.sql                                                                             */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 20:45:49 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL dots-views.log

CREATE VIEW @oracle_dots@.AAFEATURE
AS SELECT
  aa_feature_id,
  aa_sequence_id,
  feature_name_id,
  subclass_view,
  sequence_ontology_id,
  description,
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
 FROM AAFeatureImp
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.AAORTHOLOGEXPERIMENT
AS SELECT
  aa_seq_group_experiment_id,
  subclass_view,
  description,
  sequence_source,
  pvalue_mant,
  pvalue_exp,
  percent_identity,
  percent_match,
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
FROM AASeqGroupExperimentImp
WHERE subclass_view = 'AAOrthologExperiment'
WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.AAORTHOLOGGROUP
AS SELECT
  aa_sequence_group_id,
  subclass_view,
  name,
  description,
  number_of_members,
  max_score,
  min_score,
  max_match_identity,
  min_match_identity,
  max_match_length,
  min_match_length,
  max_pvalue_mant,
  max_pvalue_exp,
  min_pvalue_mant,
  min_pvalue_exp,
  aa_seq_group_experiment_id,
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
FROM AASequenceGroupImp
WHERE subclass_view = 'AAOrthologGroup'
WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.AAPARALOGEXPERIMENT
AS SELECT
  aa_seq_group_experiment_id,
  subclass_view,
  description,
  sequence_source,
  pvalue_mant,
  pvalue_exp,
  percent_identity,
  percent_match,
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
FROM AASeqGroupExperimentImp
WHERE subclass_view = 'AAParalogExperiment'
WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.AAPARALOGGROUP
AS SELECT
  aa_sequence_group_id,
  subclass_view,
  name,
  description,
  number_of_members,
  max_score,
  min_score,
  max_match_identity,
  min_match_identity,
  max_match_length,
  min_match_length,
  max_pvalue_mant,
  max_pvalue_exp,
  min_pvalue_mant,
  min_pvalue_exp,
  aa_seq_group_experiment_id,
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
FROM AASequenceGroupImp
WHERE subclass_view = 'AAParalogGroup'
WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.AASEQGROUPEXPERIMENT
AS SELECT
  aa_seq_group_experiment_id,
  description,
  sequence_source,
  pvalue_mant,
  pvalue_exp,
  percent_identity,
  percent_match,
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
FROM AASeqGroupExperimentImp
WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.AASEQUENCE
AS SELECT
  aa_sequence_id,
  sequence_version,
  subclass_view,
  molecular_weight,
  sequence,
  length,
  description,
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
 FROM AASequenceImp
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.AASEQUENCEGROUP
AS SELECT
  aa_sequence_group_id,
  name,
  description,
  number_of_members,
  max_match_identity,
  min_match_identity,
  max_match_length,
  min_match_length,
  max_pvalue_mant,
  max_pvalue_exp,
  min_pvalue_mant,
  min_pvalue_exp,
  max_score,
  min_score,
  aa_seq_group_experiment_id,
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
FROM AASequenceGroupImp
WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.ALLELEFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  parent_id,
  name,
  string20 AS description,
  review_status_id,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'AlleleFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.ASSEMBLY
AS SELECT
  na_sequence_id,
  sequence_version,
  sequence_type_id,
  taxon_id,
  sequence,
  tinyint1 AS full_length_cds,
  source_na_sequence_id AS ASSEMBLY_CONSISTENCY,
  bit1 AS CONTAINS_MRNA,
  int1 AS NUMBER_OF_CONTAINED_SEQUENCES,
  string1 AS NOTES,
  length,
  a_count,
  c_count,
  g_count,
  t_count,
  other_count,
  description,
  subclass_view,
  clob1 AS GAPPED_CONSENSUS,
  clob2 AS QUALITY_VALUES,
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
 FROM NASequenceImp
 WHERE subclass_view = 'Assembly'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.BINDINGSITEFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  source_id,
  external_database_release_id,
  prediction_algorithm_id,
  is_predicted,
  review_status_id,
  string2 AS MODEL,
  int1 AS MODEL_ID,
  float1 AS PRIMARY_SCORE,
  float2 AS SECONDARY_SCORE,
  string1 AS SYNDROME,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'BindingSiteFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.CHROMOSOMEELEMENTFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  parent_id,
  name,
  string1 AS description,
  source_id,
  external_database_release_id,
  prediction_algorithm_id,
  review_status_id,
  int1 AS length,
  string2 AS chromosome_end,
  float1 AS percent_at,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'ChromosomeElementFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.COLLECTIONNAFEATURE
AS SELECT
  na_feature_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  source_id,
  external_database_release_id,
  prediction_algorithm_id,
  is_predicted,
  review_status_id,
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
  FROM NAFeatureImp
  WHERE subclass_view = 'CollectionNaFeature'
  WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.DNAREGULATORY
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  string1 AS CITATION,
  string2 AS EVIDENCE,
  string3 AS FUNCTION,
  string4 AS GENE,
  string5 AS LABEL,
  string6 AS MAP,
  string7 AS PARTIAL,
  string8 AS PHENOTYPE,
  string9 AS STANDARD_NAME,
  string10 AS USEDIN,
  tinyint1 AS IS_PARTIAL,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'DNARegulatory'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.DNASTRUCTURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  string1 AS CITATION,
  string2 AS DIRECTION,
  string3 AS EVIDENCE,
  string4 AS FUNCTION,
  string5 AS GENE,
  string6 AS LABEL,
  string7 AS MAP,
  string8 AS PARTIAL,
  string9 AS PCR_CONDITIONS,
  string10 AS STANDARD_NAME,
  string11 AS USEDIN,
  tinyint1 AS IS_PARTIAL,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'DNAStructure'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.DOMAINFEATURE
AS SELECT
  aa_feature_id,
  aa_sequence_id,
  subclass_view,
  sequence_ontology_id,
  string1 AS NAME,
  description,
  prediction_algorithm_id,
  string2 AS ALGORITHM_NAME,
  float1 AS SCORE,
  float2 AS E_VALUE,
  float3 AS PROBABILITY,
  int1 AS number_of_domains,
  pfam_entry_id,
  motif_aa_sequence_id,
  is_predicted,
  review_status_id,
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
  row_alg_invocation_id 
 FROM AAFeatureImp
 WHERE subclass_view = 'DomainFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.EXONFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  source_id,
  external_database_release_id,
  prediction_algorithm_id,
  is_predicted,
  review_status_id,
  tinyint1 AS IS_ONE_OF,
  tinyint2 AS IS_OPTIONAL,
  int1 AS ORDER_NUMBER,
  string1 AS VERSION,
  tinyint3 AS NUMBER_OF_ALTERNATES,
  tinyint4 AS IS_INITIAL_EXON,
  tinyint5 AS IS_FINAL_EXON,
  int4 AS IS_MERGED_EXON,
  int2 AS CODING_START,
  int3 AS CODING_END,
  tinyint6 AS READING_FRAME,
  float1 AS SCORE,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'ExonFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.EXTERNALAASEQUENCE
AS SELECT
  aa_sequence_id,
  subclass_view,
  molecular_weight,
  sequence,
  length,
  description,
  external_database_release_id,
  source_id,
  string1 AS SECONDARY_IDENTIFIER,
  string2 AS NAME,
  string3 AS MOLECULE_TYPE,
  string4 AS CRC32_VALUE,
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
 FROM AASequenceImp
 WHERE subclass_view = 'ExternalAASequence'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.EXTERNALNASEQUENCE
AS SELECT
  na_sequence_id,
  sequence_version,
  sequence_type_id,
  external_database_release_id,
  string1 AS SOURCE_ID,
  string2 AS SECONDARY_IDENTIFIER,
  string3 AS NAME,
  taxon_id,
  sequence,
  length,
  a_count,
  c_count,
  g_count,
  t_count,
  other_count,
  description,
  string4 AS CHROMOSOME,
  int1 AS CHROMOSOME_ORDER_NUM,
  subclass_view,
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
 FROM NASequenceImp
 WHERE subclass_view = 'ExternalNASequence'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.GENEFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  source_id,
  external_database_release_id,
  prediction_algorithm_id,
  is_predicted,
  review_status_id,
  string14 AS GENE_TYPE,
  tinyint2 AS CONFIRMED_BY_SIMILARITY,
  int1 AS PREDICTION_NUMBER,
  int2 AS NUMBER_OF_EXONS,
  tinyint3 AS HAS_INITIAL_EXON,
  tinyint4 AS HAS_FINAL_EXON,
  float1 AS SCORE,
  float2 AS SECONDARY_SCORE,
  tinyint5 AS IS_PSEUDO,
  tinyint6 AS IS_PARTIAL,
  string1 AS ALLELE,
  string2 AS CITATION,
  string3 AS EVIDENCE,
  string4 AS FUNCTION,
  string5 AS GENE,
  string6 AS LABEL,
  string7 AS MAP,
  string9 AS PHENOTYPE,
  string10 AS PRODUCT,
  string12 AS STANDARD_NAME,
  string13 AS USEDIN,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'GeneFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.GENOMICSEQUENCE
AS SELECT
  na_sequence_id,
  sequence_version,
  sequence_type_id,
  sequencing_center_contact_id,
  external_database_release_id,
  string1 AS SOURCE_ID,
  string3 AS NAME,
  taxon_id,
  sequence,
  length,
  a_count,
  c_count,
  g_count,
  t_count,
  other_count,
  description,
  string4 AS CHROMOSOME,
  int1 AS CHROMOSOME_ORDER_NUM,
  subclass_view,
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
 FROM NASequenceImp
 WHERE subclass_view = 'GenomicSequence'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.HEXAMERFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  float1 AS score,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'HexamerFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.IMMUNOGLOBULIN
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  string1 AS CITATION,
  string7 AS CODON,
  int1 AS CODON_START,
  string2 AS EVIDENCE,
  string3 AS GENE,
  string4 AS LABEL,
  string5 AS MAP,
  string6 AS PARTIAL,
  string8 AS PRODUCT,
  string9 AS PSEUDO,
  string10 AS TRANSL_EXCEPT,
  text1 AS TRANSLATION,
  int2 AS TRANSL_TABLE,
  string11 AS STANDARD_NAME,
  string12 AS USEDIN,
  tinyint1 AS IS_PARTIAL,
  tinyint2 AS IS_PSEUDO,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'Immunoglobulin'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.INFLECTIONPOINTFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  parent_id,
  name,
  string1 AS description,
  source_id,
  external_database_release_id,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'InflectionPointFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.INPARALOGEXPERIMENT
AS SELECT
  seq_group_experiment_id,
  subclass_view,
  algorithm_id,
  description,
  sequence_source,
  pvalue_mant,
  pvalue_exp,
  percent_identity,
  percent_match,
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
       FROM    SeqGroupExperimentImp
       WHERE   subclass_view='InParalogExperiment'
       WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.INPARALOGGROUP
AS SELECT
  sequence_group_id,
  name,
  description,
  number_of_members,
  max_score,
  min_score,
  max_match_identity,
  min_match_identity,
  max_percent_match,
  min_percent_match,
  max_pvalue_mant,
  max_pvalue_exp,
  min_pvalue_mant,
  min_pvalue_exp,
  sequence_group_experiment_id,
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
      FROM     SequenceGroupImp
      WHERE    subclass_view = 'InParalogGroup'
      with check OPTION;

CREATE VIEW @oracle_dots@.INTRONFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  source_id,
  external_database_release_id,
  prediction_algorithm_id,
  is_predicted,
  review_status_id,
  tinyint1 AS is_one_of,
  int1 AS order_number,
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
FROM NAFeatureImp
WHERE subclass_view = 'IntronFeature'
WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.MISCELLANEOUS
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  string1 AS BOUND_MOIETY,
  string2 AS CITATION,
  string3 AS EVIDENCE,
  string4 AS FUNCTION,
  string5 AS GENE,
  string6 AS LABEL,
  string7 AS MAP,
  string8 AS PARTIAL,
  string9 AS PCR_CONDITIONS,
  string10 AS PHENOTYPE,
  string11 AS PRODUCT,
  string12 AS PSEUDO,
  string13 AS STANDARD_NAME,
  string14 AS USEDIN,
  tinyint1 AS IS_PARTIAL,
  tinyint2 AS IS_PSEUDO,
  int1 AS NUM,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'Miscellaneous'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.MOTIFAASEQUENCE
AS SELECT
  aa_sequence_id,
  sequence_version,
  subclass_view,
  molecular_weight,
  sequence,
  length,
  int1 AS NUMBER_OF_CONTAINED_SEQUENCES,
  description,
  external_database_release_id,
  source_id,
  string1 AS SECONDARY_IDENTIFIER,
  string2 AS NAME,
  string3 AS MOLECULE_TYPE,
  string4 AS CRC32_VALUE,
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
 FROM AASequenceImp
 WHERE subclass_view = 'MotifAASequence'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.NAFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
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
 FROM NAFeatureImp
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.NASEQUENCE
AS SELECT
  na_sequence_id,
  sequence_version,
  subclass_view,
  sequence_type_id,
  taxon_id,
  sequence,
  length,
  a_count,
  c_count,
  g_count,
  t_count,
  other_count,
  description,
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
 FROM NASequenceImp
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.ORTHOLOGEXPERIMENT
AS SELECT
  seq_group_experiment_id,
  subclass_view,
  algorithm_id,
  description,
  sequence_source,
  pvalue_mant,
  pvalue_exp,
  percent_identity,
  percent_match,
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
       FROM    SEQGROUPEXPERIMENTIMP
       WHERE   subclass_view='OrthologExperiment'
       WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.ORTHOLOGGROUP
AS SELECT
  sequence_group_id,
  subclass_view,
  name,
  description,
  number_of_members,
  max_score,
  min_score,
  number_of_taxa,
  max_match_identity,
  min_match_identity,
  max_percent_match,
  min_percent_match,
  max_pvalue_mant,
  max_pvalue_exp,
  min_pvalue_mant,
  min_pvalue_exp,
  sequence_group_experiment_id,
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
      FROM     SequenceGroupImp
      WHERE    subclass_view = 'OrthologGroup'
      with CHECK OPTION;

CREATE VIEW @oracle_dots@.OUTPARALOGEXPERIMENT
AS SELECT
  seq_group_experiment_id,
  subclass_view,
  algorithm_id,
  description,
  sequence_source,
  pvalue_mant,
  pvalue_exp,
  percent_identity,
  percent_match,
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
       FROM     SeqGroupExperimentImp
       WHERE   subclass_view='OutParalogExperiment'
       WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.OUTPARALOGGROUP
AS SELECT
  sequence_group_id,
  name,
  description,
  number_of_members,
  max_score,
  min_score,
  max_match_identity,
  min_match_identity,
  max_percent_match,
  min_percent_match,
  max_pvalue_mant,
  max_pvalue_exp,
  min_pvalue_mant,
  min_pvalue_exp,
  sequence_group_experiment_id,
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
 FROM SequenceGroupImp
 WHERE subclass_view = 'OutParalogGroup'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.POLYAFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  external_database_release_id,
  source_id,
  is_predicted,
  prediction_algorithm_id,
  float1 AS SCORE,
  review_status_id,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'PolyAFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.POSTTRANSLATIONALMODFEATURE
AS SELECT
  aa_feature_id,
  aa_sequence_id,
  subclass_view,
  sequence_ontology_id,
  string1 AS name,
  description,
  prediction_algorithm_id,
  is_predicted,
  review_status_id,
  source_id,
  external_database_release_id,
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
 FROM AAFeatureImp
 WHERE subclass_view = 'PostTranslationalModFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.PREDICTEDAAFEATURE
AS SELECT
  aa_feature_id,
  aa_sequence_id,
  subclass_view,
  sequence_ontology_id,
  string1 AS NAME,
  description,
  prediction_algorithm_id,
  string2 AS ALGORITHM_NAME,
  float1 AS SCORE,
  pfam_entry_id,
  is_predicted,
  review_status_id,
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
  row_alg_invocation_id 
 FROM AAFeatureImp
 WHERE subclass_view = 'PredictedAAFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.PROMOTERFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  external_database_release_id,
  source_id,
  is_predicted,
  prediction_algorithm_id,
  float1 AS SCORE,
  review_status_id,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'PromoterFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.PROTEINFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  string1 AS CITATION,
  string2 AS CLONE,
  string3 AS CODON,
  int1 AS CODON_START,
  string4 AS EC_NUMBER,
  string5 AS EVIDENCE,
  string6 AS FUNCTION,
  string7 AS GENE,
  string8 AS LABEL,
  string9 AS MAP,
  string10 AS PARTIAL,
  string11 AS PRODUCT,
  string12 AS STANDARD_NAME,
  string13 AS TRANSL_EXCEPT,
  string14 AS USEDIN,
  tinyint1 AS IS_PARTIAL,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'ProteinFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.REPEATREGIONAAFEATURE
AS SELECT
  aa_feature_id,
  aa_sequence_id,
  subclass_view,
  sequence_ontology_id,
  repeat_type_id,
  int1 AS period,
  float1 AS copynum,
  int2 AS consensus_size,
  tinyint1 AS percent_match,
  tinyint2 AS percent_indel,
  float2 AS score,
  string6 AS consensus,
  prediction_algorithm_id,
  string2 AS ALGORITHM_NAME,
  review_status_id,
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
 FROM AAFeatureImp
 WHERE subclass_view = 'RepeatRegionAAFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.REPEATS
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  string1 AS CITATION,
  string2 AS EVIDENCE,
  string3 AS FUNCTION,
  string4 AS GENE,
  string5 AS LABEL,
  string6 AS MAP,
  string7 AS PARTIAL,
  string8 AS RPT_FAMILY,
  string9 AS RPT_TYPE,
  string10 AS RPT_UNIT,
  string11 AS STANDARD_NAME,
  string12 AS USEDIN,
  tinyint1 AS IS_PARTIAL,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'Repeats'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.REPLICATIONORIGINFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  parent_id,
  name,
  string1 AS description,
  source_id,
  external_database_release_id,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'ReplicationOriginFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.RESTRICTIONFRAGMENTFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  string1 AS enzyme_name,
  string2 AS type_of_cut,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'RestrictionFragmentFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.RNAFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  source_id,
  external_database_release_id,
  prediction_algorithm_id,
  is_predicted,
  review_status_id,
  int1 AS NUMBER_OF_EXONS,
  int2 AS TRANSLATION_START,
  int3 AS TRANSLATION_STOP,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'RNAFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.RNAREGULATORYFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  source_id,
  external_database_release_id,
  prediction_algorithm_id,
  is_predicted,
  float1 AS score,
  string1 AS function,
  review_status_id,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'RNARegulatoryFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.RNASECONDARYSTRUCTURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  source_id,
  external_database_release_id,
  prediction_algorithm_id,
  is_predicted,
  float1 AS score,
  review_status_id,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'RNASecondaryStructureFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.RNASTRUCTURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  string1 AS CITATION,
  string2 AS EVIDENCE,
  string3 AS FUNCTION,
  string4 AS GENE,
  string5 AS LABEL,
  string6 AS MAP,
  string7 AS PARTIAL,
  string8 AS PRODUCT,
  string9 AS STANDARD_NAME,
  string10 AS USEDIN,
  tinyint1 AS IS_PARTIAL,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'RNAStructure'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.RNATYPE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  string1 AS ANTICODON,
  string2 AS CITATION,
  string3 AS CODON,
  string4 AS EVIDENCE,
  string5 AS FUNCTION,
  string6 AS GENE,
  string7 AS LABEL,
  string8 AS MAP,
  string9 AS PARTIAL,
  string10 AS PRODUCT,
  string11 AS PSEUDO,
  string12 AS STANDARD_NAME,
  string13 AS USEDIN,
  tinyint1 AS IS_PARTIAL,
  tinyint2 AS IS_PSEUDO,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'RNAType'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.SAGETAGFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  external_database_release_id,
  source_id,
  prediction_algorithm_id,
  is_predicted,
  review_status_id,
  string1 AS restriction_enzyme,
  int1 AS binding_location_id,
  int2 AS trailer_location_id,
  int3 AS tag_location_id,
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
FROM NAFeatureImp
WHERE subclass_view = 'SAGETagFeature'
WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.SECONDARYSTRUCTUREAAFEATURE
AS SELECT
  aa_feature_id,
  aa_sequence_id,
  subclass_view,
  sequence_ontology_id,
  source_id,
  string1 AS NAME,
  external_database_release_id,
  prediction_algorithm_id,
  is_predicted,
  float1 AS SCORE,
  review_status_id,
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
 FROM AAFeatureImp
 WHERE subclass_view = 'SecondaryStructureAAFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.SEQGROUPEXPERIMENT
AS SELECT
  seq_group_experiment_id,
  algorithm_id,
  description,
  sequence_source,
  pvalue_mant,
  pvalue_exp,
  percent_identity,
  percent_match,
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
        FROM    SeqGroupExperimentImp
       WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.SEQUENCEGROUP
AS SELECT
  sequence_group_id,
  name,
  description,
  number_of_members,
  number_of_taxa,
  max_match_identity,
  min_match_identity,
  max_percent_match,
  min_percent_match,
  max_pvalue_mant,
  max_pvalue_exp,
  min_pvalue_mant,
  min_pvalue_exp,
  max_score,
  min_score,
  sequence_group_experiment_id,
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
FROM    SequenceGroupImp
WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.SEQVARIATION
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  string1 AS CITATION,
  string2 AS CLONE,
  string3 AS EVIDENCE,
  string5 AS FUNCTION,
  string6 AS GENE,
  string7 AS LABEL,
  string8 AS MAP,
  string9 AS ORGANISM,
  string10 AS PARTIAL,
  string11 AS PHENOTYPE,
  string12 AS PRODUCT,
  string13 AS STANDARD_NAME,
  string20 AS SUBSTITUTE,
  string15 AS NUM,
  string16 AS USEDIN,
  string17 AS MOD_BASE,
  tinyint1 AS IS_PARTIAL,
  float1 AS FREQUENCY,
  string18 AS ALLELE,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'SeqVariation'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.SIGNALPEPTIDEFEATURE
AS SELECT
  aa_feature_id,
  aa_sequence_id,
  subclass_view,
  sequence_ontology_id,
  string1 AS NAME,
  description,
  prediction_algorithm_id,
  string2 AS ALGORITHM_NAME,
  float1 AS MAXY_SCORE,
  tinyint1 AS MAXY_CONCLUSION,
  float2 AS MAXC_SCORE,
  tinyint2 AS MAXC_CONCLUSION,
  float3 AS MAXS_SCORE,
  tinyint3 AS MAXS_CONCLUSION,
  float4 AS MEANS_SCORE,
  tinyint4 AS MEANS_CONCLUSION,
  int1 AS NUM_POSITIVES,
  is_predicted,
  review_status_id,
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
  row_alg_invocation_id 
 FROM AAFeatureImp
 WHERE subclass_view = 'SignalPeptideFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.SOURCE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  string1 AS CELL_LINE,
  string2 AS CELL_TYPE,
  string3 AS CHROMOPLAST,
  string4 AS CHROMOSOME,
  string5 AS CLONE,
  string6 AS CLONE_LIB,
  string7 AS CULTIVAR,
  string8 AS CYANELLE,
  string9 AS DEV_STAGE,
  string10 AS FOCUS,
  string11 AS FREQUENCY,
  string12 AS GERMLINE,
  string13 AS HAPLOTYPE,
  text1 AS INSERTION_SEQ,
  string14 AS ISOLATE,
  string15 AS KINETOPLAST,
  string16 AS LAB_HOST,
  string17 AS MACRONUCLEAR,
  string18 AS ORGANELLE,
  string19 AS POP_VARIANT,
  string20 AS PLASMID,
  string21 AS PROVIRAL,
  string22 AS REARRANGED,
  string23 AS SEQUENCED_MOL,
  string24 AS SEROTYPE,
  string25 AS SEX,
  string26 AS SPECIFIC_HOST,
  string27 AS STRAIN,
  string28 AS SUB_CLONE,
  string29 AS SUB_SPECIES,
  string30 AS SUB_STRAIN,
  string31 AS TISSUE_LIB,
  string32 AS TRANSPOSON,
  string33 AS VARIETY,
  string34 AS VIRION,
  string35 AS CHLOROPLAST,
  string36 AS CITATION,
  string37 AS MAP,
  string38 AS ORGANISM,
  string39 AS SPECIMEN_VOUCHER,
  string40 AS TISSUE_TYPE,
  string41 AS USEDIN,
  string42 AS LABEL,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'Source'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.SPLICEDNASEQUENCE
AS SELECT
  na_sequence_id,
  sequence_version,
  sequence_type_id,
  external_database_release_id,
  string1 AS SOURCE_ID,
  string2 AS SECONDARY_IDENTIFIER,
  string3 AS NAME,
  taxon_id,
  sequence,
  length,
  a_count,
  c_count,
  g_count,
  t_count,
  other_count,
  description,
  subclass_view,
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
 FROM NASequenceImp
 WHERE subclass_view = 'SplicedNASequence'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.SPLICESITEFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  parent_id,
  source_id,
  external_database_release_id,
  prediction_algorithm_id,
  is_predicted,
  float1 AS score,
  review_status_id,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'SpliceSiteFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.STS
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  string1 AS CITATION,
  string2 AS EVIDENCE,
  string3 AS GENE,
  string4 AS LABEL,
  string5 AS MAP,
  string6 AS PARTIAL,
  string7 AS STANDARD_NAME,
  string8 AS USEDIN,
  tinyint1 AS IS_PARTIAL,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'STS'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.TANDEMREPEATFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  int1 AS period,
  float1 AS copynum,
  int2 AS consensus_size,
  tinyint1 AS percent_match,
  tinyint2 AS percent_indel,
  float2 AS score,
  int3 AS a_count,
  int4 AS c_count,
  int5 AS g_count,
  int6 AS t_count,
  float3 AS entropy,
  string1 AS consensus,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'TandemRepeatFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.TERTIARYSTRUCTUREAAFEATURE
AS SELECT
  aa_feature_id,
  aa_sequence_id,
  subclass_view,
  sequence_ontology_id,
  parent_id,
  source_id,
  string1 AS NAME,
  external_database_release_id,
  prediction_algorithm_id,
  is_predicted,
  float1 AS SCORE,
  review_status_id,
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
 FROM AAFeatureImp
 WHERE subclass_view = 'TertiaryStructureAAFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.TRANSCRIPT
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  string1 AS CITATION,
  string2 AS CLONE,
  string3 AS CODON,
  int1 AS CODON_START,
  string4 AS CONS_SPLICE,
  string5 AS EC_NUMBER,
  string6 AS EVIDENCE,
  string7 AS FUNCTION,
  string8 AS GENE,
  string9 AS LABEL,
  string10 AS MAP,
  string11 AS NUM,
  string12 AS PARTIAL,
  string13 AS PRODUCT,
  string14 AS PROTEIN_ID,
  string15 AS PSEUDO,
  string16 AS STANDARD_NAME,
  text1 AS TRANSLATION,
  string17 AS TRANSL_EXCEPT,
  int2 AS TRANSL_TABLE,
  string18 AS USEDIN,
  tinyint1 AS IS_PARTIAL,
  tinyint2 AS IS_PSEUDO,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'Transcript'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.TRANSLATEDAAFEATURE
AS SELECT
  aa_feature_id,
  aa_sequence_id,
  na_feature_id,
  subclass_view,
  sequence_ontology_id,
  description,
  prediction_algorithm_id,
  is_predicted,
  int1 AS TRANSLATION_START,
  int2 AS TRANSLATION_STOP,
  tinyint1 AS IS_SIMPLE,
  string1 AS CODON_TABLE,
  review_status_id,
  float1 AS TRANSLATION_SCORE,
  string2 AS TRANSLATION_MODEL,
  int3 AS NUMBER_OF_SEGMENTS,
  float2 AS DIANA_ATG_SCORE,
  int4 AS DIANA_ATG_POSITION,
  float3 AS P_VALUE,
  string4 AS PARAMETER_VALUES,
  tinyint2 AS IS_REVERSED,
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
 FROM AAFeatureImp
 WHERE subclass_view = 'TranslatedAAFeature'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.TRANSLATEDAASEQUENCE
AS SELECT
  aa_sequence_id,
  sequence_version,
  subclass_view,
  molecular_weight,
  sequence,
  length,
  description,
  string2 AS NOTES,
  int1 AS IS_SIMPLE,
  external_database_release_id,
  source_id,
  string1 AS SECONDARY_IDENTIFIER,
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
 FROM AASequenceImp
 WHERE subclass_view = 'TranslatedAASequence'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.TRANSPOSABLEELEMENT
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  source_id,
  external_database_release_id,
  prediction_algorithm_id,
  is_predicted,
  review_status_id,
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
 FROM NAFeatureImp
 WHERE subclass_view = 'TransposableElement'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.TRIVIALTRANSLATION
AS SELECT
  aa_sequence_id,
  sequence_version,
  subclass_view,
  molecular_weight,
  sequence,
  length,
  description,
  tinyint1 AS READING_FRAME,
  string1 AS CODON_TABLE,
  int1 AS TRANSLATION_START,
  int2 AS TRANSLATION_STOP,
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
 FROM AASequenceImp
 WHERE subclass_view = 'TrivialTranslation'
 WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.UTRFEATURE
AS SELECT
  na_feature_id,
  na_sequence_id,
  subclass_view,
  sequence_ontology_id,
  name,
  parent_id,
  source_id,
  external_database_release_id,
  prediction_algorithm_id,
  is_predicted,
  review_status_id,
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
FROM NAFeatureImp
WHERE subclass_view = 'UTRFeature'
WITH CHECK OPTION;

CREATE VIEW @oracle_dots@.VIRTUALSEQUENCE
AS SELECT
  na_sequence_id,
  sequence_version,
  string3 AS CONFIDENCE,
  description,
  sequence_type_id,
  external_database_release_id,
  string1 AS SOURCE_ID,
  string2 AS SECONDARY_IDENTIFIER,
  taxon_id,
  sequence,
  length,
  a_count,
  c_count,
  g_count,
  t_count,
  other_count,
  string4 AS CHROMOSOME,
  int1 AS CHROMOSOME_ORDER_NUM,
  subclass_view,
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
 FROM NASequenceImp
 WHERE subclass_view = 'VirtualSequence'
 WITH CHECK OPTION;


/* 68 view(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

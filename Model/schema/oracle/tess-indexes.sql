
/*                                                                                            */
/* tess-indexes.sql                                                                           */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Dec  9 16:13:59 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL tess-indexes.log

/* ACTIVITYCONDITIONS */
create index @oracle_tess@.ACTIVITYCONDITIONS_IND01 on @oracle_tess@.ACTIVITYCONDITIONS (ACTIVITY_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ACTIVITYCONDITIONS_IND02 on @oracle_tess@.ACTIVITYCONDITIONS (REVIEW_STATUS_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ACTIVITYCONDITIONS_IND03 on @oracle_tess@.ACTIVITYCONDITIONS (TAXON_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ACTIVITYCONDITIONS_IND04 on @oracle_tess@.ACTIVITYCONDITIONS (ANATOMY_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ACTIVITYCONDITIONS_IND05 on @oracle_tess@.ACTIVITYCONDITIONS (CELL_TYPE_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ACTIVITYCONDITIONS_IND06 on @oracle_tess@.ACTIVITYCONDITIONS (DEVELOPMENTAL_STAGE_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ACTIVITYCONDITIONS_IND07 on @oracle_tess@.ACTIVITYCONDITIONS (DISEASE_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ACTIVITYCONDITIONS_IND08 on @oracle_tess@.ACTIVITYCONDITIONS (PHENOTYPE_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* ACTIVITYIMP */
create index @oracle_tess@.ACTIVITYIMP_IND02 on @oracle_tess@.ACTIVITYIMP (MOIETY_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ACTIVITYIMP_IND03 on @oracle_tess@.ACTIVITYIMP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ACTIVITYIMP_IND04 on @oracle_tess@.ACTIVITYIMP (REVIEW_STATUS_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ACTIVITYIMP_IND01 on @oracle_tess@.ACTIVITYIMP (GO_TERM_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* ACTIVITYINFERENCESOURCE */
create index @oracle_tess@.ACTIVITYINFERENCESOURCE_IND01 on @oracle_tess@.ACTIVITYINFERENCESOURCE (ACTIVITY_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* ANALYSIS */
create index @oracle_tess@.ANALYSIS_IND01 on @oracle_tess@.ANALYSIS (POSITIVE_TRAINING_SET_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ANALYSIS_IND02 on @oracle_tess@.ANALYSIS (NEGATIVE_TRAINING_SET_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ANALYSIS_IND03 on @oracle_tess@.ANALYSIS (PROTOCOL_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ANALYSIS_IND04 on @oracle_tess@.ANALYSIS (REVIEW_STATUS_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ANALYSIS_IND05 on @oracle_tess@.ANALYSIS (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.ANALYSIS_IND06 on @oracle_tess@.ANALYSIS (PARAMETER_GROUP_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* FOOTPRINT */
create index @oracle_tess@.FOOTPRINT_IND01 on @oracle_tess@.FOOTPRINT (ACTIVITY_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.FOOTPRINT_IND02 on @oracle_tess@.FOOTPRINT (NA_FEATURE_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.FOOTPRINT_IND03 on @oracle_tess@.FOOTPRINT (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* FOOTPRINTMETHODPROTOCOL */
create index @oracle_tess@.FOOTPRINTMETHODPROTOCOL_IND01 on @oracle_tess@.FOOTPRINTMETHODPROTOCOL (FOOTPRINT_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.FOOTPRINTMETHODPROTOCOL_IND02 on @oracle_tess@.FOOTPRINTMETHODPROTOCOL (PROTOCOL_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* MARKOVCHAINOBS */


/* MODELIMP */
create index @oracle_tess@.MODELIMP_IND01 on @oracle_tess@.MODELIMP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.MODELIMP_IND02 on @oracle_tess@.MODELIMP (BEST_PRACTICE_PARAM_GROUP_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.MODELIMP_IND03 on @oracle_tess@.MODELIMP (REVIEW_STATUS_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* MODELRESULT */
create index @oracle_tess@.MODELRESULT_IND01 on @oracle_tess@.MODELRESULT (MODEL_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.MODELRESULT_IND02 on @oracle_tess@.MODELRESULT (ANALYSIS_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.MODELRESULT_IND03 on @oracle_tess@.MODELRESULT (PARAMETER_GROUP_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.MODELRESULT_IND04 on @oracle_tess@.MODELRESULT (REVIEW_STATUS_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* MOIETYIMP */
create index @oracle_tess@.MOIETYIMP_IND01 on @oracle_tess@.MOIETYIMP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.MOIETYIMP_IND02 on @oracle_tess@.MOIETYIMP (TAXON_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.MOIETYIMP_IND03 on @oracle_tess@.MOIETYIMP (REVIEW_STATUS_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* MOIETYINSTANCE */
create index @oracle_tess@.MOIETYINSTANCE_IND01 on @oracle_tess@.MOIETYINSTANCE (MOIETY_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.MOIETYINSTANCE_IND02 on @oracle_tess@.MOIETYINSTANCE (DOGMA_OBJECT_TABLE_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.MOIETYINSTANCE_IND03 on @oracle_tess@.MOIETYINSTANCE (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* MOIETYMEMBER */
create index @oracle_tess@.MOIETYMEMBER_IND01 on @oracle_tess@.MOIETYMEMBER (WHOLE_MOIETY_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.MOIETYMEMBER_IND02 on @oracle_tess@.MOIETYMEMBER (PART_MOIETY_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.MOIETYMEMBER_IND03 on @oracle_tess@.MOIETYMEMBER (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.MOIETYMEMBER_IND04 on @oracle_tess@.MOIETYMEMBER (REVIEW_STATUS_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* MOIETYSYNONYM */
create index @oracle_tess@.MOIETYSYNONYM_IND01 on @oracle_tess@.MOIETYSYNONYM (MOIETY_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.MOIETYSYNONYM_IND02 on @oracle_tess@.MOIETYSYNONYM (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* MULTINOMIALLABEL */
create index @oracle_tess@.MULTINOMIALLABEL_IND01 on @oracle_tess@.MULTINOMIALLABEL (MULTINOMIAL_LABEL_SET_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* MULTINOMIALLABELSET */


/* MULTINOMIALOBSERVATION */


/* MULTINOMIALOBSERVATIONSET */


/* NOTE */
create index @oracle_tess@.NOTE_IND01 on @oracle_tess@.NOTE (TABLE_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* PARAMETERGROUP */
create index @oracle_tess@.PARAMETERGROUP_IND01 on @oracle_tess@.PARAMETERGROUP (REVIEW_STATUS_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* PARAMETERSUBGROUP */
create index @oracle_tess@.PARAMETERSUBGROUP_IND01 on @oracle_tess@.PARAMETERSUBGROUP (PARENT_GROUP_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.PARAMETERSUBGROUP_IND02 on @oracle_tess@.PARAMETERSUBGROUP (CHILD_GROUP_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* PARAMETERVALUE */
create index @oracle_tess@.PARAMETERVALUE_IND01 on @oracle_tess@.PARAMETERVALUE (PARAMETER_GROUP_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.PARAMETERVALUE_IND02 on @oracle_tess@.PARAMETERVALUE (TYPE_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* PARSERITEM */
create index @oracle_tess@.PARSERITEM_IND01 on @oracle_tess@.PARSERITEM (SBCG_RECOGNITION_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.PARSERITEM_IND02 on @oracle_tess@.PARSERITEM (NA_FEATURE_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.PARSERITEM_IND03 on @oracle_tess@.PARSERITEM (AA_FEATURE_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* PARSERITEMEDGETYPE */


/* PARSERITEMLINK */
create index @oracle_tess@.PARSERITEMLINK_IND01 on @oracle_tess@.PARSERITEMLINK (PARENT_PARSER_ITEM_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.PARSERITEMLINK_IND02 on @oracle_tess@.PARSERITEMLINK (CHILD_PARSER_ITEM_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.PARSERITEMLINK_IND03 on @oracle_tess@.PARSERITEMLINK (PARSER_ITEM_EDGE_TYPE_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* PREDICTIONRESULT */
create index @oracle_tess@.PREDICTIONRESULT_IND02 on @oracle_tess@.PREDICTIONRESULT (FOOTPRINT_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.PREDICTIONRESULT_IND03 on @oracle_tess@.PREDICTIONRESULT (REVIEW_STATUS_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.PREDICTIONRESULT_IND04 on @oracle_tess@.PREDICTIONRESULT (ANALYSIS_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.PREDICTIONRESULT_IND01 on @oracle_tess@.PREDICTIONRESULT (MODEL_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* SBCGANNOTATIONFILTER */
create index @oracle_tess@.SBCGANNOTATIONFILTER_IND01 on @oracle_tess@.SBCGANNOTATIONFILTER (SBCG_RECOG_PATH_EXPRESSION_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.SBCGANNOTATIONFILTER_IND02 on @oracle_tess@.SBCGANNOTATIONFILTER (SBCG_PATH_TERM_REL_TYPE_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* SBCGANNOTATIONFILTERTERM */
create index @oracle_tess@.SBCGANNOTATIONFILTERTERM_IND01 on @oracle_tess@.SBCGANNOTATIONFILTERTERM (SBCG_ANNOTATION_FILTER_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.SBCGANNOTATIONFILTERTERM_IND02 on @oracle_tess@.SBCGANNOTATIONFILTERTERM (SBCG_COMPARISON_TYPE_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* SBCGANNOTATIONGUIDE */
create index @oracle_tess@.SBCGANNOTATIONGUIDE_IND01 on @oracle_tess@.SBCGANNOTATIONGUIDE (MODEL_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* SBCGCOMPARISONTYPE */


/* SBCGNONTERMINAL */
create index @oracle_tess@.SBCGNONTERMINAL_IND01 on @oracle_tess@.SBCGNONTERMINAL (SBGC_GRAMMAR_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* SBCGPATHTERMRELATIONTYPE */


/* SBCGPRODUCTION */
create index @oracle_tess@.SBCGPRODUCTION_IND01 on @oracle_tess@.SBCGPRODUCTION (SBGC_GRAMMAR_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.SBCGPRODUCTION_IND02 on @oracle_tess@.SBCGPRODUCTION (SBCG_NONTERMINAL_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.SBCGPRODUCTION_IND03 on @oracle_tess@.SBCGPRODUCTION (SBCG_PRODUCTION_TYPE_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.SBCGPRODUCTION_IND04 on @oracle_tess@.SBCGPRODUCTION (SBCG_ANNOTATION_GUIDE_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.SBCGPRODUCTION_IND05 on @oracle_tess@.SBCGPRODUCTION (SBCG_PATH_BOUND_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* SBCGPRODUCTIONTYPE */


/* SBCGRECOGMULTIOBS */


/* SBCGRECOGNITIONIMP */
create index @oracle_tess@.SBCGRECOGNITIONIMP_IND01 on @oracle_tess@.SBCGRECOGNITIONIMP (MODEL_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.SBCGRECOGNITIONIMP_IND02 on @oracle_tess@.SBCGRECOGNITIONIMP (SBCG_NONTERMINAL_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.SBCGRECOGNITIONIMP_IND03 on @oracle_tess@.SBCGRECOGNITIONIMP (SBCG_STREAM_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.SBCGRECOGNITIONIMP_IND04 on @oracle_tess@.SBCGRECOGNITIONIMP (PARENT_SBCG_RECOGNITION_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* SBCGRHSTERM */
create index @oracle_tess@.SBCGRHSTERM_IND01 on @oracle_tess@.SBCGRHSTERM (SBCG_PRODUCTION_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.SBCGRHSTERM_IND02 on @oracle_tess@.SBCGRHSTERM (SBCG_RECOGNITION_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.SBCGRHSTERM_IND03 on @oracle_tess@.SBCGRHSTERM (SBCG_ANNOTATION_GUIDE_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* SBCGSTREAM */
create index @oracle_tess@.SBCGSTREAM_IND01 on @oracle_tess@.SBCGSTREAM (MODEL_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* SBCGSTREAMPARAMETER */
create index @oracle_tess@.SBCGSTREAMPARAMETER_IND01 on @oracle_tess@.SBCGSTREAMPARAMETER (SBCG_STREAM_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* TRAININGSET */
create index @oracle_tess@.TRAININGSET_IND01 on @oracle_tess@.TRAININGSET (ACTIVITY_ID)  TABLESPACE @oracle_tessIndexTablespace@;

/* TRAININGSETMEMBER */
create index @oracle_tess@.TRAININGSETMEMBER_IND01 on @oracle_tess@.TRAININGSETMEMBER (TRAINING_SET_ID)  TABLESPACE @oracle_tessIndexTablespace@;
create index @oracle_tess@.TRAININGSETMEMBER_IND02 on @oracle_tess@.TRAININGSETMEMBER (FOOTPRINT_ID)  TABLESPACE @oracle_tessIndexTablespace@;



/* 83 index(es) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

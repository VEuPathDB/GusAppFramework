
/*                                                                                            */
/* tess-constraints.sql                                                                       */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Dec  9 16:13:59 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL tess-constraints.log

/* NON-PRIMARY KEY CONSTRAINTS */

/* ACTIVITYCONDITIONS */
alter table @oracle_tess@.ACTIVITYCONDITIONS add constraint ACTIVITYCONDITIONS_FK01 foreign key (ACTIVITY_ID) references @oracle_tess@.ACTIVITYIMP (ACTIVITY_ID);
alter table @oracle_tess@.ACTIVITYCONDITIONS add constraint ACTIVITYCONDITIONS_FK02 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);
alter table @oracle_tess@.ACTIVITYCONDITIONS add constraint ACTIVITYCONDITIONS_FK03 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_tess@.ACTIVITYCONDITIONS add constraint ACTIVITYCONDITIONS_FK04 foreign key (ANATOMY_ID) references @oracle_sres@.ANATOMY (ANATOMY_ID);
alter table @oracle_tess@.ACTIVITYCONDITIONS add constraint ACTIVITYCONDITIONS_FK05 foreign key (CELL_TYPE_ID) references @oracle_sres@.ANATOMY (ANATOMY_ID);
alter table @oracle_tess@.ACTIVITYCONDITIONS add constraint ACTIVITYCONDITIONS_FK06 foreign key (DEVELOPMENTAL_STAGE_ID) references @oracle_sres@.DEVELOPMENTALSTAGE (DEVELOPMENTAL_STAGE_ID);
alter table @oracle_tess@.ACTIVITYCONDITIONS add constraint ACTIVITYCONDITIONS_FK07 foreign key (DISEASE_ID) references @oracle_sres@.DISEASE (DISEASE_ID);
alter table @oracle_tess@.ACTIVITYCONDITIONS add constraint ACTIVITYCONDITIONS_FK08 foreign key (PHENOTYPE_ID) references @oracle_sres@.PHENOTYPE (PHENOTYPE_ID);

/* ACTIVITYIMP */
alter table @oracle_tess@.ACTIVITYIMP add constraint ACTIVITYIMP_FK01 foreign key (GO_TERM_ID) references @oracle_sres@.GOTERM (GO_TERM_ID);
alter table @oracle_tess@.ACTIVITYIMP add constraint ACTIVITYIMP_FK02 foreign key (MOIETY_ID) references @oracle_tess@.MOIETYIMP (MOIETY_ID);
alter table @oracle_tess@.ACTIVITYIMP add constraint ACTIVITYIMP_FK03 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_tess@.ACTIVITYIMP add constraint ACTIVITYIMP_FK04 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* ACTIVITYINFERENCESOURCE */
alter table @oracle_tess@.ACTIVITYINFERENCESOURCE add constraint ACTIVITYINFERENCESOURCE_FK01 foreign key (ACTIVITY_ID) references @oracle_tess@.ACTIVITYIMP (ACTIVITY_ID);

/* ANALYSIS */
alter table @oracle_tess@.ANALYSIS add constraint ANALYSIS_FK01 foreign key (POSITIVE_TRAINING_SET_ID) references @oracle_tess@.TRAININGSET (TRAINING_SET_ID);
alter table @oracle_tess@.ANALYSIS add constraint ANALYSIS_FK02 foreign key (NEGATIVE_TRAINING_SET_ID) references @oracle_tess@.TRAININGSET (TRAINING_SET_ID);
alter table @oracle_tess@.ANALYSIS add constraint ANALYSIS_FK04 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);
alter table @oracle_tess@.ANALYSIS add constraint ANALYSIS_FK05 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_tess@.ANALYSIS add constraint ANALYSIS_FK06 foreign key (PARAMETER_GROUP_ID) references @oracle_tess@.PARAMETERGROUP (PARAMETER_GROUP_ID);

/* FOOTPRINT */
alter table @oracle_tess@.FOOTPRINT add constraint FOOTPRINT_FK01 foreign key (ACTIVITY_ID) references @oracle_tess@.ACTIVITYIMP (ACTIVITY_ID);
alter table @oracle_tess@.FOOTPRINT add constraint FOOTPRINT_FK02 foreign key (NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);
alter table @oracle_tess@.FOOTPRINT add constraint FOOTPRINT_FK03 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* FOOTPRINTMETHODPROTOCOL */
alter table @oracle_tess@.FOOTPRINTMETHODPROTOCOL add constraint FOOTPRINTMETHODPROTOCOL_FK01 foreign key (FOOTPRINT_ID) references @oracle_tess@.FOOTPRINT (FOOTPRINT_ID);

/* MARKOVCHAINOBS */
alter table @oracle_tess@.MARKOVCHAINOBS add constraint MARKOVCHAINOBS_FK01 foreign key (MODEL_ID) references @oracle_tess@.MODELIMP (MODEL_ID);

/* MODELIMP */
alter table @oracle_tess@.MODELIMP add constraint MODELIMP_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_tess@.MODELIMP add constraint MODELIMP_FK02 foreign key (BEST_PRACTICE_PARAM_GROUP_ID) references @oracle_tess@.PARAMETERGROUP (PARAMETER_GROUP_ID);
alter table @oracle_tess@.MODELIMP add constraint MODELIMP_FK03 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* MODELRESULT */
alter table @oracle_tess@.MODELRESULT add constraint MODELRESULT_FK01 foreign key (MODEL_ID) references @oracle_tess@.MODELIMP (MODEL_ID);
alter table @oracle_tess@.MODELRESULT add constraint MODELRESULT_FK02 foreign key (ANALYSIS_ID) references @oracle_tess@.ANALYSIS (ANALYSIS_ID);
alter table @oracle_tess@.MODELRESULT add constraint MODELRESULT_FK03 foreign key (PARAMETER_GROUP_ID) references @oracle_tess@.PARAMETERGROUP (PARAMETER_GROUP_ID);
alter table @oracle_tess@.MODELRESULT add constraint MODELRESULT_FK04 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* MOIETYIMP */
alter table @oracle_tess@.MOIETYIMP add constraint MOIETYIMP_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_tess@.MOIETYIMP add constraint MOIETYIMP_FK02 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_tess@.MOIETYIMP add constraint MOIETYIMP_FK03 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* MOIETYINSTANCE */
alter table @oracle_tess@.MOIETYINSTANCE add constraint MOIETYINSTANCE_FK01 foreign key (MOIETY_ID) references @oracle_tess@.MOIETYIMP (MOIETY_ID);
alter table @oracle_tess@.MOIETYINSTANCE add constraint MOIETYINSTANCE_FK02 foreign key (DOGMA_OBJECT_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_tess@.MOIETYINSTANCE add constraint MOIETYINSTANCE_FK03 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* MOIETYMEMBER */
alter table @oracle_tess@.MOIETYMEMBER add constraint MOIETYMEMBER_FK01 foreign key (WHOLE_MOIETY_ID) references @oracle_tess@.MOIETYIMP (MOIETY_ID);
alter table @oracle_tess@.MOIETYMEMBER add constraint MOIETYMEMBER_FK02 foreign key (PART_MOIETY_ID) references @oracle_tess@.MOIETYIMP (MOIETY_ID);
alter table @oracle_tess@.MOIETYMEMBER add constraint MOIETYMEMBER_FK03 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_tess@.MOIETYMEMBER add constraint MOIETYMEMBER_FK04 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* MOIETYSYNONYM */
alter table @oracle_tess@.MOIETYSYNONYM add constraint MOIETYSYNONYM_FK01 foreign key (MOIETY_ID) references @oracle_tess@.MOIETYIMP (MOIETY_ID);
alter table @oracle_tess@.MOIETYSYNONYM add constraint MOIETYSYNONYM_FK02 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* MULTINOMIALLABEL */
alter table @oracle_tess@.MULTINOMIALLABEL add constraint MULTINOMIALLABEL_FK01 foreign key (MULTINOMIAL_LABEL_SET_ID) references @oracle_tess@.MULTINOMIALLABELSET (MULTINOMIAL_LABEL_SET_ID);

/* MULTINOMIALLABELSET */

/* MULTINOMIALOBSERVATION */

/* MULTINOMIALOBSERVATIONSET */
alter table @oracle_tess@.MULTINOMIALOBSERVATIONSET add constraint MULTINOMIALOBSERVATIONSET_FK02 foreign key (MULTINOMIAL_LABEL_SET_ID) references @oracle_tess@.MULTINOMIALLABELSET (MULTINOMIAL_LABEL_SET_ID);

/* NOTE */
alter table @oracle_tess@.NOTE add constraint NOTE_FK01 foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* PARAMETERGROUP */
alter table @oracle_tess@.PARAMETERGROUP add constraint PARAMETERGROUP_FK01 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* PARAMETERSUBGROUP */
alter table @oracle_tess@.PARAMETERSUBGROUP add constraint PARAMETERSUBGROUP_FK01 foreign key (PARENT_GROUP_ID) references @oracle_tess@.PARAMETERGROUP (PARAMETER_GROUP_ID);
alter table @oracle_tess@.PARAMETERSUBGROUP add constraint PARAMETERSUBGROUP_FK02 foreign key (CHILD_GROUP_ID) references @oracle_tess@.PARAMETERGROUP (PARAMETER_GROUP_ID);

/* PARAMETERVALUE */
alter table @oracle_tess@.PARAMETERVALUE add constraint PARAMETERVALUE_FK01 foreign key (PARAMETER_GROUP_ID) references @oracle_tess@.PARAMETERGROUP (PARAMETER_GROUP_ID);
alter table @oracle_tess@.PARAMETERVALUE add constraint PARAMETERVALUE_FK02 foreign key (TYPE_ID) references @oracle_core@.ALGORITHMPARAMKEYTYPE (ALGORITHM_PARAM_KEY_TYPE_ID);

/* PARSERITEM */
alter table @oracle_tess@.PARSERITEM add constraint PARSERITEM_FK01 foreign key (SBCG_RECOGNITION_ID) references @oracle_tess@.SBCGRECOGNITIONIMP (SBCG_RECOGNITION_ID);
alter table @oracle_tess@.PARSERITEM add constraint PARSERITEM_FK02 foreign key (NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);

/* PARSERITEMEDGETYPE */

/* PARSERITEMLINK */
alter table @oracle_tess@.PARSERITEMLINK add constraint PARSERITEMLINK_FK01 foreign key (PARENT_PARSER_ITEM_ID) references @oracle_tess@.PARSERITEM (PARSER_ITEM_ID);
alter table @oracle_tess@.PARSERITEMLINK add constraint PARSERITEMLINK_FK02 foreign key (CHILD_PARSER_ITEM_ID) references @oracle_tess@.PARSERITEM (PARSER_ITEM_ID);
alter table @oracle_tess@.PARSERITEMLINK add constraint PARSERITEMLINK_FK03 foreign key (PARSER_ITEM_EDGE_TYPE_ID) references @oracle_tess@.PARSERITEMEDGETYPE (PARSER_ITEM_EDGE_TYPE_ID);

/* PREDICTIONRESULT */
alter table @oracle_tess@.PREDICTIONRESULT add constraint PREDICTIONRESULT_FK01 foreign key (MODEL_ID) references @oracle_tess@.MODELIMP (MODEL_ID);
alter table @oracle_tess@.PREDICTIONRESULT add constraint PREDICTIONRESULT_FK02 foreign key (FOOTPRINT_ID) references @oracle_tess@.FOOTPRINT (FOOTPRINT_ID);
alter table @oracle_tess@.PREDICTIONRESULT add constraint PREDICTIONRESULT_FK03 foreign key (ANALYSIS_ID) references @oracle_tess@.ANALYSIS (ANALYSIS_ID);
alter table @oracle_tess@.PREDICTIONRESULT add constraint PREDICTIONRESULT_FK04 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* SBCGANNOTATIONFILTER */
alter table @oracle_tess@.SBCGANNOTATIONFILTER add constraint SBCGANNOTATIONFILTER_FK01 foreign key (SBCG_RECOG_PATH_EXPRESSION_ID) references @oracle_tess@.SBCGRECOGNITIONIMP (SBCG_RECOGNITION_ID);
alter table @oracle_tess@.SBCGANNOTATIONFILTER add constraint SBCGANNOTATIONFILTER_FK02 foreign key (SBCG_PATH_TERM_REL_TYPE_ID) references @oracle_tess@.SBCGPATHTERMRELATIONTYPE (SBCG_PATH_TERM_REL_TYPE_ID);

/* SBCGANNOTATIONFILTERTERM */
alter table @oracle_tess@.SBCGANNOTATIONFILTERTERM add constraint SBCGANNOTATIONFILTERTERM_FK01 foreign key (SBCG_ANNOTATION_FILTER_ID) references @oracle_tess@.SBCGANNOTATIONFILTER (SBCG_ANNOTATION_FILTER_ID);
alter table @oracle_tess@.SBCGANNOTATIONFILTERTERM add constraint SBCGANNOTATIONFILTERTERM_FK02 foreign key (SBCG_COMPARISON_TYPE_ID) references @oracle_tess@.SBCGCOMPARISONTYPE (SBCG_COMPARISON_TYPE_ID);

/* SBCGANNOTATIONGUIDE */
alter table @oracle_tess@.SBCGANNOTATIONGUIDE add constraint SBCGANNOTATIONGUIDE_FK01 foreign key (MODEL_ID) references @oracle_tess@.MODELIMP (MODEL_ID);

/* SBCGCOMPARISONTYPE */

/* SBCGNONTERMINAL */
alter table @oracle_tess@.SBCGNONTERMINAL add constraint SBCGNONTERMINAL_FK01 foreign key (SBGC_GRAMMAR_ID) references @oracle_tess@.MODELIMP (MODEL_ID);

/* SBCGPATHTERMRELATIONTYPE */

/* SBCGPRODUCTION */
alter table @oracle_tess@.SBCGPRODUCTION add constraint SBCGPRODUCTION_FK01 foreign key (SBGC_GRAMMAR_ID) references @oracle_tess@.MODELIMP (MODEL_ID);
alter table @oracle_tess@.SBCGPRODUCTION add constraint SBCGPRODUCTION_FK02 foreign key (SBCG_NONTERMINAL_ID) references @oracle_tess@.SBCGNONTERMINAL (SBCG_NONTERMINAL_ID);
alter table @oracle_tess@.SBCGPRODUCTION add constraint SBCGPRODUCTION_FK03 foreign key (SBCG_PRODUCTION_TYPE_ID) references @oracle_tess@.SBCGPRODUCTIONTYPE (SBCG_PRODUCTION_TYPE_ID);
alter table @oracle_tess@.SBCGPRODUCTION add constraint SBCGPRODUCTION_FK04 foreign key (SBCG_ANNOTATION_GUIDE_ID) references @oracle_tess@.SBCGANNOTATIONGUIDE (SBCG_ANNOTATION_GUIDE_ID);
alter table @oracle_tess@.SBCGPRODUCTION add constraint SBCGPRODUCTION_FK05 foreign key (SBCG_PATH_BOUND_ID) references @oracle_tess@.SBCGRECOGNITIONIMP (SBCG_RECOGNITION_ID);

/* SBCGPRODUCTIONTYPE */

/* SBCGRECOGMULTIOBS */
alter table @oracle_tess@.SBCGRECOGMULTIOBS add constraint SBCGRECOGMULTIOBS_FK01 foreign key (SBCG_RECOGNITION_ID) references @oracle_tess@.SBCGRECOGNITIONIMP (SBCG_RECOGNITION_ID);

/* SBCGRECOGNITIONIMP */
alter table @oracle_tess@.SBCGRECOGNITIONIMP add constraint SBCGRECOGNITIONIMP_FK01 foreign key (MODEL_ID) references @oracle_tess@.MODELIMP (MODEL_ID);
alter table @oracle_tess@.SBCGRECOGNITIONIMP add constraint SBCGRECOGNITIONIMP_FK02 foreign key (SBCG_NONTERMINAL_ID) references @oracle_tess@.SBCGNONTERMINAL (SBCG_NONTERMINAL_ID);
alter table @oracle_tess@.SBCGRECOGNITIONIMP add constraint SBCGRECOGNITIONIMP_FK03 foreign key (SBCG_STREAM_ID) references @oracle_tess@.SBCGSTREAM (SBCG_STREAM_ID);
alter table @oracle_tess@.SBCGRECOGNITIONIMP add constraint SBCGRECOGNITIONIMP_FK04 foreign key (PARENT_SBCG_RECOGNITION_ID) references @oracle_tess@.SBCGRECOGNITIONIMP (SBCG_RECOGNITION_ID);

/* SBCGRHSTERM */
alter table @oracle_tess@.SBCGRHSTERM add constraint SBCGRHSTERM_FK01 foreign key (SBCG_PRODUCTION_ID) references @oracle_tess@.SBCGPRODUCTION (SBCG_PRODUCTION_ID);
alter table @oracle_tess@.SBCGRHSTERM add constraint SBCGRHSTERM_FK02 foreign key (SBCG_RECOGNITION_ID) references @oracle_tess@.SBCGRECOGNITIONIMP (SBCG_RECOGNITION_ID);
alter table @oracle_tess@.SBCGRHSTERM add constraint SBCGRHSTERM_FK03 foreign key (SBCG_ANNOTATION_GUIDE_ID) references @oracle_tess@.SBCGANNOTATIONGUIDE (SBCG_ANNOTATION_GUIDE_ID);

/* SBCGSTREAM */
alter table @oracle_tess@.SBCGSTREAM add constraint SBCGSTREAM_FK01 foreign key (MODEL_ID) references @oracle_tess@.MODELIMP (MODEL_ID);

/* SBCGSTREAMPARAMETER */
alter table @oracle_tess@.SBCGSTREAMPARAMETER add constraint SBCGSTREAMPARAMETER_FK01 foreign key (SBCG_STREAM_ID) references @oracle_tess@.SBCGSTREAM (SBCG_STREAM_ID);

/* TRAININGSET */
alter table @oracle_tess@.TRAININGSET add constraint TRAININGSET_FK01 foreign key (ACTIVITY_ID) references @oracle_tess@.ACTIVITYIMP (ACTIVITY_ID);

/* TRAININGSETMEMBER */
alter table @oracle_tess@.TRAININGSETMEMBER add constraint TRAININGSETMEMBER_FK01 foreign key (TRAINING_SET_ID) references @oracle_tess@.TRAININGSET (TRAINING_SET_ID);
alter table @oracle_tess@.TRAININGSETMEMBER add constraint TRAININGSETMEMBER_FK02 foreign key (FOOTPRINT_ID) references @oracle_tess@.FOOTPRINT (FOOTPRINT_ID);



/* 83 non-primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

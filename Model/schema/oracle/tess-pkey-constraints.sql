
/*                                                                                            */
/* tess-pkey-constraints.sql                                                                  */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 12:28:53 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL tess-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table TESStest.ACTIVITYCONDITIONS add constraint PK_ACTIVITYCONDITIONS primary key (ACTIVITY_CONDITIONS_ID);
alter table TESStest.ACTIVITYIMP add constraint PK_ACTIVITYIMP primary key (ACTIVITY_ID);
alter table TESStest.ACTIVITYINFERENCESOURCE add constraint PK_ACTIVITYINFERENCESOURCE primary key (ACTIVITY_INFERENCE_SOURCE);
alter table TESStest.ANALYSIS add constraint PK_ANALYSIS primary key (ANALYSIS_ID);
alter table TESStest.FOOTPRINT add constraint PK_FOOTPRINT primary key (FOOTPRINT_ID);
alter table TESStest.FOOTPRINTMETHODPROTOCOL add constraint PK_FOOTPRINTMETHODPROTOCOL primary key (FOOTPRINT_PROTOCOL_ID);
alter table TESStest.MODEL add constraint PK_MODEL primary key (ACTIVITY_MODEL_ID);
alter table TESStest.MODELRESULT add constraint PK_MODELRESULT primary key (MODEL_RESULT_ID);
alter table TESStest.MOIETYIMP add constraint PK_MOIETYIMP primary key (MOIETY_ID);
alter table TESStest.MOIETYINSTANCE add constraint PK_MOIETYINSTANCE primary key (MOIETY_INSTANCE_ID);
alter table TESStest.MOIETYMEMBER add constraint PK_MOIETYMEMBER primary key (MOIETY_MEMBER_ID);
alter table TESStest.MOIETYSYNONYM add constraint PK_MOIETYSYNONYM primary key (MOIETY_SYNONYM_ID);
alter table TESStest.MULTINOMIALLABEL add constraint PK_MULTINOMIALLABEL primary key (MULTINOMIAL_LABEL_ID);
alter table TESStest.MULTINOMIALLABELSET add constraint PK_MULTINOMIALLABELSET primary key (MULTINOMIAL_LABEL_SET_ID);
alter table TESStest.MULTINOMIALOBSERVATION add constraint PK_MULTINOMIALOBSERVATION primary key (MULTINOMIAL_OBS_ID);
alter table TESStest.MULTINOMIALOBSERVATIONSET add constraint PK_MULTINOMIALOBSERVATIONSET primary key (MULTINOMIAL_OBS_SET_ID);
alter table TESStest.NOTE add constraint PK_NOTE primary key (NOTE_ID);
alter table TESStest.PARAMETERGROUP add constraint PK_PARAMETERGROUP primary key (PARAMETER_GROUP_ID);
alter table TESStest.PARAMETERSUBGROUP add constraint PK_PARAMETERSUBGROUP primary key (PARAMETER_SUBGROUP_ID);
alter table TESStest.PARAMETERVALUE add constraint PK_PARAMETERVALUE primary key (PARAMETER_VALUE_ID);
alter table TESStest.PARSERITEM add constraint PK_PARSERITEM primary key (PARSER_ITEM_ID);
alter table TESStest.PARSERITEMEDGETYPE add constraint PK_PARSERITEMEDGETYPE primary key (PARSER_ITEM_EDGE_TYPE_ID);
alter table TESStest.PARSERITEMLINK add constraint PK_PARSERITEMLINK primary key (PARSER_ITEM_LINK_ID);
alter table TESStest.PREDICTIONRESULT add constraint PK_PREDICTIONRESULT primary key (PREDICTION_RESULT_ID);
alter table TESStest.SBCGANNOTATIONFILTER add constraint PK_SBCGANNOTATIONFILTER primary key (SBCG_ANNOTATION_FILTER_ID);
alter table TESStest.SBCGANNOTATIONFILTERTERM add constraint PK_SBCGANNOTATIONFILTERTERM primary key (SCBG_ANNOTATION_FILTER_TERM_ID);
alter table TESStest.SBCGANNOTATIONGUIDE add constraint PK_SBCGANNOTATIONGUIDE primary key (SBCG_ANNOTATION_GUIDE_ID);
alter table TESStest.SBCGCOMPARISONTYPE add constraint PK_SBCGCOMPARISONTYPE primary key (SBCG_COMPARISON_TYPE_ID);
alter table TESStest.SBCGGRAMMAR add constraint PK_SBCGGRAMMAR primary key (SBCG_GRAMMAR_ID);
alter table TESStest.SBCGNONTERMINAL add constraint PK_SBCGNONTERMINAL primary key (SBCG_NONTERMINAL_ID);
alter table TESStest.SBCGPATHTERMRELATIONTYPE add constraint PK_SBCGPATHTERMRELATIONTYPE primary key (SBCG_PATH_TERM_REL_TYPE_ID);
alter table TESStest.SBCGPRODUCTION add constraint PK_SBCGPRODUCTION primary key (SBCG_PRODUCTION_ID);
alter table TESStest.SBCGPRODUCTIONTYPE add constraint PK_SBCGPRODUCTIONTYPE primary key (SBCG_PRODUCTION_TYPE_ID);
alter table TESStest.SBCGRECOGNITIONIMP add constraint PK_SBCGRECOGNITIONIMP primary key (SBCG_RECOGNITION_ID);
alter table TESStest.SBCGRHSTERM add constraint PK_SBCGRHSTERM primary key (SBCG_RHS_TERM_ID);
alter table TESStest.SBCGSTREAM add constraint PK_SBCGSTREAM primary key (SBCG_STREAM_ID);
alter table TESStest.SBCGSTREAMPARAMETER add constraint PK_SBCGSTREAMPARAMETER primary key (SBCG_STREAM_PARAMETER_ID);
alter table TESStest.TRAININGSET add constraint PK_TRAININGSET primary key (TRAINING_SET_ID);
alter table TESStest.TRAININGSETMEMBER add constraint PK_TRAININGSETMEMBER primary key (TRAINING_SET_MEMBER_ID);


/* 39 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

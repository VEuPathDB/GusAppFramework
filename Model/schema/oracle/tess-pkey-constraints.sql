
/*                                                                                            */
/* tess-pkey-constraints.sql                                                                  */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Dec  9 16:13:59 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL tess-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table @oracle_tess@.ACTIVITYCONDITIONS add constraint PK_ACTIVITYCONDITIONS primary key (ACTIVITY_CONDITIONS_ID);
alter table @oracle_tess@.ACTIVITYIMP add constraint PK_ACTIVITYIMP primary key (ACTIVITY_ID);
alter table @oracle_tess@.ACTIVITYINFERENCESOURCE add constraint PK_ACTIVITYINFERENCESOURCE primary key (ACTIVITY_INFERENCE_SOURCE);
alter table @oracle_tess@.ANALYSIS add constraint PK_ANALYSIS primary key (ANALYSIS_ID);
alter table @oracle_tess@.FOOTPRINT add constraint PK_FOOTPRINT primary key (FOOTPRINT_ID);
alter table @oracle_tess@.FOOTPRINTMETHODPROTOCOL add constraint PK_FOOTPRINTMETHODPROTOCOL primary key (FOOTPRINT_PROTOCOL_ID);
alter table @oracle_tess@.MODELIMP add constraint PK_MODELIMP primary key (MODEL_ID);
alter table @oracle_tess@.MODELRESULT add constraint PK_MODELRESULT primary key (MODEL_RESULT_ID);
alter table @oracle_tess@.MOIETYIMP add constraint PK_MOIETYIMP primary key (MOIETY_ID);
alter table @oracle_tess@.MOIETYINSTANCE add constraint PK_MOIETYINSTANCE primary key (MOIETY_INSTANCE_ID);
alter table @oracle_tess@.MOIETYMEMBER add constraint PK_MOIETYMEMBER primary key (MOIETY_MEMBER_ID);
alter table @oracle_tess@.MOIETYSYNONYM add constraint PK_MOIETYSYNONYM primary key (MOIETY_SYNONYM_ID);
alter table @oracle_tess@.MULTINOMIALLABEL add constraint PK_MULTINOMIALLABEL primary key (MULTINOMIAL_LABEL_ID);
alter table @oracle_tess@.MULTINOMIALLABELSET add constraint PK_MULTINOMIALLABELSET primary key (MULTINOMIAL_LABEL_SET_ID);
alter table @oracle_tess@.NOTE add constraint PK_NOTE primary key (NOTE_ID);
alter table @oracle_tess@.PARAMETERGROUP add constraint PK_PARAMETERGROUP primary key (PARAMETER_GROUP_ID);
alter table @oracle_tess@.PARAMETERSUBGROUP add constraint PK_PARAMETERSUBGROUP primary key (PARAMETER_SUBGROUP_ID);
alter table @oracle_tess@.PARAMETERVALUE add constraint PK_PARAMETERVALUE primary key (PARAMETER_VALUE_ID);
alter table @oracle_tess@.PARSERITEM add constraint PK_PARSERITEM primary key (PARSER_ITEM_ID);
alter table @oracle_tess@.PARSERITEMEDGETYPE add constraint PK_PARSERITEMEDGETYPE primary key (PARSER_ITEM_EDGE_TYPE_ID);
alter table @oracle_tess@.PARSERITEMLINK add constraint PK_PARSERITEMLINK primary key (PARSER_ITEM_LINK_ID);
alter table @oracle_tess@.PREDICTIONRESULT add constraint PK_PREDICTIONRESULT primary key (PREDICTION_RESULT_ID);
alter table @oracle_tess@.SBCGANNOTATIONFILTER add constraint PK_SBCGANNOTATIONFILTER primary key (SBCG_ANNOTATION_FILTER_ID);
alter table @oracle_tess@.SBCGANNOTATIONFILTERTERM add constraint PK_SBCGANNOTATIONFILTERTERM primary key (SCBG_ANNOTATION_FILTER_TERM_ID);
alter table @oracle_tess@.SBCGANNOTATIONGUIDE add constraint PK_SBCGANNOTATIONGUIDE primary key (SBCG_ANNOTATION_GUIDE_ID);
alter table @oracle_tess@.SBCGCOMPARISONTYPE add constraint PK_SBCGCOMPARISONTYPE primary key (SBCG_COMPARISON_TYPE_ID);
alter table @oracle_tess@.SBCGNONTERMINAL add constraint PK_SBCGNONTERMINAL primary key (SBCG_NONTERMINAL_ID);
alter table @oracle_tess@.SBCGPATHTERMRELATIONTYPE add constraint PK_SBCGPATHTERMRELATIONTYPE primary key (SBCG_PATH_TERM_REL_TYPE_ID);
alter table @oracle_tess@.SBCGPRODUCTION add constraint PK_SBCGPRODUCTION primary key (SBCG_PRODUCTION_ID);
alter table @oracle_tess@.SBCGPRODUCTIONTYPE add constraint PK_SBCGPRODUCTIONTYPE primary key (SBCG_PRODUCTION_TYPE_ID);
alter table @oracle_tess@.SBCGRECOGNITIONIMP add constraint PK_SBCGRECOGNITIONIMP primary key (SBCG_RECOGNITION_ID);
alter table @oracle_tess@.SBCGRHSTERM add constraint PK_SBCGRHSTERM primary key (SBCG_RHS_TERM_ID);
alter table @oracle_tess@.SBCGSTREAM add constraint PK_SBCGSTREAM primary key (SBCG_STREAM_ID);
alter table @oracle_tess@.SBCGSTREAMPARAMETER add constraint PK_SBCGSTREAMPARAMETER primary key (SBCG_STREAM_PARAMETER_ID);
alter table @oracle_tess@.TRAININGSET add constraint PK_TRAININGSET primary key (TRAINING_SET_ID);
alter table @oracle_tess@.TRAININGSETMEMBER add constraint PK_TRAININGSETMEMBER primary key (TRAINING_SET_MEMBER_ID);


/* 36 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

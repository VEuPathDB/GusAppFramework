
/*                                                                                            */
/* rad3ver-pkey-constraints.sql                                                               */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Feb 17 11:50:09 EST 2004     */
/*                                                                                            */

SET ECHO ON
SPOOL rad3ver-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table @oracle_radver@.ACQUISITIONPARAMVER add constraint PK_ACQUISITIONPARAMVER primary key (ACQUISITION_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ACQUISITIONVER add constraint PK_ACQUISITIONVER primary key (ACQUISITION_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ANALYSISINPUTVER add constraint PK_ANALYSISINPUTVER primary key (ANALYSIS_INPUT_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ANALYSISPARAMVER add constraint PK_ANALYSISPARAMVER primary key (ANALYSIS_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ANALYSISQCPARAMVER add constraint PK_ANALYSISQCPARAMVER primary key (ANALYSIS_QC_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ANALYSISRESULTIMPVER add constraint PK_ANALYSISRESULTIMP primary key (ANALYSIS_RESULT_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ANALYSISVER add constraint PK_ANALYSIS primary key (ANALYSIS_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ARRAYANNOTATIONVER add constraint PK_ARRAYANNOTATIONVER primary key (ARRAY_ANNOTATION_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ARRAYGROUPLINKVER add constraint PK_ARRAYGROUPLINKVER primary key (ARRAY_GROUP_LINK_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ARRAYGROUPVER add constraint PK_ARRAYGROUPVER primary key (ARRAY_GROUP_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ARRAYVER add constraint PK_ARRAYVER primary key (ARRAY_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ASSAYBIOMATERIALVER add constraint PK_ASSAYBIOMATERIALVER primary key (ASSAY_BIO_MATERIAL_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ASSAYCONTROLVER add constraint PK_ASSAYCONTROLVER primary key (ASSAY_CONTROL_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ASSAYLABELEDEXTRACTVER add constraint PK_ASSAYLABELEDEXTRACTVER primary key (ASSAY_LABELED_EXTRACT_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ASSAYPARAMVER add constraint PK_ASSAYPARAMVER primary key (ASSAY_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ASSAYVER add constraint PK_ASSAYVER primary key (ASSAY_ID,MODIFICATION_DATE);
alter table @oracle_radver@.BIOMATERIALIMPVER add constraint PK_BIOMATERIALIMPVER primary key (BIO_MATERIAL_ID,MODIFICATION_DATE);
alter table @oracle_radver@.BIOMATERIALMEASUREMENTVER add constraint PK_BIOMATERIALMEASUREMENTVER primary key (BIO_MATERIAL_MEASUREMENT_ID,MODIFICATION_DATE);
alter table @oracle_radver@.CHANNELVER add constraint PK_CHANNELVER primary key (CHANNEL_ID,MODIFICATION_DATE);
alter table @oracle_radver@.COMPOSITEELEMENTGUSVER add constraint PK_COMPOSITEELEMENTGUSVER primary key (COMPOSITE_ELEMENT_GUS_ID,MODIFICATION_DATE);
alter table @oracle_radver@.COMPOSITEELEMENTIMPVER add constraint PK_COMPOSITEELEMENTIMPVER primary key (COMPOSITE_ELEMENT_ID,MODIFICATION_DATE);
alter table @oracle_radver@.CONTROLVER add constraint PK_CONTROLVER primary key (CONTROL_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ELEMENTANNOTATIONVER add constraint PK_ELEMENTANNOTATIONVER primary key (ELEMENT_ANNOTATION_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ELEMENTIMPVER add constraint PK_ELEMENTIMPVER primary key (ELEMENT_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ELEMENTRESULTIMPVER add constraint PK_ELEMENTRESULTIMPVER primary key (ELEMENT_RESULT_ID,MODIFICATION_DATE);
alter table @oracle_radver@.INTEGRITYSTATINPUTVER add constraint PK_INTEGRITYSTATINPUTVER primary key (INTEGRITY_STAT_INPUT_ID,MODIFICATION_DATE);
alter table @oracle_radver@.INTEGRITYSTATISTICVER add constraint PK_INTEGRITYSTATISTICVER primary key (INTEGRITY_STATISTIC_ID,MODIFICATION_DATE);
alter table @oracle_radver@.LABELMETHODVER add constraint PK_LABELMETHODVER primary key (LABEL_METHOD_ID,MODIFICATION_DATE);
alter table @oracle_radver@.LOGICALGROUPLINKVER add constraint PK_LOGICALGROUPLINKVER primary key (LOGICAL_GROUP_LINK_ID,MODIFICATION_DATE);
alter table @oracle_radver@.LOGICALGROUPVER add constraint PK_LOGICALGROUPVER primary key (LOGICAL_GROUP_ID,MODIFICATION_DATE);
alter table @oracle_radver@.MAGEDOCUMENTATIONVER add constraint PK_MAGEDOCUMENTATIONVER primary key (MAGE_DOCUMENTATION_ID,MODIFICATION_DATE);
alter table @oracle_radver@.MAGE_MLVER add constraint PK_MAGE_MLVER primary key (MAGE_ML_ID,MODIFICATION_DATE);
alter table @oracle_radver@.ONTOLOGYENTRYVER add constraint PK_ONTOLOGYENTRYVER primary key (ONTOLOGY_ENTRY_ID,MODIFICATION_DATE);
alter table @oracle_radver@.PROCESSIMPLEMENTATIONVER add constraint PK_PROCESSIMPLEMENTATIONVER primary key (PROCESS_IMPLEMENTATION_ID,MODIFICATION_DATE);
alter table @oracle_radver@.PROCESSINVOCATIONPARAMVER add constraint PK_PROCESSINVOCATIONPARAMVER primary key (PROCESS_INVOCATION_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_radver@.PROCESSINVOCATIONVER add constraint PK_PROCESSINVOCATIONVER primary key (PROCESS_INVOCATION_ID,MODIFICATION_DATE);
alter table @oracle_radver@.PROCESSINVQUANTIFICATIONVER add constraint PK_PROCESSINVQUANTIFICATIONVER primary key (PROCESS_INV_QUANTIFICATION_ID,MODIFICATION_DATE);
alter table @oracle_radver@.PROCESSIOELEMENTVER add constraint PK_PROCESSIOELEMENTVER primary key (PROCESS_IO_ELEMENT_ID,MODIFICATION_DATE);
alter table @oracle_radver@.PROCESSIOVER add constraint PK_PROCESSIOVER primary key (PROCESS_IO_ID,MODIFICATION_DATE);
alter table @oracle_radver@.PROCESSRESULTVER add constraint PK_PROCESSRESULTVER primary key (PROCESS_RESULT_ID,MODIFICATION_DATE);
alter table @oracle_radver@.PROJECTLINKVER add constraint PK_PROJECTLINKVER primary key (PROJECT_LINK_ID,MODIFICATION_DATE);
alter table @oracle_radver@.PROTOCOLPARAMVER add constraint PK_PROTOCOLPARAMVER primary key (PROTOCOL_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_radver@.PROTOCOLQCPARAMVER add constraint PK_PROTOCOLQCPARAMVER primary key (PROTOCOL_QC_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_radver@.PROTOCOLVER add constraint PK_PROTOCOLVER primary key (PROTOCOL_ID,MODIFICATION_DATE);
alter table @oracle_radver@.QUANTIFICATIONPARAMVER add constraint PK_QUANTIFICATIONPARAMVER primary key (QUANTIFICATION_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_radver@.QUANTIFICATIONVER add constraint PK_QUANTIFICATIONVER primary key (QUANTIFICATION_ID,MODIFICATION_DATE);
alter table @oracle_radver@.RELATEDACQUISITIONVER add constraint PK_RELATEDACQUISITIONVER primary key (RELATED_ACQUISITION_ID,MODIFICATION_DATE);
alter table @oracle_radver@.RELATEDQUANTIFICATIONVER add constraint PK_RELATEDQUANTIFICATIONVER primary key (RELATED_QUANTIFICATION_ID,MODIFICATION_DATE);
alter table @oracle_radver@.STUDYASSAYVER add constraint PK_STUDYASSAYVER primary key (STUDY_ASSAY_ID,MODIFICATION_DATE);
alter table @oracle_radver@.STUDYBIOMATERIALVER add constraint PK_STUDYBIOMATERIALVER primary key (STUDY_BIO_MATERIAL_ID,MODIFICATION_DATE);
alter table @oracle_radver@.STUDYDESIGNASSAYVER add constraint PK_STUDYDESIGNASSAYVER primary key (STUDY_DESIGN_ASSAY_ID,MODIFICATION_DATE);
alter table @oracle_radver@.STUDYDESIGNDESCRIPTIONVER add constraint PK_STUDYDESIGNDESCRIPTIONVER primary key (STUDY_DESIGN_DESCRIPTION_ID,MODIFICATION_DATE);
alter table @oracle_radver@.STUDYDESIGNTYPEVER add constraint PK_STUDYDESIGNTYPEVER primary key (STUDY_DESIGN_TYPE_ID,MODIFICATION_DATE);
alter table @oracle_radver@.STUDYDESIGNVER add constraint PK_STUDYDESIGNVER primary key (STUDY_DESIGN_ID,MODIFICATION_DATE);
alter table @oracle_radver@.STUDYFACTORVALUEVER add constraint PK_STUDYFACTORVALUEVER primary key (STUDY_FACTOR_VALUE_ID,MODIFICATION_DATE);
alter table @oracle_radver@.STUDYFACTORVER add constraint PK_STUDYFACTORVER primary key (STUDY_FACTOR_ID,MODIFICATION_DATE);
alter table @oracle_radver@.STUDYVER add constraint PK_STUDYVER primary key (STUDY_ID,MODIFICATION_DATE);
alter table @oracle_radver@.TREATMENTPARAMVER add constraint PK_TREATMENTPARAMVER primary key (TREATMENT_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_radver@.TREATMENTVER add constraint PK_TREATMENTVER primary key (TREATMENT_ID,MODIFICATION_DATE);


/* 59 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

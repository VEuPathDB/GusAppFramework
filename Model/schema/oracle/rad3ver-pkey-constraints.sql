
/*                                                                                            */
/* rad3ver-pkey-constraints.sql                                                               */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Thu Feb 13 13:30:40 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL rad3ver-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table @oracle_rad3ver@.ACQUISITIONPARAMVER add constraint PK_ACQUISITIONPARAMVER primary key (ACQUISITION_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ACQUISITIONVER add constraint PK_ACQUISITIONVER primary key (ACQUISITION_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ANALYSISIMPLEMENTATIONVER add constraint PK_ANALYSISIMPLEMENTATIONVER primary key (ANALYSIS_IMPLEMENTATION_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ANALYSISINPUTVER add constraint PK_ANALYSISINPUTVER primary key (ANALYSIS_INPUT_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ANALYSISINVOCATIONPARAMVER add constraint PK_ANALYSISINVOCATIONPARAMVER primary key (ANALYSIS_INVOCATION_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ANALYSISINVOCATIONVER add constraint PK_ANALYSISINVOCATIONVER primary key (ANALYSIS_INVOCATION_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ANALYSISOUTPUTVER add constraint PK_ANALYSISOUTPUTVER primary key (ANALYSIS_OUTPUT_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ANALYSISVER add constraint PK_ANALYSISVER primary key (ANALYSIS_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ARRAYANNOTATIONVER add constraint PK_ARRAYANNOTATIONVER primary key (ARRAY_ANNOTATION_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ARRAYVER add constraint PK_ARRAYVER primary key (ARRAY_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ASSAYBIOMATERIALVER add constraint PK_ASSAYBIOMATERIALVER primary key (ASSAY_BIO_MATERIAL_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ASSAYLABELEDEXTRACTVER add constraint PK_ASSAYLABELEDEXTRACTVER primary key (ASSAY_LABELED_EXTRACT_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ASSAYPARAMVER add constraint PK_ASSAYPARAMVER primary key (ASSAY_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ASSAYVER add constraint PK_ASSAYVER primary key (ASSAY_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.BIOMATERIALIMPVER add constraint PK_BIOMATERIALIMPVER primary key (BIO_MATERIAL_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.BIOMATERIALMEASUREMENTVER add constraint PK_BIOMATERIALMEASUREMENTVER primary key (BIO_MATERIAL_MEASUREMENT_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.CHANNELVER add constraint PK_CHANNELVER primary key (CHANNEL_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.COMPOSITEELEMENTGUSVER add constraint PK_COMPOSITEELEMENTGUSVER primary key (COMPOSITE_ELEMENT_GUS_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.COMPOSITEELEMENTIMPVER add constraint PK_COMPOSITEELEMENTIMPVER primary key (COMPOSITE_ELEMENT_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.CONTROLVER add constraint PK_CONTROLVER primary key (CONTROL_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ELEMENTANNOTATIONVER add constraint PK_ELEMENTANNOTATIONVER primary key (ELEMENT_ANNOTATION_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ELEMENTIMPVER add constraint PK_ELEMENTIMPVER primary key (ELEMENT_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ELEMENTRESULTIMPVER add constraint PK_ELEMENTRESULTIMPVER primary key (ELEMENT_RESULT_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.LABELMETHODVER add constraint PK_LABELMETHODVER primary key (LABEL_METHOD_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.MAGEDOCUMENTATIONVER add constraint PK_MAGEDOCUMENTATIONVER primary key (MAGE_DOCUMENTATION_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.MAGE_MLVER add constraint PK_MAGE_MLVER primary key (MAGE_ML_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.ONTOLOGYENTRYVER add constraint PK_ONTOLOGYENTRYVER primary key (ONTOLOGY_ENTRY_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.PROCESSIMPLEMENTATIONVER add constraint PK_PROCESSIMPLEMENTATIONVER primary key (PROCESS_IMPLEMENTATION_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.PROCESSINVOCATIONPARAMVER add constraint PK_PROCESSINVOCATIONPARAMVER primary key (PROCESS_INVOCATION_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.PROCESSINVOCATIONVER add constraint PK_PROCESSINVOCATIONVER primary key (PROCESS_INVOCATION_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.PROCESSINVQUANTIFICATIONVER add constraint PK_PROCESSINVQUANTIFICATIONVER primary key (PROCESS_INV_QUANTIFICATION_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.PROCESSIOELEMENTVER add constraint PK_PROCESSIOELEMENTVER primary key (PROCESS_IO_ELEMENT_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.PROCESSIOVER add constraint PK_PROCESSIOVER primary key (PROCESS_IO_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.PROCESSRESULTVER add constraint PK_PROCESSRESULTVER primary key (PROCESS_RESULT_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.PROJECTLINKVER add constraint PK_PROJECTLINKVER primary key (PROJECT_LINK_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.PROTOCOLPARAMVER add constraint PK_PROTOCOLPARAMVER primary key (PROTOCOL_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.PROTOCOLVER add constraint PK_PROTOCOLVER primary key (PROTOCOL_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.QUANTIFICATIONPARAMVER add constraint PK_QUANTIFICATIONPARAMVER primary key (QUANTIFICATION_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.QUANTIFICATIONVER add constraint PK_QUANTIFICATIONVER primary key (QUANTIFICATION_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.RELATEDACQUISITIONVER add constraint PK_RELATEDACQUISITIONVER primary key (RELATED_ACQUISITION_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.RELATEDQUANTIFICATIONVER add constraint PK_RELATEDQUANTIFICATIONVER primary key (RELATED_QUANTIFICATION_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.STUDYASSAYVER add constraint PK_STUDYASSAYVER primary key (STUDY_ASSAY_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.STUDYDESIGNASSAYVER add constraint PK_STUDYDESIGNASSAYVER primary key (STUDY_DESIGN_ASSAY_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.STUDYDESIGNDESCRIPTIONVER add constraint PK_STUDYDESIGNDESCRIPTIONVER primary key (STUDY_DESIGN_DESCRIPTION_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.STUDYDESIGNTYPEVER add constraint PK_STUDYDESIGNTYPEVER primary key (STUDY_DESIGN_TYPE_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.STUDYDESIGNVER add constraint PK_STUDYDESIGNVER primary key (STUDY_DESIGN_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.STUDYFACTORVALUEVER add constraint PK_STUDYFACTORVALUEVER primary key (STUDY_FACTOR_VALUE_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.STUDYFACTORVER add constraint PK_STUDYFACTORVER primary key (STUDY_FACTOR_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.STUDYVER add constraint PK_STUDYVER primary key (STUDY_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.TREATMENTPARAMVER add constraint PK_TREATMENTPARAMVER primary key (TREATMENT_PARAM_ID,MODIFICATION_DATE);
alter table @oracle_rad3ver@.TREATMENTVER add constraint PK_TREATMENTVER primary key (TREATMENT_ID,MODIFICATION_DATE);


/* 51 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

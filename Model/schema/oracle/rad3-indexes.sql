
/*                                                                                            */
/* rad3-indexes.sql                                                                           */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Thu Feb 13 22:54:27 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL rad3-indexes.log

/* ACQUISITION */
create unique index @oracle_rad3@.ACQUISITION_AK01 on @oracle_rad3@.ACQUISITION (NAME)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ACQUISITION_IND01 on @oracle_rad3@.ACQUISITION (ASSAY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ACQUISITION_IND02 on @oracle_rad3@.ACQUISITION (CHANNEL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ACQUISITION_IND03 on @oracle_rad3@.ACQUISITION (PROTOCOL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ACQUISITIONPARAM */
create unique index @oracle_rad3@.ACQPARAM_AK01 on @oracle_rad3@.ACQUISITIONPARAM (ACQUISITION_ID,NAME)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ANALYSIS */


/* ANALYSISIMPLEMENTATION */
create index @oracle_rad3@.ANALYSISIMPLEMENTATION_IND01 on @oracle_rad3@.ANALYSISIMPLEMENTATION (ANALYSIS_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ANALYSISIMPLEMENTATIONPARAM */
create index @oracle_rad3@.ANALYSISIMPPARAM_IND01 on @oracle_rad3@.ANALYSISIMPLEMENTATIONPARAM (ANALYSIS_IMPLEMENTATION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ANALYSISINPUT */
create index @oracle_rad3@.ANALYSISINPUT_IND01 on @oracle_rad3@.ANALYSISINPUT (ANALYSIS_INVOCATION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ANALYSISINPUT_IND02 on @oracle_rad3@.ANALYSISINPUT (TABLE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ANALYSISINVOCATION */
create index @oracle_rad3@.ANALYSISINVOCATION_IND01 on @oracle_rad3@.ANALYSISINVOCATION (ANALYSIS_IMPLEMENTATION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ANALYSISINVOCATIONPARAM */
create index @oracle_rad3@.ANALYSISINVOCATIONPARAM_IND01 on @oracle_rad3@.ANALYSISINVOCATIONPARAM (ANALYSIS_INVOCATION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ANALYSISOUTPUT */
create index @oracle_rad3@.ANALYSISOUTPUT_IND01 on @oracle_rad3@.ANALYSISOUTPUT (ANALYSIS_INVOCATION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ARRAY */
create unique index @oracle_rad3@.ARRAY_AK01 on @oracle_rad3@.ARRAY (NAME,VERSION)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ARRAY_IND02 on @oracle_rad3@.ARRAY (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ARRAY_IND03 on @oracle_rad3@.ARRAY (PLATFORM_TYPE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ARRAY_IND04 on @oracle_rad3@.ARRAY (SUBSTRATE_TYPE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ARRAY_IND05 on @oracle_rad3@.ARRAY (PROTOCOL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ARRAY_IND06 on @oracle_rad3@.ARRAY (MANUFACTURER_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ARRAYANNOTATION */
create index @oracle_rad3@.ARRAYANNOTATION_IND01 on @oracle_rad3@.ARRAYANNOTATION (ARRAY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ASSAY */
create index @oracle_rad3@.ASSAY_IND01 on @oracle_rad3@.ASSAY (ARRAY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ASSAY_IND02 on @oracle_rad3@.ASSAY (OPERATOR_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ASSAY_IND03 on @oracle_rad3@.ASSAY (PROTOCOL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ASSAY_IND04 on @oracle_rad3@.ASSAY (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create unique index @oracle_rad3@.ASSAY_AK01 on @oracle_rad3@.ASSAY (NAME)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ASSAYBIOMATERIAL */
create index @oracle_rad3@.ASSAYBIOMATERIAL_IND02 on @oracle_rad3@.ASSAYBIOMATERIAL (ASSAY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ASSAYBIOMATERIAL_IND01 on @oracle_rad3@.ASSAYBIOMATERIAL (BIO_MATERIAL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ASSAYLABELEDEXTRACT */
create index @oracle_rad3@.ASSAYLABELEDEXTRACT_IND01 on @oracle_rad3@.ASSAYLABELEDEXTRACT (ASSAY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ASSAYLABELEDEXTRACT_IND02 on @oracle_rad3@.ASSAYLABELEDEXTRACT (CHANNEL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ASSAYLABELEDEXTRACT_IND03 on @oracle_rad3@.ASSAYLABELEDEXTRACT (LABELED_EXTRACT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ASSAYPARAM */
create index @oracle_rad3@.ASSAYPARAM_IND01 on @oracle_rad3@.ASSAYPARAM (ASSAY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ASSAYPARAM_IND02 on @oracle_rad3@.ASSAYPARAM (PROTOCOL_PARAM_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* BIOMATERIALCHARACTERISTIC */
create index @oracle_rad3@.BIOMATCHARACTERISTIC_IND01 on @oracle_rad3@.BIOMATERIALCHARACTERISTIC (BIO_MATERIAL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.BIOMATCHARACTERISTIC_IND02 on @oracle_rad3@.BIOMATERIALCHARACTERISTIC (ONTOLOGY_ENTRY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* BIOMATERIALIMP */
create index @oracle_rad3@.BIOMATERIALIMP_IND01 on @oracle_rad3@.BIOMATERIALIMP (LABEL_METHOD_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.BIOMATERIALIMP_IND02 on @oracle_rad3@.BIOMATERIALIMP (TAXON_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.BIOMATERIALIMP_IND03 on @oracle_rad3@.BIOMATERIALIMP (BIO_MATERIAL_TYPE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.BIOMATERIALIMP_IND04 on @oracle_rad3@.BIOMATERIALIMP (BIO_SOURCE_PROVIDER_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.BIOMATERIALIMP_IND05 on @oracle_rad3@.BIOMATERIALIMP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* BIOMATERIALMEASUREMENT */
create index @oracle_rad3@.BIOMATERIALMEASUREMENT_IND04 on @oracle_rad3@.BIOMATERIALMEASUREMENT (BIO_MATERIAL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.BIOMATERIALMEASUREMENT_IND05 on @oracle_rad3@.BIOMATERIALMEASUREMENT (UNIT_TYPE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.BIOMATERIALMEASUREMENT_IND03 on @oracle_rad3@.BIOMATERIALMEASUREMENT (TREATMENT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* CHANNEL */
create unique index @oracle_rad3@.CHANNEL_AK01 on @oracle_rad3@.CHANNEL (NAME)  TABLESPACE @oracle_rad3IndexTablespace@;

/* COMPOSITEELEMENTANNOTATION */
create index @oracle_rad3@.COMPELEMENTANNOT_IND01 on @oracle_rad3@.COMPOSITEELEMENTANNOTATION (COMPOSITE_ELEMENT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* COMPOSITEELEMENTGUS */
create index @oracle_rad3@.COMPOSITEELEMENTGUS_IND01 on @oracle_rad3@.COMPOSITEELEMENTGUS (COMPOSITE_ELEMENT_ID,TABLE_ID,ROW_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.COMPOSITEELEMENTGUS_IND02 on @oracle_rad3@.COMPOSITEELEMENTGUS (TABLE_ID,ROW_ID,COMPOSITE_ELEMENT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* COMPOSITEELEMENTIMP */
create index @oracle_rad3@.RAD3_SPOTFAMILY_IND01 on @oracle_rad3@.COMPOSITEELEMENTIMP (SMALLSTRING1,SMALLSTRING2,COMPOSITE_ELEMENT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.RAD3_SPOTFAMILY_IND02 on @oracle_rad3@.COMPOSITEELEMENTIMP (ARRAY_ID,SOURCE_ID,EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.SAGETAG_IND02 on @oracle_rad3@.COMPOSITEELEMENTIMP (PARENT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.SAGETAG_IND03 on @oracle_rad3@.COMPOSITEELEMENTIMP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.SAGETAG_IND01 on @oracle_rad3@.COMPOSITEELEMENTIMP (ARRAY_ID,TINYSTRING1)  TABLESPACE @oracle_rad3IndexTablespace@;

/* COMPOSITEELEMENTRESULTIMP */
create index @oracle_rad3@.COMPELEMENTRESULTIMP_IND01 on @oracle_rad3@.COMPOSITEELEMENTRESULTIMP (COMPOSITE_ELEMENT_ID,SUBCLASS_VIEW)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.COMPELEMENTRESULTIMP_IND02 on @oracle_rad3@.COMPOSITEELEMENTRESULTIMP (QUANTIFICATION_ID,COMPOSITE_ELEMENT_ID,SUBCLASS_VIEW)  TABLESPACE @oracle_rad3IndexTablespace@;

/* CONTROL */
create index @oracle_rad3@.CONTROL_IND01 on @oracle_rad3@.CONTROL (TABLE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.CONTROL_IND02 on @oracle_rad3@.CONTROL (ASSAY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.CONTROL_IND03 on @oracle_rad3@.CONTROL (CONTROL_TYPE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ELEMENTANNOTATION */
create index @oracle_rad3@.ELEMENTANNOTATION_IND01 on @oracle_rad3@.ELEMENTANNOTATION (ELEMENT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ELEMENTIMP */
create index @oracle_rad3@.RAD3_SPOT_IND02 on @oracle_rad3@.ELEMENTIMP (COMPOSITE_ELEMENT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.SHORTOLIGO_IND02 on @oracle_rad3@.ELEMENTIMP (ELEMENT_TYPE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.SHORTOLIGO_IND03 on @oracle_rad3@.ELEMENTIMP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.SPOT_IND01 on @oracle_rad3@.ELEMENTIMP (ARRAY_ID,CHAR1,CHAR2,CHAR3,CHAR4,CHAR5,CHAR6)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.SAGETAMAPPING_IND01 on @oracle_rad3@.ELEMENTIMP (ARRAY_ID,EXTERNAL_DATABASE_RELEASE_ID,SOURCE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ARRAY_IND01 on @oracle_rad3@.ELEMENTIMP (ARRAY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.SHORTOLIGO_IND01 on @oracle_rad3@.ELEMENTIMP (ARRAY_ID,TINYSTRING1,TINYSTRING2)  TABLESPACE @oracle_rad3IndexTablespace@;

/* ELEMENTRESULTIMP */
create index @oracle_rad3@.ELEMENTRESULTIMP_IND01 on @oracle_rad3@.ELEMENTRESULTIMP (ELEMENT_ID,SUBCLASS_VIEW)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ELEMENTRESULTIMP_IND02 on @oracle_rad3@.ELEMENTRESULTIMP (QUANTIFICATION_ID,ELEMENT_ID,SUBCLASS_VIEW)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ELEMENTRESULTIMP_IND03 on @oracle_rad3@.ELEMENTRESULTIMP (COMPOSITE_ELEMENT_RESULT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* LABELMETHOD */
create index @oracle_rad3@.LABELMETHOD_IND01 on @oracle_rad3@.LABELMETHOD (PROTOCOL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.LABELMETHOD_IND02 on @oracle_rad3@.LABELMETHOD (CHANNEL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* MAGEDOCUMENTATION */
create index @oracle_rad3@.MAGEDOCUMENTATION_IND01 on @oracle_rad3@.MAGEDOCUMENTATION (TABLE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.MAGEDOCUMENTATION_IND02 on @oracle_rad3@.MAGEDOCUMENTATION (MAGE_ML_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* MAGE_ML */


/* ONTOLOGYENTRY */
create index @oracle_rad3@.ONTOLOGYENTRY_IND01 on @oracle_rad3@.ONTOLOGYENTRY (PARENT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ONTOLOGYENTRY_IND02 on @oracle_rad3@.ONTOLOGYENTRY (TABLE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.ONTOLOGYENTRY_IND03 on @oracle_rad3@.ONTOLOGYENTRY (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create unique index @oracle_rad3@.ONTOLOGYENTRY_AK01 on @oracle_rad3@.ONTOLOGYENTRY (CATEGORY,VALUE)  TABLESPACE @oracle_rad3IndexTablespace@;

/* PROCESSIMPLEMENTATION */
create index @oracle_rad3@.PROCESSIMPLEMENTATION_IND_01 on @oracle_rad3@.PROCESSIMPLEMENTATION (PROCESS_TYPE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* PROCESSIMPLEMENTATIONPARAM */
create index @oracle_rad3@.PROCESSIMPPARAM_IND01 on @oracle_rad3@.PROCESSIMPLEMENTATIONPARAM (PROCESS_IMPLEMENTATION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* PROCESSINVOCATION */
create index @oracle_rad3@.PROCESSINVOCATION_IND01 on @oracle_rad3@.PROCESSINVOCATION (PROCESS_IMPLEMENTATION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* PROCESSINVOCATIONPARAM */
create index @oracle_rad3@.PROCESSINVOCATIONPARAM_IND01 on @oracle_rad3@.PROCESSINVOCATIONPARAM (PROCESS_INVOCATION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* PROCESSINVQUANTIFICATION */
create index @oracle_rad3@.PROCESSINVQUANTIFICATION_IND01 on @oracle_rad3@.PROCESSINVQUANTIFICATION (PROCESS_INVOCATION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.PROCESSINVQUANTIFICATION_IND02 on @oracle_rad3@.PROCESSINVQUANTIFICATION (QUANTIFICATION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* PROCESSIO */
create index @oracle_rad3@.PROCESSIO_IND_01 on @oracle_rad3@.PROCESSIO (OUTPUT_RESULT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.PROCESSIO_IND_02 on @oracle_rad3@.PROCESSIO (PROCESS_INVOCATION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.PROCESSIO_IND_03 on @oracle_rad3@.PROCESSIO (INPUT_RESULT_ID,TABLE_ID,OUTPUT_RESULT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.PROCESSIO_IND01 on @oracle_rad3@.PROCESSIO (TABLE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* PROCESSIOELEMENT */
create index @oracle_rad3@.PROCESSIOELEMENT_IND01 on @oracle_rad3@.PROCESSIOELEMENT (PROCESS_IO_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* PROCESSRESULT */
create index @oracle_rad3@.PROCESSRESULT_IND01 on @oracle_rad3@.PROCESSRESULT (PROCESS_RESULT_ID,VALUE)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.PROCESSRESULT_IND02 on @oracle_rad3@.PROCESSRESULT (UNIT_TYPE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* PROJECTLINK */
create index @oracle_rad3@.PROJECTLINK_IND03 on @oracle_rad3@.PROJECTLINK (ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.PROJECTLINK_IND02 on @oracle_rad3@.PROJECTLINK (TABLE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.PROJECTLINK_IND01 on @oracle_rad3@.PROJECTLINK (PROJECT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* PROTOCOL */
create index @oracle_rad3@.PROTOCOL_IND01 on @oracle_rad3@.PROTOCOL (BIBLIOGRAPHIC_REFERENCE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.PROTOCOL_IND02 on @oracle_rad3@.PROTOCOL (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.PROTOCOL_IND03 on @oracle_rad3@.PROTOCOL (PROTOCOL_TYPE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create unique index @oracle_rad3@.PROTOCOL_AK01 on @oracle_rad3@.PROTOCOL (NAME)  TABLESPACE @oracle_rad3IndexTablespace@;

/* PROTOCOLPARAM */
create index @oracle_rad3@.PROTOCOLPARAM_IND01 on @oracle_rad3@.PROTOCOLPARAM (DATA_TYPE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.PROTOCOLPARAM_IND02 on @oracle_rad3@.PROTOCOLPARAM (UNIT_TYPE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.PROTOCOLPARAM_IND03 on @oracle_rad3@.PROTOCOLPARAM (PROTOCOL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* QUANTIFICATION */
create unique index @oracle_rad3@.QUANTIFICATION_AK01 on @oracle_rad3@.QUANTIFICATION (NAME)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.QUANTIFICATION_IND01 on @oracle_rad3@.QUANTIFICATION (ACQUISITION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.QUANTIFICATION_IND02 on @oracle_rad3@.QUANTIFICATION (OPERATOR_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.QUANTIFICATION_IND03 on @oracle_rad3@.QUANTIFICATION (PROTOCOL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.QUANTIFICATION_IND04 on @oracle_rad3@.QUANTIFICATION (RESULT_TABLE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* QUANTIFICATIONPARAM */
create unique index @oracle_rad3@.QUANTPARAM_AK01 on @oracle_rad3@.QUANTIFICATIONPARAM (QUANTIFICATION_ID,NAME)  TABLESPACE @oracle_rad3IndexTablespace@;

/* RELATEDACQUISITION */
create index @oracle_rad3@.RELATEDACQUISITION_IND01 on @oracle_rad3@.RELATEDACQUISITION (ACQUISITION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.RELATEDACQUISITION_IND02 on @oracle_rad3@.RELATEDACQUISITION (ASSOCIATED_ACQUISITION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* RELATEDQUANTIFICATION */
create index @oracle_rad3@.RELATEDQUANTIFICATION_IND01 on @oracle_rad3@.RELATEDQUANTIFICATION (QUANTIFICATION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.RELATEDQUANTIFICATION_IND02 on @oracle_rad3@.RELATEDQUANTIFICATION (ASSOCIATED_QUANTIFICATION_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* STUDY */
create unique index @oracle_rad3@.STUDY_AK01 on @oracle_rad3@.STUDY (NAME)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.STUDY_IND01 on @oracle_rad3@.STUDY (BIBLIOGRAPHIC_REFERENCE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.STUDY_IND02 on @oracle_rad3@.STUDY (CONTACT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.STUDY_IND03 on @oracle_rad3@.STUDY (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* STUDYASSAY */
create index @oracle_rad3@.STUDYASSAY_IND01 on @oracle_rad3@.STUDYASSAY (ASSAY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.STUDYASSAY_IND02 on @oracle_rad3@.STUDYASSAY (STUDY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* STUDYDESIGN */
create index @oracle_rad3@.STUDYDESIGN_IND01 on @oracle_rad3@.STUDYDESIGN (STUDY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* STUDYDESIGNASSAY */
create index @oracle_rad3@.STUDYDESIGNASSAY_IND01 on @oracle_rad3@.STUDYDESIGNASSAY (ASSAY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.STUDYDESIGNASSAY_IND02 on @oracle_rad3@.STUDYDESIGNASSAY (STUDY_DESIGN_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* STUDYDESIGNDESCRIPTION */
create index @oracle_rad3@.STUDYDESIGNDESCRIPTION_IND01 on @oracle_rad3@.STUDYDESIGNDESCRIPTION (STUDY_DESIGN_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* STUDYDESIGNTYPE */
create index @oracle_rad3@.STUDYDESIGNTYPE_IND01 on @oracle_rad3@.STUDYDESIGNTYPE (ONTOLOGY_ENTRY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.STUDYDESIGNTYPE_IND02 on @oracle_rad3@.STUDYDESIGNTYPE (STUDY_DESIGN_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* STUDYFACTOR */
create unique index @oracle_rad3@.STUDYFACTOR_AK01 on @oracle_rad3@.STUDYFACTOR (STUDY_DESIGN_ID,NAME)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.STUDYFACTOR_IND01 on @oracle_rad3@.STUDYFACTOR (STUDY_FACTOR_TYPE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* STUDYFACTORVALUE */
create index @oracle_rad3@.STUDYFACTORVALUE_IND01 on @oracle_rad3@.STUDYFACTORVALUE (ASSAY_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.STUDYFACTORVALUE_IND02 on @oracle_rad3@.STUDYFACTORVALUE (STUDY_FACTOR_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* TREATMENT */
create index @oracle_rad3@.TREATMENT_IND01 on @oracle_rad3@.TREATMENT (BIO_MATERIAL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.TREATMENT_IND02 on @oracle_rad3@.TREATMENT (TREATMENT_TYPE_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.TREATMENT_IND03 on @oracle_rad3@.TREATMENT (PROTOCOL_ID)  TABLESPACE @oracle_rad3IndexTablespace@;

/* TREATMENTPARAM */
create index @oracle_rad3@.TREATMENTPARAM_IND01 on @oracle_rad3@.TREATMENTPARAM (PROTOCOL_PARAM_ID)  TABLESPACE @oracle_rad3IndexTablespace@;
create index @oracle_rad3@.TREATMENTPARAM_IND02 on @oracle_rad3@.TREATMENTPARAM (TREATMENT_ID)  TABLESPACE @oracle_rad3IndexTablespace@;



/* 128 index(es) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

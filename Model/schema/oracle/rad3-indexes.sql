
/*                                                                                            */
/* rad3-indexes.sql                                                                           */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Feb 17 12:47:09 EST 2004     */
/*                                                                                            */

SET ECHO ON
SPOOL rad3-indexes.log

/* ACQUISITION */
create index @oracle_rad@.ACQUISITION_IND01 on @oracle_rad@.ACQUISITION (ASSAY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ACQUISITION_IND02 on @oracle_rad@.ACQUISITION (CHANNEL_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ACQUISITION_IND03 on @oracle_rad@.ACQUISITION (PROTOCOL_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ACQUISITION_IND04 on @oracle_rad@.ACQUISITION (NAME)  TABLESPACE @oracle_radIndexTablespace@;

/* ACQUISITIONPARAM */
create unique index @oracle_rad@.ACQPARAM_AK01 on @oracle_rad@.ACQUISITIONPARAM (ACQUISITION_ID,NAME)  TABLESPACE @oracle_radIndexTablespace@;

/* ANALYSIS */


/* ANALYSISINPUT */


/* ANALYSISPARAM */


/* ANALYSISQCPARAM */


/* ANALYSISRESULTIMP */


/* ARRAY */
create unique index @oracle_rad@.ARRAY_AK01 on @oracle_rad@.ARRAY (NAME,VERSION)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ARRAY_IND02 on @oracle_rad@.ARRAY (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ARRAY_IND03 on @oracle_rad@.ARRAY (PLATFORM_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ARRAY_IND04 on @oracle_rad@.ARRAY (SUBSTRATE_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ARRAY_IND05 on @oracle_rad@.ARRAY (PROTOCOL_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ARRAY_IND06 on @oracle_rad@.ARRAY (MANUFACTURER_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* ARRAYANNOTATION */
create index @oracle_rad@.ARRAYANNOTATION_IND01 on @oracle_rad@.ARRAYANNOTATION (ARRAY_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* ARRAYGROUP */


/* ARRAYGROUPLINK */
create index @oracle_rad@.ARRAYGROUPLINK_IND01 on @oracle_rad@.ARRAYGROUPLINK (ARRAY_GROUP_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ARRAYGROUPLINK_IND02 on @oracle_rad@.ARRAYGROUPLINK (ARRAY_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* ASSAY */
create index @oracle_rad@.ASSAY_IND01 on @oracle_rad@.ASSAY (ARRAY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ASSAY_IND02 on @oracle_rad@.ASSAY (OPERATOR_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ASSAY_IND03 on @oracle_rad@.ASSAY (PROTOCOL_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ASSAY_IND04 on @oracle_rad@.ASSAY (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ASSAY_IND05 on @oracle_rad@.ASSAY (NAME)  TABLESPACE @oracle_radIndexTablespace@;

/* ASSAYBIOMATERIAL */
create index @oracle_rad@.ASSAYBIOMATERIAL_IND02 on @oracle_rad@.ASSAYBIOMATERIAL (ASSAY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ASSAYBIOMATERIAL_IND01 on @oracle_rad@.ASSAYBIOMATERIAL (BIO_MATERIAL_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* ASSAYCONTROL */
create index @oracle_rad@.ASSAYCONTROL_IND01 on @oracle_rad@.ASSAYCONTROL (ASSAY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ASSAYCONTROL_IND02 on @oracle_rad@.ASSAYCONTROL (CONTROL_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* ASSAYLABELEDEXTRACT */
create index @oracle_rad@.ASSAYLABELEDEXTRACT_IND01 on @oracle_rad@.ASSAYLABELEDEXTRACT (ASSAY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ASSAYLABELEDEXTRACT_IND02 on @oracle_rad@.ASSAYLABELEDEXTRACT (CHANNEL_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ASSAYLABELEDEXTRACT_IND03 on @oracle_rad@.ASSAYLABELEDEXTRACT (LABELED_EXTRACT_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* ASSAYPARAM */
create index @oracle_rad@.ASSAYPARAM_IND01 on @oracle_rad@.ASSAYPARAM (ASSAY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ASSAYPARAM_IND02 on @oracle_rad@.ASSAYPARAM (PROTOCOL_PARAM_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* BIOMATERIALCHARACTERISTIC */
create index @oracle_rad@.BIOMATCHARACTERISTIC_IND01 on @oracle_rad@.BIOMATERIALCHARACTERISTIC (BIO_MATERIAL_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.BIOMATCHARACTERISTIC_IND02 on @oracle_rad@.BIOMATERIALCHARACTERISTIC (ONTOLOGY_ENTRY_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* BIOMATERIALIMP */
create index @oracle_rad@.BIOMATERIALIMP_IND01 on @oracle_rad@.BIOMATERIALIMP (LABEL_METHOD_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.BIOMATERIALIMP_IND02 on @oracle_rad@.BIOMATERIALIMP (TAXON_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.BIOMATERIALIMP_IND03 on @oracle_rad@.BIOMATERIALIMP (BIO_MATERIAL_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.BIOMATERIALIMP_IND04 on @oracle_rad@.BIOMATERIALIMP (BIO_SOURCE_PROVIDER_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.BIOMATERIALIMP_IND05 on @oracle_rad@.BIOMATERIALIMP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* BIOMATERIALMEASUREMENT */
create index @oracle_rad@.BIOMATERIALMEASUREMENT_IND04 on @oracle_rad@.BIOMATERIALMEASUREMENT (BIO_MATERIAL_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.BIOMATERIALMEASUREMENT_IND05 on @oracle_rad@.BIOMATERIALMEASUREMENT (UNIT_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.BIOMATERIALMEASUREMENT_IND03 on @oracle_rad@.BIOMATERIALMEASUREMENT (TREATMENT_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* CHANNEL */
create unique index @oracle_rad@.CHANNEL_AK01 on @oracle_rad@.CHANNEL (NAME)  TABLESPACE @oracle_radIndexTablespace@;

/* COMPOSITEELEMENTANNOTATION */
create index @oracle_rad@.COMPELEMENTANNOT_IND01 on @oracle_rad@.COMPOSITEELEMENTANNOTATION (COMPOSITE_ELEMENT_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* COMPOSITEELEMENTGUS */
create index @oracle_rad@.COMPOSITEELEMENTGUS_IND01 on @oracle_rad@.COMPOSITEELEMENTGUS (COMPOSITE_ELEMENT_ID,TABLE_ID,ROW_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.COMPOSITEELEMENTGUS_IND02 on @oracle_rad@.COMPOSITEELEMENTGUS (TABLE_ID,ROW_ID,COMPOSITE_ELEMENT_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* COMPOSITEELEMENTIMP */
create index @oracle_rad@.@oracle_rad@_SPOTFAMILY_IND01 on @oracle_rad@.COMPOSITEELEMENTIMP (SMALLSTRING1,SMALLSTRING2,COMPOSITE_ELEMENT_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.@oracle_rad@_SPOTFAMILY_IND02 on @oracle_rad@.COMPOSITEELEMENTIMP (ARRAY_ID,SOURCE_ID,EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.SAGETAG_IND02 on @oracle_rad@.COMPOSITEELEMENTIMP (PARENT_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.SAGETAG_IND03 on @oracle_rad@.COMPOSITEELEMENTIMP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.@oracle_rad@_SPOTFAMILY_IND03 on @oracle_rad@.COMPOSITEELEMENTIMP (EXTERNAL_DATABASE_RELEASE_ID,ARRAY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.SAGETAG_IND01 on @oracle_rad@.COMPOSITEELEMENTIMP (ARRAY_ID,TINYSTRING1)  TABLESPACE @oracle_radIndexTablespace@;

/* COMPOSITEELEMENTRESULTIMP */
create index @oracle_rad@.COMPELEMENTRESULTIMP_IND01 on @oracle_rad@.COMPOSITEELEMENTRESULTIMP (COMPOSITE_ELEMENT_ID,SUBCLASS_VIEW)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.COMPELEMENTRESULTIMP_IND02 on @oracle_rad@.COMPOSITEELEMENTRESULTIMP (QUANTIFICATION_ID,COMPOSITE_ELEMENT_ID,SUBCLASS_VIEW)  TABLESPACE @oracle_radIndexTablespace@;

/* CONTROL */
create index @oracle_rad@.CONTROL_IND01 on @oracle_rad@.CONTROL (TABLE_ID,ROW_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.CONTROL_IND02 on @oracle_rad@.CONTROL (CONTROL_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* ELEMENTANNOTATION */
create index @oracle_rad@.ELEMENTANNOTATION_IND01 on @oracle_rad@.ELEMENTANNOTATION (ELEMENT_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* ELEMENTIMP */
create index @oracle_rad@.@oracle_rad@_SPOT_IND02 on @oracle_rad@.ELEMENTIMP (COMPOSITE_ELEMENT_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.SHORTOLIGO_IND02 on @oracle_rad@.ELEMENTIMP (ELEMENT_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.SHORTOLIGO_IND03 on @oracle_rad@.ELEMENTIMP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.SAGETAGMAPPING_IND01 on @oracle_rad@.ELEMENTIMP (SOURCE_ID,COMPOSITE_ELEMENT_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.SPOT_IND01 on @oracle_rad@.ELEMENTIMP (ARRAY_ID,CHAR1,CHAR2,CHAR3,CHAR4,CHAR5,CHAR6)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ARRAY_IND01 on @oracle_rad@.ELEMENTIMP (ARRAY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.SHORTOLIGO_IND01 on @oracle_rad@.ELEMENTIMP (ARRAY_ID,TINYSTRING1,TINYSTRING2)  TABLESPACE @oracle_radIndexTablespace@;

/* ELEMENTRESULTIMP */
create index @oracle_rad@.ELEMENTRESULTIMP_IND01 on @oracle_rad@.ELEMENTRESULTIMP (ELEMENT_ID,SUBCLASS_VIEW)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ELEMENTRESULTIMP_IND02 on @oracle_rad@.ELEMENTRESULTIMP (QUANTIFICATION_ID,ELEMENT_ID,SUBCLASS_VIEW)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ELEMENTRESULTIMP_IND03 on @oracle_rad@.ELEMENTRESULTIMP (COMPOSITE_ELEMENT_RESULT_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* INTEGRITYSTATINPUT */
create index @oracle_rad@.INTEGRITYSTATINPUT_IND01 on @oracle_rad@.INTEGRITYSTATINPUT (INTEGRITY_STATISTIC_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.INTEGRITYSTATINPUT_IND02 on @oracle_rad@.INTEGRITYSTATINPUT (INPUT_TABLE_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* INTEGRITYSTATISTIC */


/* LABELMETHOD */
create index @oracle_rad@.LABELMETHOD_IND01 on @oracle_rad@.LABELMETHOD (PROTOCOL_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.LABELMETHOD_IND02 on @oracle_rad@.LABELMETHOD (CHANNEL_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* LOGICALGROUP */


/* LOGICALGROUPLINK */


/* MAGEDOCUMENTATION */
create index @oracle_rad@.MAGEDOCUMENTATION_IND01 on @oracle_rad@.MAGEDOCUMENTATION (TABLE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.MAGEDOCUMENTATION_IND02 on @oracle_rad@.MAGEDOCUMENTATION (MAGE_ML_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* MAGE_ML */


/* ONTOLOGYENTRY */
create index @oracle_rad@.ONTOLOGYENTRY_IND01 on @oracle_rad@.ONTOLOGYENTRY (PARENT_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ONTOLOGYENTRY_IND02 on @oracle_rad@.ONTOLOGYENTRY (TABLE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.ONTOLOGYENTRY_IND03 on @oracle_rad@.ONTOLOGYENTRY (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create unique index @oracle_rad@.ONTOLOGYENTRY_AK01 on @oracle_rad@.ONTOLOGYENTRY (CATEGORY,VALUE)  TABLESPACE @oracle_radIndexTablespace@;

/* PROCESSIMPLEMENTATION */
create index @oracle_rad@.PROCESSIMPLEMENTATION_IND_01 on @oracle_rad@.PROCESSIMPLEMENTATION (PROCESS_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* PROCESSIMPLEMENTATIONPARAM */
create index @oracle_rad@.PROCESSIMPPARAM_IND01 on @oracle_rad@.PROCESSIMPLEMENTATIONPARAM (PROCESS_IMPLEMENTATION_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* PROCESSINVOCATION */
create index @oracle_rad@.PROCESSINVOCATION_IND01 on @oracle_rad@.PROCESSINVOCATION (PROCESS_IMPLEMENTATION_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* PROCESSINVOCATIONPARAM */
create index @oracle_rad@.PROCESSINVOCATIONPARAM_IND01 on @oracle_rad@.PROCESSINVOCATIONPARAM (PROCESS_INVOCATION_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* PROCESSINVQUANTIFICATION */
create index @oracle_rad@.PROCESSINVQUANTIFICATION_IND01 on @oracle_rad@.PROCESSINVQUANTIFICATION (PROCESS_INVOCATION_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.PROCESSINVQUANTIFICATION_IND02 on @oracle_rad@.PROCESSINVQUANTIFICATION (QUANTIFICATION_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* PROCESSIO */
create index @oracle_rad@.PROCESSIO_IND_01 on @oracle_rad@.PROCESSIO (OUTPUT_RESULT_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.PROCESSIO_IND_02 on @oracle_rad@.PROCESSIO (PROCESS_INVOCATION_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.PROCESSIO_IND_03 on @oracle_rad@.PROCESSIO (INPUT_RESULT_ID,TABLE_ID,OUTPUT_RESULT_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.PROCESSIO_IND01 on @oracle_rad@.PROCESSIO (TABLE_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* PROCESSIOELEMENT */
create index @oracle_rad@.PROCESSIOELEMENT_IND01 on @oracle_rad@.PROCESSIOELEMENT (PROCESS_IO_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* PROCESSRESULT */
create index @oracle_rad@.PROCESSRESULT_IND01 on @oracle_rad@.PROCESSRESULT (PROCESS_RESULT_ID,VALUE)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.PROCESSRESULT_IND02 on @oracle_rad@.PROCESSRESULT (UNIT_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* PROJECTLINK */
create unique index @oracle_rad@.PROJECTLINK_AK01 on @oracle_rad@.PROJECTLINK (PROJECT_ID,TABLE_ID,ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.PROJECTLINK_IND03 on @oracle_rad@.PROJECTLINK (ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.PROJECTLINK_IND02 on @oracle_rad@.PROJECTLINK (TABLE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.PROJECTLINK_IND01 on @oracle_rad@.PROJECTLINK (PROJECT_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* PROTOCOL */
create index @oracle_rad@.PROTOCOL_IND01 on @oracle_rad@.PROTOCOL (PROTOCOL_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.PROTOCOL_IND02 on @oracle_rad@.PROTOCOL (SOFTWARE_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.PROTOCOL_IND03 on @oracle_rad@.PROTOCOL (HARDWARE_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* PROTOCOLPARAM */
create index @oracle_rad@.PROTOCOLPARAM_IND01 on @oracle_rad@.PROTOCOLPARAM (DATA_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.PROTOCOLPARAM_IND02 on @oracle_rad@.PROTOCOLPARAM (UNIT_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.PROTOCOLPARAM_IND03 on @oracle_rad@.PROTOCOLPARAM (PROTOCOL_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* PROTOCOLQCPARAM */


/* QUANTIFICATION */
create index @oracle_rad@.QUANTIFICATION_IND05 on @oracle_rad@.QUANTIFICATION (NAME)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.QUANTIFICATION_IND01 on @oracle_rad@.QUANTIFICATION (ACQUISITION_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.QUANTIFICATION_IND02 on @oracle_rad@.QUANTIFICATION (OPERATOR_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.QUANTIFICATION_IND03 on @oracle_rad@.QUANTIFICATION (PROTOCOL_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.QUANTIFICATION_IND04 on @oracle_rad@.QUANTIFICATION (RESULT_TABLE_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* QUANTIFICATIONPARAM */
create unique index @oracle_rad@.QUANTPARAM_AK01 on @oracle_rad@.QUANTIFICATIONPARAM (QUANTIFICATION_ID,NAME)  TABLESPACE @oracle_radIndexTablespace@;

/* RELATEDACQUISITION */
create index @oracle_rad@.RELATEDACQUISITION_IND01 on @oracle_rad@.RELATEDACQUISITION (ACQUISITION_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.RELATEDACQUISITION_IND02 on @oracle_rad@.RELATEDACQUISITION (ASSOCIATED_ACQUISITION_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* RELATEDQUANTIFICATION */
create index @oracle_rad@.RELATEDQUANTIFICATION_IND01 on @oracle_rad@.RELATEDQUANTIFICATION (QUANTIFICATION_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.RELATEDQUANTIFICATION_IND02 on @oracle_rad@.RELATEDQUANTIFICATION (ASSOCIATED_QUANTIFICATION_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* STUDY */
create unique index @oracle_rad@.STUDY_AK01 on @oracle_rad@.STUDY (NAME)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.STUDY_IND01 on @oracle_rad@.STUDY (BIBLIOGRAPHIC_REFERENCE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.STUDY_IND02 on @oracle_rad@.STUDY (CONTACT_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.STUDY_IND03 on @oracle_rad@.STUDY (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* STUDYASSAY */
create index @oracle_rad@.STUDYASSAY_IND01 on @oracle_rad@.STUDYASSAY (ASSAY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.STUDYASSAY_IND02 on @oracle_rad@.STUDYASSAY (STUDY_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* STUDYBIOMATERIAL */
create index @oracle_rad@.STUDYBIOMATERIAL_IND01 on @oracle_rad@.STUDYBIOMATERIAL (STUDY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.STUDYBIOMATERIAL_IND02 on @oracle_rad@.STUDYBIOMATERIAL (BIO_MATERIAL_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* STUDYDESIGN */
create index @oracle_rad@.STUDYDESIGN_IND01 on @oracle_rad@.STUDYDESIGN (STUDY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create unique index @oracle_rad@.STUDYDESIGN_AK01 on @oracle_rad@.STUDYDESIGN (STUDY_ID,NAME)  TABLESPACE @oracle_radIndexTablespace@;

/* STUDYDESIGNASSAY */
create index @oracle_rad@.STUDYDESIGNASSAY_IND01 on @oracle_rad@.STUDYDESIGNASSAY (ASSAY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.STUDYDESIGNASSAY_IND02 on @oracle_rad@.STUDYDESIGNASSAY (STUDY_DESIGN_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* STUDYDESIGNDESCRIPTION */
create index @oracle_rad@.STUDYDESIGNDESCRIPTION_IND01 on @oracle_rad@.STUDYDESIGNDESCRIPTION (STUDY_DESIGN_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* STUDYDESIGNTYPE */
create index @oracle_rad@.STUDYDESIGNTYPE_IND01 on @oracle_rad@.STUDYDESIGNTYPE (ONTOLOGY_ENTRY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.STUDYDESIGNTYPE_IND02 on @oracle_rad@.STUDYDESIGNTYPE (STUDY_DESIGN_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* STUDYFACTOR */
create unique index @oracle_rad@.STUDYFACTOR_AK01 on @oracle_rad@.STUDYFACTOR (STUDY_DESIGN_ID,NAME)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.STUDYFACTOR_IND01 on @oracle_rad@.STUDYFACTOR (STUDY_FACTOR_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* STUDYFACTORVALUE */
create index @oracle_rad@.STUDYFACTORVALUE_IND01 on @oracle_rad@.STUDYFACTORVALUE (ASSAY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.STUDYFACTORVALUE_IND02 on @oracle_rad@.STUDYFACTORVALUE (STUDY_FACTOR_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.STUDYFACTORVALUE_IND03 on @oracle_rad@.STUDYFACTORVALUE (VALUE_ONTOLOGY_ENTRY_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.STUDYFACTORVALUE_IND04 on @oracle_rad@.STUDYFACTORVALUE (MEASUREMENT_UNIT_OE_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* TREATMENT */
create index @oracle_rad@.TREATMENT_IND01 on @oracle_rad@.TREATMENT (BIO_MATERIAL_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.TREATMENT_IND02 on @oracle_rad@.TREATMENT (TREATMENT_TYPE_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.TREATMENT_IND03 on @oracle_rad@.TREATMENT (PROTOCOL_ID)  TABLESPACE @oracle_radIndexTablespace@;

/* TREATMENTPARAM */
create index @oracle_rad@.TREATMENTPARAM_IND01 on @oracle_rad@.TREATMENTPARAM (PROTOCOL_PARAM_ID)  TABLESPACE @oracle_radIndexTablespace@;
create index @oracle_rad@.TREATMENTPARAM_IND02 on @oracle_rad@.TREATMENTPARAM (TREATMENT_ID)  TABLESPACE @oracle_radIndexTablespace@;



/* 132 index(es) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

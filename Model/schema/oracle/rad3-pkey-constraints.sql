
/*                                                                                            */
/* rad3-pkey-constraints.sql                                                                  */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Dec  9 16:09:11 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL rad3-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table @oracle_rad@.ACQUISITION add constraint PK_ACQUISITION primary key (ACQUISITION_ID);
alter table @oracle_rad@.ACQUISITIONPARAM add constraint PK_ACQUISITIONPARAM primary key (ACQUISITION_PARAM_ID);
alter table @oracle_rad@.ANALYSIS add constraint PK_ANALYSIS primary key (ANALYSIS_ID);
alter table @oracle_rad@.ANALYSISINPUT add constraint PK_ANALYSISINPUT primary key (ANALYSIS_INPUT_ID);
alter table @oracle_rad@.ANALYSISPARAM add constraint PK_ANALYSISPARAM primary key (ANALYSIS_PARAM_ID);
alter table @oracle_rad@.ANALYSISQCPARAM add constraint PK_ANALYSISQCPARAM primary key (ANALYSIS_QC_PARAM_ID);
alter table @oracle_rad@.ANALYSISRESULTIMP add constraint PK_ANALYSISRESULTIMP primary key (ANALYSIS_RESULT_ID);
alter table @oracle_rad@.ARRAY add constraint PK_ARRAY primary key (ARRAY_ID);
alter table @oracle_rad@.ARRAYANNOTATION add constraint PK_ARRAYANNOTATION primary key (ARRAY_ANNOTATION_ID);
alter table @oracle_rad@.ARRAYGROUP add constraint PK_ARRAYGROUP primary key (ARRAY_GROUP_ID);
alter table @oracle_rad@.ARRAYGROUPLINK add constraint PK_ARRAYGROUPLINK primary key (ARRAY_GROUP_LINK_ID);
alter table @oracle_rad@.ASSAY add constraint PK_ASSAY primary key (ASSAY_ID);
alter table @oracle_rad@.ASSAYBIOMATERIAL add constraint PK_ASSAYBIOMATERIAL primary key (ASSAY_BIO_MATERIAL_ID);
alter table @oracle_rad@.ASSAYCONTROL add constraint PK_ASSAYCONTROL primary key (ASSAY_CONTROL_ID);
alter table @oracle_rad@.ASSAYLABELEDEXTRACT add constraint PK_ASSAYLABELEDEXTRACT primary key (ASSAY_LABELED_EXTRACT_ID);
alter table @oracle_rad@.ASSAYPARAM add constraint PK_ASSAYPARAM primary key (ASSAY_PARAM_ID);
alter table @oracle_rad@.BIOMATERIALCHARACTERISTIC add constraint PK_BIOAMATCHARACTERISTIC primary key (BIO_MATERIAL_CHARACTERISTIC_ID);
alter table @oracle_rad@.BIOMATERIALIMP add constraint PK_BIOMATERIALIMP primary key (BIO_MATERIAL_ID);
alter table @oracle_rad@.BIOMATERIALMEASUREMENT add constraint PK_BIOMATERIALMEASUREMENT primary key (BIO_MATERIAL_MEASUREMENT_ID);
alter table @oracle_rad@.CHANNEL add constraint PK_CHANNEL primary key (CHANNEL_ID);
alter table @oracle_rad@.COMPOSITEELEMENTANNOTATION add constraint PK_COMPOSITEELEMENTANNOTATION primary key (COMPOSITE_ELEMENT_ANNOT_ID);
alter table @oracle_rad@.COMPOSITEELEMENTGUS add constraint PK_COMPOSITEELEMENTGUS primary key (COMPOSITE_ELEMENT_GUS_ID);
alter table @oracle_rad@.COMPOSITEELEMENTIMP add constraint PK_COMPOSITEELEMENTIMP primary key (COMPOSITE_ELEMENT_ID);
alter table @oracle_rad@.COMPOSITEELEMENTRESULTIMP add constraint PK_SFMRES primary key (COMPOSITE_ELEMENT_RESULT_ID);
alter table @oracle_rad@.CONTROL add constraint PK_CONTROL primary key (CONTROL_ID);
alter table @oracle_rad@.ELEMENTANNOTATION add constraint PK_ELEMENTANNOTATION primary key (ELEMENT_ANNOTATION_ID);
alter table @oracle_rad@.ELEMENTIMP add constraint PK_ELEMENT primary key (ELEMENT_ID);
alter table @oracle_rad@.ELEMENTRESULTIMP add constraint PK_ELEMENTRESULT_N primary key (ELEMENT_RESULT_ID);
alter table @oracle_rad@.INTEGRITYSTATINPUT add constraint PK_INTEGRITYSTATINPUT primary key (INTEGRITY_STAT_INPUT_ID);
alter table @oracle_rad@.INTEGRITYSTATISTIC add constraint PK_INTEGRITYSTATISTIC primary key (INTEGRITY_STATISTIC_ID);
alter table @oracle_rad@.LABELMETHOD add constraint PK_LABEL primary key (LABEL_METHOD_ID);
alter table @oracle_rad@.LOGICALGROUP add constraint PK_LOGICALGROUP primary key (LOGICAL_GROUP_ID);
alter table @oracle_rad@.LOGICALGROUPLINK add constraint PK_LOGICALGROUPLINK primary key (LOGICAL_GROUP_LINK_ID);
alter table @oracle_rad@.MAGEDOCUMENTATION add constraint PK_MAGEDOCUMENTATION primary key (MAGE_DOCUMENTATION_ID);
alter table @oracle_rad@.MAGE_ML add constraint PK_MAGEML primary key (MAGE_ML_ID);
alter table @oracle_rad@.ONTOLOGYENTRY add constraint PK_ONTOLOGYENTRY primary key (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.PROCESSIMPLEMENTATION add constraint PK_PROCESSIMPLEMENTATION primary key (PROCESS_IMPLEMENTATION_ID);
alter table @oracle_rad@.PROCESSIMPLEMENTATIONPARAM add constraint PK_PROCESSIMPPARAM primary key (PROCESS_IMPLEMETATION_PARAM_ID);
alter table @oracle_rad@.PROCESSINVOCATION add constraint PK_PROCESSINV primary key (PROCESS_INVOCATION_ID);
alter table @oracle_rad@.PROCESSINVOCATIONPARAM add constraint PK_PROCESSINVOCATIONPARAM primary key (PROCESS_INVOCATION_PARAM_ID);
alter table @oracle_rad@.PROCESSINVQUANTIFICATION add constraint PK_PROCESSINVQUANT primary key (PROCESS_INV_QUANTIFICATION_ID);
alter table @oracle_rad@.PROCESSIO add constraint PK_PROCESSIO primary key (PROCESS_IO_ID);
alter table @oracle_rad@.PROCESSIOELEMENT add constraint PK_PROCESSIOELEMENT primary key (PROCESS_IO_ELEMENT_ID);
alter table @oracle_rad@.PROCESSRESULT add constraint PK_RESULT5 primary key (PROCESS_RESULT_ID);
alter table @oracle_rad@.PROJECTLINK add constraint PK_PROJECTLINK primary key (PROJECT_LINK_ID);
alter table @oracle_rad@.PROTOCOL add constraint PK_PROTOCOL primary key (PROTOCOL_ID);
alter table @oracle_rad@.PROTOCOLPARAM add constraint PK_PROTOCOLPARAM primary key (PROTOCOL_PARAM_ID);
alter table @oracle_rad@.PROTOCOLQCPARAM add constraint PK_PROTOCOLQCPARAM primary key (PROTOCOL_QC_PARAM_ID);
alter table @oracle_rad@.QUANTIFICATION add constraint PK_QUANTIFICATION primary key (QUANTIFICATION_ID);
alter table @oracle_rad@.QUANTIFICATIONPARAM add constraint PK_QUANTIFICATIONPARAM primary key (QUANTIFICATION_PARAM_ID);
alter table @oracle_rad@.RELATEDACQUISITION add constraint PK_RELASSAY primary key (RELATED_ACQUISITION_ID);
alter table @oracle_rad@.RELATEDQUANTIFICATION add constraint PK_RELATEDQUANTIFICATION primary key (RELATED_QUANTIFICATION_ID);
alter table @oracle_rad@.STUDY add constraint PK_STUDY primary key (STUDY_ID);
alter table @oracle_rad@.STUDYASSAY add constraint PK_STUDYASSAY primary key (STUDY_ASSAY_ID);
alter table @oracle_rad@.STUDYBIOMATERIAL add constraint PK_STUDYBIOMATERIAL primary key (STUDY_BIO_MATERIAL_ID);
alter table @oracle_rad@.STUDYDESIGN add constraint PK_STUDYDESIGN primary key (STUDY_DESIGN_ID);
alter table @oracle_rad@.STUDYDESIGNASSAY add constraint PK_STUDYDESIGNASSAY primary key (STUDY_DESIGN_ASSAY_ID);
alter table @oracle_rad@.STUDYDESIGNDESCRIPTION add constraint PK_STUDYDESIGNDESCR primary key (STUDY_DESIGN_DESCRIPTION_ID);
alter table @oracle_rad@.STUDYDESIGNTYPE add constraint PK_STUDYDESIGNTYPE primary key (STUDY_DESIGN_TYPE_ID);
alter table @oracle_rad@.STUDYFACTOR add constraint PK_STUDYFACTOR primary key (STUDY_FACTOR_ID);
alter table @oracle_rad@.STUDYFACTORVALUE add constraint PK_STUDYFACTORVAL primary key (STUDY_FACTOR_VALUE_ID);
alter table @oracle_rad@.TREATMENT add constraint PK_TREATMENT primary key (TREATMENT_ID);
alter table @oracle_rad@.TREATMENTPARAM add constraint PK_TREATMENTPARAM primary key (TREATMENT_PARAM_ID);


/* 63 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT


/*                                                                                            */
/* rad3-pkey-constraints.sql                                                                  */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 04:00:20 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL rad3-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table @oracle_rad3@.ACQUISITION add constraint PK_ACQUISITION primary key (ACQUISITION_ID);
alter table @oracle_rad3@.ACQUISITIONPARAM add constraint PK_ACQUISITIONPARAM primary key (ACQUISITION_PARAM_ID);
alter table @oracle_rad3@.ANALYSIS add constraint PK_ANALYSIS primary key (ANALYSIS_ID);
alter table @oracle_rad3@.ANALYSISIMPLEMENTATION add constraint PK_ANALYSISIMPLEMENTATION3 primary key (ANALYSIS_IMPLEMENTATION_ID);
alter table @oracle_rad3@.ANALYSISIMPLEMENTATIONPARAM add constraint PK_ANALYSISIMPLPARAM primary key (ANALYSIS_IMP_PARAM_ID);
alter table @oracle_rad3@.ANALYSISINPUT add constraint PK_ANALYSISINPUT primary key (ANALYSIS_INPUT_ID);
alter table @oracle_rad3@.ANALYSISINVOCATION add constraint PK_ANALYSISINVOCATION primary key (ANALYSIS_INVOCATION_ID);
alter table @oracle_rad3@.ANALYSISINVOCATIONPARAM add constraint PK_ANAYLSISINVOCATIONPARAM primary key (ANALYSIS_INVOCATION_PARAM_ID);
alter table @oracle_rad3@.ANALYSISOUTPUT add constraint PK_ANALYSISOUTPUT primary key (ANALYSIS_OUTPUT_ID);
alter table @oracle_rad3@.ARRAY add constraint PK_ARRAY primary key (ARRAY_ID);
alter table @oracle_rad3@.ARRAYANNOTATION add constraint PK_ARRAYANNOTATION primary key (ARRAY_ANNOTATION_ID);
alter table @oracle_rad3@.ASSAY add constraint PK_ASSAY primary key (ASSAY_ID);
alter table @oracle_rad3@.ASSAYBIOMATERIAL add constraint PK_ASSAYBIOMATERIAL primary key (ASSAY_BIO_MATERIAL_ID);
alter table @oracle_rad3@.ASSAYLABELEDEXTRACT add constraint PK_ASSAYLABELEDEXTRACT primary key (ASSAY_LABELED_EXTRACT_ID);
alter table @oracle_rad3@.ASSAYPARAM add constraint PK_ASSAYPARAM primary key (ASSAY_PARAM_ID);
alter table @oracle_rad3@.BIOMATERIALCHARACTERISTIC add constraint PK_BIOAMATCHARACTERISTIC primary key (BIO_MATERIAL_CHARACTERISTIC_ID);
alter table @oracle_rad3@.BIOMATERIALIMP add constraint PK_BIOMATERIALIMP primary key (BIO_MATERIAL_ID);
alter table @oracle_rad3@.BIOMATERIALMEASUREMENT add constraint PK_BIOMATERIALMEASUREMENT primary key (BIO_MATERIAL_MEASUREMENT_ID);
alter table @oracle_rad3@.CHANNEL add constraint PK_CHANNEL primary key (CHANNEL_ID);
alter table @oracle_rad3@.COMPOSITEELEMENTANNOTATION add constraint PK_COMPOSITEELEMENTANNOTATION primary key (COMPOSITE_ELEMENT_ANNOT_ID);
alter table @oracle_rad3@.COMPOSITEELEMENTGUS add constraint PK_COMPOSITEELEMENTGUS primary key (COMPOSITE_ELEMENT_GUS_ID);
alter table @oracle_rad3@.COMPOSITEELEMENTIMP add constraint PK_COMPOSITEELEMENTIMP primary key (COMPOSITE_ELEMENT_ID);
alter table @oracle_rad3@.COMPOSITEELEMENTRESULTIMP add constraint PK_SFMRES primary key (COMPOSITE_ELEMENT_RESULT_ID);
alter table @oracle_rad3@.CONTROL add constraint PK_CONTROL primary key (CONTROL_ID);
alter table @oracle_rad3@.ELEMENTANNOTATION add constraint PK_ELEMENTANNOTATION primary key (ELEMENT_ANNOTATION_ID);
alter table @oracle_rad3@.ELEMENTIMP add constraint PK_ELEMENT primary key (ELEMENT_ID);
alter table @oracle_rad3@.ELEMENTRESULTIMP add constraint PK_ELEMENTRESULT_N primary key (ELEMENT_RESULT_ID);
alter table @oracle_rad3@.LABELMETHOD add constraint PK_LABEL primary key (LABEL_METHOD_ID);
alter table @oracle_rad3@.MAGEDOCUMENTATION add constraint PK_MAGEDOCUMENTATION primary key (MAGE_DOCUMENTATION_ID);
alter table @oracle_rad3@.MAGE_ML add constraint PK_MAGEML primary key (MAGE_ML_ID);
alter table @oracle_rad3@.ONTOLOGYENTRY add constraint PK_ONTOLOGYENTRY primary key (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad3@.PROCESSIMPLEMENTATION add constraint PK_PROCESSIMPLEMENTATION primary key (PROCESS_IMPLEMENTATION_ID);
alter table @oracle_rad3@.PROCESSIMPLEMENTATIONPARAM add constraint PK_PROCESSIMPPARAM primary key (PROCESS_IMPLEMETATION_PARAM_ID);
alter table @oracle_rad3@.PROCESSINVOCATION add constraint PK_PROCESSINV primary key (PROCESS_INVOCATION_ID);
alter table @oracle_rad3@.PROCESSINVOCATIONPARAM add constraint PK_PROCESSINVOCATIONPARAM primary key (PROCESS_INVOCATION_PARAM_ID);
alter table @oracle_rad3@.PROCESSINVQUANTIFICATION add constraint PK_PROCESSINVQUANT primary key (PROCESS_INV_QUANTIFICATION_ID);
alter table @oracle_rad3@.PROCESSIO add constraint PK_PROCESSIO primary key (PROCESS_IO_ID);
alter table @oracle_rad3@.PROCESSIOELEMENT add constraint PK_PROCESSIOELEMENT primary key (PROCESS_IO_ELEMENT_ID);
alter table @oracle_rad3@.PROCESSRESULT add constraint PK_RESULT5 primary key (PROCESS_RESULT_ID);
alter table @oracle_rad3@.PROJECTLINK add constraint PK_PROJECTLINK primary key (PROJECT_LINK_ID);
alter table @oracle_rad3@.PROTOCOL add constraint PK_PROTOCOL primary key (PROTOCOL_ID);
alter table @oracle_rad3@.PROTOCOLPARAM add constraint PK_PROTOCOLPARAM primary key (PROTOCOL_PARAM_ID);
alter table @oracle_rad3@.QUANTIFICATION add constraint PK_QUANTIFICATION primary key (QUANTIFICATION_ID);
alter table @oracle_rad3@.QUANTIFICATIONPARAM add constraint PK_QUANTIFICATIONPARAM primary key (QUANTIFICATION_PARAM_ID);
alter table @oracle_rad3@.RELATEDACQUISITION add constraint PK_RELASSAY primary key (RELATED_ACQUISITION_ID);
alter table @oracle_rad3@.RELATEDQUANTIFICATION add constraint PK_RELATEDQUANTIFICATION primary key (RELATED_QUANTIFICATION_ID);
alter table @oracle_rad3@.STUDY add constraint PK_STUDY primary key (STUDY_ID);
alter table @oracle_rad3@.STUDYASSAY add constraint PK_STUDYASSAY primary key (STUDY_ASSAY_ID);
alter table @oracle_rad3@.STUDYDESIGN add constraint PK_STUDYDESIGN primary key (STUDY_DESIGN_ID);
alter table @oracle_rad3@.STUDYDESIGNASSAY add constraint PK_STUDYDESIGNASSAY primary key (STUDY_DESIGN_ASSAY_ID);
alter table @oracle_rad3@.STUDYDESIGNDESCRIPTION add constraint PK_STUDYDESIGNDESCR primary key (STUDY_DESIGN_DESCRIPTION_ID);
alter table @oracle_rad3@.STUDYDESIGNTYPE add constraint PK_STUDYDESIGNTYPE primary key (STUDY_DESIGN_TYPE_ID);
alter table @oracle_rad3@.STUDYFACTOR add constraint PK_STUDYFACTOR primary key (STUDY_FACTOR_ID);
alter table @oracle_rad3@.STUDYFACTORVALUE add constraint PK_STUDYFACTORVAL primary key (STUDY_FACTOR_VALUE_ID);
alter table @oracle_rad3@.TREATMENT add constraint PK_TREATMENT primary key (TREATMENT_ID);
alter table @oracle_rad3@.TREATMENTPARAM add constraint PK_TREATMENTPARAM primary key (TREATMENT_PARAM_ID);


/* 56 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT


/*                                                                                            */
/* rad3-pkey-constraints.sql                                                                  */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 12:30:10 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL rad3-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table RAD3test.ACQUISITION add constraint PK_ACQUISITION primary key (ACQUISITION_ID);
alter table RAD3test.ACQUISITIONPARAM add constraint PK_ACQUISITIONPARAM primary key (ACQUISITION_PARAM_ID);
alter table RAD3test.ANALYSIS add constraint PK_ANALYSIS primary key (ANALYSIS_ID);
alter table RAD3test.ANALYSISIMPLEMENTATION add constraint PK_ANALYSISIMPLEMENTATION3 primary key (ANALYSIS_IMPLEMENTATION_ID);
alter table RAD3test.ANALYSISIMPLEMENTATIONPARAM add constraint PK_ANALYSISIMPLPARAM primary key (ANALYSIS_IMP_PARAM_ID);
alter table RAD3test.ANALYSISINPUT add constraint PK_ANALYSISINPUT primary key (ANALYSIS_INPUT_ID);
alter table RAD3test.ANALYSISINVOCATION add constraint PK_ANALYSISINVOCATION primary key (ANALYSIS_INVOCATION_ID);
alter table RAD3test.ANALYSISINVOCATIONPARAM add constraint PK_ANAYLSISINVOCATIONPARAM primary key (ANALYSIS_INVOCATION_PARAM_ID);
alter table RAD3test.ANALYSISOUTPUT add constraint PK_ANALYSISOUTPUT primary key (ANALYSIS_OUTPUT_ID);
alter table RAD3test.ARRAY add constraint PK_ARRAY primary key (ARRAY_ID);
alter table RAD3test.ARRAYANNOTATION add constraint PK_ARRAYANNOTATION primary key (ARRAY_ANNOTATION_ID);
alter table RAD3test.ASSAY add constraint PK_ASSAY primary key (ASSAY_ID);
alter table RAD3test.ASSAYBIOMATERIAL add constraint PK_ASSAYBIOMATERIAL primary key (ASSAY_BIO_MATERIAL_ID);
alter table RAD3test.ASSAYLABELEDEXTRACT add constraint PK_ASSAYLABELEDEXTRACT primary key (ASSAY_LABELED_EXTRACT_ID);
alter table RAD3test.ASSAYPARAM add constraint PK_ASSAYPARAM primary key (ASSAY_PARAM_ID);
alter table RAD3test.BIOMATERIALCHARACTERISTIC add constraint PK_BIOAMATCHARACTERISTIC primary key (BIO_MATERIAL_CHARACTERISTIC_ID);
alter table RAD3test.BIOMATERIALIMP add constraint PK_BIOMATERIALIMP primary key (BIO_MATERIAL_ID);
alter table RAD3test.BIOMATERIALMEASUREMENT add constraint PK_BIOMATERIALMEASUREMENT primary key (BIO_MATERIAL_MEASUREMENT_ID);
alter table RAD3test.CHANNEL add constraint PK_CHANNEL primary key (CHANNEL_ID);
alter table RAD3test.COMPOSITEELEMENTANNOTATION add constraint PK_COMPOSITEELEMENTANNOTATION primary key (COMPOSITE_ELEMENT_ANNOT_ID);
alter table RAD3test.COMPOSITEELEMENTGUS add constraint PK_COMPOSITEELEMENTGUS primary key (COMPOSITE_ELEMENT_GUS_ID);
alter table RAD3test.COMPOSITEELEMENTIMP add constraint PK_COMPOSITEELEMENTIMP primary key (COMPOSITE_ELEMENT_ID);
alter table RAD3test.COMPOSITEELEMENTRESULTIMP add constraint PK_SFMRES primary key (COMPOSITE_ELEMENT_RESULT_ID);
alter table RAD3test.CONTROL add constraint PK_CONTROL primary key (CONTROL_ID);
alter table RAD3test.ELEMENTANNOTATION add constraint PK_ELEMENTANNOTATION primary key (ELEMENT_ANNOTATION_ID);
alter table RAD3test.ELEMENTIMP add constraint PK_ELEMENT primary key (ELEMENT_ID);
alter table RAD3test.ELEMENTRESULTIMP add constraint PK_ELEMENTRESULT_N primary key (ELEMENT_RESULT_ID);
alter table RAD3test.LABELMETHOD add constraint PK_LABEL primary key (LABEL_METHOD_ID);
alter table RAD3test.MAGEDOCUMENTATION add constraint PK_MAGEDOCUMENTATION primary key (MAGE_DOCUMENTATION_ID);
alter table RAD3test.MAGE_ML add constraint PK_MAGEML primary key (MAGE_ML_ID);
alter table RAD3test.ONTOLOGYENTRY add constraint PK_ONTOLOGYENTRY primary key (ONTOLOGY_ENTRY_ID);
alter table RAD3test.PROCESSIMPLEMENTATION add constraint PK_PROCESSIMPLEMENTATION primary key (PROCESS_IMPLEMENTATION_ID);
alter table RAD3test.PROCESSIMPLEMENTATIONPARAM add constraint PK_PROCESSIMPPARAM primary key (PROCESS_IMPLEMETATION_PARAM_ID);
alter table RAD3test.PROCESSINVOCATION add constraint PK_PROCESSINV primary key (PROCESS_INVOCATION_ID);
alter table RAD3test.PROCESSINVOCATIONPARAM add constraint PK_PROCESSINVOCATIONPARAM primary key (PROCESS_INVOCATION_PARAM_ID);
alter table RAD3test.PROCESSINVQUANTIFICATION add constraint PK_PROCESSINVQUANT primary key (PROCESS_INV_QUANTIFICATION_ID);
alter table RAD3test.PROCESSIO add constraint PK_PROCESSIO primary key (PROCESS_IO_ID);
alter table RAD3test.PROCESSIOELEMENT add constraint PK_PROCESSIOELEMENT primary key (PROCESS_IO_ELEMENT_ID);
alter table RAD3test.PROCESSRESULT add constraint PK_RESULT5 primary key (PROCESS_RESULT_ID);
alter table RAD3test.PROJECTLINK add constraint PK_PROJECTLINK primary key (PROJECT_LINK_ID);
alter table RAD3test.PROTOCOL add constraint PK_PROTOCOL primary key (PROTOCOL_ID);
alter table RAD3test.PROTOCOLPARAM add constraint PK_PROTOCOLPARAM primary key (PROTOCOL_PARAM_ID);
alter table RAD3test.QUANTIFICATION add constraint PK_QUANTIFICATION primary key (QUANTIFICATION_ID);
alter table RAD3test.QUANTIFICATIONPARAM add constraint PK_QUANTIFICATIONPARAM primary key (QUANTIFICATION_PARAM_ID);
alter table RAD3test.RELATEDACQUISITION add constraint PK_RELASSAY primary key (RELATED_ACQUISITION_ID);
alter table RAD3test.RELATEDQUANTIFICATION add constraint PK_RELATEDQUANTIFICATION primary key (RELATED_QUANTIFICATION_ID);
alter table RAD3test.STUDY add constraint PK_STUDY primary key (STUDY_ID);
alter table RAD3test.STUDYASSAY add constraint PK_STUDYASSAY primary key (STUDY_ASSAY_ID);
alter table RAD3test.STUDYDESIGN add constraint PK_STUDYDESIGN primary key (STUDY_DESIGN_ID);
alter table RAD3test.STUDYDESIGNASSAY add constraint PK_STUDYDESIGNASSAY primary key (STUDY_DESIGN_ASSAY_ID);
alter table RAD3test.STUDYDESIGNDESCRIPTION add constraint PK_STUDYDESIGNDESCR primary key (STUDY_DESIGN_DESCRIPTION_ID);
alter table RAD3test.STUDYDESIGNTYPE add constraint PK_STUDYDESIGNTYPE primary key (STUDY_DESIGN_TYPE_ID);
alter table RAD3test.STUDYFACTOR add constraint PK_STUDYFACTOR primary key (STUDY_FACTOR_ID);
alter table RAD3test.STUDYFACTORVALUE add constraint PK_STUDYFACTORVAL primary key (STUDY_FACTOR_VALUE_ID);
alter table RAD3test.TREATMENT add constraint PK_TREATMENT primary key (TREATMENT_ID);
alter table RAD3test.TREATMENTPARAM add constraint PK_TREATMENTPARAM primary key (TREATMENT_PARAM_ID);


/* 56 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

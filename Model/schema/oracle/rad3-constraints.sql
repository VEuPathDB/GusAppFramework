
/*                                                                                            */
/* rad3-constraints.sql                                                                       */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Feb 17 12:47:09 EST 2004     */
/*                                                                                            */

SET ECHO ON
SPOOL rad3-constraints.log

/* NON-PRIMARY KEY CONSTRAINTS */

/* ACQUISITION */
alter table @oracle_rad@.ACQUISITION add constraint FK_ACQ_ASSAY foreign key (ASSAY_ID) references @oracle_rad@.ASSAY (ASSAY_ID);
alter table @oracle_rad@.ACQUISITION add constraint FK_ACQ_CHANNEL foreign key (CHANNEL_ID) references @oracle_rad@.CHANNEL (CHANNEL_ID);
alter table @oracle_rad@.ACQUISITION add constraint FK_ACQ_PRTCL foreign key (PROTOCOL_ID) references @oracle_rad@.PROTOCOL (PROTOCOL_ID);

/* ACQUISITIONPARAM */
alter table @oracle_rad@.ACQUISITIONPARAM add constraint FK_ACQPARAM_ACQ foreign key (ACQUISITION_ID) references @oracle_rad@.ACQUISITION (ACQUISITION_ID);
alter table @oracle_rad@.ACQUISITIONPARAM add constraint FK_ACQPARAM_PRTPRM foreign key (PROTOCOL_PARAM_ID) references @oracle_rad@.PROTOCOLPARAM (PROTOCOL_PARAM_ID);

/* ANALYSIS */
alter table @oracle_rad@.ANALYSIS add constraint FK_ANALYSIS_CNT foreign key (OPERATOR_ID) references @oracle_sres@.CONTACT (CONTACT_ID);
alter table @oracle_rad@.ANALYSIS add constraint FK_ANALYSIS_PRT foreign key (PROTOCOL_ID) references @oracle_rad@.PROTOCOL (PROTOCOL_ID);

/* ANALYSISINPUT */
alter table @oracle_rad@.ANALYSISINPUT add constraint FK_ANALYSISINPUT_ANL foreign key (ANALYSIS_ID) references @oracle_rad@.ANALYSIS (ANALYSIS_ID);
alter table @oracle_rad@.ANALYSISINPUT add constraint FK_ANALYSISINPUT_LG foreign key (LOGICAL_GROUP_ID) references @oracle_rad@.LOGICALGROUP (LOGICAL_GROUP_ID);

/* ANALYSISPARAM */
alter table @oracle_rad@.ANALYSISPARAM add constraint FK_ANALYSISPARAM_ANL foreign key (ANALYSIS_ID) references @oracle_rad@.ANALYSIS (ANALYSIS_ID);
alter table @oracle_rad@.ANALYSISPARAM add constraint FK_ANALYSISPARAM_PRTPRM foreign key (PROTOCOL_PARAM_ID) references @oracle_rad@.PROTOCOLPARAM (PROTOCOL_PARAM_ID);

/* ANALYSISQCPARAM */
alter table @oracle_rad@.ANALYSISQCPARAM add constraint FK_ANALYSISQCPARAM_ANL foreign key (ANALYSIS_ID) references @oracle_rad@.ANALYSIS (ANALYSIS_ID);
alter table @oracle_rad@.ANALYSISQCPARAM add constraint FK_ANALYSISQCPARAM_PRTPRM foreign key (PROTOCOL_QC_PARAM_ID) references @oracle_rad@.PROTOCOLQCPARAM (PROTOCOL_QC_PARAM_ID);

/* ANALYSISRESULTIMP */
alter table @oracle_rad@.ANALYSISRESULTIMP add constraint FK_ANALYSISRESULT_TINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_rad@.ANALYSISRESULTIMP add constraint FK_ANLRESULT_ANL foreign key (ANALYSIS_ID) references @oracle_rad@.ANALYSIS (ANALYSIS_ID);

/* ARRAY */
alter table @oracle_rad@.ARRAY add constraint FK_ARRAY_CONTACT foreign key (MANUFACTURER_ID) references @oracle_sres@.CONTACT (CONTACT_ID);
alter table @oracle_rad@.ARRAY add constraint FK_ARRAY_EXTDB foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_rad@.ARRAY add constraint FK_ARRAY_ONTO01 foreign key (PLATFORM_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.ARRAY add constraint FK_ARRAY_ONTO02 foreign key (SUBSTRATE_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.ARRAY add constraint FK_ARRAY_PROTOCOL foreign key (PROTOCOL_ID) references @oracle_rad@.PROTOCOL (PROTOCOL_ID);

/* ARRAYANNOTATION */
alter table @oracle_rad@.ARRAYANNOTATION add constraint FK_ARRAYANN_ARRAY foreign key (ARRAY_ID) references @oracle_rad@.ARRAY (ARRAY_ID);

/* ARRAYGROUP */

/* ARRAYGROUPLINK */
alter table @oracle_rad@.ARRAYGROUPLINK add constraint FK_ARRAYGROUPLINKARRAY foreign key (ARRAY_ID) references @oracle_rad@.ARRAY (ARRAY_ID);
alter table @oracle_rad@.ARRAYGROUPLINK add constraint FK_ARRAYGROUPLINKARRAYGRP foreign key (ARRAY_GROUP_ID) references @oracle_rad@.ARRAYGROUP (ARRAY_GROUP_ID);

/* ASSAY */
alter table @oracle_rad@.ASSAY add constraint FK_ASSAY_ARRAY foreign key (ARRAY_ID) references @oracle_rad@.ARRAY (ARRAY_ID);
alter table @oracle_rad@.ASSAY add constraint FK_ASSAY_CONTACT foreign key (OPERATOR_ID) references @oracle_sres@.CONTACT (CONTACT_ID);
alter table @oracle_rad@.ASSAY add constraint FK_ASSAY_PRTCL foreign key (PROTOCOL_ID) references @oracle_rad@.PROTOCOL (PROTOCOL_ID);
alter table @oracle_rad@.ASSAY add constraint FK_EXTERNALDATABASERELEASE foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* ASSAYBIOMATERIAL */
alter table @oracle_rad@.ASSAYBIOMATERIAL add constraint FK_ASSAYBIOMATERIAL15 foreign key (BIO_MATERIAL_ID) references @oracle_rad@.BIOMATERIALIMP (BIO_MATERIAL_ID);
alter table @oracle_rad@.ASSAYBIOMATERIAL add constraint FK_ASSAYBIOSOURCE13 foreign key (ASSAY_ID) references @oracle_rad@.ASSAY (ASSAY_ID);

/* ASSAYCONTROL */
alter table @oracle_rad@.ASSAYCONTROL add constraint FK_ASSAYCONTROL_ASSAY foreign key (ASSAY_ID) references @oracle_rad@.ASSAY (ASSAY_ID);
alter table @oracle_rad@.ASSAYCONTROL add constraint FK_ASSAYCONTROL_CONTROL foreign key (CONTROL_ID) references @oracle_rad@.CONTROL (CONTROL_ID);
alter table @oracle_rad@.ASSAYCONTROL add constraint FK_ASSAYCONTROL_ONTO01 foreign key (UNIT_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);

/* ASSAYLABELEDEXTRACT */
alter table @oracle_rad@.ASSAYLABELEDEXTRACT add constraint FK_ASSAYLAB_ASSAY foreign key (ASSAY_ID) references @oracle_rad@.ASSAY (ASSAY_ID);
alter table @oracle_rad@.ASSAYLABELEDEXTRACT add constraint FK_ASSAYLAB_CHANNEL foreign key (CHANNEL_ID) references @oracle_rad@.CHANNEL (CHANNEL_ID);
alter table @oracle_rad@.ASSAYLABELEDEXTRACT add constraint FK_ASSAYLAB_LEX foreign key (LABELED_EXTRACT_ID) references @oracle_rad@.BIOMATERIALIMP (BIO_MATERIAL_ID);

/* ASSAYPARAM */
alter table @oracle_rad@.ASSAYPARAM add constraint FK_ASSAYPARAM_ASSAY foreign key (ASSAY_ID) references @oracle_rad@.ASSAY (ASSAY_ID);
alter table @oracle_rad@.ASSAYPARAM add constraint FK_ASSAYPARAM_PRTOPRM foreign key (PROTOCOL_PARAM_ID) references @oracle_rad@.PROTOCOLPARAM (PROTOCOL_PARAM_ID);

/* BIOMATERIALCHARACTERISTIC */
alter table @oracle_rad@.BIOMATERIALCHARACTERISTIC add constraint FK_BMCHARAC_BIOMAT foreign key (BIO_MATERIAL_ID) references @oracle_rad@.BIOMATERIALIMP (BIO_MATERIAL_ID);
alter table @oracle_rad@.BIOMATERIALCHARACTERISTIC add constraint FK_BMCHARAC_ONTOLOGY foreign key (ONTOLOGY_ENTRY_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);

/* BIOMATERIALIMP */
alter table @oracle_rad@.BIOMATERIALIMP add constraint FK_BIOMATERIALIMP15 foreign key (LABEL_METHOD_ID) references @oracle_rad@.LABELMETHOD (LABEL_METHOD_ID);
alter table @oracle_rad@.BIOMATERIALIMP add constraint FK_BIOMATIMP_TAXON foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_rad@.BIOMATERIALIMP add constraint FK_BIOMATTYPE_OE foreign key (BIO_MATERIAL_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.BIOMATERIALIMP add constraint FK_BMI_CONTACT foreign key (BIO_SOURCE_PROVIDER_ID) references @oracle_sres@.CONTACT (CONTACT_ID);
alter table @oracle_rad@.BIOMATERIALIMP add constraint FK_BMI_EXTDB foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* BIOMATERIALMEASUREMENT */
alter table @oracle_rad@.BIOMATERIALMEASUREMENT add constraint FK_BMM_BIOMATERIAL foreign key (BIO_MATERIAL_ID) references @oracle_rad@.BIOMATERIALIMP (BIO_MATERIAL_ID);
alter table @oracle_rad@.BIOMATERIALMEASUREMENT add constraint FK_BMM_ONTO foreign key (UNIT_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.BIOMATERIALMEASUREMENT add constraint FK_BMM_TREATMENT foreign key (TREATMENT_ID) references @oracle_rad@.TREATMENT (TREATMENT_ID);

/* CHANNEL */

/* COMPOSITEELEMENTANNOTATION */
alter table @oracle_rad@.COMPOSITEELEMENTANNOTATION add constraint FK_CEANNOT_CE foreign key (COMPOSITE_ELEMENT_ID) references @oracle_rad@.COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID);

/* COMPOSITEELEMENTGUS */
alter table @oracle_rad@.COMPOSITEELEMENTGUS add constraint FK_CEG_CE foreign key (COMPOSITE_ELEMENT_ID) references @oracle_rad@.COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID);
alter table @oracle_rad@.COMPOSITEELEMENTGUS add constraint FK_CEG_TABLEINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* COMPOSITEELEMENTIMP */
alter table @oracle_rad@.COMPOSITEELEMENTIMP add constraint FK_CE_ARRAY foreign key (ARRAY_ID) references @oracle_rad@.ARRAY (ARRAY_ID);
alter table @oracle_rad@.COMPOSITEELEMENTIMP add constraint FK_CE_CE foreign key (PARENT_ID) references @oracle_rad@.COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID);
alter table @oracle_rad@.COMPOSITEELEMENTIMP add constraint FK_CMPELIMP_EXTDB foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* COMPOSITEELEMENTRESULTIMP */
alter table @oracle_rad@.COMPOSITEELEMENTRESULTIMP add constraint FK_CERESULT_CELEMENT foreign key (COMPOSITE_ELEMENT_ID) references @oracle_rad@.COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID);
alter table @oracle_rad@.COMPOSITEELEMENTRESULTIMP add constraint FK_CERESULT_QUANT foreign key (QUANTIFICATION_ID) references @oracle_rad@.QUANTIFICATION (QUANTIFICATION_ID);

/* CONTROL */
alter table @oracle_rad@.CONTROL add constraint FK_CONTRL_TABLEINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_rad@.CONTROL add constraint FK_CONTROL_ONTO01 foreign key (CONTROL_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.CONTROL add constraint FK_CONTROL_ONTO02 foreign key (UNIT_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);

/* ELEMENTANNOTATION */
alter table @oracle_rad@.ELEMENTANNOTATION add constraint FK_ELEANNOT_ELEMENTIMP foreign key (ELEMENT_ID) references @oracle_rad@.ELEMENTIMP (ELEMENT_ID);

/* ELEMENTIMP */
alter table @oracle_rad@.ELEMENTIMP add constraint FK_ELEMENT_ARRAY foreign key (ARRAY_ID) references @oracle_rad@.ARRAY (ARRAY_ID);
alter table @oracle_rad@.ELEMENTIMP add constraint FK_ELEMENT_COMPELEFAM foreign key (COMPOSITE_ELEMENT_ID) references @oracle_rad@.COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID);
alter table @oracle_rad@.ELEMENTIMP add constraint FK_ELEMENT_ONTO foreign key (ELEMENT_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.ELEMENTIMP add constraint FK_ELIMP_EXTDB foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* ELEMENTRESULTIMP */
alter table @oracle_rad@.ELEMENTRESULTIMP add constraint FK_ELEMENTRESULT_ELEMENTIMP foreign key (ELEMENT_ID) references @oracle_rad@.ELEMENTIMP (ELEMENT_ID);
alter table @oracle_rad@.ELEMENTRESULTIMP add constraint FK_ELEMENTRESU_QUANT foreign key (QUANTIFICATION_ID) references @oracle_rad@.QUANTIFICATION (QUANTIFICATION_ID);
alter table @oracle_rad@.ELEMENTRESULTIMP add constraint FK_ELEMENTRES_SFR foreign key (COMPOSITE_ELEMENT_RESULT_ID) references @oracle_rad@.COMPOSITEELEMENTRESULTIMP (COMPOSITE_ELEMENT_RESULT_ID);

/* INTEGRITYSTATINPUT */
alter table @oracle_rad@.INTEGRITYSTATINPUT add constraint INTEGRITYSTATINPUT_FK01 foreign key (INTEGRITY_STATISTIC_ID) references @oracle_rad@.INTEGRITYSTATISTIC (INTEGRITY_STATISTIC_ID);
alter table @oracle_rad@.INTEGRITYSTATINPUT add constraint INTEGRITYSTATINPUT_FK02 foreign key (INPUT_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* INTEGRITYSTATISTIC */

/* LABELMETHOD */
alter table @oracle_rad@.LABELMETHOD add constraint FK_LABELEDMETHOD_PROTO foreign key (PROTOCOL_ID) references @oracle_rad@.PROTOCOL (PROTOCOL_ID);
alter table @oracle_rad@.LABELMETHOD add constraint FK_LABELMETHOD_CHANNEL foreign key (CHANNEL_ID) references @oracle_rad@.CHANNEL (CHANNEL_ID);

/* LOGICALGROUP */

/* LOGICALGROUPLINK */
alter table @oracle_rad@.LOGICALGROUPLINK add constraint FK_LOGICALGROUPLINK_LG foreign key (LOGICAL_GROUP_ID) references @oracle_rad@.LOGICALGROUP (LOGICAL_GROUP_ID);
alter table @oracle_rad@.LOGICALGROUPLINK add constraint FK_LOGICALGROUPLINK_TINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* MAGEDOCUMENTATION */
alter table @oracle_rad@.MAGEDOCUMENTATION add constraint FK_MAGEDOC_TABLEINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_rad@.MAGEDOCUMENTATION add constraint FK_MDOC_MAGEML foreign key (MAGE_ML_ID) references @oracle_rad@.MAGE_ML (MAGE_ML_ID);

/* MAGE_ML */

/* ONTOLOGYENTRY */
alter table @oracle_rad@.ONTOLOGYENTRY add constraint FK_ONTOLOGYENTRY_PARENT foreign key (PARENT_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.ONTOLOGYENTRY add constraint FK_ONTOLOGYENTRY_TABLEINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_rad@.ONTOLOGYENTRY add constraint FK_ONTO_EXTDB foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* PROCESSIMPLEMENTATION */
alter table @oracle_rad@.PROCESSIMPLEMENTATION add constraint FK_PROCESSIMP_ONTO foreign key (PROCESS_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);

/* PROCESSIMPLEMENTATIONPARAM */
alter table @oracle_rad@.PROCESSIMPLEMENTATIONPARAM add constraint FK_PRCSIMPPARAM_PRCSIMP foreign key (PROCESS_IMPLEMENTATION_ID) references @oracle_rad@.PROCESSIMPLEMENTATION (PROCESS_IMPLEMENTATION_ID);

/* PROCESSINVOCATION */
alter table @oracle_rad@.PROCESSINVOCATION add constraint FK_PROCESS_PROCIMP foreign key (PROCESS_IMPLEMENTATION_ID) references @oracle_rad@.PROCESSIMPLEMENTATION (PROCESS_IMPLEMENTATION_ID);

/* PROCESSINVOCATIONPARAM */
alter table @oracle_rad@.PROCESSINVOCATIONPARAM add constraint FK_PROCESSINVPARAM_PROCESSINV foreign key (PROCESS_INVOCATION_ID) references @oracle_rad@.PROCESSINVOCATION (PROCESS_INVOCATION_ID);

/* PROCESSINVQUANTIFICATION */
alter table @oracle_rad@.PROCESSINVQUANTIFICATION add constraint FK_PROCESSINQUANT_P foreign key (PROCESS_INVOCATION_ID) references @oracle_rad@.PROCESSINVOCATION (PROCESS_INVOCATION_ID);
alter table @oracle_rad@.PROCESSINVQUANTIFICATION add constraint FK_PROCESSINQUANT_Q foreign key (QUANTIFICATION_ID) references @oracle_rad@.QUANTIFICATION (QUANTIFICATION_ID);

/* PROCESSIO */
alter table @oracle_rad@.PROCESSIO add constraint FK_PRCSIO_TABLEINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_rad@.PROCESSIO add constraint FK_PROCESSEDRESULT21 foreign key (OUTPUT_RESULT_ID) references @oracle_rad@.PROCESSRESULT (PROCESS_RESULT_ID);
alter table @oracle_rad@.PROCESSIO add constraint FK_PROCESSIO_PROCESSINV foreign key (PROCESS_INVOCATION_ID) references @oracle_rad@.PROCESSINVOCATION (PROCESS_INVOCATION_ID);

/* PROCESSIOELEMENT */
alter table @oracle_rad@.PROCESSIOELEMENT add constraint FK_PROCESSIO foreign key (PROCESS_IO_ID) references @oracle_rad@.PROCESSIO (PROCESS_IO_ID);

/* PROCESSRESULT */
alter table @oracle_rad@.PROCESSRESULT add constraint FK_PROCESSRESULT_ONTO foreign key (UNIT_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);

/* PROJECTLINK */
alter table @oracle_rad@.PROJECTLINK add constraint FK_PROJLINK_PROJINFO foreign key (PROJECT_ID) references @oracle_core@.PROJECTINFO (PROJECT_ID);
alter table @oracle_rad@.PROJECTLINK add constraint FK_PROJLINK_TABLEINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* PROTOCOL */
alter table @oracle_rad@.PROTOCOL add constraint FK_BIBLIOGRAPHIC_REFERENCE_ID foreign key (BIBLIOGRAPHIC_REFERENCE_ID) references @oracle_sres@.BIBLIOGRAPHICREFERENCE (BIBLIOGRAPHIC_REFERENCE_ID);
alter table @oracle_rad@.PROTOCOL add constraint FK_PROTOCOL_HDWTYPE_OE foreign key (HARDWARE_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.PROTOCOL add constraint FK_PROTOCOL_PRTTYPE_OE foreign key (PROTOCOL_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.PROTOCOL add constraint FK_PROTOCOL_SFWTYPE_OE foreign key (SOFTWARE_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);

/* PROTOCOLPARAM */
alter table @oracle_rad@.PROTOCOLPARAM add constraint FK_PROTOCOLPARAM_ONTO1 foreign key (DATA_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.PROTOCOLPARAM add constraint FK_PROTOCOLPARAM_ONTO2 foreign key (UNIT_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.PROTOCOLPARAM add constraint FK_PROTOCOLPARAM_PROTO foreign key (PROTOCOL_ID) references @oracle_rad@.PROTOCOL (PROTOCOL_ID);

/* PROTOCOLQCPARAM */
alter table @oracle_rad@.PROTOCOLQCPARAM add constraint FK_PROTOCOLQCPARAM_ONTO1 foreign key (DATA_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.PROTOCOLQCPARAM add constraint FK_PROTOCOLQCPARAM_ONTO2 foreign key (UNIT_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.PROTOCOLQCPARAM add constraint FK_PROTOCOLQCPARAM_PROTO foreign key (PROTOCOL_ID) references @oracle_rad@.PROTOCOL (PROTOCOL_ID);

/* QUANTIFICATION */
alter table @oracle_rad@.QUANTIFICATION add constraint FK_QUANT_ACQ foreign key (ACQUISITION_ID) references @oracle_rad@.ACQUISITION (ACQUISITION_ID);
alter table @oracle_rad@.QUANTIFICATION add constraint FK_QUANT_CONTACT foreign key (OPERATOR_ID) references @oracle_sres@.CONTACT (CONTACT_ID);
alter table @oracle_rad@.QUANTIFICATION add constraint FK_QUANT_PROTOCOL foreign key (PROTOCOL_ID) references @oracle_rad@.PROTOCOL (PROTOCOL_ID);
alter table @oracle_rad@.QUANTIFICATION add constraint FK_QUANT_TABLEINFO foreign key (RESULT_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* QUANTIFICATIONPARAM */
alter table @oracle_rad@.QUANTIFICATIONPARAM add constraint FK_QUANTPARAM_PRTPRM foreign key (PROTOCOL_PARAM_ID) references @oracle_rad@.PROTOCOLPARAM (PROTOCOL_PARAM_ID);
alter table @oracle_rad@.QUANTIFICATIONPARAM add constraint FK_QUANTPARAM_QUANT foreign key (QUANTIFICATION_ID) references @oracle_rad@.QUANTIFICATION (QUANTIFICATION_ID);

/* RELATEDACQUISITION */
alter table @oracle_rad@.RELATEDACQUISITION add constraint FK_RELACQ_ACQ01 foreign key (ACQUISITION_ID) references @oracle_rad@.ACQUISITION (ACQUISITION_ID);
alter table @oracle_rad@.RELATEDACQUISITION add constraint FK_RELACQ_ACQ02 foreign key (ASSOCIATED_ACQUISITION_ID) references @oracle_rad@.ACQUISITION (ACQUISITION_ID);

/* RELATEDQUANTIFICATION */
alter table @oracle_rad@.RELATEDQUANTIFICATION add constraint FK_RELQUANT_QUANT01 foreign key (QUANTIFICATION_ID) references @oracle_rad@.QUANTIFICATION (QUANTIFICATION_ID);
alter table @oracle_rad@.RELATEDQUANTIFICATION add constraint FK_RELQUANT_QUANT02 foreign key (ASSOCIATED_QUANTIFICATION_ID) references @oracle_rad@.QUANTIFICATION (QUANTIFICATION_ID);

/* STUDY */
alter table @oracle_rad@.STUDY add constraint FK_STUDY_BIBREF foreign key (BIBLIOGRAPHIC_REFERENCE_ID) references @oracle_sres@.BIBLIOGRAPHICREFERENCE (BIBLIOGRAPHIC_REFERENCE_ID);
alter table @oracle_rad@.STUDY add constraint FK_STUDY_CONTACT foreign key (CONTACT_ID) references @oracle_sres@.CONTACT (CONTACT_ID);
alter table @oracle_rad@.STUDY add constraint FK_STUDY_EXTDBRELEASE foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* STUDYASSAY */
alter table @oracle_rad@.STUDYASSAY add constraint FK_STDYASSAY_ASSAY foreign key (ASSAY_ID) references @oracle_rad@.ASSAY (ASSAY_ID);
alter table @oracle_rad@.STUDYASSAY add constraint FK_STDYASSAY_STDY foreign key (STUDY_ID) references @oracle_rad@.STUDY (STUDY_ID);

/* STUDYBIOMATERIAL */
alter table @oracle_rad@.STUDYBIOMATERIAL add constraint FORMHELP_FK01 foreign key (STUDY_ID) references @oracle_rad@.STUDY (STUDY_ID);
alter table @oracle_rad@.STUDYBIOMATERIAL add constraint FORMHELP_FK02 foreign key (BIO_MATERIAL_ID) references @oracle_rad@.BIOMATERIALIMP (BIO_MATERIAL_ID);

/* STUDYDESIGN */
alter table @oracle_rad@.STUDYDESIGN add constraint FK_STDYDES_STDY foreign key (STUDY_ID) references @oracle_rad@.STUDY (STUDY_ID);

/* STUDYDESIGNASSAY */
alter table @oracle_rad@.STUDYDESIGNASSAY add constraint FK_STDYDESASSAY_ASSAY foreign key (ASSAY_ID) references @oracle_rad@.ASSAY (ASSAY_ID);
alter table @oracle_rad@.STUDYDESIGNASSAY add constraint FK_STDYDESASSAY_STDYDES foreign key (STUDY_DESIGN_ID) references @oracle_rad@.STUDYDESIGN (STUDY_DESIGN_ID);

/* STUDYDESIGNDESCRIPTION */
alter table @oracle_rad@.STUDYDESIGNDESCRIPTION add constraint FK_STDYDESDCR_STDYDES foreign key (STUDY_DESIGN_ID) references @oracle_rad@.STUDYDESIGN (STUDY_DESIGN_ID);

/* STUDYDESIGNTYPE */
alter table @oracle_rad@.STUDYDESIGNTYPE add constraint FK_STDYDESTYPE_ONTO foreign key (ONTOLOGY_ENTRY_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.STUDYDESIGNTYPE add constraint FK_STDYDESTYPE_STDYDES foreign key (STUDY_DESIGN_ID) references @oracle_rad@.STUDYDESIGN (STUDY_DESIGN_ID);

/* STUDYFACTOR */
alter table @oracle_rad@.STUDYFACTOR add constraint FK_STDYFCTR_ONTO foreign key (STUDY_FACTOR_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.STUDYFACTOR add constraint FK_STDYFCTR_STDYDES foreign key (STUDY_DESIGN_ID) references @oracle_rad@.STUDYDESIGN (STUDY_DESIGN_ID);

/* STUDYFACTORVALUE */
alter table @oracle_rad@.STUDYFACTORVALUE add constraint FK_STDYFCTRVAL_ASSAY foreign key (ASSAY_ID) references @oracle_rad@.ASSAY (ASSAY_ID);
alter table @oracle_rad@.STUDYFACTORVALUE add constraint FK_STDYFCTRVAL_OEUNIT foreign key (MEASUREMENT_UNIT_OE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.STUDYFACTORVALUE add constraint FK_STDYFCTRVAL_OEVALUE foreign key (VALUE_ONTOLOGY_ENTRY_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad@.STUDYFACTORVALUE add constraint FK_STDYFCTRVAL_STDYFCTR foreign key (STUDY_FACTOR_ID) references @oracle_rad@.STUDYFACTOR (STUDY_FACTOR_ID);

/* TREATMENT */
alter table @oracle_rad@.TREATMENT add constraint FK_TREATMENT6 foreign key (BIO_MATERIAL_ID) references @oracle_rad@.BIOMATERIALIMP (BIO_MATERIAL_ID);
alter table @oracle_rad@.TREATMENT add constraint FK_TREATMENT7 foreign key (TREATMENT_TYPE_ID) references @oracle_rad@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);

/* TREATMENTPARAM */
alter table @oracle_rad@.TREATMENTPARAM add constraint FK_TREATMENTPARAM_PRTOPRM foreign key (PROTOCOL_PARAM_ID) references @oracle_rad@.PROTOCOLPARAM (PROTOCOL_PARAM_ID);
alter table @oracle_rad@.TREATMENTPARAM add constraint FK_TREATMENTPARAM_TREATMENT foreign key (TREATMENT_ID) references @oracle_rad@.TREATMENT (TREATMENT_ID);



/* 133 non-primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

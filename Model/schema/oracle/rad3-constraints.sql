
/*                                                                                            */
/* rad3-constraints.sql                                                                       */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 20:49:26 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL rad3-constraints.log

/* NON-PRIMARY KEY CONSTRAINTS */

/* ACQUISITION */
alter table @oracle_rad3@.ACQUISITION add constraint FK_ACQ_ASSAY foreign key (ASSAY_ID) references @oracle_rad3@.ASSAY (ASSAY_ID);
alter table @oracle_rad3@.ACQUISITION add constraint FK_ACQ_CHANNEL foreign key (CHANNEL_ID) references @oracle_rad3@.CHANNEL (CHANNEL_ID);
alter table @oracle_rad3@.ACQUISITION add constraint FK_ACQ_PRTCL foreign key (PROTOCOL_ID) references @oracle_rad3@.PROTOCOL (PROTOCOL_ID);

/* ACQUISITIONPARAM */
alter table @oracle_rad3@.ACQUISITIONPARAM add constraint FK_ACQPARAM_ACQ foreign key (ACQUISITION_ID) references @oracle_rad3@.ACQUISITION (ACQUISITION_ID);

/* ANALYSIS */

/* ANALYSISIMPLEMENTATION */
alter table @oracle_rad3@.ANALYSISIMPLEMENTATION add constraint FK_ANLIMP_ANL foreign key (ANALYSIS_ID) references @oracle_rad3@.ANALYSIS (ANALYSIS_ID);

/* ANALYSISIMPLEMENTATIONPARAM */
alter table @oracle_rad3@.ANALYSISIMPLEMENTATIONPARAM add constraint FK_ANLIMPPARAM_ANLIMP foreign key (ANALYSIS_IMPLEMENTATION_ID) references @oracle_rad3@.ANALYSISIMPLEMENTATION (ANALYSIS_IMPLEMENTATION_ID);

/* ANALYSISINPUT */
alter table @oracle_rad3@.ANALYSISINPUT add constraint FK_ANLINPUT_ANALYSISINV foreign key (ANALYSIS_INVOCATION_ID) references @oracle_rad3@.ANALYSISINVOCATION (ANALYSIS_INVOCATION_ID);
alter table @oracle_rad3@.ANALYSISINPUT add constraint FK_TABLEINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* ANALYSISINVOCATION */
alter table @oracle_rad3@.ANALYSISINVOCATION add constraint FK_ANLINV_ANLIMP foreign key (ANALYSIS_IMPLEMENTATION_ID) references @oracle_rad3@.ANALYSISIMPLEMENTATION (ANALYSIS_IMPLEMENTATION_ID);

/* ANALYSISINVOCATIONPARAM */
alter table @oracle_rad3@.ANALYSISINVOCATIONPARAM add constraint FK_ANLPARAM_ANLINV foreign key (ANALYSIS_INVOCATION_ID) references @oracle_rad3@.ANALYSISINVOCATION (ANALYSIS_INVOCATION_ID);

/* ANALYSISOUTPUT */
alter table @oracle_rad3@.ANALYSISOUTPUT add constraint FK_ANALYSISOUTPUT4 foreign key (ANALYSIS_INVOCATION_ID) references @oracle_rad3@.ANALYSISINVOCATION (ANALYSIS_INVOCATION_ID);

/* ARRAY */
alter table @oracle_rad3@.ARRAY add constraint FK_ARRAY_CONTACT foreign key (MANUFACTURER_ID) references @oracle_sres@.CONTACT (CONTACT_ID);
alter table @oracle_rad3@.ARRAY add constraint FK_ARRAY_EXTDB foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_rad3@.ARRAY add constraint FK_ARRAY_ONTO01 foreign key (PLATFORM_TYPE_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad3@.ARRAY add constraint FK_ARRAY_ONTO02 foreign key (SUBSTRATE_TYPE_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad3@.ARRAY add constraint FK_ARRAY_PROTOCOL foreign key (PROTOCOL_ID) references @oracle_rad3@.PROTOCOL (PROTOCOL_ID);

/* ARRAYANNOTATION */
alter table @oracle_rad3@.ARRAYANNOTATION add constraint FK_ARRAYANN_ARRAY foreign key (ARRAY_ID) references @oracle_rad3@.ARRAY (ARRAY_ID);

/* ASSAY */
alter table @oracle_rad3@.ASSAY add constraint FK_ASSAY_ARRAY foreign key (ARRAY_ID) references @oracle_rad3@.ARRAY (ARRAY_ID);
alter table @oracle_rad3@.ASSAY add constraint FK_ASSAY_CONTACT foreign key (OPERATOR_ID) references @oracle_sres@.CONTACT (CONTACT_ID);
alter table @oracle_rad3@.ASSAY add constraint FK_ASSAY_PRTCL foreign key (PROTOCOL_ID) references @oracle_rad3@.PROTOCOL (PROTOCOL_ID);
alter table @oracle_rad3@.ASSAY add constraint FK_EXTERNALDATABASERELEASE foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* ASSAYBIOMATERIAL */
alter table @oracle_rad3@.ASSAYBIOMATERIAL add constraint FK_ASSAYBIOMATERIAL15 foreign key (BIO_MATERIAL_ID) references @oracle_rad3@.BIOMATERIALIMP (BIO_MATERIAL_ID);
alter table @oracle_rad3@.ASSAYBIOMATERIAL add constraint FK_ASSAYBIOSOURCE13 foreign key (ASSAY_ID) references @oracle_rad3@.ASSAY (ASSAY_ID);

/* ASSAYLABELEDEXTRACT */
alter table @oracle_rad3@.ASSAYLABELEDEXTRACT add constraint FK_ASSAYLAB_ASSAY foreign key (ASSAY_ID) references @oracle_rad3@.ASSAY (ASSAY_ID);
alter table @oracle_rad3@.ASSAYLABELEDEXTRACT add constraint FK_ASSAYLAB_CHANNEL foreign key (CHANNEL_ID) references @oracle_rad3@.CHANNEL (CHANNEL_ID);
alter table @oracle_rad3@.ASSAYLABELEDEXTRACT add constraint FK_ASSAYLAB_LEX foreign key (LABELED_EXTRACT_ID) references @oracle_rad3@.BIOMATERIALIMP (BIO_MATERIAL_ID);

/* ASSAYPARAM */
alter table @oracle_rad3@.ASSAYPARAM add constraint FK_ASSAYPARAM_ASSAY foreign key (ASSAY_ID) references @oracle_rad3@.ASSAY (ASSAY_ID);
alter table @oracle_rad3@.ASSAYPARAM add constraint FK_ASSAYPARAM_PRTOPRM foreign key (PROTOCOL_PARAM_ID) references @oracle_rad3@.PROTOCOLPARAM (PROTOCOL_PARAM_ID);

/* BIOMATERIALCHARACTERISTIC */
alter table @oracle_rad3@.BIOMATERIALCHARACTERISTIC add constraint FK_BMCHARAC_BIOMAT foreign key (BIO_MATERIAL_ID) references @oracle_rad3@.BIOMATERIALIMP (BIO_MATERIAL_ID);
alter table @oracle_rad3@.BIOMATERIALCHARACTERISTIC add constraint FK_BMCHARAC_ONTOLOGY foreign key (ONTOLOGY_ENTRY_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);

/* BIOMATERIALIMP */
alter table @oracle_rad3@.BIOMATERIALIMP add constraint FK_BIOMATERIALIMP15 foreign key (LABEL_METHOD_ID) references @oracle_rad3@.LABELMETHOD (LABEL_METHOD_ID);
alter table @oracle_rad3@.BIOMATERIALIMP add constraint FK_BIOMATIMP_TAXON foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_rad3@.BIOMATERIALIMP add constraint FK_BIOMATTYPE_OE foreign key (BIO_MATERIAL_TYPE_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad3@.BIOMATERIALIMP add constraint FK_BMI_CONTACT foreign key (BIO_SOURCE_PROVIDER_ID) references @oracle_sres@.CONTACT (CONTACT_ID);
alter table @oracle_rad3@.BIOMATERIALIMP add constraint FK_BMI_EXTDB foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* BIOMATERIALMEASUREMENT */
alter table @oracle_rad3@.BIOMATERIALMEASUREMENT add constraint FK_BMM_BIOMATERIAL foreign key (BIO_MATERIAL_ID) references @oracle_rad3@.BIOMATERIALIMP (BIO_MATERIAL_ID);
alter table @oracle_rad3@.BIOMATERIALMEASUREMENT add constraint FK_BMM_ONTO foreign key (UNIT_TYPE_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad3@.BIOMATERIALMEASUREMENT add constraint FK_BMM_TREATMENT foreign key (TREATMENT_ID) references @oracle_rad3@.TREATMENT (TREATMENT_ID);

/* CHANNEL */

/* COMPOSITEELEMENTANNOTATION */
alter table @oracle_rad3@.COMPOSITEELEMENTANNOTATION add constraint FK_CEANNOT_CE foreign key (COMPOSITE_ELEMENT_ID) references @oracle_rad3@.COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID);

/* COMPOSITEELEMENTGUS */
alter table @oracle_rad3@.COMPOSITEELEMENTGUS add constraint FK_CEG_CE foreign key (COMPOSITE_ELEMENT_ID) references @oracle_rad3@.COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID);
alter table @oracle_rad3@.COMPOSITEELEMENTGUS add constraint FK_CEG_TABLEINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* COMPOSITEELEMENTIMP */
alter table @oracle_rad3@.COMPOSITEELEMENTIMP add constraint FK_CE_ARRAY foreign key (ARRAY_ID) references @oracle_rad3@.ARRAY (ARRAY_ID);
alter table @oracle_rad3@.COMPOSITEELEMENTIMP add constraint FK_CE_CE foreign key (PARENT_ID) references @oracle_rad3@.COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID);
alter table @oracle_rad3@.COMPOSITEELEMENTIMP add constraint FK_CMPELIMP_EXTDB foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* COMPOSITEELEMENTRESULTIMP */
alter table @oracle_rad3@.COMPOSITEELEMENTRESULTIMP add constraint FK_CERESULT_CELEMENT foreign key (COMPOSITE_ELEMENT_ID) references @oracle_rad3@.COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID);
alter table @oracle_rad3@.COMPOSITEELEMENTRESULTIMP add constraint FK_CERESULT_QUANT foreign key (QUANTIFICATION_ID) references @oracle_rad3@.QUANTIFICATION (QUANTIFICATION_ID);

/* CONTROL */
alter table @oracle_rad3@.CONTROL add constraint FK_CONTRL_TABLEINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_rad3@.CONTROL add constraint FK_CONTROL_ASSAY foreign key (ASSAY_ID) references @oracle_rad3@.ASSAY (ASSAY_ID);
alter table @oracle_rad3@.CONTROL add constraint FK_CONTROL_ONTO foreign key (CONTROL_TYPE_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);

/* ELEMENTANNOTATION */
alter table @oracle_rad3@.ELEMENTANNOTATION add constraint FK_ELEANNOT_ELEMENTIMP foreign key (ELEMENT_ID) references @oracle_rad3@.ELEMENTIMP (ELEMENT_ID);

/* ELEMENTIMP */
alter table @oracle_rad3@.ELEMENTIMP add constraint FK_ELEMENT_ARRAY foreign key (ARRAY_ID) references @oracle_rad3@.ARRAY (ARRAY_ID);
alter table @oracle_rad3@.ELEMENTIMP add constraint FK_ELEMENT_COMPELEFAM foreign key (COMPOSITE_ELEMENT_ID) references @oracle_rad3@.COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID);
alter table @oracle_rad3@.ELEMENTIMP add constraint FK_ELEMENT_ONTO foreign key (ELEMENT_TYPE_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad3@.ELEMENTIMP add constraint FK_ELIMP_EXTDB foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* ELEMENTRESULTIMP */
alter table @oracle_rad3@.ELEMENTRESULTIMP add constraint FK_ELEMENTRESULT_ELEMENTIMP foreign key (ELEMENT_ID) references @oracle_rad3@.ELEMENTIMP (ELEMENT_ID);
alter table @oracle_rad3@.ELEMENTRESULTIMP add constraint FK_ELEMENTRESU_QUANT foreign key (QUANTIFICATION_ID) references @oracle_rad3@.QUANTIFICATION (QUANTIFICATION_ID);
alter table @oracle_rad3@.ELEMENTRESULTIMP add constraint FK_ELEMENTRES_SFR foreign key (COMPOSITE_ELEMENT_RESULT_ID) references @oracle_rad3@.COMPOSITEELEMENTRESULTIMP (COMPOSITE_ELEMENT_RESULT_ID);

/* LABELMETHOD */
alter table @oracle_rad3@.LABELMETHOD add constraint FK_LABELEDMETHOD_PROTO foreign key (PROTOCOL_ID) references @oracle_rad3@.PROTOCOL (PROTOCOL_ID);
alter table @oracle_rad3@.LABELMETHOD add constraint FK_LABELMETHOD_CHANNEL foreign key (CHANNEL_ID) references @oracle_rad3@.CHANNEL (CHANNEL_ID);

/* MAGEDOCUMENTATION */
alter table @oracle_rad3@.MAGEDOCUMENTATION add constraint FK_MAGEDOC_TABLEINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_rad3@.MAGEDOCUMENTATION add constraint FK_MDOC_MAGEML foreign key (MAGE_ML_ID) references @oracle_rad3@.MAGE_ML (MAGE_ML_ID);

/* MAGE_ML */

/* ONTOLOGYENTRY */
alter table @oracle_rad3@.ONTOLOGYENTRY add constraint FK_ONTOLOGYENTRY_PARENT foreign key (PARENT_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad3@.ONTOLOGYENTRY add constraint FK_ONTOLOGYENTRY_TABLEINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_rad3@.ONTOLOGYENTRY add constraint FK_ONTO_EXTDB foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* PROCESSIMPLEMENTATION */
alter table @oracle_rad3@.PROCESSIMPLEMENTATION add constraint FK_PROCESSIMP_ONTO foreign key (PROCESS_TYPE_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);

/* PROCESSIMPLEMENTATIONPARAM */
alter table @oracle_rad3@.PROCESSIMPLEMENTATIONPARAM add constraint FK_PRCSIMPPARAM_PRCSIMP foreign key (PROCESS_IMPLEMENTATION_ID) references @oracle_rad3@.PROCESSIMPLEMENTATION (PROCESS_IMPLEMENTATION_ID);

/* PROCESSINVOCATION */
alter table @oracle_rad3@.PROCESSINVOCATION add constraint FK_PROCESS_PROCIMP foreign key (PROCESS_IMPLEMENTATION_ID) references @oracle_rad3@.PROCESSIMPLEMENTATION (PROCESS_IMPLEMENTATION_ID);

/* PROCESSINVOCATIONPARAM */
alter table @oracle_rad3@.PROCESSINVOCATIONPARAM add constraint FK_PROCESSINVPARAM_PROCESSINV foreign key (PROCESS_INVOCATION_ID) references @oracle_rad3@.PROCESSINVOCATION (PROCESS_INVOCATION_ID);

/* PROCESSINVQUANTIFICATION */
alter table @oracle_rad3@.PROCESSINVQUANTIFICATION add constraint FK_PROCESSINQUANT_P foreign key (PROCESS_INVOCATION_ID) references @oracle_rad3@.PROCESSINVOCATION (PROCESS_INVOCATION_ID);
alter table @oracle_rad3@.PROCESSINVQUANTIFICATION add constraint FK_PROCESSINQUANT_Q foreign key (QUANTIFICATION_ID) references @oracle_rad3@.QUANTIFICATION (QUANTIFICATION_ID);

/* PROCESSIO */
alter table @oracle_rad3@.PROCESSIO add constraint FK_PRCSIO_TABLEINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_rad3@.PROCESSIO add constraint FK_PROCESSEDRESULT21 foreign key (OUTPUT_RESULT_ID) references @oracle_rad3@.PROCESSRESULT (PROCESS_RESULT_ID);
alter table @oracle_rad3@.PROCESSIO add constraint FK_PROCESSIO_PROCESSINV foreign key (PROCESS_INVOCATION_ID) references @oracle_rad3@.PROCESSINVOCATION (PROCESS_INVOCATION_ID);

/* PROCESSIOELEMENT */
alter table @oracle_rad3@.PROCESSIOELEMENT add constraint FK_PROCESSIO foreign key (PROCESS_IO_ID) references @oracle_rad3@.PROCESSIO (PROCESS_IO_ID);

/* PROCESSRESULT */
alter table @oracle_rad3@.PROCESSRESULT add constraint FK_PROCESSRESULT_ONTO foreign key (UNIT_TYPE_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);

/* PROJECTLINK */
alter table @oracle_rad3@.PROJECTLINK add constraint FK_PROJLINK_PROJINFO foreign key (PROJECT_ID) references @oracle_core@.PROJECTINFO (PROJECT_ID);
alter table @oracle_rad3@.PROJECTLINK add constraint FK_PROJLINK_TABLEINFO foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* PROTOCOL */
alter table @oracle_rad3@.PROTOCOL add constraint FK_PROTOCOL_BIBREF foreign key (BIBLIOGRAPHIC_REFERENCE_ID) references @oracle_sres@.BIBLIOGRAPHICREFERENCE (BIBLIOGRAPHIC_REFERENCE_ID);
alter table @oracle_rad3@.PROTOCOL add constraint FK_PROTOCOL_EXTDBREL foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_rad3@.PROTOCOL add constraint FK_PROTOCOL_ONTO foreign key (PROTOCOL_TYPE_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);

/* PROTOCOLPARAM */
alter table @oracle_rad3@.PROTOCOLPARAM add constraint FK_PROTOCOLPARAM_ONTO1 foreign key (DATA_TYPE_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad3@.PROTOCOLPARAM add constraint FK_PROTOCOLPARAM_ONTO2 foreign key (UNIT_TYPE_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad3@.PROTOCOLPARAM add constraint FK_PROTOCOLPARAM_PROTO foreign key (PROTOCOL_ID) references @oracle_rad3@.PROTOCOL (PROTOCOL_ID);

/* QUANTIFICATION */
alter table @oracle_rad3@.QUANTIFICATION add constraint FK_QUANT_ACQ foreign key (ACQUISITION_ID) references @oracle_rad3@.ACQUISITION (ACQUISITION_ID);
alter table @oracle_rad3@.QUANTIFICATION add constraint FK_QUANT_CONTACT foreign key (OPERATOR_ID) references @oracle_sres@.CONTACT (CONTACT_ID);
alter table @oracle_rad3@.QUANTIFICATION add constraint FK_QUANT_PROTOCOL foreign key (PROTOCOL_ID) references @oracle_rad3@.PROTOCOL (PROTOCOL_ID);
alter table @oracle_rad3@.QUANTIFICATION add constraint FK_QUANT_TABLEINFO foreign key (RESULT_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* QUANTIFICATIONPARAM */
alter table @oracle_rad3@.QUANTIFICATIONPARAM add constraint FK_QUANTPARAM_QUANT foreign key (QUANTIFICATION_ID) references @oracle_rad3@.QUANTIFICATION (QUANTIFICATION_ID);

/* RELATEDACQUISITION */
alter table @oracle_rad3@.RELATEDACQUISITION add constraint FK_RELACQ_ACQ01 foreign key (ACQUISITION_ID) references @oracle_rad3@.ACQUISITION (ACQUISITION_ID);
alter table @oracle_rad3@.RELATEDACQUISITION add constraint FK_RELACQ_ACQ02 foreign key (ASSOCIATED_ACQUISITION_ID) references @oracle_rad3@.ACQUISITION (ACQUISITION_ID);

/* RELATEDQUANTIFICATION */
alter table @oracle_rad3@.RELATEDQUANTIFICATION add constraint FK_RELQUANT_QUANT01 foreign key (QUANTIFICATION_ID) references @oracle_rad3@.QUANTIFICATION (QUANTIFICATION_ID);
alter table @oracle_rad3@.RELATEDQUANTIFICATION add constraint FK_RELQUANT_QUANT02 foreign key (ASSOCIATED_QUANTIFICATION_ID) references @oracle_rad3@.QUANTIFICATION (QUANTIFICATION_ID);

/* STUDY */
alter table @oracle_rad3@.STUDY add constraint FK_STUDY_BIBREF foreign key (BIBLIOGRAPHIC_REFERENCE_ID) references @oracle_sres@.BIBLIOGRAPHICREFERENCE (BIBLIOGRAPHIC_REFERENCE_ID);
alter table @oracle_rad3@.STUDY add constraint FK_STUDY_CONTACT foreign key (CONTACT_ID) references @oracle_sres@.CONTACT (CONTACT_ID);
alter table @oracle_rad3@.STUDY add constraint FK_STUDY_EXTDBRELEASE foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* STUDYASSAY */
alter table @oracle_rad3@.STUDYASSAY add constraint FK_STDYASSAY_ASSAY foreign key (ASSAY_ID) references @oracle_rad3@.ASSAY (ASSAY_ID);
alter table @oracle_rad3@.STUDYASSAY add constraint FK_STDYASSAY_STDY foreign key (STUDY_ID) references @oracle_rad3@.STUDY (STUDY_ID);

/* STUDYDESIGN */
alter table @oracle_rad3@.STUDYDESIGN add constraint FK_STDYDES_STDY foreign key (STUDY_ID) references @oracle_rad3@.STUDY (STUDY_ID);

/* STUDYDESIGNASSAY */
alter table @oracle_rad3@.STUDYDESIGNASSAY add constraint FK_STDYDESASSAY_ASSAY foreign key (ASSAY_ID) references @oracle_rad3@.ASSAY (ASSAY_ID);
alter table @oracle_rad3@.STUDYDESIGNASSAY add constraint FK_STDYDESASSAY_STDYDES foreign key (STUDY_DESIGN_ID) references @oracle_rad3@.STUDYDESIGN (STUDY_DESIGN_ID);

/* STUDYDESIGNDESCRIPTION */
alter table @oracle_rad3@.STUDYDESIGNDESCRIPTION add constraint FK_STDYDESDCR_STDYDES foreign key (STUDY_DESIGN_ID) references @oracle_rad3@.STUDYDESIGN (STUDY_DESIGN_ID);

/* STUDYDESIGNTYPE */
alter table @oracle_rad3@.STUDYDESIGNTYPE add constraint FK_STDYDESTYPE_ONTO foreign key (ONTOLOGY_ENTRY_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad3@.STUDYDESIGNTYPE add constraint FK_STDYDESTYPE_STDYDES foreign key (STUDY_DESIGN_ID) references @oracle_rad3@.STUDYDESIGN (STUDY_DESIGN_ID);

/* STUDYFACTOR */
alter table @oracle_rad3@.STUDYFACTOR add constraint FK_STDYFCTR_ONTO foreign key (STUDY_FACTOR_TYPE_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad3@.STUDYFACTOR add constraint FK_STDYFCTR_STDYDES foreign key (STUDY_DESIGN_ID) references @oracle_rad3@.STUDYDESIGN (STUDY_DESIGN_ID);

/* STUDYFACTORVALUE */
alter table @oracle_rad3@.STUDYFACTORVALUE add constraint FK_STDYFCTRVAL_ASSAY foreign key (ASSAY_ID) references @oracle_rad3@.ASSAY (ASSAY_ID);
alter table @oracle_rad3@.STUDYFACTORVALUE add constraint FK_STDYFCTRVAL_STDYFCTR foreign key (STUDY_FACTOR_ID) references @oracle_rad3@.STUDYFACTOR (STUDY_FACTOR_ID);

/* TREATMENT */
alter table @oracle_rad3@.TREATMENT add constraint FK_TREATMENT6 foreign key (BIO_MATERIAL_ID) references @oracle_rad3@.BIOMATERIALIMP (BIO_MATERIAL_ID);
alter table @oracle_rad3@.TREATMENT add constraint FK_TREATMENT7 foreign key (TREATMENT_TYPE_ID) references @oracle_rad3@.ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID);
alter table @oracle_rad3@.TREATMENT add constraint FK_TREATMEN_PROTOCOL foreign key (PROTOCOL_ID) references @oracle_rad3@.PROTOCOL (PROTOCOL_ID);

/* TREATMENTPARAM */
alter table @oracle_rad3@.TREATMENTPARAM add constraint FK_TREATMENTPARAM_PRTOPRM foreign key (PROTOCOL_PARAM_ID) references @oracle_rad3@.PROTOCOLPARAM (PROTOCOL_PARAM_ID);
alter table @oracle_rad3@.TREATMENTPARAM add constraint FK_TREATMENTPARAM_TREATMENT foreign key (TREATMENT_ID) references @oracle_rad3@.TREATMENT (TREATMENT_ID);



/* 112 non-primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

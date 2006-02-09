/*==============================================================*/
/* Database name:  ProtDB                                       */
/* DBMS name:      ORACLE Version 9i                            */
/* Release version:     09/2003                                 */
/* Created by:     Andrew Jones                                 */
/*==============================================================*/


alter table ACQUISITION
   drop constraint FK_ACQ_ASSAY
/


alter table ACQUISITION
   drop constraint FK_ACQ_CHANNEL
/


alter table ACQUISITION
   drop constraint FK_ACQ_PRTCL
/


alter table ACQUISITIONPARAM
   drop constraint FK_ACQPARAM_ACQ
/


alter table ACQUISITIONPARAM
   drop constraint FK_ACQPARAM_PRTPRM
/


alter table ANALYSISIMPLEMENTATION
   drop constraint FK_ANLIMP_ANL
/


alter table ANALYSISIMPLEMENTATIONPARAM
   drop constraint FK_ANLIMPPARAM_ANLIMP
/


alter table ANALYSISINPUT
   drop constraint FK_ANLINPUT_ANALYSISINV
/


alter table ANALYSISINVOCATION
   drop constraint FK_ANLINV_ANLIMP
/


alter table ANALYSISINVOCATIONPARAM
   drop constraint FK_ANLPARAM_ANLINV
/


alter table ANALYSISOUTPUT
   drop constraint FK_ANALYSISOUTPUT4
/


alter table ANALYTEMEASUREMENT
   drop constraint FK_ANALYTE__REFERENCE_BIOASSAY
/


alter table ANALYTEMEASUREMENT
   drop constraint FK_ANALYTE__REFERENCE_BIOMATER
/


alter table ARRAY
   drop constraint FK_ARRAY_ONTO01
/


alter table ARRAY
   drop constraint FK_ARRAY_ONTO02
/


alter table ARRAY
   drop constraint FK_ARRAY_PROTOCOL
/


alter table ARRAYANNOTATION
   drop constraint FK_ARRAYANN_ARRAY
/


alter table ASSAY
   drop constraint FK_ASSAY_ARRAY
/


alter table ASSAY
   drop constraint FK_ASSAY_PRTCL
/


alter table ASSAYBIOMATERIAL
   drop constraint FK_ASSAYBIOMATERIAL15
/


alter table ASSAYBIOMATERIAL
   drop constraint FK_ASSAYBIOSOURCE13
/


alter table ASSAYDATAPOINT
   drop constraint FK_ASSAYDAT_REFERENCE_LCCOLUMN
/


alter table ASSAYGROUP
   drop constraint FK_ASSAYGRO_REFERENCE_ASSAY
/


alter table ASSAYGROUP
   drop constraint FK_ASSAYGRO_REFERENCE_STUDY
/


alter table ASSAYGROUP
   drop constraint FK_ASSAYGRO_REFERENCE_STUDYDES
/


alter table ASSAYGROUP
   drop constraint FK_ASSAYGRO_REFERENCE_STUDYFAC
/


alter table ASSAYLABELEDEXTRACT
   drop constraint FK_ASSAYLAB_ASSAY
/


alter table ASSAYLABELEDEXTRACT
   drop constraint FK_ASSAYLAB_CHANNEL
/


alter table ASSAYLABELEDEXTRACT
   drop constraint FK_ASSAYLAB_LEX
/


alter table ASSAYPARAM
   drop constraint FK_ASSAYPARAM_ASSAY
/


alter table ASSAYPARAM
   drop constraint FK_ASSAYPARAM_PRTOPRM
/


alter table ASSAYPARAMPROT
   drop constraint FK_ASSAYPAR_REFERENCE_PROTEOME
/


alter table ASSAYPARAMPROT
   drop constraint FK_ASSAYPAR_REFERENCE_PROTOCOL
/


alter table BAND
   drop constraint FK_BAND_REFERENCE_PHYSICAL
/


alter table BIOASSAYTREATMENT
   drop constraint FK_BIOASSAY_REFERENCE_ONTOLOGY
/


alter table BIOASSAYTREATMENT
   drop constraint FK_BIOASSAY_REFERENCE_PROTEOME
/


alter table BIOASSAYTREATMENT
   drop constraint FK_BIOASSAY_REFERENCE_PROTOCOL
/


alter table BIOMATERIALCHARACTERISTIC
   drop constraint FK_BMCHARAC_BIOMAT
/


alter table BIOMATERIALCHARACTERISTIC
   drop constraint FK_BMCHARAC_ONTOLOGY
/


alter table BIOMATERIALIMP
   drop constraint FK_BIOMATERIALIMP15
/


alter table BIOMATERIALIMP
   drop constraint FK_BIOMATTYPE_OE
/


alter table BIOMATERIALMEASUREMENT
   drop constraint FK_BMM_BIOMATERIAL
/


alter table BIOMATERIALMEASUREMENT
   drop constraint FK_BMM_ONTO
/


alter table BIOMATERIALMEASUREMENT
   drop constraint FK_BMM_TREATMENT
/


alter table BOUNDARYPOINT
   drop constraint FK_BOUNDARY_REFERENCE_IDENTIFI
/


alter table CHEMICALTREATMENT
   drop constraint FK_CHEMICAL_REFERENCE_BIOASSAY
/


alter table CHEMICALTREATMENT
   drop constraint FK_CHEMICAL_REFERENCE_ONTOLOGY
/


alter table COLLISIONCELL
   drop constraint FK_COLLISIO_REFERENCE_MZANALYS
/


alter table COMPOSITEELEMENTANNOTATION
   drop constraint FK_CEANNOT_CE
/


alter table COMPOSITEELEMENTGUS
   drop constraint FK_CEG_CE
/


alter table COMPOSITEELEMENTIMP
   drop constraint FK_CE_ARRAY
/


alter table COMPOSITEELEMENTIMP
   drop constraint FK_CE_CE
/


alter table COMPOSITEELEMENTRESULTIMP
   drop constraint FK_CERESULT_CELEMENT
/


alter table COMPOSITEELEMENTRESULTIMP
   drop constraint FK_CERESULT_QUANT
/


alter table CONTROL
   drop constraint FK_CONTROL_ASSAY
/


alter table CONTROL
   drop constraint FK_CONTROL_ONTO
/


alter table DATABASEENTRY
   drop constraint FK_DATABASE_NAME_FK_DATABA_ONT
/


alter table DATABASEENTRY
   drop constraint FK_DATABASE_URI_FK_DATABA_ONTO
/


alter table DATABASEENTRY
   drop constraint FK_DATABASE_VERS_FK_DATABA_ONT
/


alter table DBSEARCH
   drop constraint FK_DBSEARCH_REFERENCE_DBSEARCH
/


alter table DBSEARCH
   drop constraint FK_DBSEARCH_REFERENCE_PEAKLIST
/


alter table DBSEARCHPARAMETERS
   drop constraint FK_DBSEARCH_REFERENCE_PROTOCOL
/


alter table DIGESINGLESPOT
   drop constraint FK_DIGESING_REFERENCE_IDENTIFI
/


alter table DIGESINGLESPOT
   drop constraint FK_DIGESING_REFERENCE_IMAGE_AN
/


alter table DIGESINGLESPOT
   drop constraint FK_DIGESING_REFERENCE_SPOT_MEA
/


alter table ELECTROSPRAY
   drop constraint FK_ELECTROS_REFERENCE_IONSOURC
/


alter table ELEMENTANNOTATION
   drop constraint FK_ELEANNOT_ELEMENTIMP
/


alter table ELEMENTIMP
   drop constraint FK_ELEMENT_ARRAY
/


alter table ELEMENTIMP
   drop constraint FK_ELEMENT_COMPELEFAM
/


alter table ELEMENTIMP
   drop constraint FK_ELEMENT_ONTO
/


alter table ELEMENTRESULTIMP
   drop constraint FK_ELEMENTRESULT_ELEMENTIMP
/


alter table ELEMENTRESULTIMP
   drop constraint FK_ELEMENTRESU_QUANT
/


alter table ELEMENTRESULTIMP
   drop constraint FK_ELEMENTRES_SFR
/


alter table FRACTION
   drop constraint FK_FRACTION_REFERENCE_BIOMATER
/


alter table FRACTION
   drop constraint FK_FRACTION_REFERENCE_LCCOLUMN
/


alter table GEL1D
   drop constraint FK_GEL1D_REFERENCE_BIOASSAY
/


alter table GEL2D
   drop constraint FK_GEL2D_REFERENCE_BIOASSAY
/


alter table GRADIENTSTEP
   drop constraint FK_GRADIENT_REFERENCE_LCCOLUMN
/


alter table HEXAPOLE
   drop constraint FK_HEXAPOLE_REFERENCE_MZANALYS
/


alter table IDENTIFIEDSPOT
   drop constraint FK_IDENTIFI_REFERENCE_IMAGE_AN
/


alter table IDENTIFIEDSPOT
   drop constraint FK_IDENTIFI_REFERENCE_PHYSICAL
/


alter table IDENTIFIEDSPOT
   drop constraint FK_IDENTIFI_REFERENCE_SPOT_MEA
/


alter table IMAGEACQUISITION
   drop constraint FK_IMAGE_AC_REFERENCE_CHANNEL
/


alter table IMAGEACQUISITION
   drop constraint FK_IMAGE_AC_REFERENCE_PROTEOME
/


alter table GELIMAGEANALYSIS
   drop constraint FK_IMAGE_AN_REFERENCE_IMAGE_AC
/


alter table GELIMAGEANALYSIS
   drop constraint FK_IMAGE_AN_REFERENCE_PROTOCOL
/


alter table INTEGRITYSTATINPUT
   drop constraint INTEGRITYSTATINPUT_FK01
/


alter table IONTRAP
   drop constraint FK_IONTRAP_REFERENCE_MZANALYS
/


alter table LABELMETHOD
   drop constraint FK_LABELEDMETHOD_PROTO
/


alter table LABELMETHOD
   drop constraint FK_LABELMETHOD_CHANNEL
/


alter table LCCOLUMN
   drop constraint FK_LCCOLUMN_REFERENCE_BIOASSAY
/


alter table LISTPROCESSING
   drop constraint FK_LISTPROC_REFERENCE_PEAKLIST
/


alter table MAGEDOCUMENTATION
   drop constraint FK_MDOC_MAGEML
/


alter table MALDI
   drop constraint FK_MALDI_REFERENCE_IONSOURC
/


alter table MASSSPECEXPERIMENT
   drop constraint FK_MASSSPEC_REFERENCE_BIOASSAY
/


alter table MASSSPECEXPERIMENT
   drop constraint FK_MASSSPEC_REFERENCE_MASSSPEC
/


alter table MASSSPECMACHINE
   drop constraint FK_MASSSPEC_REFERENCE_IONSOURC
/


alter table MATCHEDSPOTS
   drop constraint FK_MATCHED__REFERENCE_IDENTIFI
/


alter table MATCHEDSPOTS
   drop constraint FK_MATCHED__REFERENCE_MULTIPLE
/


alter table MOBILEPHASECOMPONENT
   drop constraint FK_MOBILEPH_REFERENCE_LCCOLUMN
/


alter table MSMSFRACTION
   drop constraint FK_MSMSFRAC_REFERENCE_PEAKLIST
/


alter table MULTIPLEANALYSIS
   drop constraint FK_MULTIPLE_REFERENCE_IMAGE_AN
/


alter table MULTIPLEANALYSIS
   drop constraint FK_MULTIPLE_REFERENCE_ONTOLOGY
/


alter table MULTIPLEANALYSIS
   drop constraint FK_MULTIPLE_REFERENCE_PROTOCOL
/


alter table MZANALYSIS
   drop constraint FK_MZANALYS_REFERENCE_DETECTIO
/


alter table ONTOLOGYENTRY
   drop constraint FK_ONTOLOGYENTRY_PARENT
/


alter table OTHERIONISATION
   drop constraint FK_OTHERION_REFERENCE_IONSOURC
/


alter table OTHERIONISATION
   drop constraint FK_OTHERION_REFERENCE_ONTOLOGY
/


alter table OTHERMZANALYSIS
   drop constraint FK_OTHERMZA_REFERENCE_MZANALYS
/


alter table OTHERMZANALYSIS
   drop constraint FK_OTHERMZA_REFERENCE_ONTOLOGY
/


alter table PEAK
   drop constraint FK_PEAK_REFERENCE_PEAKLIST
/


alter table PEAKLIST
   drop constraint FK_PEAKLIST_REFERENCE_MASSSPEC
/


alter table PEPTIDEHIT
   drop constraint FK_PEPTIDEH_REFERENCE_DATABASE
/


alter table PEPTIDEHIT
   drop constraint FK_PEPTIDEH_REFERENCE_DBSEARCH
/


alter table PERCENTX
   drop constraint FK_PERCENTX_REFERENCE_GRADIENT
/


alter table PERCENTX
   drop constraint FK_PERCENTX_REFERENCE_MOBILEPH
/


alter table PHYSICALGELITEM
   drop constraint FK_PHYSICAL_REFERENCE_BIOMATER
/


alter table PHYSICALGELITEM
   drop constraint FK_PHYSICAL_REFERENCE_GEL1D
/


alter table PHYSICALGELITEM
   drop constraint FK_PHYSICAL_REFERENCE_GEL2D
/


alter table PHYSICALGELITEM
   drop constraint FK_PHYSICAL_REFERENCE_PROTEINR
/


alter table PROCESSIMPLEMENTATION
   drop constraint FK_PROCESSIMP_ONTO
/


alter table PROCESSIMPLEMENTATIONPARAM
   drop constraint FK_PRCSIMPPARAM_PRCSIMP
/


alter table PROCESSINVOCATION
   drop constraint FK_PROCESS_PROCIMP
/


alter table PROCESSINVOCATIONPARAM
   drop constraint FK_PROCESSINVPARAM_PROCESSINV
/


alter table PROCESSINVQUANTIFICATION
   drop constraint FK_PROCESSINQUANT_P
/


alter table PROCESSINVQUANTIFICATION
   drop constraint FK_PROCESSINQUANT_Q
/


alter table PROCESSIO
   drop constraint FK_PROCESSEDRESULT21
/


alter table PROCESSIO
   drop constraint FK_PROCESSIO_PROCESSINV
/


alter table PROCESSIOELEMENT
   drop constraint FK_PROCESSIO
/


alter table PROCESSRESULT
   drop constraint FK_PROCESSRESULT_ONTO
/


alter table PROTEINHIT
   drop constraint FK_PROTEINH_REFERENCE_PEPTIDEH
/


alter table PROTEINHIT
   drop constraint FK_PROTEINH_REFERENCE_PROTEINR
/


alter table PROTEINMODIFICATION
   drop constraint FK_PROTEINM_REFERENCE_ONTOLOGY
/


alter table PROTEINMODIFICATION
   drop constraint FK_PROTEINM_REFERENCE_PROTEINR
/


alter table PROTEINRECORD
   drop constraint FK_PROTEINR_REFERENCE_DATABASE
/


alter table PROTEOMEASSAY
   drop constraint FK_PROTEOME_REFERENCE_PROTOCOL
/


alter table PROTOCOL
   drop constraint FK_PROTOCOL_HDWTYPE_OE
/


alter table PROTOCOL
   drop constraint FK_PROTOCOL_PRTTYPE_OE
/


alter table PROTOCOL
   drop constraint FK_PROTOCOL_SFWTYPE_OE
/


alter table PROTOCOLPARAM
   drop constraint FK_PROTOCOLPARAM_ONTO1
/


alter table PROTOCOLPARAM
   drop constraint FK_PROTOCOLPARAM_ONTO2
/


alter table PROTOCOLPARAM
   drop constraint FK_PROTOCOLPARAM_PROTO
/


alter table QUADRUPOLE
   drop constraint FK_QUADRUPO_REFERENCE_MZANALYS
/


alter table QUANTIFICATION
   drop constraint FK_QUANT_ACQ
/


alter table QUANTIFICATION
   drop constraint FK_QUANT_PROTOCOL
/


alter table QUANTIFICATIONPARAM
   drop constraint FK_QUANTPARAM_PRTPRM
/


alter table QUANTIFICATIONPARAM
   drop constraint FK_QUANTPARAM_QUANT
/


alter table RELATEDACQUISITION
   drop constraint FK_RELACQ_ACQ01
/


alter table RELATEDACQUISITION
   drop constraint FK_RELACQ_ACQ02
/


alter table RELATEDQUANTIFICATION
   drop constraint FK_RELQUANT_QUANT01
/


alter table RELATEDQUANTIFICATION
   drop constraint FK_RELQUANT_QUANT02
/


alter table SPOTRATIO
   drop constraint FK_SPOTRATI_2_FK_DIGE_S_DIGES2
/


alter table SPOTRATIO
   drop constraint FK_SPOTRATI_FK_DIGE_S_DIGESING
/


alter table STUDYASSAY
   drop constraint FK_STDYASSAY_ASSAY
/


alter table STUDYASSAY
   drop constraint FK_STDYASSAY_STDY
/


alter table STUDYASSAYPROT
   drop constraint FK_STUDYASS_REFERENCE_PROTEOME
/


alter table STUDYASSAYPROT
   drop constraint FK_STUDYASS_REFERENCE_STUDY
/


alter table STUDYBIOMATERIAL
   drop constraint FORMHELP_FK01
/


alter table STUDYBIOMATERIAL
   drop constraint FORMHELP_FK02
/


alter table STUDYDESIGN
   drop constraint FK_STDYDES_STDY
/


alter table STUDYDESIGNASSAY
   drop constraint FK_STDYDESASSAY_ASSAY
/


alter table STUDYDESIGNASSAY
   drop constraint FK_STDYDESASSAY_STDYDES
/


alter table STUDYDESIGNASSAYPROT
   drop constraint FK_STUDYDES_REFERENCE_STUDYDES
/


alter table STUDYDESIGNASSAYPROT
   drop constraint FK_STUDYDES_REFERENCE_PROTEOME
/


alter table STUDYDESIGNDESCRIPTION
   drop constraint FK_STDYDESDCR_STDYDES
/


alter table STUDYDESIGNTYPE
   drop constraint FK_STDYDESTYPE_ONTO
/


alter table STUDYDESIGNTYPE
   drop constraint FK_STDYDESTYPE_STDYDES
/


alter table STUDYFACTOR
   drop constraint FK_STDYFCTR_ONTO
/


alter table STUDYFACTOR
   drop constraint FK_STDYFCTR_STDYDES
/


alter table STUDYFACTORVALUE
   drop constraint FK_STDYFCTRVAL_ASSAY
/


alter table STUDYFACTORVALUE
   drop constraint FK_STDYFCTRVAL_OEUNIT
/


alter table STUDYFACTORVALUE
   drop constraint FK_STDYFCTRVAL_OEVALUE
/


alter table STUDYFACTORVALUE
   drop constraint FK_STDYFCTRVAL_STDYFCTR
/


alter table STUDYFACTORVALUEPROT
   drop constraint FK_STUDYFAC_FK_SFV_ME_ONTOLOGY
/


alter table STUDYFACTORVALUEPROT
   drop constraint FK_STUDYFAC_FK_STF_VA_ONTOLOGY
/


alter table STUDYFACTORVALUEPROT
   drop constraint FK_STUDYFAC_REFERENCE_PROTEOME
/


alter table STUDYFACTORVALUEPROT
   drop constraint FK_STUDYFAC_REFERENCE_STUDYFAC
/


alter table TANDEMSEQUENCEDATA
   drop constraint FK_TANDEMSE_REFERENCE_DBSEARCH
/


alter table TOF
   drop constraint FK_TOF_REFERENCE_MZANALYS
/


alter table TREATEDANALYTE
   drop constraint FK_TREATEDA_REFERENCE_BIOMATER
/


alter table TREATEDANALYTE
   drop constraint FK_TREATEDA_REFERENCE_CHEMICAL
/


alter table TREATMENT
   drop constraint FK_TREATMENT6
/


alter table TREATMENT
   drop constraint FK_TREATMENT7
/


alter table TREATMENTPARAM
   drop constraint FK_TREATMENTPARAM_PRTOPRM
/


alter table TREATMENTPARAM
   drop constraint FK_TREATMENTPARAM_TREATMENT
/


drop view SPOTFAMILY
/


drop view SPOTELEMENTRESULT
/


drop view SPOT
/


drop view SHORTOLIGOFAMILY
/


drop view SHORTOLIGO
/


drop view SCANALYZEELEMENTRESULT
/


drop view SAGETAGRESULT
/


drop view SAGETAGMAPPING
/


drop view SAGETAG
/


drop view OTHER_SPOT_MEASURES
/


drop view MOIDRESULT
/


drop view LABELEDEXTRACT
/


drop view GENEPIXELEMENTRESULT
/


drop view GEMTOOLSELEMENTRESULT
/


drop view ELEMENTRESULT
/


drop view ELEMENT
/


drop view COMPOSITEELEMENTRESULT
/


drop view COMPOSITEELEMENT
/


drop view BIOSOURCE
/


drop view BIOSAMPLE
/


drop view BIOMATERIAL
/


drop view ARRAYVISIONELEMENTRESULT
/


drop view AFFYMETRIXMAS5
/


drop view AFFYMETRIXMAS4
/


drop view AFFYMETRIXCEL
/


drop index ACQUISITION_IND05
/


drop index ACQUISITION_IND06
/


drop index ACQUISITION_IND07
/


drop index ACQUISITION_IND08
/


drop index ACQPARAM_AK01
/


drop index ANALYSISIMPLEMENTATION_IND01
/


drop index ANALYSISIMPPARAM_IND01
/


drop index ANALYSISINPUT_IND01
/


drop index ANALYSISINPUT_IND02
/


drop index ANALYSISINVOCATION_IND01
/


drop index ANALYSISINVOCATIONPARAM_IND01
/


drop index ANALYSISOUTPUT_IND01
/


drop index ANALYTE_MEASUREMENT_IND04
/


drop index ARRAY_AK01
/


drop index ARRAY_IND02
/


drop index ARRAY_IND03
/


drop index ARRAY_IND04
/


drop index ARRAY_IND05
/


drop index ARRAY_IND06
/


drop index ARRAYANNOTATION_IND01
/


drop index ASSAY_IND02
/


drop index ASSAY_IND03
/


drop index ASSAY_IND04
/


drop index ASSAY_IND05
/


drop index ASSAY_INDEX
/


drop index ASSAYBIOMATERIAL_IND01
/


drop index ASSAYBIOMATERIAL_IND02
/


drop index ASSAYLABELEDEXTRACT_IND01
/


drop index ASSAYLABELEDEXTRACT_IND02
/


drop index ASSAYLABELEDEXTRACT_IND03
/


drop index ASSAYPARAM_IND01
/


drop index ASSAYPARAM_IND02
/


drop index ASSAYPARAM_PROT_IND02
/


drop index BIOMATCHARACTERISTIC_IND01
/


drop index BIOMATCHARACTERISTIC_IND02
/


drop index BIOMATERIALIMP_IND01
/


drop index BIOMATERIALIMP_IND02
/


drop index BIOMATERIALIMP_IND03
/


drop index BIOMATERIALIMP_IND04
/


drop index BIOMATERIALIMP_IND05
/


drop index BIOMATERIALMEASUREMENT_IND03
/


drop index BIOMATERIALMEASUREMENT_IND04
/


drop index BIOMATERIALMEASUREMENT_IND05
/


drop index CHANNEL_AK01
/


drop index COMPELEMENTANNOT_IND01
/


drop index RAD3_SPOTFAMILY_IND01
/


drop index RAD3_SPOTFAMILY_IND02
/


drop index SAGETAG_IND01
/


drop index SAGETAG_IND02
/


drop index SAGETAG_IND03
/


drop index COMPELEMENTRESULTIMP_IND01
/


drop index COMPELEMENTRESULTIMP_IND02
/


drop index CONTROL_IND01
/


drop index CONTROL_IND02
/


drop index CONTROL_IND03
/


drop index ELEMENTANNOTATION_IND01
/


drop index ARRAY_IND01
/


drop index RAD3_SPOT_IND02
/


drop index SHORTOLIGO_IND02
/


drop index SHORTOLIGO_IND03
/


drop index ELEMENTRESULTIMP_IND01
/


drop index ELEMENTRESULTIMP_IND02
/


drop index ELEMENTRESULTIMP_IND03
/


drop index ACQUISITION_IND02
/


drop index ACQUISITION_IND03
/


drop index ACQUISITION_IND04
/


drop index INTEGRITYSTATINPUT_IND01
/


drop index INTEGRITYSTATINPUT_IND02
/


drop index LABELMETHOD_IND01
/


drop index LABELMETHOD_IND02
/


drop index MAGEDOCUMENTATION_IND01
/


drop index MAGEDOCUMENTATION_IND02
/


drop index MPC_IND
/


drop index ONTOLOGYENTRY_AK01
/


drop index ONTOLOGYENTRY_IND01
/


drop index ONTOLOGYENTRY_IND02
/


drop index ONTOLOGYENTRY_IND03
/


drop index PROCESSIMPLEMENTATION_IND_01
/


drop index PROCESSIMPPARAM_IND01
/


drop index PROCESSINVOCATION_IND01
/


drop index PROCESSINVOCATIONPARAM_IND01
/


drop index PROCESSINVQUANTIFICATION_IND01
/


drop index PROCESSINVQUANTIFICATION_IND02
/


drop index PROCESSIO_IND01
/


drop index PROCESSIO_IND_01
/


drop index PROCESSIO_IND_02
/


drop index PROCESSIO_IND_03
/


drop index PROCESSIOELEMENT_IND01
/


drop index PROCESSRESULT_IND01
/


drop index PROCESSRESULT_IND02
/


drop index PROTEOME_ASSAY_IND02
/


drop index PROTEOME_ASSAY_IND03
/


drop index PROTEOME_ASSAY_IND04
/


drop index PROTEOME_ASSAY_IND05
/


drop index PROTOCOL_IND01
/


drop index PROTOCOL_IND02
/


drop index PROTOCOL_IND03
/


drop index PROTOCOLPARAM_IND01
/


drop index PROTOCOLPARAM_IND02
/


drop index PROTOCOLPARAM_IND03
/


drop index QUANTIFICATION_IND01
/


drop index QUANTIFICATION_IND02
/


drop index QUANTIFICATION_IND03
/


drop index QUANTIFICATION_IND04
/


drop index QUANTIFICATION_IND05
/


drop index QUANTPARAM_AK01
/


drop index RELATEDACQUISITION_IND01
/


drop index RELATEDACQUISITION_IND02
/


drop index RELATEDQUANTIFICATION_IND01
/


drop index RELATEDQUANTIFICATION_IND02
/


drop index STUDY_AK01
/


drop index STUDY_IND01
/


drop index STUDY_IND02
/


drop index STUDY_IND03
/


drop index STUDYASSAY_IND01
/


drop index STUDYASSAY_IND02
/


drop index STUDYASSAY_PROT_IND02
/


drop index STUDYBIOMATERIAL_IND01
/


drop index STUDYBIOMATERIAL_IND02
/


drop index STUDYDESIGN_AK01
/


drop index STUDYDESIGN_IND01
/


drop index STUDYDESIGNASSAY_IND01
/


drop index STUDYDESIGNASSAY_IND02
/


drop index STUDYDESIGNASSAYPROT_IND02
/


drop index STUDYDESIGNDESCRIPTION_IND01
/


drop index STUDYDESIGNTYPE_IND01
/


drop index STUDYDESIGNTYPE_IND02
/


drop index STUDYFACTOR_AK01
/


drop index STUDYFACTOR_IND01
/


drop index STUDYFACTORVALUE_IND01
/


drop index STUDYFACTORVALUE_IND2
/


drop index STUDYFACTORVALUE_IND3
/


drop index STUDYFACTORVALUE_IND4
/


drop index TREATMENT_IND01
/


drop index TREATMENT_IND02
/


drop index TREATMENT_IND03
/


drop index TREATMENTPARAM_IND01
/


drop index TREATMENTPARAM_IND02
/


drop table ACQUISITION cascade constraints
/


drop table ACQUISITIONPARAM cascade constraints
/


drop table ANALYSIS cascade constraints
/


drop table ANALYSISIMPLEMENTATION cascade constraints
/


drop table ANALYSISIMPLEMENTATIONPARAM cascade constraints
/


drop table ANALYSISINPUT cascade constraints
/


drop table ANALYSISINVOCATION cascade constraints
/


drop table ANALYSISINVOCATIONPARAM cascade constraints
/


drop table ANALYSISOUTPUT cascade constraints
/


drop table ANALYTEMEASUREMENT cascade constraints
/


drop table ARRAY cascade constraints
/


drop table ARRAYANNOTATION cascade constraints
/


drop table ASSAY cascade constraints
/


drop table ASSAYBIOMATERIAL cascade constraints
/


drop table ASSAYDATAPOINT cascade constraints
/


drop table ASSAYGROUP cascade constraints
/


drop table ASSAYLABELEDEXTRACT cascade constraints
/


drop table ASSAYPARAM cascade constraints
/


drop table ASSAYPARAMPROT cascade constraints
/


drop table BAND cascade constraints
/


drop table BIOASSAYTREATMENT cascade constraints
/


drop table BIOMATERIALCHARACTERISTIC cascade constraints
/


drop table BIOMATERIALIMP cascade constraints
/


drop table BIOMATERIALMEASUREMENT cascade constraints
/


drop table BOUNDARYPOINT cascade constraints
/


drop table CHANNEL cascade constraints
/


drop table CHEMICALTREATMENT cascade constraints
/


drop table COLLISIONCELL cascade constraints
/


drop table COMPOSITEELEMENTANNOTATION cascade constraints
/


drop table COMPOSITEELEMENTGUS cascade constraints
/


drop table COMPOSITEELEMENTIMP cascade constraints
/


drop table COMPOSITEELEMENTRESULTIMP cascade constraints
/


drop table CONTROL cascade constraints
/


drop table DATABASEENTRY cascade constraints
/


drop table DBSEARCH cascade constraints
/


drop table DBSEARCHPARAMETERS cascade constraints
/


drop table DETECTION cascade constraints
/


drop table DIGESINGLESPOT cascade constraints
/


drop table ELECTROSPRAY cascade constraints
/


drop table ELEMENTANNOTATION cascade constraints
/


drop table ELEMENTIMP cascade constraints
/


drop table ELEMENTRESULTIMP cascade constraints
/


drop table FRACTION cascade constraints
/


drop table GEL1D cascade constraints
/


drop table GEL2D cascade constraints
/


drop table GRADIENTSTEP cascade constraints
/


drop table HEXAPOLE cascade constraints
/


drop table IDENTIFIEDSPOT cascade constraints
/


drop table IMAGEACQUISITION cascade constraints
/


drop table GELIMAGEANALYSIS cascade constraints
/


drop table INTEGRITYSTATINPUT cascade constraints
/


drop table INTEGRITYSTATISTIC cascade constraints
/


drop table IONSOURCE cascade constraints
/


drop table IONTRAP cascade constraints
/


drop table LABELMETHOD cascade constraints
/


drop table LCCOLUMN cascade constraints
/


drop table LISTPROCESSING cascade constraints
/


drop table MAGEDOCUMENTATION cascade constraints
/


drop table MAGEML cascade constraints
/


drop table MALDI cascade constraints
/


drop table MASSSPECEXPERIMENT cascade constraints
/


drop table MASSSPECMACHINE cascade constraints
/


drop table MATCHEDSPOTS cascade constraints
/


drop table MOBILEPHASECOMPONENT cascade constraints
/


drop table MSMSFRACTION cascade constraints
/


drop table MULTIPLEANALYSIS cascade constraints
/


drop table MZANALYSIS cascade constraints
/


drop table ONTOLOGYENTRY cascade constraints
/


drop table OTHERIONISATION cascade constraints
/


drop table OTHERMZANALYSIS cascade constraints
/


drop table PEAK cascade constraints
/


drop table PEAKLIST cascade constraints
/


drop table PEPTIDEHIT cascade constraints
/


drop table PERCENTX cascade constraints
/


drop table PHYSICALGELITEM cascade constraints
/


drop table PROCESSIMPLEMENTATION cascade constraints
/


drop table PROCESSIMPLEMENTATIONPARAM cascade constraints
/


drop table PROCESSINVOCATION cascade constraints
/


drop table PROCESSINVOCATIONPARAM cascade constraints
/


drop table PROCESSINVQUANTIFICATION cascade constraints
/


drop table PROCESSIO cascade constraints
/


drop table PROCESSIOELEMENT cascade constraints
/


drop table PROCESSRESULT cascade constraints
/


drop table PROTEINHIT cascade constraints
/


drop table PROTEINMODIFICATION cascade constraints
/


drop table PROTEINRECORD cascade constraints
/


drop table PROTEOMEASSAY cascade constraints
/


drop table PROTOCOL cascade constraints
/


drop table PROTOCOLPARAM cascade constraints
/


drop table QUADRUPOLE cascade constraints
/


drop table QUANTIFICATION cascade constraints
/


drop table QUANTIFICATIONPARAM cascade constraints
/


drop table RELATEDACQUISITION cascade constraints
/


drop table RELATEDQUANTIFICATION cascade constraints
/


drop table SPOTMEASURESIMP cascade constraints
/


drop table SPOTRATIO cascade constraints
/


drop table STUDY cascade constraints
/


drop table STUDYASSAY cascade constraints
/


drop table STUDYASSAYPROT cascade constraints
/


drop table STUDYBIOMATERIAL cascade constraints
/


drop table STUDYDESIGN cascade constraints
/


drop table STUDYDESIGNASSAY cascade constraints
/


drop table STUDYDESIGNASSAYPROT cascade constraints
/


drop table STUDYDESIGNDESCRIPTION cascade constraints
/


drop table STUDYDESIGNTYPE cascade constraints
/


drop table STUDYFACTOR cascade constraints
/


drop table STUDYFACTORVALUE cascade constraints
/


drop table STUDYFACTORVALUEPROT cascade constraints
/


drop table TANDEMSEQUENCEDATA cascade constraints
/


drop table TOF cascade constraints
/


drop table TREATEDANALYTE cascade constraints
/


drop table TREATMENT cascade constraints
/


drop table TREATMENTPARAM cascade constraints
/


/*==============================================================*/
/* Table: ACQUISITION                                           */
/*==============================================================*/


create table ACQUISITION  (
   ACQUISITION_ID       NUMBER(8)                        not null,
   ASSAY_ID             NUMBER(8)                        not null,
   PROTOCOL_ID          NUMBER(10),
   CHANNEL_ID           NUMBER(4),
   ACQUISITION_DATE     DATE,
   NAME                 VARCHAR2(100),
   URI                  VARCHAR2(255),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ACQUISITION primary key (ACQUISITION_ID)
)
/


/*==============================================================*/
/* Index: ACQUISITION_IND05                                     */
/*==============================================================*/
create index ACQUISITION_IND05 on ACQUISITION (
   ASSAY_ID ASC
)
/


/*==============================================================*/
/* Index: ACQUISITION_IND06                                     */
/*==============================================================*/
create index ACQUISITION_IND06 on ACQUISITION (
   CHANNEL_ID ASC
)
/


/*==============================================================*/
/* Index: ACQUISITION_IND07                                     */
/*==============================================================*/
create index ACQUISITION_IND07 on ACQUISITION (
   PROTOCOL_ID ASC
)
/


/*==============================================================*/
/* Index: ACQUISITION_IND08                                     */
/*==============================================================*/
create index ACQUISITION_IND08 on ACQUISITION (
   NAME ASC
)
/


/*==============================================================*/
/* Table: ACQUISITIONPARAM                                      */
/*==============================================================*/


create table ACQUISITIONPARAM  (
   ACQUISITION_PARAM_ID NUMBER(5)                        not null,
   ACQUISITION_ID       NUMBER(8)                        not null,
   PROTOCOL_PARAM_ID    NUMBER(10),
   NAME                 VARCHAR2(100)                    not null,
   VALUE                VARCHAR2(50)                     not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ACQUISITIONPARAM primary key (ACQUISITION_PARAM_ID)
)
/


/*==============================================================*/
/* Index: ACQPARAM_AK01                                         */
/*==============================================================*/
create unique index ACQPARAM_AK01 on ACQUISITIONPARAM (
   ACQUISITION_ID ASC,
   NAME ASC
)
/


/*==============================================================*/
/* Table: ANALYSIS                                              */
/*==============================================================*/


create table ANALYSIS  (
   ANALYSIS_ID          NUMBER(5)                        not null,
   NAME                 VARCHAR2(100)                    not null,
   DESCRIPTION          VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ANALYSIS primary key (ANALYSIS_ID)
)
/


/*==============================================================*/
/* Table: ANALYSISIMPLEMENTATION                                */
/*==============================================================*/


create table ANALYSISIMPLEMENTATION  (
   ANALYSIS_IMPLEMENTATION_ID NUMBER(5)                        not null,
   ANALYSIS_ID          NUMBER(5)                        not null,
   NAME                 VARCHAR2(100)                    not null,
   DESCRIPTION          VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ANALYSISIMPLEMENTATION3 primary key (ANALYSIS_IMPLEMENTATION_ID)
)
/


/*==============================================================*/
/* Index: ANALYSISIMPLEMENTATION_IND01                          */
/*==============================================================*/
create index ANALYSISIMPLEMENTATION_IND01 on ANALYSISIMPLEMENTATION (
   ANALYSIS_ID ASC
)
/


/*==============================================================*/
/* Table: ANALYSISIMPLEMENTATIONPARAM                           */
/*==============================================================*/


create table ANALYSISIMPLEMENTATIONPARAM  (
   ANALYSIS_IMP_PARAM_ID NUMBER(5)                        not null,
   ANALYSIS_IMPLEMENTATION_ID NUMBER(5)                        not null,
   NAME                 VARCHAR2(100)                    not null,
   VALUE                VARCHAR2(100)                    not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ANALYSISIMPLPARAM primary key (ANALYSIS_IMP_PARAM_ID)
)
/


/*==============================================================*/
/* Index: ANALYSISIMPPARAM_IND01                                */
/*==============================================================*/
create index ANALYSISIMPPARAM_IND01 on ANALYSISIMPLEMENTATIONPARAM (
   ANALYSIS_IMPLEMENTATION_ID ASC
)
/


/*==============================================================*/
/* Table: ANALYSISINPUT                                         */
/*==============================================================*/


create table ANALYSISINPUT  (
   ANALYSIS_INPUT_ID    NUMBER(5)                        not null,
   ANALYSIS_INVOCATION_ID NUMBER(5)                        not null,
   TABLE_ID             NUMBER(5),
   INPUT_ROW_ID         NUMBER(10),
   INPUT_VALUE          VARCHAR2(50),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ANALYSISINPUT primary key (ANALYSIS_INPUT_ID)
)
/


/*==============================================================*/
/* Index: ANALYSISINPUT_IND01                                   */
/*==============================================================*/
create index ANALYSISINPUT_IND01 on ANALYSISINPUT (
   ANALYSIS_INVOCATION_ID ASC
)
/


/*==============================================================*/
/* Index: ANALYSISINPUT_IND02                                   */
/*==============================================================*/
create index ANALYSISINPUT_IND02 on ANALYSISINPUT (
   TABLE_ID ASC
)
/


/*==============================================================*/
/* Table: ANALYSISINVOCATION                                    */
/*==============================================================*/


create table ANALYSISINVOCATION  (
   ANALYSIS_INVOCATION_ID NUMBER(5)                        not null,
   ANALYSIS_IMPLEMENTATION_ID NUMBER(5)                        not null,
   NAME                 VARCHAR2(100)                    not null,
   DESCRIPTION          VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ANALYSISINVOCATION primary key (ANALYSIS_INVOCATION_ID)
)
/


/*==============================================================*/
/* Index: ANALYSISINVOCATION_IND01                              */
/*==============================================================*/
create index ANALYSISINVOCATION_IND01 on ANALYSISINVOCATION (
   ANALYSIS_IMPLEMENTATION_ID ASC
)
/


/*==============================================================*/
/* Table: ANALYSISINVOCATIONPARAM                               */
/*==============================================================*/


create table ANALYSISINVOCATIONPARAM  (
   ANALYSIS_INVOCATION_PARAM_ID NUMBER(5)                        not null,
   ANALYSIS_INVOCATION_ID NUMBER(5)                        not null,
   NAME                 VARCHAR2(100)                    not null,
   VALUE                VARCHAR2(100)                    not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ANAYLSISINVOCATIONPARAM primary key (ANALYSIS_INVOCATION_PARAM_ID)
)
/


/*==============================================================*/
/* Index: ANALYSISINVOCATIONPARAM_IND01                         */
/*==============================================================*/
create index ANALYSISINVOCATIONPARAM_IND01 on ANALYSISINVOCATIONPARAM (
   ANALYSIS_INVOCATION_ID ASC
)
/


/*==============================================================*/
/* Table: ANALYSISOUTPUT                                        */
/*==============================================================*/


create table ANALYSISOUTPUT  (
   ANALYSIS_OUTPUT_ID   NUMBER(10)                       not null,
   ANALYSIS_INVOCATION_ID NUMBER(5)                        not null,
   NAME                 VARCHAR2(100)                    not null,
   TYPE                 VARCHAR2(50)                     not null,
   VALUE                NUMBER(5)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ANALYSISOUTPUT primary key (ANALYSIS_OUTPUT_ID)
)
/


/*==============================================================*/
/* Index: ANALYSISOUTPUT_IND01                                  */
/*==============================================================*/
create index ANALYSISOUTPUT_IND01 on ANALYSISOUTPUT (
   ANALYSIS_INVOCATION_ID ASC
)
/


/*==============================================================*/
/* Table: ANALYTEMEASUREMENT                                    */
/*==============================================================*/


create table ANALYTEMEASUREMENT  (
   BIO_MATERIAL_MEASUREMENT_ID NUMBER(10)                       not null,
   BIO_MATERIAL_ID      NUMBER(8)                        not null,
   BIOASSAY_TREATMENT_ID NUMBER(8),
   VALUE                FLOAT,
   UNIT_TYPE_ID         NUMBER(5),
   MEASUREMENT_DESCRIPTION VARCHAR2(300),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ANALYTE_MEASUREMENT primary key (BIO_MATERIAL_MEASUREMENT_ID)
)
/


/*==============================================================*/
/* Index: ANALYTE_MEASUREMENT_IND04                             */
/*==============================================================*/
create unique index ANALYTE_MEASUREMENT_IND04 on ANALYTEMEASUREMENT (
   BIO_MATERIAL_ID ASC
)
/


/*==============================================================*/
/* Table: ARRAY                                                 */
/*==============================================================*/


create table ARRAY  (
   ARRAY_ID             NUMBER(4)                        not null,
   MANUFACTURER_ID      NUMBER(12)                       not null,
   PLATFORM_TYPE_ID     NUMBER(10)                       not null,
   SUBSTRATE_TYPE_ID    NUMBER(10),
   PROTOCOL_ID          NUMBER(10),
   EXTERNAL_DATABASE_RELEASE_ID NUMBER(4),
   SOURCE_ID            VARCHAR2(100),
   NAME                 VARCHAR2(100)                    not null,
   VERSION              VARCHAR2(50)                     not null,
   DESCRIPTION          VARCHAR2(500),
   ARRAY_DIMENSIONS     VARCHAR2(50),
   ELEMENT_DIMENSIONS   VARCHAR2(50),
   NUMBER_OF_ELEMENTS   NUMBER(10),
   NUM_ARRAY_COLUMNS    NUMBER(3),
   NUM_ARRAY_ROWS       NUMBER(3),
   NUM_GRID_COLUMNS     NUMBER(3),
   NUM_GRID_ROWS        NUMBER(3),
   NUM_SUB_COLUMNS      NUMBER(6),
   NUM_SUB_ROWS         NUMBER(6),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ARRAY primary key (ARRAY_ID)
)
/


/*==============================================================*/
/* Index: ARRAY_AK01                                            */
/*==============================================================*/
create unique index ARRAY_AK01 on ARRAY (
   NAME ASC,
   VERSION ASC
)
/


/*==============================================================*/
/* Index: ARRAY_IND02                                           */
/*==============================================================*/
create index ARRAY_IND02 on ARRAY (
   EXTERNAL_DATABASE_RELEASE_ID ASC
)
/


/*==============================================================*/
/* Index: ARRAY_IND03                                           */
/*==============================================================*/
create index ARRAY_IND03 on ARRAY (
   PLATFORM_TYPE_ID ASC
)
/


/*==============================================================*/
/* Index: ARRAY_IND04                                           */
/*==============================================================*/
create index ARRAY_IND04 on ARRAY (
   SUBSTRATE_TYPE_ID ASC
)
/


/*==============================================================*/
/* Index: ARRAY_IND05                                           */
/*==============================================================*/
create index ARRAY_IND05 on ARRAY (
   PROTOCOL_ID ASC
)
/


/*==============================================================*/
/* Index: ARRAY_IND06                                           */
/*==============================================================*/
create index ARRAY_IND06 on ARRAY (
   MANUFACTURER_ID ASC
)
/


/*==============================================================*/
/* Table: ARRAYANNOTATION                                       */
/*==============================================================*/


create table ARRAYANNOTATION  (
   ARRAY_ANNOTATION_ID  NUMBER(5)                        not null,
   ARRAY_ID             NUMBER(4)                        not null,
   NAME                 VARCHAR2(500)                    not null,
   VALUE                VARCHAR2(100)                    not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ARRAYANNOTATION primary key (ARRAY_ANNOTATION_ID)
)
/


/*==============================================================*/
/* Index: ARRAYANNOTATION_IND01                                 */
/*==============================================================*/
create index ARRAYANNOTATION_IND01 on ARRAYANNOTATION (
   ARRAY_ID ASC
)
/


/*==============================================================*/
/* Table: ASSAY                                                 */
/*==============================================================*/


create table ASSAY  (
   ASSAY_ID             NUMBER(8)                        not null,
   ARRAY_ID             NUMBER(4)                        not null,
   PROTOCOL_ID          NUMBER(10),
   ASSAY_DATE           DATE,
   ARRAY_IDENTIFIER     VARCHAR2(100),
   ARRAY_BATCH_IDENTIFIER VARCHAR2(100),
   OPERATOR_ID          NUMBER(10)                       not null,
   EXTERNAL_DATABASE_RELEASE_ID NUMBER(5),
   SOURCE_ID            VARCHAR2(50),
   NAME                 VARCHAR2(100),
   DESCRIPTION          VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ASSAY primary key (ASSAY_ID)
)
/


/*==============================================================*/
/* Index: ASSAY_INDEX                                           */
/*==============================================================*/
create index ASSAY_INDEX on ASSAY (
   ARRAY_ID ASC
)
/


/*==============================================================*/
/* Index: ASSAY_IND02                                           */
/*==============================================================*/
create index ASSAY_IND02 on ASSAY (
   OPERATOR_ID ASC
)
/


/*==============================================================*/
/* Index: ASSAY_IND03                                           */
/*==============================================================*/
create index ASSAY_IND03 on ASSAY (
   PROTOCOL_ID ASC
)
/


/*==============================================================*/
/* Index: ASSAY_IND04                                           */
/*==============================================================*/
create index ASSAY_IND04 on ASSAY (
   EXTERNAL_DATABASE_RELEASE_ID ASC
)
/


/*==============================================================*/
/* Index: ASSAY_IND05                                           */
/*==============================================================*/
create index ASSAY_IND05 on ASSAY (
   NAME ASC
)
/


/*==============================================================*/
/* Table: ASSAYBIOMATERIAL                                      */
/*==============================================================*/


create table ASSAYBIOMATERIAL  (
   ASSAY_BIO_MATERIAL_ID NUMBER(5)                        not null,
   ASSAY_ID             NUMBER(8)                        not null,
   BIO_MATERIAL_ID      NUMBER(8)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ASSAYBIOMATERIAL primary key (ASSAY_BIO_MATERIAL_ID)
)
/


/*==============================================================*/
/* Index: ASSAYBIOMATERIAL_IND01                                */
/*==============================================================*/
create index ASSAYBIOMATERIAL_IND01 on ASSAYBIOMATERIAL (
   BIO_MATERIAL_ID ASC
)
/


/*==============================================================*/
/* Index: ASSAYBIOMATERIAL_IND02                                */
/*==============================================================*/
create index ASSAYBIOMATERIAL_IND02 on ASSAYBIOMATERIAL (
   ASSAY_ID ASC
)
/


/*==============================================================*/
/* Table: ASSAYDATAPOINT                                        */
/*==============================================================*/


create table ASSAYDATAPOINT  (
   id                   NUMBER(8)                        not null,
   time                 float                            not null,
   protein_assay        float                            not null,
   lc_column            NUMBER(8)                        not null,
   constraint PK_ASSAYDATAPOINT primary key (lc_column, id)
)
/


/*==============================================================*/
/* Table: ASSAYGROUP                                            */
/*==============================================================*/


create table ASSAYGROUP  (
   STUDY_ID             NUMBER(4)                        not null,
   ASSAY_ID             NUMBER(8)                        not null,
   STUDY_DESIGN_ID      NUMBER(5)                        not null,
   FACTOR_VALUE         VARCHAR2(100)                    not null,
   STUDY_FACTOR_VALUE_ID NUMBER(8),
   constraint PK_ASSAYGROUP primary key (STUDY_ID, ASSAY_ID, STUDY_DESIGN_ID)
)
/


/*==============================================================*/
/* Table: ASSAYLABELEDEXTRACT                                   */
/*==============================================================*/


create table ASSAYLABELEDEXTRACT  (
   ASSAY_LABELED_EXTRACT_ID NUMBER(8)                        not null,
   ASSAY_ID             NUMBER(8)                        not null,
   LABELED_EXTRACT_ID   NUMBER(8)                        not null,
   CHANNEL_ID           NUMBER(4)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ASSAYLABELEDEXTRACT primary key (ASSAY_LABELED_EXTRACT_ID)
)
/


/*==============================================================*/
/* Index: ASSAYLABELEDEXTRACT_IND01                             */
/*==============================================================*/
create index ASSAYLABELEDEXTRACT_IND01 on ASSAYLABELEDEXTRACT (
   ASSAY_ID ASC
)
/


/*==============================================================*/
/* Index: ASSAYLABELEDEXTRACT_IND02                             */
/*==============================================================*/
create index ASSAYLABELEDEXTRACT_IND02 on ASSAYLABELEDEXTRACT (
   CHANNEL_ID ASC
)
/


/*==============================================================*/
/* Index: ASSAYLABELEDEXTRACT_IND03                             */
/*==============================================================*/
create index ASSAYLABELEDEXTRACT_IND03 on ASSAYLABELEDEXTRACT (
   LABELED_EXTRACT_ID ASC
)
/


/*==============================================================*/
/* Table: ASSAYPARAM                                            */
/*==============================================================*/


create table ASSAYPARAM  (
   ASSAY_PARAM_ID       NUMBER(10)                       not null,
   ASSAY_ID             NUMBER(8)                        not null,
   PROTOCOL_PARAM_ID    NUMBER(10)                       not null,
   VALUE                VARCHAR2(100)                    not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ASSAYPARAM primary key (ASSAY_PARAM_ID)
)
/


/*==============================================================*/
/* Index: ASSAYPARAM_IND01                                      */
/*==============================================================*/
create index ASSAYPARAM_IND01 on ASSAYPARAM (
   ASSAY_ID ASC
)
/


/*==============================================================*/
/* Index: ASSAYPARAM_IND02                                      */
/*==============================================================*/
create index ASSAYPARAM_IND02 on ASSAYPARAM (
   PROTOCOL_PARAM_ID ASC
)
/


/*==============================================================*/
/* Table: ASSAYPARAMPROT                                        */
/*==============================================================*/


create table ASSAYPARAMPROT  (
   ASSAY_PARAM_ID       NUMBER(10)                       not null,
   PROTEOME_ASSAY_ID    NUMBER(8),
   PROTOCOL_PARAM_ID    NUMBER(10)                       not null,
   VALUE                VARCHAR2(100)                    not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ASSAYPARAM_PROT primary key (ASSAY_PARAM_ID)
)
/


/*==============================================================*/
/* Index: ASSAYPARAM_PROT_IND02                                 */
/*==============================================================*/
create index ASSAYPARAM_PROT_IND02 on ASSAYPARAMPROT (
   PROTOCOL_PARAM_ID ASC
)
/


/*==============================================================*/
/* Table: BAND                                                  */
/*==============================================================*/


create table BAND  (
   id                   NUMBER(8)                        not null,
   area                 float,
   intensity            float,
   local_background     float,
   annotation           varchar(200),
   annotation_source    varchar(200),
   volume               float,
   pixel_x_coord        float,
   pixel_y_coord        float,
   pixel_radius         float,
   normalisation        varchar(200),
   normalised_volume    float,
   lane_number          float                            not null,
   apparent_mass        float                            not null,
   gel_1d               NUMBER(8)                        not null,
   physicalGelSpot_ID   NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_BAND primary key (gel_1d, id)
)
/


/*==============================================================*/
/* Table: BIOASSAYTREATMENT                                     */
/*==============================================================*/


create table BIOASSAYTREATMENT  (
   BIOASSAY_TREATMENT_ID NUMBER(8)                        not null,
   ORDER_NUM            NUMBER(3)                        not null,
   PROTEOME_ASSAY_ID    NUMBER(8),
   PROTOCOL_ID          NUMBER(10),
   TREATMENT_TYPE_ID    NUMBER(10),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_BIOASSAYTREATMENT primary key (BIOASSAY_TREATMENT_ID)
)
/


/*==============================================================*/
/* Table: BIOMATERIALCHARACTERISTIC                             */
/*==============================================================*/


create table BIOMATERIALCHARACTERISTIC  (
   BIO_MATERIAL_CHARACTERISTIC_ID NUMBER(5)                        not null,
   BIO_MATERIAL_ID      NUMBER(8)                        not null,
   ONTOLOGY_ENTRY_ID    NUMBER(10)                       not null,
   VALUE                VARCHAR2(100),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_BIOAMATCHARACTERISTIC primary key (BIO_MATERIAL_CHARACTERISTIC_ID)
)
/


/*==============================================================*/
/* Index: BIOMATCHARACTERISTIC_IND01                            */
/*==============================================================*/
create index BIOMATCHARACTERISTIC_IND01 on BIOMATERIALCHARACTERISTIC (
   BIO_MATERIAL_ID ASC
)
/


/*==============================================================*/
/* Index: BIOMATCHARACTERISTIC_IND02                            */
/*==============================================================*/
create index BIOMATCHARACTERISTIC_IND02 on BIOMATERIALCHARACTERISTIC (
   ONTOLOGY_ENTRY_ID ASC
)
/


/*==============================================================*/
/* Table: BIOMATERIALIMP                                        */
/*==============================================================*/


create table BIOMATERIALIMP  (
   BIO_MATERIAL_ID      NUMBER(8)                        not null,
   LABEL_METHOD_ID      NUMBER(4),
   TAXON_ID             NUMBER(10),
   BIO_SOURCE_PROVIDER_ID NUMBER(12),
   BIO_MATERIAL_TYPE_ID NUMBER(10),
   SUBCLASS_VIEW        VARCHAR2(27)                     not null,
   EXTERNAL_DATABASE_RELEASE_ID NUMBER(5),
   SOURCE_ID            VARCHAR2(50),
   STRING1              VARCHAR2(100),
   STRING2              VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_BIOMATERIALIMP primary key (BIO_MATERIAL_ID)
)
/


/*==============================================================*/
/* Index: BIOMATERIALIMP_IND01                                  */
/*==============================================================*/
create index BIOMATERIALIMP_IND01 on BIOMATERIALIMP (
   LABEL_METHOD_ID ASC
)
/


/*==============================================================*/
/* Index: BIOMATERIALIMP_IND02                                  */
/*==============================================================*/
create index BIOMATERIALIMP_IND02 on BIOMATERIALIMP (
   TAXON_ID ASC
)
/


/*==============================================================*/
/* Index: BIOMATERIALIMP_IND03                                  */
/*==============================================================*/
create index BIOMATERIALIMP_IND03 on BIOMATERIALIMP (
   BIO_MATERIAL_TYPE_ID ASC
)
/


/*==============================================================*/
/* Index: BIOMATERIALIMP_IND04                                  */
/*==============================================================*/
create index BIOMATERIALIMP_IND04 on BIOMATERIALIMP (
   BIO_SOURCE_PROVIDER_ID ASC
)
/


/*==============================================================*/
/* Index: BIOMATERIALIMP_IND05                                  */
/*==============================================================*/
create index BIOMATERIALIMP_IND05 on BIOMATERIALIMP (
   EXTERNAL_DATABASE_RELEASE_ID ASC
)
/


/*==============================================================*/
/* Table: BIOMATERIALMEASUREMENT                                */
/*==============================================================*/


create table BIOMATERIALMEASUREMENT  (
   BIO_MATERIAL_MEASUREMENT_ID NUMBER(10)                       not null,
   TREATMENT_ID         NUMBER(10)                       not null,
   BIO_MATERIAL_ID      NUMBER(8)                        not null,
   VALUE                FLOAT,
   UNIT_TYPE_ID         NUMBER(10),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_BIOMATERIALMEASUREMENT primary key (BIO_MATERIAL_MEASUREMENT_ID)
)
/


/*==============================================================*/
/* Index: BIOMATERIALMEASUREMENT_IND03                          */
/*==============================================================*/
create index BIOMATERIALMEASUREMENT_IND03 on BIOMATERIALMEASUREMENT (
   TREATMENT_ID ASC
)
/


/*==============================================================*/
/* Index: BIOMATERIALMEASUREMENT_IND04                          */
/*==============================================================*/
create index BIOMATERIALMEASUREMENT_IND04 on BIOMATERIALMEASUREMENT (
   BIO_MATERIAL_ID ASC
)
/


/*==============================================================*/
/* Index: BIOMATERIALMEASUREMENT_IND05                          */
/*==============================================================*/
create index BIOMATERIALMEASUREMENT_IND05 on BIOMATERIALMEASUREMENT (
   UNIT_TYPE_ID ASC
)
/


/*==============================================================*/
/* Table: BOUNDARYPOINT                                         */
/*==============================================================*/


create table BOUNDARYPOINT  (
   id                   NUMBER(8)                        not null,
   pixel_x_coord        float                            not null,
   pixel_y_coord        float                            not null,
   spot_gel_2d          NUMBER(8)                        not null,
   spot_id              NUMBER(8)                        not null,
   physicalGelItem_ID   NUMBER(8)                        not null,
   gel2D                NUMBER(8)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_BOUNDARYPOINT primary key (spot_gel_2d, spot_id, physicalGelItem_ID, gel2D, id)
)
/


/*==============================================================*/
/* Table: CHANNEL                                               */
/*==============================================================*/


create table CHANNEL  (
   CHANNEL_ID           NUMBER(4)                        not null,
   NAME                 VARCHAR2(100)                    not null,
   DEFINITION           VARCHAR2(500)                    not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_CHANNEL primary key (CHANNEL_ID)
)
/


/*==============================================================*/
/* Index: CHANNEL_AK01                                          */
/*==============================================================*/
create unique index CHANNEL_AK01 on CHANNEL (
   NAME ASC
)
/


/*==============================================================*/
/* Table: CHEMICALTREATMENT                                     */
/*==============================================================*/


create table CHEMICALTREATMENT  (
   chemical_treatment_ID NUMBER(8)                        not null,
   BIOASSAY_TREATMENT_ID NUMBER(8)                        not null,
   treatment_type       NUMBER(10),
   digestion            varchar(200)                     not null,
   derivatisations      varchar(200)                     not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_CHEMICALTREATMENT primary key (chemical_treatment_ID)
)
/


/*==============================================================*/
/* Table: COLLISIONCELL                                         */
/*==============================================================*/


create table COLLISIONCELL  (
   collision_cellID     NUMBER(8)                        not null,
   mz_analysis_ID       NUMBER(8),
   gas_type             varchar(100)                     not null,
   gas_pressure         float                            not null,
   collision_offset     float                            not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_COLLISIONCELL primary key (collision_cellID)
)
/


/*==============================================================*/
/* Table: COMPOSITEELEMENTANNOTATION                            */
/*==============================================================*/


create table COMPOSITEELEMENTANNOTATION  (
   COMPOSITE_ELEMENT_ANNOT_ID NUMBER(12)                       not null,
   COMPOSITE_ELEMENT_ID NUMBER(10)                       not null,
   NAME                 VARCHAR2(500)                    not null,
   VALUE                VARCHAR2(255)                    not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_COMPOSITEELEMENTANNOTATION primary key (COMPOSITE_ELEMENT_ANNOT_ID)
)
/


/*==============================================================*/
/* Index: COMPELEMENTANNOT_IND01                                */
/*==============================================================*/
create index COMPELEMENTANNOT_IND01 on COMPOSITEELEMENTANNOTATION (
   COMPOSITE_ELEMENT_ID ASC
)
/


/*==============================================================*/
/* Table: COMPOSITEELEMENTGUS                                   */
/*==============================================================*/


create table COMPOSITEELEMENTGUS  (
   COMPOSITE_ELEMENT_GUS_ID NUMBER(12)                       not null,
   COMPOSITE_ELEMENT_ID NUMBER(10),
   TABLE_ID             NUMBER(5)                        not null,
   ROW_ID               NUMBER(12)                       not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_COMPOSITEELEMENTGUS primary key (COMPOSITE_ELEMENT_GUS_ID)
)
/


/*==============================================================*/
/* Table: COMPOSITEELEMENTIMP                                   */
/*==============================================================*/


create table COMPOSITEELEMENTIMP  (
   COMPOSITE_ELEMENT_ID NUMBER(10)                       not null,
   PARENT_ID            NUMBER(10),
   ARRAY_ID             NUMBER(4)                        not null,
   SUBCLASS_VIEW        VARCHAR2(27)                     not null,
   EXTERNAL_DATABASE_RELEASE_ID NUMBER(4),
   SOURCE_ID            VARCHAR2(50),
   TINYINT1             NUMBER(3),
   SMALLINT1            NUMBER(5),
   SMALLINT2            NUMBER(5),
   CHAR1                VARCHAR2(5),
   CHAR2                VARCHAR2(5),
   TINYSTRING1          VARCHAR2(50),
   TINYSTRING2          VARCHAR2(50),
   SMALLSTRING1         VARCHAR2(100),
   SMALLSTRING2         VARCHAR2(100),
   STRING1              VARCHAR2(500),
   STRING2              VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_COMPOSITEELEMENTIMP primary key (COMPOSITE_ELEMENT_ID)
)
/


/*==============================================================*/
/* Index: RAD3_SPOTFAMILY_IND01                                 */
/*==============================================================*/
create index RAD3_SPOTFAMILY_IND01 on COMPOSITEELEMENTIMP (
   COMPOSITE_ELEMENT_ID ASC,
   SMALLSTRING1 ASC,
   SMALLSTRING2 ASC
)
/


/*==============================================================*/
/* Index: RAD3_SPOTFAMILY_IND02                                 */
/*==============================================================*/
create index RAD3_SPOTFAMILY_IND02 on COMPOSITEELEMENTIMP (
   ARRAY_ID ASC,
   EXTERNAL_DATABASE_RELEASE_ID ASC,
   SOURCE_ID ASC
)
/


/*==============================================================*/
/* Index: SAGETAG_IND01                                         */
/*==============================================================*/
create index SAGETAG_IND01 on COMPOSITEELEMENTIMP (
   ARRAY_ID ASC,
   TINYSTRING1 ASC
)
/


/*==============================================================*/
/* Index: SAGETAG_IND02                                         */
/*==============================================================*/
create index SAGETAG_IND02 on COMPOSITEELEMENTIMP (
   PARENT_ID ASC
)
/


/*==============================================================*/
/* Index: SAGETAG_IND03                                         */
/*==============================================================*/
create index SAGETAG_IND03 on COMPOSITEELEMENTIMP (
   EXTERNAL_DATABASE_RELEASE_ID ASC
)
/


/*==============================================================*/
/* Table: COMPOSITEELEMENTRESULTIMP                             */
/*==============================================================*/


create table COMPOSITEELEMENTRESULTIMP  (
   COMPOSITE_ELEMENT_RESULT_ID NUMBER(10)                       not null,
   COMPOSITE_ELEMENT_ID NUMBER(10)                       not null,
   QUANTIFICATION_ID    NUMBER(8)                        not null,
   SUBCLASS_VIEW        VARCHAR2(27)                     not null,
   FLOAT1               FLOAT,
   FLOAT2               FLOAT,
   FLOAT3               FLOAT,
   FLOAT4               FLOAT,
   INT1                 NUMBER(12),
   SMALLINT1            NUMBER(5),
   SMALLINT2            NUMBER(5),
   SMALLINT3            NUMBER(5),
   TINYINT1             NUMBER(3),
   TINYINT2             NUMBER(3),
   TINYINT3             NUMBER(3),
   CHAR1                VARCHAR2(5),
   CHAR2                VARCHAR2(5),
   CHAR3                VARCHAR2(5),
   STRING1              VARCHAR2(500),
   STRING2              VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_SFMRES primary key (COMPOSITE_ELEMENT_RESULT_ID)
)
/


/*==============================================================*/
/* Index: COMPELEMENTRESULTIMP_IND01                            */
/*==============================================================*/
create index COMPELEMENTRESULTIMP_IND01 on COMPOSITEELEMENTRESULTIMP (
   COMPOSITE_ELEMENT_ID ASC,
   SUBCLASS_VIEW ASC
)
/


/*==============================================================*/
/* Index: COMPELEMENTRESULTIMP_IND02                            */
/*==============================================================*/
create index COMPELEMENTRESULTIMP_IND02 on COMPOSITEELEMENTRESULTIMP (
   COMPOSITE_ELEMENT_ID ASC,
   QUANTIFICATION_ID ASC,
   SUBCLASS_VIEW ASC
)
/


/*==============================================================*/
/* Table: CONTROL                                               */
/*==============================================================*/


create table CONTROL  (
   CONTROL_ID           NUMBER(5)                        not null,
   CONTROL_TYPE_ID      NUMBER(10)                       not null,
   ASSAY_ID             NUMBER(8)                        not null,
   TABLE_ID             NUMBER(10)                       not null,
   ROW_ID               NUMBER(12)                       not null,
   NAME                 VARCHAR2(100),
   VALUE                VARCHAR2(255),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_CONTROL primary key (CONTROL_ID)
)
/


/*==============================================================*/
/* Index: CONTROL_IND01                                         */
/*==============================================================*/
create index CONTROL_IND01 on CONTROL (
   TABLE_ID ASC
)
/


/*==============================================================*/
/* Index: CONTROL_IND02                                         */
/*==============================================================*/
create index CONTROL_IND02 on CONTROL (
   ASSAY_ID ASC
)
/


/*==============================================================*/
/* Index: CONTROL_IND03                                         */
/*==============================================================*/
create index CONTROL_IND03 on CONTROL (
   CONTROL_TYPE_ID ASC
)
/


/*==============================================================*/
/* Table: DATABASEENTRY                                         */
/*==============================================================*/


create table DATABASEENTRY  (
   database_name        NUMBER(10),
   database_version     NUMBER(10),
   database_uri         NUMBER(10),
   database_entry_ID    NUMBER(8)                        not null,
   accession            VARCHAR(20),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_DATABASE_ENTRY primary key (database_entry_ID)
)
/


/*==============================================================*/
/* Table: DBSEARCH                                              */
/*==============================================================*/


create table DBSEARCH  (
   db_search_ID         NUMBER(8)                        not null,
   peak_list_ID         NUMBER(8),
   db_search_parameters_ID NUMBER(8),
   username             varchar(100)                     not null,
   id_date              date                             not null,
   n_terminal_aa        varchar(100),
   c_terminal_aa        varchar(100),
   count_of_specific_aa NUMBER(8),
   name_of_counted_aa   varchar(100),
   regex_pattern        varchar(100),
   db_search_parameters NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_DBSEARCH primary key (db_search_ID)
)
/


/*==============================================================*/
/* Table: DBSEARCHPARAMETERS                                    */
/*==============================================================*/


create table DBSEARCHPARAMETERS  (
   db_search_parameters_ID NUMBER(8)                        not null,
   PROTOCOL_ID          NUMBER(10),
   program              varchar(100)                     not null,
   database             varchar(100)                     not null,
   database_date        date                             not null,
   taxonomical_filter   NUMBER(8),
   fixed_modifications  varchar(100),
   variable_modifications varchar(100),
   max_missed_cleavages NUMBER(8),
   mass_value_type      varchar(100),
   fragment_ion_tolerance float,
   peptide_mass_tolerance float,
   accurate_mass_mode   NUMBER(8),
   mass_error_type      varchar(100),
   mass_error           float,
   protonated           NUMBER(8),
   icat_option          NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_DBSEARCHPARAMETERS primary key (db_search_parameters_ID)
)
/


/*==============================================================*/
/* Table: DETECTION                                             */
/*==============================================================*/


create table DETECTION  (
   detection_ID         NUMBER(8)                        not null,
   type                 varchar(9)                       
         constraint CKC_TYPE_DETECTIO check (type is null or ( type in ('photomultiplier','electron 
multiplier','micro-channel plate','ICR') )),
   constraint PK_DETECTION primary key (detection_ID)
)
/


/*==============================================================*/
/* Table: DIGESINGLESPOT                                        */
/*==============================================================*/


create table DIGESINGLESPOT  (
   identified_spot_ID   NUMBER(8),
   DIGESingleSpot_ID    NUMBER(8)                        not null,
   GEL_IMAGE_ANALYSIS_ID    NUMBER(8)                        not null,
   SPOT_MEASURES_ID     NUMBER(10),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_DIGESINGLESPOT primary key (DIGESingleSpot_ID)
)
/


/*==============================================================*/
/* Table: ELECTROSPRAY                                          */
/*==============================================================*/


create table ELECTROSPRAY  (
   electrospray_ID      NUMBER(8)                        not null,
   ion_source_ID        NUMBER(8),
   spray_tip_voltage    float,
   spray_tip_diameter   float                            not null,
   solution_voltage     float,
   cone_voltage         float                            not null,
   loading_type         varchar(2)                       
         constraint CKC_LOADING_TYPE_ELECTROS check (loading_type is null or ( loading_type in ('LC','DI') 
)),
   solvent              varchar(100)                     not null,
   interface_manufacturer varchar(200)                     not null,
   spray_tip_manufacturer varchar(200)                     not null,
   ion_source           NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ELECTROSPRAY primary key (electrospray_ID)
)
/


/*==============================================================*/
/* Table: ELEMENTANNOTATION                                     */
/*==============================================================*/


create table ELEMENTANNOTATION  (
   ELEMENT_ANNOTATION_ID NUMBER(10)                       not null,
   ELEMENT_ID           NUMBER(10)                       not null,
   NAME                 VARCHAR2(100)                    not null,
   VALUE                VARCHAR2(500)                    not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ELEMENTANNOTATION primary key (ELEMENT_ANNOTATION_ID)
)
/


/*==============================================================*/
/* Index: ELEMENTANNOTATION_IND01                               */
/*==============================================================*/
create index ELEMENTANNOTATION_IND01 on ELEMENTANNOTATION (
   ELEMENT_ID ASC
)
/


/*==============================================================*/
/* Table: ELEMENTIMP                                            */
/*==============================================================*/


create table ELEMENTIMP  (
   ELEMENT_ID           NUMBER(10)                       not null,
   COMPOSITE_ELEMENT_ID NUMBER(10),
   ARRAY_ID             NUMBER(4)                        not null,
   ELEMENT_TYPE_ID      NUMBER(10),
   EXTERNAL_DATABASE_RELEASE_ID NUMBER(5),
   SOURCE_ID            VARCHAR2(50),
   SUBCLASS_VIEW        VARCHAR2(27)                     not null,
   TINYINT1             NUMBER(3),
   SMALLINT1            NUMBER(5),
   CHAR1                VARCHAR2(5),
   CHAR2                VARCHAR2(5),
   CHAR3                VARCHAR2(5),
   CHAR4                VARCHAR2(5),
   CHAR5                VARCHAR2(5),
   CHAR6                VARCHAR2(5),
   CHAR7                VARCHAR2(5),
   TINYSTRING1          VARCHAR2(50),
   TINYSTRING2          VARCHAR2(50),
   SMALLSTRING1         VARCHAR2(100),
   SMALLSTRING2         VARCHAR2(100),
   STRING1              VARCHAR2(500),
   STRING2              VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ELEMENT primary key (ELEMENT_ID)
)
/


/*==============================================================*/
/* Index: ARRAY_IND01                                           */
/*==============================================================*/
create index ARRAY_IND01 on ELEMENTIMP (
   ARRAY_ID ASC
)
/


/*==============================================================*/
/* Index: RAD3_SPOT_IND02                                       */
/*==============================================================*/
create index RAD3_SPOT_IND02 on ELEMENTIMP (
   COMPOSITE_ELEMENT_ID ASC
)
/


/*==============================================================*/
/* Index: SHORTOLIGO_IND02                                      */
/*==============================================================*/
create index SHORTOLIGO_IND02 on ELEMENTIMP (
   ELEMENT_TYPE_ID ASC
)
/


/*==============================================================*/
/* Index: SHORTOLIGO_IND03                                      */
/*==============================================================*/
create index SHORTOLIGO_IND03 on ELEMENTIMP (
   EXTERNAL_DATABASE_RELEASE_ID ASC
)
/


/*==============================================================*/
/* Table: ELEMENTRESULTIMP                                      */
/*==============================================================*/


create table ELEMENTRESULTIMP  (
   ELEMENT_RESULT_ID    NUMBER(10)                       not null,
   ELEMENT_ID           NUMBER(10)                       not null,
   COMPOSITE_ELEMENT_RESULT_ID NUMBER(10),
   QUANTIFICATION_ID    NUMBER(8)                        not null,
   SUBCLASS_VIEW        VARCHAR2(27)                     not null,
   FOREGROUND           FLOAT,
   BACKGROUND           FLOAT,
   FOREGROUND_SD        FLOAT,
   BACKGROUND_SD        FLOAT,
   FLOAT1               FLOAT,
   FLOAT2               FLOAT,
   FLOAT3               FLOAT,
   FLOAT4               FLOAT,
   FLOAT5               FLOAT,
   FLOAT6               FLOAT,
   FLOAT7               FLOAT,
   FLOAT8               FLOAT,
   FLOAT9               FLOAT,
   FLOAT10              FLOAT,
   FLOAT11              FLOAT,
   FLOAT12              FLOAT,
   FLOAT13              FLOAT,
   FLOAT14              FLOAT,
   INT1                 NUMBER(12),
   INT2                 NUMBER(12),
   INT3                 NUMBER(12),
   INT4                 NUMBER(12),
   INT5                 NUMBER(12),
   INT6                 NUMBER(12),
   INT7                 NUMBER(12),
   INT8                 NUMBER(12),
   INT9                 NUMBER(12),
   INT10                NUMBER(12),
   INT11                NUMBER(12),
   INT12                NUMBER(12),
   INT13                NUMBER(12),
   INT14                NUMBER(12),
   INT15                NUMBER(12),
   TINYINT1             NUMBER(3),
   TINYINT2             NUMBER(3),
   TINYINT3             NUMBER(3),
   SMALLINT1            NUMBER(5),
   SMALLINT2            NUMBER(5),
   SMALLINT3            NUMBER(5),
   CHAR1                VARCHAR2(5),
   CHAR2                VARCHAR2(5),
   CHAR3                VARCHAR2(5),
   CHAR4                VARCHAR2(5),
   TINYSTRING1          VARCHAR2(50),
   TINYSTRING2          VARCHAR2(50),
   TINYSTRING3          VARCHAR2(50),
   SMALLSTRING1         VARCHAR2(100),
   SMALLSTRING2         VARCHAR2(100),
   STRING1              VARCHAR2(500),
   STRING2              VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ELEMENTRESULT_N primary key (ELEMENT_RESULT_ID)
)
/


/*==============================================================*/
/* Index: ELEMENTRESULTIMP_IND01                                */
/*==============================================================*/
create index ELEMENTRESULTIMP_IND01 on ELEMENTRESULTIMP (
   ELEMENT_ID ASC,
   SUBCLASS_VIEW ASC
)
/


/*==============================================================*/
/* Index: ELEMENTRESULTIMP_IND02                                */
/*==============================================================*/
create index ELEMENTRESULTIMP_IND02 on ELEMENTRESULTIMP (
   ELEMENT_ID ASC,
   QUANTIFICATION_ID ASC,
   SUBCLASS_VIEW ASC
)
/


/*==============================================================*/
/* Index: ELEMENTRESULTIMP_IND03                                */
/*==============================================================*/
create index ELEMENTRESULTIMP_IND03 on ELEMENTRESULTIMP (
   COMPOSITE_ELEMENT_RESULT_ID ASC
)
/


/*==============================================================*/
/* Table: FRACTION                                              */
/*==============================================================*/


create table FRACTION  (
   Fraction_ID          NUMBER(8)                        not null,
   start_point          float                            not null,
   end_point            float                            not null,
   protein_assay        float,
   LCColumn_ID          NUMBER(8)                        not null,
   BIO_MATERIAL_ID      NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_FRACTION primary key (Fraction_ID, LCColumn_ID)
)
/


/*==============================================================*/
/* Table: GEL1D                                                 */
/*==============================================================*/


create table GEL1D  (
   Gel1D_ID             NUMBER(8)                        not null,
   BIOASSAY_TREATMENT_ID NUMBER(8)                        not null,
   description          varchar(100)                     not null,
   equipment            varchar(200)                     not null,
   percent_acrylamide   float                            not null,
   solubilization_buffer varchar(100)                     not null,
   stain_details        varchar(200)                     not null,
   protein_assay        float,
   in_gel_digestion     varchar(100),
   background           varchar(100),
   pixel_size_x         varchar(100),
   pixel_size_y         varchar(100),
   denaturing_agent     varchar(100),
   mass_start           float,
   mass_end             float,
   run_details          varchar(300),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_GEL1D primary key (Gel1D_ID)
)
/


/*==============================================================*/
/* Table: GEL2D                                                 */
/*==============================================================*/


create table GEL2D  (
   Gel2D_ID             NUMBER(8)                        not null,
   BIOASSAY_TREATMENT_ID NUMBER(8)                        not null,
   description          varchar(500),
   equipment            varchar(200),
   percent_acrylamide   float,
   solubilization_buffer varchar(100),
   stain_details        varchar(200),
   protein_assay        float,
   in_gel_digestion     varchar(100),
   background           varchar(100),
   pixel_size_x         varchar(100),
   pixel_size_y         varchar(100),
   pi_start             float,
   pi_end               float,
   mass_start           float,
   mass_end             float,
   first_dim_details    varchar(200),
   second_dim_details   varchar(200),
   dimensionX           NUMBER(8),
   dimensionY           NUMBER(8),
   dimensionZ           NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_GEL2D primary key (Gel2D_ID)
)
/


/*==============================================================*/
/* Table: GELIMAGEANALYSIS                                      */
/*==============================================================*/


create table GELIMAGEANALYSIS  (
   ACQUISITION_ID       NUMBER(8)                        not null,
   PROTOCOL_ID          NUMBER(10),
   GEL_IMAGE_ANALYSIS_ID    NUMBER(8)                    not null,
   processing_description VARCHAR(300),
   warped_image         VARCHAR(100),
   warping_map          VARCHAR(100),
   name                 VARCHAR(100),
   IMAGEANALYSIS_DATE   DATE,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_GEL_IMAGE_ANALYSIS primary key (GEL_IMAGE_ANALYSIS_ID)
)
/


/*==============================================================*/
/* Table: GRADIENTSTEP                                          */
/*==============================================================*/


create table GRADIENTSTEP  (
   GradientStep_ID      NUMBER(8)                        not null,
   step_time            float                            not null,
   lc_column            NUMBER(8)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_GRADIENTSTEP primary key (lc_column, GradientStep_ID)
)
/


/*==============================================================*/
/* Table: HEXAPOLE                                              */
/*==============================================================*/


create table HEXAPOLE  (
   hexapole_ID          NUMBER(8)                        not null,
   mz_analysis_ID       NUMBER(8),
   description          varchar(100),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_HEXAPOLE primary key (hexapole_ID)
)
/


/*==============================================================*/
/* Table: IDENTIFIEDSPOT                                        */
/*==============================================================*/


create table IDENTIFIEDSPOT  (
   identified_spot_ID   NUMBER(8)                        not null,
   area                 float,
   intensity            float,
   local_background     float,
   annotation           varchar(200),
   annotation_source    varchar(200),
   volume               float,
   pixel_x_coord        float,
   pixel_y_coord        float,
   pixel_radius         float,
   normalisation        varchar(200),
   normalised_volume    float,
   apparent_pi          float,
   apparent_mass        float,
   physicalGelItem_ID   NUMBER(8)                        not null,
   GEL_IMAGE_ANALYSIS_ID    NUMBER(8),
   SPOT_MEASURES_ID     NUMBER(10),
   peakHeight           NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_IDENTIFIEDSPOT primary key (identified_spot_ID)
)
/


/*==============================================================*/
/* Table: IMAGEACQUISITION                                      */
/*==============================================================*/


create table IMAGEACQUISITION  (
   IMAGE_ACQUISITION_ID NUMBER(8)                        not null,
   PROTOCOL_ID          NUMBER(10),
   CHANNEL_ID           NUMBER(4),
   PROTEOME_ASSAY_ID    NUMBER(8),
   ACQUISITION_DATE     DATE,
   NAME                 VARCHAR2(100),
   URI                  VARCHAR2(255),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_IMAGE_ACQUISITION primary key (IMAGE_ACQUISITION_ID)
)
/


/*==============================================================*/
/* Index: ACQUISITION_IND02                                     */
/*==============================================================*/
create index ACQUISITION_IND02 on IMAGEACQUISITION (
   CHANNEL_ID ASC
)
/


/*==============================================================*/
/* Index: ACQUISITION_IND03                                     */
/*==============================================================*/
create index ACQUISITION_IND03 on IMAGEACQUISITION (
   PROTOCOL_ID ASC
)
/


/*==============================================================*/
/* Index: ACQUISITION_IND04                                     */
/*==============================================================*/
create index ACQUISITION_IND04 on IMAGEACQUISITION (
   NAME ASC
)
/




/*==============================================================*/
/* Table: INTEGRITYSTATINPUT                                    */
/*==============================================================*/


create table INTEGRITYSTATINPUT  (
   INTEGRITY_STAT_INPUT_ID NUMBER(10)                       not null,
   INTEGRITY_STATISTIC_ID NUMBER(8)                        not null,
   INPUT_TABLE_ID       NUMBER(10)                       not null,
   INPUT_ROW_ID         NUMBER(10)                       not null,
   ROW_DESIGNATION      VARCHAR2(200),
   IS_TRUSTED_INPUT     NUMBER(1),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_INTEGRITYSTATINPUT primary key (INTEGRITY_STAT_INPUT_ID)
)
/


/*==============================================================*/
/* Index: INTEGRITYSTATINPUT_IND01                              */
/*==============================================================*/
create index INTEGRITYSTATINPUT_IND01 on INTEGRITYSTATINPUT (
   INTEGRITY_STATISTIC_ID ASC
)
/


/*==============================================================*/
/* Index: INTEGRITYSTATINPUT_IND02                              */
/*==============================================================*/
create index INTEGRITYSTATINPUT_IND02 on INTEGRITYSTATINPUT (
   INPUT_TABLE_ID ASC
)
/


/*==============================================================*/
/* Table: INTEGRITYSTATISTIC                                    */
/*==============================================================*/


create table INTEGRITYSTATISTIC  (
   INTEGRITY_STATISTIC_ID NUMBER(8)                        not null,
   STATISTIC_METHOD     VARCHAR2(200)                    not null,
   TRUSTED_INPUT_FORMULA VARCHAR2(200),
   VALUE                VARCHAR2(100)                    not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_INTEGRITYSTATISTIC primary key (INTEGRITY_STATISTIC_ID)
)
/


/*==============================================================*/
/* Table: IONSOURCE                                             */
/*==============================================================*/


create table IONSOURCE  (
   ion_source_ID        NUMBER(8)                        not null,
   collision_energy     float,
   type                 varchar(12)                      
         constraint CKC_TYPE_IONSOURC check (type is null or ( type in 
('MALDI','Electrospray','OtherIonisation') )),
   mz_analysis          NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_IONSOURCE primary key (ion_source_ID)
)
/


/*==============================================================*/
/* Table: IONTRAP                                               */
/*==============================================================*/


create table IONTRAP  (
   ion_trap_ID          NUMBER(8)                        not null,
   mz_analysis_ID       NUMBER(8),
   gas_type             varchar(100)                     not null,
   gas_pressure         float                            not null,
   rf_frequency         float,
   excitation_amplitude float,
   isolation_centre     float                            not null,
   isolation_width      float                            not null,
   final_ms_level       float,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_IONTRAP primary key (ion_trap_ID)
)
/


/*==============================================================*/
/* Table: LABELMETHOD                                           */
/*==============================================================*/


create table LABELMETHOD  (
   LABEL_METHOD_ID      NUMBER(4)                        not null,
   PROTOCOL_ID          NUMBER(10)                       not null,
   CHANNEL_ID           NUMBER(4)                        not null,
   LABEL_USED           VARCHAR2(50),
   LABEL_METHOD         VARCHAR2(1000),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_LABEL primary key (LABEL_METHOD_ID)
)
/


/*==============================================================*/
/* Index: LABELMETHOD_IND01                                     */
/*==============================================================*/
create index LABELMETHOD_IND01 on LABELMETHOD (
   PROTOCOL_ID ASC
)
/


/*==============================================================*/
/* Index: LABELMETHOD_IND02                                     */
/*==============================================================*/
create index LABELMETHOD_IND02 on LABELMETHOD (
   CHANNEL_ID ASC
)
/


/*==============================================================*/
/* Table: LCCOLUMN                                              */
/*==============================================================*/


create table LCCOLUMN  (
   LCColumn_ID          NUMBER(8)                        not null,
   BIOASSAY_TREATMENT_ID NUMBER(8),
   description          varchar(200)                     not null,
   manufacturer         varchar(100)                     not null,
   part_number          varchar(50)                      not null,
   batch_number         varchar(50)                      not null,
   internal_length      float                            not null,
   internal_diameter    float                            not null,
   stationary_phase     varchar(200)                     not null,
   bead_size            float,
   pore_size            float,
   temperature          float                            not null,
   flow_rate            float,
   injection_volume     float                            not null,
   parameters_file      varchar(100)                     not null,
   lc_column            NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_LCCOLUMN primary key (LCColumn_ID)
)
/


/*==============================================================*/
/* Table: LISTPROCESSING                                        */
/*==============================================================*/


create table LISTPROCESSING  (
   list_processing_ID   NUMBER(8)                        not null,
   smoothing_process    varchar(100)                     not null,
   background_threshold float                            not null,
   peak_list_ID         NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_LISTPROCESSING primary key (list_processing_ID)
)
/


/*==============================================================*/
/* Table: MAGEDOCUMENTATION                                     */
/*==============================================================*/


create table MAGEDOCUMENTATION  (
   MAGE_DOCUMENTATION_ID NUMBER(5)                        not null,
   MAGE_ML_ID           NUMBER(8)                        not null,
   TABLE_ID             NUMBER(10)                       not null,
   ROW_ID               NUMBER(12)                       not null,
   MAGE_IDENTIFIER      VARCHAR2(100)                    not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_MAGEDOCUMENTATION primary key (MAGE_DOCUMENTATION_ID)
)
/


/*==============================================================*/
/* Index: MAGEDOCUMENTATION_IND01                               */
/*==============================================================*/
create index MAGEDOCUMENTATION_IND01 on MAGEDOCUMENTATION (
   TABLE_ID ASC
)
/


/*==============================================================*/
/* Index: MAGEDOCUMENTATION_IND02                               */
/*==============================================================*/
create index MAGEDOCUMENTATION_IND02 on MAGEDOCUMENTATION (
   MAGE_ML_ID ASC
)
/


/*==============================================================*/
/* Table: MAGEML                                                */
/*==============================================================*/


create table MAGEML  (
   MAGE_ML_ID           NUMBER(8)                        not null,
   MAGE_PACKAGE         VARCHAR2(100)                    not null,
   MAGE_ML              CLOB                             not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_MAGEML primary key (MAGE_ML_ID)
)
/


/*==============================================================*/
/* Table: MALDI                                                 */
/*==============================================================*/


create table MALDI  (
   MALDI_ID             NUMBER(8)                        not null,
   ion_source_ID        NUMBER(8),
   laser_wavelength     float                            not null,
   laser_power          float,
   matrix_type          varchar(100),
   grid_voltage         float                            not null,
   acceleration_voltage float                            not null,
   ion_mode             varchar(50)                      not null,
   ion_source           NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_MALDI primary key (MALDI_ID)
)
/


/*==============================================================*/
/* Table: MASSSPECEXPERIMENT                                    */
/*==============================================================*/


create table MASSSPECEXPERIMENT  (
   mass_spec_experiment_ID NUMBER(8)                        not null,
   BIOASSAY_TREATMENT_ID NUMBER(8)                        not null,
   MSMachineID          NUMBER(8),
   description          varchar(200),
   parameters_file      varchar(200),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_MASSSPECEXPERIMENT primary key (mass_spec_experiment_ID)
)
/


/*==============================================================*/
/* Table: MASSSPECMACHINE                                       */
/*==============================================================*/


create table MASSSPECMACHINE  (
   mass_spec_machine_ID NUMBER(8)                        not null,
   ion_source_ID        NUMBER(8),
   manufacturer         varchar(200)                     not null,
   model_name           varchar(200)                     not null,
   software_version     varchar(200)                     not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_MASSSPECMACHINE primary key (mass_spec_machine_ID)
)
/


/*==============================================================*/
/* Table: MATCHEDSPOTS                                          */
/*==============================================================*/


create table MATCHEDSPOTS  (
   matched_Spots_ID     NUMBER(8)                        not null,
   ACQUISITION_ID       NUMBER(8),
   GEL_IMAGE_ANALYSIS_ID    NUMBER(8),
   multiple_analysis_ID NUMBER(8),
   gel_2d               NUMBER(8)                        not null,
   identified_spot_ID   NUMBER(8)                        not null,
   physicalGelItem_ID   NUMBER(8)                        not null,
   gel2D                NUMBER(8)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_MATCHED_SPOTS primary key (matched_Spots_ID, gel_2d, identified_spot_ID, 
physicalGelItem_ID, gel2D)
)
/


/*==============================================================*/
/* Table: MOBILEPHASECOMPONENT                                  */
/*==============================================================*/


create table MOBILEPHASECOMPONENT  (
   id                   NUMBER(8)                        not null,
   description          varchar(100)                     not null,
   concentration        float                            not null,
   lc_column            NUMBER(8)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_MOBILEPHASECOMPONENT primary key (id)
)
/


/*==============================================================*/
/* Index: MPC_IND                                               */
/*==============================================================*/
create index MPC_IND on MOBILEPHASECOMPONENT (
   lc_column ASC
)
/


/*==============================================================*/
/* Table: MSMSFRACTION                                          */
/*==============================================================*/


create table MSMSFRACTION  (
   peak_list_ID         NUMBER(8),
   msms_fraction_ID     NUMBER(8)                        not null,
   target_m_to_z        float                            not null,
   plus_or_minus        float                            not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_MSMSFRACTION primary key (msms_fraction_ID)
)
/


/*==============================================================*/
/* Table: MULTIPLEANALYSIS                                      */
/*==============================================================*/


create table MULTIPLEANALYSIS  (
   ACQUISITION_ID       NUMBER(8)                        not null,
   GEL_IMAGE_ANALYSIS_ID    NUMBER(8)                        not null,
   multiple_analysis_ID NUMBER(8)                        not null,
   analysis_type        NUMBER(10),
   PROTOCOL_ID          NUMBER(10),
   description          VARCHAR(300),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_MULTIPLE_ANALYSIS primary key (ACQUISITION_ID, GEL_IMAGE_ANALYSIS_ID, multiple_analysis_ID)
)
/


/*==============================================================*/
/* Table: MZANALYSIS                                            */
/*==============================================================*/


create table MZANALYSIS  (
   mz_analysis_ID       NUMBER(8)                        not null,
   detection_ID         NUMBER(8),
   type                 varchar(14)                      
         constraint CKC_TYPE_MZANALYS check (type is null or ( type in 
('Quadrupole','Hexapole','IonTrap','CollisionCell','ToF','OthermzAnalysis') )),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_MZANALYSIS primary key (mz_analysis_ID)
)
/


/*==============================================================*/
/* Table: ONTOLOGYENTRY                                         */
/*==============================================================*/


create table ONTOLOGYENTRY  (
   ONTOLOGY_ENTRY_ID    NUMBER(10)                       not null,
   PARENT_ID            NUMBER(10),
   TABLE_ID             NUMBER(8),
   ROW_ID               NUMBER(12),
   EXTERNAL_DATABASE_RELEASE_ID NUMBER(10),
   SOURCE_ID            VARCHAR2(100),
   URI                  VARCHAR2(500),
   NAME                 VARCHAR2(100),
   CATEGORY             VARCHAR2(100)                    not null,
   VALUE                VARCHAR2(100)                    not null,
   DEFINITION           VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_ONTOLOGYENTRY primary key (ONTOLOGY_ENTRY_ID)
)
/


/*==============================================================*/
/* Index: ONTOLOGYENTRY_AK01                                    */
/*==============================================================*/
create unique index ONTOLOGYENTRY_AK01 on ONTOLOGYENTRY (
   CATEGORY ASC,
   VALUE ASC
)
/


/*==============================================================*/
/* Index: ONTOLOGYENTRY_IND01                                   */
/*==============================================================*/
create index ONTOLOGYENTRY_IND01 on ONTOLOGYENTRY (
   PARENT_ID ASC
)
/


/*==============================================================*/
/* Index: ONTOLOGYENTRY_IND02                                   */
/*==============================================================*/
create index ONTOLOGYENTRY_IND02 on ONTOLOGYENTRY (
   TABLE_ID ASC
)
/


/*==============================================================*/
/* Index: ONTOLOGYENTRY_IND03                                   */
/*==============================================================*/
create index ONTOLOGYENTRY_IND03 on ONTOLOGYENTRY (
   EXTERNAL_DATABASE_RELEASE_ID ASC
)
/


/*==============================================================*/
/* Table: OTHERIONISATION                                       */
/*==============================================================*/


create table OTHERIONISATION  (
   otherIonisation_ID   NUMBER(8)                        not null,
   ion_source_ID        NUMBER(8),
   ONTOLOGY_ENTRY_ID    NUMBER(10),
   name                 varchar(100)                     not null,
   ion_source           NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_OTHERIONISATION primary key (otherIonisation_ID)
)
/


/*==============================================================*/
/* Table: OTHERMZANALYSIS                                       */
/*==============================================================*/


create table OTHERMZANALYSIS  (
   other_mz_analysis_ID NUMBER(8)                        not null,
   mz_analysis_ID       NUMBER(8),
   ONTOLOGY_ENTRY_ID    NUMBER(10),
   name                 varchar(50)                      not null,
   mz_analysis          NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_OTHERMZANALYSIS primary key (other_mz_analysis_ID)
)
/


/*==============================================================*/
/* Table: PEAK                                                  */
/*==============================================================*/


create table PEAK  (
   peak_ID              NUMBER(8)                        not null,
   m_to_z               float                            not null,
   abundance            float,
   multiplicity         NUMBER(8),
   peak_list_ID         NUMBER(8)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PEAK primary key (peak_ID, peak_list_ID)
)
/


/*==============================================================*/
/* Table: PEAKLIST                                              */
/*==============================================================*/


create table PEAKLIST  (
   peak_list_ID         NUMBER(8)                        not null,
   mass_spec_experiment_ID NUMBER(8),
   list_type            varchar(11)                      not null
         constraint CKC_LIST_TYPE_PEAKLIST check (list_type in ('Full List','Edited List','MSMS Result')),
   description          varchar(100),
   mass_value_type      varchar(50),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PEAKLIST primary key (peak_list_ID)
)
/


/*==============================================================*/
/* Table: PEPTIDEHIT                                            */
/*==============================================================*/


create table PEPTIDEHIT  (
   peptide_hit_ID       NUMBER(8)                        not null,
   score                float                            not null,
   score_type           varchar(100)                     not null,
   sequence             varchar(100)                     not null,
   information          varchar(100),
   probability          float,
   db_search_ID         NUMBER(8),
   database_entry_ID    NUMBER(8),
   constraint PK_PEPTIDEHIT primary key (peptide_hit_ID)
)
/


/*==============================================================*/
/* Table: PERCENTX                                              */
/*==============================================================*/


create table PERCENTX  (
   Percent_ID           NUMBER(8)                        not null,
   lc_column            NUMBER(8),
   GradientStep_ID      NUMBER(8),
   percentage           float                            not null,
   mobile_phase_component NUMBER(8)                        not null,
   gradient_step_lc_column NUMBER(8)                        not null,
   gradient_step_id     NUMBER(8)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PERCENTX primary key (Percent_ID)
)
/


/*==============================================================*/
/* Table: PHYSICALGELITEM                                       */
/*==============================================================*/


create table PHYSICALGELITEM  (
   physicalGelItem_ID   NUMBER(8)                        not null,
   gel2D                NUMBER(8),
   Gel1D_ID             NUMBER(8),
   BIO_MATERIAL_ID      NUMBER(8),
   ProteinRecord_ID     NUMBER(8),
   description          VARCHAR(200),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PHYSICALGELITEM primary key (physicalGelItem_ID)
)
/


/*==============================================================*/
/* Table: PROCESSIMPLEMENTATION                                 */
/*==============================================================*/


create table PROCESSIMPLEMENTATION  (
   PROCESS_IMPLEMENTATION_ID NUMBER(5)                        not null,
   PROCESS_TYPE_ID      NUMBER(10)                       not null,
   NAME                 VARCHAR2(100),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PROCESSIMPLEMENTATION primary key (PROCESS_IMPLEMENTATION_ID)
)
/


/*==============================================================*/
/* Index: PROCESSIMPLEMENTATION_IND_01                          */
/*==============================================================*/
create index PROCESSIMPLEMENTATION_IND_01 on PROCESSIMPLEMENTATION (
   PROCESS_TYPE_ID ASC
)
/


/*==============================================================*/
/* Table: PROCESSIMPLEMENTATIONPARAM                            */
/*==============================================================*/


create table PROCESSIMPLEMENTATIONPARAM  (
   PROCESS_IMPLEMETATION_PARAM_ID NUMBER(5)                        not null,
   PROCESS_IMPLEMENTATION_ID NUMBER(5)                        not null,
   NAME                 VARCHAR2(100)                    not null,
   VALUE                VARCHAR2(100)                    not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PROCESSIMPPARAM primary key (PROCESS_IMPLEMETATION_PARAM_ID)
)
/


/*==============================================================*/
/* Index: PROCESSIMPPARAM_IND01                                 */
/*==============================================================*/
create index PROCESSIMPPARAM_IND01 on PROCESSIMPLEMENTATIONPARAM (
   PROCESS_IMPLEMENTATION_ID ASC
)
/


/*==============================================================*/
/* Table: PROCESSINVOCATION                                     */
/*==============================================================*/


create table PROCESSINVOCATION  (
   PROCESS_INVOCATION_ID NUMBER(5)                        not null,
   PROCESS_IMPLEMENTATION_ID NUMBER(5)                        not null,
   PROCESS_INVOCATION_DATE DATE                             not null,
   DESCRIPTION          VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PROCESSINV primary key (PROCESS_INVOCATION_ID)
)
/


/*==============================================================*/
/* Index: PROCESSINVOCATION_IND01                               */
/*==============================================================*/
create index PROCESSINVOCATION_IND01 on PROCESSINVOCATION (
   PROCESS_IMPLEMENTATION_ID ASC
)
/


/*==============================================================*/
/* Table: PROCESSINVOCATIONPARAM                                */
/*==============================================================*/


create table PROCESSINVOCATIONPARAM  (
   PROCESS_INVOCATION_PARAM_ID NUMBER(8)                        not null,
   PROCESS_INVOCATION_ID NUMBER(5)                        not null,
   NAME                 VARCHAR2(100)                    not null,
   VALUE                VARCHAR2(100)                    not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PROCESSINVOCATIONPARAM primary key (PROCESS_INVOCATION_PARAM_ID)
)
/


/*==============================================================*/
/* Index: PROCESSINVOCATIONPARAM_IND01                          */
/*==============================================================*/
create index PROCESSINVOCATIONPARAM_IND01 on PROCESSINVOCATIONPARAM (
   PROCESS_INVOCATION_ID ASC
)
/


/*==============================================================*/
/* Table: PROCESSINVQUANTIFICATION                              */
/*==============================================================*/


create table PROCESSINVQUANTIFICATION  (
   PROCESS_INV_QUANTIFICATION_ID NUMBER(8)                        not null,
   PROCESS_INVOCATION_ID NUMBER(5)                        not null,
   QUANTIFICATION_ID    NUMBER(8)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PROCESSINVQUANT primary key (PROCESS_INV_QUANTIFICATION_ID)
)
/


/*==============================================================*/
/* Index: PROCESSINVQUANTIFICATION_IND01                        */
/*==============================================================*/
create index PROCESSINVQUANTIFICATION_IND01 on PROCESSINVQUANTIFICATION (
   PROCESS_INVOCATION_ID ASC
)
/


/*==============================================================*/
/* Index: PROCESSINVQUANTIFICATION_IND02                        */
/*==============================================================*/
create index PROCESSINVQUANTIFICATION_IND02 on PROCESSINVQUANTIFICATION (
   QUANTIFICATION_ID ASC
)
/


/*==============================================================*/
/* Table: PROCESSIO                                             */
/*==============================================================*/


create table PROCESSIO  (
   PROCESS_IO_ID        NUMBER(12)                       not null,
   PROCESS_INVOCATION_ID NUMBER(5)                        not null,
   TABLE_ID             NUMBER(5)                        not null,
   INPUT_RESULT_ID      NUMBER(12)                       not null,
   INPUT_ROLE           VARCHAR2(50),
   OUTPUT_RESULT_ID     NUMBER(12)                       not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PROCESSIO primary key (PROCESS_IO_ID)
)
/


/*==============================================================*/
/* Index: PROCESSIO_IND01                                       */
/*==============================================================*/
create index PROCESSIO_IND01 on PROCESSIO (
   TABLE_ID ASC
)
/


/*==============================================================*/
/* Index: PROCESSIO_IND_01                                      */
/*==============================================================*/
create index PROCESSIO_IND_01 on PROCESSIO (
   OUTPUT_RESULT_ID ASC
)
/


/*==============================================================*/
/* Index: PROCESSIO_IND_02                                      */
/*==============================================================*/
create index PROCESSIO_IND_02 on PROCESSIO (
   PROCESS_INVOCATION_ID ASC
)
/


/*==============================================================*/
/* Index: PROCESSIO_IND_03                                      */
/*==============================================================*/
create index PROCESSIO_IND_03 on PROCESSIO (
   INPUT_RESULT_ID ASC,
   OUTPUT_RESULT_ID ASC,
   TABLE_ID ASC
)
/


/*==============================================================*/
/* Table: PROCESSIOELEMENT                                      */
/*==============================================================*/


create table PROCESSIOELEMENT  (
   PROCESS_IO_ELEMENT_ID NUMBER(10)                       not null,
   PROCESS_IO_ID        NUMBER(12)                       not null,
   ELEMENT_ID           NUMBER(8)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PROCESSIOELEMENT primary key (PROCESS_IO_ELEMENT_ID)
)
/


/*==============================================================*/
/* Index: PROCESSIOELEMENT_IND01                                */
/*==============================================================*/
create index PROCESSIOELEMENT_IND01 on PROCESSIOELEMENT (
   PROCESS_IO_ID ASC
)
/


/*==============================================================*/
/* Table: PROCESSRESULT                                         */
/*==============================================================*/


create table PROCESSRESULT  (
   PROCESS_RESULT_ID    NUMBER(12)                       not null,
   VALUE                FLOAT                            not null,
   UNIT_TYPE_ID         NUMBER(10),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_RESULT5 primary key (PROCESS_RESULT_ID)
)
/


/*==============================================================*/
/* Index: PROCESSRESULT_IND01                                   */
/*==============================================================*/
create index PROCESSRESULT_IND01 on PROCESSRESULT (
   PROCESS_RESULT_ID ASC,
   VALUE ASC
)
/


/*==============================================================*/
/* Index: PROCESSRESULT_IND02                                   */
/*==============================================================*/
create index PROCESSRESULT_IND02 on PROCESSRESULT (
   UNIT_TYPE_ID ASC
)
/


/*==============================================================*/
/* Table: PROTEINHIT                                            */
/*==============================================================*/


create table PROTEINHIT  (
   protein_hit_ID       NUMBER(8)                        not null,
   ProteinRecord_ID     NUMBER(8),
   peptide_hit_ID       NUMBER(8),
   description          VARCHAR(300),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PROTEINHIT primary key (protein_hit_ID)
)
/


/*==============================================================*/
/* Table: PROTEINMODIFICATION                                   */
/*==============================================================*/


create table PROTEINMODIFICATION  (
   protein_modification_ID NUMBER(8)                        not null,
   modification_type    NUMBER(10),
   protein_record_ID    NUMBER(8),
   start_pos            NUMBER(8),
   end_pos              NUMBER(8),
   description          VARCHAR(200),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PROTEINMODIFICATION primary key (protein_modification_ID)
)
/


/*==============================================================*/
/* Table: PROTEINRECORD                                         */
/*==============================================================*/


create table PROTEINRECORD  (
   protein_record_ID    NUMBER(8)                        not null,
   database_entry_ID    NUMBER(8),
   protein_name         VARCHAR2(100),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PROTEINRECORD primary key (protein_record_ID)
)
/


/*==============================================================*/
/* Table: PROTEOMEASSAY                                         */
/*==============================================================*/


create table PROTEOMEASSAY  (
   PROTEOME_ASSAY_ID    NUMBER(8)                        not null,
   PROTOCOL_ID          NUMBER(10),
   ASSAY_DATE           DATE,
   OPERATOR_ID          NUMBER(10)                       not null,
   EXTERNAL_DATABASE_RELEASE_ID NUMBER(5),
   SOURCE_ID            VARCHAR2(50),
   NAME                 VARCHAR2(100),
   DESCRIPTION          VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PROTEOME_ASSAY primary key (PROTEOME_ASSAY_ID)
)
/


/*==============================================================*/
/* Index: PROTEOME_ASSAY_IND02                                  */
/*==============================================================*/
create index PROTEOME_ASSAY_IND02 on PROTEOMEASSAY (
   OPERATOR_ID ASC
)
/


/*==============================================================*/
/* Index: PROTEOME_ASSAY_IND03                                  */
/*==============================================================*/
create index PROTEOME_ASSAY_IND03 on PROTEOMEASSAY (
   PROTOCOL_ID ASC
)
/


/*==============================================================*/
/* Index: PROTEOME_ASSAY_IND04                                  */
/*==============================================================*/
create index PROTEOME_ASSAY_IND04 on PROTEOMEASSAY (
   EXTERNAL_DATABASE_RELEASE_ID ASC
)
/


/*==============================================================*/
/* Index: PROTEOME_ASSAY_IND05                                  */
/*==============================================================*/
create index PROTEOME_ASSAY_IND05 on PROTEOMEASSAY (
   NAME ASC
)
/


/*==============================================================*/
/* Table: PROTOCOL                                              */
/*==============================================================*/


create table PROTOCOL  (
   PROTOCOL_ID          NUMBER(10)                       not null,
   PROTOCOL_TYPE_ID     NUMBER(10)                       not null,
   SOFTWARE_TYPE_ID     NUMBER(10),
   HARDWARE_TYPE_ID     NUMBER(10),
   BIBLIOGRAPHIC_REFERENCE_ID NUMBER(10),
   EXTERNAL_DATABASE_RELEASE_ID NUMBER(4),
   SOURCE_ID            VARCHAR2(100),
   NAME                 VARCHAR2(100)                    not null,
   URI                  VARCHAR2(100),
   PROTOCOL_DESCRIPTION VARCHAR2(4000),
   HARDWARE_DESCRIPTION VARCHAR2(500),
   SOFTWARE_DESCRIPTION VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PROTOCOL primary key (PROTOCOL_ID)
)
/


/*==============================================================*/
/* Index: PROTOCOL_IND01                                        */
/*==============================================================*/
create index PROTOCOL_IND01 on PROTOCOL (
   PROTOCOL_TYPE_ID ASC
)
/


/*==============================================================*/
/* Index: PROTOCOL_IND02                                        */
/*==============================================================*/
create index PROTOCOL_IND02 on PROTOCOL (
   SOFTWARE_TYPE_ID ASC
)
/


/*==============================================================*/
/* Index: PROTOCOL_IND03                                        */
/*==============================================================*/
create index PROTOCOL_IND03 on PROTOCOL (
   HARDWARE_TYPE_ID ASC
)
/


/*==============================================================*/
/* Table: PROTOCOLPARAM                                         */
/*==============================================================*/


create table PROTOCOLPARAM  (
   PROTOCOL_PARAM_ID    NUMBER(10)                       not null,
   PROTOCOL_ID          NUMBER(10)                       not null,
   NAME                 VARCHAR2(100)                    not null,
   DATA_TYPE_ID         NUMBER(10),
   UNIT_TYPE_ID         NUMBER(10),
   VALUE                VARCHAR2(100),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_PROTOCOLPARAM primary key (PROTOCOL_PARAM_ID)
)
/


/*==============================================================*/
/* Index: PROTOCOLPARAM_IND01                                   */
/*==============================================================*/
create index PROTOCOLPARAM_IND01 on PROTOCOLPARAM (
   DATA_TYPE_ID ASC
)
/


/*==============================================================*/
/* Index: PROTOCOLPARAM_IND02                                   */
/*==============================================================*/
create index PROTOCOLPARAM_IND02 on PROTOCOLPARAM (
   UNIT_TYPE_ID ASC
)
/


/*==============================================================*/
/* Index: PROTOCOLPARAM_IND03                                   */
/*==============================================================*/
create index PROTOCOLPARAM_IND03 on PROTOCOLPARAM (
   PROTOCOL_ID ASC
)
/


/*==============================================================*/
/* Table: QUADRUPOLE                                            */
/*==============================================================*/


create table QUADRUPOLE  (
   quadrupole_ID        NUMBER(8)                        not null,
   mz_analysis_ID       NUMBER(8),
   description          varchar(100),
   mz_analysis          NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_QUADRUPOLE primary key (quadrupole_ID)
)
/


/*==============================================================*/
/* Table: QUANTIFICATION                                        */
/*==============================================================*/


create table QUANTIFICATION  (
   QUANTIFICATION_ID    NUMBER(8)                        not null,
   ACQUISITION_ID       NUMBER(8)                        not null,
   OPERATOR_ID          NUMBER(10),
   PROTOCOL_ID          NUMBER(10),
   RESULT_TABLE_ID      NUMBER(5),
   QUANTIFICATION_DATE  DATE,
   NAME                 VARCHAR2(100),
   URI                  VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_QUANTIFICATION primary key (QUANTIFICATION_ID)
)
/


/*==============================================================*/
/* Index: QUANTIFICATION_IND01                                  */
/*==============================================================*/
create index QUANTIFICATION_IND01 on QUANTIFICATION (
   ACQUISITION_ID ASC
)
/


/*==============================================================*/
/* Index: QUANTIFICATION_IND02                                  */
/*==============================================================*/
create index QUANTIFICATION_IND02 on QUANTIFICATION (
   OPERATOR_ID ASC
)
/


/*==============================================================*/
/* Index: QUANTIFICATION_IND03                                  */
/*==============================================================*/
create index QUANTIFICATION_IND03 on QUANTIFICATION (
   PROTOCOL_ID ASC
)
/


/*==============================================================*/
/* Index: QUANTIFICATION_IND04                                  */
/*==============================================================*/
create index QUANTIFICATION_IND04 on QUANTIFICATION (
   RESULT_TABLE_ID ASC
)
/


/*==============================================================*/
/* Index: QUANTIFICATION_IND05                                  */
/*==============================================================*/
create index QUANTIFICATION_IND05 on QUANTIFICATION (
   NAME ASC
)
/


/*==============================================================*/
/* Table: QUANTIFICATIONPARAM                                   */
/*==============================================================*/


create table QUANTIFICATIONPARAM  (
   QUANTIFICATION_PARAM_ID NUMBER(5)                        not null,
   QUANTIFICATION_ID    NUMBER(8)                        not null,
   PROTOCOL_PARAM_ID    NUMBER(10),
   NAME                 VARCHAR2(100)                    not null,
   VALUE                VARCHAR2(50)                     not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_QUANTIFICATIONPARAM primary key (QUANTIFICATION_PARAM_ID)
)
/


/*==============================================================*/
/* Index: QUANTPARAM_AK01                                       */
/*==============================================================*/
create unique index QUANTPARAM_AK01 on QUANTIFICATIONPARAM (
   NAME ASC,
   QUANTIFICATION_ID ASC
)
/


/*==============================================================*/
/* Table: RELATEDACQUISITION                                    */
/*==============================================================*/


create table RELATEDACQUISITION  (
   RELATED_ACQUISITION_ID NUMBER(4)                        not null,
   ACQUISITION_ID       NUMBER(8)                        not null,
   ASSOCIATED_ACQUISITION_ID NUMBER(8)                        not null,
   NAME                 VARCHAR2(100),
   DESIGNATION          VARCHAR2(50),
   ASSOCIATED_DESIGNATION VARCHAR2(50),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_RELASSAY primary key (RELATED_ACQUISITION_ID)
)
/


/*==============================================================*/
/* Index: RELATEDACQUISITION_IND01                              */
/*==============================================================*/
create index RELATEDACQUISITION_IND01 on RELATEDACQUISITION (
   ACQUISITION_ID ASC
)
/


/*==============================================================*/
/* Index: RELATEDACQUISITION_IND02                              */
/*==============================================================*/
create index RELATEDACQUISITION_IND02 on RELATEDACQUISITION (
   ASSOCIATED_ACQUISITION_ID ASC
)
/


/*==============================================================*/
/* Table: RELATEDQUANTIFICATION                                 */
/*==============================================================*/


create table RELATEDQUANTIFICATION  (
   RELATED_QUANTIFICATION_ID NUMBER(4)                        not null,
   QUANTIFICATION_ID    NUMBER(8)                        not null,
   ASSOCIATED_QUANTIFICATION_ID NUMBER(8)                        not null,
   NAME                 VARCHAR2(100),
   DESIGNATION          VARCHAR2(50),
   ASSOCIATED_DESIGNATION VARCHAR2(50),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_RELATEDQUANTIFICATION primary key (RELATED_QUANTIFICATION_ID)
)
/


/*==============================================================*/
/* Index: RELATEDQUANTIFICATION_IND01                           */
/*==============================================================*/
create index RELATEDQUANTIFICATION_IND01 on RELATEDQUANTIFICATION (
   QUANTIFICATION_ID ASC
)
/


/*==============================================================*/
/* Index: RELATEDQUANTIFICATION_IND02                           */
/*==============================================================*/
create index RELATEDQUANTIFICATION_IND02 on RELATEDQUANTIFICATION (
   ASSOCIATED_QUANTIFICATION_ID ASC
)
/


/*==============================================================*/
/* Table: SPOTMEASURESIMP                                       */
/*==============================================================*/


create table SPOTMEASURESIMP  (
   SPOT_MEASURES_ID     NUMBER(10)                       not null,
   SUBCLASS_VIEW        VARCHAR2(27)                     not null,
   FLOAT1               FLOAT,
   FLOAT2               FLOAT,
   FLOAT3               FLOAT,
   FLOAT4               FLOAT,
   FLOAT5               FLOAT,
   FLOAT6               FLOAT,
   FLOAT7               FLOAT,
   FLOAT8               FLOAT,
   FLOAT9               FLOAT,
   FLOAT10              FLOAT,
   FLOAT11              FLOAT,
   FLOAT12              FLOAT,
   FLOAT13              FLOAT,
   FLOAT14              FLOAT,
   INT1                 NUMBER(12),
   INT2                 NUMBER(12),
   INT3                 NUMBER(12),
   INT4                 NUMBER(12),
   INT5                 NUMBER(12),
   INT6                 NUMBER(12),
   INT7                 NUMBER(12),
   INT8                 NUMBER(12),
   INT9                 NUMBER(12),
   INT10                NUMBER(12),
   INT11                NUMBER(12),
   INT12                NUMBER(12),
   INT13                NUMBER(12),
   INT14                NUMBER(12),
   INT15                NUMBER(12),
   TINYINT1             NUMBER(3),
   TINYINT2             NUMBER(3),
   TINYINT3             NUMBER(3),
   SMALLINT1            NUMBER(5),
   SMALLINT2            NUMBER(5),
   SMALLINT3            NUMBER(5),
   CHAR1                VARCHAR2(5),
   CHAR2                VARCHAR2(5),
   CHAR3                VARCHAR2(5),
   CHAR4                VARCHAR2(5),
   TINYSTRING1          VARCHAR2(50),
   TINYSTRING2          VARCHAR2(50),
   TINYSTRING3          VARCHAR2(50),
   SMALLSTRING1         VARCHAR2(100),
   SMALLSTRING2         VARCHAR2(100),
   STRING1              VARCHAR2(500),
   STRING2              VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_SPOT_MEASURES_IMP primary key (SPOT_MEASURES_ID)
)
/


/*==============================================================*/
/* Table: SPOTRATIO                                             */
/*==============================================================*/


create table SPOTRATIO  (
   spotRatio_ID         NUMBER(8)                        not null,
   first_DIGESingleSpot_ID NUMBER(8)                        not null,
   second_DIGESingleSpot_ID NUMBER(8)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_SPOTRATIO primary key (spotRatio_ID)
)
/


/*==============================================================*/
/* Table: STUDY                                                 */
/*==============================================================*/


create table STUDY  (
   STUDY_ID             NUMBER(4)                        not null,
   CONTACT_ID           NUMBER(12)                       not null,
   BIBLIOGRAPHIC_REFERENCE_ID NUMBER(10),
   EXTERNAL_DATABASE_RELEASE_ID NUMBER(4),
   SOURCE_ID            VARCHAR2(100),
   NAME                 VARCHAR2(100)                    not null,
   DESCRIPTION          VARCHAR2(4000),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_STUDY primary key (STUDY_ID)
)
/


/*==============================================================*/
/* Index: STUDY_AK01                                            */
/*==============================================================*/
create unique index STUDY_AK01 on STUDY (
   NAME ASC
)
/


/*==============================================================*/
/* Index: STUDY_IND01                                           */
/*==============================================================*/
create index STUDY_IND01 on STUDY (
   BIBLIOGRAPHIC_REFERENCE_ID ASC
)
/


/*==============================================================*/
/* Index: STUDY_IND02                                           */
/*==============================================================*/
create index STUDY_IND02 on STUDY (
   CONTACT_ID ASC
)
/


/*==============================================================*/
/* Index: STUDY_IND03                                           */
/*==============================================================*/
create index STUDY_IND03 on STUDY (
   EXTERNAL_DATABASE_RELEASE_ID ASC
)
/


/*==============================================================*/
/* Table: STUDYASSAY                                            */
/*==============================================================*/


create table STUDYASSAY  (
   STUDY_ASSAY_ID       NUMBER(8)                        not null,
   STUDY_ID             NUMBER(4)                        not null,
   ASSAY_ID             NUMBER(8)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_STUDYASSAY primary key (STUDY_ASSAY_ID)
)
/


/*==============================================================*/
/* Index: STUDYASSAY_IND01                                      */
/*==============================================================*/
create index STUDYASSAY_IND01 on STUDYASSAY (
   ASSAY_ID ASC
)
/


/*==============================================================*/
/* Index: STUDYASSAY_IND02                                      */
/*==============================================================*/
create index STUDYASSAY_IND02 on STUDYASSAY (
   STUDY_ID ASC
)
/


/*==============================================================*/
/* Table: STUDYASSAYPROT                                        */
/*==============================================================*/


create table STUDYASSAYPROT  (
   STUDY_ASSAY_ID       NUMBER(8)                        not null,
   PROTEOME_ASSAY_ID    NUMBER(8),
   STUDY_ID             NUMBER(4)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_STUDYASSAY_PROT primary key (STUDY_ASSAY_ID)
)
/


/*==============================================================*/
/* Index: STUDYASSAY_PROT_IND02                                 */
/*==============================================================*/
create index STUDYASSAY_PROT_IND02 on STUDYASSAYPROT (
   STUDY_ID ASC
)
/


/*==============================================================*/
/* Table: STUDYBIOMATERIAL                                      */
/*==============================================================*/


create table STUDYBIOMATERIAL  (
   STUDY_BIO_MATERIAL_ID NUMBER(10)                       not null,
   STUDY_ID             NUMBER(4)                        not null,
   BIO_MATERIAL_ID      NUMBER(8)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_STUDYBIOMATERIAL primary key (STUDY_BIO_MATERIAL_ID)
)
/


/*==============================================================*/
/* Index: STUDYBIOMATERIAL_IND01                                */
/*==============================================================*/
create index STUDYBIOMATERIAL_IND01 on STUDYBIOMATERIAL (
   STUDY_ID ASC
)
/


/*==============================================================*/
/* Index: STUDYBIOMATERIAL_IND02                                */
/*==============================================================*/
create index STUDYBIOMATERIAL_IND02 on STUDYBIOMATERIAL (
   BIO_MATERIAL_ID ASC
)
/


/*==============================================================*/
/* Table: STUDYDESIGN                                           */
/*==============================================================*/


create table STUDYDESIGN  (
   STUDY_DESIGN_ID      NUMBER(5)                        not null,
   STUDY_ID             NUMBER(4)                        not null,
   NAME                 VARCHAR2(100)                    not null,
   DESCRIPTION          VARCHAR2(4000),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_STUDYDESIGN primary key (STUDY_DESIGN_ID)
)
/


/*==============================================================*/
/* Index: STUDYDESIGN_AK01                                      */
/*==============================================================*/
create unique index STUDYDESIGN_AK01 on STUDYDESIGN (
   NAME ASC,
   STUDY_ID ASC
)
/


/*==============================================================*/
/* Index: STUDYDESIGN_IND01                                     */
/*==============================================================*/
create index STUDYDESIGN_IND01 on STUDYDESIGN (
   STUDY_ID ASC
)
/


/*==============================================================*/
/* Table: STUDYDESIGNASSAY                                      */
/*==============================================================*/


create table STUDYDESIGNASSAY  (
   STUDY_DESIGN_ASSAY_ID NUMBER(8)                        not null,
   STUDY_DESIGN_ID      NUMBER(5)                        not null,
   ASSAY_ID             NUMBER(8)                        not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_STUDYDESIGNASSAY primary key (STUDY_DESIGN_ASSAY_ID)
)
/


/*==============================================================*/
/* Index: STUDYDESIGNASSAY_IND01                                */
/*==============================================================*/
create index STUDYDESIGNASSAY_IND01 on STUDYDESIGNASSAY (
   ASSAY_ID ASC
)
/


/*==============================================================*/
/* Index: STUDYDESIGNASSAY_IND02                                */
/*==============================================================*/
create index STUDYDESIGNASSAY_IND02 on STUDYDESIGNASSAY (
   STUDY_DESIGN_ID ASC
)
/


/*==============================================================*/
/* Table: STUDYDESIGNASSAYPROT                                  */
/*==============================================================*/


create table STUDYDESIGNASSAYPROT  (
   STUDY_DESIGN_ASSAY_ID NUMBER(8)                        not null,
   STUDY_DESIGN_ID      NUMBER(5)                        not null,
   PROTEOME_ASSAY_ID    NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_STUDYDESIGNASSAYPROT primary key (STUDY_DESIGN_ASSAY_ID)
)
/


/*==============================================================*/
/* Index: STUDYDESIGNASSAYPROT_IND02                            */
/*==============================================================*/
create index STUDYDESIGNASSAYPROT_IND02 on STUDYDESIGNASSAYPROT (
   STUDY_DESIGN_ID ASC
)
/


/*==============================================================*/
/* Table: STUDYDESIGNDESCRIPTION                                */
/*==============================================================*/


create table STUDYDESIGNDESCRIPTION  (
   STUDY_DESIGN_DESCRIPTION_ID NUMBER(5)                        not null,
   STUDY_DESIGN_ID      NUMBER(5)                        not null,
   DESCRIPTION_TYPE     VARCHAR2(100)                    not null,
   DESCRIPTION          VARCHAR2(4000)                   not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_STUDYDESIGNDESCR primary key (STUDY_DESIGN_DESCRIPTION_ID)
)
/


/*==============================================================*/
/* Index: STUDYDESIGNDESCRIPTION_IND01                          */
/*==============================================================*/
create index STUDYDESIGNDESCRIPTION_IND01 on STUDYDESIGNDESCRIPTION (
   STUDY_DESIGN_ID ASC
)
/


/*==============================================================*/
/* Table: STUDYDESIGNTYPE                                       */
/*==============================================================*/


create table STUDYDESIGNTYPE  (
   STUDY_DESIGN_TYPE_ID NUMBER(6)                        not null,
   STUDY_DESIGN_ID      NUMBER(5)                        not null,
   ONTOLOGY_ENTRY_ID    NUMBER(10)                       not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_STUDYDESIGNTYPE primary key (STUDY_DESIGN_TYPE_ID)
)
/


/*==============================================================*/
/* Index: STUDYDESIGNTYPE_IND01                                 */
/*==============================================================*/
create index STUDYDESIGNTYPE_IND01 on STUDYDESIGNTYPE (
   ONTOLOGY_ENTRY_ID ASC
)
/


/*==============================================================*/
/* Index: STUDYDESIGNTYPE_IND02                                 */
/*==============================================================*/
create index STUDYDESIGNTYPE_IND02 on STUDYDESIGNTYPE (
   STUDY_DESIGN_ID ASC
)
/


/*==============================================================*/
/* Table: STUDYFACTOR                                           */
/*==============================================================*/


create table STUDYFACTOR  (
   STUDY_FACTOR_ID      NUMBER(5)                        not null,
   STUDY_DESIGN_ID      NUMBER(5)                        not null,
   STUDY_FACTOR_TYPE_ID NUMBER(10),
   NAME                 VARCHAR2(100)                    not null,
   DESCRIPTION          VARCHAR2(500),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_STUDYFACTOR primary key (STUDY_FACTOR_ID)
)
/


/*==============================================================*/
/* Index: STUDYFACTOR_AK01                                      */
/*==============================================================*/
create unique index STUDYFACTOR_AK01 on STUDYFACTOR (
   NAME ASC,
   STUDY_DESIGN_ID ASC
)
/


/*==============================================================*/
/* Index: STUDYFACTOR_IND01                                     */
/*==============================================================*/
create index STUDYFACTOR_IND01 on STUDYFACTOR (
   STUDY_FACTOR_TYPE_ID ASC
)
/


/*==============================================================*/
/* Table: STUDYFACTORVALUE                                      */
/*==============================================================*/


create table STUDYFACTORVALUE  (
   STUDY_FACTOR_VALUE_ID NUMBER(8)                        not null,
   STUDY_FACTOR_ID      NUMBER(5)                        not null,
   ASSAY_ID             NUMBER(8)                        not null,
   VALUE_ONTOLOGY_ENTRY_ID NUMBER(10),
   STRING_VALUE         VARCHAR2(100),
   MEASUREMENT_UNIT_OE_ID NUMBER(10),
   MEASUREMENT_TYPE     VARCHAR2(10),
   MEASUREMENT_KIND     VARCHAR2(20),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_STUDYFACTORVAL primary key (STUDY_FACTOR_VALUE_ID)
)
/


/*==============================================================*/
/* Index: STUDYFACTORVALUE_IND01                                */
/*==============================================================*/
create index STUDYFACTORVALUE_IND01 on STUDYFACTORVALUE (
   ASSAY_ID ASC
)
/


/*==============================================================*/
/* Index: STUDYFACTORVALUE_IND2                                 */
/*==============================================================*/
create index STUDYFACTORVALUE_IND2 on STUDYFACTORVALUE (
   STUDY_FACTOR_ID ASC
)
/


/*==============================================================*/
/* Index: STUDYFACTORVALUE_IND3                                 */
/*==============================================================*/
create index STUDYFACTORVALUE_IND3 on STUDYFACTORVALUE (
   VALUE_ONTOLOGY_ENTRY_ID ASC
)
/


/*==============================================================*/
/* Index: STUDYFACTORVALUE_IND4                                 */
/*==============================================================*/
create index STUDYFACTORVALUE_IND4 on STUDYFACTORVALUE (
   MEASUREMENT_UNIT_OE_ID ASC
)
/


/*==============================================================*/
/* Table: STUDYFACTORVALUEPROT                                  */
/*==============================================================*/


create table STUDYFACTORVALUEPROT  (
   STUDY_FACTOR_VALUE_ID NUMBER(8)                        not null,
   STUDY_FACTOR_ID      NUMBER(5)                        not null,
   PROTEOME_ASSAY_ID    NUMBER(8)                        not null,
   VALUE_ONTOLOGY_ENTRY_ID NUMBER(10),
   STRING_VALUE         VARCHAR2(100),
   MEASUREMENT_UNIT_OE_ID NUMBER(10),
   MEASUREMENT_TYPE     VARCHAR2(10),
   MEASUREMENT_KIND     VARCHAR2(20),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_STUDYFACVAL_PROT primary key (STUDY_FACTOR_VALUE_ID)
)
/


/*==============================================================*/
/* Table: TANDEMSEQUENCEDATA                                    */
/*==============================================================*/


create table TANDEMSEQUENCEDATA  (
   tandem_sequence_ID   NUMBER(8)                        not null,
   db_search_parameters_ID NUMBER(8),
   source_type          varchar(100)                     not null,
   sequence             varchar(100)                     not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_TANDEMSEQUENCEDATA primary key (tandem_sequence_ID)
)
/


/*==============================================================*/
/* Table: TOF                                                   */
/*==============================================================*/


create table TOF  (
   TOF_ID               NUMBER(8)                        not null,
   mz_analysis_ID       NUMBER(8),
   reflectron_state     varchar(4)                       not null
         constraint CKC_REFLECTRON_STATE_TOF check (reflectron_state in ('On','Off','None')),
   internal_length      float                            not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_TOF primary key (TOF_ID)
)
/


/*==============================================================*/
/* Table: TREATEDANALYTE                                        */
/*==============================================================*/


create table TREATEDANALYTE  (
   chemical_treatment_ID NUMBER(8),
   treated_analyte_ID   NUMBER(8)                        not null,
   BIO_MATERIAL_ID      NUMBER(8),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_TREATEDANALYTE primary key (treated_analyte_ID)
)
/


/*==============================================================*/
/* Table: TREATMENT                                             */
/*==============================================================*/


create table TREATMENT  (
   TREATMENT_ID         NUMBER(10)                       not null,
   ORDER_NUM            NUMBER(3)                        not null,
   BIO_MATERIAL_ID      NUMBER(8)                        not null,
   TREATMENT_TYPE_ID    NUMBER(10)                       not null,
   PROTOCOL_ID          NUMBER(10),
   NAME                 VARCHAR2(100),
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(12)                       not null,
   ROW_PROJECT_ID       NUMBER(12)                       not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_TREATMENT primary key (TREATMENT_ID)
)
/


/*==============================================================*/
/* Index: TREATMENT_IND01                                       */
/*==============================================================*/
create index TREATMENT_IND01 on TREATMENT (
   BIO_MATERIAL_ID ASC
)
/


/*==============================================================*/
/* Index: TREATMENT_IND02                                       */
/*==============================================================*/
create index TREATMENT_IND02 on TREATMENT (
   TREATMENT_TYPE_ID ASC
)
/


/*==============================================================*/
/* Index: TREATMENT_IND03                                       */
/*==============================================================*/
create index TREATMENT_IND03 on TREATMENT (
   PROTOCOL_ID ASC
)
/


/*==============================================================*/
/* Table: TREATMENTPARAM                                        */
/*==============================================================*/


create table TREATMENTPARAM  (
   TREATMENT_PARAM_ID   NUMBER(10)                       not null,
   TREATMENT_ID         NUMBER(10)                       not null,
   PROTOCOL_PARAM_ID    NUMBER(10)                       not null,
   VALUE                VARCHAR2(100)                    not null,
   MODIFICATION_DATE    DATE                             not null,
   USER_READ            NUMBER(1)                        not null,
   USER_WRITE           NUMBER(1)                        not null,
   GROUP_READ           NUMBER(1)                        not null,
   GROUP_WRITE          NUMBER(1)                        not null,
   OTHER_READ           NUMBER(1)                        not null,
   OTHER_WRITE          NUMBER(1)                        not null,
   ROW_USER_ID          NUMBER(12)                       not null,
   ROW_GROUP_ID         NUMBER(3)                        not null,
   ROW_PROJECT_ID       NUMBER(3)                        not null,
   ROW_ALG_INVOCATION_ID NUMBER(12)                       not null,
   constraint PK_TREATMENTPARAM primary key (TREATMENT_PARAM_ID)
)
/


/*==============================================================*/
/* Index: TREATMENTPARAM_IND01                                  */
/*==============================================================*/
create index TREATMENTPARAM_IND01 on TREATMENTPARAM (
   PROTOCOL_PARAM_ID ASC
)
/


/*==============================================================*/
/* Index: TREATMENTPARAM_IND02                                  */
/*==============================================================*/
create index TREATMENTPARAM_IND02 on TREATMENTPARAM (
   TREATMENT_ID ASC
)
/


/*==============================================================*/
/* View: AFFYMETRIXCEL                                          */
/*==============================================================*/
create or replace view AFFYMETRIXCEL(ELEMENT_RESULT_ID, ELEMENT_ID, COMPOSITE_ELEMENT_RESULT_ID, 
QUANTIFICATION_ID, SUBCLASS_VIEW, MEAN, STDV, NPIXELS, MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, 
GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  element_result_id,
  element_id,
  composite_element_result_id,
  quantification_id,
  subclass_view,
  foreground AS mean,
  float1 AS stdv,
  int3 AS npixels,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM ElementResultImp
WHERE subclass_view = 'AffymetrixCEL'
with check option
/


/*==============================================================*/
/* View: AFFYMETRIXMAS4                                         */
/*==============================================================*/
create or replace view AFFYMETRIXMAS4(COMPOSITE_ELEMENT_RESULT_ID, COMPOSITE_ELEMENT_ID, 
QUANTIFICATION_ID, SUBCLASS_VIEW, POSITIVE_PROBE_PAIRS, NEGATIVE_PROBE_PAIRS, NUM_PROBE_PAIRS_USED, 
PAIRS_IN_AVERAGE, LOG_AVERAGE_RATIO, AVERAGE_DIFFERENCE, ABSOLUTE_CALL, MODIFICATION_DATE, USER_READ, 
USER_WRITE, GROUP_READ, GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, 
ROW_ALG_INVOCATION_ID) as
SELECT
  composite_element_result_id,
  composite_element_id,
  quantification_id,
  subclass_view,
  tinyint1 AS positive_probe_pairs,
  tinyint2 AS negative_probe_pairs,
  tinyint3 AS num_probe_pairs_used,
  smallint1 AS pairs_in_average,
  float1 AS log_average_ratio,
  float2 AS average_difference,
  string1 AS absolute_call,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM CompositeElementResultImp
WHERE subclass_view = 'AffymetrixMAS4'
with check option
/


/*==============================================================*/
/* View: AFFYMETRIXMAS5                                         */
/*==============================================================*/
create or replace view AFFYMETRIXMAS5(COMPOSITE_ELEMENT_RESULT_ID, SUBCLASS_VIEW, 
COMPOSITE_ELEMENT_ID, 
QUANTIFICATION_ID, SIGNAL, DETECTION, DETECTION_P_VALUE, STAT_PAIRS, STAT_PAIRS_USED, MODIFICATION_DATE, 
USER_READ, USER_WRITE, GROUP_READ, GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, 
ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  composite_element_result_id,
  subclass_view,
  composite_element_id,
  quantification_id,
  float1 AS signal,
  char1 AS detection,
  float2 AS detection_p_value,
  smallint1 AS stat_pairs,
  smallint2 AS stat_pairs_used,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM CompositeElementResultImp
WHERE SUBCLASS_VIEW = 'AffymetrixMAS5'
with check option
/


/*==============================================================*/
/* View: ARRAYVISIONELEMENTRESULT                               */
/*==============================================================*/
create or replace view ARRAYVISIONELEMENTRESULT(ELEMENT_RESULT_ID, SUBCLASS_VIEW, ELEMENT_ID, 
COMPOSITE_ELEMENT_RESULT_ID, QUANTIFICATION_ID, FOREGROUND, BACKGROUND, SD, MAD, SIGNAL_TO_NOISE, 
PERCENT_REMOVED, PERCENT_REPLACED, PERCENT_AT_FLOOR, PERCENT_AT_CEILING, BKG_PERCENT_AT_FLOOR, 
BKG_PERCENT_AT_CEILING, X, Y, AREA, FLAG, MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, GROUP_WRITE, 
OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  element_result_id,
  subclass_view,
  element_id,
  composite_element_result_id,
  quantification_id,
  foreground,
  background,
  foreground_sd AS sd,
  float1 AS mad,
  float2 AS signal_to_noise,
  float3 AS percent_removed,
  float4 AS percent_replaced,
  float5 AS percent_at_floor,
  float6 AS percent_at_ceiling,
  float7 AS bkg_percent_at_floor,
  float8 AS bkg_percent_at_ceiling,
  tinystring1 AS x,
  tinystring2 AS y,
  tinystring3 AS area,
  tinyint1 AS flag,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM ElementResultImp
WHERE subclass_view = 'ArrayVisionElementResult'
with check option
/


/*==============================================================*/
/* View: BIOMATERIAL                                            */
/*==============================================================*/
create or replace view BIOMATERIAL(BIO_MATERIAL_ID, SUBCLASS_VIEW, BIO_MATERIAL_TYPE_ID, 
EXTERNAL_DATABASE_RELEASE_ID, SOURCE_ID, MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, GROUP_WRITE, 
OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  bio_material_id,
  subclass_view,
  bio_material_type_id,
  external_database_release_id,
  source_id,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM BioMaterialImp
WHERE subclass_view = 'BioMaterial'
with check option
/


/*==============================================================*/
/* View: BIOSAMPLE                                              */
/*==============================================================*/
create or replace view BIOSAMPLE(BIO_MATERIAL_ID, SUBCLASS_VIEW, BIO_MATERIAL_TYPE_ID, 
EXTERNAL_DATABASE_RELEASE_ID, SOURCE_ID, NAME, DESCRIPTION, MODIFICATION_DATE, USER_READ, USER_WRITE, 
GROUP_READ, GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, 
ROW_ALG_INVOCATION_ID) as
SELECT
  bio_material_id,
  subclass_view,
  bio_material_type_id,
  external_database_release_id,
  source_id,
  string1 AS name,
  string2 AS description,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM BioMaterialImp
WHERE subclass_view = 'BioSample'
with check option
/


/*==============================================================*/
/* View: BIOSOURCE                                              */
/*==============================================================*/
create or replace view BIOSOURCE(BIO_MATERIAL_ID, SUBCLASS_VIEW, TAXON_ID, BIO_MATERIAL_TYPE_ID, 
BIO_SOURCE_PROVIDER_ID, EXTERNAL_DATABASE_RELEASE_ID, SOURCE_ID, NAME, DESCRIPTION, MODIFICATION_DATE, 
USER_READ, USER_WRITE, GROUP_READ, GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, 
ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT BioMaterialImp.bio_material_id,
BioMaterialImp.subclass_view,
BioMaterialImp.taxon_id,
BioMaterialImp.bio_material_type_id,
BioMaterialImp.bio_source_provider_id,
BioMaterialImp.external_database_release_id,
BioMaterialImp.source_id,
BioMaterialImp.string1 AS name,
BioMaterialImp.string2 AS description,
BioMaterialImp.modification_date,
BioMaterialImp.user_read,
BioMaterialImp.user_write,
BioMaterialImp.group_read,
BioMaterialImp.group_write,
BioMaterialImp.other_read,
BioMaterialImp.other_write,
BioMaterialImp.row_user_id,
BioMaterialImp.row_group_id,
BioMaterialImp.row_project_id,
BioMaterialImp.row_alg_invocation_id
FROM BioMaterialImp
where subclass_view='BioSource'
with check option
/


/*==============================================================*/
/* View: COMPOSITEELEMENT                                       */
/*==============================================================*/
create or replace view COMPOSITEELEMENT(COMPOSITE_ELEMENT_ID, SUBCLASS_VIEW, PARENT_ID, ARRAY_ID, 
EXTERNAL_DATABASE_RELEASE_ID, SOURCE_ID, MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, GROUP_WRITE, 
OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  composite_element_id,
  subclass_view,
  parent_id,
  array_id,
  external_database_release_id,
  source_id,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM CompositeElementImp
WHERE subclass_view = 'CompositeElement'
with check option
/


/*==============================================================*/
/* View: COMPOSITEELEMENTRESULT                                 */
/*==============================================================*/
create or replace view COMPOSITEELEMENTRESULT(COMPOSITE_ELEMENT_RESULT_ID, SUBCLASS_VIEW, 
COMPOSITE_ELEMENT_ID, QUANTIFICATION_ID, MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, GROUP_WRITE, 
OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  composite_element_result_id,
  subclass_view,
  composite_element_id,
  quantification_id,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM CompositeElementResultImp
WHERE subclass_view = 'CompositeElementResult'
with check option
/


/*==============================================================*/
/* View: ELEMENT                                                */
/*==============================================================*/
create or replace view ELEMENT(ELEMENT_ID, SUBCLASS_VIEW, ELEMENT_TYPE_ID, COMPOSITE_ELEMENT_ID, 
ARRAY_ID, EXTERNAL_DATABASE_RELEASE_ID, SOURCE_ID, MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, 
GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  element_id,
  subclass_view,
  element_type_id,
  composite_element_id,
  array_id,
  external_database_release_id,
  source_id,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM ElementImp
WHERE subclass_view = 'Element'
with check option
/


/*==============================================================*/
/* View: ELEMENTRESULT                                          */
/*==============================================================*/
create or replace view ELEMENTRESULT(ELEMENT_RESULT_ID, SUBCLASS_VIEW, ELEMENT_ID, 
COMPOSITE_ELEMENT_RESULT_ID, QUANTIFICATION_ID, FOREGROUND, BACKGROUND, FOREGROUND_SD, BACKGROUND_SD, 
MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, 
ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  element_result_id,
  subclass_view,
  element_id,
  composite_element_result_id,
  quantification_id,
  foreground,
  background,
  foreground_sd,
  background_sd,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM ElementResultImp
WHERE subclass_view = 'ElementResult'
with check option
/


/*==============================================================*/
/* View: GEMTOOLSELEMENTRESULT                                  */
/*==============================================================*/
create or replace view GEMTOOLSELEMENTRESULT(ELEMENT_RESULT_ID, ELEMENT_ID, 
COMPOSITE_ELEMENT_RESULT_ID, QUANTIFICATION_ID, SUBCLASS_VIEW, SIGNAL, SIGNAL_TO_BACKGROUND, 
AREA_PERCENTAGE, VISUAL_FLAG, MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, GROUP_WRITE, OTHER_READ, 
OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  element_result_id,
  element_id,
  composite_element_result_id,
  quantification_id,
  subclass_view,
  float1 AS signal,
  float2 AS signal_to_background,
  float3 AS area_percentage,
  tinyint1 AS visual_flag,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM ElementResultImp WHERE subclass_view = 'GEMToolsElementResult'
with check option
/


/*==============================================================*/
/* View: GENEPIXELEMENTRESULT                                   */
/*==============================================================*/
create or replace view GENEPIXELEMENTRESULT(ELEMENT_RESULT_ID, ELEMENT_ID, 
COMPOSITE_ELEMENT_RESULT_ID, 
QUANTIFICATION_ID, SUBCLASS_VIEW, FOREGROUND_SD, BACKGROUND_SD, SPOT_DIAMETER, FOREGROUND_MEAN, 
FOREGROUND_MEDIAN, BACKGROUND_MEAN, BACKGROUND_MEDIAN, PERCENT_OVER_BG_PLUS_ONE_SD, 
PERCENT_OVER_BG_PLUS_TWO_SDS, PERCENT_FOREGROUND_SATURATED, MEAN_OF_RATIOS, MEDIAN_OF_RATIOS, RATIOS_SD, 
RGN_RATIO, RGN_R_SQUARED, NUM_FOREGROUND_PIXELS, NUM_BACKGROUND_PIXELS, FLAG, MODIFICATION_DATE, USER_READ, 
USER_WRITE, GROUP_READ, GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, 
ROW_ALG_INVOCATION_ID) as
SELECT element_result_id,
element_id,
composite_element_result_id,
quantification_id,
subclass_view,
foreground_sd,
background_sd,
float1 AS spot_diameter,
float2 AS foreground_mean,
float3 AS foreground_median,
float4 AS background_mean,
float5 AS background_median,
float6 AS percent_over_bg_plus_one_sd,
float7 AS percent_over_bg_plus_two_sds,
float8 AS percent_foreground_saturated,
float9 AS mean_of_ratios,
float10 AS median_of_ratios,
float11 AS ratios_sd,
float12 as rgn_ratio,
float13 as rgn_r_squared,
smallint1 AS num_foreground_pixels,
smallint2 AS num_background_pixels,
tinyint1 AS flag,
modification_date,
user_read,
user_write,
group_read,
group_write,
other_read,
other_write,
row_user_id,
row_group_id,
row_project_id,
row_alg_invocation_id
FROM ElementResultImp
WHERE subclass_view = 'GenePixElementResult'
with check option
/


/*==============================================================*/
/* View: LABELEDEXTRACT                                         */
/*==============================================================*/
create or replace view LABELEDEXTRACT(BIO_MATERIAL_ID, SUBCLASS_VIEW, BIO_MATERIAL_TYPE_ID, 
LABEL_METHOD_ID, EXTERNAL_DATABASE_RELEASE_ID, SOURCE_ID, NAME, DESCRIPTION, MODIFICATION_DATE, USER_READ, 
USER_WRITE, GROUP_READ, GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, 
ROW_ALG_INVOCATION_ID) as
SELECT
  bio_material_id,
  subclass_view,
  bio_material_type_id,
  label_method_id,
  external_database_release_id,
  source_id,
  string1 AS name,
  string2 AS description,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM BioMaterialImp
WHERE LABEL_METHOD_ID is not null
AND SUBCLASS_VIEW = 'LabeledExtract'
with check option
/


/*==============================================================*/
/* View: MOIDRESULT                                             */
/*==============================================================*/
create or replace view MOIDRESULT(COMPOSITE_ELEMENT_RESULT_ID, COMPOSITE_ELEMENT_ID, 
QUANTIFICATION_ID, 
SUBCLASS_VIEW, EXPRESSION, LOWER_BOUND, UPPER_BOUND, LOG_P, MODIFICATION_DATE, USER_READ, USER_WRITE, 
GROUP_READ, GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, 
ROW_ALG_INVOCATION_ID) as
SELECT
  composite_element_result_id,
  composite_element_id,
  quantification_id,
  subclass_view,
  float1 AS expression,
  float2 AS lower_bound,
  float3 AS upper_bound,
  float4 AS log_p,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM CompositeElementResultImp
WHERE subclass_view = 'MOIDResult'
with check option
/

drop view OTHERSPOTMEASURES
/


/*==============================================================*/
/* View: OTHERSPOTMEASURES                                      */
/*==============================================================*/
create or replace view OTHERSPOTMEASURES as
select SPOTMEASURESIMP.SPOT_MEASURES_ID, SPOTMEASURESIMP.SUBCLASS_VIEW, 
SPOTMEASURESIMP.FLOAT1, SPOTMEASURESIMP.FLOAT2, SPOTMEASURESIMP.FLOAT3, 
SPOTMEASURESIMP.FLOAT4, SPOTMEASURESIMP.FLOAT5, SPOTMEASURESIMP.FLOAT6, 
SPOTMEASURESIMP.FLOAT7, SPOTMEASURESIMP.FLOAT8, SPOTMEASURESIMP.FLOAT9, 
SPOTMEASURESIMP.FLOAT10, SPOTMEASURESIMP.FLOAT11, SPOTMEASURESIMP.FLOAT12, 
SPOTMEASURESIMP.FLOAT13, SPOTMEASURESIMP.FLOAT14, SPOTMEASURESIMP.INT1, 
SPOTMEASURESIMP.INT2, SPOTMEASURESIMP.INT3, SPOTMEASURESIMP.INT4, 
SPOTMEASURESIMP.INT5, 
SPOTMEASURESIMP.INT6, SPOTMEASURESIMP.INT7, SPOTMEASURESIMP.INT8, 
SPOTMEASURESIMP.INT9, 
SPOTMEASURESIMP.INT10, SPOTMEASURESIMP.INT11, SPOTMEASURESIMP.INT12, 
SPOTMEASURESIMP.INT13, SPOTMEASURESIMP.INT14, SPOTMEASURESIMP.INT15, 
SPOTMEASURESIMP.TINYINT1, SPOTMEASURESIMP.TINYINT2, SPOTMEASURESIMP.TINYINT3
, SPOTMEASURESIMP.SMALLINT1, SPOTMEASURESIMP.SMALLINT2, SPOTMEASURESIMP.SMALLINT3, 
SPOTMEASURESIMP.CHAR1, SPOTMEASURESIMP.CHAR2, SPOTMEASURESIMP.CHAR3, 
SPOTMEASURESIMP.CHAR4, SPOTMEASURESIMP.TINYSTRING1, SPOTMEASURESIMP.TINYSTRING2, 
SPOTMEASURESIMP.TINYSTRING3, SPOTMEASURESIMP.SMALLSTRING1, SPOTMEASURESIMP.SMALLSTRING2, 
SPOTMEASURESIMP.STRING1, SPOTMEASURESIMP.STRING2, SPOTMEASURESIMP.MODIFICATION_DATE, 
SPOTMEASURESIMP.USER_READ, SPOTMEASURESIMP.USER_WRITE, SPOTMEASURESIMP.GROUP_READ, 
SPOTMEASURESIMP.GROUP_WRITE, SPOTMEASURESIMP.OTHER_READ, SPOTMEASURESIMP.OTHER_WRITE, 
SPOTMEASURESIMP.ROW_USER_ID, SPOTMEASURESIMP.ROW_GROUP_ID, SPOTMEASURESIMP.ROW_PROJECT_ID, 
SPOTMEASURESIMP.ROW_ALG_INVOCATION_ID
from SPOTMEASURESIMP
/

/*==============================================================*/
/* View: SAGETAG                                                */
/*==============================================================*/
create or replace view SAGETAG(COMPOSITE_ELEMENT_ID, SUBCLASS_VIEW, PARENT_ID, ARRAY_ID, TAG, 
MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, 
ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  composite_element_id,
  subclass_view,
  parent_id,
  array_id,
  tinystring1 AS tag,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM CompositeElementImp
WHERE subclass_view = 'SAGETag'
with check option
/


/*==============================================================*/
/* View: SAGETAGMAPPING                                         */
/*==============================================================*/
create or replace view SAGETAGMAPPING(ELEMENT_ID, SUBCLASS_VIEW, ARRAY_ID, COMPOSITE_ELEMENT_ID, 
EXTERNAL_DATABASE_RELEASE_ID, SOURCE_ID, MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, GROUP_WRITE, 
OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  element_id,
  subclass_view,
  array_id,
  composite_element_id,
  external_database_release_id,
  source_id,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM ElementImp
WHERE subclass_view = 'SAGETagMapping'
with check option
/


/*==============================================================*/
/* View: SAGETAGRESULT                                          */
/*==============================================================*/
create or replace view SAGETAGRESULT(COMPOSITE_ELEMENT_RESULT_ID, COMPOSITE_ELEMENT_ID, 
QUANTIFICATION_ID, SUBCLASS_VIEW, TAG_COUNT, MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, 
GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  composite_element_result_id,
  composite_element_id,
  quantification_id,
  subclass_view,
  int1 AS tag_count,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM CompositeElementResultImp
WHERE subclass_view = 'SAGETagResult'
with check option
/


/*==============================================================*/
/* View: SCANALYZEELEMENTRESULT                                 */
/*==============================================================*/
create or replace view SCANALYZEELEMENTRESULT(ELEMENT_RESULT_ID, ELEMENT_ID, 
COMPOSITE_ELEMENT_RESULT_ID, QUANTIFICATION_ID, SUBCLASS_VIEW, I, B, BA, SPIX, BGPIX, TOP, LEFT, BOT, RIGHT, 
FLAG, MRAT, REGR, CORR, LFRAT, GTB1, GTB2, EDGEA, KSD, KSP, MODIFICATION_DATE, USER_READ, USER_WRITE, 
GROUP_READ, GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, 
ROW_ALG_INVOCATION_ID) as
SELECT
  element_result_id,
  element_id,
  composite_element_result_id,
  quantification_id,
  subclass_view,
  foreground AS i,
  background AS b,
  float1 AS ba,
  int1 AS spix,
  int2 AS bgpix,
  int3 AS top,
  int4 AS left,
  int5 AS bot,
  int6 AS right,
  tinyint1 AS flag,
  float2 AS mrat,
  float3 AS regr,
  float4 AS corr,
  float5 AS lfrat,
  float6 AS gtb1,
  float7 AS gtb2,
  float8 AS edgea,
  float9 AS ksd,
  float10 AS ksp,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM ElementResultImp
WHERE subclass_view = 'ScanAlyzeElementResult'
with check option
/


/*==============================================================*/
/* View: SHORTOLIGO                                             */
/*==============================================================*/
create or replace view SHORTOLIGO(ELEMENT_ID, SUBCLASS_VIEW, ARRAY_ID, COMPOSITE_ELEMENT_ID, NAME, 
X_POSITION, Y_POSITION, SEQUENCE, DESCRIPTION, MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, 
GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  element_id,
  subclass_view,
  array_id,
  composite_element_id,
  smallstring2 AS name,
  tinystring1 AS x_position,
  tinystring2 AS y_position,
  smallstring1 AS sequence,
  string1 AS description,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM ElementImp
WHERE subclass_view = 'ShortOligo'
with check option
/


/*==============================================================*/
/* View: SHORTOLIGOFAMILY                                       */
/*==============================================================*/
create or replace view SHORTOLIGOFAMILY(COMPOSITE_ELEMENT_ID, SUBCLASS_VIEW, PARENT_ID, ARRAY_ID, 
EXTERNAL_DATABASE_RELEASE_ID, SOURCE_ID, NAME, DESCRIPTION, MODIFICATION_DATE, USER_READ, USER_WRITE, 
GROUP_READ, GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, 
ROW_ALG_INVOCATION_ID) as
SELECT
  composite_element_id,
  subclass_view,
  parent_id,
  array_id,
  external_database_release_id,
  source_id,
  smallstring1 AS name,
  string1 AS description,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM CompositeElementImp
WHERE subclass_view = 'ShortOligoFamily'
with check option
/


/*==============================================================*/
/* View: SPOT                                                   */
/*==============================================================*/
create or replace view SPOT(ELEMENT_ID, SUBCLASS_VIEW, ARRAY_ID, ELEMENT_TYPE_ID, 
COMPOSITE_ELEMENT_ID, 
EXTERNAL_DATABASE_RELEASE_ID, SOURCE_ID, ARRAY_ROW, ARRAY_COLUMN, GRID_ROW, GRID_COLUMN, SUB_ROW, 
SUB_COLUMN, SEQUENCE_VERIFIED, NAME, DESCRIPTION, MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, 
GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  element_id,
  subclass_view,
  array_id,
  element_type_id,
  composite_element_id,
  external_database_release_id,
  source_id,
  char1 AS array_row,
  char2 AS array_column,
  char3 AS grid_row,
  char4 AS grid_column,
  char5 AS sub_row,
  char6 AS sub_column,
  tinyint1 AS sequence_verified,
  tinystring1 AS name,
  string1 AS description,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM ElementImp
WHERE subclass_view = 'Spot'
with check option
/


/*==============================================================*/
/* View: SPOTELEMENTRESULT                                      */
/*==============================================================*/
create or replace view SPOTELEMENTRESULT(ELEMENT_RESULT_ID, ELEMENT_ID, COMPOSITE_ELEMENT_RESULT_ID, 
QUANTIFICATION_ID, SUBCLASS_VIEW, MEDIAN, MORPH, IQR, MEAN, BG_MEDIAN, BG_MEAN, BG_SD, VALLEY, MORPH_ERODE, 
MORPH_CLOSE_OPEN, AREA, PERIMETER, CIRCULARITY, BADSPOT, VISUAL_FLAG, MODIFICATION_DATE, USER_READ, 
USER_WRITE, GROUP_READ, GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, ROW_GROUP_ID, ROW_PROJECT_ID, 
ROW_ALG_INVOCATION_ID) as
SELECT
  element_result_id,
  element_id,
  composite_element_result_id,
  quantification_id,
  subclass_view,
  foreground AS median,
  background AS morph,
  foreground_sd AS iqr,
  float1 AS mean,
  float2 AS bg_median,
  float3 AS bg_mean,
  float4 AS bg_sd,
  float5 AS valley,
  float6 AS morph_erode,
  float7 AS morph_close_open,
  int1 AS area,
  int2 AS perimeter,
  float8 AS circularity,
  tinyint1 AS badspot,
  tinyint2 AS visual_flag,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM ElementResultImp WHERE subclass_view = 'SpotElementResult'
with check option
/


/*==============================================================*/
/* View: SPOTFAMILY                                             */
/*==============================================================*/
create or replace view SPOTFAMILY(COMPOSITE_ELEMENT_ID, SUBCLASS_VIEW, PARENT_ID, ARRAY_ID, 
EXTERNAL_DATABASE_RELEASE_ID, SOURCE_ID, PLATE_NAME, WELL_LOCATION, PCR_FAILURE_FLAG, NAME, DESCRIPTION, 
MODIFICATION_DATE, USER_READ, USER_WRITE, GROUP_READ, GROUP_WRITE, OTHER_READ, OTHER_WRITE, ROW_USER_ID, 
ROW_GROUP_ID, ROW_PROJECT_ID, ROW_ALG_INVOCATION_ID) as
SELECT
  composite_element_id,
  subclass_view,
  parent_id,
  array_id,
  external_database_release_id,
  source_id,
  smallstring1 AS plate_name,
  smallstring2 AS well_location,
  tinyint1 AS pcr_failure_flag,
  string2 AS name,
  string1 AS description,
  modification_date,
  user_read,
  user_write,
  group_read,
  group_write,
  other_read,
  other_write,
  row_user_id,
  row_group_id,
  row_project_id,
  row_alg_invocation_id
FROM CompositeElementImp
where subclass_view = 'SpotFamily'
with check option
/


alter table ACQUISITION 
   add constraint FK_ACQ_ASSAY foreign key (ASSAY_ID) 
      references ASSAY (ASSAY_ID) not deferrable
/


alter table ACQUISITION 
   add constraint FK_ACQ_CHANNEL foreign key (CHANNEL_ID) 
      references CHANNEL (CHANNEL_ID) not deferrable
/


alter table ACQUISITION 
   add constraint FK_ACQ_PRTCL foreign key (PROTOCOL_ID) 
      references PROTOCOL (PROTOCOL_ID) not deferrable
/


alter table ACQUISITIONPARAM 
   add constraint FK_ACQPARAM_ACQ foreign key (ACQUISITION_ID) 
      references ACQUISITION (ACQUISITION_ID) not deferrable
/


alter table ACQUISITIONPARAM 
   add constraint FK_ACQPARAM_PRTPRM foreign key (PROTOCOL_PARAM_ID) 
      references PROTOCOLPARAM (PROTOCOL_PARAM_ID) not deferrable
/


alter table ANALYSISIMPLEMENTATION 
   add constraint FK_ANLIMP_ANL foreign key (ANALYSIS_ID) 
      references ANALYSIS (ANALYSIS_ID) not deferrable
/


alter table ANALYSISIMPLEMENTATIONPARAM 
   add constraint FK_ANLIMPPARAM_ANLIMP foreign key (ANALYSIS_IMPLEMENTATION_ID) 
      references ANALYSISIMPLEMENTATION (ANALYSIS_IMPLEMENTATION_ID) not deferrable
/


alter table ANALYSISINPUT 
   add constraint FK_ANLINPUT_ANALYSISINV foreign key (ANALYSIS_INVOCATION_ID) 
      references ANALYSISINVOCATION (ANALYSIS_INVOCATION_ID) not deferrable
/


alter table ANALYSISINVOCATION 
   add constraint FK_ANLINV_ANLIMP foreign key (ANALYSIS_IMPLEMENTATION_ID) 
      references ANALYSISIMPLEMENTATION (ANALYSIS_IMPLEMENTATION_ID) not deferrable
/


alter table ANALYSISINVOCATIONPARAM 
   add constraint FK_ANLPARAM_ANLINV foreign key (ANALYSIS_INVOCATION_ID) 
      references ANALYSISINVOCATION (ANALYSIS_INVOCATION_ID) not deferrable
/


alter table ANALYSISOUTPUT 
   add constraint FK_ANALYSISOUTPUT4 foreign key (ANALYSIS_INVOCATION_ID) 
      references ANALYSISINVOCATION (ANALYSIS_INVOCATION_ID) not deferrable
/


alter table ANALYTEMEASUREMENT 
   add constraint FK_ANALYTE__REFERENCE_BIOASSAY foreign key (BIOASSAY_TREATMENT_ID) 
      references BIOASSAYTREATMENT (BIOASSAY_TREATMENT_ID)
/


alter table ANALYTEMEASUREMENT 
   add constraint FK_ANALYTE__REFERENCE_BIOMATER foreign key (BIO_MATERIAL_ID) 
      references BIOMATERIALIMP (BIO_MATERIAL_ID)
/


alter table ARRAY 
   add constraint FK_ARRAY_ONTO01 foreign key (PLATFORM_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table ARRAY 
   add constraint FK_ARRAY_ONTO02 foreign key (SUBSTRATE_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table ARRAY 
   add constraint FK_ARRAY_PROTOCOL foreign key (PROTOCOL_ID) 
      references PROTOCOL (PROTOCOL_ID) not deferrable
/


alter table ARRAYANNOTATION 
   add constraint FK_ARRAYANN_ARRAY foreign key (ARRAY_ID) 
      references ARRAY (ARRAY_ID) not deferrable
/


alter table ASSAY 
   add constraint FK_ASSAY_ARRAY foreign key (ARRAY_ID) 
      references ARRAY (ARRAY_ID) not deferrable
/


alter table ASSAY 
   add constraint FK_ASSAY_PRTCL foreign key (PROTOCOL_ID) 
      references PROTOCOL (PROTOCOL_ID) not deferrable
/


alter table ASSAYBIOMATERIAL 
   add constraint FK_ASSAYBIOMATERIAL15 foreign key (BIO_MATERIAL_ID) 
      references BIOMATERIALIMP (BIO_MATERIAL_ID) not deferrable
/


alter table ASSAYBIOMATERIAL 
   add constraint FK_ASSAYBIOSOURCE13 foreign key (ASSAY_ID) 
      references ASSAY (ASSAY_ID) not deferrable
/


alter table ASSAYDATAPOINT 
   add constraint FK_ASSAYDAT_REFERENCE_LCCOLUMN foreign key (id) 
      references LCCOLUMN (LCColumn_ID)
/


alter table ASSAYGROUP 
   add constraint FK_ASSAYGRO_REFERENCE_ASSAY foreign key (ASSAY_ID) 
      references ASSAY (ASSAY_ID)
/


alter table ASSAYGROUP 
   add constraint FK_ASSAYGRO_REFERENCE_STUDY foreign key (STUDY_ID) 
      references STUDY (STUDY_ID)
/


alter table ASSAYGROUP 
   add constraint FK_ASSAYGRO_REFERENCE_STUDYDES foreign key (STUDY_DESIGN_ID) 
      references STUDYDESIGN (STUDY_DESIGN_ID)
/


alter table ASSAYGROUP 
   add constraint FK_ASSAYGRO_REFERENCE_STUDYFAC foreign key (STUDY_FACTOR_VALUE_ID) 
      references STUDYFACTORVALUE (STUDY_FACTOR_VALUE_ID)
/


alter table ASSAYLABELEDEXTRACT 
   add constraint FK_ASSAYLAB_ASSAY foreign key (ASSAY_ID) 
      references ASSAY (ASSAY_ID) not deferrable
/


alter table ASSAYLABELEDEXTRACT 
   add constraint FK_ASSAYLAB_CHANNEL foreign key (CHANNEL_ID) 
      references CHANNEL (CHANNEL_ID) not deferrable
/


alter table ASSAYLABELEDEXTRACT 
   add constraint FK_ASSAYLAB_LEX foreign key (LABELED_EXTRACT_ID) 
      references BIOMATERIALIMP (BIO_MATERIAL_ID) not deferrable
/


alter table ASSAYPARAM 
   add constraint FK_ASSAYPARAM_ASSAY foreign key (ASSAY_ID) 
      references ASSAY (ASSAY_ID) not deferrable
/


alter table ASSAYPARAM 
   add constraint FK_ASSAYPARAM_PRTOPRM foreign key (PROTOCOL_PARAM_ID) 
      references PROTOCOLPARAM (PROTOCOL_PARAM_ID) not deferrable
/


alter table ASSAYPARAMPROT 
   add constraint FK_ASSAYPAR_REFERENCE_PROTEOME foreign key (PROTEOME_ASSAY_ID) 
      references PROTEOMEASSAY (PROTEOME_ASSAY_ID)
/


alter table ASSAYPARAMPROT 
   add constraint FK_ASSAYPAR_REFERENCE_PROTOCOL foreign key (PROTOCOL_PARAM_ID) 
      references PROTOCOLPARAM (PROTOCOL_PARAM_ID)
/


alter table BAND 
   add constraint FK_BAND_REFERENCE_PHYSICAL foreign key (physicalGelSpot_ID) 
      references PHYSICALGELITEM (physicalGelItem_ID)
/


alter table BIOASSAYTREATMENT 
   add constraint FK_BIOASSAY_REFERENCE_ONTOLOGY foreign key (TREATMENT_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID)
/


alter table BIOASSAYTREATMENT 
   add constraint FK_BIOASSAY_REFERENCE_PROTEOME foreign key (PROTEOME_ASSAY_ID) 
      references PROTEOMEASSAY (PROTEOME_ASSAY_ID)
/


alter table BIOASSAYTREATMENT 
   add constraint FK_BIOASSAY_REFERENCE_PROTOCOL foreign key (PROTOCOL_ID) 
      references PROTOCOL (PROTOCOL_ID)
/


alter table BIOMATERIALCHARACTERISTIC 
   add constraint FK_BMCHARAC_BIOMAT foreign key (BIO_MATERIAL_ID) 
      references BIOMATERIALIMP (BIO_MATERIAL_ID) not deferrable
/


alter table BIOMATERIALCHARACTERISTIC 
   add constraint FK_BMCHARAC_ONTOLOGY foreign key (ONTOLOGY_ENTRY_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table BIOMATERIALIMP 
   add constraint FK_BIOMATERIALIMP15 foreign key (LABEL_METHOD_ID) 
      references LABELMETHOD (LABEL_METHOD_ID) not deferrable
/


alter table BIOMATERIALIMP 
   add constraint FK_BIOMATTYPE_OE foreign key (BIO_MATERIAL_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table BIOMATERIALMEASUREMENT 
   add constraint FK_BMM_BIOMATERIAL foreign key (BIO_MATERIAL_ID) 
      references BIOMATERIALIMP (BIO_MATERIAL_ID) not deferrable
/


alter table BIOMATERIALMEASUREMENT 
   add constraint FK_BMM_ONTO foreign key (UNIT_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table BIOMATERIALMEASUREMENT 
   add constraint FK_BMM_TREATMENT foreign key (TREATMENT_ID) 
      references TREATMENT (TREATMENT_ID) not deferrable
/


alter table BOUNDARYPOINT 
   add constraint FK_BOUNDARY_REFERENCE_IDENTIFI foreign key (spot_id) 
      references IDENTIFIEDSPOT (identified_spot_ID) 
      on delete cascade
/


alter table CHEMICALTREATMENT 
   add constraint FK_CHEMICAL_REFERENCE_BIOASSAY foreign key (BIOASSAY_TREATMENT_ID) 
      references BIOASSAYTREATMENT (BIOASSAY_TREATMENT_ID)
/


alter table CHEMICALTREATMENT 
   add constraint FK_CHEMICAL_REFERENCE_ONTOLOGY foreign key (treatment_type) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID)
/


alter table COLLISIONCELL 
   add constraint FK_COLLISIO_REFERENCE_MZANALYS foreign key (mz_analysis_ID) 
      references MZANALYSIS (mz_analysis_ID)
/


alter table COMPOSITEELEMENTANNOTATION 
   add constraint FK_CEANNOT_CE foreign key (COMPOSITE_ELEMENT_ID) 
      references COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID) not deferrable
/


alter table COMPOSITEELEMENTGUS 
   add constraint FK_CEG_CE foreign key (COMPOSITE_ELEMENT_ID) 
      references COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID) not deferrable
/


alter table COMPOSITEELEMENTIMP 
   add constraint FK_CE_ARRAY foreign key (ARRAY_ID) 
      references ARRAY (ARRAY_ID) not deferrable
/


alter table COMPOSITEELEMENTIMP 
   add constraint FK_CE_CE foreign key (PARENT_ID) 
      references COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID) not deferrable
/


alter table COMPOSITEELEMENTRESULTIMP 
   add constraint FK_CERESULT_CELEMENT foreign key (COMPOSITE_ELEMENT_ID) 
      references COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID) not deferrable
/


alter table COMPOSITEELEMENTRESULTIMP 
   add constraint FK_CERESULT_QUANT foreign key (QUANTIFICATION_ID) 
      references QUANTIFICATION (QUANTIFICATION_ID) not deferrable
/


alter table CONTROL 
   add constraint FK_CONTROL_ASSAY foreign key (ASSAY_ID) 
      references ASSAY (ASSAY_ID) not deferrable
/


alter table CONTROL 
   add constraint FK_CONTROL_ONTO foreign key (CONTROL_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table DATABASEENTRY 
   add constraint FK_DATABASE_NAME_FK_DATABA_ONT foreign key (database_name) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID)
/


alter table DATABASEENTRY 
   add constraint FK_DATABASE_URI_FK_DATABA_ONTO foreign key (database_uri) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID)
/


alter table DATABASEENTRY 
   add constraint FK_DATABASE_VERS_FK_DATABA_ONT foreign key (database_version) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID)
/


alter table DBSEARCH 
   add constraint FK_DBSEARCH_REFERENCE_DBSEARCH foreign key (db_search_parameters_ID) 
      references DBSEARCHPARAMETERS (db_search_parameters_ID)
/


alter table DBSEARCH 
   add constraint FK_DBSEARCH_REFERENCE_PEAKLIST foreign key (peak_list_ID) 
      references PEAKLIST (peak_list_ID)
/


alter table DBSEARCHPARAMETERS 
   add constraint FK_DBSEARCH_REFERENCE_PROTOCOL foreign key (PROTOCOL_ID) 
      references PROTOCOL (PROTOCOL_ID)
/


alter table DIGESINGLESPOT 
   add constraint FK_DIGESING_REFERENCE_IDENTIFI foreign key (identified_spot_ID) 
      references IDENTIFIEDSPOT (identified_spot_ID)
/


alter table DIGESINGLESPOT 
   add constraint FK_DIGESING_REFERENCE_IMAGE_AN foreign key (GEL_IMAGE_ANALYSIS_ID) 
      references GELIMAGEANALYSIS (GEL_IMAGE_ANALYSIS_ID)
/


alter table DIGESINGLESPOT 
   add constraint FK_DIGESING_REFERENCE_SPOT_MEA foreign key (SPOT_MEASURES_ID) 
      references SPOTMEASURESIMP (SPOT_MEASURES_ID)
/


alter table ELECTROSPRAY 
   add constraint FK_ELECTROS_REFERENCE_IONSOURC foreign key (ion_source_ID) 
      references IONSOURCE (ion_source_ID)
/


alter table ELEMENTANNOTATION 
   add constraint FK_ELEANNOT_ELEMENTIMP foreign key (ELEMENT_ID) 
      references ELEMENTIMP (ELEMENT_ID) not deferrable
/


alter table ELEMENTIMP 
   add constraint FK_ELEMENT_ARRAY foreign key (ARRAY_ID) 
      references ARRAY (ARRAY_ID) not deferrable
/


alter table ELEMENTIMP 
   add constraint FK_ELEMENT_COMPELEFAM foreign key (COMPOSITE_ELEMENT_ID) 
      references COMPOSITEELEMENTIMP (COMPOSITE_ELEMENT_ID) not deferrable
/


alter table ELEMENTIMP 
   add constraint FK_ELEMENT_ONTO foreign key (ELEMENT_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table ELEMENTRESULTIMP 
   add constraint FK_ELEMENTRESULT_ELEMENTIMP foreign key (ELEMENT_ID) 
      references ELEMENTIMP (ELEMENT_ID) not deferrable
/


alter table ELEMENTRESULTIMP 
   add constraint FK_ELEMENTRESU_QUANT foreign key (QUANTIFICATION_ID) 
      references QUANTIFICATION (QUANTIFICATION_ID) not deferrable
/


alter table ELEMENTRESULTIMP 
   add constraint FK_ELEMENTRES_SFR foreign key (COMPOSITE_ELEMENT_RESULT_ID) 
      references COMPOSITEELEMENTRESULTIMP (COMPOSITE_ELEMENT_RESULT_ID) not deferrable
/


alter table FRACTION 
   add constraint FK_FRACTION_REFERENCE_BIOMATER foreign key (BIO_MATERIAL_ID) 
      references BIOMATERIALIMP (BIO_MATERIAL_ID)
/


alter table FRACTION 
   add constraint FK_FRACTION_REFERENCE_LCCOLUMN foreign key (LCColumn_ID) 
      references LCCOLUMN (LCColumn_ID)
/


alter table GEL1D 
   add constraint FK_GEL1D_REFERENCE_BIOASSAY foreign key (BIOASSAY_TREATMENT_ID) 
      references BIOASSAYTREATMENT (BIOASSAY_TREATMENT_ID)
/


alter table GEL2D 
   add constraint FK_GEL2D_REFERENCE_BIOASSAY foreign key (BIOASSAY_TREATMENT_ID) 
      references BIOASSAYTREATMENT (BIOASSAY_TREATMENT_ID)
/


alter table GRADIENTSTEP 
   add constraint FK_GRADIENT_REFERENCE_LCCOLUMN foreign key (GradientStep_ID) 
      references LCCOLUMN (LCColumn_ID)
/


alter table HEXAPOLE 
   add constraint FK_HEXAPOLE_REFERENCE_MZANALYS foreign key (mz_analysis_ID) 
      references MZANALYSIS (mz_analysis_ID)
/


alter table IDENTIFIEDSPOT 
   add constraint FK_IDENTIFI_REFERENCE_IMAGE_AN foreign key (GEL_IMAGE_ANALYSIS_ID) 
      references GELIMAGEANALYSIS (GEL_IMAGE_ANALYSIS_ID)
/


alter table IDENTIFIEDSPOT 
   add constraint FK_IDENTIFI_REFERENCE_PHYSICAL foreign key (physicalGelItem_ID) 
      references PHYSICALGELITEM (physicalGelItem_ID)
/


alter table IDENTIFIEDSPOT 
   add constraint FK_IDENTIFI_REFERENCE_SPOT_MEA foreign key (SPOT_MEASURES_ID) 
      references SPOTMEASURESIMP (SPOT_MEASURES_ID)
/


alter table IMAGEACQUISITION 
   add constraint FK_IMAGE_AC_REFERENCE_CHANNEL foreign key (CHANNEL_ID) 
      references CHANNEL (CHANNEL_ID)
/


alter table IMAGEACQUISITION 
   add constraint FK_IMAGE_AC_REFERENCE_PROTEOME foreign key (PROTEOME_ASSAY_ID) 
      references PROTEOMEASSAY (PROTEOME_ASSAY_ID)
/


alter table GELIMAGEANALYSIS 
   add constraint FK_IMAGE_AN_REFERENCE_IMAGE_AC foreign key (ACQUISITION_ID) 
      references IMAGEACQUISITION (IMAGE_ACQUISITION_ID)
/


alter table GELIMAGEANALYSIS 
   add constraint FK_IMAGE_AN_REFERENCE_PROTOCOL foreign key (PROTOCOL_ID) 
      references PROTOCOL (PROTOCOL_ID)
/


alter table INTEGRITYSTATINPUT 
   add constraint INTEGRITYSTATINPUT_FK01 foreign key (INTEGRITY_STATISTIC_ID) 
      references INTEGRITYSTATISTIC (INTEGRITY_STATISTIC_ID) not deferrable
/


alter table IONTRAP 
   add constraint FK_IONTRAP_REFERENCE_MZANALYS foreign key (mz_analysis_ID) 
      references MZANALYSIS (mz_analysis_ID)
/


alter table LABELMETHOD 
   add constraint FK_LABELEDMETHOD_PROTO foreign key (PROTOCOL_ID) 
      references PROTOCOL (PROTOCOL_ID) not deferrable
/


alter table LABELMETHOD 
   add constraint FK_LABELMETHOD_CHANNEL foreign key (CHANNEL_ID) 
      references CHANNEL (CHANNEL_ID) not deferrable
/


alter table LCCOLUMN 
   add constraint FK_LCCOLUMN_REFERENCE_BIOASSAY foreign key (BIOASSAY_TREATMENT_ID) 
      references BIOASSAYTREATMENT (BIOASSAY_TREATMENT_ID)
/


alter table LISTPROCESSING 
   add constraint FK_LISTPROC_REFERENCE_PEAKLIST foreign key (peak_list_ID) 
      references PEAKLIST (peak_list_ID)
/


alter table MAGEDOCUMENTATION 
   add constraint FK_MDOC_MAGEML foreign key (MAGE_ML_ID) 
      references MAGEML (MAGE_ML_ID) not deferrable
/


alter table MALDI 
   add constraint FK_MALDI_REFERENCE_IONSOURC foreign key (ion_source_ID) 
      references IONSOURCE (ion_source_ID)
/


alter table MASSSPECEXPERIMENT 
   add constraint FK_MASSSPEC_REFERENCE_BIOASSAY foreign key (BIOASSAY_TREATMENT_ID) 
      references BIOASSAYTREATMENT (BIOASSAY_TREATMENT_ID)
/


alter table MASSSPECEXPERIMENT 
   add constraint FK_MASSSPEC_REFERENCE_MASSSPEC foreign key (MSMachineID) 
      references MASSSPECMACHINE (mass_spec_machine_ID)
/


alter table MASSSPECMACHINE 
   add constraint FK_MASSSPEC_REFERENCE_IONSOURC foreign key (ion_source_ID) 
      references IONSOURCE (ion_source_ID)
/


alter table MATCHEDSPOTS 
   add constraint FK_MATCHED__REFERENCE_IDENTIFI foreign key (identified_spot_ID) 
      references IDENTIFIEDSPOT (identified_spot_ID)
/


alter table MATCHEDSPOTS 
   add constraint FK_MATCHED__REFERENCE_MULTIPLE foreign key (ACQUISITION_ID, GEL_IMAGE_ANALYSIS_ID, 
multiple_analysis_ID) 
      references MULTIPLEANALYSIS (ACQUISITION_ID, GEL_IMAGE_ANALYSIS_ID, multiple_analysis_ID)
/


alter table MOBILEPHASECOMPONENT 
   add constraint FK_MOBILEPH_REFERENCE_LCCOLUMN foreign key (lc_column) 
      references LCCOLUMN (LCColumn_ID)
/


alter table MSMSFRACTION 
   add constraint FK_MSMSFRAC_REFERENCE_PEAKLIST foreign key (peak_list_ID) 
      references PEAKLIST (peak_list_ID)
/


alter table MULTIPLEANALYSIS 
   add constraint FK_MULTIPLE_REFERENCE_IMAGE_AN foreign key (GEL_IMAGE_ANALYSIS_ID) 
      references GELIMAGEANALYSIS (GEL_IMAGE_ANALYSIS_ID)
/


alter table MULTIPLEANALYSIS 
   add constraint FK_MULTIPLE_REFERENCE_ONTOLOGY foreign key (analysis_type) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID)
/


alter table MULTIPLEANALYSIS 
   add constraint FK_MULTIPLE_REFERENCE_PROTOCOL foreign key (PROTOCOL_ID) 
      references PROTOCOL (PROTOCOL_ID)
/


alter table MZANALYSIS 
   add constraint FK_MZANALYS_REFERENCE_DETECTIO foreign key (detection_ID) 
      references DETECTION (detection_ID)
/


alter table ONTOLOGYENTRY 
   add constraint FK_ONTOLOGYENTRY_PARENT foreign key (PARENT_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table OTHERIONISATION 
   add constraint FK_OTHERION_REFERENCE_IONSOURC foreign key (ion_source_ID) 
      references IONSOURCE (ion_source_ID)
/


alter table OTHERIONISATION 
   add constraint FK_OTHERION_REFERENCE_ONTOLOGY foreign key (ONTOLOGY_ENTRY_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID)
/


alter table OTHERMZANALYSIS 
   add constraint FK_OTHERMZA_REFERENCE_MZANALYS foreign key (mz_analysis_ID) 
      references MZANALYSIS (mz_analysis_ID)
/


alter table OTHERMZANALYSIS 
   add constraint FK_OTHERMZA_REFERENCE_ONTOLOGY foreign key (ONTOLOGY_ENTRY_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID)
/


alter table PEAK 
   add constraint FK_PEAK_REFERENCE_PEAKLIST foreign key (peak_list_ID) 
      references PEAKLIST (peak_list_ID)
/


alter table PEAKLIST 
   add constraint FK_PEAKLIST_REFERENCE_MASSSPEC foreign key (mass_spec_experiment_ID) 
      references MASSSPECEXPERIMENT (mass_spec_experiment_ID)
/


alter table PEPTIDEHIT 
   add constraint FK_PEPTIDEH_REFERENCE_DATABASE foreign key (database_entry_ID) 
      references DATABASEENTRY (database_entry_ID)
/


alter table PEPTIDEHIT 
   add constraint FK_PEPTIDEH_REFERENCE_DBSEARCH foreign key (db_search_ID) 
      references DBSEARCH (db_search_ID)
/


alter table PERCENTX 
   add constraint FK_PERCENTX_REFERENCE_GRADIENT foreign key (lc_column, GradientStep_ID) 
      references GRADIENTSTEP (lc_column, GradientStep_ID)
/


alter table PERCENTX 
   add constraint FK_PERCENTX_REFERENCE_MOBILEPH foreign key (Percent_ID) 
      references MOBILEPHASECOMPONENT (id)
/


alter table PHYSICALGELITEM 
   add constraint FK_PHYSICAL_REFERENCE_BIOMATER foreign key (BIO_MATERIAL_ID) 
      references BIOMATERIALIMP (BIO_MATERIAL_ID)
/


alter table PHYSICALGELITEM 
   add constraint FK_PHYSICAL_REFERENCE_GEL1D foreign key (Gel1D_ID) 
      references GEL1D (Gel1D_ID)
/


alter table PHYSICALGELITEM 
   add constraint FK_PHYSICAL_REFERENCE_GEL2D foreign key (gel2D) 
      references GEL2D (Gel2D_ID)
/


alter table PHYSICALGELITEM 
   add constraint FK_PHYSICAL_REFERENCE_PROTEINR foreign key (ProteinRecord_ID) 
      references PROTEINRECORD (protein_record_ID)
/


alter table PROCESSIMPLEMENTATION 
   add constraint FK_PROCESSIMP_ONTO foreign key (PROCESS_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table PROCESSIMPLEMENTATIONPARAM 
   add constraint FK_PRCSIMPPARAM_PRCSIMP foreign key (PROCESS_IMPLEMENTATION_ID) 
      references PROCESSIMPLEMENTATION (PROCESS_IMPLEMENTATION_ID) not deferrable
/


alter table PROCESSINVOCATION 
   add constraint FK_PROCESS_PROCIMP foreign key (PROCESS_IMPLEMENTATION_ID) 
      references PROCESSIMPLEMENTATION (PROCESS_IMPLEMENTATION_ID) not deferrable
/


alter table PROCESSINVOCATIONPARAM 
   add constraint FK_PROCESSINVPARAM_PROCESSINV foreign key (PROCESS_INVOCATION_ID) 
      references PROCESSINVOCATION (PROCESS_INVOCATION_ID) not deferrable
/


alter table PROCESSINVQUANTIFICATION 
   add constraint FK_PROCESSINQUANT_P foreign key (PROCESS_INVOCATION_ID) 
      references PROCESSINVOCATION (PROCESS_INVOCATION_ID) not deferrable
/


alter table PROCESSINVQUANTIFICATION 
   add constraint FK_PROCESSINQUANT_Q foreign key (QUANTIFICATION_ID) 
      references QUANTIFICATION (QUANTIFICATION_ID) not deferrable
/


alter table PROCESSIO 
   add constraint FK_PROCESSEDRESULT21 foreign key (OUTPUT_RESULT_ID) 
      references PROCESSRESULT (PROCESS_RESULT_ID) not deferrable
/


alter table PROCESSIO 
   add constraint FK_PROCESSIO_PROCESSINV foreign key (PROCESS_INVOCATION_ID) 
      references PROCESSINVOCATION (PROCESS_INVOCATION_ID) not deferrable
/


alter table PROCESSIOELEMENT 
   add constraint FK_PROCESSIO foreign key (PROCESS_IO_ID) 
      references PROCESSIO (PROCESS_IO_ID) not deferrable
/


alter table PROCESSRESULT 
   add constraint FK_PROCESSRESULT_ONTO foreign key (UNIT_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table PROTEINHIT 
   add constraint FK_PROTEINH_REFERENCE_PEPTIDEH foreign key (peptide_hit_ID) 
      references PEPTIDEHIT (peptide_hit_ID)
/


alter table PROTEINHIT 
   add constraint FK_PROTEINH_REFERENCE_PROTEINR foreign key (ProteinRecord_ID) 
      references PROTEINRECORD (protein_record_ID)
/


alter table PROTEINMODIFICATION 
   add constraint FK_PROTEINM_REFERENCE_ONTOLOGY foreign key (modification_type) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID)
/


alter table PROTEINMODIFICATION 
   add constraint FK_PROTEINM_REFERENCE_PROTEINR foreign key (protein_record_ID) 
      references PROTEINRECORD (protein_record_ID)
/


alter table PROTEINRECORD 
   add constraint FK_PROTEINR_REFERENCE_DATABASE foreign key (database_entry_ID) 
      references DATABASEENTRY (database_entry_ID)
/


alter table PROTEOMEASSAY 
   add constraint FK_PROTEOME_REFERENCE_PROTOCOL foreign key (PROTOCOL_ID) 
      references PROTOCOL (PROTOCOL_ID)
/


alter table PROTOCOL 
   add constraint FK_PROTOCOL_HDWTYPE_OE foreign key (HARDWARE_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table PROTOCOL 
   add constraint FK_PROTOCOL_PRTTYPE_OE foreign key (PROTOCOL_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table PROTOCOL 
   add constraint FK_PROTOCOL_SFWTYPE_OE foreign key (SOFTWARE_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table PROTOCOLPARAM 
   add constraint FK_PROTOCOLPARAM_ONTO1 foreign key (DATA_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table PROTOCOLPARAM 
   add constraint FK_PROTOCOLPARAM_ONTO2 foreign key (UNIT_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table PROTOCOLPARAM 
   add constraint FK_PROTOCOLPARAM_PROTO foreign key (PROTOCOL_ID) 
      references PROTOCOL (PROTOCOL_ID) not deferrable
/


alter table QUADRUPOLE 
   add constraint FK_QUADRUPO_REFERENCE_MZANALYS foreign key (mz_analysis_ID) 
      references MZANALYSIS (mz_analysis_ID)
/


alter table QUANTIFICATION 
   add constraint FK_QUANT_ACQ foreign key (ACQUISITION_ID) 
      references ACQUISITION (ACQUISITION_ID) not deferrable
/


alter table QUANTIFICATION 
   add constraint FK_QUANT_PROTOCOL foreign key (PROTOCOL_ID) 
      references PROTOCOL (PROTOCOL_ID) not deferrable
/


alter table QUANTIFICATIONPARAM 
   add constraint FK_QUANTPARAM_PRTPRM foreign key (PROTOCOL_PARAM_ID) 
      references PROTOCOLPARAM (PROTOCOL_PARAM_ID) not deferrable
/


alter table QUANTIFICATIONPARAM 
   add constraint FK_QUANTPARAM_QUANT foreign key (QUANTIFICATION_ID) 
      references QUANTIFICATION (QUANTIFICATION_ID) not deferrable
/


alter table RELATEDACQUISITION 
   add constraint FK_RELACQ_ACQ01 foreign key (ACQUISITION_ID) 
      references ACQUISITION (ACQUISITION_ID) not deferrable
/


alter table RELATEDACQUISITION 
   add constraint FK_RELACQ_ACQ02 foreign key (ASSOCIATED_ACQUISITION_ID) 
      references ACQUISITION (ACQUISITION_ID) not deferrable
/


alter table RELATEDQUANTIFICATION 
   add constraint FK_RELQUANT_QUANT01 foreign key (QUANTIFICATION_ID) 
      references QUANTIFICATION (QUANTIFICATION_ID) not deferrable
/


alter table RELATEDQUANTIFICATION 
   add constraint FK_RELQUANT_QUANT02 foreign key (ASSOCIATED_QUANTIFICATION_ID) 
      references QUANTIFICATION (QUANTIFICATION_ID) not deferrable
/


alter table SPOTRATIO 
   add constraint FK_SPOTRATI_2_FK_DIGE_S_DIGES2 foreign key (second_DIGESingleSpot_ID) 
      references DIGESINGLESPOT (DIGESingleSpot_ID)
/


alter table SPOTRATIO 
   add constraint FK_SPOTRATI_FK_DIGE_S_DIGESING foreign key (first_DIGESingleSpot_ID) 
      references DIGESINGLESPOT (DIGESingleSpot_ID)
/


alter table STUDYASSAY 
   add constraint FK_STDYASSAY_ASSAY foreign key (ASSAY_ID) 
      references ASSAY (ASSAY_ID) not deferrable
/


alter table STUDYASSAY 
   add constraint FK_STDYASSAY_STDY foreign key (STUDY_ID) 
      references STUDY (STUDY_ID) not deferrable
/


alter table STUDYASSAYPROT 
   add constraint FK_STUDYASS_REFERENCE_PROTEOME foreign key (PROTEOME_ASSAY_ID) 
      references PROTEOMEASSAY (PROTEOME_ASSAY_ID)
/


alter table STUDYASSAYPROT 
   add constraint FK_STUDYASS_REFERENCE_STUDY foreign key (STUDY_ID) 
      references STUDY (STUDY_ID)
/


alter table STUDYBIOMATERIAL 
   add constraint FORMHELP_FK01 foreign key (STUDY_ID) 
      references STUDY (STUDY_ID) not deferrable
/


alter table STUDYBIOMATERIAL 
   add constraint FORMHELP_FK02 foreign key (BIO_MATERIAL_ID) 
      references BIOMATERIALIMP (BIO_MATERIAL_ID) not deferrable
/


alter table STUDYDESIGN 
   add constraint FK_STDYDES_STDY foreign key (STUDY_ID) 
      references STUDY (STUDY_ID) not deferrable
/


alter table STUDYDESIGNASSAY 
   add constraint FK_STDYDESASSAY_ASSAY foreign key (ASSAY_ID) 
      references ASSAY (ASSAY_ID) not deferrable
/


alter table STUDYDESIGNASSAY 
   add constraint FK_STDYDESASSAY_STDYDES foreign key (STUDY_DESIGN_ID) 
      references STUDYDESIGN (STUDY_DESIGN_ID) not deferrable
/


alter table STUDYDESIGNASSAYPROT 
   add constraint FK_STUDYDES_REFERENCE_STUDYDES foreign key (STUDY_DESIGN_ID) 
      references STUDYDESIGN (STUDY_DESIGN_ID)
/


alter table STUDYDESIGNASSAYPROT 
   add constraint FK_STUDYDES_REFERENCE_PROTEOME foreign key (PROTEOME_ASSAY_ID) 
      references PROTEOMEASSAY (PROTEOME_ASSAY_ID)
/


alter table STUDYDESIGNDESCRIPTION 
   add constraint FK_STDYDESDCR_STDYDES foreign key (STUDY_DESIGN_ID) 
      references STUDYDESIGN (STUDY_DESIGN_ID) not deferrable
/


alter table STUDYDESIGNTYPE 
   add constraint FK_STDYDESTYPE_ONTO foreign key (ONTOLOGY_ENTRY_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table STUDYDESIGNTYPE 
   add constraint FK_STDYDESTYPE_STDYDES foreign key (STUDY_DESIGN_ID) 
      references STUDYDESIGN (STUDY_DESIGN_ID) not deferrable
/


alter table STUDYFACTOR 
   add constraint FK_STDYFCTR_ONTO foreign key (STUDY_FACTOR_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table STUDYFACTOR 
   add constraint FK_STDYFCTR_STDYDES foreign key (STUDY_DESIGN_ID) 
      references STUDYDESIGN (STUDY_DESIGN_ID) not deferrable
/


alter table STUDYFACTORVALUE 
   add constraint FK_STDYFCTRVAL_ASSAY foreign key (ASSAY_ID) 
      references ASSAY (ASSAY_ID) not deferrable
/


alter table STUDYFACTORVALUE 
   add constraint FK_STDYFCTRVAL_OEUNIT foreign key (MEASUREMENT_UNIT_OE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table STUDYFACTORVALUE 
   add constraint FK_STDYFCTRVAL_OEVALUE foreign key (VALUE_ONTOLOGY_ENTRY_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table STUDYFACTORVALUE 
   add constraint FK_STDYFCTRVAL_STDYFCTR foreign key (STUDY_FACTOR_ID) 
      references STUDYFACTOR (STUDY_FACTOR_ID) not deferrable
/


alter table STUDYFACTORVALUEPROT 
   add constraint FK_STUDYFAC_FK_SFV_ME_ONTOLOGY foreign key (MEASUREMENT_UNIT_OE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID)
/


alter table STUDYFACTORVALUEPROT 
   add constraint FK_STUDYFAC_FK_STF_VA_ONTOLOGY foreign key (VALUE_ONTOLOGY_ENTRY_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID)
/


alter table STUDYFACTORVALUEPROT 
   add constraint FK_STUDYFAC_REFERENCE_PROTEOME foreign key (PROTEOME_ASSAY_ID) 
      references PROTEOMEASSAY (PROTEOME_ASSAY_ID)
/


alter table STUDYFACTORVALUEPROT 
   add constraint FK_STUDYFAC_REFERENCE_STUDYFAC foreign key (STUDY_FACTOR_ID) 
      references STUDYFACTOR (STUDY_FACTOR_ID)
/


alter table TANDEMSEQUENCEDATA 
   add constraint FK_TANDEMSE_REFERENCE_DBSEARCH foreign key (db_search_parameters_ID) 
      references DBSEARCHPARAMETERS (db_search_parameters_ID)
/


alter table TOF 
   add constraint FK_TOF_REFERENCE_MZANALYS foreign key (mz_analysis_ID) 
      references MZANALYSIS (mz_analysis_ID)
/


alter table TREATEDANALYTE 
   add constraint FK_TREATEDA_REFERENCE_BIOMATER foreign key (BIO_MATERIAL_ID) 
      references BIOMATERIALIMP (BIO_MATERIAL_ID)
/


alter table TREATEDANALYTE 
   add constraint FK_TREATEDA_REFERENCE_CHEMICAL foreign key (chemical_treatment_ID) 
      references CHEMICALTREATMENT (chemical_treatment_ID)
/


alter table TREATMENT 
   add constraint FK_TREATMENT6 foreign key (BIO_MATERIAL_ID) 
      references BIOMATERIALIMP (BIO_MATERIAL_ID) not deferrable
/


alter table TREATMENT 
   add constraint FK_TREATMENT7 foreign key (TREATMENT_TYPE_ID) 
      references ONTOLOGYENTRY (ONTOLOGY_ENTRY_ID) not deferrable
/


alter table TREATMENTPARAM 
   add constraint FK_TREATMENTPARAM_PRTOPRM foreign key (PROTOCOL_PARAM_ID) 
      references PROTOCOLPARAM (PROTOCOL_PARAM_ID) not deferrable
/


alter table TREATMENTPARAM 
   add constraint FK_TREATMENTPARAM_TREATMENT foreign key (TREATMENT_ID) 
      references TREATMENT (TREATMENT_ID) not deferrable
/







/*                                                                                            */
/* dots-constraints.sql                                                                       */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 20:45:58 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL dots-constraints.log

/* NON-PRIMARY KEY CONSTRAINTS */

/* AACOMMENT */
alter table @oracle_dots@.AACOMMENT add constraint AACOMMENT_FK04 foreign key (AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);
alter table @oracle_dots@.AACOMMENT add constraint AACOMMENT_FK05 foreign key (COMMENT_NAME_ID) references @oracle_dots@.COMMENTNAME (COMMENT_NAME_ID);

/* AAENTRY */
alter table @oracle_dots@.AAENTRY add constraint AAENTRY_FK04 foreign key (AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);

/* AAFAMILYEXPERIMENT */
alter table @oracle_dots@.AAFAMILYEXPERIMENT add constraint AAFAMILYEXPERIMENT_FK01 foreign key (AA_ORTHOLOG_EXPERIMENT_ID) references @oracle_dots@.AASEQGROUPEXPERIMENTIMP (AA_SEQ_GROUP_EXPERIMENT_ID);
alter table @oracle_dots@.AAFAMILYEXPERIMENT add constraint AAFAMILYEXPERIMENT_FK02 foreign key (AA_PARALOG_EXPERIMENT_ID) references @oracle_dots@.AASEQGROUPEXPERIMENTIMP (AA_SEQ_GROUP_EXPERIMENT_ID);

/* AAFEATUREIMP */
alter table @oracle_dots@.AAFEATUREIMP add constraint AAFEATUREIMP_FK01 foreign key (AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);
alter table @oracle_dots@.AAFEATUREIMP add constraint AAFEATUREIMP_FK02 foreign key (FEATURE_NAME_ID) references @oracle_dots@.FEATURENAME (FEATURE_NAME_ID);
alter table @oracle_dots@.AAFEATUREIMP add constraint AAFEATUREIMP_FK03 foreign key (PARENT_ID) references @oracle_dots@.AAFEATUREIMP (AA_FEATURE_ID);
alter table @oracle_dots@.AAFEATUREIMP add constraint AAFEATUREIMP_FK04 foreign key (NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);
alter table @oracle_dots@.AAFEATUREIMP add constraint AAFEATUREIMP_FK05 foreign key (SEQUENCE_ONTOLOGY_ID) references @oracle_sres@.SEQUENCEONTOLOGY (SEQUENCE_ONTOLOGY_ID);
alter table @oracle_dots@.AAFEATUREIMP add constraint AAFEATUREIMP_FK06 foreign key (PFAM_ENTRY_ID) references @oracle_dots@.PFAMENTRY (PFAM_ENTRY_ID);
alter table @oracle_dots@.AAFEATUREIMP add constraint AAFEATUREIMP_FK07 foreign key (MOTIF_AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);
alter table @oracle_dots@.AAFEATUREIMP add constraint AAFEATUREIMP_FK08 foreign key (REPEAT_TYPE_ID) references @oracle_dots@.REPEATTYPE (REPEAT_TYPE_ID);
alter table @oracle_dots@.AAFEATUREIMP add constraint AAFEATUREIMP_FK09 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.AAFEATUREIMP add constraint AAFEATUREIMP_FK10 foreign key (PREDICTION_ALGORITHM_ID) references @oracle_core@.ALGORITHM (ALGORITHM_ID);
alter table @oracle_dots@.AAFEATUREIMP add constraint AAFEATUREIMP_FK11 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* AAGENE */
alter table @oracle_dots@.AAGENE add constraint AAGENE_FK04 foreign key (AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);

/* AAGENESYNONYM */
alter table @oracle_dots@.AAGENESYNONYM add constraint AAGENESYNONYM_FK04 foreign key (AA_GENE_ID) references @oracle_dots@.AAGENE (AA_GENE_ID);

/* AALOCATION */
alter table @oracle_dots@.AALOCATION add constraint AALOCATION_FK04 foreign key (AA_FEATURE_ID) references @oracle_dots@.AAFEATUREIMP (AA_FEATURE_ID);

/* AAMOTIFGOTERMRULE */
alter table @oracle_dots@.AAMOTIFGOTERMRULE add constraint AAMOTIFGOTERMRULE_FK01 foreign key (AA_MOTIF_GO_TERM_RULE_SET_ID) references @oracle_dots@.AAMOTIFGOTERMRULESET (AA_MOTIF_GO_TERM_RULE_SET_ID);
alter table @oracle_dots@.AAMOTIFGOTERMRULE add constraint AAMOTIFGOTERMRULE_FK02 foreign key (GO_TERM_ID) references @oracle_sres@.GOTERM (GO_TERM_ID);
alter table @oracle_dots@.AAMOTIFGOTERMRULE add constraint AAMOTIFGOTERMRULE_FK03 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);
alter table @oracle_dots@.AAMOTIFGOTERMRULE add constraint AAMOTIFGOTERMRULE_FK04 foreign key (REVIEWER_ID) references @oracle_core@.USERINFO (USER_ID);

/* AAMOTIFGOTERMRULESET */
alter table @oracle_dots@.AAMOTIFGOTERMRULESET add constraint AAMOTIFGOTERMRULESET_FK01 foreign key (AA_SEQUENCE_ID_1) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);
alter table @oracle_dots@.AAMOTIFGOTERMRULESET add constraint AAMOTIFGOTERMRULESET_FK02 foreign key (AA_SEQUENCE_ID_2) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);
alter table @oracle_dots@.AAMOTIFGOTERMRULESET add constraint AAMOTIFGOTERMRULESET_FK03 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);
alter table @oracle_dots@.AAMOTIFGOTERMRULESET add constraint AAMOTIFGOTERMRULESET_FK04 foreign key (REVIEWER_ID) references @oracle_core@.USERINFO (USER_ID);

/* AASEQGROUPEXPERIMENTIMP */

/* AASEQUENCEDBREF */
alter table @oracle_dots@.AASEQUENCEDBREF add constraint AASEQUENCEDBREF_FK04 foreign key (DB_REF_ID) references @oracle_sres@.DBREF (DB_REF_ID);
alter table @oracle_dots@.AASEQUENCEDBREF add constraint AASEQUENCEDBREF_FK05 foreign key (AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);

/* AASEQUENCEFAMILY */
alter table @oracle_dots@.AASEQUENCEFAMILY add constraint AASEQUENCEFAMILY_FK01 foreign key (AA_FAMILY_EXPERIMENT_ID) references @oracle_dots@.AAFAMILYEXPERIMENT (AA_FAMILY_EXPERIMENT_ID);

/* AASEQUENCEGROUPFAMILY */
alter table @oracle_dots@.AASEQUENCEGROUPFAMILY add constraint AASEQUENCEGROUPFAMILY_FK01 foreign key (AA_SEQUENCE_FAMILY_ID) references @oracle_dots@.AASEQUENCEFAMILY (AA_SEQUENCE_FAMILY_ID);
alter table @oracle_dots@.AASEQUENCEGROUPFAMILY add constraint AASEQUENCEGROUPFAMILY_FK02 foreign key (AA_SEQUENCE_GROUP_ID) references @oracle_dots@.AASEQUENCEGROUPIMP (AA_SEQUENCE_GROUP_ID);

/* AASEQUENCEGROUPIMP */
alter table @oracle_dots@.AASEQUENCEGROUPIMP add constraint AASEQUENCEGROUPIMP_FK01 foreign key (AA_SEQ_GROUP_EXPERIMENT_ID) references @oracle_dots@.AASEQGROUPEXPERIMENTIMP (AA_SEQ_GROUP_EXPERIMENT_ID);

/* AASEQUENCEIMP */
alter table @oracle_dots@.AASEQUENCEIMP add constraint AASEQUENCEIMP_FK04 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.AASEQUENCEIMP add constraint AASEQUENCEIMP_FK05 foreign key (SOURCE_AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);

/* AASEQUENCEKEYWORD */
alter table @oracle_dots@.AASEQUENCEKEYWORD add constraint AASEQUENCEKEYWORD_FK04 foreign key (KEYWORD_ID) references @oracle_dots@.KEYWORD (KEYWORD_ID);
alter table @oracle_dots@.AASEQUENCEKEYWORD add constraint AASEQUENCEKEYWORD_FK05 foreign key (AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);

/* AASEQUENCEORGANELLE */
alter table @oracle_dots@.AASEQUENCEORGANELLE add constraint AASEQUENCEORGANELLE_FK04 foreign key (ORGANELLE_ID) references @oracle_dots@.ORGANELLE (ORGANELLE_ID);
alter table @oracle_dots@.AASEQUENCEORGANELLE add constraint AASEQUENCEORGANELLE_FK05 foreign key (AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);

/* AASEQUENCEREF */
alter table @oracle_dots@.AASEQUENCEREF add constraint AASEQUENCEREF_FK01 foreign key (REFERENCE_ID) references @oracle_sres@.REFERENCE (REFERENCE_ID);
alter table @oracle_dots@.AASEQUENCEREF add constraint AASEQUENCEREF_FK02 foreign key (AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);

/* AASEQUENCESEQUENCEGROUP */
alter table @oracle_dots@.AASEQUENCESEQUENCEGROUP add constraint AASEQUENCESEQUENCEGROUP_FK01 foreign key (AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);
alter table @oracle_dots@.AASEQUENCESEQUENCEGROUP add constraint AASEQUENCESEQUENCEGROUP_FK02 foreign key (AA_SEQUENCE_GROUP_ID) references @oracle_dots@.AASEQUENCEGROUPIMP (AA_SEQUENCE_GROUP_ID);

/* AASEQUENCETAXON */
alter table @oracle_dots@.AASEQUENCETAXON add constraint AASEQUENCETAXON_FK03 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_dots@.AASEQUENCETAXON add constraint AASEQUENCETAXON_FK05 foreign key (AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);

/* ALLELE */
alter table @oracle_dots@.ALLELE add constraint ALLELE_FK01 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);
alter table @oracle_dots@.ALLELE add constraint ALLELE_FK02 foreign key (GENE_ID) references @oracle_dots@.GENE (GENE_ID);
alter table @oracle_dots@.ALLELE add constraint ALLELE_FK03 foreign key (MUTAGEN_ID) references @oracle_sres@.MUTAGEN (MUTAGEN_ID);

/* ALLELECOMPLEMENTATION */
alter table @oracle_dots@.ALLELECOMPLEMENTATION add constraint ALLELECOMPLEMENTATION_FK01 foreign key (COMPLEMENTATION_ID) references @oracle_dots@.COMPLEMENTATION (COMPLEMENTATION_ID);
alter table @oracle_dots@.ALLELECOMPLEMENTATION add constraint ALLELECOMPLEMENTATION_FK02 foreign key (ALLELE_ID) references @oracle_dots@.ALLELE (ALLELE_ID);
alter table @oracle_dots@.ALLELECOMPLEMENTATION add constraint ALLELECOMPLEMENTATION_FK03 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* ALLELEINSTANCE */
alter table @oracle_dots@.ALLELEINSTANCE add constraint ALLELEINSTANCE_FK01 foreign key (NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);
alter table @oracle_dots@.ALLELEINSTANCE add constraint ALLELEINSTANCE_FK02 foreign key (ALLELE_ID) references @oracle_dots@.ALLELE (ALLELE_ID);
alter table @oracle_dots@.ALLELEINSTANCE add constraint ALLELEINSTANCE_FK03 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* ALLELEPHENOTYPE */
alter table @oracle_dots@.ALLELEPHENOTYPE add constraint ALLELEPHENOTYPE_FK01 foreign key (PHENOTYPE_ID) references @oracle_sres@.PHENOTYPE (PHENOTYPE_ID);
alter table @oracle_dots@.ALLELEPHENOTYPE add constraint ALLELEPHENOTYPE_FK02 foreign key (ALLELE_ID) references @oracle_dots@.ALLELE (ALLELE_ID);
alter table @oracle_dots@.ALLELEPHENOTYPE add constraint ALLELEPHENOTYPE_FK03 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* ALLELEPHENOTYPECLASS */
alter table @oracle_dots@.ALLELEPHENOTYPECLASS add constraint ALLELEPHENOTYPECLASS_FK01 foreign key (PHENOTYPE_CLASS_ID) references @oracle_sres@.PHENOTYPECLASS (PHENOTYPE_CLASS_ID);
alter table @oracle_dots@.ALLELEPHENOTYPECLASS add constraint ALLELEPHENOTYPECLASS_FK02 foreign key (ALLELE_ID) references @oracle_dots@.ALLELE (ALLELE_ID);
alter table @oracle_dots@.ALLELEPHENOTYPECLASS add constraint ALLELEPHENOTYPECLASS_FK03 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* ANATOMYLIBRARY */
alter table @oracle_dots@.ANATOMYLIBRARY add constraint ANATOMYLIBRARY_FK04 foreign key (ANATOMY_ID) references @oracle_sres@.ANATOMY (ANATOMY_ID);

/* ANATOMYLOE */

/* ASSEMBLYANATOMYPERCENT */
alter table @oracle_dots@.ASSEMBLYANATOMYPERCENT add constraint ASSEMBLYANATOMYPERCENT_FK01 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.ASSEMBLYANATOMYPERCENT add constraint ASSEMBLYANATOMYPERCENT_FK02 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_dots@.ASSEMBLYANATOMYPERCENT add constraint ASSEMBLYANATOMYPERCENT_FK03 foreign key (ANATOMY_ID) references @oracle_sres@.ANATOMY (ANATOMY_ID);

/* ASSEMBLYSEQUENCE */
alter table @oracle_dots@.ASSEMBLYSEQUENCE add constraint ASSEMBLYSEQUENCE_FK04 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.ASSEMBLYSEQUENCE add constraint ASSEMBLYSEQUENCE_FK05 foreign key (ASSEMBLY_NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* ASSEMBLYSEQUENCESNP */
alter table @oracle_dots@.ASSEMBLYSEQUENCESNP add constraint ASSEMBLYSEQUENCESNP_FK01 foreign key (ASSEMBLY_SEQUENCE_ID) references @oracle_dots@.ASSEMBLYSEQUENCE (ASSEMBLY_SEQUENCE_ID);
alter table @oracle_dots@.ASSEMBLYSEQUENCESNP add constraint ASSEMBLYSEQUENCESNP_FK02 foreign key (ASSEMBLY_SNP_ID) references @oracle_dots@.ASSEMBLYSNP (ASSEMBLY_SNP_ID);

/* ASSEMBLYSNP */
alter table @oracle_dots@.ASSEMBLYSNP add constraint ASSEMBLYSNP_FK01 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* ATTRIBUTION */
alter table @oracle_dots@.ATTRIBUTION add constraint ATTRIBUTION_FK01 foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.ATTRIBUTION add constraint ATTRIBUTION_FK02 foreign key (CONTACT_ID) references @oracle_sres@.CONTACT (CONTACT_ID);

/* BESTSIMILARITYPAIR */
alter table @oracle_dots@.BESTSIMILARITYPAIR add constraint BESTSIMILARITYPAIR_FK05 foreign key (SOURCE_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.BESTSIMILARITYPAIR add constraint BESTSIMILARITYPAIR_FK06 foreign key (PAIRED_SOURCE_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.BESTSIMILARITYPAIR add constraint BESTSIMILARITYPAIR_FK07 foreign key (ORTHOLOG_EXPERIMENT_ID) references @oracle_dots@.SEQGROUPEXPERIMENTIMP (SEQ_GROUP_EXPERIMENT_ID);

/* BLATALIGNMENT */
alter table @oracle_dots@.BLATALIGNMENT add constraint BLATALIGNMENT_FK01 foreign key (QUERY_NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.BLATALIGNMENT add constraint BLATALIGNMENT_FK02 foreign key (TARGET_NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.BLATALIGNMENT add constraint BLATALIGNMENT_FK03 foreign key (QUERY_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.BLATALIGNMENT add constraint BLATALIGNMENT_FK04 foreign key (QUERY_TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_dots@.BLATALIGNMENT add constraint BLATALIGNMENT_FK05 foreign key (QUERY_EXTERNAL_DB_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.BLATALIGNMENT add constraint BLATALIGNMENT_FK06 foreign key (TARGET_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.BLATALIGNMENT add constraint BLATALIGNMENT_FK07 foreign key (TARGET_TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_dots@.BLATALIGNMENT add constraint BLATALIGNMENT_FK08 foreign key (TARGET_EXTERNAL_DB_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.BLATALIGNMENT add constraint BLATALIGNMENT_FK09 foreign key (BLAT_ALIGNMENT_QUALITY_ID) references @oracle_dots@.BLATALIGNMENTQUALITY (BLAT_ALIGNMENT_QUALITY_ID);

/* BLATALIGNMENTQUALITY */

/* CLONE */
alter table @oracle_dots@.CLONE add constraint CLONE_FK03 foreign key (LIBRARY_ID) references @oracle_dots@.LIBRARY (LIBRARY_ID);

/* CLONEINSET */
alter table @oracle_dots@.CLONEINSET add constraint CLONEINSET_FK01 foreign key (CLONE_ID) references @oracle_dots@.CLONE (CLONE_ID);
alter table @oracle_dots@.CLONEINSET add constraint CLONEINSET_FK05 foreign key (CLONE_SET_ID) references @oracle_dots@.CLONESET (CLONE_SET_ID);

/* CLONESET */
alter table @oracle_dots@.CLONESET add constraint CLONESET_FK03 foreign key (CONTACT_ID) references @oracle_sres@.CONTACT (CONTACT_ID);

/* COMMENTNAME */

/* COMMENTS */
alter table @oracle_dots@.COMMENTS add constraint COMMENTS_FK01 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* COMPLEMENTATION */
alter table @oracle_dots@.COMPLEMENTATION add constraint COMPLEMENTATION_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.COMPLEMENTATION add constraint COMPLEMENTATION_FK02 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_dots@.COMPLEMENTATION add constraint COMPLEMENTATION_FK03 foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.COMPLEMENTATION add constraint COMPLEMENTATION_FK04 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* COMPLEX */
alter table @oracle_dots@.COMPLEX add constraint COMPLEX_FK01 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);
alter table @oracle_dots@.COMPLEX add constraint COMPLEX_FK02 foreign key (COMPLEX_TYPE_ID) references @oracle_dots@.COMPLEXTYPE (COMPLEX_TYPE_ID);
alter table @oracle_dots@.COMPLEX add constraint COMPLEX_FK03 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* COMPLEXANATOMY */
alter table @oracle_dots@.COMPLEXANATOMY add constraint COMPLEXANATOMY_FK01 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);
alter table @oracle_dots@.COMPLEXANATOMY add constraint COMPLEXANATOMY_FK02 foreign key (ANATOMY_ID) references @oracle_sres@.ANATOMY (ANATOMY_ID);
alter table @oracle_dots@.COMPLEXANATOMY add constraint COMPLEXANATOMY_FK03 foreign key (COMPLEX_ID) references @oracle_dots@.COMPLEX (COMPLEX_ID);

/* COMPLEXCOMPONENT */
alter table @oracle_dots@.COMPLEXCOMPONENT add constraint COMPLEXCOMPONENT_FK01 foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.COMPLEXCOMPONENT add constraint COMPLEXCOMPONENT_FK02 foreign key (COMPLEX_ID) references @oracle_dots@.COMPLEX (COMPLEX_ID);

/* COMPLEXTYPE */

/* CONSISTENTALIGNMENT */
alter table @oracle_dots@.CONSISTENTALIGNMENT add constraint CONSISTENTALIGNMENT_FK04 foreign key (SIMILARITY_ID) references @oracle_dots@.SIMILARITY (SIMILARITY_ID);
alter table @oracle_dots@.CONSISTENTALIGNMENT add constraint CONSISTENTALIGNMENT_FK05 foreign key (GENOMIC_NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.CONSISTENTALIGNMENT add constraint CONSISTENTALIGNMENT_FK06 foreign key (TRANSCRIPT_NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* DBREFNAFEATURE */
alter table @oracle_dots@.DBREFNAFEATURE add constraint DBREFNAFEATURE_FK04 foreign key (DB_REF_ID) references @oracle_sres@.DBREF (DB_REF_ID);
alter table @oracle_dots@.DBREFNAFEATURE add constraint DBREFNAFEATURE_FK05 foreign key (NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);

/* DBREFNASEQUENCE */
alter table @oracle_dots@.DBREFNASEQUENCE add constraint DBREFNASEQUENCE_FK04 foreign key (DB_REF_ID) references @oracle_sres@.DBREF (DB_REF_ID);
alter table @oracle_dots@.DBREFNASEQUENCE add constraint DBREFNASEQUENCE_FK05 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* DBREFPFAMENTRY */
alter table @oracle_dots@.DBREFPFAMENTRY add constraint DBREFPFAMENTRY_FK01 foreign key (DB_REF_ID) references @oracle_sres@.DBREF (DB_REF_ID);
alter table @oracle_dots@.DBREFPFAMENTRY add constraint DBREFPFAMENTRY_FK05 foreign key (PFAM_ENTRY_ID) references @oracle_dots@.PFAMENTRY (PFAM_ENTRY_ID);

/* EFFECTORACTIONTYPE */
alter table @oracle_dots@.EFFECTORACTIONTYPE add constraint EFFECTORACTIONTYPE_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* ENDSEQUENCEPAIRMAP */
alter table @oracle_dots@.ENDSEQUENCEPAIRMAP add constraint ENDSEQUENCEPAIRMAP_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.ENDSEQUENCEPAIRMAP add constraint ENDSEQUENCEPAIRMAP_FK02 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_dots@.ENDSEQUENCEPAIRMAP add constraint ENDSEQUENCEPAIRMAP_FK03 foreign key (NA_SEQUENCE_ID_1) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.ENDSEQUENCEPAIRMAP add constraint ENDSEQUENCEPAIRMAP_FK04 foreign key (NA_SEQUENCE_ID_2) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* EPCR */
alter table @oracle_dots@.EPCR add constraint EPCR_FK01 foreign key (MAP_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.EPCR add constraint EPCR_FK02 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.EPCR add constraint EPCR_FK03 foreign key (SIMILARITY_ID_1) references @oracle_dots@.SIMILARITY (SIMILARITY_ID);
alter table @oracle_dots@.EPCR add constraint EPCR_FK04 foreign key (SIMILARITY_ID_2) references @oracle_dots@.SIMILARITY (SIMILARITY_ID);

/* EST */
alter table @oracle_dots@.EST add constraint EST_FK01 foreign key (CLONE_ID) references @oracle_dots@.CLONE (CLONE_ID);
alter table @oracle_dots@.EST add constraint EST_FK04 foreign key (CONTACT_ID) references @oracle_sres@.CONTACT (CONTACT_ID);
alter table @oracle_dots@.EST add constraint EST_FK06 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.EST add constraint EST_FK08 foreign key (LIBRARY_ID) references @oracle_dots@.LIBRARY (LIBRARY_ID);

/* EVIDENCE */
alter table @oracle_dots@.EVIDENCE add constraint EVIDENCE_FK04 foreign key (FACT_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.EVIDENCE add constraint EVIDENCE_FK05 foreign key (TARGET_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* EXONLOCATION */
alter table @oracle_dots@.EXONLOCATION add constraint EXONLOCATION_FK04 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* FAMILY */
alter table @oracle_dots@.FAMILY add constraint FAMILY_FK04 foreign key (PARENT_FAMILY_ID) references @oracle_dots@.FAMILY (FAMILY_ID);

/* FAMILYGENE */
alter table @oracle_dots@.FAMILYGENE add constraint FAMILYGENE_FK03 foreign key (GENE_ID) references @oracle_dots@.GENE (GENE_ID);
alter table @oracle_dots@.FAMILYGENE add constraint FAMILYGENE_FK05 foreign key (FAMILY_ID) references @oracle_dots@.FAMILY (FAMILY_ID);

/* FAMILYPROTEIN */
alter table @oracle_dots@.FAMILYPROTEIN add constraint FAMILYPROTEIN_FK04 foreign key (FAMILY_ID) references @oracle_dots@.FAMILY (FAMILY_ID);
alter table @oracle_dots@.FAMILYPROTEIN add constraint FAMILYPROTEIN_FK05 foreign key (PROTEIN_ID) references @oracle_dots@.PROTEIN (PROTEIN_ID);

/* FEATURENAME */

/* FINGERPRINTCLONE */
alter table @oracle_dots@.FINGERPRINTCLONE add constraint FINGERPRINTCLONE_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* FINGERPRINTCLONECONTIG */
alter table @oracle_dots@.FINGERPRINTCLONECONTIG add constraint FINGERPRINTCLONECONTIG_FK01 foreign key (FINGERPRINT_CLONE_ID) references @oracle_dots@.FINGERPRINTCLONE (FINGERPRINT_CLONE_ID);
alter table @oracle_dots@.FINGERPRINTCLONECONTIG add constraint FINGERPRINTCLONECONTIG_FK02 foreign key (FINGERPRINT_CONTIG_ID) references @oracle_dots@.FINGERPRINTCONTIG (FINGERPRINT_CONTIG_ID);

/* FINGERPRINTCLONEMARKER */
alter table @oracle_dots@.FINGERPRINTCLONEMARKER add constraint FINGERPRINTCLONEMARKER_FK01 foreign key (FINGERPRINT_MAP_ID) references @oracle_dots@.FINGERPRINTMAP (FINGERPRINT_MAP_ID);
alter table @oracle_dots@.FINGERPRINTCLONEMARKER add constraint FINGERPRINTCLONEMARKER_FK02 foreign key (FINGERPRINT_CLONE_ID) references @oracle_dots@.FINGERPRINTCLONE (FINGERPRINT_CLONE_ID);
alter table @oracle_dots@.FINGERPRINTCLONEMARKER add constraint FINGERPRINTCLONEMARKER_FK03 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* FINGERPRINTCONTIG */
alter table @oracle_dots@.FINGERPRINTCONTIG add constraint FINGERPRINTCONTIG_FK01 foreign key (FINGERPRINT_MAP_ID) references @oracle_dots@.FINGERPRINTMAP (FINGERPRINT_MAP_ID);

/* FINGERPRINTMAP */
alter table @oracle_dots@.FINGERPRINTMAP add constraint FINGERPRINTMAP_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* GENE */
alter table @oracle_dots@.GENE add constraint GENE_FK04 foreign key (GENE_CATEGORY_ID) references @oracle_dots@.GENECATEGORY (GENE_CATEGORY_ID);
alter table @oracle_dots@.GENE add constraint GENE_FK05 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* GENEALIAS */
alter table @oracle_dots@.GENEALIAS add constraint GENEALIAS_FK05 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);
alter table @oracle_dots@.GENEALIAS add constraint GENEALIAS_FK06 foreign key (GENE_ID) references @oracle_dots@.GENE (GENE_ID);

/* GENECATEGORY */

/* GENECHROMOSOMALLOCATION */
alter table @oracle_dots@.GENECHROMOSOMALLOCATION add constraint GENECHROMOSOMALLOCATION_FK01 foreign key (GENE_ID) references @oracle_dots@.GENE (GENE_ID);

/* GENEFAMILY */

/* GENEFAMILYRELATION */
alter table @oracle_dots@.GENEFAMILYRELATION add constraint GENEFAMILYRELATION_FK02 foreign key (GENE_ID) references @oracle_dots@.GENE (GENE_ID);
alter table @oracle_dots@.GENEFAMILYRELATION add constraint GENEFAMILYRELATION_FK05 foreign key (GENE_FAMILY_ID) references @oracle_dots@.GENEFAMILY (GENE_FAMILY_ID);

/* GENEFEATURESAGETAGLINK */
alter table @oracle_dots@.GENEFEATURESAGETAGLINK add constraint GENEFEATURESAGETAGLINK_FK01 foreign key (GENOMIC_NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.GENEFEATURESAGETAGLINK add constraint GENEFEATURESAGETAGLINK_FK02 foreign key (GENE_NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);
alter table @oracle_dots@.GENEFEATURESAGETAGLINK add constraint GENEFEATURESAGETAGLINK_FK03 foreign key (TAG_NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);

/* GENEFEATURESEQOVERLAP */
alter table @oracle_dots@.GENEFEATURESEQOVERLAP add constraint GENEFEATURESEQOVERLAP_FK01 foreign key (GENE_NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);
alter table @oracle_dots@.GENEFEATURESEQOVERLAP add constraint GENEFEATURESEQOVERLAP_FK02 foreign key (GENOMIC_NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.GENEFEATURESEQOVERLAP add constraint GENEFEATURESEQOVERLAP_FK03 foreign key (SEQ_NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.GENEFEATURESEQOVERLAP add constraint GENEFEATURESEQOVERLAP_FK04 foreign key (END_SEQUENCE_PAIR_MAP_ID) references @oracle_dots@.ENDSEQUENCEPAIRMAP (END_SEQUENCE_PAIR_MAP_ID);
alter table @oracle_dots@.GENEFEATURESEQOVERLAP add constraint GENEFEATURESEQOVERLAP_FK05 foreign key (EPCR_ID) references @oracle_dots@.EPCR (EPCR_ID);
alter table @oracle_dots@.GENEFEATURESEQOVERLAP add constraint GENEFEATURESEQOVERLAP_FK06 foreign key (SIMILARITY_ID) references @oracle_dots@.SIMILARITY (SIMILARITY_ID);
alter table @oracle_dots@.GENEFEATURESEQOVERLAP add constraint GENEFEATURESEQOVERLAP_FK07 foreign key (BLAT_ALIGNMENT_ID) references @oracle_dots@.BLATALIGNMENT (BLAT_ALIGNMENT_ID);

/* GENEINSTANCE */
alter table @oracle_dots@.GENEINSTANCE add constraint GENEINSTANCE_FK05 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);
alter table @oracle_dots@.GENEINSTANCE add constraint GENEINSTANCE_FK06 foreign key (GENE_ID) references @oracle_dots@.GENE (GENE_ID);
alter table @oracle_dots@.GENEINSTANCE add constraint GENEINSTANCE_FK07 foreign key (NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);
alter table @oracle_dots@.GENEINSTANCE add constraint GENEINSTANCE_FK08 foreign key (GENE_INSTANCE_CATEGORY_ID) references @oracle_dots@.GENEINSTANCECATEGORY (GENE_INSTANCE_CATEGORY_ID);

/* GENEINSTANCECATEGORY */

/* GENESUPERFAMILY */

/* GENESUPERFAMILYRELATION */
alter table @oracle_dots@.GENESUPERFAMILYRELATION add constraint GENESUPERFAMILYRELATION_FK04 foreign key (GENE_FAMILY_ID) references @oracle_dots@.GENEFAMILY (GENE_FAMILY_ID);
alter table @oracle_dots@.GENESUPERFAMILYRELATION add constraint GENESUPERFAMILYRELATION_FK06 foreign key (GENE_SUPER_FAMILY_ID) references @oracle_dots@.GENESUPERFAMILY (GENE_SUPER_FAMILY_ID);

/* GENESYNONYM */
alter table @oracle_dots@.GENESYNONYM add constraint GENESYNONYM_FK03 foreign key (GENE_ID) references @oracle_dots@.GENE (GENE_ID);
alter table @oracle_dots@.GENESYNONYM add constraint GENESYNONYM_FK04 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* GENETRAPASSEMBLY */
alter table @oracle_dots@.GENETRAPASSEMBLY add constraint GENETRAPASSEMBLY_FK01 foreign key (TAG_NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.GENETRAPASSEMBLY add constraint GENETRAPASSEMBLY_FK02 foreign key (ASSEMBLY_NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* GOASSOCIATION */
alter table @oracle_dots@.GOASSOCIATION add constraint GOASSOCIATION_FK03 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);
alter table @oracle_dots@.GOASSOCIATION add unique (TABLE_ID,ROW_ID,GO_TERM_ID);
alter table @oracle_dots@.GOASSOCIATION add constraint GOSSOCIATION_FK01 foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.GOASSOCIATION add constraint GOSSOCIATION_FK02 foreign key (GO_TERM_ID) references @oracle_sres@.GOTERM (GO_TERM_ID);

/* GOASSOCIATIONINSTANCE */
alter table @oracle_dots@.GOASSOCIATIONINSTANCE add constraint GOASSOCIATIONINSTANCE_FK01 foreign key (GO_ASSOCIATION_ID) references @oracle_dots@.GOASSOCIATION (GO_ASSOCIATION_ID);
alter table @oracle_dots@.GOASSOCIATIONINSTANCE add constraint GOASSOCIATIONINSTANCE_FK02 foreign key (GO_ASSOC_INST_LOE_ID) references @oracle_dots@.GOASSOCIATIONINSTANCELOE (GO_ASSOC_INST_LOE_ID);
alter table @oracle_dots@.GOASSOCIATIONINSTANCE add constraint GOASSOCIATIONINSTANCE_FK03 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.GOASSOCIATIONINSTANCE add constraint GOASSOCIATIONINSTANCE_FK04 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* GOASSOCIATIONINSTANCELOE */

/* GOASSOCINSTEVIDCODE */
alter table @oracle_dots@.GOASSOCINSTEVIDCODE add constraint GOASSOCINSTEVIDCODE_FK01 foreign key (GO_EVIDENCE_CODE_ID) references @oracle_sres@.GOEVIDENCECODE (GO_EVIDENCE_CODE_ID);
alter table @oracle_dots@.GOASSOCINSTEVIDCODE add constraint GOASSOCINSTEVIDCODE_FK02 foreign key (GO_ASSOCIATION_INSTANCE_ID) references @oracle_dots@.GOASSOCIATIONINSTANCE (GO_ASSOCIATION_INSTANCE_ID);
alter table @oracle_dots@.GOASSOCINSTEVIDCODE add constraint GOASSOCINSTEVIDCODE_FK03 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* INDEXWORD */

/* INDEXWORDLINK */
alter table @oracle_dots@.INDEXWORDLINK add constraint INDEXWORDLINK_FK04 foreign key (TARGET_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.INDEXWORDLINK add constraint INDEXWORDLINK_FK05 foreign key (INDEX_WORD_ID) references @oracle_dots@.INDEXWORD (INDEX_WORD_ID);

/* INDEXWORDSIMLINK */
alter table @oracle_dots@.INDEXWORDSIMLINK add constraint INDEXWORDSIMLINK_FK04 foreign key (TARGET_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.INDEXWORDSIMLINK add constraint INDEXWORDSIMLINK_FK05 foreign key (INDEX_WORD_ID) references @oracle_dots@.INDEXWORD (INDEX_WORD_ID);
alter table @oracle_dots@.INDEXWORDSIMLINK add constraint INDEXWORDSIMLINK_FK06 foreign key (SIMILARITY_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.INDEXWORDSIMLINK add constraint INDEXWORDSIMLINK_FK07 foreign key (BEST_SIMILARITY_ID) references @oracle_dots@.SIMILARITY (SIMILARITY_ID);

/* INTERACTION */
alter table @oracle_dots@.INTERACTION add constraint INTERACTION_FK01 foreign key (INTERACTION_TYPE_ID) references @oracle_dots@.INTERACTIONTYPE (INTERACTION_TYPE_ID);
alter table @oracle_dots@.INTERACTION add constraint INTERACTION_FK02 foreign key (EFFECTOR_ACTION_TYPE_ID) references @oracle_dots@.EFFECTORACTIONTYPE (EFFECTOR_ACTION_TYPE_ID);
alter table @oracle_dots@.INTERACTION add constraint INTERACTION_FK03 foreign key (EFFECTOR_ROW_SET_ID) references @oracle_dots@.ROWSET (ROW_SET_ID);
alter table @oracle_dots@.INTERACTION add constraint INTERACTION_FK04 foreign key (TARGET_ROW_SET_ID) references @oracle_dots@.ROWSET (ROW_SET_ID);
alter table @oracle_dots@.INTERACTION add constraint INTERACTION_FK05 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.INTERACTION add constraint INTERACTION_FK06 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* INTERACTIONINTERACTIONLOE */
alter table @oracle_dots@.INTERACTIONINTERACTIONLOE add constraint INTERACTIONINTERACTIONLOE_FK01 foreign key (INTERACTION_ID) references @oracle_dots@.INTERACTION (INTERACTION_ID);
alter table @oracle_dots@.INTERACTIONINTERACTIONLOE add constraint INTERACTIONINTERACTIONLOE_FK02 foreign key (INTERACTION_LOE_ID) references @oracle_dots@.INTERACTIONLOE (INTERACTION_LOE_ID);

/* INTERACTIONLOE */

/* INTERACTIONTYPE */
alter table @oracle_dots@.INTERACTIONTYPE add constraint INTERACTIONTYPE_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* ISEXPRESSED */
alter table @oracle_dots@.ISEXPRESSED add constraint ISEXPRESSED_FK05 foreign key (ANATOMY_ID) references @oracle_sres@.ANATOMY (ANATOMY_ID);
alter table @oracle_dots@.ISEXPRESSED add constraint ISEXPRESSED_FK06 foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* KEYWORD */
alter table @oracle_dots@.KEYWORD add constraint KEYWORD_FK foreign key (PREFERRED_KEYWORD_ID) references @oracle_dots@.KEYWORD (KEYWORD_ID);

/* LIBRARY */
alter table @oracle_dots@.LIBRARY add constraint LIBRARY_FK01 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_dots@.LIBRARY add constraint LIBRARY_FK03 foreign key (ANATOMY_ID) references @oracle_sres@.ANATOMY (ANATOMY_ID);

/* MERGESPLIT */
alter table @oracle_dots@.MERGESPLIT add constraint MERGESPLIT_FK04 foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* MOTIF */
alter table @oracle_dots@.MOTIF add constraint MOTIF_FK04 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* NACOMMENT */
alter table @oracle_dots@.NACOMMENT add constraint NACOMMENT_FK01 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* NAENTRY */
alter table @oracle_dots@.NAENTRY add constraint NAENTRY_FK04 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* NAFEATRELATIONSHIPTYPE */

/* NAFEATURECOMMENT */
alter table @oracle_dots@.NAFEATURECOMMENT add constraint NAFEATURECOMMENT_FK01 foreign key (NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);

/* NAFEATUREIMP */
alter table @oracle_dots@.NAFEATUREIMP add constraint NAFEATUREIMP_FK03 foreign key (SEQUENCE_ONTOLOGY_ID) references @oracle_sres@.SEQUENCEONTOLOGY (SEQUENCE_ONTOLOGY_ID);
alter table @oracle_dots@.NAFEATUREIMP add constraint NAFEATUREIMP_FK04 foreign key (PARENT_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);
alter table @oracle_dots@.NAFEATUREIMP add constraint NAFEATUREIMP_FK05 foreign key (PREDICTION_ALGORITHM_ID) references @oracle_core@.ALGORITHM (ALGORITHM_ID);
alter table @oracle_dots@.NAFEATUREIMP add constraint NAFEATUREIMP_FK06 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.NAFEATUREIMP add constraint NAFEATUREIMP_FK07 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.NAFEATUREIMP add constraint NAFEATUREIMP_FK08 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* NAFEATURENAGENE */
alter table @oracle_dots@.NAFEATURENAGENE add constraint NAFEATURENAGENE_FK04 foreign key (NA_GENE_ID) references @oracle_dots@.NAGENE (NA_GENE_ID);
alter table @oracle_dots@.NAFEATURENAGENE add constraint NAFEATURENAGENE_FK05 foreign key (NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);

/* NAFEATURENAPROTEIN */
alter table @oracle_dots@.NAFEATURENAPROTEIN add constraint NAFEATURENAPROTEIN_FK04 foreign key (NA_PROTEIN_ID) references @oracle_dots@.NAPROTEIN (NA_PROTEIN_ID);
alter table @oracle_dots@.NAFEATURENAPROTEIN add constraint NAFEATURENAPROTEIN_FK05 foreign key (NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);

/* NAFEATURENAPT */
alter table @oracle_dots@.NAFEATURENAPT add constraint NAFEATURENAPT_FK05 foreign key (NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);
alter table @oracle_dots@.NAFEATURENAPT add constraint NAFEATURENAPT_FK06 foreign key (NA_PRIMARY_TRANSCRIPT_ID) references @oracle_dots@.NAPRIMARYTRANSCRIPT (NA_PRIMARY_TRANSCRIPT_ID);

/* NAFEATURERELATIONSHIP */
alter table @oracle_dots@.NAFEATURERELATIONSHIP add constraint NAFEATURERELATIONSHIP_FK05 foreign key (NA_FEAT_RELATIONSHIP_TYPE_ID) references @oracle_dots@.NAFEATRELATIONSHIPTYPE (NA_FEAT_RELATIONSHIP_TYPE_ID);
alter table @oracle_dots@.NAFEATURERELATIONSHIP add constraint NAFEATURERELATIONSHIP_FK06 foreign key (PARENT_NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);
alter table @oracle_dots@.NAFEATURERELATIONSHIP add constraint NAFEATURERELATIONSHIP_FK07 foreign key (CHILD_NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);

/* NAGENE */

/* NALOCATION */
alter table @oracle_dots@.NALOCATION add constraint NALOCATION_FK04 foreign key (NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);

/* NAPRIMARYTRANSCRIPT */
alter table @oracle_dots@.NAPRIMARYTRANSCRIPT add constraint NAPRIMARYTRANSCRIPT_FK04 foreign key (NA_GENE_ID) references @oracle_dots@.NAGENE (NA_GENE_ID);

/* NAPROTEIN */
alter table @oracle_dots@.NAPROTEIN add constraint NAPROTEIN_FK04 foreign key (NA_PRIMARY_TRANSCRIPT_ID) references @oracle_dots@.NAPRIMARYTRANSCRIPT (NA_PRIMARY_TRANSCRIPT_ID);

/* NASEQCYTOLOCATION */
alter table @oracle_dots@.NASEQCYTOLOCATION add constraint NASEQCYTOLOCATION foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* NASEQUENCEIMP */
alter table @oracle_dots@.NASEQUENCEIMP add constraint NASEQUENCEIMP_FK01 foreign key (SEQUENCE_TYPE_ID) references @oracle_dots@.SEQUENCETYPE (SEQUENCE_TYPE_ID);
alter table @oracle_dots@.NASEQUENCEIMP add constraint NASEQUENCEIMP_FK02 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_dots@.NASEQUENCEIMP add constraint NASEQUENCEIMP_FK03 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.NASEQUENCEIMP add constraint NASEQUENCEIMP_FK05 foreign key (SEQUENCE_PIECE_ID) references @oracle_dots@.SEQUENCEPIECE (SEQUENCE_PIECE_ID);
alter table @oracle_dots@.NASEQUENCEIMP add constraint NASEQUENCEIMP_FK06 foreign key (SEQUENCING_CENTER_CONTACT_ID) references @oracle_sres@.CONTACT (CONTACT_ID);

/* NASEQUENCEKEYWORD */
alter table @oracle_dots@.NASEQUENCEKEYWORD add constraint NASEQUENCEKEYWORD_FK04 foreign key (KEYWORD_ID) references @oracle_dots@.KEYWORD (KEYWORD_ID);
alter table @oracle_dots@.NASEQUENCEKEYWORD add constraint NASEQUENCEKEYWORD_FK05 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* NASEQUENCEORGANELLE */
alter table @oracle_dots@.NASEQUENCEORGANELLE add constraint NASEQUENCEORGANELLE_FK04 foreign key (ORGANELLE_ID) references @oracle_dots@.ORGANELLE (ORGANELLE_ID);
alter table @oracle_dots@.NASEQUENCEORGANELLE add constraint NASEQUENCEORGANELLE_FK05 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* NASEQUENCEREF */
alter table @oracle_dots@.NASEQUENCEREF add constraint NASEQUENCEREF_FK01 foreign key (REFERENCE_ID) references @oracle_sres@.REFERENCE (REFERENCE_ID);
alter table @oracle_dots@.NASEQUENCEREF add constraint NASEQUENCEREF_FK05 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* NRDBENTRY */
alter table @oracle_dots@.NRDBENTRY add constraint NRDBENTRY_FK01 foreign key (AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);
alter table @oracle_dots@.NRDBENTRY add constraint NRDBENTRY_FK02 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.NRDBENTRY add constraint NRDBENTRY_FK03 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);

/* OPTICALMAP */
alter table @oracle_dots@.OPTICALMAP add constraint OPTICALMAP_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.OPTICALMAP add constraint OPTICALMAP_FK02 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);

/* OPTICALMAPALIGNMENT */
alter table @oracle_dots@.OPTICALMAPALIGNMENT add constraint OPTICALMAPALIGNMENT_FK01 foreign key (OPTICAL_MAP_ID) references @oracle_dots@.OPTICALMAP (OPTICAL_MAP_ID);
alter table @oracle_dots@.OPTICALMAPALIGNMENT add constraint OPTICALMAPALIGNMENT_FK02 foreign key (NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.OPTICALMAPALIGNMENT add constraint OPTICALMAPALIGNMENT_FK03 foreign key (ALGORITHM_ID) references @oracle_core@.ALGORITHM (ALGORITHM_ID);

/* OPTICALMAPALIGNMENTSPAN */
alter table @oracle_dots@.OPTICALMAPALIGNMENTSPAN add constraint OPTICALMAPALIGNMENTSPAN_FK01 foreign key (OPTICAL_MAP_ALIGNMENT_ID) references @oracle_dots@.OPTICALMAPALIGNMENT (OPTICAL_MAP_ALIGNMENT_ID);
alter table @oracle_dots@.OPTICALMAPALIGNMENTSPAN add constraint OPTICALMAPALIGNMENTSPAN_FK02 foreign key (OPTICAL_MAP_FRAGMENT_ID) references @oracle_dots@.OPTICALMAPFRAGMENT (OPTICAL_MAP_FRAGMENT_ID);
alter table @oracle_dots@.OPTICALMAPALIGNMENTSPAN add constraint OPTICALMAPALIGNMENTSPAN_FK03 foreign key (NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);

/* OPTICALMAPFRAGMENT */
alter table @oracle_dots@.OPTICALMAPFRAGMENT add constraint OPTICALMAPFRAGMENT_FK01 foreign key (OPTICAL_MAP_ID) references @oracle_dots@.OPTICALMAP (OPTICAL_MAP_ID);

/* ORGANELLE */

/* PATHWAY */
alter table @oracle_dots@.PATHWAY add constraint PATHWAY_FK04 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* PATHWAYINTERACTION */
alter table @oracle_dots@.PATHWAYINTERACTION add constraint PATHWAYINTERACTION_FK04 foreign key (PATHWAY_ID) references @oracle_dots@.PATHWAY (PATHWAY_ID);
alter table @oracle_dots@.PATHWAYINTERACTION add constraint PATHWAYINTERACTION_FK06 foreign key (INTERACTION_ID) references @oracle_dots@.INTERACTION (INTERACTION_ID);

/* PFAMENTRY */

/* PLASMOMAP */
alter table @oracle_dots@.PLASMOMAP add constraint PLASMOMAP_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.PLASMOMAP add constraint PLASMOMAP_FK02 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);

/* PROJECTLINK */
alter table @oracle_dots@.PROJECTLINK add constraint PROJECTLINK_FK04 foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.PROJECTLINK add constraint PROJECTLINK_FK05 foreign key (PROJECT_ID) references @oracle_core@.PROJECTINFO (PROJECT_ID);

/* PROTEIN */
alter table @oracle_dots@.PROTEIN add constraint PROTEIN_FK01 foreign key (RNA_ID) references @oracle_dots@.RNA (RNA_ID);
alter table @oracle_dots@.PROTEIN add constraint PROTEIN_FK06 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* PROTEINCATEGORY */

/* PROTEININSTANCE */
alter table @oracle_dots@.PROTEININSTANCE add constraint PROTEININSTANCE_FK01 foreign key (PROTEIN_INSTANCE_CATEGORY_ID) references @oracle_dots@.PROTEININSTANCECATEGORY (PROTEIN_INSTANCE_CATEGORY_ID);
alter table @oracle_dots@.PROTEININSTANCE add constraint PROTEININSTANCE_FK02 foreign key (PROTEIN_ID) references @oracle_dots@.PROTEIN (PROTEIN_ID);
alter table @oracle_dots@.PROTEININSTANCE add constraint PROTEININSTANCE_FK03 foreign key (AA_FEATURE_ID) references @oracle_dots@.AAFEATUREIMP (AA_FEATURE_ID);
alter table @oracle_dots@.PROTEININSTANCE add constraint PROTEININSTANCE_FK04 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* PROTEININSTANCECATEGORY */

/* PROTEINPROPERTY */
alter table @oracle_dots@.PROTEINPROPERTY add constraint PROTEINPROPERTY_FK01 foreign key (AA_SEQUENCE_ID) references @oracle_dots@.AASEQUENCEIMP (AA_SEQUENCE_ID);
alter table @oracle_dots@.PROTEINPROPERTY add constraint PROTEINPROPERTY_FK02 foreign key (PROTEIN_PROPERTY_TYPE_ID) references @oracle_dots@.PROTEINPROPERTYTYPE (PROTEIN_PROPERTY_TYPE_ID);
alter table @oracle_dots@.PROTEINPROPERTY add constraint PROTEINPROPERTY_FK03 foreign key (PREDICTION_ALGORITHM_ID) references @oracle_core@.ALGORITHM (ALGORITHM_ID);
alter table @oracle_dots@.PROTEINPROPERTY add constraint PROTEINPROPERTY_FK04 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);
alter table @oracle_dots@.PROTEINPROPERTY add constraint PROTEINPROPERTY_FK05 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* PROTEINPROPERTYTYPE */

/* PROTEINPROTEINCATEGORY */
alter table @oracle_dots@.PROTEINPROTEINCATEGORY add constraint PROTEINPROTEINCATEGORY_FK01 foreign key (PROTEIN_ID) references @oracle_dots@.PROTEIN (PROTEIN_ID);
alter table @oracle_dots@.PROTEINPROTEINCATEGORY add constraint PROTEINPROTEINCATEGORY_FK02 foreign key (PROTEIN_CATEGORY_ID) references @oracle_dots@.PROTEINCATEGORY (PROTEIN_CATEGORY_ID);

/* PROTEINSYNONYM */
alter table @oracle_dots@.PROTEINSYNONYM add constraint PROTEINSYNONYM_FK04 foreign key (PROTEIN_ID) references @oracle_dots@.PROTEIN (PROTEIN_ID);
alter table @oracle_dots@.PROTEINSYNONYM add constraint PROTEINSYNONYM_FK05 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* REPEATTYPE */
alter table @oracle_dots@.REPEATTYPE add constraint REPEATTYPE_FK04 foreign key (PARENT_ID) references @oracle_dots@.REPEATTYPE (REPEAT_TYPE_ID);
alter table @oracle_dots@.REPEATTYPE add constraint REPEATTYPE_FK05 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_dots@.REPEATTYPE add constraint REPEATTYPE_FK06 foreign key (EXEMPLAR_NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* RHMAP */
alter table @oracle_dots@.RHMAP add constraint RHMAP_FK foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_dots@.RHMAP add constraint RHMAP_FK05 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* RHMAPMARKER */
alter table @oracle_dots@.RHMAPMARKER add constraint RHMAPMARKER_FK04 foreign key (RH_MARKER_ID) references @oracle_dots@.RHMARKER (RH_MARKER_ID);
alter table @oracle_dots@.RHMAPMARKER add constraint RHMAPMARKER_FK05 foreign key (RH_MAP_ID) references @oracle_dots@.RHMAP (RH_MAP_ID);

/* RHMARKER */
alter table @oracle_dots@.RHMARKER add constraint RHMARKER_FK04 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);
alter table @oracle_dots@.RHMARKER add constraint RHMARKER_FK05 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* RNA */
alter table @oracle_dots@.RNA add constraint RNA_FK04 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);
alter table @oracle_dots@.RNA add constraint RNA_FK05 foreign key (GENE_ID) references @oracle_dots@.GENE (GENE_ID);

/* RNAANATOMY */
alter table @oracle_dots@.RNAANATOMY add constraint RNAANATOMY_FK04 foreign key (ANATOMY_ID) references @oracle_sres@.ANATOMY (ANATOMY_ID);
alter table @oracle_dots@.RNAANATOMY add constraint RNAANATOMY_FK05 foreign key (RNA_ID) references @oracle_dots@.RNA (RNA_ID);

/* RNAANATOMYLOE */
alter table @oracle_dots@.RNAANATOMYLOE add constraint RNAANATOMYLOE_FK04 foreign key (ANATOMY_LOE_ID) references @oracle_dots@.ANATOMYLOE (ANATOMY_LOE_ID);
alter table @oracle_dots@.RNAANATOMYLOE add constraint RNAANATOMYLOE_FK05 foreign key (RNA_ANATOMY_ID) references @oracle_dots@.RNAANATOMY (RNA_ANATOMY_ID);

/* RNACATEGORY */

/* RNAFEATUREEXON */
alter table @oracle_dots@.RNAFEATUREEXON add constraint RNAFEATUREEXON_FK01 foreign key (RNA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);
alter table @oracle_dots@.RNAFEATUREEXON add constraint RNAFEATUREEXON_FK02 foreign key (EXON_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);

/* RNAICONSTRUCT */
alter table @oracle_dots@.RNAICONSTRUCT add constraint RNAICONSTRUCT_FK01 foreign key (RNA_ID) references @oracle_dots@.RNA (RNA_ID);
alter table @oracle_dots@.RNAICONSTRUCT add constraint RNAICONSTRUCT_FK02 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* RNAINSTANCE */
alter table @oracle_dots@.RNAINSTANCE add constraint RNAINSTANCES_FK02 foreign key (NA_FEATURE_ID) references @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID);
alter table @oracle_dots@.RNAINSTANCE add constraint RNAINSTANCE_FK01 foreign key (RNA_ID) references @oracle_dots@.RNA (RNA_ID);
alter table @oracle_dots@.RNAINSTANCE add constraint RNAINSTANCE_FK03 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);
alter table @oracle_dots@.RNAINSTANCE add constraint RNAINSTANCE_FK04 foreign key (RNA_INSTANCE_CATEGORY_ID) references @oracle_dots@.RNAINSTANCECATEGORY (RNA_INSTANCE_CATEGORY_ID);

/* RNAINSTANCECATEGORY */

/* RNAIPHENOTYPE */
alter table @oracle_dots@.RNAIPHENOTYPE add constraint RNAIPHENOTYPE_FK01 foreign key (RNAI_CONSTRUCT_ID) references @oracle_dots@.RNAICONSTRUCT (RNAI_CONSTRUCT_ID);
alter table @oracle_dots@.RNAIPHENOTYPE add constraint RNAIPHENOTYPE_FK02 foreign key (PHENOTYPE_ID) references @oracle_sres@.PHENOTYPE (PHENOTYPE_ID);
alter table @oracle_dots@.RNAIPHENOTYPE add constraint RNAIPHENOTYPE_FK03 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* RNARNACATEGORY */
alter table @oracle_dots@.RNARNACATEGORY add constraint RNARNACATEGORY_FK05 foreign key (RNA_CATEGORY_ID) references @oracle_dots@.RNACATEGORY (RNA_CATEGORY_ID);
alter table @oracle_dots@.RNARNACATEGORY add constraint RNARNACATEGORY_FK06 foreign key (RNA_ID) references @oracle_dots@.RNA (RNA_ID);

/* ROWSET */

/* ROWSETMEMBER */
alter table @oracle_dots@.ROWSETMEMBER add constraint ROWSETMEMBER_FK01 foreign key (ROW_SET_ID) references @oracle_dots@.ROWSET (ROW_SET_ID);
alter table @oracle_dots@.ROWSETMEMBER add constraint ROWSETMEMBER_FK02 foreign key (TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* SECONDARYACCS */
alter table @oracle_dots@.SECONDARYACCS add constraint SECONDARYACCS_FK04 foreign key (AA_ENTRY_ID) references @oracle_dots@.AAENTRY (AA_ENTRY_ID);
alter table @oracle_dots@.SECONDARYACCS add constraint SECONDARYACCS_FK05 foreign key (NA_ENTRY_ID) references @oracle_dots@.NAENTRY (NA_ENTRY_ID);
alter table @oracle_dots@.SECONDARYACCS add constraint SECONDARYACCS_FK06 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* SEQGROUPEXPERIMENTIMP */
alter table @oracle_dots@.SEQGROUPEXPERIMENTIMP add constraint SEQGROUPEXPERIMENTIMP_FK05 foreign key (ALGORITHM_ID) references @oracle_core@.ALGORITHM (ALGORITHM_ID);

/* SEQUENCEFAMILY */
alter table @oracle_dots@.SEQUENCEFAMILY add constraint SEQUENCEFAMILY_FK05 foreign key (SEQUENCE_FAMILY_EXPERIMENT_ID) references @oracle_dots@.SEQUENCEFAMILYEXPERIMENT (SEQUENCE_FAMILY_EXPERIMENT_ID);

/* SEQUENCEFAMILYEXPERIMENT */
alter table @oracle_dots@.SEQUENCEFAMILYEXPERIMENT add constraint SEQUENCEFAMILYEXPERIMENT_FK05 foreign key (ORTHOLOG_EXPERIMENT_ID) references @oracle_dots@.SEQGROUPEXPERIMENTIMP (SEQ_GROUP_EXPERIMENT_ID);
alter table @oracle_dots@.SEQUENCEFAMILYEXPERIMENT add constraint SEQUENCEFAMILYEXPERIMENT_FK06 foreign key (IN_PARALOG_EXPERIMENT_ID) references @oracle_dots@.SEQGROUPEXPERIMENTIMP (SEQ_GROUP_EXPERIMENT_ID);
alter table @oracle_dots@.SEQUENCEFAMILYEXPERIMENT add constraint SEQUENCEFAMILYEXPERIMENT_FK07 foreign key (OUT_PARALOG_EXPERIMENT_ID) references @oracle_dots@.SEQGROUPEXPERIMENTIMP (SEQ_GROUP_EXPERIMENT_ID);

/* SEQUENCEGROUPFAMILY */
alter table @oracle_dots@.SEQUENCEGROUPFAMILY add constraint SEQUENCEGROUPFAMILY_FK05 foreign key (SEQUENCE_FAMILY_ID) references @oracle_dots@.SEQUENCEFAMILY (SEQUENCE_FAMILY_ID);
alter table @oracle_dots@.SEQUENCEGROUPFAMILY add constraint SEQUENCEGROUPFAMILY_FK06 foreign key (SEQUENCE_GROUP_ID) references @oracle_dots@.SEQUENCEGROUPIMP (SEQUENCE_GROUP_ID);

/* SEQUENCEGROUPIMP */
alter table @oracle_dots@.SEQUENCEGROUPIMP add constraint SEQUENCEGROUPIMP_FK05 foreign key (SEQUENCE_GROUP_EXPERIMENT_ID) references @oracle_dots@.SEQGROUPEXPERIMENTIMP (SEQ_GROUP_EXPERIMENT_ID);

/* SEQUENCEPIECE */
alter table @oracle_dots@.SEQUENCEPIECE add constraint SEQUENCEPIECE_FK04 foreign key (PIECE_NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);
alter table @oracle_dots@.SEQUENCEPIECE add constraint SEQUENCEPIECE_FK06 foreign key (VIRTUAL_NA_SEQUENCE_ID) references @oracle_dots@.NASEQUENCEIMP (NA_SEQUENCE_ID);

/* SEQUENCESEQUENCEGROUP */
alter table @oracle_dots@.SEQUENCESEQUENCEGROUP add constraint SEQUENCESEQUENCEGROUP_FK05 foreign key (SOURCE_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.SEQUENCESEQUENCEGROUP add constraint SEQUENCESEQUENCEGROUP_FK06 foreign key (SEQUENCE_GROUP_ID) references @oracle_dots@.SEQUENCEGROUPIMP (SEQUENCE_GROUP_ID);

/* SEQUENCETYPE */
alter table @oracle_dots@.SEQUENCETYPE add constraint SEQUENCETYPE_FK foreign key (PARENT_SEQUENCE_TYPE_ID) references @oracle_dots@.SEQUENCETYPE (SEQUENCE_TYPE_ID);

/* SIMILARITY */
alter table @oracle_dots@.SIMILARITY add constraint SIMILARITY_FK01 foreign key (ALGORITHM_ID) references @oracle_core@.ALGORITHM (ALGORITHM_ID);
alter table @oracle_dots@.SIMILARITY add constraint SIMILARITY_FK04 foreign key (QUERY_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_dots@.SIMILARITY add constraint SIMILARITY_FK05 foreign key (SUBJECT_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);

/* SIMILARITYSPAN */
alter table @oracle_dots@.SIMILARITYSPAN add constraint SIMILARITYSPAN_FK03 foreign key (SIMILARITY_ID) references @oracle_dots@.SIMILARITY (SIMILARITY_ID);

/* TRANSLATEDAAFEATSEG */
alter table @oracle_dots@.TRANSLATEDAAFEATSEG add constraint TRANSLATEDAAFEATSEG_FK01 foreign key (AA_FEATURE_ID) references @oracle_dots@.AAFEATUREIMP (AA_FEATURE_ID);



/* 316 non-primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

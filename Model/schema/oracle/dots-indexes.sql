
/*                                                                                            */
/* dots-indexes.sql                                                                           */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Feb 17 11:45:25 EST 2004     */
/*                                                                                            */

SET ECHO ON
SPOOL dots-indexes.log

/* AACOMMENT */
create index @oracle_dots@.AACOMMENT_IND01 on @oracle_dots@.AACOMMENT (COMMENT_NAME_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AACOMMENT_IND02 on @oracle_dots@.AACOMMENT (AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AAENTRY */
create index @oracle_dots@.AAENTRY_IND01 on @oracle_dots@.AAENTRY (AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create unique index @oracle_dots@.AAENTRY_IND02 on @oracle_dots@.AAENTRY (SOURCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AAFAMILYEXPERIMENT */
create index @oracle_dots@.AAFAMILYEXPERIMENT_IND01 on @oracle_dots@.AAFAMILYEXPERIMENT (AA_ORTHOLOG_EXPERIMENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFAMILYEXPERIMENT_IND02 on @oracle_dots@.AAFAMILYEXPERIMENT (AA_PARALOG_EXPERIMENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AAFEATUREIMP */
create index @oracle_dots@.AAFEATUREIMP_IND08 on @oracle_dots@.AAFEATUREIMP (PREDICTION_ALGORITHM_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFEATUREIMP_IND09 on @oracle_dots@.AAFEATUREIMP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFEATUREIMP_IND01 on @oracle_dots@.AAFEATUREIMP (AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFEATUREIMP_IND02 on @oracle_dots@.AAFEATUREIMP (FEATURE_NAME_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EPITOPEFEATURE_IND01 on @oracle_dots@.AAFEATUREIMP (STRING1,FLOAT1,FLOAT2)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFEATUREIMP_IND04 on @oracle_dots@.AAFEATUREIMP (NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFEATUREIMP_IND06 on @oracle_dots@.AAFEATUREIMP (INT1)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFEATUREIMP_IND10 on @oracle_dots@.AAFEATUREIMP (PFAM_ENTRY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFEATUREIMP_IND11 on @oracle_dots@.AAFEATUREIMP (MOTIF_AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFEATUREIMP_IND12 on @oracle_dots@.AAFEATUREIMP (REPEAT_TYPE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFEATUREIMP_IND05 on @oracle_dots@.AAFEATUREIMP (SUBCLASS_VIEW)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFEATUREIMP_IND07 on @oracle_dots@.AAFEATUREIMP (AA_SEQUENCE_ID,SUBCLASS_VIEW)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFEATUREIMP_IND13 on @oracle_dots@.AAFEATUREIMP (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFEATUREIMP_IND14 on @oracle_dots@.AAFEATUREIMP (PARENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAFEATUREIMP_IND15 on @oracle_dots@.AAFEATUREIMP (SEQUENCE_ONTOLOGY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AAGENE */
create index @oracle_dots@.AAGENE_IND01 on @oracle_dots@.AAGENE (AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AAGENESYNONYM */
create index @oracle_dots@.AAGENESYNONYM_IND01 on @oracle_dots@.AAGENESYNONYM (AA_GENE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AALOCATION */
create index @oracle_dots@.AALOCATION_IND01 on @oracle_dots@.AALOCATION (AA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AAMOTIFGOTERMRULE */
create index @oracle_dots@.AAMOTIFGOTERMRULE_IND01 on @oracle_dots@.AAMOTIFGOTERMRULE (AA_MOTIF_GO_TERM_RULE_SET_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAMOTIFGOTERMRULE_IND02 on @oracle_dots@.AAMOTIFGOTERMRULE (GO_TERM_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAMOTIFGOTERMRULE_IND03 on @oracle_dots@.AAMOTIFGOTERMRULE (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAMOTIFGOTERMRULE_IND04 on @oracle_dots@.AAMOTIFGOTERMRULE (REVIEWER_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAMOTIFGOTERMRULE_IND05 on @oracle_dots@.AAMOTIFGOTERMRULE (DEFINING)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAMOTIFGOTERMRULE_IND06 on @oracle_dots@.AAMOTIFGOTERMRULE (AA_MOTIF_GO_TERM_RULE_ID,AA_MOTIF_GO_TERM_RULE_SET_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAMOTIFGOTERMRULE_IND07 on @oracle_dots@.AAMOTIFGOTERMRULE (DEFINING,AA_MOTIF_GO_TERM_RULE_SET_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AAMOTIFGOTERMRULESET */
create index @oracle_dots@.AAMOTIFGOTERMRULESET_IND01 on @oracle_dots@.AAMOTIFGOTERMRULESET (AA_SEQUENCE_ID_1)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAMOTIFGOTERMRULESET_IND02 on @oracle_dots@.AAMOTIFGOTERMRULESET (AA_SEQUENCE_ID_2)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAMOTIFGOTERMRULESET_IND03 on @oracle_dots@.AAMOTIFGOTERMRULESET (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AAMOTIFGOTERMRULESET_IND04 on @oracle_dots@.AAMOTIFGOTERMRULESET (REVIEWER_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AASEQGROUPEXPERIMENTIMP */


/* AASEQUENCEDBREF */
create index @oracle_dots@.AASEQUENCEDBREF_IND01 on @oracle_dots@.AASEQUENCEDBREF (DB_REF_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCEDBREF_IND02 on @oracle_dots@.AASEQUENCEDBREF (AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AASEQUENCEENZYMECLASS */
create index @oracle_dots@.AASEQUENCEENZYMECLASS_AASEQ on @oracle_dots@.AASEQUENCEENZYMECLASS (AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCEENZYMECLASS_EC on @oracle_dots@.AASEQUENCEENZYMECLASS (ENZYME_CLASS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCEENZYMECLASS_IND01 on @oracle_dots@.AASEQUENCEENZYMECLASS (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AASEQUENCEFAMILY */
create index @oracle_dots@.AASEQUENCEFAMILY_IND01 on @oracle_dots@.AASEQUENCEFAMILY (AA_FAMILY_EXPERIMENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AASEQUENCEGROUPFAMILY */
create index @oracle_dots@.AASEQUENCEGROUPFAMILY_IND01 on @oracle_dots@.AASEQUENCEGROUPFAMILY (AA_SEQUENCE_FAMILY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCEGROUPFAMILY_IND02 on @oracle_dots@.AASEQUENCEGROUPFAMILY (AA_SEQUENCE_GROUP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AASEQUENCEGROUPIMP */
create index @oracle_dots@.AASEQUENCEGROUPIMP_IND01 on @oracle_dots@.AASEQUENCEGROUPIMP (AA_SEQ_GROUP_EXPERIMENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AASEQUENCEIMP */
create index @oracle_dots@.AASEQUENCEIMP_IND03 on @oracle_dots@.AASEQUENCEIMP (SOURCE_AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCEIMP_IND04 on @oracle_dots@.AASEQUENCEIMP (SUBCLASS_VIEW,STRING1,EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCEIMP_IND05 on @oracle_dots@.AASEQUENCEIMP (SUBCLASS_VIEW,SOURCE_ID,EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCEIMP_IND06 on @oracle_dots@.AASEQUENCEIMP (SUBCLASS_VIEW,AA_SEQUENCE_ID,SEQUENCE_VERSION)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCEIMP_IND02 on @oracle_dots@.AASEQUENCEIMP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCEIMP_IND08 on @oracle_dots@.AASEQUENCEIMP (SUBCLASS_VIEW,SOURCE_ID,STRING2)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AASEQUENCEKEYWORD */
create index @oracle_dots@.AASEQUENCEKEYWORD_IND01 on @oracle_dots@.AASEQUENCEKEYWORD (KEYWORD_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCEKEYWORD_IND02 on @oracle_dots@.AASEQUENCEKEYWORD (AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AASEQUENCEORGANELLE */
create index @oracle_dots@.AASEQUENCEORGANELLE_IND01 on @oracle_dots@.AASEQUENCEORGANELLE (ORGANELLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCEORGANELLE_IND02 on @oracle_dots@.AASEQUENCEORGANELLE (AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AASEQUENCEREF */
create index @oracle_dots@.AASEQUENCEREF_IND01 on @oracle_dots@.AASEQUENCEREF (AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCEREF_IND02 on @oracle_dots@.AASEQUENCEREF (REFERENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AASEQUENCESEQUENCEGROUP */
create index @oracle_dots@.AASEQUENCESEQUENCEGROUP_IND01 on @oracle_dots@.AASEQUENCESEQUENCEGROUP (AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCESEQUENCEGROUP_IND02 on @oracle_dots@.AASEQUENCESEQUENCEGROUP (AA_SEQUENCE_GROUP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* AASEQUENCETAXON */
create index @oracle_dots@.AASEQUENCETAXON_IND01 on @oracle_dots@.AASEQUENCETAXON (TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.AASEQUENCETAXON_IND02 on @oracle_dots@.AASEQUENCETAXON (AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ALLELE */
create index @oracle_dots@.ALLELE_IND01 on @oracle_dots@.ALLELE (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ALLELE_IND02 on @oracle_dots@.ALLELE (GENE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ALLELE_IND03 on @oracle_dots@.ALLELE (MUTAGEN_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ALLELECOMPLEMENTATION */
create index @oracle_dots@.ALLELECOMPLEMENTATION_IND01 on @oracle_dots@.ALLELECOMPLEMENTATION (COMPLEMENTATION_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ALLELECOMPLEMENTATION_IND02 on @oracle_dots@.ALLELECOMPLEMENTATION (ALLELE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ALLELECOMPLEMENTATION_IND03 on @oracle_dots@.ALLELECOMPLEMENTATION (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ALLELEINSTANCE */
create index @oracle_dots@.ALLELEINSTANCE_IND01 on @oracle_dots@.ALLELEINSTANCE (NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ALLELEINSTANCE_IND02 on @oracle_dots@.ALLELEINSTANCE (ALLELE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ALLELEINSTANCE_IND03 on @oracle_dots@.ALLELEINSTANCE (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ALLELEPHENOTYPE */
create index @oracle_dots@.ALLELEPHENOTYPE_IND01 on @oracle_dots@.ALLELEPHENOTYPE (PHENOTYPE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ALLELEPHENOTYPE_IND02 on @oracle_dots@.ALLELEPHENOTYPE (ALLELE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ALLELEPHENOTYPE_IND03 on @oracle_dots@.ALLELEPHENOTYPE (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ALLELEPHENOTYPECLASS */
create index @oracle_dots@.ALLELEPHENOTYPECLASS_IND01 on @oracle_dots@.ALLELEPHENOTYPECLASS (PHENOTYPE_CLASS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ALLELEPHENOTYPECLASS_IND02 on @oracle_dots@.ALLELEPHENOTYPECLASS (ALLELE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ALLELEPHENOTYPECLASS_IND03 on @oracle_dots@.ALLELEPHENOTYPECLASS (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ANATOMYLIBRARY */
create index @oracle_dots@.ANATOMYLIBRARY_IND02 on @oracle_dots@.ANATOMYLIBRARY (DBEST_LIBRARY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ANATOMYLIBRARY_IND01 on @oracle_dots@.ANATOMYLIBRARY (ANATOMY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ANATOMYLOE */


/* ASSEMBLYANATOMYPERCENT */
create index @oracle_dots@.ASSEMBLYANATOMYPERCENT_IND01 on @oracle_dots@.ASSEMBLYANATOMYPERCENT (ANATOMY_ID,PERCENT,EST_COUNT,TAXON_ID,NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ASSEMBLYANATOMYPERCENT_IND03 on @oracle_dots@.ASSEMBLYANATOMYPERCENT (TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ASSEMBLYANATOMYPERCENT_IND02 on @oracle_dots@.ASSEMBLYANATOMYPERCENT (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ASSEMBLYSEQUENCE */
create index @oracle_dots@.ASSEMBLYSEQUENCE_IND01 on @oracle_dots@.ASSEMBLYSEQUENCE (ASSEMBLY_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ASSEMBLYSEQUENCE_IND02 on @oracle_dots@.ASSEMBLYSEQUENCE (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ASSEMBLYSEQUENCESNP */
create index @oracle_dots@.ASSEMBLYSEQUENCESNP_IND01 on @oracle_dots@.ASSEMBLYSEQUENCESNP (ASSEMBLY_SNP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ASSEMBLYSEQUENCESNP_IND02 on @oracle_dots@.ASSEMBLYSEQUENCESNP (ASSEMBLY_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ASSEMBLYSNP */
create index @oracle_dots@.ASSEMBLYSNP_IND01 on @oracle_dots@.ASSEMBLYSNP (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ATTRIBUTION */
create index @oracle_dots@.ATTRIBUTION_IND01 on @oracle_dots@.ATTRIBUTION (TABLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ATTRIBUTION_IND02 on @oracle_dots@.ATTRIBUTION (CONTACT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* BESTSIMILARITYPAIR */
create index @oracle_dots@.BESTSIMILARITYPAIR_IND01 on @oracle_dots@.BESTSIMILARITYPAIR (SOURCE_TABLE_ID,SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.BESTSIMILARITYPAIR_IND02 on @oracle_dots@.BESTSIMILARITYPAIR (PAIRED_SOURCE_TABLE_ID,PAIRED_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.BESTSIMILARITYPAIR_IND03 on @oracle_dots@.BESTSIMILARITYPAIR (ORTHOLOG_EXPERIMENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* BLATALIGNMENT */
create index @oracle_dots@.BLATALIGNMENT_IND04 on @oracle_dots@.BLATALIGNMENT (TARGET_NA_SEQUENCE_ID,TARGET_START,TARGET_END)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.BLATALIGNMENT_IND05 on @oracle_dots@.BLATALIGNMENT (QUERY_TABLE_ID,QUERY_TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.BLATALIGNMENT_IND02 on @oracle_dots@.BLATALIGNMENT (TARGET_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.BLATALIGNMENT_IND01 on @oracle_dots@.BLATALIGNMENT (QUERY_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.BLATALIGNMENT_IND03 on @oracle_dots@.BLATALIGNMENT (QUERY_TAXON_ID,QUERY_TABLE_ID,IS_CONSISTENT,QUERY_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.BLATALIGNMENT_IND06 on @oracle_dots@.BLATALIGNMENT (TARGET_TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.BLATALIGNMENT_IND07 on @oracle_dots@.BLATALIGNMENT (TARGET_EXTERNAL_DB_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.BLATALIGNMENT_IND09 on @oracle_dots@.BLATALIGNMENT (QUERY_EXTERNAL_DB_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.BLATALIGNMENT_IND10 on @oracle_dots@.BLATALIGNMENT (TARGET_TABLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* BLATALIGNMENTQUALITY */


/* CLONE */
create index @oracle_dots@.CLONE_IND01 on @oracle_dots@.CLONE (DBEST_CLONE_UID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.CLONE_IND02 on @oracle_dots@.CLONE (LIBRARY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.CLONE_IND03 on @oracle_dots@.CLONE (IMAGE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.CLONE_IND04 on @oracle_dots@.CLONE (WASHU_NAME)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.CLONE_IND05 on @oracle_dots@.CLONE (DBEST_CLONE_UID,WASHU_NAME)  TABLESPACE @oracle_dotsIndexTablespace@;

/* CLONEINSET */
create index @oracle_dots@.CLONEINSET_IND02 on @oracle_dots@.CLONEINSET (CLONE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.CLONEINSET_IND01 on @oracle_dots@.CLONEINSET (CLONE_SET_ID,CLONE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* CLONESET */
create index @oracle_dots@.CLONESET_IND01 on @oracle_dots@.CLONESET (CONTACT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* COMMENTNAME */
create unique index @oracle_dots@.COMMENTNAME_IND01 on @oracle_dots@.COMMENTNAME (NAME)  TABLESPACE @oracle_dotsIndexTablespace@;

/* COMMENTS */
create index @oracle_dots@.COMMENTS_IND01 on @oracle_dots@.COMMENTS (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* COMPLEMENTATION */
create index @oracle_dots@.COMPLEMENTATION_IND01 on @oracle_dots@.COMPLEMENTATION (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.COMPLEMENTATION_IND02 on @oracle_dots@.COMPLEMENTATION (TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.COMPLEMENTATION_IND03 on @oracle_dots@.COMPLEMENTATION (TABLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.COMPLEMENTATION_IND04 on @oracle_dots@.COMPLEMENTATION (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* COMPLEX */
create index @oracle_dots@.COMPLEX_IND01 on @oracle_dots@.COMPLEX (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.COMPLEX_IND02 on @oracle_dots@.COMPLEX (COMPLEX_TYPE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.COMPLEX_IND03 on @oracle_dots@.COMPLEX (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* COMPLEXANATOMY */
create index @oracle_dots@.COMPLEXANATOMY_IND01 on @oracle_dots@.COMPLEXANATOMY (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.COMPLEXANATOMY_IND02 on @oracle_dots@.COMPLEXANATOMY (ANATOMY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.COMPLEXANATOMY_IND03 on @oracle_dots@.COMPLEXANATOMY (COMPLEX_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* COMPLEXCOMPONENT */
create index @oracle_dots@.COMPLEXCOMPONENT_IND01 on @oracle_dots@.COMPLEXCOMPONENT (TABLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.COMPLEXCOMPONENT_IND02 on @oracle_dots@.COMPLEXCOMPONENT (COMPLEX_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* COMPLEXTYPE */


/* CONSISTENTALIGNMENT */
create index @oracle_dots@.CONSISTENTALIGNMENT_IND01 on @oracle_dots@.CONSISTENTALIGNMENT (TRANSCRIPT_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.CONSISTENTALIGNMENT_IND02 on @oracle_dots@.CONSISTENTALIGNMENT (GENOMIC_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.CONSISTENTALIGNMENT_IND03 on @oracle_dots@.CONSISTENTALIGNMENT (SIMILARITY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.CONSISTENTALIGNMENT_IND04 on @oracle_dots@.CONSISTENTALIGNMENT (NUMBER_OF_SPANS,TRANSCRIPT_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* DBREFNAFEATURE */
create index @oracle_dots@.DBREFNAFEATURE_IND02 on @oracle_dots@.DBREFNAFEATURE (DB_REF_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.DBREFNAFEATURE_IND01 on @oracle_dots@.DBREFNAFEATURE (NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* DBREFNASEQUENCE */
create index @oracle_dots@.DBREFNASEQUENCE_IND03 on @oracle_dots@.DBREFNASEQUENCE (DB_REF_ID,NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.DBREFNASEQUENCE_IND01 on @oracle_dots@.DBREFNASEQUENCE (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.DBREFNASEQUENCE_IND02 on @oracle_dots@.DBREFNASEQUENCE (DB_REF_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* DBREFPFAMENTRY */
create index @oracle_dots@.DBREFPFAMENTRY_IND01 on @oracle_dots@.DBREFPFAMENTRY (DB_REF_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.DBREFPFAMENTRY_IND02 on @oracle_dots@.DBREFPFAMENTRY (PFAM_ENTRY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* EFFECTORACTIONTYPE */
create index @oracle_dots@.EFFECTORACTIONTYPE_IND01 on @oracle_dots@.EFFECTORACTIONTYPE (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ENDSEQUENCEPAIRMAP */
create index @oracle_dots@.ENDSEQUENCEPAIRMAP_IND01 on @oracle_dots@.ENDSEQUENCEPAIRMAP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ENDSEQUENCEPAIRMAP_IND02 on @oracle_dots@.ENDSEQUENCEPAIRMAP (TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ENDSEQUENCEPAIRMAP_IND03 on @oracle_dots@.ENDSEQUENCEPAIRMAP (NA_SEQUENCE_ID_1)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ENDSEQUENCEPAIRMAP_IND04 on @oracle_dots@.ENDSEQUENCEPAIRMAP (NA_SEQUENCE_ID_2)  TABLESPACE @oracle_dotsIndexTablespace@;

/* EPCR */
create index @oracle_dots@.EPCR_IND04 on @oracle_dots@.EPCR (SIMILARITY_ID_1)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EPCR_IND05 on @oracle_dots@.EPCR (SIMILARITY_ID_2)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EPCR_IND02 on @oracle_dots@.EPCR (MAP_TABLE_ID,MAP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EPCR_IND01 on @oracle_dots@.EPCR (NA_SEQUENCE_ID,START_POS,STOP_POS)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EPCR_IND03 on @oracle_dots@.EPCR (MAP_TABLE_ID,MAP_ID,NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* EST */
create index @oracle_dots@.EST_IND02 on @oracle_dots@.EST (CONTACT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EST_IND03 on @oracle_dots@.EST (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EST_IND04 on @oracle_dots@.EST (LIBRARY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EST_IND05 on @oracle_dots@.EST (DBEST_ID_EST)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EST_IND06 on @oracle_dots@.EST (ACCESSION)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EST_IND01 on @oracle_dots@.EST (CLONE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* EVIDENCE */
create index @oracle_dots@.EVIDENCE_IND01 on @oracle_dots@.EVIDENCE (FACT_ID,FACT_TABLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EVIDENCE_IND02 on @oracle_dots@.EVIDENCE (TARGET_ID,TARGET_TABLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EVIDENCE_IND03 on @oracle_dots@.EVIDENCE (FACT_TABLE_ID,TARGET_TABLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EVIDENCE_IND04 on @oracle_dots@.EVIDENCE (TARGET_TABLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.EVIDENCE_IND05 on @oracle_dots@.EVIDENCE (FACT_TABLE_ID,TARGET_TABLE_ID,FACT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* EXONLOCATION */
create index @oracle_dots@.EXONLOCATION_IND01 on @oracle_dots@.EXONLOCATION (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* FAMILY */
create index @oracle_dots@.FAMILY_IND01 on @oracle_dots@.FAMILY (PARENT_FAMILY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* FAMILYGENE */
create index @oracle_dots@.FAMILYGENE_IND01 on @oracle_dots@.FAMILYGENE (FAMILY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.FAMILYGENE_IND02 on @oracle_dots@.FAMILYGENE (GENE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* FAMILYPROTEIN */
create index @oracle_dots@.FAMILYPROTEIN_IND01 on @oracle_dots@.FAMILYPROTEIN (FAMILY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.FAMILYPROTEIN_IND02 on @oracle_dots@.FAMILYPROTEIN (PROTEIN_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* FEATURENAME */


/* FINGERPRINTCLONE */
create index @oracle_dots@.FINGERPRINTCLONE_IND01 on @oracle_dots@.FINGERPRINTCLONE (SOURCE_ID,EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.FINGERPRINTCLONE_IND02 on @oracle_dots@.FINGERPRINTCLONE (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* FINGERPRINTCLONECONTIG */
create index @oracle_dots@.FINGERPRINTCLONECONTIG_IND02 on @oracle_dots@.FINGERPRINTCLONECONTIG (FINGERPRINT_CONTIG_ID,CLONE_ORDER_NUM)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.FINGERPRINTCLONECONTIG_IND01 on @oracle_dots@.FINGERPRINTCLONECONTIG (FINGERPRINT_CLONE_ID,CLONE_ORDER_NUM)  TABLESPACE @oracle_dotsIndexTablespace@;

/* FINGERPRINTCLONEMARKER */
create index @oracle_dots@.FINGERPRINTCLONEMARKER_IND01 on @oracle_dots@.FINGERPRINTCLONEMARKER (FINGERPRINT_CLONE_ID,FINGERPRINT_MAP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.FINGERPRINTCLONEMARKER_IND02 on @oracle_dots@.FINGERPRINTCLONEMARKER (SOURCE_ID,FINGERPRINT_MAP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.FINGERPRINTCLONEMARKER_IND03 on @oracle_dots@.FINGERPRINTCLONEMARKER (FINGERPRINT_MAP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.FINGERPRINTCLONEMARKER_IND04 on @oracle_dots@.FINGERPRINTCLONEMARKER (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* FINGERPRINTCONTIG */
create index @oracle_dots@.FINGERPRINTCONTIG_IND01 on @oracle_dots@.FINGERPRINTCONTIG (NAME,FINGERPRINT_MAP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.FINGERPRINTCONTIG_IND02 on @oracle_dots@.FINGERPRINTCONTIG (FINGERPRINT_MAP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* FINGERPRINTMAP */
create index @oracle_dots@.FINGERPRINTMAP_IND01 on @oracle_dots@.FINGERPRINTMAP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* GENE */
create index @oracle_dots@.GENE_IND05 on @oracle_dots@.GENE (GENE_SYMBOL)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENE_IND02 on @oracle_dots@.GENE (NAME)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENE_IND03 on @oracle_dots@.GENE (GENE_CATEGORY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENE_IND04 on @oracle_dots@.GENE (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* GENEALIAS */
create index @oracle_dots@.GENEALIAS_IND01 on @oracle_dots@.GENEALIAS (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEALIAS_IND02 on @oracle_dots@.GENEALIAS (GENE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* GENECATEGORY */


/* GENECHROMOSOMALLOCATION */
create index @oracle_dots@.GENECHROMOSOMALLOCATION_IND01 on @oracle_dots@.GENECHROMOSOMALLOCATION (GENE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* GENEFAMILY */


/* GENEFAMILYRELATION */
create index @oracle_dots@.GENEFAMILYRELATION_IND01 on @oracle_dots@.GENEFAMILYRELATION (GENE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFAMILYRELATION_IND02 on @oracle_dots@.GENEFAMILYRELATION (GENE_FAMILY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* GENEFEATURESAGETAGLINK */
create index @oracle_dots@.GENEFEATURESAGETAGLINK_IND01 on @oracle_dots@.GENEFEATURESAGETAGLINK (FIVE_PRIME_TAG_OFFSET,THREE_PRIME_TAG_OFFSET,SAME_STRAND,GENOMIC_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESAGETAGLINK_IND02 on @oracle_dots@.GENEFEATURESAGETAGLINK (GENE_NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESAGETAGLINK_IND03 on @oracle_dots@.GENEFEATURESAGETAGLINK (TAG_NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESAGETAGLINK_IND04 on @oracle_dots@.GENEFEATURESAGETAGLINK (GENOMIC_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* GENEFEATURESEQOVERLAP */
create index @oracle_dots@.GENEFEATURESEQOVERLAP_IND09 on @oracle_dots@.GENEFEATURESEQOVERLAP (GENE_CODING_OVERLAP)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESEQOVERLAP_IND10 on @oracle_dots@.GENEFEATURESEQOVERLAP (GENE_PERCENT_COVERED)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESEQOVERLAP_IND11 on @oracle_dots@.GENEFEATURESEQOVERLAP (GENE_PERCENT_CODING_COVERED)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESEQOVERLAP_IND12 on @oracle_dots@.GENEFEATURESEQOVERLAP (SEQUENCE_PERCENT_COVERED)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESEQOVERLAP_IND01 on @oracle_dots@.GENEFEATURESEQOVERLAP (GENE_NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESEQOVERLAP_IND02 on @oracle_dots@.GENEFEATURESEQOVERLAP (GENOMIC_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESEQOVERLAP_IND03 on @oracle_dots@.GENEFEATURESEQOVERLAP (SEQ_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESEQOVERLAP_IND04 on @oracle_dots@.GENEFEATURESEQOVERLAP (END_SEQUENCE_PAIR_MAP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESEQOVERLAP_IND05 on @oracle_dots@.GENEFEATURESEQOVERLAP (EPCR_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESEQOVERLAP_IND06 on @oracle_dots@.GENEFEATURESEQOVERLAP (SIMILARITY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESEQOVERLAP_IND08 on @oracle_dots@.GENEFEATURESEQOVERLAP (BLAT_ALIGNMENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEFEATURESEQOVERLAP_IND13 on @oracle_dots@.GENEFEATURESEQOVERLAP (GENE_OVERLAP)  TABLESPACE @oracle_dotsIndexTablespace@;

/* GENEINSTANCE */
create index @oracle_dots@.GENEINSTANCE_IND01 on @oracle_dots@.GENEINSTANCE (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEINSTANCE_IND02 on @oracle_dots@.GENEINSTANCE (GENE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEINSTANCE_IND03 on @oracle_dots@.GENEINSTANCE (NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENEINSTANCE_IND04 on @oracle_dots@.GENEINSTANCE (GENE_INSTANCE_CATEGORY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* GENEINSTANCECATEGORY */


/* GENESUPERFAMILY */


/* GENESUPERFAMILYRELATION */
create index @oracle_dots@.GENESUPERFAMILYRELATION_IND01 on @oracle_dots@.GENESUPERFAMILYRELATION (GENE_SUPER_FAMILY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENESUPERFAMILYRELATION_IND02 on @oracle_dots@.GENESUPERFAMILYRELATION (GENE_FAMILY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* GENESYNONYM */
create index @oracle_dots@.GENESYNONYM_IND01 on @oracle_dots@.GENESYNONYM (GENE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENESYNONYM_IND03 on @oracle_dots@.GENESYNONYM (SYNONYM_NAME)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENESYNONYM_IND04 on @oracle_dots@.GENESYNONYM (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* GENETRAPASSEMBLY */
create index @oracle_dots@.GENETRAPASSEMBLY_IND01 on @oracle_dots@.GENETRAPASSEMBLY (TAG_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENETRAPASSEMBLY_IND02 on @oracle_dots@.GENETRAPASSEMBLY (ASSEMBLY_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GENETRAPASSEMBLY_IND03 on @oracle_dots@.GENETRAPASSEMBLY (PERCENT_IDENTITY,TAG_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* GOASSOCIATION */
create index @oracle_dots@.GOASSOCIATION_IND01 on @oracle_dots@.GOASSOCIATION (GO_TERM_ID,IS_DEPRECATED,REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GOASSOCIATION_IND02 on @oracle_dots@.GOASSOCIATION (TABLE_ID,ROW_ID,IS_DEPRECATED,REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create bitmap index @oracle_dots@.GOASSOCIATION_BM_REVIEWSTATUS on @oracle_dots@.GOASSOCIATION (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* GOASSOCIATIONINSTANCE */
create index @oracle_dots@.GOASSOCIATIONINSTANCE_IND06 on @oracle_dots@.GOASSOCIATIONINSTANCE (REVIEW_STATUS_ID,IS_DEPRECATED)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GOASSOCIATIONINSTANCE_IND01 on @oracle_dots@.GOASSOCIATIONINSTANCE (GO_ASSOCIATION_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GOASSOCIATIONINSTANCE_IND02 on @oracle_dots@.GOASSOCIATIONINSTANCE (GO_ASSOC_INST_LOE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GOASSOCIATIONINSTANCE_IND03 on @oracle_dots@.GOASSOCIATIONINSTANCE (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* GOASSOCIATIONINSTANCELOE */

/* GOASSOCINSTEVIDCODE */
create index @oracle_dots@.GOASSOCINSTEVIDCODE_IND02 on @oracle_dots@.GOASSOCINSTEVIDCODE (GO_ASSOCIATION_INSTANCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GOASSOCINSTEVIDCODE_IND03 on @oracle_dots@.GOASSOCINSTEVIDCODE (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.GOASSOCINSTEVIDCODE_IND01 on @oracle_dots@.GOASSOCINSTEVIDCODE (GO_EVIDENCE_CODE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* INDEXWORD */
create index @oracle_dots@.INDEXWORD_IND01 on @oracle_dots@.INDEXWORD (WORD)  TABLESPACE @oracle_dotsIndexTablespace@;

/* INDEXWORDLINK */
create index @oracle_dots@.INDEXWORDLINK_IND02 on @oracle_dots@.INDEXWORDLINK (TARGET_TABLE_ID,TARGET_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.INDEXWORDLINK_IND03 on @oracle_dots@.INDEXWORDLINK (INDEX_WORD_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* INDEXWORDSIMLINK */
create index @oracle_dots@.INDEXWORDSIMLINK_IND04 on @oracle_dots@.INDEXWORDSIMLINK (BEST_SIMILARITY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.INDEXWORDSIMLINK_IND01 on @oracle_dots@.INDEXWORDSIMLINK (TARGET_TABLE_ID,TARGET_ID,INDEX_WORD_ID,BEST_P_VALUE_EXP,BEST_P_VALUE_MANT)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.INDEXWORDSIMLINK_IND03 on @oracle_dots@.INDEXWORDSIMLINK (SIMILARITY_TABLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.INDEXWORDSIMLINK_IND02 on @oracle_dots@.INDEXWORDSIMLINK (INDEX_WORD_ID,BEST_P_VALUE_EXP,TARGET_TABLE_ID,SIMILARITY_TABLE_ID,BEST_SIMILARITY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* INTERACTION */
create index @oracle_dots@.INTERACTION_IND01 on @oracle_dots@.INTERACTION (INTERACTION_TYPE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.INTERACTION_IND02 on @oracle_dots@.INTERACTION (EFFECTOR_ACTION_TYPE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.INTERACTION_IND03 on @oracle_dots@.INTERACTION (EFFECTOR_ROW_SET_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.INTERACTION_IND04 on @oracle_dots@.INTERACTION (TARGET_ROW_SET_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.INTERACTION_IND05 on @oracle_dots@.INTERACTION (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.INTERACTION_IND06 on @oracle_dots@.INTERACTION (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* INTERACTIONINTERACTIONLOE */
create index @oracle_dots@.INTERACTIONINTERACTLOE_IND01 on @oracle_dots@.INTERACTIONINTERACTIONLOE (INTERACTION_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.INTERACTIONINTERACTLOE_IND02 on @oracle_dots@.INTERACTIONINTERACTIONLOE (INTERACTION_LOE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* INTERACTIONLOE */


/* INTERACTIONTYPE */
create index @oracle_dots@.INTERACTIONTYPE_IND01 on @oracle_dots@.INTERACTIONTYPE (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ISEXPRESSED */
create index @oracle_dots@.ISEXPRESSED_IND01 on @oracle_dots@.ISEXPRESSED (TABLE_ID,ROW_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ISEXPRESSED_IND02 on @oracle_dots@.ISEXPRESSED (ANATOMY_ID,IS_CONFIRMED)  TABLESPACE @oracle_dotsIndexTablespace@;

/* KEYWORD */
create index @oracle_dots@.KEYWORD_IND01 on @oracle_dots@.KEYWORD (PREFERRED_KEYWORD_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* LIBRARY */
create index @oracle_dots@.LIBRARY_IND01 on @oracle_dots@.LIBRARY (DBEST_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.LIBRARY_IND02 on @oracle_dots@.LIBRARY (TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.LIBRARY_IND03 on @oracle_dots@.LIBRARY (ANATOMY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* MERGESPLIT */
create index @oracle_dots@.MERGESPLIT_IND01 on @oracle_dots@.MERGESPLIT (TABLE_ID,OLD_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* MOTIF */
create index @oracle_dots@.MOTIF_IND01 on @oracle_dots@.MOTIF (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* MOTIFREJECTIONREASON */


/* NACOMMENT */
create index @oracle_dots@.NACOMMENT_IND01 on @oracle_dots@.NACOMMENT (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NAENTRY */
create index @oracle_dots@.NAENTRY_IND01 on @oracle_dots@.NAENTRY (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create unique index @oracle_dots@.NAENTRY_IND02 on @oracle_dots@.NAENTRY (SOURCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NAFEATRELATIONSHIPTYPE */


/* NAFEATURECOMMENT */
create index @oracle_dots@.NAFEATURECOMMENT_IND01 on @oracle_dots@.NAFEATURECOMMENT (NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NAFEATUREIMP */
create index @oracle_dots@.NAFEATUREIMP_IND08 on @oracle_dots@.NAFEATUREIMP (NA_FEATURE_ID,PREDICTION_ALGORITHM_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATUREIMP_IND09 on @oracle_dots@.NAFEATUREIMP (STRING5,SUBCLASS_VIEW,NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATUREIMP_IND01 on @oracle_dots@.NAFEATUREIMP (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATUREIMP_IND03 on @oracle_dots@.NAFEATUREIMP (SOURCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATUREIMP_IND04 on @oracle_dots@.NAFEATUREIMP (PARENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATUREIMP_IND05 on @oracle_dots@.NAFEATUREIMP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATUREIMP_IND06 on @oracle_dots@.NAFEATUREIMP (STRING14)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATUREIMP_IND07 on @oracle_dots@.NAFEATUREIMP (SUBCLASS_VIEW,NA_SEQUENCE_ID,STRING1)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATUREIMP_IND10 on @oracle_dots@.NAFEATUREIMP (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATUREIMP_IND11 on @oracle_dots@.NAFEATUREIMP (SEQUENCE_ONTOLOGY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATUREIMP_IND12 on @oracle_dots@.NAFEATUREIMP (PREDICTION_ALGORITHM_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NAFEATURENAGENE */
create index @oracle_dots@.NAFEATURENAGENE_IND01 on @oracle_dots@.NAFEATURENAGENE (NA_GENE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATURENAGENE_IND02 on @oracle_dots@.NAFEATURENAGENE (NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NAFEATURENAPROTEIN */
create index @oracle_dots@.NAFEATURENAPROTEIN_IND01 on @oracle_dots@.NAFEATURENAPROTEIN (NA_PROTEIN_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATURENAPROTEIN_IND02 on @oracle_dots@.NAFEATURENAPROTEIN (NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NAFEATURENAPT */
create index @oracle_dots@.NAFEATURENAPT_IND02 on @oracle_dots@.NAFEATURENAPT (NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATURENAPT_IND03 on @oracle_dots@.NAFEATURENAPT (NA_PRIMARY_TRANSCRIPT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NAFEATURERELATIONSHIP */
create index @oracle_dots@.NAFEATURERELATIONSHIP_IND01 on @oracle_dots@.NAFEATURERELATIONSHIP (NA_FEAT_RELATIONSHIP_TYPE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATURERELATIONSHIP_IND02 on @oracle_dots@.NAFEATURERELATIONSHIP (PARENT_NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAFEATURERELATIONSHIP_IND03 on @oracle_dots@.NAFEATURERELATIONSHIP (CHILD_NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NAGENE */
create index @oracle_dots@.NAGENE_IND01 on @oracle_dots@.NAGENE (NAME)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NALOCATION */
create index @oracle_dots@.NALOCATION_IND01 on @oracle_dots@.NALOCATION (NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NALOCATION_IND02 on @oracle_dots@.NALOCATION (START_MIN,END_MAX)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NAPRIMARYTRANSCRIPT */
create index @oracle_dots@.NAPRIMARYTRANSCRIPT_IND01 on @oracle_dots@.NAPRIMARYTRANSCRIPT (NA_GENE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NAPROTEIN */
create index @oracle_dots@.NAPROTEIN_IND01 on @oracle_dots@.NAPROTEIN (NA_PRIMARY_TRANSCRIPT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NAPROTEIN_IND02 on @oracle_dots@.NAPROTEIN (NAME)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NASEQCYTOLOCATION */
create index @oracle_dots@.NASEQCYTOLOCATION_IND01 on @oracle_dots@.NASEQCYTOLOCATION (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NASEQUENCEIMP */
create index @oracle_dots@.NASEQUENCEIMP_IND01 on @oracle_dots@.NASEQUENCEIMP (SUBCLASS_VIEW,STRING1,EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEIMP_IND15 on @oracle_dots@.NASEQUENCEIMP (EXTERNAL_DATABASE_RELEASE_ID,TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEIMP_IND02 on @oracle_dots@.NASEQUENCEIMP (SEQUENCE_TYPE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEIMP_IND07 on @oracle_dots@.NASEQUENCEIMP (INT1)  TABLESPACE @oracle_dotsIndexTablespace@;
create bitmap index @oracle_dots@.NASEQUENCEIMP_BM_IND_SV_TAXON on @oracle_dots@.NASEQUENCEIMP (SUBCLASS_VIEW,TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEIMP_IND04 on @oracle_dots@.NASEQUENCEIMP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEIMP_IND16 on @oracle_dots@.NASEQUENCEIMP (TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEIMP_IND09 on @oracle_dots@.NASEQUENCEIMP (STRING4,SUBCLASS_VIEW)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEIMP_IND10 on @oracle_dots@.NASEQUENCEIMP (INT1,SUBCLASS_VIEW)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEIMP_IND13 on @oracle_dots@.NASEQUENCEIMP (STRING2)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEIMP_IND08 on @oracle_dots@.NASEQUENCEIMP (EXTERNAL_DATABASE_RELEASE_ID,SUBCLASS_VIEW)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEIMP_IND17 on @oracle_dots@.NASEQUENCEIMP (SEQUENCING_CENTER_CONTACT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEIMP_IND05 on @oracle_dots@.NASEQUENCEIMP (SEQUENCE_PIECE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NASEQUENCEKEYWORD */
create index @oracle_dots@.NASEQUENCEKEYWORD_IND01 on @oracle_dots@.NASEQUENCEKEYWORD (KEYWORD_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEKEYWORD_IND02 on @oracle_dots@.NASEQUENCEKEYWORD (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NASEQUENCEORGANELLE */
create index @oracle_dots@.NASEQUENCEORGANELLE_IND01 on @oracle_dots@.NASEQUENCEORGANELLE (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEORGANELLE_IND02 on @oracle_dots@.NASEQUENCEORGANELLE (ORGANELLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NASEQUENCEREF */
create index @oracle_dots@.NASEQUENCEREF_IND01 on @oracle_dots@.NASEQUENCEREF (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NASEQUENCEREF_IND02 on @oracle_dots@.NASEQUENCEREF (REFERENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* NRDBENTRY */
create index @oracle_dots@.NRDBENTRY_IND01 on @oracle_dots@.NRDBENTRY (AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NRDBENTRY_IND02 on @oracle_dots@.NRDBENTRY (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NRDBENTRY_IND03 on @oracle_dots@.NRDBENTRY (TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NRDBENTRY_IND04 on @oracle_dots@.NRDBENTRY (SOURCE_ID,EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.NRDBENTRY_IND05 on @oracle_dots@.NRDBENTRY (GID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* OPTICALMAP */
create index @oracle_dots@.OPTICALMAP_IND01 on @oracle_dots@.OPTICALMAP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.OPTICALMAP_IND02 on @oracle_dots@.OPTICALMAP (TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* OPTICALMAPALIGNMENT */
create index @oracle_dots@.OPTICALMAPALIGNMENT_IND01 on @oracle_dots@.OPTICALMAPALIGNMENT (OPTICAL_MAP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.OPTICALMAPALIGNMENT_IND02 on @oracle_dots@.OPTICALMAPALIGNMENT (NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.OPTICALMAPALIGNMENT_IND03 on @oracle_dots@.OPTICALMAPALIGNMENT (ALGORITHM_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* OPTICALMAPALIGNMENTSPAN */
create index @oracle_dots@.OPTICALMAPALIGNMENTSPAN_IND01 on @oracle_dots@.OPTICALMAPALIGNMENTSPAN (NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.OPTICALMAPALIGNMENTSPAN_IND02 on @oracle_dots@.OPTICALMAPALIGNMENTSPAN (OPTICAL_MAP_ALIGNMENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.OPTICALMAPALIGNMENTSPAN_IND03 on @oracle_dots@.OPTICALMAPALIGNMENTSPAN (OPTICAL_MAP_FRAGMENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* OPTICALMAPFRAGMENT */
create index @oracle_dots@.OPTICALMAPFRAGMENT_IND01 on @oracle_dots@.OPTICALMAPFRAGMENT (OPTICAL_MAP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ORGANELLE */


/* PATHWAY */
create index @oracle_dots@.PATHWAY_IND01 on @oracle_dots@.PATHWAY (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* PATHWAYINTERACTION */
create index @oracle_dots@.PATHWAYINTERACTION_IND01 on @oracle_dots@.PATHWAYINTERACTION (PATHWAY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PATHWAYINTERACTION_IND02 on @oracle_dots@.PATHWAYINTERACTION (INTERACTION_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* PFAMENTRY */
create unique index @oracle_dots@.PFAMENTRY_IND02 on @oracle_dots@.PFAMENTRY (ACCESSION,PFAM_ENTRY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create unique index @oracle_dots@.PFAMENTRY_IND01 on @oracle_dots@.PFAMENTRY (RELEASE,ACCESSION)  TABLESPACE @oracle_dotsIndexTablespace@;

/* PLASMOMAP */
create index @oracle_dots@.PLASMOMAP_IND04 on @oracle_dots@.PLASMOMAP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PLASMOMAP_IND05 on @oracle_dots@.PLASMOMAP (TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PLASMOMAP_IND01 on @oracle_dots@.PLASMOMAP (SOURCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PLASMOMAP_IND02 on @oracle_dots@.PLASMOMAP (ACCESSION)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PLASMOMAP_IND03 on @oracle_dots@.PLASMOMAP (CHROMOSOME,CENTIMORGANS,TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* PROJECTLINK */
create index @oracle_dots@.PROJECTLINK_IND01 on @oracle_dots@.PROJECTLINK (PROJECT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PROJECTLINK_IND02 on @oracle_dots@.PROJECTLINK (TABLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PROJECTLINK_IND03 on @oracle_dots@.PROJECTLINK (PROJECT_ID,TABLE_ID,ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* PROTEIN */
create index @oracle_dots@.PROTEIN_IND02 on @oracle_dots@.PROTEIN (PROTEIN_ID,RNA_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PROTEIN_IND01 on @oracle_dots@.PROTEIN (RNA_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PROTEIN_IND03 on @oracle_dots@.PROTEIN (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* PROTEINCATEGORY */


/* PROTEININSTANCE */
create index @oracle_dots@.PROTEININSTANCE_IND01 on @oracle_dots@.PROTEININSTANCE (PROTEIN_INSTANCE_CATEGORY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PROTEININSTANCE_IND02 on @oracle_dots@.PROTEININSTANCE (PROTEIN_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PROTEININSTANCE_IND03 on @oracle_dots@.PROTEININSTANCE (AA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PROTEININSTANCE_IND04 on @oracle_dots@.PROTEININSTANCE (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* PROTEININSTANCECATEGORY */


/* PROTEINPROPERTY */
create index @oracle_dots@.PROTEINPROPERTY_IND01 on @oracle_dots@.PROTEINPROPERTY (AA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PROTEINPROPERTY_IND02 on @oracle_dots@.PROTEINPROPERTY (PROTEIN_PROPERTY_TYPE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PROTEINPROPERTY_IND03 on @oracle_dots@.PROTEINPROPERTY (PREDICTION_ALGORITHM_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PROTEINPROPERTY_IND04 on @oracle_dots@.PROTEINPROPERTY (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PROTEINPROPERTY_IND05 on @oracle_dots@.PROTEINPROPERTY (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* PROTEINPROPERTYTYPE */


/* PROTEINPROTEINCATEGORY */
create index @oracle_dots@.PROTEINPROTEINCATEGORY_IND01 on @oracle_dots@.PROTEINPROTEINCATEGORY (PROTEIN_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PROTEINPROTEINCATEGORY_IND02 on @oracle_dots@.PROTEINPROTEINCATEGORY (PROTEIN_CATEGORY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* PROTEINSYNONYM */
create index @oracle_dots@.PROTEINSYNONYM_IND01 on @oracle_dots@.PROTEINSYNONYM (PROTEIN_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.PROTEINSYNONYM_IND02 on @oracle_dots@.PROTEINSYNONYM (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* REJECTEDMOTIF */
create index @oracle_dots@.REJECTEDMOTIFSOURCEIDX on @oracle_dots@.REJECTEDMOTIF (SOURCE_ID,EXTERNAL_DATABASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* REPEATTYPE */
create index @oracle_dots@.REPEATTYPE_IND01 on @oracle_dots@.REPEATTYPE (PARENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.REPEATTYPE_IND02 on @oracle_dots@.REPEATTYPE (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.REPEATTYPE_IND03 on @oracle_dots@.REPEATTYPE (EXEMPLAR_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* RHMAP */
create index @oracle_dots@.RHMAP_IND01 on @oracle_dots@.RHMAP (TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RHMAP_IND02 on @oracle_dots@.RHMAP (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* RHMAPMARKER */
create index @oracle_dots@.RHMAPMARKER_IND01 on @oracle_dots@.RHMAPMARKER (RH_MARKER_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RHMAPMARKER_IND02 on @oracle_dots@.RHMAPMARKER (RH_MAP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RHMAPMARKER_IND03 on @oracle_dots@.RHMAPMARKER (CHROMOSOME,CENTIRAYS,RH_MARKER_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* RHMARKER */
create index @oracle_dots@.RHMARKER_IND01 on @oracle_dots@.RHMARKER (TAXON_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RHMARKER_IND02 on @oracle_dots@.RHMARKER (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* RNA */
create index @oracle_dots@.RNA_IND01 on @oracle_dots@.RNA (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RNA_IND02 on @oracle_dots@.RNA (GENE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* RNAANATOMY */
create index @oracle_dots@.RNAANATOMY_IND01 on @oracle_dots@.RNAANATOMY (ANATOMY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RNAANATOMY_IND02 on @oracle_dots@.RNAANATOMY (RNA_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* RNAANATOMYLOE */
create index @oracle_dots@.RNAANATOMYLOE_IND01 on @oracle_dots@.RNAANATOMYLOE (ANATOMY_LOE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RNAANATOMYLOE_IND02 on @oracle_dots@.RNAANATOMYLOE (RNA_ANATOMY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* RNACATEGORY */


/* RNAFEATUREEXON */
create index @oracle_dots@.RNAFEATUREEXON_IND01 on @oracle_dots@.RNAFEATUREEXON (EXON_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RNAFEATUREEXON_IND02 on @oracle_dots@.RNAFEATUREEXON (RNA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* RNAICONSTRUCT */
create index @oracle_dots@.RNAICONSTRUCT_IND01 on @oracle_dots@.RNAICONSTRUCT (RNA_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RNAICONSTRUCT_IND02 on @oracle_dots@.RNAICONSTRUCT (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* RNAINSTANCE */
create index @oracle_dots@.RNAINSTANCE_IND01 on @oracle_dots@.RNAINSTANCE (NA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RNAINSTANCE_IND02 on @oracle_dots@.RNAINSTANCE (RNA_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RNAINSTANCE_IND03 on @oracle_dots@.RNAINSTANCE (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RNAINSTANCE_IND04 on @oracle_dots@.RNAINSTANCE (RNA_INSTANCE_CATEGORY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* RNAINSTANCECATEGORY */


/* RNAIPHENOTYPE */
create index @oracle_dots@.RNAIPHENOTYPE_IND01 on @oracle_dots@.RNAIPHENOTYPE (RNAI_CONSTRUCT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RNAIPHENOTYPE_IND02 on @oracle_dots@.RNAIPHENOTYPE (PHENOTYPE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RNAIPHENOTYPE_IND03 on @oracle_dots@.RNAIPHENOTYPE (REVIEW_STATUS_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* RNARNACATEGORY */
create index @oracle_dots@.RNARNACATEGORY_IND01 on @oracle_dots@.RNARNACATEGORY (RNA_CATEGORY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.RNARNACATEGORY_IND02 on @oracle_dots@.RNARNACATEGORY (RNA_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* ROWSET */


/* ROWSETMEMBER */
create index @oracle_dots@.ROWSETMEMBER_IND01 on @oracle_dots@.ROWSETMEMBER (ROW_SET_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.ROWSETMEMBER_IND02 on @oracle_dots@.ROWSETMEMBER (TABLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* SECONDARYACCS */
create index @oracle_dots@.SECONDARYACCS_IND01 on @oracle_dots@.SECONDARYACCS (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.SECONDARYACCS_IND02 on @oracle_dots@.SECONDARYACCS (SOURCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.SECONDARYACCS_IND03 on @oracle_dots@.SECONDARYACCS (SECONDARY_ACCS)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.SECONDARYACCS_IND04 on @oracle_dots@.SECONDARYACCS (AA_ENTRY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.SECONDARYACCS_IND05 on @oracle_dots@.SECONDARYACCS (NA_ENTRY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* SEQGROUPEXPERIMENTIMP */
create index @oracle_dots@.SEQGROUPEXPERIMENTIMP_IND01 on @oracle_dots@.SEQGROUPEXPERIMENTIMP (ALGORITHM_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* SEQUENCEFAMILY */
create index @oracle_dots@.SEQUENCEFAMILY_IND01 on @oracle_dots@.SEQUENCEFAMILY (SEQUENCE_FAMILY_EXPERIMENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* SEQUENCEFAMILYEXPERIMENT */
create index @oracle_dots@.SEQUENCEFAMILYEXPERIMENT_IND01 on @oracle_dots@.SEQUENCEFAMILYEXPERIMENT (ORTHOLOG_EXPERIMENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.SEQUENCEFAMILYEXPERIMENT_IND02 on @oracle_dots@.SEQUENCEFAMILYEXPERIMENT (IN_PARALOG_EXPERIMENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.SEQUENCEFAMILYEXPERIMENT_IND03 on @oracle_dots@.SEQUENCEFAMILYEXPERIMENT (OUT_PARALOG_EXPERIMENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* SEQUENCEGROUPFAMILY */
create index @oracle_dots@.SEQUENCEGROUPFAMILY_IND01 on @oracle_dots@.SEQUENCEGROUPFAMILY (SEQUENCE_FAMILY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.SEQUENCEGROUPFAMILY_IND02 on @oracle_dots@.SEQUENCEGROUPFAMILY (SEQUENCE_GROUP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* SEQUENCEGROUPIMP */
create index @oracle_dots@.SEQUENCEGROUPIMP_IND01 on @oracle_dots@.SEQUENCEGROUPIMP (SEQUENCE_GROUP_EXPERIMENT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* SEQUENCEPIECE */
create index @oracle_dots@.SEQUENCEPIECE_IND01 on @oracle_dots@.SEQUENCEPIECE (PIECE_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.SEQUENCEPIECE_IND02 on @oracle_dots@.SEQUENCEPIECE (VIRTUAL_NA_SEQUENCE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* SEQUENCESEQUENCEGROUP */
create index @oracle_dots@.SEQUENCESEQUENCEGROUP_IND01 on @oracle_dots@.SEQUENCESEQUENCEGROUP (SOURCE_TABLE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.SEQUENCESEQUENCEGROUP_IND02 on @oracle_dots@.SEQUENCESEQUENCEGROUP (SEQUENCE_GROUP_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* SEQUENCETYPE */
create index @oracle_dots@.SEQUENCETYPE_IND01 on @oracle_dots@.SEQUENCETYPE (PARENT_SEQUENCE_TYPE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* SIMILARITY */
create index @oracle_dots@.SIMILARITY_IND03 on @oracle_dots@.SIMILARITY (SUBJECT_TABLE_ID,SUBJECT_ID,MIN_SUBJECT_START,MAX_SUBJECT_END)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.SIMILARITY_IND04 on @oracle_dots@.SIMILARITY (QUERY_TABLE_ID,QUERY_ID,MIN_QUERY_START,MAX_QUERY_END)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.SIMILARITY_IND06 on @oracle_dots@.SIMILARITY (SUBJECT_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.SIMILARITY_IND05 on @oracle_dots@.SIMILARITY (QUERY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;
create index @oracle_dots@.SIMILARITY_IND08 on @oracle_dots@.SIMILARITY (ROW_ALG_INVOCATION_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* SIMILARITYSPAN */
create index @oracle_dots@.SIMILARITYSPAN_IND01N on @oracle_dots@.SIMILARITYSPAN (SIMILARITY_ID)  TABLESPACE @oracle_dotsIndexTablespace@;

/* TRANSLATEDAAFEATSEG */
create index @oracle_dots@.TRANSLATEDAAFEATSEG_IND01 on @oracle_dots@.TRANSLATEDAAFEATSEG (AA_FEATURE_ID)  TABLESPACE @oracle_dotsIndexTablespace@;



/* 391 index(es) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

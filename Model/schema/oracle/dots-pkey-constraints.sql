
/*                                                                                            */
/* dots-pkey-constraints.sql                                                                  */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Dec  9 16:12:06 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL dots-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table @oracle_dots@.AACOMMENT add constraint PK_AACOMMENT primary key (AA_COMMENT_ID);
alter table @oracle_dots@.AAENTRY add constraint PK_AAENTRY primary key (AA_ENTRY_ID);
alter table @oracle_dots@.AAFAMILYEXPERIMENT add constraint PK_AAFAMILYEXPERIMENT primary key (AA_FAMILY_EXPERIMENT_ID);
alter table @oracle_dots@.AAFEATUREIMP add constraint PK_AAFEATUREIMP primary key (AA_FEATURE_ID);
alter table @oracle_dots@.AAGENE add constraint PK_AAGENE primary key (AA_GENE_ID);
alter table @oracle_dots@.AAGENESYNONYM add constraint PK_AAGENESYNONYM primary key (AA_GENE_SYNONYM_ID);
alter table @oracle_dots@.AALOCATION add constraint PK_AALOCATION primary key (AA_LOCATION_ID);
alter table @oracle_dots@.AAMOTIFGOTERMRULE add constraint PK_AAMOTIFGOTERMRULE primary key (AA_MOTIF_GO_TERM_RULE_ID);
alter table @oracle_dots@.AAMOTIFGOTERMRULESET add constraint AAMOTIFGOTERMRULESET_PK primary key (AA_MOTIF_GO_TERM_RULE_SET_ID);
alter table @oracle_dots@.AASEQGROUPEXPERIMENTIMP add constraint PK_AASEQGROUPEXPERIMENTIMP primary key (AA_SEQ_GROUP_EXPERIMENT_ID);
alter table @oracle_dots@.AASEQUENCEDBREF add constraint PK_AASEQUENCEDBREF primary key (AA_SEQUENCE_DB_REF_ID);
alter table @oracle_dots@.AASEQUENCEENZYMECLASS add constraint AASEQUENCEENZYMECLASS_PK primary key (AA_SEQUENCE_ENZYME_CLASS_ID);
alter table @oracle_dots@.AASEQUENCEFAMILY add constraint PK_AASEQUENCEFAMILY primary key (AA_SEQUENCE_FAMILY_ID);
alter table @oracle_dots@.AASEQUENCEGROUPFAMILY add constraint PK_AASEQUENCEGROUPFAMILY primary key (AA_SEQUENCE_GROUP_FAMILY_ID);
alter table @oracle_dots@.AASEQUENCEGROUPIMP add constraint PK_AASEQUENCEGROUPIMP primary key (AA_SEQUENCE_GROUP_ID);
alter table @oracle_dots@.AASEQUENCEIMP add constraint PK_AASEQUENCEIMP primary key (AA_SEQUENCE_ID);
alter table @oracle_dots@.AASEQUENCEKEYWORD add constraint PK_AASEQUENCEKEYWORD primary key (AA_SEQUENCE_KEYWORD_ID);
alter table @oracle_dots@.AASEQUENCEORGANELLE add constraint PK_AASEQUENCEORGANELLE primary key (AA_SEQUENCE_ORGANELLE_ID);
alter table @oracle_dots@.AASEQUENCEREF add constraint PK_AASEQUENCEREF primary key (AA_SEQUENCE_REF_ID);
alter table @oracle_dots@.AASEQUENCESEQUENCEGROUP add constraint PK_AASEQUENCESEQUENCEGROUP primary key (AA_SEQUENCE_SEQUENCE_GROUP_ID);
alter table @oracle_dots@.AASEQUENCETAXON add constraint PK_AASEQUENCETAXON primary key (AA_SEQUENCE_TAXON_ID);
alter table @oracle_dots@.ALLELE add constraint PK_ALLELE primary key (ALLELE_ID);
alter table @oracle_dots@.ALLELECOMPLEMENTATION add constraint PK_ALLELECOMPLEMENTATION primary key (ALLELE_COMPLEMENTATION_ID);
alter table @oracle_dots@.ALLELEINSTANCE add constraint PK_ALLELEINSTANCE primary key (ALLELE_INSTANCE_ID);
alter table @oracle_dots@.ALLELEPHENOTYPE add constraint PK_ALLELEPHENOTYPE primary key (ALLELE_PHENOTYPE_ID);
alter table @oracle_dots@.ALLELEPHENOTYPECLASS add constraint PK_ALLELEPHENOTYPECLASS primary key (ALLELE_PHENOTYPE_CLASS_ID);
alter table @oracle_dots@.ANATOMYLIBRARY add constraint PK_ANATOMYLIBRARY primary key (ANATOMY_LIBRARY_ID);
alter table @oracle_dots@.ANATOMYLOE add constraint PK_ANATOMYLOE primary key (ANATOMY_LOE_ID);
alter table @oracle_dots@.ASSEMBLYANATOMYPERCENT add constraint PK_ASSEMBLYANATOMYPERCENT primary key (ASSEMBLY_ANATOMY_PERCENT_ID);
alter table @oracle_dots@.ASSEMBLYSEQUENCE add constraint PK_ASSEMBLYSEQUENCE primary key (ASSEMBLY_SEQUENCE_ID);
alter table @oracle_dots@.ASSEMBLYSEQUENCESNP add constraint PK_ASSEMBLYSEQUENCESNP primary key (ASSEMBLY_SEQUENCE_SNP_ID);
alter table @oracle_dots@.ASSEMBLYSNP add constraint PK_ASSEMBLYSNP primary key (ASSEMBLY_SNP_ID);
alter table @oracle_dots@.ATTRIBUTION add constraint PK_ATTRIBUTION primary key (ATTRIBUTION_ID);
alter table @oracle_dots@.BESTSIMILARITYPAIR add constraint PK_BESTSIMILARITYPAIR primary key (BEST_SIMILARITY_PAIR_ID);
alter table @oracle_dots@.BLATALIGNMENT add constraint PK_BLATALIGNMENT primary key (BLAT_ALIGNMENT_ID);
alter table @oracle_dots@.BLATALIGNMENTQUALITY add constraint PK_BLATALIGNMENTQUALITY primary key (BLAT_ALIGNMENT_QUALITY_ID);
alter table @oracle_dots@.CLONE add constraint PK_CLONE primary key (CLONE_ID);
alter table @oracle_dots@.CLONEINSET add constraint PK_CLONEINSET primary key (CLONE_IN_SET_ID);
alter table @oracle_dots@.CLONESET add constraint PK_CLONESET primary key (CLONE_SET_ID);
alter table @oracle_dots@.COMMENTNAME add constraint PK_COMMENTNAME primary key (COMMENT_NAME_ID);
alter table @oracle_dots@.COMMENTS add constraint PK_COMMENTS primary key (COMMENTS_ID);
alter table @oracle_dots@.COMPLEMENTATION add constraint PK_COMPLEMENTATION primary key (COMPLEMENTATION_ID);
alter table @oracle_dots@.COMPLEX add constraint PK_COMPLEX primary key (COMPLEX_ID);
alter table @oracle_dots@.COMPLEXANATOMY add constraint PK_COMPLEXANATOMY primary key (COMPLEX_ANATOMY_ID);
alter table @oracle_dots@.COMPLEXCOMPONENT add constraint PK_COMPLEXCOMPONENT primary key (COMPLEX_COMPONENT_ID);
alter table @oracle_dots@.COMPLEXTYPE add constraint PK_COMPLEXTYPE primary key (COMPLEX_TYPE_ID);
alter table @oracle_dots@.CONSISTENTALIGNMENT add constraint PK_CONSISTENTALIGNMENT primary key (CONSISTENT_ALIGNMENT_ID);
alter table @oracle_dots@.DBREFNAFEATURE add constraint PK_DBREFNAFEATURE primary key (DB_REF_NA_FEATURE_ID);
alter table @oracle_dots@.DBREFNASEQUENCE add constraint PK_DBREFNASEQUENCE primary key (DB_REF_NA_SEQUENCE_ID);
alter table @oracle_dots@.DBREFPFAMENTRY add constraint PK_DBREFPFAMENTRY primary key (DB_REF_PFAM_ENTRY_ID);
alter table @oracle_dots@.EFFECTORACTIONTYPE add constraint PK_EFFECTORACTIONTYPE primary key (EFFECTOR_ACTION_TYPE_ID);
alter table @oracle_dots@.ENDSEQUENCEPAIRMAP add constraint PK_ENDSEQUENCEPAIRMAP primary key (END_SEQUENCE_PAIR_MAP_ID);
alter table @oracle_dots@.EPCR add constraint PK_EPCR primary key (EPCR_ID);
alter table @oracle_dots@.EST add constraint PK_EST primary key (EST_ID);
alter table @oracle_dots@.EVIDENCE add constraint PK_EVIDENCE primary key (EVIDENCE_ID);
alter table @oracle_dots@.EXONLOCATION add constraint PK_EXONLOCATION primary key (EXON_LOCATION_ID);
alter table @oracle_dots@.FAMILY add constraint PK_FAMILY primary key (FAMILY_ID);
alter table @oracle_dots@.FAMILYGENE add constraint PK_FAMILYGENE primary key (FAMILY_GENE_ID);
alter table @oracle_dots@.FAMILYPROTEIN add constraint PK_FAMILYPROTEIN primary key (FAMILY_PROTEIN_ID);
alter table @oracle_dots@.FEATURENAME add constraint PK_FEATURENAME primary key (FEATURE_NAME_ID);
alter table @oracle_dots@.FINGERPRINTCLONE add constraint PK_FINGERPRINTCLONE primary key (FINGERPRINT_CLONE_ID);
alter table @oracle_dots@.FINGERPRINTCLONECONTIG add constraint PK_FINGERPRINTCLONECONTIG primary key (FINGERPRINT_CLONE_CONTIG_ID);
alter table @oracle_dots@.FINGERPRINTCLONEMARKER add constraint PK_FINGERPRINTCLONEMARKER primary key (FINGERPRINT_CLONE_MARKER_ID);
alter table @oracle_dots@.FINGERPRINTCONTIG add constraint PK_FINGERPRINTCONTIG primary key (FINGERPRINT_CONTIG_ID);
alter table @oracle_dots@.FINGERPRINTMAP add constraint PK_FINGERPRINTMAP primary key (FINGERPRINT_MAP_ID);
alter table @oracle_dots@.GENE add constraint PK_GENE primary key (GENE_ID);
alter table @oracle_dots@.GENEALIAS add constraint PK_GENEALIAS primary key (GENE_ALIAS_ID);
alter table @oracle_dots@.GENECATEGORY add constraint PK_GENECATEGORY primary key (GENE_CATEGORY_ID);
alter table @oracle_dots@.GENECHROMOSOMALLOCATION add constraint PK_GENECHROMOSOMALLOCATION primary key (GENE_CHROMOSOMAL_LOCATION_ID);
alter table @oracle_dots@.GENEFAMILY add constraint PK_GENEFAMILY primary key (GENE_FAMILY_ID);
alter table @oracle_dots@.GENEFAMILYRELATION add constraint PK_GENEFAMILYRELATION primary key (GENE_FAMILY_RELATION_ID);
alter table @oracle_dots@.GENEFEATURESAGETAGLINK add constraint PK_GENEFEATURESAGETAGLINK primary key (GENE_FEATURE_SAGE_TAG_LINK_ID);
alter table @oracle_dots@.GENEFEATURESEQOVERLAP add constraint PK_GENEFEATURESEQOVERLAP primary key (GENE_FEATURE_SEQ_OVERLAP_ID);
alter table @oracle_dots@.GENEINSTANCE add constraint PK_GENEINSTANCE primary key (GENE_INSTANCE_ID);
alter table @oracle_dots@.GENEINSTANCECATEGORY add constraint PK_GENEINSTANCECATEGORY primary key (GENE_INSTANCE_CATEGORY_ID);
alter table @oracle_dots@.GENESUPERFAMILY add constraint PK_GENESUPERFAMILY primary key (GENE_SUPER_FAMILY_ID);
alter table @oracle_dots@.GENESUPERFAMILYRELATION add constraint PK_GENESUPERFAMILYRELATION primary key (GENE_SUPERFAMILY_RELATION_ID);
alter table @oracle_dots@.GENESYNONYM add constraint PK_GENESYNONYM primary key (GENE_SYNONYM_ID);
alter table @oracle_dots@.GENETRAPASSEMBLY add constraint PK_GENETRAPASSEMBLY primary key (GENE_TRAP_ASSEMBLY_ID);
alter table @oracle_dots@.GOASSOCIATION add constraint GOASSOCIATION_PK primary key (GO_ASSOCIATION_ID);
alter table @oracle_dots@.GOASSOCIATIONINSTANCE add constraint GOASSOCIATIONINSTANCE_PK primary key (GO_ASSOCIATION_INSTANCE_ID);
alter table @oracle_dots@.GOASSOCIATIONINSTANCELOE add constraint GOASSOCIATIONINSTANCELOE_PK primary key (GO_ASSOC_INST_LOE_ID);
alter table @oracle_dots@.GOASSOCINSTEVIDCODE add constraint GOASSOCINSTEVIDCODE_PK primary key (GO_ASSOC_INST_EVID_CODE_ID);
alter table @oracle_dots@.INDEXWORD add constraint PK_INDEXWORD primary key (INDEX_WORD_ID);
alter table @oracle_dots@.INDEXWORDLINK add constraint PK_INDEXWORDLINK primary key (INDEX_WORD_LINK_ID);
alter table @oracle_dots@.INDEXWORDSIMLINK add constraint PK_INDEXWORDSIMLINK primary key (INDEX_WORD_SIM_LINK_ID);
alter table @oracle_dots@.INTERACTION add constraint PK_INTERACTION primary key (INTERACTION_ID);
alter table @oracle_dots@.INTERACTIONINTERACTIONLOE add constraint PK_INTERACTIONINTERACTIONLOE primary key (INTERACTION_INTERACTION_LOE_ID);
alter table @oracle_dots@.INTERACTIONLOE add constraint PK_INTERACTIONLOE primary key (INTERACTION_LOE_ID);
alter table @oracle_dots@.INTERACTIONTYPE add constraint PK_INTERACTIONTYPE primary key (INTERACTION_TYPE_ID);
alter table @oracle_dots@.ISEXPRESSED add constraint PK_ISEXPRESSED primary key (IS_EXPRESSED_ID);
alter table @oracle_dots@.KEYWORD add constraint PK_KEYWORD primary key (KEYWORD_ID);
alter table @oracle_dots@.LIBRARY add constraint PK_LIBRARY primary key (LIBRARY_ID);
alter table @oracle_dots@.MERGESPLIT add constraint PK_MERGESPLIT primary key (MERGE_SPLIT_ID);
alter table @oracle_dots@.MOTIF add constraint PK_MOTIF primary key (MOTIF_ID);
alter table @oracle_dots@.NACOMMENT add constraint PK_NACOMMENT primary key (NA_COMMENT_ID);
alter table @oracle_dots@.NAENTRY add constraint PK_NAENTRY primary key (NA_ENTRY_ID);
alter table @oracle_dots@.NAFEATRELATIONSHIPTYPE add constraint PK_NAFEATRELATIONSHIPTYPE primary key (NA_FEAT_RELATIONSHIP_TYPE_ID);
alter table @oracle_dots@.NAFEATURECOMMENT add constraint PK_NAFEATURECOMMENT primary key (NA_FEATURE_COMMENT_ID);
alter table @oracle_dots@.NAFEATUREIMP add constraint PK_NAFEATUREIMP primary key (NA_FEATURE_ID);
alter table @oracle_dots@.NAFEATURENAGENE add constraint PK_NAFEATURENAGENE primary key (NA_FEATURE_NA_GENE_ID);
alter table @oracle_dots@.NAFEATURENAPROTEIN add constraint PK_NAFEATURENAPROTEIN primary key (NA_FEATURE_NA_PROTEIN_ID);
alter table @oracle_dots@.NAFEATURENAPT add constraint PK_NAFEATURENAPT primary key (NA_FEATURE_NA_PT_ID);
alter table @oracle_dots@.NAFEATURERELATIONSHIP add constraint PK_NAFEATURERELATIONSHIP primary key (NA_FEATURE_RELATIONSHIP_ID);
alter table @oracle_dots@.NAGENE add constraint PK_NAGENE primary key (NA_GENE_ID);
alter table @oracle_dots@.NALOCATION add constraint PK_NALOCATION primary key (NA_LOCATION_ID);
alter table @oracle_dots@.NAPRIMARYTRANSCRIPT add constraint PK_NAPRIMARYTRANSCRIPT primary key (NA_PRIMARY_TRANSCRIPT_ID);
alter table @oracle_dots@.NAPROTEIN add constraint PK_NAPROTEIN primary key (NA_PROTEIN_ID);
alter table @oracle_dots@.NASEQCYTOLOCATION add constraint PK_NASEQCYTOLOCATION primary key (NA_SEQ_CYTO_LOCATION_ID);
alter table @oracle_dots@.NASEQUENCEIMP add constraint PK_NASEQUENCEIMP primary key (NA_SEQUENCE_ID);
alter table @oracle_dots@.NASEQUENCEKEYWORD add constraint PK_NASEQUENCEKEYWORD primary key (NA_SEQUENCE_KEYWORD_ID);
alter table @oracle_dots@.NASEQUENCEORGANELLE add constraint PK_NASEQUENCEORGANELLE primary key (NA_SEQUENCE_ORGANELLE_ID);
alter table @oracle_dots@.NASEQUENCEREF add constraint PK_NASEQUENCEREF primary key (NA_SEQUENCE_REF_ID);
alter table @oracle_dots@.NRDBENTRY add constraint PK_NRDBENTRY primary key (NRDB_ENTRY_ID);
alter table @oracle_dots@.OPTICALMAP add constraint PK_OPTICALMAP primary key (OPTICAL_MAP_ID);
alter table @oracle_dots@.OPTICALMAPALIGNMENT add constraint PK_OPTICALMAPALIGNMENT primary key (OPTICAL_MAP_ALIGNMENT_ID);
alter table @oracle_dots@.OPTICALMAPALIGNMENTSPAN add constraint PK_OPTICALMAPALIGNMENTSPAN primary key (OPTICAL_MAP_ALIGNMENT_SPAN_ID);
alter table @oracle_dots@.OPTICALMAPFRAGMENT add constraint PK_OPTICALMAPFRAGMENT primary key (OPTICAL_MAP_FRAGMENT_ID);
alter table @oracle_dots@.ORGANELLE add constraint PK_ORGANELLE primary key (ORGANELLE_ID);
alter table @oracle_dots@.PATHWAY add constraint PK_PATHWAY primary key (PATHWAY_ID);
alter table @oracle_dots@.PATHWAYINTERACTION add constraint PK_PATHWAYINTERACTION primary key (PATHWAY_INTERACTION_ID);
alter table @oracle_dots@.PFAMENTRY add constraint PK_PFAMENTRY primary key (PFAM_ENTRY_ID);
alter table @oracle_dots@.PLASMOMAP add constraint PK_PLASMOMAP primary key (PLASMOMAP_ID);
alter table @oracle_dots@.PROJECTLINK add constraint PK_PROJECTLINK primary key (PROJECT_LINK_ID);
alter table @oracle_dots@.PROTEIN add constraint PK_PROTEIN primary key (PROTEIN_ID);
alter table @oracle_dots@.PROTEINCATEGORY add constraint PK_PROTEINCATEGORY primary key (PROTEIN_CATEGORY_ID);
alter table @oracle_dots@.PROTEININSTANCE add constraint PK_PROTEININSTANCE primary key (PROTEIN_INSTANCE_ID);
alter table @oracle_dots@.PROTEININSTANCECATEGORY add constraint PK_PROTEININSTANCECATEGORY primary key (PROTEIN_INSTANCE_CATEGORY_ID);
alter table @oracle_dots@.PROTEINPROPERTY add constraint PK_PROTEINPROPERTY primary key (PROTEIN_PROPERTY_ID);
alter table @oracle_dots@.PROTEINPROPERTYTYPE add constraint PK_PROTEINPROPERTYTYPE primary key (PROTEIN_PROPERTY_TYPE_ID);
alter table @oracle_dots@.PROTEINPROTEINCATEGORY add constraint PK_PROTEINPROTEINCATEGORY primary key (PROTEIN_PROTEIN_CATEGORY_ID);
alter table @oracle_dots@.PROTEINSYNONYM add constraint PK_PROTEINSYNONYM primary key (PROTEIN_SYNONYM_ID);
alter table @oracle_dots@.REPEATTYPE add constraint PK_REPEATTYPE primary key (REPEAT_TYPE_ID);
alter table @oracle_dots@.RHMAP add constraint PK_RHMAP primary key (RH_MAP_ID);
alter table @oracle_dots@.RHMAPMARKER add constraint PK_RHMAPMARKER primary key (RH_MAP_MARKER_ID);
alter table @oracle_dots@.RHMARKER add constraint PK_RHMARKERPRKER primary key (RH_MARKER_ID);
alter table @oracle_dots@.RNA add constraint PK_RNA primary key (RNA_ID);
alter table @oracle_dots@.RNAANATOMY add constraint PK_RNAANATOMY primary key (RNA_ANATOMY_ID);
alter table @oracle_dots@.RNAANATOMYLOE add constraint PK_RNAANATOMYLOE primary key (RNA_ANATOMY_LOE_ID);
alter table @oracle_dots@.RNACATEGORY add constraint PK_RNACATEGORY primary key (RNA_CATEGORY_ID);
alter table @oracle_dots@.RNAFEATUREEXON add constraint PK_RNAFEATUREEXON primary key (RNA_FEATURE_EXON_ID);
alter table @oracle_dots@.RNAICONSTRUCT add constraint PK_RNAICONSTRUCT primary key (RNAI_CONSTRUCT_ID);
alter table @oracle_dots@.RNAINSTANCE add constraint PK_RNAINSTANCE primary key (RNA_INSTANCE_ID);
alter table @oracle_dots@.RNAINSTANCECATEGORY add constraint PK_RNAINSTANCECATEGORY primary key (RNA_INSTANCE_CATEGORY_ID);
alter table @oracle_dots@.RNAIPHENOTYPE add constraint PK_RNAIPHENOTYPE primary key (RNAI_PHENOTYPE_ID);
alter table @oracle_dots@.RNARNACATEGORY add constraint PK_RNARNACATEGORY primary key (RNA_RNA_CATEGORY_ID);
alter table @oracle_dots@.ROWSET add constraint PK_ROWSET primary key (ROW_SET_ID);
alter table @oracle_dots@.ROWSETMEMBER add constraint PK_ROWSETMEMBER primary key (ROW_SET_MEMBER_ID);
alter table @oracle_dots@.SECONDARYACCS add constraint PK_SECONDARYACCS primary key (SECONDARY_ACCS_ID);
alter table @oracle_dots@.SEQGROUPEXPERIMENTIMP add constraint PK_SEQGROUPEXPERIMENTIMP primary key (SEQ_GROUP_EXPERIMENT_ID);
alter table @oracle_dots@.SEQUENCEFAMILY add constraint PK_SEQUENCEFAMILY primary key (SEQUENCE_FAMILY_ID);
alter table @oracle_dots@.SEQUENCEFAMILYEXPERIMENT add constraint PK_SEQUENCEFAMILYEXPERIMENT primary key (SEQUENCE_FAMILY_EXPERIMENT_ID);
alter table @oracle_dots@.SEQUENCEGROUPFAMILY add constraint PK_SEQUENCEGROUPFAMILY primary key (SEQUENCE_GROUP_FAMILY_ID);
alter table @oracle_dots@.SEQUENCEGROUPIMP add constraint PK_SEQUENCEGROUPIMP primary key (SEQUENCE_GROUP_ID);
alter table @oracle_dots@.SEQUENCEPIECE add constraint PK_SEQUENCEPIECE primary key (SEQUENCE_PIECE_ID);
alter table @oracle_dots@.SEQUENCESEQUENCEGROUP add constraint PK_SEQUENCESEQUENCEGROUP primary key (SEQUENCE_SEQUENCE_GROUP_ID);
alter table @oracle_dots@.SEQUENCETYPE add constraint PK_SEQUENCETYPE primary key (SEQUENCE_TYPE_ID);
alter table @oracle_dots@.SIMILARITY add constraint PK_SIMILARITY primary key (SIMILARITY_ID);
alter table @oracle_dots@.SIMILARITYSPAN add constraint PK_SIMILARITYSPAN primary key (SIMILARITY_SPAN_ID);
alter table @oracle_dots@.TRANSLATEDAAFEATSEG add constraint PK_TRANSLATEDAAFEATSEG primary key (TRANSLATED_AA_FEAT_SEG_ID);


/* 160 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

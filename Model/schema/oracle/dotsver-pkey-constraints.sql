
/*                                                                                            */
/* dotsver-pkey-constraints.sql                                                               */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 03:58:52 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL dotsver-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table @oracle_dotsver@.AACOMMENTVER add constraint PK_AACOMMENTVER primary key (AA_COMMENT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AAENTRYVER add constraint PK_AAENTRYVER primary key (AA_ENTRY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AAFAMILYEXPERIMENTVER add constraint PK_AAFAMILYEXPERIMENTVER primary key (AA_FAMILY_EXPERIMENT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AAGENESYNONYMVER add constraint PK_AAGENESYNONYMVER primary key (AA_GENE_SYNONYM_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AAGENEVER add constraint PK_AAGENEVER primary key (AA_GENE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AALOCATIONVER add constraint PK_AALOCATIONVER primary key (AA_LOCATION_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AAMOTIFGOTERMRULEVER add constraint PK_AAMOTIFGOTERMRULEVER primary key (AA_MOTIF_GO_TERM_RULE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AASEQGROUPEXPERIMENTIMPVER add constraint PK_AASEQGROUPEXPERIMENTIMPVER primary key (AA_SEQ_GROUP_EXPERIMENT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AASEQUENCEDBREFVER add constraint PK_AASEQUENCEDBREFVER primary key (AA_SEQUENCE_DB_REF_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AASEQUENCEFAMILYVER add constraint PK_AASEQUENCEFAMILYVER primary key (AA_SEQUENCE_FAMILY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AASEQUENCEGROUPFAMILYVER add constraint PK_AASEQUENCEGROUPFAMILYVER primary key (AA_SEQUENCE_GROUP_FAMILY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AASEQUENCEGROUPIMPVER add constraint PK_AASEQUENCEGROUPIMPVER primary key (AA_SEQUENCE_GROUP_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AASEQUENCEIMPVER add constraint PK_AASEQUENCEIMPVER primary key (AA_SEQUENCE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AASEQUENCEKEYWORDVER add constraint PK_AASEQUENCEKEYWORDVER primary key (AA_SEQUENCE_KEYWORD_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AASEQUENCEORGANELLEVER add constraint PK_AASEQUENCEORGANELLEVER primary key (AA_SEQUENCE_ORGANELLE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AASEQUENCEREFVER add constraint PK_AASEQUENCEREFVER primary key (AA_SEQUENCE_REF_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AASEQUENCESEQUENCEGROUPVER add constraint PK_AASEQUENCESEQUENCEGROUPVER primary key (AA_SEQUENCE_SEQUENCE_GROUP_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.AASEQUENCETAXONVER add constraint PK_AASEQUENCETAXONVER primary key (AA_SEQUENCE_TAXON_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.ANATOMYLIBRARYVER add constraint PK_ANATOMYLIBRARYVER primary key (ANATOMY_LIBRARY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.ANATOMYLOEVER add constraint PK_ANATOMYLOEVER primary key (ANATOMY_LOE_ID);
alter table @oracle_dotsver@.ASSEMBLYANATOMYPERCENTVER add constraint PK_ASSEMBLYANATOMYPERCENTVER primary key (ASSEMBLY_ANATOMY_PERCENT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.ASSEMBLYSEQUENCESNPVER add constraint PK_ASSEMBLYSEQUENCESNPVER primary key (ASSEMBLY_SEQUENCE_SNP_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.ASSEMBLYSEQUENCEVER add constraint PK_ASSEMBLYSEQUENCEVER primary key (ASSEMBLY_SEQUENCE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.ASSEMBLYSNPVER add constraint PK_ASSEMBLYSNPVER primary key (ASSEMBLY_SNP_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.ATTRIBUTIONVER add constraint PK_ATTRIBUTIONVER primary key (ATTRIBUTION_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.BESTSIMILARITYPAIRVER add constraint PK_BESTSIMILARITYPAIRVER primary key (BEST_SIMILARITY_PAIR_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.CLONEINSETVER add constraint PK_CLONEINSETVER primary key (CLONE_IN_SET_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.CLONESETVER add constraint PK_CLONESETVER primary key (CLONE_SET_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.CLONEVER add constraint PK_CLONEVER primary key (CLONE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.COMMENTNAMEVER add constraint PK_COMMENTNAMEVER primary key (COMMENT_NAME_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.COMMENTSVER add constraint PK_COMMENTSVER primary key (COMMENTS_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.COMPLEXANATOMYVER add constraint PK_COMPLEXANATOMYVER primary key (COMPLEX_ANATOMY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.COMPLEXCOMPONENTVER add constraint PK_COMPLEXCOMPONENTVER primary key (COMPLEX_COMPONENT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.COMPLEXTYPEVER add constraint PK_COMPLEXTYPEVER primary key (COMPLEX_TYPE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.COMPLEXVER add constraint PK_COMPLEXVER primary key (COMPLEX_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.CONSISTENTALIGNMENTVER add constraint PK_CONSISTENTALIGNMENTVER primary key (CONSISTENT_ALIGNMENT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.DBREFNAFEATUREVER add constraint PK_DBREFNAFEATUREVER primary key (DB_REF_NA_FEATURE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.DBREFPFAMENTRYVER add constraint PK_DBREFPFAMENTRYVER primary key (DB_REF_PFAM_ENTRY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.EFFECTORACTIONTYPEVER add constraint PK_EFFECTORACTIONTYPEVER primary key (EFFECTOR_ACTION_TYPE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.ENDSEQUENCEPAIRMAPVER add constraint PK_ENDSEQUENCEPAIRMAPVER primary key (END_SEQUENCE_PAIR_MAP_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.EPCRVER add constraint PK_EPCRVER primary key (EPCR_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.ESTVER add constraint PK_ESTVER primary key (EST_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.EVIDENCEVER add constraint PK_EVIDENCEVER primary key (EVIDENCE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.EXONLOCATIONVER add constraint PK_EXONLOCATIONVER primary key (EXON_LOCATION_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.FAMILYGENEVER add constraint PK_FAMILYGENEVER primary key (FAMILY_GENE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.FAMILYPROTEINVER add constraint PK_FAMILYPROTEINVER primary key (FAMILY_PROTEIN_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.FAMILYVER add constraint PK_FAMILYVER primary key (FAMILY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.FEATURENAMEVER add constraint PK_FEATURENAMEVER primary key (FEATURE_NAME_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.FINGERPRINTCLONECONTIGVER add constraint PK_FINGERPRINTCLONECONTIGVER primary key (FINGERPRINT_CLONE_CONTIG_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.FINGERPRINTCLONEMARKERVER add constraint PK_FINGERPRINTCLONEMARKERVER primary key (FINGERPRINT_CLONE_MARKER_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.FINGERPRINTCLONEVER add constraint PK_FINGERPRINTCLONEVER primary key (FINGERPRINT_CLONE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.FINGERPRINTCONTIGVER add constraint PK_FINGERPRINTCONTIGVER primary key (FINGERPRINT_CONTIG_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.FINGERPRINTMAPVER add constraint PK_FINGERPRINTMAPVER primary key (FINGERPRINT_MAP_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.GENEALIASVER add constraint PK_GENEALIASVER primary key (GENE_ALIAS_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.GENECATEGORYVER add constraint PK_GENECATEGORYVER primary key (GENE_CATEGORY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.GENECHROMOSOMALLOCATIONVER add constraint PK_GENECHROMOSOMALLOCATIONVER primary key (GENE_CHROMOSOMAL_LOCATION_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.GENEFAMILYRELATIONVER add constraint PK_GENEFAMILYRELATIONVER primary key (GENE_FAMILY_RELATION_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.GENEFAMILYVER add constraint PK_GENEFAMILYVER primary key (GENE_FAMILY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.GENEFEATURESAGETAGLINKVER add constraint PK_GENEFEATURESAGETAGLINKVER primary key (GENE_FEATURE_SAGE_TAG_LINK_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.GENEFEATURESEQOVERLAPVER add constraint PK_GENEFEATURESEQOVERLAPVER primary key (GENE_FEATURE_SEQ_OVERLAP_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.GENEINSTANCECATEGORYVER add constraint PK_GENEINSTANCECATEGORYVER primary key (GENE_INSTANCE_CATEGORY_ID);
alter table @oracle_dotsver@.GENEINSTANCEVER add constraint PK_GENEINSTANCEVER primary key (GENE_INSTANCE_ID);
alter table @oracle_dotsver@.GENESUPERFAMILYVER add constraint PK_GENESUPERFAMILYVER primary key (GENE_SUPER_FAMILY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.GENESYNONYMVER add constraint PK_GENESYNONYMVER primary key (GENE_SYNONYM_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.GENETRAPASSEMBLYVER add constraint PK_GENETRAPASSEMBLYVER primary key (GENE_TRAP_ASSEMBLY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.INDEXWORDLINKVER add constraint PK_INDEXWORDLINKVER primary key (INDEX_WORD_LINK_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.INDEXWORDSIMLINKVER add constraint PK_INDEXWORDSIMLINKVER primary key (INDEX_WORD_SIM_LINK_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.INDEXWORDVER add constraint PK_INDEXWORDVER primary key (INDEX_WORD_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.INTERACTIONINTERACTIONLOEVER add constraint PK_INTERACTINTERACTIONLOEVER primary key (INTERACTION_INTERACTION_LOE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.INTERACTIONLOEVER add constraint PK_INTERACTIONLOEVER primary key (INTERACTION_LOE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.INTERACTIONTYPEVER add constraint PK_INTERACTIONTYPEVER primary key (INTERACTION_TYPE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.INTERACTIONVER add constraint PK_INTERACTIONVER primary key (INTERACTION_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.ISEXPRESSEDVER add constraint PK_ISEXPRESSEDVER primary key (IS_EXPRESSED_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.KEYWORDVER add constraint PK_KEYWORDVER primary key (KEYWORD_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.LIBRARYVER add constraint PK_LIBRARYVER primary key (LIBRARY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.MERGESPLITVER add constraint PK_MERGESPLITVER primary key (MERGE_SPLIT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.MOTIFVER add constraint PK_MOTIFVER primary key (MOTIF_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NACOMMENTVER add constraint PK_NACOMMENTVER primary key (NA_COMMENT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NAENTRYVER add constraint PK_NAENTRYVER primary key (NA_ENTRY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NAFEATRELATIONSHIPTYPEVER add constraint PK_NAFEATRELATIONSHIPTYPEVER primary key (NA_FEAT_RELATIONSHIP_TYPE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NAFEATURECOMMENTVER add constraint PK_NAFEATURECOMMENTVER primary key (NA_FEATURE_COMMENT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NAFEATURENAGENEVER add constraint PK_NAFEATURENAGENEVER primary key (NA_FEATURE_NA_GENE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NAFEATURENAPROTEINVER add constraint PK_NAFEATURENAPROTEINVER primary key (NA_FEATURE_NA_PROTEIN_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NAFEATURENAPTVER add constraint PK_NAFEATURENAPTVER primary key (NA_FEATURE_NA_PT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NAFEATURERELATIONSHIPVER add constraint PK_NAFEATURERELATIONSHIPVER primary key (NA_FEATURE_RELATIONSHIP_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NAGENEVER add constraint PK_NAGENEVER primary key (NA_GENE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NALOCATIONVER add constraint PK_NALOCATIONVER primary key (NA_LOCATION_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NAPRIMARYTRANSCRIPTVER add constraint PK_NAPRIMARYTRANSCRIPTVER primary key (NA_PRIMARY_TRANSCRIPT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NAPROTEINVER add constraint PK_NAPROTEINVER primary key (NA_PROTEIN_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NASEQCYTOLOCATIONVER add constraint PK_NASEQCYTOLOCATIONVER primary key (NA_SEQ_CYTO_LOCATION_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NASEQUENCEIMPVER add constraint PK_NASEQUENCEIMPVER primary key (NA_SEQUENCE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NASEQUENCEKEYWORDVER add constraint PK_NASEQUENCEKEYWORDVER primary key (NA_SEQUENCE_KEYWORD_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NASEQUENCEORGANELLEVER add constraint PK_NASEQUENCEORGANELLEVER primary key (NA_SEQUENCE_ORGANELLE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NASEQUENCEREFVER add constraint PK_NASEQUENCEREFVER primary key (NA_SEQUENCE_REF_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.NRDBENTRYVER add constraint PK_NRDBENTRYVER primary key (NRDB_ENTRY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.OPTICALMAPALIGNMENTSPANVER add constraint PK_OPTICALMAPALIGNMENTSPANVER primary key (OPTICAL_MAP_ALIGNMENT_SPAN_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.OPTICALMAPALIGNMENTVER add constraint PK_OPTICALMAPALIGNMENTVER primary key (OPTICAL_MAP_ALIGNMENT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.OPTICALMAPFRAGMENTVER add constraint PK_OPTICALMAPFRAGMENTVER primary key (OPTICAL_MAP_FRAGMENT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.OPTICALMAPVER add constraint PK_OPTICALMAPVER primary key (OPTICAL_MAP_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.ORGANELLEVER add constraint PK_ORGANELLEVER primary key (ORGANELLE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.PATHWAYINTERACTIONVER add constraint PK_PATHWAYINTERACTIONVER primary key (PATHWAY_INTERACTION_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.PATHWAYVER add constraint PK_PATHWAYVER primary key (PATHWAY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.PFAMENTRYVER add constraint PK_PFAMENTRYVER primary key (PFAM_ENTRY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.PROJECTLINKVER add constraint PK_PROJECTLINKVER primary key (PROJECT_LINK_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.PROTEINCATEGORYVER add constraint PK_PROTEINCATEGORYVER primary key (PROTEIN_CATEGORY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.PROTEININSTANCEVER add constraint PK_PROTEININSTANCEVER primary key (PROTEIN_INSTANCE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.PROTEINPROPERTYTYPEVER add constraint PK_PROTEINPROPERTYTYPEVER primary key (PROTEIN_PROPERTY_TYPE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.PROTEINPROTEINCATEGORYVER add constraint PK_PROTEINPROTEINCATEGORYVER primary key (PROTEIN_PROTEIN_CATEGORY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.PROTEINSYNONYMVER add constraint PK_PROTEINSYNONYMVER primary key (PROTEIN_SYNONYM_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.PROTEINVER add constraint PK_PROTEINVER primary key (PROTEIN_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.REPEATTYPEVER add constraint PK_REPEATTYPEVER primary key (REPEAT_TYPE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.RHMAPMARKERVER add constraint PK_RHMAPMARKERVER primary key (RH_MAP_MARKER_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.RHMAPVER add constraint PK_RHMAPVER primary key (RH_MAP_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.RHMARKERVER add constraint PK_RHMARKERVER primary key (RH_MARKER_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.RNAANATOMYLOEVER add constraint PK_RNAANATOMYLOEVER primary key (RNA_ANATOMY_LOE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.RNAANATOMYVER add constraint PK_RNAANATOMYVER primary key (RNA_ANATOMY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.RNACATEGORYVER add constraint PK_RNACATEGORYVER primary key (RNA_CATEGORY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.RNAFEATUREEXONVER add constraint PK_RNAFEATUREEXONVER primary key (RNA_FEATURE_EXON_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.RNAICONSTRUCTVER add constraint PK_RNAICONSTRUCTVER primary key (RNAI_CONSTRUCT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.RNAINSTANCECATEGORYVER add constraint PK_RNAINSTANCECATEGORYVER primary key (RNA_INSTANCE_CATEGORY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.RNAINSTANCEVER add constraint PK_RNAINSTANCEVER primary key (RNA_INSTANCE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.RNARNACATEGORYVER add constraint PK_RNARNACATEGORYVER primary key (RNA_RNA_CATEGORY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.RNAVER add constraint PK_RNAVER primary key (RNA_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.ROWSETMEMBERVER add constraint PK_ROWSETMEMBERVER primary key (ROW_SET_MEMBER_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.ROWSETVER add constraint PK_ROWSETVER primary key (ROW_SET_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.SECONDARYACCSVER add constraint PK_SECONDARYACCSVER primary key (SECONDARY_ACCS_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.SEQGROUPEXPERIMENTIMPVER add constraint PK_SEQGROUPEXPERIMENTIMPVER primary key (SEQ_GROUP_EXPERIMENT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.SEQUENCEFAMILYEXPERIMENTVER add constraint PK_SEQUENCEFAMILYEXPERIMENTVER primary key (SEQUENCE_FAMILY_EXPERIMENT_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.SEQUENCEFAMILYVER add constraint PK_SEQUENCEFAMILYVER primary key (SEQUENCE_FAMILY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.SEQUENCEGROUPFAMILYVER add constraint PK_SEQUENCEGROUPFAMILYVER primary key (SEQUENCE_GROUP_FAMILY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.SEQUENCEGROUPIMPVER add constraint PK_SEQUENCEGROUPIMPVER primary key (SEQUENCE_GROUP_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.SEQUENCEPIECEVER add constraint PK_SEQUENCEPIECEVER primary key (SEQUENCE_PIECE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.SEQUENCESEQUENCEGROUPVER add constraint PK_SEQUENCESEQUENCEGROUPVER primary key (SEQUENCE_SEQUENCE_GROUP_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.SEQUENCETYPEVER add constraint PK_SEQUENCETYPEVER primary key (SEQUENCE_TYPE_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.SIMILARITYSPANVER add constraint PK_SIMILARITYSPANVER primary key (SIMILARITY_SPAN_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.SIMILARITYVER add constraint PK_SIMILARITYVER primary key (SIMILARITY_ID,MODIFICATION_DATE);
alter table @oracle_dotsver@.TRANSLATEDAAFEATSEGVER add constraint PK_TRANSLATEDAAFEATSEGVER primary key (TRANSLATED_AA_FEAT_SEG_ID,MODIFICATION_DATE);


/* 137 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

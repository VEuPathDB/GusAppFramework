
/*                                                                                            */
/* sres-indexes.sql                                                                           */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Thu Feb 13 22:47:14 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL sres-indexes.log

/* ABSTRACT */
create index @oracle_sres@.ABSTRACT_IND01 on @oracle_sres@.ABSTRACT (BIBLIOGRAPHIC_REFERENCE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* ANATOMY */
create index @oracle_sres@.ANATOMY_IND01 on @oracle_sres@.ANATOMY (PARENT_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* ANATOMYLINEAGE */
create index @oracle_sres@.ANATOMYLINEAGE_IND01 on @oracle_sres@.ANATOMYLINEAGE (ANATOMY_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.ANATOMYLINEAGE_IND02 on @oracle_sres@.ANATOMYLINEAGE (LINEAGE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* AUTHOR */


/* BIBLIOGRAPHICREFERENCE */
create index @oracle_sres@.BIBLIOGRAPHICREFERENCE_IND01 on @oracle_sres@.BIBLIOGRAPHICREFERENCE (BIB_REF_TYPE_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.BIBLIOGRAPHICREFERENCE_IND02 on @oracle_sres@.BIBLIOGRAPHICREFERENCE (CONTACT_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* BIBREFANNOTATION */
create index @oracle_sres@.BIBREFANNOTATION_IND01 on @oracle_sres@.BIBREFANNOTATION (BIBLIOGRAPHIC_REFERENCE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* BIBREFAUTHOR */
create index @oracle_sres@.BIBREFAUTHOR_IND01 on @oracle_sres@.BIBREFAUTHOR (AUTHOR_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.BIBREFAUTHOR_IND02 on @oracle_sres@.BIBREFAUTHOR (BIBLIOGRAPHIC_REFERENCE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* BIBREFTYPE */
create index @oracle_sres@.BIBREFTYPE_IND01 on @oracle_sres@.BIBREFTYPE (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* CONTACT */
create unique index @oracle_sres@.CONTACT_AK01 on @oracle_sres@.CONTACT (NAME)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.CONTACT_IND01 on @oracle_sres@.CONTACT (AFFILIATION_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.CONTACT_IND02 on @oracle_sres@.CONTACT (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* DBREF */
create index @oracle_sres@.DBREF_IND01 on @oracle_sres@.DBREF (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* DEVELOPMENTALSTAGE */
create index @oracle_sres@.DEVELOPMENTALSTAGE_IND01 on @oracle_sres@.DEVELOPMENTALSTAGE (PARENT_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.DEVELOPMENTALSTAGE_IND02 on @oracle_sres@.DEVELOPMENTALSTAGE (TAXON_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* DISEASE */
create index @oracle_sres@.DISEASE_IND01 on @oracle_sres@.DISEASE (PARENT_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* ENZYMECLASS */
create index @oracle_sres@.ENZYMECLASS_IND01 on @oracle_sres@.ENZYMECLASS (PARENT_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.ENZYMECLASS_IND02 on @oracle_sres@.ENZYMECLASS (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* ENZYMECLASSATTRIBUTE */
create index @oracle_sres@.ENZYMECLASSATTRIBUTE_IND01 on @oracle_sres@.ENZYMECLASSATTRIBUTE (ENZYME_CLASS_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* EXTERNALDATABASE */


/* EXTERNALDATABASEENTRY */
create index @oracle_sres@.EXTERNALDATABASEENTRY_IND01 on @oracle_sres@.EXTERNALDATABASEENTRY (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.EXTERNALDATABASEENTRY_IND02 on @oracle_sres@.EXTERNALDATABASEENTRY (REVIEW_STATUS_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* EXTERNALDATABASEKEYWORD */
create index @oracle_sres@.EXTERNALDATABASEKEYWORD_IND01 on @oracle_sres@.EXTERNALDATABASEKEYWORD (KEYWORD_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.EXTERNALDATABASEKEYWORD_IND02 on @oracle_sres@.EXTERNALDATABASEKEYWORD (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* EXTERNALDATABASELINK */
create index @oracle_sres@.EXTERNALDATABASELINK_IND01 on @oracle_sres@.EXTERNALDATABASELINK (LINK_TABLE_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.EXTERNALDATABASELINK_IND02 on @oracle_sres@.EXTERNALDATABASELINK (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* EXTERNALDATABASERELEASE */
create index @oracle_sres@.EXTERNALDATABASERELEASE_IND01 on @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* GENETICCODE */


/* GOEVIDENCECODE */


/* GORELATIONSHIP */
create index @oracle_sres@.GORELATIONSHIP_IND03 on @oracle_sres@.GORELATIONSHIP (GO_RELATIONSHIP_TYPE_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.GORELATIONSHIP_IND01 on @oracle_sres@.GORELATIONSHIP (PARENT_TERM_ID,CHILD_TERM_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.GORELATIONSHIP_IND02 on @oracle_sres@.GORELATIONSHIP (CHILD_TERM_ID,PARENT_TERM_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* GORELATIONSHIPTYPE */


/* GOSYNONYM */
create index @oracle_sres@.GOSYNONYM_IND01 on @oracle_sres@.GOSYNONYM (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.GOSYNONYM_IND02 on @oracle_sres@.GOSYNONYM (GO_TERM_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* GOTERM */
create index @oracle_sres@.GOTERM_IND01 on @oracle_sres@.GOTERM (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.GOTERM_IND02 on @oracle_sres@.GOTERM (ANCESTOR_GO_TERM_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* LINEAGE */


/* MGEDONTOLOGYRELATIONSHIP */
create index @oracle_sres@.MGEDONTOLOGYRELATIONSHIP_IND01 on @oracle_sres@.MGEDONTOLOGYRELATIONSHIP (CHILD_TERM_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.MGEDONTOLOGYRELATIONSHIP_IND02 on @oracle_sres@.MGEDONTOLOGYRELATIONSHIP (PARENT_TERM_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.MGEDONTOLOGYRELATIONSHIP_IND03 on @oracle_sres@.MGEDONTOLOGYRELATIONSHIP (ONTOLOGY_RELATIONSHIP_TYPE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* MGEDONTOLOGYTERM */
create index @oracle_sres@.MGEDONTOLOGYTERM_IND01 on @oracle_sres@.MGEDONTOLOGYTERM (EXTERNAL_DATABASE_RELEASE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* MUTAGEN */


/* ONTOLOGYRELATIONSHIPTYPE */


/* PATOATTRIBUTE */


/* PHENOTYPE */
create index @oracle_sres@.PHENOTYPE_IND01 on @oracle_sres@.PHENOTYPE (ANATOMY_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.PHENOTYPE_IND02 on @oracle_sres@.PHENOTYPE (CELL_TYPE_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.PHENOTYPE_IND03 on @oracle_sres@.PHENOTYPE (DEVELOPMENTAL_STAGE_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.PHENOTYPE_IND04 on @oracle_sres@.PHENOTYPE (PARENT_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.PHENOTYPE_IND05 on @oracle_sres@.PHENOTYPE (PATO_ATTRIBUTE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* PHENOTYPECLASS */


/* REFERENCE */
create index @oracle_sres@.REFERENCE_IND01 on @oracle_sres@.REFERENCE (DB_REF_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* REVIEWSTATUS */


/* SEQUENCEONTOLOGY */


/* SEQUENCEREFERENCE */
create index @oracle_sres@.SEQUENCEREFERENCE_IND01 on @oracle_sres@.SEQUENCEREFERENCE (BIBLIOGRAPHIC_REFERENCE_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* TAXON */
create index @oracle_sres@.TAXON_IND01 on @oracle_sres@.TAXON (NCBI_TAX_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.TAXON_IND02 on @oracle_sres@.TAXON (GENETIC_CODE_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.TAXON_IND03 on @oracle_sres@.TAXON (MITOCHONDRIAL_GENETIC_CODE_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.TAXON_IND04 on @oracle_sres@.TAXON (PARENT_ID)  TABLESPACE @oracle_sresIndexTablespace@;

/* TAXONNAME */
create index @oracle_sres@.TAXONNAME_IND01 on @oracle_sres@.TAXONNAME (TAXON_ID)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.TAXONNAME_IND02 on @oracle_sres@.TAXONNAME (NAME)  TABLESPACE @oracle_sresIndexTablespace@;
create index @oracle_sres@.TAXONNAME_IND04 on @oracle_sres@.TAXONNAME (NAME_CLASS)  TABLESPACE @oracle_sresIndexTablespace@;



/* 52 index(es) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

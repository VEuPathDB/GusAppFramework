
/*                                                                                            */
/* sres-pkey-constraints.sql                                                                  */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 20:43:22 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL sres-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table @oracle_sres@.ABSTRACT add constraint PK_ABSTRACT primary key (ABSTRACT_ID);
alter table @oracle_sres@.ANATOMY add constraint PK_ANATOMY primary key (ANATOMY_ID);
alter table @oracle_sres@.ANATOMYLINEAGE add constraint PK_ANATOMYLINEAGE primary key (ANATOMY_LINEAGE_ID);
alter table @oracle_sres@.AUTHOR add constraint PK_AUTHOR primary key (AUTHOR_ID);
alter table @oracle_sres@.BIBLIOGRAPHICREFERENCE add constraint PK_BIBLIOGRAPHICREFERENCE primary key (BIBLIOGRAPHIC_REFERENCE_ID);
alter table @oracle_sres@.BIBREFANNOTATION add constraint PK_BIBREFANNOT primary key (BIB_REF_ANNOTATION_ID);
alter table @oracle_sres@.BIBREFAUTHOR add constraint PK_BIBREFAUTHOR primary key (BIB_REF_AUTHOR_ID);
alter table @oracle_sres@.BIBREFTYPE add constraint PK_BIBREFTYPE primary key (BIB_REF_TYPE_ID);
alter table @oracle_sres@.CONTACT add constraint PK_CONTACT primary key (CONTACT_ID);
alter table @oracle_sres@.DBREF add constraint PK_DBREF primary key (DB_REF_ID);
alter table @oracle_sres@.DEVELOPMENTALSTAGE add constraint PK_DEVSTAGE primary key (DEVELOPMENTAL_STAGE_ID);
alter table @oracle_sres@.DISEASE add constraint PK_DISEASE primary key (DISEASE_ID);
alter table @oracle_sres@.ENZYMECLASS add constraint ENZYMECLASS_PK primary key (ENZYME_CLASS_ID);
alter table @oracle_sres@.ENZYMECLASSATTRIBUTE add constraint ENZYMECLASSATTRIBUTE_PK primary key (ENZYME_CLASS_ATTRIBUTE_ID);
alter table @oracle_sres@.EXTERNALDATABASE add constraint PK_EXTERNALDATABASE primary key (EXTERNAL_DATABASE_ID);
alter table @oracle_sres@.EXTERNALDATABASEENTRY add constraint PK_EXTERNALDATABASEENTRY primary key (EXTERNAL_DATABASE_ENTRY_ID);
alter table @oracle_sres@.EXTERNALDATABASEKEYWORD add constraint PK_EXTERNALDATABASEKEYWORD primary key (EXTERNAL_DATABASE_KEYWORD_ID);
alter table @oracle_sres@.EXTERNALDATABASELINK add constraint PK_EXTERNALDATABASELINK primary key (EXTERNAL_DATABASE_LINK_ID);
alter table @oracle_sres@.EXTERNALDATABASERELEASE add constraint PK_EXTERNALDATABASERELEASE primary key (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_sres@.GENETICCODE add constraint PK_GENETICCODE primary key (GENETIC_CODE_ID);
alter table @oracle_sres@.GOEVIDENCECODE add constraint GOEVIDENCECODE_PK primary key (GO_EVIDENCE_CODE_ID);
alter table @oracle_sres@.GORELATIONSHIP add constraint GORELATIONSHIP_PK primary key (GO_RELATIONSHIP_ID);
alter table @oracle_sres@.GORELATIONSHIPTYPE add constraint GORELATIONSHIPTYPE_PK primary key (GO_RELATIONSHIP_TYPE_ID);
alter table @oracle_sres@.GOSYNONYM add constraint PK_GOSYNONYM primary key (GO_SYNONYM_ID);
alter table @oracle_sres@.GOTERM add constraint GOTERM_PK primary key (GO_TERM_ID);
alter table @oracle_sres@.LINEAGE add constraint PK_LINEAGE primary key (LINEAGE_ID);
alter table @oracle_sres@.MGEDONTOLOGYRELATIONSHIP add constraint PK_MGEDONTOLOGYRELATIONSHIP primary key (MGED_ONTOLOGY_RELATIONSHIP_ID);
alter table @oracle_sres@.MGEDONTOLOGYTERM add constraint PK_MGEDONTOLOGYTERM primary key (MGED_ONTOLOGY_TERM_ID);
alter table @oracle_sres@.MUTAGEN add constraint PK_MUTAGEN primary key (MUTAGEN_ID);
alter table @oracle_sres@.ONTOLOGYRELATIONSHIPTYPE add constraint PK_ONTOLOGYRELATIONSHIPTYPE primary key (ONTOLOGY_RELATIONSHIP_TYPE_ID);
alter table @oracle_sres@.PATOATTRIBUTE add constraint PK_PATOATTRIBUTE primary key (PATO_ATTRIBUTE_ID);
alter table @oracle_sres@.PHENOTYPE add constraint PK_PHENOTYPE primary key (PHENOTYPE_ID);
alter table @oracle_sres@.PHENOTYPECLASS add constraint PK_PHENOTYPECLASS primary key (PHENOTYPE_CLASS_ID);
alter table @oracle_sres@.REFERENCE add constraint PK_REFERENCE primary key (REFERENCE_ID);
alter table @oracle_sres@.REVIEWSTATUS add constraint PK_REVIEWSTATUS primary key (REVIEW_STATUS_ID);
alter table @oracle_sres@.SEQUENCEONTOLOGY add constraint PK_SEQUENCEONTOLOGY primary key (SEQUENCE_ONTOLOGY_ID);
alter table @oracle_sres@.SEQUENCEREFERENCE add constraint PK_SEQUENCEREF primary key (SEQUENCE_REFERENCE_ID);
alter table @oracle_sres@.TAXON add constraint PK_TAXON primary key (TAXON_ID);
alter table @oracle_sres@.TAXONNAME add constraint PK_TAXONNAME primary key (TAXON_NAME_ID);


/* 39 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

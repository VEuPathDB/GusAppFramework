
/*                                                                                            */
/* sres-pkey-constraints.sql                                                                  */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 12:23:17 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL sres-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table SRestest.ABSTRACT add constraint PK_ABSTRACT primary key (ABSTRACT_ID);
alter table SRestest.ANATOMY add constraint PK_ANATOMY primary key (ANATOMY_ID);
alter table SRestest.ANATOMYLINEAGE add constraint PK_ANATOMYLINEAGE primary key (ANATOMY_LINEAGE_ID);
alter table SRestest.AUTHOR add constraint PK_AUTHOR primary key (AUTHOR_ID);
alter table SRestest.BIBLIOGRAPHICREFERENCE add constraint PK_BIBLIOGRAPHICREFERENCE primary key (BIBLIOGRAPHIC_REFERENCE_ID);
alter table SRestest.BIBREFANNOTATION add constraint PK_BIBREFANNOT primary key (BIB_REF_ANNOTATION_ID);
alter table SRestest.BIBREFAUTHOR add constraint PK_BIBREFAUTHOR primary key (BIB_REF_AUTHOR_ID);
alter table SRestest.BIBREFTYPE add constraint PK_BIBREFTYPE primary key (BIB_REF_TYPE_ID);
alter table SRestest.CONTACT add constraint PK_CONTACT primary key (CONTACT_ID);
alter table SRestest.DBREF add constraint PK_DBREF primary key (DB_REF_ID);
alter table SRestest.DEVELOPMENTALSTAGE add constraint PK_DEVSTAGE primary key (DEVELOPMENTAL_STAGE_ID);
alter table SRestest.DISEASE add constraint PK_DISEASE primary key (DISEASE_ID);
alter table SRestest.ENZYMECLASS add constraint ENZYMECLASS_PK primary key (ENZYME_CLASS_ID);
alter table SRestest.ENZYMECLASSATTRIBUTE add constraint ENZYMECLASSATTRIBUTE_PK primary key (ENZYME_CLASS_ATTRIBUTE_ID);
alter table SRestest.EXTERNALDATABASE add constraint PK_EXTERNALDATABASE primary key (EXTERNAL_DATABASE_ID);
alter table SRestest.EXTERNALDATABASEENTRY add constraint PK_EXTERNALDATABASEENTRY primary key (EXTERNAL_DATABASE_ENTRY_ID);
alter table SRestest.EXTERNALDATABASEKEYWORD add constraint PK_EXTERNALDATABASEKEYWORD primary key (EXTERNAL_DATABASE_KEYWORD_ID);
alter table SRestest.EXTERNALDATABASELINK add constraint PK_EXTERNALDATABASELINK primary key (EXTERNAL_DATABASE_LINK_ID);
alter table SRestest.EXTERNALDATABASERELEASE add constraint PK_EXTERNALDATABASERELEASE primary key (EXTERNAL_DATABASE_RELEASE_ID);
alter table SRestest.GENETICCODE add constraint PK_GENETICCODE primary key (GENETIC_CODE_ID);
alter table SRestest.GOEVIDENCECODE add constraint GOEVIDENCECODE_PK primary key (GO_EVIDENCE_CODE_ID);
alter table SRestest.GORELATIONSHIP add constraint GORELATIONSHIP_PK primary key (GO_RELATIONSHIP_ID);
alter table SRestest.GORELATIONSHIPTYPE add constraint GORELATIONSHIPTYPE_PK primary key (GO_RELATIONSHIP_TYPE_ID);
alter table SRestest.GOSYNONYM add constraint PK_GOSYNONYM primary key (GO_SYNONYM_ID);
alter table SRestest.GOTERM add constraint GOTERM_PK primary key (GO_TERM_ID);
alter table SRestest.LINEAGE add constraint PK_LINEAGE primary key (LINEAGE_ID);
alter table SRestest.MGEDONTOLOGYRELATIONSHIP add constraint PK_MGEDONTOLOGYRELATIONSHIP primary key (MGED_ONTOLOGY_RELATIONSHIP_ID);
alter table SRestest.MGEDONTOLOGYTERM add constraint PK_MGEDONTOLOGYTERM primary key (MGED_ONTOLOGY_TERM_ID);
alter table SRestest.MUTAGEN add constraint PK_MUTAGEN primary key (MUTAGEN_ID);
alter table SRestest.ONTOLOGYRELATIONSHIPTYPE add constraint PK_ONTOLOGYRELATIONSHIPTYPE primary key (ONTOLOGY_RELATIONSHIP_TYPE_ID);
alter table SRestest.PATOATTRIBUTE add constraint PK_PATOATTRIBUTE primary key (PATO_ATTRIBUTE_ID);
alter table SRestest.PHENOTYPE add constraint PK_PHENOTYPE primary key (PHENOTYPE_ID);
alter table SRestest.PHENOTYPECLASS add constraint PK_PHENOTYPECLASS primary key (PHENOTYPE_CLASS_ID);
alter table SRestest.REFERENCE add constraint PK_REFERENCE primary key (REFERENCE_ID);
alter table SRestest.REVIEWSTATUS add constraint PK_REVIEWSTATUS primary key (REVIEW_STATUS_ID);
alter table SRestest.SEQUENCEONTOLOGY add constraint PK_SEQUENCEONTOLOGY primary key (SEQUENCE_ONTOLOGY_ID);
alter table SRestest.SEQUENCEREFERENCE add constraint PK_SEQUENCEREF primary key (SEQUENCE_REFERENCE_ID);
alter table SRestest.TAXON add constraint PK_TAXON primary key (TAXON_ID);
alter table SRestest.TAXONNAME add constraint PK_TAXONNAME primary key (TAXON_NAME_ID);


/* 39 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

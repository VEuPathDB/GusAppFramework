
/*                                                                                            */
/* sres-constraints.sql                                                                       */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 12:23:17 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL sres-constraints.log

/* NON-PRIMARY KEY CONSTRAINTS */

/* ABSTRACT */
alter table SRestest.ABSTRACT add constraint FK_ABSTRACT_BIBREF foreign key (BIBLIOGRAPHIC_REFERENCE_ID) references SRestest.BIBLIOGRAPHICREFERENCE (BIBLIOGRAPHIC_REFERENCE_ID);

/* ANATOMY */
alter table SRestest.ANATOMY add constraint ANATOMY_FK02 foreign key (PARENT_ID) references SRestest.ANATOMY (ANATOMY_ID);

/* ANATOMYLINEAGE */
alter table SRestest.ANATOMYLINEAGE add constraint ANATOMYLINEAGE_FK04 foreign key (ANATOMY_ID) references SRestest.ANATOMY (ANATOMY_ID);
alter table SRestest.ANATOMYLINEAGE add constraint ANATOMYLINEAGE_FK05 foreign key (LINEAGE_ID) references SRestest.LINEAGE (LINEAGE_ID);

/* AUTHOR */

/* BIBLIOGRAPHICREFERENCE */
alter table SRestest.BIBLIOGRAPHICREFERENCE add constraint BIBLIOGRAPHICREFERENCE_FK01 foreign key (BIB_REF_TYPE_ID) references SRestest.BIBREFTYPE (BIB_REF_TYPE_ID);
alter table SRestest.BIBLIOGRAPHICREFERENCE add constraint BIBLIOGRAPHICREFERENCE_FK02 foreign key (CONTACT_ID) references SRestest.CONTACT (CONTACT_ID);

/* BIBREFANNOTATION */
alter table SRestest.BIBREFANNOTATION add constraint FK_BIBREFANNOT_BIBREF foreign key (BIBLIOGRAPHIC_REFERENCE_ID) references SRestest.BIBLIOGRAPHICREFERENCE (BIBLIOGRAPHIC_REFERENCE_ID);

/* BIBREFAUTHOR */
alter table SRestest.BIBREFAUTHOR add constraint FK_BIBREFAUTHOR_AUTHOR foreign key (AUTHOR_ID) references SRestest.AUTHOR (AUTHOR_ID);
alter table SRestest.BIBREFAUTHOR add constraint FK_BIBREFAUTHOR_BIBREF foreign key (BIBLIOGRAPHIC_REFERENCE_ID) references SRestest.BIBLIOGRAPHICREFERENCE (BIBLIOGRAPHIC_REFERENCE_ID);

/* BIBREFTYPE */
alter table SRestest.BIBREFTYPE add constraint BIBREFTYPE_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references SRestest.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* CONTACT */
alter table SRestest.CONTACT add constraint CONTACT_FK03 foreign key (AFFILIATION_ID) references SRestest.CONTACT (CONTACT_ID);
alter table SRestest.CONTACT add constraint CONTACT_FK04 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references SRestest.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* DBREF */
alter table SRestest.DBREF add constraint DBREF_FK04 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references SRestest.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* DEVELOPMENTALSTAGE */
alter table SRestest.DEVELOPMENTALSTAGE add constraint DEVELOPMENTALSTAGE_FK01 foreign key (PARENT_ID) references SRestest.DEVELOPMENTALSTAGE (DEVELOPMENTAL_STAGE_ID);
alter table SRestest.DEVELOPMENTALSTAGE add constraint DEVELOPMENTALSTAGE_FK02 foreign key (TAXON_ID) references SRestest.TAXON (TAXON_ID);

/* DISEASE */
alter table SRestest.DISEASE add constraint DISEASE_FK01 foreign key (PARENT_ID) references SRestest.DISEASE (DISEASE_ID);

/* ENZYMECLASS */
alter table SRestest.ENZYMECLASS add constraint ENZYMECLASS_FK01 foreign key (PARENT_ID) references SRestest.ENZYMECLASS (ENZYME_CLASS_ID);
alter table SRestest.ENZYMECLASS add constraint ENZYMECLASS_FK02 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references SRestest.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* ENZYMECLASSATTRIBUTE */
alter table SRestest.ENZYMECLASSATTRIBUTE add constraint ENZYMECLASSATTRIBUTE_FK01 foreign key (ENZYME_CLASS_ID) references SRestest.ENZYMECLASS (ENZYME_CLASS_ID);

/* EXTERNALDATABASE */

/* EXTERNALDATABASEENTRY */
alter table SRestest.EXTERNALDATABASEENTRY add constraint EXTERNALDATABASEENTRY_FK05 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references SRestest.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table SRestest.EXTERNALDATABASEENTRY add constraint EXTERNALDATABASEENTRY_FK06 foreign key (REVIEW_STATUS_ID) references SRestest.REVIEWSTATUS (REVIEW_STATUS_ID);

/* EXTERNALDATABASEKEYWORD */
alter table SRestest.EXTERNALDATABASEKEYWORD add constraint EXTERNALDATABASEKEYWORD_FK01 foreign key (KEYWORD_ID) references DoTStest.KEYWORD (KEYWORD_ID);
alter table SRestest.EXTERNALDATABASEKEYWORD add constraint EXTERNALDATABASEKEYWORD_FK05 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references SRestest.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* EXTERNALDATABASELINK */
alter table SRestest.EXTERNALDATABASELINK add constraint EXTERNALDATABASELINK_FK05 foreign key (LINK_TABLE_ID) references Coretest.TABLEINFO (TABLE_ID);
alter table SRestest.EXTERNALDATABASELINK add constraint EXTERNALDATABASELINK_FK06 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references SRestest.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* EXTERNALDATABASERELEASE */
alter table SRestest.EXTERNALDATABASERELEASE add constraint EXTERNALDATABASERELEASE_FK01 foreign key (EXTERNAL_DATABASE_ID) references SRestest.EXTERNALDATABASE (EXTERNAL_DATABASE_ID);

/* GENETICCODE */

/* GOEVIDENCECODE */

/* GORELATIONSHIP */
alter table SRestest.GORELATIONSHIP add constraint GORELATIONSHIP_FK01 foreign key (PARENT_TERM_ID) references SRestest.GOTERM (GO_TERM_ID);
alter table SRestest.GORELATIONSHIP add constraint GORELATIONSHIP_FK02 foreign key (CHILD_TERM_ID) references SRestest.GOTERM (GO_TERM_ID);
alter table SRestest.GORELATIONSHIP add constraint GORELATIONSHIP_FK03 foreign key (GO_RELATIONSHIP_TYPE_ID) references SRestest.GORELATIONSHIPTYPE (GO_RELATIONSHIP_TYPE_ID);

/* GORELATIONSHIPTYPE */

/* GOSYNONYM */
alter table SRestest.GOSYNONYM add constraint GOSYNONYM_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references SRestest.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table SRestest.GOSYNONYM add constraint GOSYNONYM_FK02 foreign key (GO_TERM_ID) references SRestest.GOTERM (GO_TERM_ID);

/* GOTERM */
alter table SRestest.GOTERM add constraint GOTERM_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references SRestest.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table SRestest.GOTERM add constraint GOTERM_FK02 foreign key (ANCESTOR_GO_TERM_ID) references SRestest.GOTERM (GO_TERM_ID);

/* LINEAGE */

/* MGEDONTOLOGYRELATIONSHIP */
alter table SRestest.MGEDONTOLOGYRELATIONSHIP add constraint FK_MGEDOEREL_MGEDONTOTERM_C foreign key (CHILD_TERM_ID) references SRestest.MGEDONTOLOGYTERM (MGED_ONTOLOGY_TERM_ID);
alter table SRestest.MGEDONTOLOGYRELATIONSHIP add constraint FK_MGEDOEREL_MGEDONTOTERM_P foreign key (PARENT_TERM_ID) references SRestest.MGEDONTOLOGYTERM (MGED_ONTOLOGY_TERM_ID);
alter table SRestest.MGEDONTOLOGYRELATIONSHIP add constraint FK_MGEDOEREL_ONTORELTYPE foreign key (ONTOLOGY_RELATIONSHIP_TYPE_ID) references SRestest.ONTOLOGYRELATIONSHIPTYPE (ONTOLOGY_RELATIONSHIP_TYPE_ID);

/* MGEDONTOLOGYTERM */
alter table SRestest.MGEDONTOLOGYTERM add constraint FK_MGEDOETERM_EXTDBREL foreign key (EXTERNAL_DATABASE_RELEASE_ID) references SRestest.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* MUTAGEN */

/* ONTOLOGYRELATIONSHIPTYPE */

/* PATOATTRIBUTE */

/* PHENOTYPE */
alter table SRestest.PHENOTYPE add constraint FK_PHENOTYPE_ANAT01 foreign key (ANATOMY_ID) references SRestest.ANATOMY (ANATOMY_ID);
alter table SRestest.PHENOTYPE add constraint FK_PHENOTYPE_ANAT02 foreign key (CELL_TYPE_ID) references SRestest.ANATOMY (ANATOMY_ID);
alter table SRestest.PHENOTYPE add constraint FK_PHENOTYPE_DEVSTAGE01 foreign key (DEVELOPMENTAL_STAGE_ID) references SRestest.DEVELOPMENTALSTAGE (DEVELOPMENTAL_STAGE_ID);
alter table SRestest.PHENOTYPE add constraint FK_PHENOTYPE_PARENT foreign key (PARENT_ID) references SRestest.PHENOTYPE (PHENOTYPE_ID);
alter table SRestest.PHENOTYPE add constraint FK_PHENOTYPE_PATO foreign key (PATO_ATTRIBUTE_ID) references SRestest.PATOATTRIBUTE (PATO_ATTRIBUTE_ID);

/* PHENOTYPECLASS */

/* REFERENCE */
alter table SRestest.REFERENCE add constraint REFERENCE_FK04 foreign key (DB_REF_ID) references SRestest.DBREF (DB_REF_ID);

/* REVIEWSTATUS */

/* SEQUENCEONTOLOGY */

/* SEQUENCEREFERENCE */
alter table SRestest.SEQUENCEREFERENCE add constraint FK_SEQREF_BIBREF foreign key (BIBLIOGRAPHIC_REFERENCE_ID) references SRestest.BIBLIOGRAPHICREFERENCE (BIBLIOGRAPHIC_REFERENCE_ID);

/* TAXON */
alter table SRestest.TAXON add constraint TAXON_FK01 foreign key (GENETIC_CODE_ID) references SRestest.GENETICCODE (GENETIC_CODE_ID);
alter table SRestest.TAXON add constraint TAXON_FK02 foreign key (MITOCHONDRIAL_GENETIC_CODE_ID) references SRestest.GENETICCODE (GENETIC_CODE_ID);
alter table SRestest.TAXON add constraint TAXON_FK03 foreign key (PARENT_ID) references SRestest.TAXON (TAXON_ID);

/* TAXONNAME */
alter table SRestest.TAXONNAME add constraint TAXONNAME_FK01 foreign key (TAXON_ID) references SRestest.TAXON (TAXON_ID);



/* 48 non-primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

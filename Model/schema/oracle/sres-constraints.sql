
/*                                                                                            */
/* sres-constraints.sql                                                                       */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 20:43:22 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL sres-constraints.log

/* NON-PRIMARY KEY CONSTRAINTS */

/* ABSTRACT */
alter table @oracle_sres@.ABSTRACT add constraint FK_ABSTRACT_BIBREF foreign key (BIBLIOGRAPHIC_REFERENCE_ID) references @oracle_sres@.BIBLIOGRAPHICREFERENCE (BIBLIOGRAPHIC_REFERENCE_ID);

/* ANATOMY */
alter table @oracle_sres@.ANATOMY add constraint ANATOMY_FK02 foreign key (PARENT_ID) references @oracle_sres@.ANATOMY (ANATOMY_ID);

/* ANATOMYLINEAGE */
alter table @oracle_sres@.ANATOMYLINEAGE add constraint ANATOMYLINEAGE_FK04 foreign key (ANATOMY_ID) references @oracle_sres@.ANATOMY (ANATOMY_ID);
alter table @oracle_sres@.ANATOMYLINEAGE add constraint ANATOMYLINEAGE_FK05 foreign key (LINEAGE_ID) references @oracle_sres@.LINEAGE (LINEAGE_ID);

/* AUTHOR */

/* BIBLIOGRAPHICREFERENCE */
alter table @oracle_sres@.BIBLIOGRAPHICREFERENCE add constraint BIBLIOGRAPHICREFERENCE_FK01 foreign key (BIB_REF_TYPE_ID) references @oracle_sres@.BIBREFTYPE (BIB_REF_TYPE_ID);
alter table @oracle_sres@.BIBLIOGRAPHICREFERENCE add constraint BIBLIOGRAPHICREFERENCE_FK02 foreign key (CONTACT_ID) references @oracle_sres@.CONTACT (CONTACT_ID);

/* BIBREFANNOTATION */
alter table @oracle_sres@.BIBREFANNOTATION add constraint FK_BIBREFANNOT_BIBREF foreign key (BIBLIOGRAPHIC_REFERENCE_ID) references @oracle_sres@.BIBLIOGRAPHICREFERENCE (BIBLIOGRAPHIC_REFERENCE_ID);

/* BIBREFAUTHOR */
alter table @oracle_sres@.BIBREFAUTHOR add constraint FK_BIBREFAUTHOR_AUTHOR foreign key (AUTHOR_ID) references @oracle_sres@.AUTHOR (AUTHOR_ID);
alter table @oracle_sres@.BIBREFAUTHOR add constraint FK_BIBREFAUTHOR_BIBREF foreign key (BIBLIOGRAPHIC_REFERENCE_ID) references @oracle_sres@.BIBLIOGRAPHICREFERENCE (BIBLIOGRAPHIC_REFERENCE_ID);

/* BIBREFTYPE */
alter table @oracle_sres@.BIBREFTYPE add constraint BIBREFTYPE_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* CONTACT */
alter table @oracle_sres@.CONTACT add constraint CONTACT_FK03 foreign key (AFFILIATION_ID) references @oracle_sres@.CONTACT (CONTACT_ID);
alter table @oracle_sres@.CONTACT add constraint CONTACT_FK04 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* DBREF */
alter table @oracle_sres@.DBREF add constraint DBREF_FK04 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* DEVELOPMENTALSTAGE */
alter table @oracle_sres@.DEVELOPMENTALSTAGE add constraint DEVELOPMENTALSTAGE_FK01 foreign key (PARENT_ID) references @oracle_sres@.DEVELOPMENTALSTAGE (DEVELOPMENTAL_STAGE_ID);
alter table @oracle_sres@.DEVELOPMENTALSTAGE add constraint DEVELOPMENTALSTAGE_FK02 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);

/* DISEASE */
alter table @oracle_sres@.DISEASE add constraint DISEASE_FK01 foreign key (PARENT_ID) references @oracle_sres@.DISEASE (DISEASE_ID);

/* ENZYMECLASS */
alter table @oracle_sres@.ENZYMECLASS add constraint ENZYMECLASS_FK01 foreign key (PARENT_ID) references @oracle_sres@.ENZYMECLASS (ENZYME_CLASS_ID);
alter table @oracle_sres@.ENZYMECLASS add constraint ENZYMECLASS_FK02 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* ENZYMECLASSATTRIBUTE */
alter table @oracle_sres@.ENZYMECLASSATTRIBUTE add constraint ENZYMECLASSATTRIBUTE_FK01 foreign key (ENZYME_CLASS_ID) references @oracle_sres@.ENZYMECLASS (ENZYME_CLASS_ID);

/* EXTERNALDATABASE */

/* EXTERNALDATABASEENTRY */
alter table @oracle_sres@.EXTERNALDATABASEENTRY add constraint EXTERNALDATABASEENTRY_FK05 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_sres@.EXTERNALDATABASEENTRY add constraint EXTERNALDATABASEENTRY_FK06 foreign key (REVIEW_STATUS_ID) references @oracle_sres@.REVIEWSTATUS (REVIEW_STATUS_ID);

/* EXTERNALDATABASEKEYWORD */
alter table @oracle_sres@.EXTERNALDATABASEKEYWORD add constraint EXTERNALDATABASEKEYWORD_FK01 foreign key (KEYWORD_ID) references @oracle_dots@.KEYWORD (KEYWORD_ID);
alter table @oracle_sres@.EXTERNALDATABASEKEYWORD add constraint EXTERNALDATABASEKEYWORD_FK05 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* EXTERNALDATABASELINK */
alter table @oracle_sres@.EXTERNALDATABASELINK add constraint EXTERNALDATABASELINK_FK05 foreign key (LINK_TABLE_ID) references @oracle_core@.TABLEINFO (TABLE_ID);
alter table @oracle_sres@.EXTERNALDATABASELINK add constraint EXTERNALDATABASELINK_FK06 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* EXTERNALDATABASERELEASE */
alter table @oracle_sres@.EXTERNALDATABASERELEASE add constraint EXTERNALDATABASERELEASE_FK01 foreign key (EXTERNAL_DATABASE_ID) references @oracle_sres@.EXTERNALDATABASE (EXTERNAL_DATABASE_ID);

/* GENETICCODE */

/* GOEVIDENCECODE */

/* GORELATIONSHIP */
alter table @oracle_sres@.GORELATIONSHIP add constraint GORELATIONSHIP_FK01 foreign key (PARENT_TERM_ID) references @oracle_sres@.GOTERM (GO_TERM_ID);
alter table @oracle_sres@.GORELATIONSHIP add constraint GORELATIONSHIP_FK02 foreign key (CHILD_TERM_ID) references @oracle_sres@.GOTERM (GO_TERM_ID);
alter table @oracle_sres@.GORELATIONSHIP add constraint GORELATIONSHIP_FK03 foreign key (GO_RELATIONSHIP_TYPE_ID) references @oracle_sres@.GORELATIONSHIPTYPE (GO_RELATIONSHIP_TYPE_ID);

/* GORELATIONSHIPTYPE */

/* GOSYNONYM */
alter table @oracle_sres@.GOSYNONYM add constraint GOSYNONYM_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_sres@.GOSYNONYM add constraint GOSYNONYM_FK02 foreign key (GO_TERM_ID) references @oracle_sres@.GOTERM (GO_TERM_ID);

/* GOTERM */
alter table @oracle_sres@.GOTERM add constraint GOTERM_FK01 foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);
alter table @oracle_sres@.GOTERM add constraint GOTERM_FK02 foreign key (ANCESTOR_GO_TERM_ID) references @oracle_sres@.GOTERM (GO_TERM_ID);

/* LINEAGE */

/* MGEDONTOLOGYRELATIONSHIP */
alter table @oracle_sres@.MGEDONTOLOGYRELATIONSHIP add constraint FK_MGEDOEREL_MGEDONTOTERM_C foreign key (CHILD_TERM_ID) references @oracle_sres@.MGEDONTOLOGYTERM (MGED_ONTOLOGY_TERM_ID);
alter table @oracle_sres@.MGEDONTOLOGYRELATIONSHIP add constraint FK_MGEDOEREL_MGEDONTOTERM_P foreign key (PARENT_TERM_ID) references @oracle_sres@.MGEDONTOLOGYTERM (MGED_ONTOLOGY_TERM_ID);
alter table @oracle_sres@.MGEDONTOLOGYRELATIONSHIP add constraint FK_MGEDOEREL_ONTORELTYPE foreign key (ONTOLOGY_RELATIONSHIP_TYPE_ID) references @oracle_sres@.ONTOLOGYRELATIONSHIPTYPE (ONTOLOGY_RELATIONSHIP_TYPE_ID);

/* MGEDONTOLOGYTERM */
alter table @oracle_sres@.MGEDONTOLOGYTERM add constraint FK_MGEDOETERM_EXTDBREL foreign key (EXTERNAL_DATABASE_RELEASE_ID) references @oracle_sres@.EXTERNALDATABASERELEASE (EXTERNAL_DATABASE_RELEASE_ID);

/* MUTAGEN */

/* ONTOLOGYRELATIONSHIPTYPE */

/* PATOATTRIBUTE */

/* PHENOTYPE */
alter table @oracle_sres@.PHENOTYPE add constraint FK_PHENOTYPE_ANAT01 foreign key (ANATOMY_ID) references @oracle_sres@.ANATOMY (ANATOMY_ID);
alter table @oracle_sres@.PHENOTYPE add constraint FK_PHENOTYPE_ANAT02 foreign key (CELL_TYPE_ID) references @oracle_sres@.ANATOMY (ANATOMY_ID);
alter table @oracle_sres@.PHENOTYPE add constraint FK_PHENOTYPE_DEVSTAGE01 foreign key (DEVELOPMENTAL_STAGE_ID) references @oracle_sres@.DEVELOPMENTALSTAGE (DEVELOPMENTAL_STAGE_ID);
alter table @oracle_sres@.PHENOTYPE add constraint FK_PHENOTYPE_PARENT foreign key (PARENT_ID) references @oracle_sres@.PHENOTYPE (PHENOTYPE_ID);
alter table @oracle_sres@.PHENOTYPE add constraint FK_PHENOTYPE_PATO foreign key (PATO_ATTRIBUTE_ID) references @oracle_sres@.PATOATTRIBUTE (PATO_ATTRIBUTE_ID);

/* PHENOTYPECLASS */

/* REFERENCE */
alter table @oracle_sres@.REFERENCE add constraint REFERENCE_FK04 foreign key (DB_REF_ID) references @oracle_sres@.DBREF (DB_REF_ID);

/* REVIEWSTATUS */

/* SEQUENCEONTOLOGY */

/* SEQUENCEREFERENCE */
alter table @oracle_sres@.SEQUENCEREFERENCE add constraint FK_SEQREF_BIBREF foreign key (BIBLIOGRAPHIC_REFERENCE_ID) references @oracle_sres@.BIBLIOGRAPHICREFERENCE (BIBLIOGRAPHIC_REFERENCE_ID);

/* TAXON */
alter table @oracle_sres@.TAXON add constraint TAXON_FK01 foreign key (GENETIC_CODE_ID) references @oracle_sres@.GENETICCODE (GENETIC_CODE_ID);
alter table @oracle_sres@.TAXON add constraint TAXON_FK02 foreign key (MITOCHONDRIAL_GENETIC_CODE_ID) references @oracle_sres@.GENETICCODE (GENETIC_CODE_ID);
alter table @oracle_sres@.TAXON add constraint TAXON_FK03 foreign key (PARENT_ID) references @oracle_sres@.TAXON (TAXON_ID);

/* TAXONNAME */
alter table @oracle_sres@.TAXONNAME add constraint TAXONNAME_FK01 foreign key (TAXON_ID) references @oracle_sres@.TAXON (TAXON_ID);



/* 48 non-primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

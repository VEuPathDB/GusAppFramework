
/*                                                                                            */
/* sresver-pkey-constraints.sql                                                               */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 12:23:37 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL sresver-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table SRestestVer.ABSTRACTVER add constraint PK_ABSTRACTVER primary key (ABSTRACT_ID,MODIFICATION_DATE);
alter table SRestestVer.ANATOMYLINEAGEVER add constraint PK_ANATOMYLINEAGEVER primary key (ANATOMY_LINEAGE_ID,MODIFICATION_DATE);
alter table SRestestVer.ANATOMYVER add constraint PK_ANATOMYVER primary key (ANATOMY_ID,MODIFICATION_DATE);
alter table SRestestVer.AUTHORVER add constraint PK_AUTHORVER primary key (AUTHOR_ID,MODIFICATION_DATE);
alter table SRestestVer.BIBLIOGRAPHICREFERENCEVER add constraint PK_BIBLIOGRAPHICREFERENCEVER primary key (BIBLIOGRAPHIC_REFERENCE_ID,MODIFICATION_DATE);
alter table SRestestVer.BIBREFANNOTATIONVER add constraint PK_BIBREFANNOTATIONVER primary key (BIB_REF_ANNOTATION_ID,MODIFICATION_DATE);
alter table SRestestVer.BIBREFAUTHORVER add constraint PK_BIBREFAUTHORVER primary key (BIB_REF_AUTHOR_ID,MODIFICATION_DATE);
alter table SRestestVer.BIBREFTYPEVER add constraint PK_BIBREFTYPEVER primary key (BIB_REF_TYPE_ID,MODIFICATION_DATE);
alter table SRestestVer.CONTACTVER add constraint PK_CONTACTVER primary key (CONTACT_ID,MODIFICATION_DATE);
alter table SRestestVer.DBREFVER add constraint PK_DBREFVER primary key (DB_REF_ID,MODIFICATION_DATE);
alter table SRestestVer.DEVELOPMENTALSTAGEVER add constraint PK_DEVELOPMENTALSTAGEVER primary key (DEVELOPMENTAL_STAGE_ID,MODIFICATION_DATE);
alter table SRestestVer.DISEASEVER add constraint PK_DISEASEVER primary key (DISEASE_ID,MODIFICATION_DATE);
alter table SRestestVer.ENZYMECLASSATTRIBUTEVER add constraint PK_ENZYMECLASSATTRIBUTEVER primary key (ENZYME_CLASS_ATTRIBUTE_ID,MODIFICATION_DATE);
alter table SRestestVer.ENZYMECLASSVER add constraint PK_ENZYMECLASSVER primary key (ENZYME_CLASS_ID,MODIFICATION_DATE);
alter table SRestestVer.EXTERNALDATABASEENTRYVER add constraint PK_EXTERNALDATABASEENTRYVER primary key (EXTERNAL_DATABASE_ENTRY_ID,MODIFICATION_DATE);
alter table SRestestVer.EXTERNALDATABASEKEYWORDVER add constraint PK_EXTERNALDATABASEKEYWORDVER primary key (EXTERNAL_DATABASE_KEYWORD_ID,MODIFICATION_DATE);
alter table SRestestVer.EXTERNALDATABASERELEASEVER add constraint PK_EXTERNALDATABASERELEASEVER primary key (EXTERNAL_DATABASE_RELEASE_ID,MODIFICATION_DATE);
alter table SRestestVer.EXTERNALDATABASEVER add constraint PK_EXTERNALDATABASEVER primary key (EXTERNAL_DATABASE_ID,MODIFICATION_DATE);
alter table SRestestVer.GENETICCODEVER add constraint PK_GENETICCODEVER primary key (GENETIC_CODE_ID,MODIFICATION_DATE);
alter table SRestestVer.GOSYNONYMVER add constraint PK_GOSYNONYMVER primary key (GO_SYNONYM_ID,MODIFICATION_DATE);
alter table SRestestVer.LINEAGEVER add constraint PK_LINEAGEVER primary key (LINEAGE_ID,MODIFICATION_DATE);
alter table SRestestVer.MGEDONTOLOGYRELATIONSHIPVER add constraint PK_MGEDONTOLOGYRELATIONSHIPVER primary key (MGED_ONTOLOGY_RELATIONSHIP_ID,MODIFICATION_DATE);
alter table SRestestVer.MGEDONTOLOGYTERMVER add constraint PK_MGEDONTOLOGYTERMVER primary key (MGED_ONTOLOGY_TERM_ID,MODIFICATION_DATE);
alter table SRestestVer.MUTAGENVER add constraint PK_MUTAGENVER primary key (MUTAGEN_ID,MODIFICATION_DATE);
alter table SRestestVer.ONTOLOGYRELATIONSHIPTYPEVER add constraint PK_ONTOLOGYRELATIONSHIPTYPEVER primary key (ONTOLOGY_RELATIONSHIP_TYPE_ID,MODIFICATION_DATE);
alter table SRestestVer.PATOATTRIBUTEVER add constraint PK_PATOATTRIBUTEVER primary key (PATO_ATTRIBUTE_ID,MODIFICATION_DATE);
alter table SRestestVer.PHENOTYPECLASSVER add constraint PK_PHENOTYPECLASSVER primary key (PHENOTYPE_CLASS_ID,MODIFICATION_DATE);
alter table SRestestVer.PHENOTYPEVER add constraint PK_PHENOTYPEVER primary key (PHENOTYPE_ID,MODIFICATION_DATE);
alter table SRestestVer.REFERENCEVER add constraint PK_REFERENCEVER primary key (REFERENCE_ID,MODIFICATION_DATE);
alter table SRestestVer.REVIEWSTATUSVER add constraint PK_REVIEWSTATUSVER primary key (REVIEW_STATUS_ID,MODIFICATION_DATE);
alter table SRestestVer.SEQUENCEONTOLOGYVER add constraint PK_SEQUENCEONTOLOGYVER primary key (SEQUENCE_ONTOLOGY_ID,MODIFICATION_DATE);
alter table SRestestVer.SEQUENCEREFERENCEVER add constraint PK_SEQUENCEREFERENCEVER primary key (SEQUENCE_REFERENCE_ID,MODIFICATION_DATE);
alter table SRestestVer.TAXONNAMEVER add constraint PK_TAXONNAMEVER primary key (TAXON_NAME_ID,MODIFICATION_DATE);
alter table SRestestVer.TAXONVER add constraint PK_TAXONVER primary key (TAXON_ID,MODIFICATION_DATE);


/* 34 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

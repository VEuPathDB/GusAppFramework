
/*                                                                                            */
/* sresver-pkey-constraints.sql                                                               */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 03:54:40 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL sresver-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table @oracle_sresver@.ABSTRACTVER add constraint PK_ABSTRACTVER primary key (ABSTRACT_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.ANATOMYLINEAGEVER add constraint PK_ANATOMYLINEAGEVER primary key (ANATOMY_LINEAGE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.ANATOMYVER add constraint PK_ANATOMYVER primary key (ANATOMY_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.AUTHORVER add constraint PK_AUTHORVER primary key (AUTHOR_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.BIBLIOGRAPHICREFERENCEVER add constraint PK_BIBLIOGRAPHICREFERENCEVER primary key (BIBLIOGRAPHIC_REFERENCE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.BIBREFANNOTATIONVER add constraint PK_BIBREFANNOTATIONVER primary key (BIB_REF_ANNOTATION_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.BIBREFAUTHORVER add constraint PK_BIBREFAUTHORVER primary key (BIB_REF_AUTHOR_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.BIBREFTYPEVER add constraint PK_BIBREFTYPEVER primary key (BIB_REF_TYPE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.CONTACTVER add constraint PK_CONTACTVER primary key (CONTACT_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.DBREFVER add constraint PK_DBREFVER primary key (DB_REF_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.DEVELOPMENTALSTAGEVER add constraint PK_DEVELOPMENTALSTAGEVER primary key (DEVELOPMENTAL_STAGE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.DISEASEVER add constraint PK_DISEASEVER primary key (DISEASE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.ENZYMECLASSATTRIBUTEVER add constraint PK_ENZYMECLASSATTRIBUTEVER primary key (ENZYME_CLASS_ATTRIBUTE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.ENZYMECLASSVER add constraint PK_ENZYMECLASSVER primary key (ENZYME_CLASS_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.EXTERNALDATABASEENTRYVER add constraint PK_EXTERNALDATABASEENTRYVER primary key (EXTERNAL_DATABASE_ENTRY_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.EXTERNALDATABASEKEYWORDVER add constraint PK_EXTERNALDATABASEKEYWORDVER primary key (EXTERNAL_DATABASE_KEYWORD_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.EXTERNALDATABASERELEASEVER add constraint PK_EXTERNALDATABASERELEASEVER primary key (EXTERNAL_DATABASE_RELEASE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.EXTERNALDATABASEVER add constraint PK_EXTERNALDATABASEVER primary key (EXTERNAL_DATABASE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.GENETICCODEVER add constraint PK_GENETICCODEVER primary key (GENETIC_CODE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.GOSYNONYMVER add constraint PK_GOSYNONYMVER primary key (GO_SYNONYM_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.LINEAGEVER add constraint PK_LINEAGEVER primary key (LINEAGE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.MGEDONTOLOGYRELATIONSHIPVER add constraint PK_MGEDONTOLOGYRELATIONSHIPVER primary key (MGED_ONTOLOGY_RELATIONSHIP_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.MGEDONTOLOGYTERMVER add constraint PK_MGEDONTOLOGYTERMVER primary key (MGED_ONTOLOGY_TERM_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.MUTAGENVER add constraint PK_MUTAGENVER primary key (MUTAGEN_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.ONTOLOGYRELATIONSHIPTYPEVER add constraint PK_ONTOLOGYRELATIONSHIPTYPEVER primary key (ONTOLOGY_RELATIONSHIP_TYPE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.PATOATTRIBUTEVER add constraint PK_PATOATTRIBUTEVER primary key (PATO_ATTRIBUTE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.PHENOTYPECLASSVER add constraint PK_PHENOTYPECLASSVER primary key (PHENOTYPE_CLASS_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.PHENOTYPEVER add constraint PK_PHENOTYPEVER primary key (PHENOTYPE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.REFERENCEVER add constraint PK_REFERENCEVER primary key (REFERENCE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.REVIEWSTATUSVER add constraint PK_REVIEWSTATUSVER primary key (REVIEW_STATUS_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.SEQUENCEONTOLOGYVER add constraint PK_SEQUENCEONTOLOGYVER primary key (SEQUENCE_ONTOLOGY_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.SEQUENCEREFERENCEVER add constraint PK_SEQUENCEREFERENCEVER primary key (SEQUENCE_REFERENCE_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.TAXONNAMEVER add constraint PK_TAXONNAMEVER primary key (TAXON_NAME_ID,MODIFICATION_DATE);
alter table @oracle_sresver@.TAXONVER add constraint PK_TAXONVER primary key (TAXON_ID,MODIFICATION_DATE);


/* 34 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT


/*                                                                                            */
/* sres-sequences.sql                                                                         */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 20:43:01 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL sres-sequences.log

CREATE SEQUENCE @oracle_sres@.ABSTRACT_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.ANATOMYLINEAGE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.ANATOMY_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.AUTHOR_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.BIBLIOGRAPHICREFERENCE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.BIBREFANNOTATION_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.BIBREFAUTHOR_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.BIBREFTYPE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.CONTACT_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.DBREF_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.DEVELOPMENTALSTAGE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.DISEASE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.ENZYMECLASSATTRIBUTE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.ENZYMECLASS_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.EXTERNALDATABASEENTRY_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.EXTERNALDATABASEKEYWORD_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.EXTERNALDATABASELINK_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.EXTERNALDATABASERELEASE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.EXTERNALDATABASE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.GENETICCODE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.GOEVIDENCECODE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.GORELATIONSHIPTYPE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.GORELATIONSHIP_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.GOSYNONYM_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.GOTERM_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.LINEAGE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.MGEDONTOLOGYRELATIONSHIP_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.MGEDONTOLOGYTERM_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.MUTAGEN_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.ONTOLOGYRELATIONSHIPTYPE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.PATOATTRIBUTE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.PHENOTYPECLASS_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.PHENOTYPE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.REFERENCE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.REVIEWSTATUS_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.SEQUENCEONTOLOGY_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.SEQUENCEREFERENCE_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.TAXONNAME_SQ START WITH 1;
CREATE SEQUENCE @oracle_sres@.TAXON_SQ START WITH 1;

/* 39 sequences(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT


/*                                                                                            */
/* core-DatabaseInfo-rows.sql                                                                 */
/*                                                                                            */
/* Populate Core.DatabaseInfo, which lists each of the GUS namespaces (i.e. schemas/users).   */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 23:57:12 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL core-DatabaseInfo-rows.log

SET ESCAPE '\';
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
INSERT INTO @oracle_core@.DatabaseInfo VALUES(1,'3','@oracle_core@','Core administrative files used by all GUS3.0 schemas','2002-04-16 12:49:03',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.DatabaseInfo VALUES(2,'3','@oracle_corever@','Version tables for Core','2002-04-16 12:49:03',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.DatabaseInfo VALUES(3,'3','@oracle_sres@','Shared resources used by all GUS3.0 schemas','2002-04-16 12:49:03',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.DatabaseInfo VALUES(4,'3','@oracle_sresver@','Version tables for SRes','2002-04-16 12:49:03',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.DatabaseInfo VALUES(5,'3','@oracle_dots@','Tables for storing Sequence and Sequence Annotation including GenBank, SwissProt','2002-04-16 12:49:03',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.DatabaseInfo VALUES(6,'3','@oracle_dotsver@','Version tables for DoTS','2002-04-16 12:49:03',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.DatabaseInfo VALUES(8,'1.0','@oracle_tessver@','Version tables for Tess.','2002-04-23 10:16:48',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.DatabaseInfo VALUES(9,'1.0','@oracle_tess@','Data relating to transcriptional regulation.','2002-04-23 10:16:48',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.DatabaseInfo VALUES(10,'3','@oracle_rad3@','RNA Abundance Database. Stores high-throughput gene expression experimental data and annotations.','2002-05-16 15:14:06',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.DatabaseInfo VALUES(11,'3','@oracle_rad3ver@','Version tables for RAD3','2003-02-12 20:50:31',1,1,1,1,1,0,1, 1, 1, 1);

/* 10 row(s) */


DROP SEQUENCE @oracle_core@.DatabaseInfo_SQ;
CREATE SEQUENCE @oracle_core@.DatabaseInfo_SQ START WITH 12;

COMMIT;
SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

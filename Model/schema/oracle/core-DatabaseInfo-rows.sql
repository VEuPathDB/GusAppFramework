
/*                                                                                            */
/* core-DatabaseInfo-rows.sql                                                                 */
/*                                                                                            */
/* Populate Core.DatabaseInfo, which lists each of the GUS namespaces (i.e. schemas/users).   */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 12:22:24 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL core-DatabaseInfo-rows.log

SET ESCAPE '\';
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
INSERT INTO Coretest.DatabaseInfo VALUES(1,'3','Coretest','Core administrative files used by all GUS3.0 schemas','2002-04-16 12:49:03',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO Coretest.DatabaseInfo VALUES(2,'3','CoretestVer','Version tables for Core','2002-04-16 12:49:03',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO Coretest.DatabaseInfo VALUES(3,'3','SRestest','Shared resources used by all GUS3.0 schemas','2002-04-16 12:49:03',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO Coretest.DatabaseInfo VALUES(4,'3','SRestestVer','Version tables for SRes','2002-04-16 12:49:03',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO Coretest.DatabaseInfo VALUES(5,'3','DoTStest','Tables for storing Sequence and Sequence Annotation including GenBank, SwissProt','2002-04-16 12:49:03',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO Coretest.DatabaseInfo VALUES(6,'3','DoTStestVer','Version tables for DoTS','2002-04-16 12:49:03',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO Coretest.DatabaseInfo VALUES(8,'1.0','TESStestVer','Version tables for Tess.','2002-04-23 10:16:48',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO Coretest.DatabaseInfo VALUES(9,'1.0','TESStest','Data relating to transcriptional regulation.','2002-04-23 10:16:48',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO Coretest.DatabaseInfo VALUES(10,'3','RAD3test','RNA Abundance Database. Stores high-throughput gene expression experimental data and annotations.','2002-05-16 15:14:06',1,1,1,1,1,0,1, 1, 1, 1);

/* 9 row(s) */


DROP SEQUENCE Coretest.DatabaseInfo_SQ;
CREATE SEQUENCE Coretest.DatabaseInfo_SQ START WITH 11;

COMMIT;
SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT


/*                                                                                            */
/* core-AlgorithmParamKeyType-rows.sql                                                        */
/*                                                                                            */
/* Populate Core.AlgorithmParamKeyType, which is a controlled vocabulary of plugin parameter types (e.g., int, float, etc.) */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Feb 25 10:26:34 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL core-AlgorithmParamKeyType-rows.log

SET ESCAPE '\';
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
INSERT INTO @oracle_core@.AlgorithmParamKeyType VALUES(0,'string','2000-02-08 20:43:00',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.AlgorithmParamKeyType VALUES(1,'float','2000-02-08 20:43:00',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.AlgorithmParamKeyType VALUES(2,'int','2000-02-08 20:43:00',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.AlgorithmParamKeyType VALUES(3,'ref','2000-02-08 20:43:00',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.AlgorithmParamKeyType VALUES(4,'boolean','2000-02-08 20:43:00',1,1,1,1,1,0,1, 1, 1, 1);
INSERT INTO @oracle_core@.AlgorithmParamKeyType VALUES(5,'date','2001-03-07 12:00:58',1,1,1,1,1,0,1, 1, 1, 1);

/* 6 row(s) */


DROP SEQUENCE @oracle_core@.AlgorithmParamKeyType_SQ;
CREATE SEQUENCE @oracle_core@.AlgorithmParamKeyType_SQ START WITH 6;

COMMIT;
SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

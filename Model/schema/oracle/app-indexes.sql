
/*                                                                                            */
/* app-indexes.sql                                                                            */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Feb 17 12:46:26 EST 2004     */
/*                                                                                            */

SET ECHO ON
SPOOL app-indexes.log

/* APPLICATION */


/* FORMHELP */
create index @oracle_app@.FORMHELP_IND01 on @oracle_app@.FORMHELP (APPLICATION_ID)  TABLESPACE @oracle_appIndexTablespace@;



/* 1 index(es) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

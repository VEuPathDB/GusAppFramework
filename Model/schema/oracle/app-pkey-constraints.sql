
/*                                                                                            */
/* app-pkey-constraints.sql                                                                   */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Feb 17 12:46:26 EST 2004     */
/*                                                                                            */

SET ECHO ON
SPOOL app-pkey-constraints.log

/* PRIMARY KEY CONSTRAINTS */

alter table @oracle_app@.APPLICATION add constraint PK_APPLICATION primary key (APPLICATION_ID);
alter table @oracle_app@.FORMHELP add constraint PK_FORMHELP primary key (FORM_HELP_ID);


/* 2 primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

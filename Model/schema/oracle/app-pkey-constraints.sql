
/*                                                                                            */
/* app-pkey-constraints.sql                                                                   */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Dec  9 16:14:20 EST 2003     */
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


/*                                                                                            */
/* app-constraints.sql                                                                        */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Tue Dec  9 16:14:20 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL app-constraints.log

/* NON-PRIMARY KEY CONSTRAINTS */

/* APPLICATION */

/* FORMHELP */
alter table @oracle_app@.FORMHELP add constraint FORMHELP_FK01 foreign key (APPLICATION_ID) references @oracle_app@.APPLICATION (APPLICATION_ID);



/* 1 non-primary key constraint(s) */

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

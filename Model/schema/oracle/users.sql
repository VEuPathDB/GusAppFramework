
/*                                                                                            */
/* users.sql                                                                                  */
/*                                                                                            */
/* CREATE USER statments for the Oracle users/schemas that will hold the tables in GUS.       */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 23:57:12 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL users.log

/* ----------------------------------------------------------------------- */
/* New schema = @oracle_core@ (original name = core) */
/* ----------------------------------------------------------------------- */
DROP USER @oracle_core@ CASCADE;

CREATE USER @oracle_core@ IDENTIFIED BY @oracle_corePassword@ 
  TEMPORARY TABLESPACE @oracle_tempTablespace@
  DEFAULT TABLESPACE @oracle_coreTablespace@
  QUOTA @oracle_tempQuota@ ON @oracle_tempTablespace@
  QUOTA @oracle_defaultQuota@ ON @oracle_coreTablespace@;

GRANT CONNECT TO @oracle_core@;
GRANT RESOURCE TO @oracle_core@;
GRANT CREATE SESSION TO @oracle_core@;
GRANT CREATE TABLE TO @oracle_core@;
GRANT CREATE VIEW TO @oracle_core@;
GRANT CREATE SEQUENCE TO @oracle_core@;

/* ----------------------------------------------------------------------- */
/* New schema = @oracle_corever@ (original name = corever) */
/* ----------------------------------------------------------------------- */
DROP USER @oracle_corever@ CASCADE;

CREATE USER @oracle_corever@ IDENTIFIED BY @oracle_coreverPassword@ 
  TEMPORARY TABLESPACE @oracle_tempTablespace@
  DEFAULT TABLESPACE @oracle_coreverTablespace@
  QUOTA @oracle_tempQuota@ ON @oracle_tempTablespace@
  QUOTA @oracle_defaultQuota@ ON @oracle_coreverTablespace@;

GRANT CONNECT TO @oracle_corever@;
GRANT RESOURCE TO @oracle_corever@;
GRANT CREATE SESSION TO @oracle_corever@;
GRANT CREATE TABLE TO @oracle_corever@;
GRANT CREATE VIEW TO @oracle_corever@;
GRANT CREATE SEQUENCE TO @oracle_corever@;

/* ----------------------------------------------------------------------- */
/* New schema = @oracle_sres@ (original name = sres) */
/* ----------------------------------------------------------------------- */
DROP USER @oracle_sres@ CASCADE;

CREATE USER @oracle_sres@ IDENTIFIED BY @oracle_sresPassword@ 
  TEMPORARY TABLESPACE @oracle_tempTablespace@
  DEFAULT TABLESPACE @oracle_sresTablespace@
  QUOTA @oracle_tempQuota@ ON @oracle_tempTablespace@
  QUOTA @oracle_defaultQuota@ ON @oracle_sresTablespace@;

GRANT CONNECT TO @oracle_sres@;
GRANT RESOURCE TO @oracle_sres@;
GRANT CREATE SESSION TO @oracle_sres@;
GRANT CREATE TABLE TO @oracle_sres@;
GRANT CREATE VIEW TO @oracle_sres@;
GRANT CREATE SEQUENCE TO @oracle_sres@;

/* ----------------------------------------------------------------------- */
/* New schema = @oracle_sresver@ (original name = sresver) */
/* ----------------------------------------------------------------------- */
DROP USER @oracle_sresver@ CASCADE;

CREATE USER @oracle_sresver@ IDENTIFIED BY @oracle_sresverPassword@ 
  TEMPORARY TABLESPACE @oracle_tempTablespace@
  DEFAULT TABLESPACE @oracle_sresverTablespace@
  QUOTA @oracle_tempQuota@ ON @oracle_tempTablespace@
  QUOTA @oracle_defaultQuota@ ON @oracle_sresverTablespace@;

GRANT CONNECT TO @oracle_sresver@;
GRANT RESOURCE TO @oracle_sresver@;
GRANT CREATE SESSION TO @oracle_sresver@;
GRANT CREATE TABLE TO @oracle_sresver@;
GRANT CREATE VIEW TO @oracle_sresver@;
GRANT CREATE SEQUENCE TO @oracle_sresver@;

/* ----------------------------------------------------------------------- */
/* New schema = @oracle_dots@ (original name = dots) */
/* ----------------------------------------------------------------------- */
DROP USER @oracle_dots@ CASCADE;

CREATE USER @oracle_dots@ IDENTIFIED BY @oracle_dotsPassword@ 
  TEMPORARY TABLESPACE @oracle_tempTablespace@
  DEFAULT TABLESPACE @oracle_dotsTablespace@
  QUOTA @oracle_tempQuota@ ON @oracle_tempTablespace@
  QUOTA @oracle_defaultQuota@ ON @oracle_dotsTablespace@;

GRANT CONNECT TO @oracle_dots@;
GRANT RESOURCE TO @oracle_dots@;
GRANT CREATE SESSION TO @oracle_dots@;
GRANT CREATE TABLE TO @oracle_dots@;
GRANT CREATE VIEW TO @oracle_dots@;
GRANT CREATE SEQUENCE TO @oracle_dots@;

/* ----------------------------------------------------------------------- */
/* New schema = @oracle_dotsver@ (original name = dotsver) */
/* ----------------------------------------------------------------------- */
DROP USER @oracle_dotsver@ CASCADE;

CREATE USER @oracle_dotsver@ IDENTIFIED BY @oracle_dotsverPassword@ 
  TEMPORARY TABLESPACE @oracle_tempTablespace@
  DEFAULT TABLESPACE @oracle_dotsverTablespace@
  QUOTA @oracle_tempQuota@ ON @oracle_tempTablespace@
  QUOTA @oracle_defaultQuota@ ON @oracle_dotsverTablespace@;

GRANT CONNECT TO @oracle_dotsver@;
GRANT RESOURCE TO @oracle_dotsver@;
GRANT CREATE SESSION TO @oracle_dotsver@;
GRANT CREATE TABLE TO @oracle_dotsver@;
GRANT CREATE VIEW TO @oracle_dotsver@;
GRANT CREATE SEQUENCE TO @oracle_dotsver@;

/* ----------------------------------------------------------------------- */
/* New schema = @oracle_tess@ (original name = tess) */
/* ----------------------------------------------------------------------- */
DROP USER @oracle_tess@ CASCADE;

CREATE USER @oracle_tess@ IDENTIFIED BY @oracle_tessPassword@ 
  TEMPORARY TABLESPACE @oracle_tempTablespace@
  DEFAULT TABLESPACE @oracle_tessTablespace@
  QUOTA @oracle_tempQuota@ ON @oracle_tempTablespace@
  QUOTA @oracle_defaultQuota@ ON @oracle_tessTablespace@;

GRANT CONNECT TO @oracle_tess@;
GRANT RESOURCE TO @oracle_tess@;
GRANT CREATE SESSION TO @oracle_tess@;
GRANT CREATE TABLE TO @oracle_tess@;
GRANT CREATE VIEW TO @oracle_tess@;
GRANT CREATE SEQUENCE TO @oracle_tess@;

/* ----------------------------------------------------------------------- */
/* New schema = @oracle_tessver@ (original name = tessver) */
/* ----------------------------------------------------------------------- */
DROP USER @oracle_tessver@ CASCADE;

CREATE USER @oracle_tessver@ IDENTIFIED BY @oracle_tessverPassword@ 
  TEMPORARY TABLESPACE @oracle_tempTablespace@
  DEFAULT TABLESPACE @oracle_tessverTablespace@
  QUOTA @oracle_tempQuota@ ON @oracle_tempTablespace@
  QUOTA @oracle_defaultQuota@ ON @oracle_tessverTablespace@;

GRANT CONNECT TO @oracle_tessver@;
GRANT RESOURCE TO @oracle_tessver@;
GRANT CREATE SESSION TO @oracle_tessver@;
GRANT CREATE TABLE TO @oracle_tessver@;
GRANT CREATE VIEW TO @oracle_tessver@;
GRANT CREATE SEQUENCE TO @oracle_tessver@;

/* ----------------------------------------------------------------------- */
/* New schema = @oracle_rad3@ (original name = rad3) */
/* ----------------------------------------------------------------------- */
DROP USER @oracle_rad3@ CASCADE;

CREATE USER @oracle_rad3@ IDENTIFIED BY @oracle_rad3Password@ 
  TEMPORARY TABLESPACE @oracle_tempTablespace@
  DEFAULT TABLESPACE @oracle_rad3Tablespace@
  QUOTA @oracle_tempQuota@ ON @oracle_tempTablespace@
  QUOTA @oracle_defaultQuota@ ON @oracle_rad3Tablespace@;

GRANT CONNECT TO @oracle_rad3@;
GRANT RESOURCE TO @oracle_rad3@;
GRANT CREATE SESSION TO @oracle_rad3@;
GRANT CREATE TABLE TO @oracle_rad3@;
GRANT CREATE VIEW TO @oracle_rad3@;
GRANT CREATE SEQUENCE TO @oracle_rad3@;

/* ----------------------------------------------------------------------- */
/* New schema = @oracle_rad3ver@ (original name = rad3ver) */
/* ----------------------------------------------------------------------- */
DROP USER @oracle_rad3ver@ CASCADE;

CREATE USER @oracle_rad3ver@ IDENTIFIED BY @oracle_rad3verPassword@ 
  TEMPORARY TABLESPACE @oracle_tempTablespace@
  DEFAULT TABLESPACE @oracle_rad3verTablespace@
  QUOTA @oracle_tempQuota@ ON @oracle_tempTablespace@
  QUOTA @oracle_defaultQuota@ ON @oracle_rad3verTablespace@;

GRANT CONNECT TO @oracle_rad3ver@;
GRANT RESOURCE TO @oracle_rad3ver@;
GRANT CREATE SESSION TO @oracle_rad3ver@;
GRANT CREATE TABLE TO @oracle_rad3ver@;
GRANT CREATE VIEW TO @oracle_rad3ver@;
GRANT CREATE SEQUENCE TO @oracle_rad3ver@;

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

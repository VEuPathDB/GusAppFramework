
/*                                                                                            */
/* users.sql                                                                                  */
/*                                                                                            */
/* CREATE USER statments for the Oracle users/schemas that will hold the tables in GUS.       */
/*                                                                                            */
/* This file was generated automatically by dumpSchema.pl on Wed Feb 12 12:22:24 EST 2003     */
/*                                                                                            */

SET ECHO ON
SPOOL users.log

/* ----------------------------------------------------------------------- */
/* New schema = Coretest (original name = core) */
/* ----------------------------------------------------------------------- */
DROP USER Coretest CASCADE;

CREATE USER Coretest IDENTIFIED BY password1 
  TEMPORARY TABLESPACE TEMP
  DEFAULT TABLESPACE RAID1
  QUOTA UNLIMITED ON TEMP
  QUOTA UNLIMITED ON RAID1;

GRANT CONNECT TO Coretest;
GRANT RESOURCE TO Coretest;
GRANT CREATE SESSION TO Coretest;
GRANT CREATE TABLE TO Coretest;
GRANT CREATE VIEW TO Coretest;
GRANT CREATE SEQUENCE TO Coretest;

/* ----------------------------------------------------------------------- */
/* New schema = CoretestVer (original name = corever) */
/* ----------------------------------------------------------------------- */
DROP USER CoretestVer CASCADE;

CREATE USER CoretestVer IDENTIFIED BY password1 
  TEMPORARY TABLESPACE TEMP
  DEFAULT TABLESPACE RAID1
  QUOTA UNLIMITED ON TEMP
  QUOTA UNLIMITED ON RAID1;

GRANT CONNECT TO CoretestVer;
GRANT RESOURCE TO CoretestVer;
GRANT CREATE SESSION TO CoretestVer;
GRANT CREATE TABLE TO CoretestVer;
GRANT CREATE VIEW TO CoretestVer;
GRANT CREATE SEQUENCE TO CoretestVer;

/* ----------------------------------------------------------------------- */
/* New schema = SRestest (original name = sres) */
/* ----------------------------------------------------------------------- */
DROP USER SRestest CASCADE;

CREATE USER SRestest IDENTIFIED BY password2 
  TEMPORARY TABLESPACE TEMP
  DEFAULT TABLESPACE RAID1
  QUOTA UNLIMITED ON TEMP
  QUOTA UNLIMITED ON RAID1;

GRANT CONNECT TO SRestest;
GRANT RESOURCE TO SRestest;
GRANT CREATE SESSION TO SRestest;
GRANT CREATE TABLE TO SRestest;
GRANT CREATE VIEW TO SRestest;
GRANT CREATE SEQUENCE TO SRestest;

/* ----------------------------------------------------------------------- */
/* New schema = SRestestVer (original name = sresver) */
/* ----------------------------------------------------------------------- */
DROP USER SRestestVer CASCADE;

CREATE USER SRestestVer IDENTIFIED BY password2 
  TEMPORARY TABLESPACE TEMP
  DEFAULT TABLESPACE RAID1
  QUOTA UNLIMITED ON TEMP
  QUOTA UNLIMITED ON RAID1;

GRANT CONNECT TO SRestestVer;
GRANT RESOURCE TO SRestestVer;
GRANT CREATE SESSION TO SRestestVer;
GRANT CREATE TABLE TO SRestestVer;
GRANT CREATE VIEW TO SRestestVer;
GRANT CREATE SEQUENCE TO SRestestVer;

/* ----------------------------------------------------------------------- */
/* New schema = DoTStest (original name = dots) */
/* ----------------------------------------------------------------------- */
DROP USER DoTStest CASCADE;

CREATE USER DoTStest IDENTIFIED BY password3 
  TEMPORARY TABLESPACE TEMP
  DEFAULT TABLESPACE RAID1
  QUOTA UNLIMITED ON TEMP
  QUOTA UNLIMITED ON RAID1;

GRANT CONNECT TO DoTStest;
GRANT RESOURCE TO DoTStest;
GRANT CREATE SESSION TO DoTStest;
GRANT CREATE TABLE TO DoTStest;
GRANT CREATE VIEW TO DoTStest;
GRANT CREATE SEQUENCE TO DoTStest;

/* ----------------------------------------------------------------------- */
/* New schema = DoTStestVer (original name = dotsver) */
/* ----------------------------------------------------------------------- */
DROP USER DoTStestVer CASCADE;

CREATE USER DoTStestVer IDENTIFIED BY password3 
  TEMPORARY TABLESPACE TEMP
  DEFAULT TABLESPACE RAID1
  QUOTA UNLIMITED ON TEMP
  QUOTA UNLIMITED ON RAID1;

GRANT CONNECT TO DoTStestVer;
GRANT RESOURCE TO DoTStestVer;
GRANT CREATE SESSION TO DoTStestVer;
GRANT CREATE TABLE TO DoTStestVer;
GRANT CREATE VIEW TO DoTStestVer;
GRANT CREATE SEQUENCE TO DoTStestVer;

/* ----------------------------------------------------------------------- */
/* New schema = TESStest (original name = tess) */
/* ----------------------------------------------------------------------- */
DROP USER TESStest CASCADE;

CREATE USER TESStest IDENTIFIED BY password4 
  TEMPORARY TABLESPACE TEMP
  DEFAULT TABLESPACE RAID1
  QUOTA UNLIMITED ON TEMP
  QUOTA UNLIMITED ON RAID1;

GRANT CONNECT TO TESStest;
GRANT RESOURCE TO TESStest;
GRANT CREATE SESSION TO TESStest;
GRANT CREATE TABLE TO TESStest;
GRANT CREATE VIEW TO TESStest;
GRANT CREATE SEQUENCE TO TESStest;

/* ----------------------------------------------------------------------- */
/* New schema = TESStestVer (original name = tessver) */
/* ----------------------------------------------------------------------- */
DROP USER TESStestVer CASCADE;

CREATE USER TESStestVer IDENTIFIED BY password4 
  TEMPORARY TABLESPACE TEMP
  DEFAULT TABLESPACE RAID1
  QUOTA UNLIMITED ON TEMP
  QUOTA UNLIMITED ON RAID1;

GRANT CONNECT TO TESStestVer;
GRANT RESOURCE TO TESStestVer;
GRANT CREATE SESSION TO TESStestVer;
GRANT CREATE TABLE TO TESStestVer;
GRANT CREATE VIEW TO TESStestVer;
GRANT CREATE SEQUENCE TO TESStestVer;

/* ----------------------------------------------------------------------- */
/* New schema = RAD3test (original name = rad3) */
/* ----------------------------------------------------------------------- */
DROP USER RAD3test CASCADE;

CREATE USER RAD3test IDENTIFIED BY password5 
  TEMPORARY TABLESPACE TEMP
  DEFAULT TABLESPACE RAID1
  QUOTA UNLIMITED ON TEMP
  QUOTA UNLIMITED ON RAID1;

GRANT CONNECT TO RAD3test;
GRANT RESOURCE TO RAD3test;
GRANT CREATE SESSION TO RAD3test;
GRANT CREATE TABLE TO RAD3test;
GRANT CREATE VIEW TO RAD3test;
GRANT CREATE SEQUENCE TO RAD3test;

SPOOL OFF
SET ECHO OFF
DISCONNECT
EXIT

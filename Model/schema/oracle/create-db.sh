#!/bin/sh

# Running this file will create a new GUS instance 

# create new users (as sys/sysdba) 
sqlplus 'sys/@oracle_systemPassword@@@oracle_SID@ as sysdba' @users.sql

# create all sequences
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-sequences.sql
sqlplus @oracle_sres@/@oracle_sresPassword@@@oracle_SID@ @sres-sequences.sql
sqlplus @oracle_dots@/@oracle_dotsPassword@@@oracle_SID@ @dots-sequences.sql
sqlplus @oracle_tess@/@oracle_tessPassword@@@oracle_SID@ @tess-sequences.sql
sqlplus @oracle_rad3@/@oracle_rad3Password@@@oracle_SID@ @rad3-sequences.sql

# create all tables
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-tables.sql
sqlplus @oracle_corever@/@oracle_coreverPassword@@@oracle_SID@ @corever-tables.sql
sqlplus @oracle_sres@/@oracle_sresPassword@@@oracle_SID@ @sres-tables.sql
sqlplus @oracle_sresver@/@oracle_sresverPassword@@@oracle_SID@ @sresver-tables.sql
sqlplus @oracle_dots@/@oracle_dotsPassword@@@oracle_SID@ @dots-tables.sql
sqlplus @oracle_dotsver@/@oracle_dotsverPassword@@@oracle_SID@ @dotsver-tables.sql
sqlplus @oracle_tess@/@oracle_tessPassword@@@oracle_SID@ @tess-tables.sql
sqlplus @oracle_tessver@/@oracle_tessverPassword@@@oracle_SID@ @tessver-tables.sql
sqlplus @oracle_rad3@/@oracle_rad3Password@@@oracle_SID@ @rad3-tables.sql

# create all views
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-views.sql
sqlplus @oracle_corever@/@oracle_coreverPassword@@@oracle_SID@ @corever-views.sql
sqlplus @oracle_sres@/@oracle_sresPassword@@@oracle_SID@ @sres-views.sql
sqlplus @oracle_sresver@/@oracle_sresverPassword@@@oracle_SID@ @sresver-views.sql
sqlplus @oracle_dots@/@oracle_dotsPassword@@@oracle_SID@ @dots-views.sql
sqlplus @oracle_dotsver@/@oracle_dotsverPassword@@@oracle_SID@ @dotsver-views.sql
sqlplus @oracle_tess@/@oracle_tessPassword@@@oracle_SID@ @tess-views.sql
sqlplus @oracle_tessver@/@oracle_tessverPassword@@@oracle_SID@ @tessver-views.sql
sqlplus @oracle_rad3@/@oracle_rad3Password@@@oracle_SID@ @rad3-views.sql

# create all primary key constraints
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-pkey-constraints.sql
sqlplus @oracle_corever@/@oracle_coreverPassword@@@oracle_SID@ @corever-pkey-constraints.sql
sqlplus @oracle_sres@/@oracle_sresPassword@@@oracle_SID@ @sres-pkey-constraints.sql
sqlplus @oracle_sresver@/@oracle_sresverPassword@@@oracle_SID@ @sresver-pkey-constraints.sql
sqlplus @oracle_dots@/@oracle_dotsPassword@@@oracle_SID@ @dots-pkey-constraints.sql
sqlplus @oracle_dotsver@/@oracle_dotsverPassword@@@oracle_SID@ @dotsver-pkey-constraints.sql
sqlplus @oracle_tess@/@oracle_tessPassword@@@oracle_SID@ @tess-pkey-constraints.sql
sqlplus @oracle_tessver@/@oracle_tessverPassword@@@oracle_SID@ @tessver-pkey-constraints.sql
sqlplus @oracle_rad3@/@oracle_rad3Password@@@oracle_SID@ @rad3-pkey-constraints.sql

# create all non-primary key constraints
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-constraints.sql
sqlplus @oracle_corever@/@oracle_coreverPassword@@@oracle_SID@ @corever-constraints.sql
sqlplus @oracle_sres@/@oracle_sresPassword@@@oracle_SID@ @sres-constraints.sql
sqlplus @oracle_sresver@/@oracle_sresverPassword@@@oracle_SID@ @sresver-constraints.sql
sqlplus @oracle_dots@/@oracle_dotsPassword@@@oracle_SID@ @dots-constraints.sql
sqlplus @oracle_dotsver@/@oracle_dotsverPassword@@@oracle_SID@ @dotsver-constraints.sql
sqlplus @oracle_tess@/@oracle_tessPassword@@@oracle_SID@ @tess-constraints.sql
sqlplus @oracle_tessver@/@oracle_tessverPassword@@@oracle_SID@ @tessver-constraints.sql
sqlplus @oracle_rad3@/@oracle_rad3Password@@@oracle_SID@ @rad3-constraints.sql

# insert bootstrap rows, reset relevant sequences
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @bootstrap-rows.sql

# insert any other shared data/controlled vocabularies
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-DatabaseInfo-rows.sql
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-TableInfo-rows.sql
sqlplus @oracle_sres@/@oracle_sresPassword@@@oracle_SID@ @sres-BibRefType-rows.sql

# create all indexes
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-indexes.sql
sqlplus @oracle_corever@/@oracle_coreverPassword@@@oracle_SID@ @corever-indexes.sql
sqlplus @oracle_sres@/@oracle_sresPassword@@@oracle_SID@ @sres-indexes.sql
sqlplus @oracle_sresver@/@oracle_sresverPassword@@@oracle_SID@ @sresver-indexes.sql
sqlplus @oracle_dots@/@oracle_dotsPassword@@@oracle_SID@ @dots-indexes.sql
sqlplus @oracle_dotsver@/@oracle_dotsverPassword@@@oracle_SID@ @dotsver-indexes.sql
sqlplus @oracle_tess@/@oracle_tessPassword@@@oracle_SID@ @tess-indexes.sql
sqlplus @oracle_tessver@/@oracle_tessverPassword@@@oracle_SID@ @tessver-indexes.sql
sqlplus @oracle_rad3@/@oracle_rad3Password@@@oracle_SID@ @rad3-indexes.sql

# Issued sqlplus commands for 59 SQL files


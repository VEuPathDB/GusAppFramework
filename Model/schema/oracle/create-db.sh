#!/bin/sh

# Running this file will create a new GUS instance 

# create new users (as sys/sysdba) 
sqlplus 'sys/@oracle_systemPassword@@@oracle_SID@ as sysdba' @users.sql

# create all sequences
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-sequences.sql
sqlplus @oracle_rad@/@oracle_radPassword@@@oracle_SID@ @rad3-sequences.sql
sqlplus @oracle_sres@/@oracle_sresPassword@@@oracle_SID@ @sres-sequences.sql
sqlplus @oracle_dots@/@oracle_dotsPassword@@@oracle_SID@ @dots-sequences.sql
sqlplus @oracle_tess@/@oracle_tessPassword@@@oracle_SID@ @tess-sequences.sql
sqlplus @oracle_app@/@oracle_appPassword@@@oracle_SID@ @app-sequences.sql

# create all tables
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-tables.sql
sqlplus @oracle_corever@/@oracle_coreverPassword@@@oracle_SID@ @corever-tables.sql
sqlplus @oracle_rad@/@oracle_radPassword@@@oracle_SID@ @rad3-tables.sql
sqlplus @oracle_radver@/@oracle_radverPassword@@@oracle_SID@ @rad3ver-tables.sql
sqlplus @oracle_sres@/@oracle_sresPassword@@@oracle_SID@ @sres-tables.sql
sqlplus @oracle_sresver@/@oracle_sresverPassword@@@oracle_SID@ @sresver-tables.sql
sqlplus @oracle_dots@/@oracle_dotsPassword@@@oracle_SID@ @dots-tables.sql
sqlplus @oracle_dotsver@/@oracle_dotsverPassword@@@oracle_SID@ @dotsver-tables.sql
sqlplus @oracle_tess@/@oracle_tessPassword@@@oracle_SID@ @tess-tables.sql
sqlplus @oracle_tessver@/@oracle_tessverPassword@@@oracle_SID@ @tessver-tables.sql
sqlplus @oracle_app@/@oracle_appPassword@@@oracle_SID@ @app-tables.sql
sqlplus @oracle_appver@/@oracle_appverPassword@@@oracle_SID@ @appver-tables.sql

# create all views
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-views.sql
sqlplus @oracle_corever@/@oracle_coreverPassword@@@oracle_SID@ @corever-views.sql
sqlplus @oracle_rad@/@oracle_radPassword@@@oracle_SID@ @rad3-views.sql
sqlplus @oracle_radver@/@oracle_radverPassword@@@oracle_SID@ @rad3ver-views.sql
sqlplus @oracle_sres@/@oracle_sresPassword@@@oracle_SID@ @sres-views.sql
sqlplus @oracle_sresver@/@oracle_sresverPassword@@@oracle_SID@ @sresver-views.sql
sqlplus @oracle_dots@/@oracle_dotsPassword@@@oracle_SID@ @dots-views.sql
sqlplus @oracle_dotsver@/@oracle_dotsverPassword@@@oracle_SID@ @dotsver-views.sql
sqlplus @oracle_tess@/@oracle_tessPassword@@@oracle_SID@ @tess-views.sql
sqlplus @oracle_tessver@/@oracle_tessverPassword@@@oracle_SID@ @tessver-views.sql
sqlplus @oracle_app@/@oracle_appPassword@@@oracle_SID@ @app-views.sql
sqlplus @oracle_appver@/@oracle_appverPassword@@@oracle_SID@ @appver-views.sql

# Grant permission to reference tables in @oracle_core@ to all other schemas
echo '@oracle_corePassword@' | grantPermissions.pl --login=@oracle_core@ --owner=@oracle_core@ --permissions=REFERENCES --grantees=@oracle_rad@,@oracle_sres@,@oracle_dots@,@oracle_tess@,@oracle_app@ --db-sid=@oracle_SID@ --db-host=@oracle_host@ >@oracle_core@-grants.log

# Grant permission to reference tables in @oracle_sres@ to all other schemas
echo '@oracle_sresPassword@' | grantPermissions.pl --login=@oracle_sres@ --owner=@oracle_sres@ --permissions=REFERENCES --grantees=@oracle_core@,@oracle_rad@,@oracle_dots@,@oracle_tess@,@oracle_app@ --db-sid=@oracle_SID@ --db-host=@oracle_host@ >@oracle_sres@-grants.log

# Grant permission to reference tables in @oracle_dots@ to all other schemas except @oracle_core@
echo '@oracle_dotsPassword@' | grantPermissions.pl --login=@oracle_dots@ --owner=@oracle_dots@ --permissions=REFERENCES --grantees=@oracle_rad@,@oracle_sres@,@oracle_tess@,@oracle_app@ --db-sid=@oracle_SID@ --db-host=@oracle_host@ >@oracle_dots@-grants.log

# Grant permission to reference tables in @oracle_rad@ to @oracle_tess@
echo '@oracle_radPassword@' | grantPermissions.pl --login=@oracle_rad@ --owner=@oracle_rad@ --permissions=REFERENCES --grantees=@oracle_tess@ --db-sid=@oracle_SID@ --db-host=@oracle_host@ >@oracle_rad@-grants.log

# insert bootstrap rows, reset relevant sequences
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @bootstrap-rows.sql

# insert any other shared data/controlled vocabularies
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-AlgorithmParamKeyType-rows.sql
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-DatabaseInfo-rows.sql
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-TableInfo-rows.sql

# create all primary key constraints
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-pkey-constraints.sql
sqlplus @oracle_corever@/@oracle_coreverPassword@@@oracle_SID@ @corever-pkey-constraints.sql
sqlplus @oracle_rad@/@oracle_radPassword@@@oracle_SID@ @rad3-pkey-constraints.sql
sqlplus @oracle_radver@/@oracle_radverPassword@@@oracle_SID@ @rad3ver-pkey-constraints.sql
sqlplus @oracle_sres@/@oracle_sresPassword@@@oracle_SID@ @sres-pkey-constraints.sql
sqlplus @oracle_sresver@/@oracle_sresverPassword@@@oracle_SID@ @sresver-pkey-constraints.sql
sqlplus @oracle_dots@/@oracle_dotsPassword@@@oracle_SID@ @dots-pkey-constraints.sql
sqlplus @oracle_dotsver@/@oracle_dotsverPassword@@@oracle_SID@ @dotsver-pkey-constraints.sql
sqlplus @oracle_tess@/@oracle_tessPassword@@@oracle_SID@ @tess-pkey-constraints.sql
sqlplus @oracle_tessver@/@oracle_tessverPassword@@@oracle_SID@ @tessver-pkey-constraints.sql
sqlplus @oracle_app@/@oracle_appPassword@@@oracle_SID@ @app-pkey-constraints.sql
sqlplus @oracle_appver@/@oracle_appverPassword@@@oracle_SID@ @appver-pkey-constraints.sql

# create all non-primary key constraints
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-constraints.sql
sqlplus @oracle_corever@/@oracle_coreverPassword@@@oracle_SID@ @corever-constraints.sql
sqlplus @oracle_rad@/@oracle_radPassword@@@oracle_SID@ @rad3-constraints.sql
sqlplus @oracle_radver@/@oracle_radverPassword@@@oracle_SID@ @rad3ver-constraints.sql
sqlplus @oracle_sres@/@oracle_sresPassword@@@oracle_SID@ @sres-constraints.sql
sqlplus @oracle_sresver@/@oracle_sresverPassword@@@oracle_SID@ @sresver-constraints.sql
sqlplus @oracle_dots@/@oracle_dotsPassword@@@oracle_SID@ @dots-constraints.sql
sqlplus @oracle_dotsver@/@oracle_dotsverPassword@@@oracle_SID@ @dotsver-constraints.sql
sqlplus @oracle_tess@/@oracle_tessPassword@@@oracle_SID@ @tess-constraints.sql
sqlplus @oracle_tessver@/@oracle_tessverPassword@@@oracle_SID@ @tessver-constraints.sql
sqlplus @oracle_app@/@oracle_appPassword@@@oracle_SID@ @app-constraints.sql
sqlplus @oracle_appver@/@oracle_appverPassword@@@oracle_SID@ @appver-constraints.sql

# create all indexes
sqlplus @oracle_core@/@oracle_corePassword@@@oracle_SID@ @core-indexes.sql
sqlplus @oracle_corever@/@oracle_coreverPassword@@@oracle_SID@ @corever-indexes.sql
sqlplus @oracle_rad@/@oracle_radPassword@@@oracle_SID@ @rad3-indexes.sql
sqlplus @oracle_radver@/@oracle_radverPassword@@@oracle_SID@ @rad3ver-indexes.sql
sqlplus @oracle_sres@/@oracle_sresPassword@@@oracle_SID@ @sres-indexes.sql
sqlplus @oracle_sresver@/@oracle_sresverPassword@@@oracle_SID@ @sresver-indexes.sql
sqlplus @oracle_dots@/@oracle_dotsPassword@@@oracle_SID@ @dots-indexes.sql
sqlplus @oracle_dotsver@/@oracle_dotsverPassword@@@oracle_SID@ @dotsver-indexes.sql
sqlplus @oracle_tess@/@oracle_tessPassword@@@oracle_SID@ @tess-indexes.sql
sqlplus @oracle_tessver@/@oracle_tessverPassword@@@oracle_SID@ @tessver-indexes.sql
sqlplus @oracle_app@/@oracle_appPassword@@@oracle_SID@ @app-indexes.sql
sqlplus @oracle_appver@/@oracle_appverPassword@@@oracle_SID@ @appver-indexes.sql

# Issued sqlplus commands for 71 SQL files


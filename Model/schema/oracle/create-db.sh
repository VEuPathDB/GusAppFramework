#!/bin/sh

# Running this file will create a new GUS instance 

# create new users (as sys/sysdba) 
sqlplus 'sys/gornfhs8@gusdev as sysdba' @users.sql

# create all sequences
sqlplus Coretest/password1@gusdev @core-sequences.sql
sqlplus SRestest/password2@gusdev @sres-sequences.sql
sqlplus DoTStest/password3@gusdev @dots-sequences.sql
sqlplus TESStest/password4@gusdev @tess-sequences.sql
sqlplus RAD3test/password5@gusdev @rad3-sequences.sql

# create all tables
sqlplus Coretest/password1@gusdev @core-tables.sql
sqlplus CoretestVer/password1@gusdev @corever-tables.sql
sqlplus SRestest/password2@gusdev @sres-tables.sql
sqlplus SRestestVer/password2@gusdev @sresver-tables.sql
sqlplus DoTStest/password3@gusdev @dots-tables.sql
sqlplus DoTStestVer/password3@gusdev @dotsver-tables.sql
sqlplus TESStest/password4@gusdev @tess-tables.sql
sqlplus TESStestVer/password4@gusdev @tessver-tables.sql
sqlplus RAD3test/password5@gusdev @rad3-tables.sql

# create all views
sqlplus Coretest/password1@gusdev @core-views.sql
sqlplus CoretestVer/password1@gusdev @corever-views.sql
sqlplus SRestest/password2@gusdev @sres-views.sql
sqlplus SRestestVer/password2@gusdev @sresver-views.sql
sqlplus DoTStest/password3@gusdev @dots-views.sql
sqlplus DoTStestVer/password3@gusdev @dotsver-views.sql
sqlplus TESStest/password4@gusdev @tess-views.sql
sqlplus TESStestVer/password4@gusdev @tessver-views.sql
sqlplus RAD3test/password5@gusdev @rad3-views.sql

# create all primary key constraints
sqlplus Coretest/password1@gusdev @core-pkey-constraints.sql
sqlplus CoretestVer/password1@gusdev @corever-pkey-constraints.sql
sqlplus SRestest/password2@gusdev @sres-pkey-constraints.sql
sqlplus SRestestVer/password2@gusdev @sresver-pkey-constraints.sql
sqlplus DoTStest/password3@gusdev @dots-pkey-constraints.sql
sqlplus DoTStestVer/password3@gusdev @dotsver-pkey-constraints.sql
sqlplus TESStest/password4@gusdev @tess-pkey-constraints.sql
sqlplus TESStestVer/password4@gusdev @tessver-pkey-constraints.sql
sqlplus RAD3test/password5@gusdev @rad3-pkey-constraints.sql

# create all non-primary key constraints
sqlplus Coretest/password1@gusdev @core-constraints.sql
sqlplus CoretestVer/password1@gusdev @corever-constraints.sql
sqlplus SRestest/password2@gusdev @sres-constraints.sql
sqlplus SRestestVer/password2@gusdev @sresver-constraints.sql
sqlplus DoTStest/password3@gusdev @dots-constraints.sql
sqlplus DoTStestVer/password3@gusdev @dotsver-constraints.sql
sqlplus TESStest/password4@gusdev @tess-constraints.sql
sqlplus TESStestVer/password4@gusdev @tessver-constraints.sql
sqlplus RAD3test/password5@gusdev @rad3-constraints.sql

# insert bootstrap rows, reset relevant sequences
sqlplus Coretest/password1@gusdev @bootstrap-rows.sql

# insert any other shared data/controlled vocabularies
sqlplus Coretest/password1@gusdev @core-DatabaseInfo-rows.sql
sqlplus Coretest/password1@gusdev @core-TableInfo-rows.sql
sqlplus SRestest/password2@gusdev @sres-BibRefType-rows.sql

# create all indexes
sqlplus Coretest/password1@gusdev @core-indexes.sql
sqlplus CoretestVer/password1@gusdev @corever-indexes.sql
sqlplus SRestest/password2@gusdev @sres-indexes.sql
sqlplus SRestestVer/password2@gusdev @sresver-indexes.sql
sqlplus DoTStest/password3@gusdev @dots-indexes.sql
sqlplus DoTStestVer/password3@gusdev @dotsver-indexes.sql
sqlplus TESStest/password4@gusdev @tess-indexes.sql
sqlplus TESStestVer/password4@gusdev @tessver-indexes.sql
sqlplus RAD3test/password5@gusdev @rad3-indexes.sql

# Issued sqlplus commands for 59 SQL files


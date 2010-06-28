# Creates triggers on all GUS tables which will update the modification_date
# of a row when this is inserted/updated. Useful to keep modification_date 
# honest when an insert or update is made on the db with SQL instead of 
# a plugin.

# Elisabetta Manduchi 06/28/2010 (using code sample from John Iodice)


# $ARGV[0] is the file generated with the query below, after removing 
# the header:
# select owner || '.' ||  table_name  
# from all_tables where owner  in 
# ('CORE', 'DOTS', 'PROT', 'RAD', 'SRES', 'STUDY', 'TESS', 
# 'COREVER', 'DOTSVER', 'PROTVER', 'RADVER', 'SRESVER', 'STUDYVER', 'TESSVER') 
# order by owner, table_name asc

use strict;
use IO::File;

my $fh = IO::File->new("<$ARGV[0]");

my %exists;;

while (my $line=<$fh>) {
  chomp($line);
  my $table = $line;

  until (length($line)<=27 && !$exists{$line . "_md"}) {
    chop($line);
  }

  my $name = $line . "_md";
  $exists{$name} = 1;

  STDOUT->print("create or replace trigger $name\nbefore update or insert on $table\nfor each row\nbegin\n :new.modification_date := sysdate;\nend;\n\/\n\n");
}
$fh->close();


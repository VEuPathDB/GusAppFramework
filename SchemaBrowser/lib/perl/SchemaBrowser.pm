#!/usr/bin/perl

# ----------------------------------------------------------
# SchemaBrowser.pm
#
# Schema browser package that relies on the GUS objects 
# to obtain information about parents/child relationships, 
# keys, etc.
# 
# Created: Tue Mar 21 10:54:15 EST 2000
#
# TO DO: 1. propagate parent/child relns from tables to
#           views on those tables
#        2. allow users to choose columns and display a
#           query form at the end
#
# Jonathan Crabtree
# ----------------------------------------------------------

package GUS::SchemaBrowser::SchemaBrowser;

use strict;

use GUS::ObjRelP::DbiDatabase;
use GUS::ObjRelP::DbiTable;

# ----------------------------------------------------------
# Configuration
# ----------------------------------------------------------

# ----------------------------------------------------------
# Constructor
# ----------------------------------------------------------

sub new {
    my($class, $myURL, $header, $footer, $db, $hasTableInfo ) = @_;
    bless(my $self = {}, $class);
    $self->{'myURL'} = $myURL;
    $self->{'db'} = $db;
    $self->{'hasTableInfo'} = $hasTableInfo;
    $self->{'header'} = $header;
    $self->{'footer'} = $footer;
    return $self;
}

# ----------------------------------------------------------
# generatePage: display an HTML page
# ----------------------------------------------------------

# $args->{'path'}   colon-delimited list of table names representing
#                   the path the user has followed from the index page
#
sub generatePage() {
    my($self, $args) = @_;
    
    my $dbName = $args->{'db'};
    my $tableName = $args->{'table'};
    my $path = $args->{'path'};
    my $title = $args->{'title'};

    print "Content-type:text/html\n\n";
    &{$self->{'header'}}($self, $args);

    if ($dbName eq '*') {
	&listAllDatabases($self, $args->{'logins'}, $args->{'loginsOrder'});
    } elsif ($tableName eq '*') {
	if ($self->{'hasTableInfo'}) {
	    &listAllTablesUsingTableInfo($self, $dbName, $path, 1);
	} else {
	    &listAllTables($self, $dbName, $path);
	}
    } else {
	&displayTable($self, $dbName, $tableName, $path);
    }
    
    print "<BR>\n";
    &{$self->{'footer'}}($self, $args);
    print "</BODY>\n";
    print "</HTML>\n";
}

# ----------------------------------------------------------
# Subroutines
# ----------------------------------------------------------

# List all the databases that can be browsed
#
sub listAllDatabases {
    my ($self, $logins, $loginsOrder) = @_;
    print "<BR>";
    print "<FONT FACE=\"helvetica,sans-serif\"><B>Databases available for browsing:</B></FONT><BR>\n";
    print "<BR>";

    print "<TABLE BORDER=\"0\" CELLPADDING=\"1\" CELLSPACING=\"0\" BGCOLOR=\"#dddddd\">\n";
    print "<TR><TD>\n";

    print "<TABLE BORDER=\"0\" CELLPADDING=\"5\" CELLSPACING=\"1\" BGCOLOR=\"#ffffff\" WIDTH=\"100%\">\n";

    foreach my $k (defined($loginsOrder) ? @$loginsOrder : keys %$logins) {
	print "<TR>\n";
	if ($$logins{$k}->{'disabled'}) {
	    print &formatTD("$k");
	} else {
	    print &formatTD("<A HREF=\"" . $self->{'myURL'} . "?db=$k\">$k</A>");
	}
	print &formatTD($$logins{$k}->{'description'});
	print "</TR>\n";
    }

    print "</TD></TR></TABLE>";
    print "</TABLE>";
}

# Display an exhaustive list of all tables and views, without
# relying on a TableInfo table.
#
sub listAllTables {
    my($self, $dbName, $path) = @_;

    my $tref = $self->{'db'}->getTableNames();
    my $vref = $self->{'db'}->getViewNames();
    my %vHash;

    foreach my $v (@$vref) { $vHash{$v} = 1; }

    push(@$tref, @$vref);

    my @sorted = sort { my $cA = $a; my $cB = $b; 
			$cA =~ tr/[a-z]/[A-Z]/; $cB =~ tr/[a-z]/[A-Z]/; 
			$cA cmp $cB} @$tref;

    print "<BR>";

    print "<TABLE BORDER=\"0\" CELLPADDING=\"2\" CELLSPACING=\"0\" BGCOLOR=\"#000000\">\n";
    print "<TR><TD>\n";

    print "<TABLE BORDER=\"0\" CELLPADDING=\"2\" CELLSPACING=\"1\" BGCOLOR=\"#ffffff\" WIDTH=\"100%\">\n";
    print "<TR>";
    print &formatTH("Name"), "\n";
    print &formatTH("Type"), "\n";
    print "</TR>\n";

    foreach my $tname (@sorted) {
	my $isView = defined($vHash{$tname});

	my $bgcolor = "#ffffff";
	$bgcolor = "#ccccff" if ($isView);

	print "<TR BGCOLOR=\"$bgcolor\">";
	print &formatTableTD($self, $tname, $dbName, $path);
	print &formatTD($isView ? "view" : "standard");
	print "</TR\n>";
    }
    
    print "</TABLE>\n";
    print "</TD></TR></TABLE>\n";
    print "<BR>";
}

# Display an exhaustive list of all tables using the TableInfo table.
#
sub listAllTablesUsingTableInfo {
    my($self, $dbName, $path, $showDocs) = @_;

    my $dbh = $self->{'db'}->getQueryHandle();
    my $q = $self->doSelect("select d.name||'::'||t.name as perl_name,t.* from ".$self->{db}->getCoreName().'.TableInfo t, '.$self->{db}->getCoreName().".DatabaseInfo d where t.name not like '%Ver' and d.database_id = t.database_id");
    my @sorted = sort {$a->{'perl_name'} cmp $b->{'perl_name'}} @$q;

    # Hash keyed on table id 
    #
    my %idHash;
    foreach my $row (@sorted) {
	$idHash{$row->{'table_id'}} = $row->{'perl_name'};
    }

    my $allTableDocs = $self->getAllTablesDocumentation();

    print "<BR>";
    print "<TABLE BORDER=\"0\" CELLPADDING=\"2\" CELLSPACING=\"0\" BGCOLOR=\"#000000\">\n";
    print "<TR><TD>\n";

    print "<TABLE BORDER=\"0\" CELLPADDING=\"2\" CELLSPACING=\"1\" BGCOLOR=\"#ffffff\" WIDTH=\"100%\">\n";
    print "<TR>";
    print &formatTH("ID"), "\n";
    print &formatTH("Name"), "\n";
#    print &formatTH("type"), "\n";
#    print &formatTH("is versioned?"), "\n";
    print &formatTH("view on"), "\n";
    print &formatTH("description"), "\n" if ($showDocs);
    print "</TR>\n";

    foreach my $row (@sorted) {
	next if ($row->{'table_type'} eq 'version');
	my $tableName = $row->{'perl_name'};

	my $bgcolor = "#ffffff";
	$bgcolor = "#ccccff" if ($row->{'is_view'});

	print "<TR BGCOLOR=\"$bgcolor\">";
	print &formatTD($row->{'table_id'});
	print &formatTableTD($self, $tableName, $dbName, $path);

#	if ($row->{'is_view'}) {
#	    print &formatTD("view");
#	} else {
#	    print &formatTD($row->{'table_type'});
#	}

#	print &formatRevBoolTD($row->{'is_versioned'});

	if ($row->{'is_view'}) {
	    print &formatTableTD($self, $idHash{$row->{'view_on_table_id'}}, $dbName, $path);
	} else {
	    print &formatTD("&nbsp;");
	}

	if ($showDocs) {
	    my $docs = $allTableDocs->{$tableName}->{'html_documentation'};
	    if ($docs =~ /^\s*$/) {
		print &formatTD('&nbsp;');
	    } else {
		print &formatTD("<FONT SIZE=\"-1\">" . $docs . "</FONT>");
	    }
	}

	print "</TR>\n";
    }

    print "</TABLE>\n";
    print "</TD></TR></TABLE>\n";
    print "<BR>";
}

# Query the TableInfo table for a particular table
#
sub getTableInfo {
    my ($self, $t) = @_;

    my $data = $self->doSelect("select * from TableInfo where name = '$t'");
    my $row = $data->[0];

    if ($row->{'is_view'}) {
	my $data2 = $self->doSelect("select name from TableInfo where table_id = " . 
				    $row->{'view_on_table_id'});
	my $row2 = $data2->[0];
	$row->{'view_table'} = $row2->{'name'};
    }

    return $row;
}

# Display HTML representation of a specified table.
#
sub displayTable {
    my($self, $dbName, $tableName, $path) = @_;
    my $extent = $self->{'db'}->getTable($tableName);

    my $isSybase = $self->{'db'}->getDSN() =~ /sybase/i;
    my $isOracle = $self->{'db'}->getDSN() =~ /oracle/i;

    if (not defined($extent)) {
	print "<PRE>Unknown table</PRE>\n";
	return;
    }

    my $lref = $extent->getAttributeInfo();
    my $primkey = $extent->getPrimaryKeyAttributes();

    my $parents = $extent->getParentRelations();
#    my $kids = $extent->getChildRelations();
    my $kids = $extent->getChildListWithAtts();

    # Process parent relations into a hash indexed by
    # column name.
    #
    my %pHash;

    foreach my $p (@$parents) {
	my $rel = $p->[0];
        $pHash{$p->[1]} =  {'table' => $p->[0], 'columns' => $p->[2]};
    }
#     foreach my $p (keys %$parents) {
# 	my $rel = $parents->{$p};
# 	foreach my $mykey (keys %$rel) {
# 	    my $val = $rel->{$mykey};
# 	    $pHash{$mykey} = {'table' => $p, 'columns' => $val};
# 	}
#     }

    # Process child relations into a hash indexed by
    # column name.
    #
    my %cHash;
#    foreach my $k (@$kids) {
#      $pHash{$k->[1]} =  {'table' => $k->[0], 'columns' => $k->[2]};
#    }
    ##using childList with expanded views..
    foreach my $k (keys%$kids) {
        $cHash{$kids->{$k}->[0]} =  {'table' => $k, 'columns' => $kids->{$k}->[1]};
    }
#     foreach my $c (keys %$kids) {
# 	my $rel = $kids->{$c};

# 	foreach my $mykey (keys %$rel) {
# 	    my $val = $rel->{$mykey};
# 	    $cHash{$mykey} = {'table' => $c, 'columns' => $val};
# 	}
#     }
    
    my $tinfo;

    $tinfo = {table_id => $extent->getTableId(), 
              is_view => $extent->isView(),
              view_table => ,$extent->getRealTableName(),
              table_type => 'standard'};

    my $isView = $extent->isView();

    my $tID = defined($tinfo->{'table_id'}) ? $tinfo->{'table_id'} . ". " : "";
    my $mSplit = $tinfo->{'is_merge_split_table'};
    my $isVersioned = $tinfo->{'is_versioned'};
    my $viewTable = $tinfo->{'view_table'};
    my $tType = $tinfo->{'table_type'};
    my $descr;
    my $vertable;

    if ($isView && (not(defined($viewTable)))) {
	my($vt) = ($extent->getViewSql() =~ /from\s*([^,\s]+)\s*/);
	$viewTable = $vt;
    }

    if ($isView) {
	$descr = "view on " . &tableLink($self, $viewTable, $dbName, $path);
    } else {
	$descr = "$tType table";
    }

    if ($isVersioned) {
	$vertable = ", version table = " . &tableLink($self, "${tableName}Ver", $dbName, $path);
    } else {
	$vertable = "";
    }

    my $pPath = "";

    print "<A HREF=\"", $self->{'myURL'}, "?db=$dbName\">$dbName</A>: \n";

    foreach my $node (split('\|', $path)) {
	print "->" if ($pPath ne '');
	print &tableLink($self, $node, $dbName, $pPath);

	if ($pPath eq '') {
	    $pPath = $node;
	} else {
	    $pPath = "$pPath:$node";
	}
    }

    # Get documentation for this table
    my $attDocs = $self->getTableDocumentation($tID);
    my $tableDocs = $attDocs->{'***table'};

    print "<BR><BR>";

    print "<FONT FACE=\"helvetica,sans-serif\"><B>$tID $dbName..$tableName</B> ($descr) $vertable</FONT>\n";
    print "<BR><BR>";

    if (defined($tableDocs)) {
	my $tableHtml = $tableDocs->{'html_documentation'};
	if ($tableHtml =~ /\S/) {
	    print $tableHtml, "\n";
	    print "<BR CLEAR = \"both\">\n";
	    print "<BR>\n";
	}
    }

    print "<TABLE BORDER=\"0\" CELLPADDING=\"2\" CELLSPACING=\"0\" BGCOLOR=\"#000000\" WIDTH=\"100%\">\n";
    print "<TR><TD>\n";

    print "<TABLE BORDER=\"0\" CELLPADDING=\"2\" CELLSPACING=\"1\" BGCOLOR=\"#ffffff\" WIDTH=\"100%\">\n";
    print "<TR>";
    print &formatTH("column"), "\n";
    print &formatTH("nulls?"), "\n";
    print &formatTH("identity?"), "\n" if ($isSybase);
    print &formatTH("type"), "\n";
    print &formatTH("actual type"), "\n" if ($isSybase);
#    print &formatTH("scale"), "\n";
#    print &formatTH("precision"), "\n";
    print &formatTH("parent table"), "\n";
    print &formatTH("description"), "\n";
    print "</TR>\n";

    my $bgcolor;

    foreach my $att (@$lref) {
	my $cname = $att->{'col'};
	my $lcname = $cname;
	$lcname =~ tr/A-Z/a-z/;

	$bgcolor = "#ffffff";
	$bgcolor = "#ffcccc" if (grep(/^$cname$/, @$primkey));     # primary key column

	print "<TR BGCOLOR=\"$bgcolor\">";

	print &formatTD($cname);
	print &formatRevBoolTD($att->{'Nulls'});
	print &formatBoolTD($att->{'isIdentity'}) if ($isSybase);

	my $aType = $att->{'type'};
	$aType =~ tr/[A-Z]/[a-z]/;

	if ($isOracle) {
	    if ($aType =~ /number/) {
		print &formatTD($aType . "(" . $att->{'prec'} . ")");
	    } else {
		print &formatTD($aType . "(" . $att->{'length'} . ")");
	    }
	} else {
	    print &formatTD($aType . "(" . $att->{'length'} . ")");
	}

	if ($isSybase) {
	    if ($att->{'base_type'} ne $att->{'type'}) {
		print &formatTD($att->{'base_type'} . "(" . $att->{'length'} . ")");
	    } else {
		print &formatTD("&nbsp;");
	    }
	}

#	print &formatTD($att->{'scale'});
#	print &formatTD($att->{'prec'});

	# Parent relations
	#
        if (defined $pHash{$cname}) {
	    my $reln = $pHash{$cname};
	    print &formatTableTD($self, $reln->{'table'}, $dbName, $path);
	} else {
	    print &formatTD("&nbsp;");
	}

	my $doc = $attDocs->{$lcname};
	if (defined($doc)) {
	    my $html = $doc->{'html_documentation'};
	    if ($html =~ /\S/) {
		print "<TD>\n";
		print "<FONT SIZE=\"-1\">\n";
		print $html;
		print "</FONT>\n";
		print "</TD>\n";
	    }
	} else {
	    print "<TD>&nbsp;</TD>\n";
	}
	print "</TR>\n";
    }

    print "</TABLE>\n";
    print "</TD></TR></TABLE>";
    print "<BR CLEAR=\"left\">\n";
    
    print "<FONT FACE=\"helvetica, sans-serif\"><B>Child tables:</B></FONT> ";
    
    foreach my $k (keys%$kids) { print &tableLink($self, $k, $dbName, $path), " "; }
#    foreach my $kid (@$kids) { print &tableLink($self, $kid->[0], $dbName, $path), " "; }
    print "<I>none</I>" if (scalar(keys%$kids) == 0);
#    print "<I>none</I>" if (scalar(@$kids) == 0);

    if ($isView) {
	print "<BR><BR>\n";
	print "<FONT FACE=\"helvetica, sans-serif\"><B>View SQL:</B></FONT>\n";
	print "<PRE>";
	print $extent->getViewSql();
	print "</PRE>";
    }

    print "<BR><BR>";
}

sub formatTH {
    my($str) = @_;
    return ("<TH BGCOLOR=\"#2020ff\" ALIGN=\"left\">" .
	    "<FONT COLOR=\"#ffffff\" FACE=\"helvetica, sans-serif\">$str</FONT></TH>");
}

sub formatTD {
    my($str) = @_;
    return '<TD>&nbsp;</TD>' if ($str =~ /^(NULL|\s*)$/i);
    return "<TD>$str</TD>";
}

sub formatBoolTD {
    my($str) = @_;
    return "<TD ALIGN=\"center\">yes</TD>" if ($str eq '1');
    return "<TD>&nbsp;</TD>" if ($str eq '0');
    return "<TD>&str</TD>";
}

sub formatRevBoolTD {
    my($str) = @_;
    return "<TD ALIGN=\"center\">no</TD>" if ($str eq '0');
    return "<TD>&nbsp;</TD>"; # if ($str eq '1');
    return "<TD>&str</TD>";
}

sub formatTableTD {
    my($self, $str, $dbname, $path) = @_;
    return "<TD>&nbsp;</TD>" if ($str =~ /^\s*$/);
    return "<TD>" . &tableLink($self, $str, $dbname, $path) . "</TD>";
}

sub tableLink {
    my($self, $t, $dbname, $path) = @_;
    my $newpath = ($path ne '') ? "$path|$t" : $t;
    return "<A HREF=\"" . $self->{'myURL'} . "?db=$dbname&table=$t&path=$newpath\">$t</A>";
}

# Retrieve documentation (if any) on a particular table and its columns from
# the GUS 'DatabaseDocumentation' table.  Rows are return in a hash indexed
# on column name.  The documentation for the table itself (column = 'null')
#
#
sub getTableDocumentation {
    my($self, $tableID) = @_;
#    return {} if (!($self->{'db'}->checkTableExists('DatabaseDocumentation')));
    my $rows = $self->doSelect("select * from ".$self->{db}->getCoreName().".DatabaseDocumentation where table_id = $tableID");
    my $hash = {};
    foreach my $row (@$rows) {
	my $attName = $row->{'attribute_name'};
	$attName =~ tr/A-Z/a-z/;
	if (defined($attName)) {
	    $hash->{$row->{'attribute_name'}} = $row;
	} else {
	    $hash->{'***table'} = $row;
	}
    }
    return $hash;
}

# Retrieve documentation for all tables (but not their columns)
#
sub getAllTablesDocumentation {
    my $self = shift;
#    return {} if (!($self->{'db'}->checkTableExists('DatabaseDocumentation')));
    my $rows = $self->doSelect("select db.name as schema,ti.name, dd.* " .
			       "from ".$self->{db}->getCoreName().".DatabaseDocumentation dd, ".
                               $self->{db}->getCoreName().".TableInfo ti, " .
                               $self->{db}->getCoreName().".DatabaseInfo db " .
			       "where dd.attribute_name is NULL " .
			       "and dd.table_id = ti.table_id " .
                               "and db.database_id = ti.database_id");
    my $hash = {};
    foreach my $row (@$rows) {
	my $tableName = $row->{schema}."::".$row->{'name'};
	$hash->{$tableName} = $row;
    }
    return $hash;
}

# Run a query and return the results as an arrayref
# of hashrefs.
#
sub doSelect {
    my($self, $query) = @_;
    my $result = [];

#   print STDERR "SchemaBrowser.pm: $query\n";

    my $dbh = $self->{'db'}->getQueryHandle();
    my $sth = $dbh->prepare($query);
    $sth->execute();

    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
	my %copy = %$row;
	push(@$result, \%copy);
    }
    $sth->finish();

    return $result;
}

1;

#!@perl@

# -----------------------------------------------------------------------
# Table.pm
#
# Perl object that represents an Oracle table or view.
#
# Created: Thu Feb 22 13:30:43 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

package GUS::DBAdmin::Table;

use strict;

use GUS::DBAdmin::Util;

# -----------------------------------------------------------------------
# Constructor
# -----------------------------------------------------------------------

sub new {
    my($class, $args) = @_;

    my $self = {
	owner => $args->{owner},
	name => $args->{name},
	db => $args->{db},
    };

    bless $self, $class;
    return $self;
}

# -----------------------------------------------------------------------
# Table
# -----------------------------------------------------------------------

# Convert to an identifier that can be used in an SQL query.
#
sub toString {
    my $self = shift;
    my $owner = $self->{owner};
    my $name = $self->{name};
    my $db = $self->{db};

    my $str = '';
    $str .= "${owner}." if (defined($owner));
    $str .= $name;
    $str .= "@${db}" if (defined($db));
    return $str;
}

# Whether this is actually a view
#
sub isView {
    my($self, $dbh) = @_;
    my $owner = $self->{owner};
    my $name = $self->{name};

    my $sql = ("select count(*) from all_views " .
	       "where owner = upper('$owner') " .
	       "and view_name = upper('$name') ");

    my $rows = &GUS::DBAdmin::Util::execQuery($dbh, $sql, 'scalar');

    return ($rows->[0] > 0);
}

# Generate the SQL required to recreate this object.
#
sub getSQL {
    my($self, $dbh, $newOwner, $newTS) = @_;
    return ($self->isView($dbh)) ? 
	$self->getViewSQL($dbh, $newOwner) : $self->getTableSQL($dbh, $newOwner, $newTS);
}

# Generate the SQL required to create a "version table" for this object.
#
sub getVersionTableSQL {
    my($self, $dbh, $newOwner, $newTS) = @_;
    return ($self->isView($dbh)) ? 
	$self->getViewSQL($dbh, $newOwner, 1) : $self->getTableSQL($dbh, $newOwner, $newTS, 1);
}

# Generate the SQL required to recreate this object (if it's a view.)
#
# $verTable  -  Whether to generate the SQL required to create the version database
#               view that would correspond to this object.
#
sub getViewSQL {
    my($self, $dbh, $newOwner, $verTable) = @_;
    my $owner = $self->{owner};
    my $name = $self->{name};

    $newOwner = $owner if (!defined($newOwner));
    $newOwner .= "." if ($newOwner =~ /^&&/);

    my $sql = ("select text from all_views " .
	       "where owner = upper('$owner') " .
	       "and view_name = upper('$name') ");

    my $rows = &GUS::DBAdmin::Util::execQuery($dbh, $sql, 'scalar');
    my $viewSql = $rows->[0];
    $viewSql =~ s/([\s\n\m]+)$//mg;

    my $s;

    if ($viewSql =~ /select\s+\S+\s*(,|from)/i) {

	# See whether we can parse the SELECT clause and rewrite the view
	# statement in a more concise form; this is GUS-specific.
	#
	my $cols = $self->getColumnList($dbh);

	my($values, $theRest, $where) = ($viewSql =~ /\s*select\s+((?:[^,]+\s*,\s*)+\S+(?:\s*as\s*\S+)?)(\s+from\s+\S+\s+(where\s+(?:\S+\.)?subclass_view\s*=\s*'\S+'\s+)?with check option\s*)$/mi);
	my @colVals = split(/\s*,\s*/, $values);

	if ((scalar(@colVals) == scalar(@$cols)) && ($theRest =~ /\S/)) {
	    my $ncols = scalar(@colVals);
	    my $newVals = [];

	    for(my $i = 0;$i < $ncols;++$i) {
		my $colName = $cols->[$i];
		my $colVal = $colVals[$i];
		$colName =~ tr/A-Z/a-z/;

		if ($colVal =~ /^(\S+\s+\S+|\S+\s+as\s+\S+)$/i) {
		    $colVal =~ s/\s+as\s+/ AS /;
		    push(@$newVals, $colVal);
		} else {
		    $colVal =~ tr/A-Z/a-z/;
		    push(@$newVals, ($colName eq $colVal) ? $colName : "$colVal AS $colName");
		}
	    }
	    
	    if ($verTable) {
		$s = "CREATE VIEW ${newOwner}.${name}Ver\nAS SELECT\n  " . join(",\n  ", @$newVals) . " $theRest;\n";
	    } else {
		$s = "CREATE VIEW ${newOwner}.${name}\nAS SELECT\n  " . join(",\n  ", @$newVals) . " $theRest;\n";
	    }
	} else {

	    # DEBUG
	    
#	    print STDERR "WARNING - unable to parse $owner.$name into simpler form\n";
#	    print STDERR "viewSql = '$viewSql'\n";
#	    print STDERR "values = '$values' theRest = '$theRest'\n";
#	    print STDERR "numcols = ", scalar(@$cols), "\n";
#	    print STDERR "numcolvals = ", scalar(@colVals), "\n";

	    my $cstring = join(",\n  ", @$cols);

	    if ($verTable) {
		$s = "CREATE VIEW ${newOwner}.${name}Ver\n( $cstring )\nAS $viewSql;\n";
	    } else {
		$s = "CREATE VIEW ${newOwner}.${name}\n( $cstring )\nAS $viewSql;\n";
	    }

#	    print STDERR "CREATE = '$s'\n";
	}
    } else {
	if ($verTable) {
	    $s = "CREATE VIEW ${newOwner}.${name}Ver\nAS $viewSql;\n";
	} else {
	    $s = "CREATE VIEW ${newOwner}.${name}\nAS $viewSql;\n";
	}
    }

    my ($fromTable) = ($s =~ /^\s*from (\S+)/mi);

    # If $verTable, try to append "Ver" to the name of the table being selected from
    # and add the extra columns required in a version table.
    #
    if ($verTable && $fromTable =~ /\S/) {
	$s =~ s/^(\s*from )(\S+)/$1$2Ver/mi;

	my $extraCols = "  version_alg_invocation_id,\n  version_date,\n  version_transaction_id";
	$s =~ s/(....)$(\s*from )(\S+)/$1,\n$extraCols$2$3/mi;
    }

    # HACK - This is special-purpose code aimed at simplifying the syntax of the RAD3 views.
    #
    if ($fromTable =~ /\S/) {
	my $fsub = sub {
	    my($spaces, $n1, $n2) = @_;
	    if (lc($n1) eq lc($n2)) {
		return "  $n2";
	    } else {
		return "  $n1 AS $n2";
	    }
	};
	$s =~ s/^(\s*)$fromTable\./$1/mgi;
	$s =~ s/^(\s*)(\S+) as ([^,\s]+)/&$fsub($1,$2,$3)/mgie;
    }

    return $s;
}

# Generate the SQL required to recreate this object (if it's a table.)  
# Does not include constraints (including PRIMARY KEY, if any) or indexes.
#
sub getTableSQL {
    my($self, $dbh, $newOwner, $newTS, $verTable) = @_;
    my $owner = $self->{owner};
    my $name = $self->{name};

    $newOwner = $owner if (!defined($newOwner));

    my $sql = ("select * " .
	       "from all_tab_columns " .
	       "where owner = upper('$owner') " .
	       "and table_name = upper('$name') " .
	       "order by column_id asc ");

    my $cols = &GUS::DBAdmin::Util::execQuery($dbh, $sql, 'hash');
    
    my $s = '';
    my $tname = $verTable ? "${name}Ver" : $name;

    if ($newOwner =~ /^&&/) {
	$s .= "CREATE TABLE ${newOwner}..${tname} (\n";
    } else {
	$s .= "CREATE TABLE ${newOwner}.${tname} (\n";
    }
    my $first = 1;

    foreach my $c (@$cols) {
	$s .= ",\n" if (!$first);

	# Column name
	#
	my $cname = $c->{'column_name'};
	$s .= sprintf("    %-35s", $cname);

	# Datatype
	#
	my $type = $c->{'data_type'};
	my $len = $c->{'data_length'};
	my $prec = $c->{'data_precision'};
	my $scale = $c->{'data_scale'};

	if ($prec && $scale) {
	    $s .= sprintf("%-45s", "${type}(${prec}, ${scale})");
	} elsif ($prec && !$scale) {
	    $s .= sprintf("%-45s", "${type}(${prec})");
	} elsif (!$prec && $scale) {
	    die "scale and no precision for $type";
	} elsif ($type =~ /varchar|char/i) {
	    $s .= sprintf("%-45s", "${type}(${len})");
	} else {
	    $s .= sprintf("%-45s", $c->{'data_type'});
	}

	# Column default value
	#
	my $defltLen = $c->{'default_length'};
	my $deflt = $c->{'data_default'};

	if ($deflt =~ /\S/) {
	    $s .= " DEFAULT $deflt ";

	    # DEBUG
	    # not sure what default_length is for
#	    print STDERR "INFO - set default value '$deflt' in ${owner}.${name}.${cname}; defltLen = $defltLen\n";
	}

	# NULLS allowed?
	#
	$s .= ($c->{'nullable'} =~ /n/i) ? ' NOT NULL' : ' NULL';

	$first = 0;
    }

    if ($verTable) {
	$s .= ",\n";
	$s .= "    VERSION_ALG_INVOCATION_ID          NUMBER(12)                                    NULL,\n";
	$s .= "    VERSION_DATE                       DATE                                          NULL,\n";
	$s .= "    VERSION_TRANSACTION_ID             NUMBER(12)                                    NULL\n";
    }

    $s .= ")\n";

    # TABLESPACE and STORAGE modifiers
    #
    $sql = ("select * from all_tables " .
	    "where owner = upper('$owner') " .
	    "and table_name = upper('$name') ");

    my $rows = &GUS::DBAdmin::Util::execQuery($dbh, $sql, 'hash');
    die "FAILED: $sql" if (scalar(@$rows) != 1);
    my $tcols = $rows->[0];

    my $ts = $tcols->{'tablespace_name'};

    if (defined($newTS)) {
	$s .= " TABLESPACE $newTS\n";
    } elsif (defined($ts)) {
	$s .= " TABLESPACE $ts\n";
    }

    my $sClause = '';
    my $initExtent = $tcols->{'initial_extent'};
    my $nextExtent = $tcols->{'next_extent'};
    my $minExtents = $tcols->{'min_extents'};
    my $maxExtents = $tcols->{'max_extents'};
    my $pctIncrease = $tcols->{'pct_increase'};

    # Hack
    #
    $maxExtents = 'UNLIMITED' if ($maxExtents == 2147483645);

    $sClause .= "INITIAL $initExtent " if (($initExtent) && ($initExtent != 65536));  # 65536 appears to be the default
    $sClause .= "NEXT $nextExtent " if ($nextExtent);
    $sClause .= "MINEXTENTS $minExtents " if ($minExtents > 1);
    $sClause .= "MAXEXTENTS $maxExtents " if ($maxExtents);
    $sClause .= "PCTINCREASE $pctIncrease " if ($pctIncrease);

    $s .= " STORAGE (${sClause})" if ($sClause ne '');
    $s .= ";\n";

    return $s;
}

# Get the entire contents of a table
#
sub getContents {
    my($self, $dbh, $orderBy, $returnMode) = @_;

    my $owner = $self->{'owner'};
    my $name = $self->{'name'};

    my $sql = "select * from $owner.$name $orderBy";
    return &GUS::DBAdmin::Util::execQuery($dbh, $sql, defined($returnMode) ? $returnMode : 'array');
}

# Return the SQL required to re-insert all the rows currently in
# the table.
#
sub getContentsSQL {
    my($self, $dbh, $orderBy, $newOwner, $primKeyCol, $resetSequence) = @_;

    my $insertSql = "SET ESCAPE '\\';\n";

    # Find out the database's default DATE_FORMAT; unless we do this it's possible that
    # the target database will be using a different default DATE_FORMAT and will be
    # unable to parse the stringified date values in the output file.
    #
    my $vals = &GUS::DBAdmin::Util::execQuery($dbh, "select value from sys.v\$parameter where name = 'nls_date_format'", 'scalar');
    if (defined($vals) && (scalar(@$vals) > 0)) {
	my $val = $vals->[0];
	if ($val =~ /\S/) {
	    $insertSql .= "ALTER SESSION SET NLS_DATE_FORMAT = '$val';\n";
	}
    }

    my $owner = $self->{'owner'};
    my $name = $self->{'name'};

    my $cols = $self->getColumnList($dbh);
    my $colTypes = [];
    foreach my $col (@$cols) { push(@$colTypes, $self->getColumnDatatype($dbh, $col)); }
    my $ncols = scalar(@$cols);
    my $rows = $self->getContents($dbh, $orderBy, 'array');

    $newOwner = $owner if (!defined($newOwner));
    $newOwner .= "." if ($newOwner =~ /^&&/);
    my $nrows = 0;

    foreach my $row (@$rows) {
	my $colVals = [];

	for (my $cn = 0;$cn < $ncols;++$cn) {
	    my $ct = $colTypes->[$cn];
	    my $cv = $row->[$cn];

	    if ($cn =~ /modification_date/i) {
		push(@$colVals, "SYSDATE");
	    } elsif (!defined($cv)) {
		push(@$colVals, "NULL");
	    } elsif ($ct =~ /varchar|char|date/i) {
		$cv =~ s#&#\\&#g;                     # Escape '&' character
		$cv =~ s#'#''#g;                      # Replace ' with '' in single-quoted strings
		push(@$colVals, "'$cv'");
	    } else {
		push(@$colVals, $cv);
	    }
	}
	$insertSql .= "INSERT INTO $newOwner.$name VALUES(" . join(",", @$colVals). ");\n";
	++$nrows;
    }

    $insertSql .= "\n/* $nrows row(s) */\n\n";

    # Include SQL commands to re-create the table's sequence object at the correct index.
    #
    if ($resetSequence) {
	my $rows = &GUS::DBAdmin::Util::execQuery($dbh, "select max($primKeyCol) from $owner.$name", 'scalar');
	my $newStart = $rows->[0] + 1;

	$insertSql .= "\n";
	$insertSql .= "DROP SEQUENCE ${newOwner}.${name}_SQ;\n";
	$insertSql .= "CREATE SEQUENCE ${newOwner}.${name}_SQ START WITH ${newStart};\n";
	$insertSql .= "\n";
    }

    return $insertSql;
}

# Return a list of the columns in the table in order of appearance
#
sub getColumnList {
    my($self, $dbh) = @_;

    my $owner = $self->{'owner'};
    my $name = $self->{'name'};

    my $colSql = ("select atc.column_name " .
		  "from all_tab_columns atc " .
		  "where atc.owner = upper('$owner') " .
		  "and atc.table_name = upper('$name') " .
		  "order by atc.column_id asc ");
   
    return &GUS::DBAdmin::Util::execQuery($dbh, $colSql, 'scalar');
}

# Return the datatype of a single column
#
sub getColumnDatatype {
    my($self, $dbh, $colName) = @_;

    my $owner = $self->{'owner'};
    my $name = $self->{'name'};

    my $colSql = ("SELECT atc.data_type " .
		  "FROM all_tab_columns atc " .
		  "WHERE atc.owner = upper('$owner') " .
		  "AND atc.table_name = upper('$name') " .
		  "AND atc.column_name = upper('$colName')");

    my $values = &GUS::DBAdmin::Util::execQuery($dbh, $colSql, 'scalar');
    return $values->[0];
}

# Special case; return list of primary key columns, or undef if no primarykey defined
#
sub getPrimaryKeyConstraintCols {
    my($self, $dbh) = @_;
    my $result = undef;

    my $owner = $self->{'owner'};
    my $name = $self->{'name'};

    my $cSql = ("select * " .
		"from all_constraints c " .
		"where c.owner = upper('$owner') " .
		"and c.table_name = upper('$name') " .
		"and c.constraint_type = 'P'");

    my $rows = &GUS::DBAdmin::Util::execQuery($dbh, $cSql, 'hash');

    if (defined($rows)) {
	my $nRows = scalar(@$rows);
	my $row = undef;

	if ($nRows == 1) {
	    $row = $rows->[0];
	} elsif ($nRows > 1) {
	    print STDERR "Table.pm: WARNING - $owner.$name has multiple primary key constraints\n";
	    $row = $rows->[0];
	}

	if (defined($row)) {
	    my $cols = $self->getConstraintCols($dbh, $row->{'owner'}, $row->{'constraint_name'});
	    $result = [];
	    foreach my $c (@$cols) {
		push(@$result, $c->{'column_name'});
	    }
	}
    } 
    return $result;
}

sub getUniqueConstraintColHash {
    my($self, $dbh) = @_;

    my $hash = {};

    my $owner = $self->{'owner'};
    my $name = $self->{'name'};

    my $cSql = ("select * " .
		"from all_constraints c " .
		"where c.owner = upper('$owner') " .
		"and c.table_name = upper('$name') " .
		"and c.constraint_type = 'U'");

    my $rows = &GUS::DBAdmin::Util::execQuery($dbh, $cSql, 'hash');

    foreach my $row (@$rows) {
	my $cols = $self->getConstraintCols($dbh, $row->{'owner'}, $row->{'constraint_name'});
	$hash->{join(',', map { uc($_->{column_name}) } @$cols)} = 1;
    }

    return $hash;
}

sub getConstraintCols {
    my($self, $dbh, $cowner, $cname) = @_;

    my $cSql = ("select * " .
		"from all_cons_columns cc " .
		"where cc.owner = '$cowner' " .
		"and cc.constraint_name = '$cname' ");

    return &GUS::DBAdmin::Util::execQuery($dbh, $cSql, 'hash');
}

sub constraintToSQL {
    my($self, $dbh, $tableName, $row, $renameSystemIds, $cnameHash) = @_;

    my($tOwner, $tName) = ($tableName =~ /^([^\.]+)\.([^\.]+)$/);

    # Hack - add an extra '.' if the schema name begins with && (i.e. is an SQL variable)
    $tOwner =~ s/^(&&\S+)/$1./; 

    my $cowner = $row->{owner};
    my $cname = $row->{constraint_name};
    my $type = $row->{constraint_type};
    my $isgen = ($row->{generated} =~ /generated/i);
	
    # referential integrity
    #
    if ($type eq 'R') {   
	my $rOwner = $row->{r_owner};
	my $rConstraint = $row->{r_constraint_name};
	my $dRule = $row->{delete_rule};
	
#	    print "constraintToSQL: referential constraint $cname from $tableName to $rOwner\n";
#	    print "cowner = $cowner cname = $cname\n";
	
	my $srcCols = $self->getConstraintCols($dbh, $cowner, $cname);
	my $tgtCols = $self->getConstraintCols($dbh, $rOwner, $rConstraint);
	
	my $scols = [];
	foreach my $sc (@$srcCols) {
	    push(@$scols, $sc->{column_name});
	}
	
	my $ttable = undef;
	my $tcols = [];
	foreach my $tc (@$tgtCols) {
	    $ttable = $tc->{table_name};
	    push(@$tcols, $tc->{column_name});
	}
	
	# Rename system-generated referential integrity constraint name
	#
	if ($renameSystemIds && ($cname =~ /^SYS_/)) {
	    $cname = &_generateId($tName, "FK", $cnameHash);
	}

	my $cStr = ("alter table ${tOwner}.${tName} add constraint $cname" .
		    " foreign key (" . join(',', @$scols) . ")" .
		    " references ${rOwner}.${ttable} (" . join(',', @$tcols) . ");");
	
	return("alter table ${tOwner}.${tName} drop constraint $cname;", $cStr);
    }
    
    # check constraint; ignore 'NOT NULL' constraints
    #
    elsif ($type eq 'C') {
	my $searchCond = $row->{search_condition};
	next if ($searchCond =~ /is not null$/i);

	if ($renameSystemIds && ($cname =~ /^SYS_/)) {
	    $cname = &_generateId($tName, "CK", $cnameHash);
	}

	if ($searchCond =~ /\S+ in \(.+\)/) {
#	    print STDERR "getConstraintSql: found check constraint $cname on ${tOwner}.${tName} with text '$searchCond'\n";
	    my $cStr = "alter table ${tOwner}.${tName} add constraint $cname check ($searchCond);";
	    return("alter table ${tOwner}.${tName} drop constraint $cname;", $cStr);
	}

	die "getConstraintSql: check constraint $cname on ${tOwner}.${tName} with text '$searchCond'\n";
    }
    
    # primary key constraint
    #
    elsif ($type eq 'P') {
	my $searchCond = $row->{search_condition};
	my $ccols = $self->getConstraintCols($dbh, $cowner, $cname);
	my $cnames = [];
	foreach my $cc (@$ccols) { push(@$cnames, $cc->{column_name}); }

	if ($renameSystemIds && ($cname =~ /^SYS_/)) {
	    $cname = "PK_$tName";
	}

	my $cStr = ("alter table ${tOwner}.${tName} add constraint $cname" . 
		    " primary key (" . join(',', @$cnames) . ");");
	
	return("alter table ${tOwner}.${tName} drop constraint $cname;", $cStr);
    }

    # unique constraint
    #
    elsif ($type eq 'U') {
        my $searchCond = $row->{search_condition};
        my $ccols = $self->getConstraintCols($dbh, $cowner, $cname);
        my $cnames = [];

        foreach my $cc (@$ccols) { push(@$cnames, $cc->{column_name}); }

        my $cStr = ("alter table ${tOwner}.${tName} add unique " .
                    "(" . join(',', @$cnames) . ");");

        return("alter table ${tOwner}.${tName} drop constraint $cname;", $cStr);
    }

    die "getConstraintSql: unsupported constraint type '$type'";
}

sub getConstraintsSql {
    my($self, $dbh, $newOwner, $renameSystemIds) = @_;
    my($drop1, $create1) = $self->getForeignKeyConstraintsSql($dbh, $newOwner, $renameSystemIds);
    my($drop2, $create2) = $self->getSelfConstraintsSql($dbh, $newOwner, $renameSystemIds);
    push(@$drop1, @$drop2);
    push(@$create1, @$create2);
    return ($drop1, $create1);
}

sub getForeignKeyConstraints {
    my($self, $dbh) = @_;

    my $owner = $self->{'owner'};
    my $name = $self->{'name'};
    my $tn = $self->toString();

    my $sql = ("select ac1.* " .
	       "from all_constraints ac1, all_constraints ac2 " .
	       "where ac1.constraint_type = 'R' " .
	       "and ac1.r_constraint_name = ac2.constraint_name " .
	       "and ac1.r_owner = ac2.owner " .
	       "and ac2.owner = upper('${owner}') " .
	       "and ac2.table_name = upper('${name}') ");

    return &GUS::DBAdmin::Util::execQuery($dbh, $sql, 'hash');
}

# Get constraints that reference this table as a foreign key.
#
sub getForeignKeyConstraintsSql {
    my($self, $dbh, $newOwner, $renameSystemIds) = @_;
    my $name = $self->{name};

    my $createSql = [];
    my $dropSql = [];

    my $constraints = $self->getForeignKeyConstraints($dbh);
    my $chash = {};

    foreach my $c (@$constraints) {
	my $tn = $c->{'table_name'};
	my $cn = $c->{'constraint_name'};
	$chash->{$cn} = 1 if ($tn eq $name);
    }

    foreach my $c (@$constraints) {

	# HACK - this ONLY works in the single-schema case (i.e. no foreign key constraints from outside)
	
	my $tn = $c->{table_name};
	my $to = $c->{owner};

#	$newOwner = $self->{owner} if (!defined($newOwner));
#	$tn = $newOwner . "." . $tn;

	my ($drop,$create) = $self->constraintToSQL($dbh, "${to}.${tn}", $c, $renameSystemIds, $chash);
	push(@$dropSql, $drop);
	push(@$createSql, $create);
    }
    return ($dropSql, $createSql);
}

sub getSelfConstraints {
    my($self, $dbh) = @_;

    my $owner = $self->{'owner'};
    my $name = $self->{'name'};

    my $cSql = ("select * " .
		"from all_constraints c " .
		"where c.owner = upper('$owner') " .
		"and c.table_name = upper('$name') ");

   return &GUS::DBAdmin::Util::execQuery($dbh, $cSql, 'hash');
}

sub getSelfConstraintsSql {
    my($self, $dbh, $newOwner, $renameSystemIds) = @_;
    my $name = $self->{name};

    my $tn = $self->toString();
    my $owner = $self->{owner};
    $tn =~ s/$owner\./$newOwner./ if (defined($newOwner));

    my $createSql = [];
    my $dropSql = [];

    my $constraints = $self->getSelfConstraints($dbh);

    my $chash = {};
    foreach my $c (@$constraints) {
	my $tn = $c->{'table_name'};
	my $cn = $c->{'constraint_name'};
	$chash->{$cn} = 1 if ($tn eq $name);
    }

    foreach my $c (@$constraints) {
	my ($drop,$create) = $self->constraintToSQL($dbh, $tn, $c, $renameSystemIds, $chash);
	push(@$dropSql, $drop);
	push(@$createSql, $create);
    }
    return ($dropSql, $createSql);
}

sub getIndexColumns {
    my($self, $dbh, $owner, $name) = @_;

    my $sql = ("select aic.* " .
	       "from all_ind_columns aic " .
	       "where aic.index_owner = upper('${owner}') " .
	       "and aic.index_name = upper('${name}') " . 
	       "order by aic.column_position asc ");

    return &GUS::DBAdmin::Util::execQuery($dbh, $sql, 'hash');
}

sub indexToSQL {
    my($self, $dbh, $tableName, $row, $onTable, $renameSysIds, $newOwner, $newTS, $primKeyColHash) = @_;
    my $colsMatch = 0;

    my $type = $row->{index_type};
    my $owner = $row->{owner};
    my $name = $row->{index_name};
    my $unique = $row->{uniqueness} =~ /^unique$/i;
    my $tspace = $row->{tablespace_name};

    $newOwner = $owner if (!defined($newOwner));
    $newTS = $tspace if (!defined($newTS));

    my $cols = $self->getIndexColumns($dbh, $owner, $name);
    my @cnames = map {$_->{column_name}} @$cols;

    # Use a hash table to ignore order.
    #
    if (defined($primKeyColHash)) {
	my @keys = keys %$primKeyColHash;
	my $npk = scalar(@keys);
	my $nc = scalar(@cnames);

	if ($npk == $nc) {
	    $colsMatch = 1;
	    for(my $i = 0;$i < $npk;++$i) {
		if (!defined($primKeyColHash->{$cnames[$i]})) {
		    $colsMatch = 0;
		    last;
		}
	    }
	}
    }

    # Detect and parse functional indexes
    #
    my $indexFn = undef;
    if ((scalar(@cnames) == 1) && ($cnames[0] =~ /^SYS_/i)) {
	my $cname = $cnames[0];
#	print STDERR "Table.pm: detected system-named index $cname\n";
	my $vals = GUS::DBAdmin::Util::execQuery($dbh, "select data_default from all_tab_cols where column_name = '$cname'", 'scalar');
	if (defined($vals) && (scalar(@$vals) == 1)) {
	    $indexFn = $vals->[0];
	} else {
	    print STDERR "Table.pm: WARNING - query against all_tab_cols for $cname returned ", scalar(@$vals), " row(s)\n";
	}
    }

    my $create = "create ";
    $create .= "unique " if ($unique);
    $create .= "bitmap " if ($type =~ /bitmap/i);

    if ($newOwner =~ /^&&/) {
	$create .= "index ${newOwner}..${name} on ";
    } else {
	$create .= "index ${newOwner}.${name} on ";
    }

    $onTable = $tableName if (!defined($onTable));
    $onTable =~ s/^(&&\S+)\.(\S+)$/$1..$2/;
    $create .= $onTable;

    if (defined($indexFn)) {
	$create .= " (" . $indexFn . ") ";
    } else {
	$create .= " (" . join(',', @cnames) . ") ";
    }
    $create .= " TABLESPACE $newTS" if (defined($newTS));
    $create .=";";

    return ("drop index ${owner}.${name};", $create, ($unique && $colsMatch), $cols);
}

sub getIndexes {
    my($self, $dbh, $onTable) = @_;

    my $createSql = [];
    my $dropSql = [];

    my $owner = $self->{'owner'};
    my $name = $self->{'name'};

    my $sql = ("select i.* " .
		"from all_indexes i " .
		"where i.table_owner = upper('$owner') " .
		"and i.table_name = upper('$name') ");

    return &GUS::DBAdmin::Util::execQuery($dbh, $sql, 'hash');
}

# $includePrimKeyIndex       Whether to include the system-generated index that corresponds to 
#                            the table's primary key constraint.
# $includeUniqueConsIndexes  Whether to include the system-generated indexes that correspond to
#                            the table's unique constraints.
#
sub getIndexesSql {
    my($self, $dbh, $onTable, $renameSysIds, $newOwner, $newTS, $includePrimKeyIndex, $includeUniqueConsIndexes) = @_;

    my $createSql = [];
    my $dropSql = [];

    my $tn = $self->toString();
    my $indexes = $self->getIndexes($dbh);

    my $keyCols = $self->getPrimaryKeyConstraintCols($dbh);
    my $keyColHash = {};
    foreach my $k (@$keyCols) { $keyColHash->{$k} = 1; }

    my $uniqueCols = $self->getUniqueConstraintColHash($dbh);

    foreach my $row (@$indexes) {
	my($d, $c, $isPrimKeyIndex, $indexCols) = $self->indexToSQL($dbh, $tn, $row, $onTable, $renameSysIds, $newOwner, $newTS, $keyColHash);
	my $isUniqueConsIndex = $uniqueCols->{join(',', map {uc($_->{column_name})} @$indexCols)};

	my $include = 1;
	if ($isPrimKeyIndex && !$includePrimKeyIndex) { $include = 0; }
	if ($isUniqueConsIndex && !$includeUniqueConsIndexes) { $include = 0; }

	if ($include) {
	    push(@$dropSql, $d);
	    push(@$createSql, $c);
	}
    }

    return ($dropSql, $createSql);
}

sub getUnusableIndexes {
    my($self, $dbh) = @_;

    my $tn = $self->toString();
    my $owner = $self->{'owner'};
    my $name = $self->{'name'};

    my $sql = ("select i.* " .
	       "from all_indexes i " .
	       "where i.table_owner = upper('$owner') " .
	       "and i.table_name = upper('$name') " .
	       "and i.status = 'UNUSABLE' ");

    return &GUS::DBAdmin::Util::execQuery($dbh, $sql, 'hash');
}

# Return a list of the columns in the table in order of appearance
#
sub getColumnHash {
    my($self, $dbh) = @_;
    my $list = $self->getColumnList($dbh);
    my $hash = {};
    map {$hash->{$_} = 1;} @$list;
    return $hash;
}

# Lock the table in the specified mode.  Returns 1 iff the 
# operation succeeded.
#
# $mode    one of 'row share', 'row exclusive', 'share update', 'share', 
#          'share row exclusive', or 'exclusive'
# $nowait  whether to include the NOWAIT option
#
# TO DO - support locking of (sub)partitions
#
sub lock {
    my($self, $dbh, $mode, $nowait) = @_;
    my $table = $self->toString();

    my $lockSql = "lock table $table in $mode mode ";
    $lockSql .= "nowait" if ($nowait);
    my $nRows = $dbh->do($lockSql);

#    print STDERR "$table: $lockSql returned $nRows\n";

    return $nRows;
}

# Copy all the rows in this table to another one.  Each column in the target
# table will be populated using the column of the same name in the source
# table.  If no corresponding column exists in the source table then the 
# target column must be nullable.
#
sub copyTo {
    my($self, $dbh, $table, $noExecute) = @_;

    my $srcCols = $self->getColumnHash($dbh);
    my $targetCols = $table->getColumnList($dbh);

    my $ts = $table->toString();
    my $ss = $self->toString();

    print STDERR "copyTo: copying $ss -> $ts\n";

    # Figure out which target columns we can populate from the source table.
    #
    my $popCols = [];
    foreach my $tcol(@$targetCols) {
	if (defined($srcCols->{$tcol})) {
	    push(@$popCols, $tcol);
	}
    }

    my $copySql = "insert into $ts (" . join(',', @$popCols) . ") ";

    # Any LONG columns being copied to CLOB columns have to be 
    # enclosed in a 'TO_LOB'
    #
    $copySql .= "select ";

    my $npc = scalar(@$popCols);

    for (my $cnum = 0;$cnum < $npc;++$cnum) {
	$copySql .= "," if ($cnum > 0);

	my $tgtCol = $popCols->[$cnum];
	my $srcType = $self->getColumnDatatype($dbh, $tgtCol);
	my $tgtType = $table->getColumnDatatype($dbh, $tgtCol);

	if (($srcType =~ /^long$/i) && ($tgtType =~ /lob$/i)) {
	    $copySql .= "TO_LOB(" . $popCols->[$cnum] . ")";
	} else {
	    $copySql .= $popCols->[$cnum];
	}
    }

    $copySql .= " from $ss ";

    my $nSrc = scalar(@$popCols) - scalar(keys %$srcCols);
    my $nTgt = scalar(@$targetCols) - scalar(@$popCols);

    print "copyTo: $nSrc columns not being copied from $ss\n";
    print "copyTo: $nTgt columns not being populated in $ts\n";

    print "Table: copySql = '$copySql'\n";
    my $numRows = $dbh->do($copySql) if (!$noExecute);

    print "copyTo: copied $numRows rows from $ss -> $ts\n";
    return $numRows;
}

# -----------------------------------------------------------------------
# File-scoped methods
# -----------------------------------------------------------------------

# Generate an ID that doesn't clash with any of those in $cnameHash.
#
sub _generateId {
    my($tableName, $suffix, $cnameHash) = @_;

    my $name = undef;
    my $i = 1;

    while ($i < 100) {
	my $num = sprintf("%2.2d", $i);
	$tableName = substr($tableName, 0, 25);     # assumes $suffix is at most 2 chars
	$name = "${tableName}_${suffix}${num}";
	last if (!defined($cnameHash->{$name}));
	++$i;
    }

    # Add the new name to the list!
    #
    $cnameHash->{$name} = 1;
    return $name;
}

1;

package GUS::ObjRelP::Generator::TableGenerator;

use strict;

sub new {
  my ($class, $generator, $schemaName, $tableName) = @_;

  my $self = {};
  bless $self, $class;

  $self->{generator} = $generator;
  $self->{schemaName} = $schemaName;
  $self->{tableName} = $tableName;
  $self->{fullName} = "GUS::Model::${schemaName}::$tableName";

  $self->{realTable} =
    $generator->getTable($self->{generator}->getRealTableName($self->{fullName},1));
  $self->{table} = $generator->getTable($self->{fullName}, 1);

  return $self;
}

##############################################################################
####################  Generating methods #####################################
##############################################################################

sub generate {
  my($self, $newOnly) = @_;

  my $dir = $self->{generator}->{targetDir};

  my $file = "$dir/$self->{schemaName}/$self->{tableName}Table.pm";

  return if ($newOnly && -e $file);

  open(F,">$file") || die "Can't open table file $file for writing";
  print F $self->_genHeader() . $self->_genDefaultParams() . "1;\n\n";
  close(F);
}

sub _genHeader {
  my($self) = @_;

  return
"package $self->{fullName}Table;

use strict;
use GUS::ObjRelP::DbiTable;
use vars qw (\@ISA);
\@ISA = qw (DbiTable);

";
}

sub _genDefaultParams {
  my($self) = @_;
  my $s = 
'sub setDefaultParams {
  my $self = shift;
';
  $s .= $self->_genChildAndParentLists($self->{table}->getClassName());
  $s .= $self->_genAttributeInfo($self->{table});
  $s .= '  $self->setRealTableName(\''.$self->{table}->getRealTableName()."');\n\n";
  $s .= '  $self->setIsView('.$self->{table}->isView().");\n\n";
  $s .= '  $self->setParentRelations('.$self->_genParentRelationsData().");\n\n";
  $s .= '  $self->setChildRelations('.$self->_genChildRelationsData().");\n\n";
  $s .= '  $self->setHasSequence('.($self->{table}->hasSequence() ? 1 : 0).");\n\n";
  $s .= '  $self->setHasPKSequence('.($self->{table}->hasPKSequence() ? 1 : 0).");\n\n";
  my $pkeys = $self->{table}->getPrimaryKeyAttributes();
  $s .= '  $self->setPrimaryKeyList(\''.join("','",@{$pkeys})."');\n\n" if $pkeys;
  $s .= '  $self->setTableId('.$self->{table}->getTableId().");\n\n";
  $s .= "}\n\n";
  return $s;
}

sub _genChildAndParentLists {
  my($self) = @_;

  my $kidList = $self->_genRelativeList($self->_getChildren());
  my $parentList = $self->_genRelativeList($self->_getParents());

  my $temp = '  $self->setChildList(' . "$kidList);\n\n";
  $temp .= '  $self->setParentList(' . "$parentList);\n\n";

  return $temp;
}

sub _genRelativeList {
  my ($self, $relatives) = @_;

  my @r;
  foreach my $rel (@$relatives) {
    my $s = join("','", @{$rel});
    push(@r, "['$s']");
  }
  return join(",", @r);
}

# method: createSpecialRels
# arg 1: table name
# outputs special relationships by reading from special cases file if there is one.
# output: string that is created.
sub _genSpecialRelatives {
  my( $self) = @_;

  my $temp;

  my $spec_cases = $self->{generator}->getSpecialCases();

  foreach my $rel ( @{$spec_cases->{rels}} ) {
    my @data = @{$rel};
    if ( $self->{fullName} eq $data[0] ) {
      $temp .= "  \$self->addToParentList\([\'$data[1]\'\,\'$data[2]\',\'$data[3]\']\);\n";
    }
    if ( $self->{fullName} eq $data[1] ) {
      $temp .= "  \$self->addToChildList\([\'$data[0]\'\,\'$data[3]\',\'$data[2]\']\);\n";
    }
  }
  foreach my $rel255 ( @{$spec_cases->{255}} ) {
    my @data = @{$rel255};
    if ( $self->{fullName} eq $data[0] ) {
      $temp .= "  \$self->set255ChildList\([\'$data[1]\'\,\'$data[2]\',\'$data[3]\',\'$data[4]\']\);\n";
    }
  }
  return $temp;
}

sub _genAttributeInfo {
  my($self,$tbl) = @_;

  $self->{table}->cacheAttributeInfo() unless $self->{table}->{attributeNames};

  my $atn = $self->{table}->{attributeNames};
  my $s = "  \$self->setAttributeNames('".join("','",@{$atn})."');\n\n" if $atn;
  my $qat = $self->{table}->{quotedAtts};
  $s .= "  \$self->setQuotedAtts('".join("','",keys%{$qat})."');\n\n" if $qat;

  my @attInfo;
  my $info = $self->{table}->{attInfo};
  foreach my $h (@{$info}){
    my $type = defined $h->{type} ? $h->{type} : "";
    my $prec = defined $h->{prec} ? $h->{prec} : "''";
    my $length = defined $h->{length} ? $h->{length} : "''";
    my $nulls = defined $h->{Nulls} ? $h->{Nulls} : "''";
    my $base_type = defined $h->{base_type} ? $h->{base_type} : "";

    push(@attInfo,"\{'col' => '$h->{col}', 'type' => '$type', 'prec' => $prec, 'length' => $length, 'Nulls' => $nulls, 'base_type' => '$base_type'\}");
  }

  my $attInfo = join(', ', @attInfo);
  $s .= "  \$self->setAttInfo($attInfo);\n\n";
  return $s;
}

sub _genChildRelationsData {
  my($self) = @_;
  my @rels;
  my $children = $self->{table}->getChildRelations();
  foreach my $r (@{$children}){
    push(@rels,"['".join("','",@{$r})."']");
  }
  return join(', ',@rels);
}

sub _genParentRelationsData {
  my($self) = @_;
  my @rels;
  my $parents = $self->{table}->getParentRelations();
  foreach my $r (@{$parents}){
    push(@rels,"['".join("','",@{$r})."']");
  }
  return join(', ',@rels);
}


##############################################################################
######################## Private utility methods #############################
##############################################################################

sub _getParents {
  my($self) = @_;

  if (!exists $self->{parents}) {
    $self->{parents} =
      $self->_getRelations($self->{realTable}->getParentRelations());
  }
  return $self->{parents};
}

sub _getChildren {
  my($self) = @_;

  if (!exists $self->{children}) {
    $self->{children} =
      $self->_getRelations($self->{realTable}->getChildRelations());
  }
  return $self->{children};
}

sub _getRelations {
  my ($self, $relations) = @_;

  my @list;
  foreach my $rel (@{$relations}) {
    my ($tn, $fk, $pk) = ($rel->[0], $rel->[1], $rel->[2]);
    print STDERR "rels: $tn\n";
    next if($tn =~ /dropme/i || $tn =~ /tmp$/i);

    if ($tn =~ /Imp$/) {
      foreach my $subclass ($self->{generator}->getSubclasses($tn)) {
	push(@list, [$subclass,$fk,$pk])
	  if $self->{generator}->isValidAttribute($subclass, $pk)
	    && $self->{generator}->isValidAttribute($self->{fullName}, $fk);
      }
    }

    ##put all on the list even if Imp
    push(@list, [$tn,$fk,$pk])
      if $self->{generator}->isValidAttribute($tn, $pk)
	&& $self->{generator}->isValidAttribute($self->{fullName}, $fk);
  }

  return \@list;
}

1;

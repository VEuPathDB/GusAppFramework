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
    
    my $realTableName = $self->{generator}->getRealTableName($self->{fullName});
    $self->{realTable} = $generator->getTable($realTableName ,1);
    $self->{table} = $generator->getTable($self->{fullName}, 1);
    
    return $self;
}


##############################################################################
######################## Private utility methods #############################
##############################################################################
#input: fqName is string in form of GUS::Model::Schema::Name
#returns (Schema, Name)
sub _cutFullQualifiedName{
    my ($self, $fqName) = @_;   
    
    if($fqName =~ /^\w+::\w+::(\w+)::(\w+)/){
	return ($1, $2);
    }
    else {
	die "Error: Fully Qualified Name not in form of GUS::Model::Schema::Owner";
    }
}

sub _getParents {
  my($self) = @_;

  if (!exists $self->{parents}) {
    $self->{parents} =
      $self->_getRelations($self->{realTable}->getParentRelations());
  }
#  print STDERR "Parents for $self->{tableName}\n";
#  foreach my $p (@{$self->{parents}}){
#    print STDERR "  ".join(", ",@$p)."\n";
#  }
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


sub _getParentTable {
    my ($self) = @_;
    return $self->{generator}->getParentTable($self->{fullName});
}

sub _getRelations {
  my ($self, $relations) = @_;

  my @list;
  foreach my $rel (@{$relations}) {
    my ($tn, $fk, $pk) = ($rel->[0], $rel->[1], $rel->[2]);

    next if($tn =~ /dropme/i || $tn =~ /tmp$/i);

    if ($tn =~ /Imp$/) {
      foreach my $subclass ($self->{generator}->getSubclasses($tn)) {
#        print STDERR "Adding relations for subclass $subclass .. ";
        if ($self->{generator}->isValidAttribute($subclass, $pk)
	    && $self->{generator}->isValidAttribute($self->{fullName}, $fk)){
          push(@list, [$subclass,$fk,$pk]);
#          print STDERR "columns present [$subclass,$fk,$pk]\n";
        }else{
#          print STDERR "COLUMNS ABSENT [$subclass,$fk,$pk] so not adding\n";
        } 
      }
    }

    ##put all on the list even if Imp
    push(@list, [$tn,$fk,$pk])
      if $self->{generator}->isValidAttribute($tn, $pk)
	&& $self->{generator}->isValidAttribute($self->{fullName}, $fk);
  }

  return \@list;
}
#gets attributes unique to a subclass (ignores views)
sub _getUniqueAttributes {
    my($self) = @_;
    
    my $extent_object = $self->{generator}->getTable($self->{fullName}, 1);
    my $parent = $self->_getParentTable();
    my $att_list = $extent_object->getAttributeList();
    
    return undef unless $att_list;
    
    if ( ! $parent ) {            ##doesn't have a parent...
	return @$att_list;
    } else {
	my $parent_table_object = $self->{generator}->getTable($parent,1);
	my %parentAtt;
	my $att;
	my @final_att_list;
	
	my $parent_att_list = $parent_table_object->getAttributeList();
	
	## Generate a final list of attributes unique to the child table.
	foreach my $parent_att ( @$parent_att_list ) {
	    $parentAtt{$parent_att} = 1;
	}
	foreach $att ( @$att_list ) {
	    if ( !exists($parentAtt{$att}) ) {
		push(@final_att_list,$att);
	    }
	}
	return @final_att_list;
    }
}
1;

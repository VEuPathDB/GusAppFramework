package GUS::ObjRelP::Generator::RowGenerator;

use strict;

sub new {
  my ($class, $generator, $schemaName, $tableName, $tableGenerator) = @_;

  my $self = {};
  bless $self, $class;

  $self->{generator} = $generator;
  $self->{schemaName} = $schemaName;
  $self->{tableName} = $tableName;
  $self->{tableGenerator} = $tableGenerator;
  $self->{fullName} = "${schemaName}::$tableName";

  return $self;
}


##############################################################################
######################## Utility methods #####################################
##############################################################################

sub _getParentTable {
    my ($self) = @_;
    return $self->{generator}->getParentTable($self->{fullName});
}

sub _getVersionable {
    my ($self) = @_;
    
    return $self->{generator}->getVersionable($self->{fullName});
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

#input: fqName is string in form of GUS::Model::Schema::Name
#returns (Schema, Name)
sub _cutFullQualifiedName{
    my ($self, $fqName) = @_;   
    
    if($fqName =~ /^\w+::\w+::(\w+)::(\w+)/){
	return ($1, $2);
    }
    else {
	die "Error: Fully Qualified Name '$fqName' not in form of GUS::Model::Schema::Owner";
    }
}
#input: $packageTableName is string in form of \S+.model.Schema.Name
#returns (Schema, name)
sub _cutPackageTableName{
    my ($self, $packageTableName) = @_;

    if ($packageTableName =~ /org.gusdb.model.(\w+).(\w+)/){
	return ($1, $2);
    }
    else {
	die "Error:  Package Table Name '$packageTableName' is not in the form of org.gusdb.model.SCHEMA.NAME";
    }
}


#parentAndChildAttributes - takes in a table name, true table boolean, and extentobject 
#of the table and outputs the list of attributes in both the parent and the child so the
#child knows what attributes it shares with its parents.
#getInheritedAttributes
sub _parentAndChildAttributes{
    my ($self) = @_;
    my $extent_object = $self->{generator}->getTable($self->{fullName}, 1);
    my $fullParentTable = $self->_getParentTable( $self->{fullName} );
    my $att_list = $extent_object->getAttributeList();
    my $empty_att_list;
    
    return undef unless $att_list;
    #	if ( $self->isTrueTable($table_name) ) {
    if ( ! $fullParentTable ) {            ##doesn't have a parent...
	return undef;
    } else {
	my ($parentSchema, $parentName) = $self->_cutFullQualifiedName($fullParentTable);
	my $parent = $parentSchema . "::" . $parentName;
	
	my $parent_table_object = $self->{generator}->getTable($parent,1);
	my %parentAtt;
	my %childAtt;
	my $att;
	my @final_att_list;
	
	my $parent_att_list = $parent_table_object->getAttributeList();
	
	foreach my $parent_att ( @$parent_att_list ) {

	    $parentAtt{$parent_att} = 1;
	}
	
	foreach $att ( @$att_list ) {
	    if ( exists($parentAtt{$att}) ) {
		
		push(@final_att_list,$att);
	    }
	    
	}
	return @final_att_list;
    }
}

# output: java-like method name.
sub _capAttName {
    my($self,$att) = @_;
    $att =~ tr/A-Z/a-z/;
    my@letts = split(//,$att);
    my$i;
    my$ret;
    $letts[0] =~ tr/[a-z]/[A-Z]/;
    $ret = $letts[0];
    for ($i=1;$i<scalar(@letts);$i++) {
	if ($letts[$i] eq "_") {
	    $letts[$i+1] =~ tr/[a-z]/[A-Z]/;
	} else {
	    $ret .= $letts[$i];
	}
    }
    return $ret;
}

1;

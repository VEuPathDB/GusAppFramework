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
####################  Generating methods #####################################
##############################################################################

sub generate {
  my($self, $newOnly) = @_;

  my $dir = $self->{generator}->{targetDir};

  my $file = "$dir/$self->{schemaName}/$self->{tableName}_Row.pm";

  return if ($newOnly && -e $file);

  open(F,">$file") || die "Can't open file $file for writing";
  print F $self->_genHeader() . $self->_genSetDefaultParams() .
    $self->_genAccessors() . "1;\n";
  close(F);
}

sub _genHeader {
  my ($self) = @_;

  my $temp =
"package GUS::Model::$self->{fullName}_Row;

use strict;
";
  if ($self->_getParentTable()) {
    $temp .= "use GUS::Model::".$self->_getParentTable().";\n";
  } else {
    $temp .= "use GUS::Model::GusRow;\n";
  }

  $temp .= $self->_genISA();

  return $temp;
}

sub _genISA {
  my ( $self ) = @_;

  my $parent = $self->_getParentTable();
  my $isa = '@ISA = qw (GUS::ObjRelP::RelationalRow);';
  $isa = "\@ISA = qw ($parent);" if $parent;
  return "
use vars qw (\@ISA);
$isa

";
}

sub _genSetDefaultParams {
  my( $self) = @_;
  my $temp;

  $temp .= 
'sub setDefaultParams {
  my ($self) = @_;
  $self->setVersionable(';

  $temp .= $self->_getVersionable();

  $temp .= ');
  $self->setUpdateable(1);
}

';

  return $temp;
}

sub _genAccessors {
  my ($self) = @_;

  my $temp;

  foreach my $att ($self->_getUniqueAttributes()) {

    my $sub_name = $self->_capAttName( $att );
    my $set = "set$sub_name";
    my $get = "get$sub_name";

    ##don't create methods if base classes have them...
    my $dontOverride = $self->{generator}->getDontOverride();
    next if ($dontOverride->{$set} || $dontOverride->{$get});

    ## print the set and gets with some pod commenting.
    $temp .= "sub $set {
  my(\$self,\$value) = \@_;
  \$self->set(\"$att\",\$value);
}

sub $get {
  my(\$self) = \@_;
  return \$self->get(\"$att\");
}\n\n";
  }

  return $temp;
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

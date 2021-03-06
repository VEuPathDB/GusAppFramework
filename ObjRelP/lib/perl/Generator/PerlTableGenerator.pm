package GUS::ObjRelP::Generator::PerlTableGenerator;

@ISA = qw (GUS::ObjRelP::Generator::TableGenerator);

use strict;
use GUS::ObjRelP::Generator::TableGenerator;

sub new{
    my ($class, $generator, $schemaName, $tableName, $tableGenerator) = @_;
    
    my $self=GUS::ObjRelP::Generator::TableGenerator->new($generator, $schemaName, $tableName, $tableGenerator);
    bless $self, $class;
    return $self;
}

sub generate {
    my($self, $newOnly) = @_;
    
    my $dir = $self->{generator}->{targetDir};
    
    my $file = "$dir/$self->{schemaName}/$self->{tableName}_Table.pm";
    
    return if ($newOnly && -e $file);
    
    open(F,">$file") || die "Can't open table file $file for writing";
    print F $self->_genHeader() . $self->_genDefaultParams() . "1;\n\n";
    close(F);
}

sub _genHeader {
    my($self) = @_;
    
    return
	"package $self->{fullName}_Table;

# THIS CLASS HAS BEEN AUTOMATICALLY GENERATED BY THE GUS::ObjRelP::Generator 
# PACKAGE.
#
# DO NOT EDIT!!


use strict;
use GUS::ObjRelP::DbiTable;
use vars qw (\@ISA);
\@ISA = qw (GUS::ObjRelP::DbiTable);

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
    $s .= $self->_genSpecialRelatives();
    $s .= '  $self->setHasSequence('.($self->{table}->hasSequence() ? 1 : 0).");\n\n";
    my $pkeys = $self->{table}->getPrimaryKeyAttributes();
    $s .= '  $self->setPrimaryKeyList(\''.join("','",@{$pkeys})."');\n\n" if $pkeys;
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
	push(@r, "\n      ['$s']");
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
    my $s = "  \$self->setAttributeNames(\n      '".join("',\n      '",@{$atn})."');\n\n" if $atn;
    my $qat = $self->{table}->{quotedAtts};
    $s .= "  \$self->setQuotedAtts(\n      '".join("',\n      '",keys%{$qat})."');\n\n" if $qat;
    
    my @attInfo;
    my $info = $self->{table}->{attInfo};
    foreach my $h (@{$info}){
	my $type = defined $h->{type} ? $h->{type} : "";
	my $prec = defined $h->{prec} ? $h->{prec} : "''";
	my $length = defined $h->{length} ? $h->{length} : "''";
	my $nulls = defined $h->{Nulls} ? $h->{Nulls} : "''";
	my $base_type = defined $h->{base_type} ? $h->{base_type} : "";
	
	push(@attInfo,"\n      \{'col' => '$h->{col}', 'type' => '$type', 'prec' => $prec, 'length' => $length, 'Nulls' => $nulls, 'base_type' => '$base_type'\}");
    }
    
    my $attInfo = join(', ', @attInfo);
    $s .= "  \$self->setAttInfo($attInfo);\n\n";
    return $s;
}

sub _genChildRelationsData {
  my($self) = @_;
#  return $self->_genRelativeList($self->_getChildren());
  my @rels;
  my $children = $self->{table}->getChildRelations();
  foreach my $r (@{$children}){
      push(@rels,"\n      ['".join("','",@{$r})."']");
  }
  return join(', ',@rels);
}

sub _genParentRelationsData {
  my($self) = @_;
#  return $self->_genRelativeList($self->_getParents());
  my @rels;
  my $parents = $self->{realTable}->getParentRelations();
  foreach my $r (@{$parents}){
    push(@rels,"\n      ['".join("','",@{$r})."']");
  }
  return join(', ',@rels);
}

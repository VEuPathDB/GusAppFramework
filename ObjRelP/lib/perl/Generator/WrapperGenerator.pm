package GUS::ObjRelP::Generator::WrapperGenerator;

use strict;

sub new {
  my ($class, $generator, $schemaName, $tableName) = @_;

  my $self = {};
  bless $self, $class;

  $self->{generator} = $generator;
  $self->{schemaName} = $schemaName;
  $self->{tableName} = $tableName;
  $self->{fullName} = "${schemaName}::$tableName";

  return $self;
}

sub generate {
  my($self, $newOnly) = @_;

  my $dir = $self->{generator}->{targetDir};

  my $file = "$dir/$self->{schemaName}/$self->{tableName}.pm";

  return if ($newOnly && -e $file);

  if (-e "$file.man") {
    system("cp $file.man $file") == 0 || die "Couldn't cp $file.man $file";
  } else {
    open(F,">$file") || die "Can't open file $file for writing";
    print F $self->_genHeader() . "1;\n\n";
    close(F);
    }
}

sub _genHeader {
  my ( $self ) = @_;

  my $rowclass = "GUS::Model::$self->{fullName}_Row";

  my $temp .= "
package GUS::Model::$self->{fullName};

use strict;
use $rowclass;



use vars qw \(\@ISA\);
\@ISA = qw \($rowclass\);


";
  return $temp;
}

1;

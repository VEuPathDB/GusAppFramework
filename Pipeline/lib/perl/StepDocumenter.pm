package GUS::Pipeline::StepDocumenter;

use strict;

use lib "$ENV{GUS_HOME}/lib/perl";

# Document a pipeline step

=pod
This is what is supported
  { name => "Find transmembranes for P.f",
    input => "protein sequences",
    output => "transmembrane domains",
    descrip => "this is the big description",
    tools => [
       { name => "tmhmm",
         version => "1.0.0",
         params => "-m -short -whatever",
         url => "an URL if appropriate",
         pubmedIds => "12345, 222333",
         credits => "Joe Schmoe, Univ. Penn; josette Schmoe, UCSC"
       },
      ]
    };
=cut

sub new {
  my ($class, $signal, $documentationInfo) = @_;

  my $self = $documentationInfo;
  bless($self,$class);

  $self->{signal} = $signal;

  $self->validateInfo();

  return $self;
}

sub validateInfo {
  my ($self) = @_;

  my %validKeys = (name=>1, input=>1, output=>1, descrip=>1, tools=>1);
  foreach my $key (keys(%$self)) {
    next if $key eq 'signal';
    $self->error("'$key' is not a supported documentation field")
      unless $validKeys{$key};
  }

  foreach my $key (keys(%validKeys)) {
    $self->error("'$key' is a required documentation field")
      unless $self->{$key};
  }

  $self->error("'tools' must be a ref to a (possibly empty) array of tools")
    unless ref($self->{tools}) eq "ARRAY";

  my %validToolsKeys =
    (name=>1, version=>1, params=>1, url=>1, pubmedIds=>1, credits=>1);

  my @tools = @{$self->{tools}};

  foreach my $tool (@tools) {

    $self->error("each tool must be a hash reference: '$tool'")
      unless ref($tool) eq "HASH";

    foreach my $key (keys(%$tool)) {
      $self->error("'$key' is not a supported documentation field for a tool")
	unless $validToolsKeys{$key};
    }

    foreach my $key (keys(%validToolsKeys)) {
      $self->error("'$key' is a required documentation field for a tool")
	unless defined($tool->{$key});
    }

#  $self->error("in tool '$tool->{name}', tool->{pubmedIds} must be a ref to a (possibly empty) array of pubmed ids")
 #   unless ref($tool->{pubmedIds}) eq "ARRAY";

#  $self->error("in tool '$tool->{name}', tool->{credits} must be a ref to a (possibly empty) array of credits")
#    unless ref($tool->{credits}) eq "ARRAY";

  }
}

sub printXml {
  my ($self) = @_;

  my $xml = <<XML;
  <record>
    <attribute name="name">$self->{name}</attribute>
    <attribute name="input">$self->{input}</attribute>
    <attribute name="output">$self->{output}</attribute>
    <attribute name="descrip">$self->{descrip}</attribute>
XML

  my @tools = @{$self->{tools}};

  if (scalar(@tools)) {
    $xml .= "    <table name=\"tools\">\n";
    foreach my $tool (@tools) {
      $xml .= <<TABLE;
      <row>
        <column name="name">$tool->{name}</column>
        <column name="version">$tool->{version}</column>
        <column name="params">$tool->{params}</column>
        <column name="url">$tool->{url}</column>
        <column name="pubmedIds">$tool->{pubmedIds}</column>
        <column name="credits">$tool->{credits}</column>
      </row>
TABLE
    }
    $xml .= "    </table>\n";
  }
  $xml .= "  </record>\n\n";
  print $xml;
}

sub error {
  my ($self, $msg) = @_;

  print STDERR "Error documenting step '$self->{signal}': \n$msg\n";
  exit(1);
}

############ static methods  #########################3
sub start {
  print "<xmlAnswer>\n";
}

sub end {
  print "</xmlAnswer>\n";
}

1;

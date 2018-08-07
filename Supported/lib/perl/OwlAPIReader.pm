package GUS::Supported::OwlAPIReader;

sub new {
	my($class, $file) = @_;
	my $self = {};
	bless($self,$class);
	$self->{file} = $file;
	$self->init();
	return $self;
}

sub init {
	my($self) = @_;
	my $file = $self->{file};
   # build classpath
  opendir(D, "$ENV{GUS_HOME}/lib/java") || $self->error("Can't open $ENV{GUS_HOME}/lib/java to find .jar files");
  my @jars;
  foreach my $jar (readdir D){
    next if ($jar !~ /\.jar$/);
    push(@jars, "$ENV{GUS_HOME}/lib/java/$jar");
  }
  my $classpath = join(':', @jars);

  # This will create a file appending "_terms.txt" to the inFile 
  my $systemResult = system("java -classpath $classpath org.gusdb.gus.supported.OntologyVisitor $file");
  unless($systemResult / 256 == 0) {
    $self->error("Could not Parse OWL file $file");
  }

  # This will create a file appending "_isA.txt" to the inFile 
  my $systemResult = system("java -classpath $classpath org.gusdb.gus.supported.IsA_Axioms $file");
  unless($systemResult / 256 == 0) {
    $self->error("Could not Parse OWL file $file");
  }
}

sub getTerms {
	my ($self) = @_;
	my $file = $self->{file};
	my @keys = qw/sid name def synonyms uri obs/;
  return $self->readFile($file . "_terms.txt", \@keys);
}

sub getRelationships {
	my ($self) = @_;
	my $file = $self->{file};
	my @keys = qw/subject type object/;
  return $self->readFile($file . "_isA.txt", \@keys);
}

=item C<readFile>
Opens the out file and reads ALL lines into an arrayref. (Chomps off the newline chars)
B<Parameters:>
 $file(string): full path to the .owl_terms.txt or .owl_isA.txt tab-delimited file
 $keys(arrayref): array of keys to use in a hashref for each row
B<Return Type:> 
 C<ARRAYREF> Each element is a hashref

=cut

sub readFile {
  my ($self, $file, $keys) = @_;
  open(FILE, "< $file") or $self->error("Could Not open file $file for reading: $!");
  my $header = <FILE>; #remove the header
	unless (@$keys){
		chomp $header;
		@$keys = split(/\t/, $header);
	}
	my @data;
	while (my $line = <FILE>){
		chomp $line;
		my @values = split(/\t/, $line);
		my %struct;
		@struct{@$keys} = @values;
		push(@data, \%struct);
	}
	my @sorted = sort { $a->{$keys->[0]} cmp $b->{$keys->[0]} } @data;
  return \@sorted;
}

sub getDisplayOrder {
	return {};
}

sub error {
	my ($self, @msg) = @_;
	printf STDERR ("%s\n", join("\n", @msg));
}

1;

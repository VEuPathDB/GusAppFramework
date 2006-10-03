package GUS::Community::AffymetrixArrayFileReader;

use strict;
use GUS::Community::ArrayDesign;

=pod

=head2 Description

Extraction of annotaion (Rad::ArrayDesign, Rad::ShortOligo, Rad::ShortOligoFamily) from
standard affymetrix files: target_file (fasta), probe_file (tab), and CDF file  (all of 
which can be downloaded from www.affymetrix.com for standard arrays.

Most of this code was taken from the script MakeLoadAffyArrayDesign written by 
 H. He. and R. Gorski.

=cut

sub new {
  my ($class, $file, $type) = @_;

  unless($file && $type) {
    die "AffymetrixArrayFileReader requires both File and Type";
  }

  unless($type eq 'cdf' || $type eq 'probe' || $type eq 'target') {
    die "Supported Types are:  cdf, probe, and target";
  }

  my $args = {file => $file,
              type => $type,
             };

  bless $args, $class;
}


sub getType {$_[0]->{type} }
sub getFile {$_[0]->{file} }


sub readFile {
  my ($self) = @_;

  my $rv;

  my $type = $self->getType();
  my $file = $self->getFile();

  if($type eq 'cdf') {
    $rv = $self->readCdf($file);
  }
  elsif($type eq 'probe') {
    $rv = $self->readProbeTab($file);
  }
  elsif($type eq 'target') {
    $rv = $self->readTargetFasta($file);
  }
  else {
    die "Supported Types are:  cdf, probe, and target";
  }
  return($rv);
}

#--------------------
sub readCdf {
#--------------------
  my ($self, $file) = @_;

  my $array =  GUS::Community::ArrayDesign->new();
  print STDERR "Please make sure the CDF file does not have ^M characters. Otherwise, run dos2unix to convert the file first!\n";

  open(CDF, $file) || die "Cannot open cdf file $file for reading: $!";

  while(<CDF>) {
    chomp;
    $array->load_data($_);
  }
  close(CDF);
  print STDERR "finished reading CDF file $file.\n";

  return $array;
}


# retrieve probe sequence info for each probe pair (PM only) (Element)
#--------------------
sub readProbeTab {
#--------------------
  my ($self, $probe_file) = @_;

  my %probe_map;

  my $header = 0;
  my %fields;

  open PROBE, "$probe_file";
  while(<PROBE>){
    chomp;
    my @F = split(/\t/);

    unless ($header) {
      foreach my $i (0..$#F) {
        $fields{"$F[$i]"} = $i;
      }
      $header = 1;
      next;
    }

    my $key = join "\t", $F[$fields{"Probe Set Name"}], $F[$fields{"Probe X"}], $F[$fields{"Probe Y"}]; #probe_set x_pos y_pos
    $probe_map{$key} = $F[$fields{"Probe Sequence"}];
  }
  return \%probe_map;

}

# retrieve source_id for each probe set (CompositeElement)
#--------------------
sub readTargetFasta {
#--------------------
  my ($self, $file) = @_;

  open(TARGET, "grep \">target\" $file |") || die "Could not read target File $file: $!"; 

  my %gb_map;

  while(<TARGET>){
    chomp;
    my ($id, $source, $res) = split(/;/, $_, 3);

    my $gb;

    my $probe_set = (split(/:/,$id))[2]; 

    $source =~ s/^\s//;
    $res =~ s/^\s//;

    if ($source =~ /^gb\|([\w\_]+)(\.\d)?$/) {
      $gb = $1; # if source_id has version number, e.g., gb|NM_030770.1, trim it off
    } else {
       if ($res =~ /gb:([\w\_]+)(\.\d)?\s/) {
         $gb = $1;
       } elsif ($res =~ /^\"?([A-Z]+\d+)\s/) {
         $gb = $1;
       } elsif ($res =~ /gb=(\w+)\s/) {
         $gb = $1;
       }
     }
    $gb_map{$probe_set} = $gb;
  }
  return \%gb_map;
}


1;

# $Id: $
#vvvvvvvvvvvvvvvvvvvvvvvvv GUS4_STATUS vvvvvvvvvvvvvvvvvvvvvvvvv
  # GUS4_STATUS | SRes.OntologyTerm              | auto   | absent
  # GUS4_STATUS | SRes.SequenceOntology          | auto   | absent
  # GUS4_STATUS | Study.OntologyEntry            | auto   | absent
  # GUS4_STATUS | SRes.GOTerm                    | auto   | absent
  # GUS4_STATUS | Dots.RNAFeatureExon            | auto   | absent
  # GUS4_STATUS | RAD.SageTag                    | auto   | absent
  # GUS4_STATUS | RAD.Analysis                   | auto   | absent
  # GUS4_STATUS | ApiDB.Profile                  | auto   | absent
  # GUS4_STATUS | Study.Study                    | auto   | absent
  # GUS4_STATUS | Dots.Isolate                   | auto   | absent
  # GUS4_STATUS | DeprecatedTables               | auto   | absent
  # GUS4_STATUS | Pathway                        | auto   | absent
  # GUS4_STATUS | DoTS.SequenceVariation         | auto   | absent
  # GUS4_STATUS | RNASeq Junctions               | auto   | absent
  # GUS4_STATUS | Simple Rename                  | auto   | absent
  # GUS4_STATUS | ApiDB Tuning Gene              | auto   | absent
  # GUS4_STATUS | Rethink                        | auto   | absent
  # GUS4_STATUS | dots.gene                      | manual | unreviewed
die 'This file has broken or unreviewed GUS4_STATUS rules.  Please remove this line when all are fixed or absent';
#^^^^^^^^^^^^^^^^^^^^^^^^^ End GUS4_STATUS ^^^^^^^^^^^^^^^^^^^^

# POD documentation - main docs before the code

=head1 NAME

GUS::Community::ArrayDesign - Affy Chip Template.

=head1 DESCRIPTION

Modification (by R. Gorski) of the BioPerl module for Bio::Expression::Affymetrix::ArrayDesign 
(Copyright Allen Day <allenday@ucla.edu>, Stan Nelson <snelson@ucla.edu>
Human Genetics, UCLA Medical School, University of California, Los Angeles)

=head1 FEEDBACK

Direct feedback to E<lt>rgorski@mail.med.upenn.edu<gt>.

=cut

package GUS::Community::ArrayDesign;

use strict;
use Bio::Root::Root;
use Bio::Expression::FeatureGroup;
use GUS::Community::Feature;

use base qw(Bio::Root::Root);
use vars qw($DEBUG);

my %cellHeader = (
'QC_X' =>0,
'QC_Y' =>1,
'QC_PROBE' =>2,
'QC_PLEN' =>3,
'QC_ATOM' =>4,
'QC_INDEX' =>5,
'QC_MATCH' =>6,
'QC_BG' =>7
);


my %blockHeader = (
'UNIT_X' =>0,
'UNIT_Y' =>1,
'UNIT_PROBE' =>2,
'UNIT_FEAT' =>3,
'UNIT_QUAL' =>4,
'UNIT_EXPOS' =>5,
'UNIT_POS' =>6,
'UNIT_CBASE' =>7,
'UNIT_PBASE' =>8,
'UNIT_TBASE' =>9,
'UNIT_ATOM' =>10,
'INDEX' =>11,
'CODONIND' =>12,
'CODON' =>13,
'REGIONTYPE' =>14,
'REGION' =>15
);

use Class::MakeMethods::Emulator::MethodMaker
  get_set       => [ qw(
						cel header modified intensity masks outliers heavy
						algorithm algorithm_parameters name date type version dat_header
						mode _temp_name id
					   )
				   ],
  new_with_init => 'new',
;

=head2 _initialize

 Title   : _initialize
 Function: For compatibility with Bioperl. Defers to init().

=cut

sub _initialize {
  return shift->init(@_);
}

=head2 init

 Title   : init
 Function: For compatibility with Class::MakeMethods. 

=cut

sub init {
  my ($self,@args) = @_;

  $self->SUPER::_initialize(@args);
  $DEBUG = 1 if( ! defined $DEBUG && $self->verbose > 0);
}

=head2 matrix

 Title   : matrix
 Usage   : $self->matrix($x_coord, $y_coord, \$feature)
 Function: get-set method for matrix object/coordinate pair
 Returns : a matrix location
 Args    : A coordinate for a matrix location and optional value

=cut

sub matrix {
  my($self,@args) = @_;
  $self->{matrix} = []   unless defined $self->{matrix};
  return $self->{matrix} unless defined $args[0];

  $self->{matrix}->[ $args[1] ][ $args[0] ] = $args[2] if defined $args[2];
  return $self->{matrix}->[ $args[1] ][ $args[0] ];
}

=head2 featuregroup

 Title   : featuregroup
 Usage   : $self->featuregroup->($featurename);
 Function: get-set method for FeatureGroup object
Returns : a Bio::Expression::FeatureGroup object
 Args    : A key for a FeatureGroup object

=cut

sub featuregroup {
  my($self,$arg) = @_;
  return $self->{featuregroup}->{$arg} if $self->{featuregroup}->{$arg};
  $self->{featuregroup}->{$arg} = Bio::Expression::FeatureGroup->new()
	or $self->throw("Couldn't create a Bio::Expression::FeatureGroup: $!");
  return $self->{featuregroup}->{$arg};
}

=head2 qc_featuregroup

 Title   : qc_featuregroup
 Usage   : $self->qc_featuregroup($mode);
 Function: get-set method for quality control FeatureGroup object
Returns : a Bio::Expression::FeatureGroup object
 Args    : A key for a FeatureGroup object

=cut

sub qc_featuregroup {
  my($self,$arg) = @_;
  return $self->{qcfeaturegroup}->{$arg} if $self->{qcfeaturegroup}->{$arg};
  $self->{qcfeaturegroup}->{$arg} = Bio::Expression::FeatureGroup->new()
	or $self->throw("Couldn't create a Bio::Expression::FeatureGroup: $!");

  #tag it as being a QC featuregroup
  $self->{qcfeaturegroup}->{$arg}->is_qc(1);

  return $self->{qcfeaturegroup}->{$arg};
}

=head2 each_featuregroup

 Title   : each_featuregroup
 Usage   : @featuregroups = $array->each_featuregroup();
 Function: gets a list of FeatureGroup objects
 Returns : returns list of FeatureGroup objects
 Args    : none

=cut

sub each_featuregroup {
  my $self = shift;
  my @return = ();
  foreach my $p (sort keys %{$self->{featuregroup}}){
	push @return, $self->{featuregroup}->{$p};
  }
  return @return;
}

=head2

 Title   : each_qcfeaturegroup
 Usage   : @qcfeaturegroups = $array->each_qcfeaturegroup();
 Function: gets a list of quality control FeatureGroup objects
 Returns : returns list of quality control FeatureGroup objects
 Args    : none

=cut

sub each_qcfeaturegroup {
  my $self = shift;
  my @return = ();
  foreach my $p (sort keys %{$self->{qcfeaturegroup}}){
	push @return, $self->{qcfeaturegroup}->{$p};
  }
  return @return;
}

=head2

 Title   : load_data
 Usage   : $array->load_data($line);
 Function: parses current line of file and loads information
 Returns : nothing
 Args    : The line of text to be parsed

=cut
sub load_data {
  my($self,$line) = @_;

  next unless $line;
  print STDERR $self->mode . "\r" if $DEBUG;
  my($key,$value) = (undef,undef);

  if(my($try) = $line =~ /^\[(.+)\]/){
	$self->mode($try);
	return;
  } else {
	($key,$value) = $line =~ /^(.+?)=(.+)$/;
  }

  if($self->mode eq 'CDF'){
	$self->{lc($key)} = $value if $key;
  }
  elsif($self->mode eq 'Chip'){
	$self->{lc($key)} = $value if $key;
  }

  elsif($self->mode =~ /^QC/){
	return if /^CellHeader/;

	my $featuregroup = $self->qc_featuregroup($self->mode);

	my($type) = $_ =~ /Type=(.+)/;

	$featuregroup->type($type) and return if $type;
	$featuregroup->id($self->mode) if $self->mode;

	my($feature,$attrs) = $_ =~ /Cell(\d+)=(.+)/;
	return unless $attrs;
	my @attrs = split /\t/, $attrs;

	my %featureparams = (
						 x		=>	$attrs[$cellHeader{QC_X}],
						 y		=>	$attrs[$cellHeader{QC_Y}],
						);

	if($self->heavy){
	  $featureparams{probe}  = 	$attrs[$cellHeader{QC_PROBE}];
	  $featureparams{length} = 	$attrs[$cellHeader{QC_PLEN}];
	  $featureparams{atom}   = 	$attrs[$cellHeader{QC_ATOM}];
	  $featureparams{index}  = 	$attrs[$cellHeader{QC_INDEX}];
	}

	my $featureParam = GUS::Community::Feature->new( %featureparams );
	$self->matrix($attrs[$blockHeader{'UNIT_X'}],$attrs[$blockHeader{UNIT_Y}],\$feature);
	$featuregroup->add_feature($featureParam);
  }
  elsif($self->mode =~ /^Unit(\d+)_Block/){
	return if /^Block|Num|Start|Stop|CellHeader/;

	my $featuregroup;

	my($name) = $_ =~ /^Name=(.+)/;
	if($name){
	  $featuregroup = $self->featuregroup($name);
	  $featuregroup->id($name);
	  $self->_temp_name($name);
	  return;
	} else {
	  $featuregroup = $self->featuregroup($self->_temp_name);
	}

	my($feature,$attrs) = (undef,undef);
	($feature,$attrs) = $_ =~ /Cell(\d+)=(.+)/;
	return unless $attrs;
	my @attrs = split /\t/, $attrs;

	my %featureparams = (
						 x        =>	$attrs[$blockHeader{UNIT_X}],
						 id       =>	$attrs[$blockHeader{UNIT_QUAL}],
						 y	    =>	$attrs[$blockHeader{UNIT_Y}],
						 is_match =>  $attrs[$blockHeader{UNIT_CBASE}] eq $attrs[$blockHeader{UNIT_PBASE}] ? 0 : 1,
						);

	if($self->heavy){
	  $featureparams{probe}		= 	$attrs[$blockHeader{UNIT_PROBE}];
	  $featureparams{feat}		= 	$attrs[$blockHeader{UNIT_FEAT}];
	  $featureparams{expos}		= 	$attrs[$blockHeader{UNIT_EXPOS}];
	  $featureparams{pos}		= 	$attrs[$blockHeader{UNIT_POS}];
	  $featureparams{cbase}		= 	$attrs[$blockHeader{UNIT_CBASE}];
	  $featureparams{pbase}		= 	$attrs[$blockHeader{UNIT_PBASE}];
	  $featureparams{tbase}		= 	$attrs[$blockHeader{UNIT_TBASE}];
	  $featureparams{atom}		= 	$attrs[$blockHeader{UNIT_ATOM}];
	  $featureparams{index}		= 	$attrs[$blockHeader{UNIT_INDEX}];
	  $featureparams{codon_index}	= 	$attrs[$blockHeader{UNIT_CODONIND}];
	  $featureparams{codon}		= 	$attrs[$blockHeader{UNIT_CODON}];
	  $featureparams{regiontype}	= 	$attrs[$blockHeader{UNIT_REGIONTYPE}];
	  $featureparams{region}		= 	$attrs[$blockHeader{UNIT_REGION}];
	}

	my $featureParam =  GUS::Community::Feature->new( %featureparams );
	$featuregroup->add_feature($featureParam);

	$self->matrix($attrs[$blockHeader{UNIT_X}],$attrs[$blockHeader{UNIT_Y}],\$feature);

    }
  elsif($self->mode =~ /^Unit(\d+)/){
	#not sure what should be done with these... they seem extraneous
  }
}

sub DESTROY {
  my $self = shift;
  $self->destroy_features();
}

sub destroy_features {
  my $self = shift;
  my $matrix = $self->matrix;
}

1;

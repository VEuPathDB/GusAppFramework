#!/usr/bin/perl

# =================================================
# Package ParseBioycSgml
# =================================================

package GUS::Supported::ParseBiocycSgml;

# =================================================
# Documentation
# =================================================

=pod

=head1 Description
Parses a Biocyc SGML File and returns a hash that stores the pathways
=cut

use strict;
use XML::Simple;
use Data::Dumper;
use FileHandle;
use File::Basename;

# =================================================
# Package Methods
# =================================================

sub new {
  my ($class) = @_;
#  my $xml = XML::Simple->new (ForceArray => 1, KeepRoot => 0);
  my $self = {};
  bless($self, $class);
  return $self;
}


sub parseXML {
  my ($self, $filename) = @_;

  my (%pathway, %pathwayId, %reaction, %node);

  if (!$filename) {
   die "Error: XML file not found!";
  }

  #initialize parser
  # ===================================
  my $data = XMLin($filename, KeyAttr => { species => 'id', pathway => 'name' }, ForceArray => [ 'species', 'notes' ]);
  # print Dumper($data);

  # parse Compounds
  my $hashRef = $data->{'model'}->{'listOfSpecies'}->{'species'};
  my %myHash = %{$hashRef};
  my @fields = keys(%myHash);

  foreach my $f (@fields) {
    my $name = $hashRef->{$f}->{name};
    $node{$f}->{name} = $f . ": " . $name; 
    $node{$f}->{source_id} = $f;
    $node{$f}->{type} = 'compound';

    # if Compound has KEGG_ID, use that as the compound source_id
    # other available Compound props (INCHI, INCHIKEY, etc)
    my @arra = $hashRef->{$f}->{notes}[0]->{body}->{p};
    foreach my $a (@arra) {
      foreach my $p (@{$a}) {
	if ( $p =~/KEGG.COMPOUND/ ) {
	  $node{$f}->{source_id} = $p;
	  $node{$f}->{source_id} =~s/KEGG.COMPOUND\:\s+.*(C\d+).*/$1/ ;
	}
      }
    }
  }

  # get Pathway IDs
  $hashRef = $data->{'model'}->{'listOfPathways'}->{'pathway'};
  foreach my $f (keys(%{$hashRef})) {
    $pathwayId{$f} = $hashRef->{$f}->{id};
  }

  # parse Reactions
  my @reactionArr = @{$data->{model}->{listOfReactions}->{reaction}};

  foreach my $reactionRef (@reactionArr) {
    my @ecNums;
    %myHash = %{$reactionRef};
    @fields = keys(%myHash);
    my (@reactants, @products);
    my $rn_id = $reactionRef->{id};
    my $dir = ($reactionRef->{reversible} eq 'true')? 'reversible' : 'irreversible';
    my  @pathways;
    my $ecNum;

    # get Pathway Names or EC number
    my @arrNotes =$reactionRef->{notes}->[0]->{body}->{p};
    foreach my $a (@arrNotes) {
      foreach my $note (@{$a}) {
	if ( $note =~/^SUBSYSTEM:/ ) {
	  $note =~s/SUBSYSTEM\:\s+(.+)/$1/ ;
	  @pathways = split(/; /, $note);  # these are all pathways that have this reaction
	}
	if ( $note =~/^EC NUMBER/ ) {
	  $ecNum = $note;
	  $ecNum =~s/EC NUMBER\:\s+EC\-(.+)/$1/ ;

	  # add wildcard in ec number, if needed
	  $ecNum = $ecNum . ".-" if ($ecNum=~/^\d+\.\d+\.\d+$/);
	  $ecNum = $ecNum . ".-.-" if ($ecNum=~/^\d+\.\d+$/);
	}
      }
    }

    # if no entry add 'Unknown'
    $ecNum = 'Unknown' if (!$ecNum); #  when Reactions do not have an EC Number.
    push (@ecNums,$ecNum); # collect ecNums'; later add them as nodes

    # get Reactants
    my @arrReactants = $reactionRef->{listOfReactants}->{speciesReference};
    my $r= $arrReactants[0];
    if (ref($r) eq 'HASH'){
      push (@reactants,$r->{species});
    } else { # when arrayRef
      foreach $a (@{$r}) {
	my %h = %{$a};
	push (@reactants,$h{species});
      }
    }
    $reaction{$rn_id}->{reactants} = @reactants;

    # get Products
    my @arrProducts = $reactionRef->{listOfProducts}->{speciesReference};
    my $p= $arrProducts[0];
    if (ref($p) eq 'HASH'){
      push (@products,$p->{species});
    } else { # when arrayRef
      foreach $a (@{$p}) {
	my %h = %{$a};
	push (@products,$h{species});
      }
    }
    $reaction{$rn_id}->{products} = @products;

    # populate hash of Pathways 
    foreach my $p (@pathways) {
      $pathway{$p}->{SOURCE_ID} = ($pathwayId{$p})? $pathwayId{$p} : $p;
      $pathway{$p}->{NAME} = $p;
      $pathway{$p}->{URI} = "http://biocyc.org/TRYPANO/NEW-IMAGE?type=PATHWAY&object=" . $pathway{$p}->{SOURCE_ID};
      $pathway{$p}->{REACTIONS}->{($reactionRef->{name})} = {
							     PRODUCTS => \@products,
							     SUBSTRATES => \@reactants,
							     ENZYMES => $ecNum,
							     NAME => $reactionRef->{name},
							     TYPE => $dir  };

      # reactant Nodes;
      my @rr = @{$pathway{$p}->{REACTIONS}->{($reactionRef->{name})}->{SUBSTRATES}};
      foreach my $reac (@{$pathway{$p}->{REACTIONS}->{($reactionRef->{name})}->{SUBSTRATES}}){
	$pathway{$p}->{NODES}->{$reac}->{SOURCE_ID}  = $node{$reac}->{source_id};
	$pathway{$p}->{NODES}->{$reac}->{UNIQ_ID}  = $node{$reac}->{name};
	$pathway{$p}->{NODES}->{$reac}->{TYPE} = 'compound';
      }

      # product Nodes
      my @pp = @{$pathway{$p}->{REACTIONS}->{($reactionRef->{name})}->{PRODUCTS}};
      foreach my $prod (@{$pathway{$p}->{REACTIONS}->{($reactionRef->{name})}->{PRODUCTS}}){
	$pathway{$p}->{NODES}->{$prod}->{SOURCE_ID}  = $node{$prod}->{source_id};
	$pathway{$p}->{NODES}->{$prod}->{UNIQ_ID}  = $node{$prod}->{name};
	$pathway{$p}->{NODES}->{$prod}->{TYPE} = 'compound';
      }

      # EC Number Nodes:
      foreach my $e (@ecNums) {
	$pathway{$p}->{NODES}->{$e}->{SOURCE_ID}  = $e;
	$pathway{$p}->{NODES}->{$e}->{UNIQ_ID}  = $e;
	$pathway{$p}->{NODES}->{$e}->{TYPE} = 'enzyme';
      }

    }
  }

#  print  Dumper %pathway;
  return \%pathway;
}  # end parseBiocycSgml


# =================================================
# End Module
# =================================================
1; 

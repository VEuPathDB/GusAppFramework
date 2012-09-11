#!/usr/bin/perl

# =================================================
# Package ParseKeggXml
# =================================================

package GUS::Supported::ParseKeggXml;

# =================================================
# Documentation
# =================================================

=pod

=head1 Description

Parses a KeggXML File and returns a hash that stores 
the pathway relationships

=cut

# =================================================
# Pragmas
# =================================================

use strict;

# =================================================
# Includes
# =================================================

use Data::Dumper;
use FileHandle;
use XML::LibXML;

# =================================================
# Package Methods
# =================================================

# -------------------------------------------------
# Subroutine: parseKGML
# Description: parses a kegg xml file
# Inputs: the filename
# Outputs: a hash data structure that stores
#          the kegg entries, relations and reactions
# -------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self, $class);
  return $self;
}



sub parseKGML {
  my ($self, $filename) = @_;

  my $pathway = undef; # returned value

  if (!$filename) {
   die "Error: KGML file not found!";
  }

  #initialize parser
  # ===================================
  my $parser = new XML::LibXML;
  my $doc = $parser->parse_file($filename);
  my $rid = 0;


  # get pathway name and id info
  # ===================================
  my @nodes = $doc->findnodes('/pathway');

  $pathway->{SOURCE_ID} = $nodes[0]->getAttribute('name');
  $pathway->{NAME} = $nodes[0]->getAttribute('title');
  $pathway->{URI} = $nodes[0]->getAttribute('link');
  $pathway->{NCOMPLEXES} = 0;
  

  # get "entries"
  # ===================================
  @nodes = $doc->findnodes('/pathway/entry');
  foreach my $entry (@nodes) {
    my $type = $entry->getAttribute('type');
 
    my $id = $entry->getAttribute('id');

    $pathway->{ENTRY}->{$id}->{TYPE} = $type;
    $pathway->{ENTRY}->{$id}->{NAME} = $entry->getAttribute('name');
    $pathway->{ENTRY}->{$id}->{REACTION} = $entry->getAttribute('reaction');
    $pathway->{ENTRY}->{$id}->{LINK} = $entry->getAttribute('link');

    my @graphicsNode = $entry->getChildrenByTagName('graphics');

    foreach my $gn (@graphicsNode) {
     my $gnName = $gn->getAttribute('name');
     $pathway->{ENTRY}->{$id}->{GRAPHICS}->{$gnName}->{FGCOLOR} = $gn->getAttribute('fgcolor');
     $pathway->{ENTRY}->{$id}->{GRAPHICS}->{$gnName}->{BGCOLOR} = $gn->getAttribute('bgcolor');
     $pathway->{ENTRY}->{$id}->{GRAPHICS}->{$gnName}->{TYPE} = $gn->getAttribute('type');
     $pathway->{ENTRY}->{$id}->{GRAPHICS}->{$gnName}->{X} = $gn->getAttribute('x');
     $pathway->{ENTRY}->{$id}->{GRAPHICS}->{$gnName}->{Y} = $gn->getAttribute('y');
     $pathway->{ENTRY}->{$id}->{GRAPHICS}->{$gnName}->{WIDTH} = $gn->getAttribute('width');
     $pathway->{ENTRY}->{$id}->{GRAPHICS}->{$gnName}->{HEIGHT} = $gn->getAttribute('height');
    }
  }  # end entries

 
  # read in the relations
  # ===================================

  my @relations = $doc->findnodes('/pathway/relation');

  foreach my $relation (@relations) {
    my $type = $relation->getAttribute('type');
 
    my $rtype = "Protein-Protein"; # if type = PPrel
    $rtype = "Enzyme-Enyzme" if $type eq "ECrel";
    $rtype = "Gene Expression" if $type eq "GErel";
    $rtype = "Protein-Compound" if $type eq "PCrel";
    $rtype = "Maplink" if $type eq "maplink";

    my $entryId = $relation->getAttribute('entry1');
    my $associatedEntryId =  $relation->getAttribute('entry2');
    my $entry = $pathway->{ENTRY}->{$entryId};
    my $associatedEntry = $pathway->{ENTRY}->{$associatedEntryId};
    my @entries = ($entryId);
    my @associatedEntries = ($associatedEntryId);

    my @subtype = $relation->getChildrenByTagName('subtype');  
 
    foreach my $e (@entries) {
      foreach my $a (@associatedEntries) {
	if (!defined $subtype[0]) {
	  $pathway->{RELATIONS}->{$rtype}->{"Relation".$rid}->{ENTRY} = $e;
	  $pathway->{RELATIONS}->{$rtype}->{"Relation".$rid}->{ASSOCIATED_ENTRY} = $a;
	  $pathway->{RELATIONS}->{$rtype}->{"Relation".$rid}->{INTERACTION_TYPE} = $rtype;
	  $rid++;
	}
	else {
	  foreach my $st (@subtype) {
	    $pathway->{RELATIONS}->{$rtype}->{"Relation".$rid}->{ENTRY} = $e;
	    $pathway->{RELATIONS}->{$rtype}->{"Relation".$rid}->{ASSOCIATED_ENTRY} = $a;
	    $pathway->{RELATIONS}->{$rtype}->{"Relation".$rid}->{INTERACTION_TYPE} = $rtype;
	    $pathway->{RELATIONS}->{$rtype}->{"Relation".$rid}->{INTERACTION_ENTITY} = $st->getAttribute('name');
	    $pathway->{RELATIONS}->{$rtype}->{"Relation".$rid}->{INTERACTION_ENTITY_ENTRY} = $st->getAttribute('value');
	    $rid++;
	  }
	}
     }
    }
 
 
  } #end relations

  # read in the reactions
  # ===================================

 my @reactions = $doc->findnodes('/pathway/reaction');

  foreach my $reaction (@reactions) {
    my $reactionName = $reaction->getAttribute('name');
      $pathway->{REACTIONS}->{$reactionName}->{ID} = $reaction->getAttribute('id');
      $pathway->{REACTIONS}->{$reactionName}->{TYPE} = $reaction->getAttribute('type');

      my @substrate = $reaction->getChildrenByTagName('substrate');
      foreach my $sbstr (@substrate) {
        my $substrId = $sbstr->getAttribute('id');
        $pathway->{REACTIONS}->{$reactionName}->{SUBSTRATE}->{$substrId}->{ENTRY} =  $substrId; 
        $pathway->{REACTIONS}->{$reactionName}->{SUBSTRATE}->{$substrId}->{NAME} =  $sbstr->getAttribute('name'); 
      } 

      my @product = $reaction->getChildrenByTagName('product');
      foreach my $prd (@product) {
        my $prdId = $prd->getAttribute('id');
        $pathway->{REACTIONS}->{$reactionName}->{PRODUCT}->{$prdId}->{ENTRY} =  $prdId;
        $pathway->{REACTIONS}->{$reactionName}->{PRODUCT}->{$prdId}->{NAME} =  $prd->getAttribute('name');
      } 
  }

  print  Dumper $pathway;
  return $pathway;
}  # end parseKeggXml


# =================================================
# End Module
# =================================================
1; 

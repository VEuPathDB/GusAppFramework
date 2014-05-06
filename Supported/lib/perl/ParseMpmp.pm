#!/usr/bin/perl

# =================================================
# Package ParseXgmml
# =================================================

package GUS::Supported::ParseMpmp;

# =================================================
# Documentation
# =================================================

=pod
=head1 Description
Parses a Xgmml MPMP File and returns a hash that stores 
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
use File::Basename;
# =================================================
# Package Methods
# =================================================

# -------------------------------------------------
# Subroutine: parseXGMML
# Description: parses a xgmml file
# Inputs: the filename
# Outputs: a hash data structure that stores the entries and relations
# -------------------------------------------------

sub new {
  my ($class) = @_;
  my $parser = new XML::LibXML;
  my $self = {parser => $parser};
  bless($self, $class);
  return $self;
}


sub parseXGMML {
  my ($self, $filename) = @_;
  my ($pathway, $nodeEntryMapping);

  if (!$filename) {
   die "Error: XGMML file not found!";
  }

  #initialize parser
  # ===================================
  my $parser = $self->{parser};
  my $doc = $parser->parse_file($filename);
  my $rid = 0;


  # get pathway name and id info
  # ===================================
  my @nodes = $doc->findnodes('/graph');
  $pathway->{SOURCE_ID} = $nodes[0]->getAttribute('label');
  $pathway->{NAME} =  $nodes[0]->getAttribute('label');

  my $linkTag = ''; 
  my @attributeArray = $nodes[0]->getChildrenByTagName('att');
  foreach my $gn (@attributeArray) {
      $linkTag  = $gn->getAttribute('value')  if  (($gn->getAttribute('name')) eq 'shared name') ;
  }
  $pathway->{URI} = "http://priweb.cc.huji.ac.il/malaria/maps/" . $linkTag . ".html";


  # get "entries"
  # ===================================
  my @nodeArray = $doc->findnodes('/graph/node');

  foreach my $entry (@nodeArray) {
    my $label = $entry->getAttribute('label'); 
    my $id = $entry->getAttribute('id');

    my ($uniqId, $xPosition, $yPosition, $type, $canonicalName);
    my @attributeArray = $entry->getChildrenByTagName('att');
    foreach my $gn (@attributeArray) {
      $type = $gn->getAttribute('value') if ($gn->getAttribute('name')) eq 'Type';
      $canonicalName  = $gn->getAttribute('value') if ($gn->getAttribute('name')) eq 'shared name';
      $canonicalName  = $id if (!$canonicalName); # cpds dont seem to have this value 
    }
    if ($type eq 'pathway') {
	$canonicalName = $label;
    }

    my @attributeArray = $entry->getChildrenByTagName('graphics');
    foreach my $gn (@attributeArray) {
	$xPosition = sprintf "%.4f", $gn->getAttribute('x');
	$yPosition = sprintf "%.4f", $gn->getAttribute('y');
    }

      if ($xPosition && $yPosition) {
	  $uniqId = $id . "_X:" . $xPosition . "_Y:" . $yPosition ;
	 #print "CHECK: ($id, $uniqId, $xPosition, $yPosition, $type, $canonicalName )\n";

	$pathway->{NODES}->{$uniqId}->{SOURCE_ID} = $label if ($uniqId);
	$pathway->{NODES}->{$uniqId}->{UNIQ_ID} = $uniqId if ($uniqId);
	$pathway->{NODES}->{$uniqId}->{TYPE} = $type;
	$pathway->{NODES}->{$uniqId}->{ENTRY_ID} = $id if ($id);

	#$pathway->{NODES}->{$uniqId}->{GRAPHICS}->{NAME} = $gn->getAttribute('name');
	#$pathway->{NODES}->{$uniqId}->{GRAPHICS}->{TYPE} = $gn->getAttribute('type');
	$pathway->{NODES}->{$uniqId}->{GRAPHICS}->{X} = $xPosition;
	$pathway->{NODES}->{$uniqId}->{GRAPHICS}->{Y} = $yPosition;  
      }
    # print "OUT uniqID= $uniqId AND   X= $xPosition  Y= $yPosition\n";
}  # end entries


  # read in the relations (edges)
  # ===================================
  my @edgeArray = $doc->findnodes('/graph/edge');
  foreach my $entry (@edgeArray) {
    my $label = $entry->getAttribute('label');
    my $source_id = $entry->getAttribute('source');
    my $target_id = $entry->getAttribute('target');

    my $source = getNodeUniqId($pathway, $source_id);
    my $target = getNodeUniqId($pathway, $target_id);
    # print "\n\nLABEL $label, SOURCE $source_id AND TARGET $target_id \n";
    # print "   SO source $source_id = $source AND target $target_id = $target\n";

    my $rtype = "Pathway Relation"; # FIX
    $pathway->{RELATIONS}->{$rtype}->{"Relation".$rid}->{ENTRY} = $source;
    $pathway->{RELATIONS}->{$rtype}->{"Relation".$rid}->{ASSOCIATED_ENTRY} = $target;
    #  $pathway->{RELATIONS}->{$rtype}->{"Relation".$rid}->{INTERACTION_TYPE} = $r;
  } #end relations


  #print  Dumper $pathway;
  return $pathway;
}  # end parseXgmml

sub getNodeUniqId {
    my ($pathway, $node_id) = @_;
    my @keyArr = keys %{$pathway->{NODES}} ;
    foreach my $uid (keys %{$pathway->{NODES}} ){
      #print "   YES $node_id is $uid\n" if ($uid =~/$node_id\_(.*)/) ;
      return $uid if ($uid =~/$node_id\_(.*)/) ;;
    }
}

# =================================================
# End Module
# =================================================
1; 

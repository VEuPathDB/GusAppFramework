package GUS::Supported::KEGGReaderv2;
use base qw(GUS::Supported::MetabolicPathwayReader);
#use lib "$ENV{GUS_HOME}/lib/perl";
use strict;

use XML::LibXML;
use File::Basename;
use JSON;
use Data::Dumper;
use Storable 'dclone';

# -------------------------------------------------
# Subroutine: read
# Description: @override parses a kegg xml file

# Outputs: a hash data structure that stores
#          the kegg entries, relations and reactions
#
#          if-else statement checks for just ec files
#          or ec and rn files. Runs relevant sub
#          for each (for updating the output hash
#          with missing EC numbers from KEGG file
#          download).
# -------------------------------------------------
sub setPathwayHash {
  my ($self, $pathwayHash) = @_;
  $self->{_pathway_hash} = $pathwayHash;
}

sub getPathwayHash {
  my ($self) = @_;
  return $self->{_pathway_hash};
}

sub read {

  # Got to #### START HERE. - for the action.
  my ($rxnDotJson);

  sub firstread {
    my $filename = shift;
    my ($pathway, $nodeEntryMapping);

    print STDERR "Reading file $filename...\n";

    if (!$filename) {
      die "Error: KGML file not found!";
    }

    #initialize parser
    # ===================================
    my $parser = XML::LibXML->new(load_ext_dtd => 0);
    my $doc = $parser->parse_file($filename);
    my $rid = 0;

    # get pathway name and id info
    # ===================================
    my @nodes = $doc->findnodes('/pathway');

    if($nodes[0]->getAttribute('name') eq "undefined"){;}
    else{
      $pathway->{SOURCE_ID} = $nodes[0]->getAttribute('name');
      $pathway->{SOURCE_ID} =~ s/path://g;

      $pathway->{NAME} = $nodes[0]->getAttribute('title');
      $pathway->{URI} = $nodes[0]->getAttribute('link');
      $pathway->{IMAGE_FILE} = basename($nodes[0]->getAttribute('image'));
      $pathway->{NCOMPLEXES} = 0;

      # get "entries"
      # ===================================
      @nodes = $doc->findnodes('/pathway/entry');
      foreach my $entry (@nodes) {
        my $type = $entry->getAttribute('type');
        my $uniqId = $entry->getAttribute('id');

        my $enzymeNames = $entry->getAttribute('name');
        $enzymeNames =~ s/gl:|ec:|cpd:|dr:|path:|rc:|rn://g;
        $nodeEntryMapping->{$entry->getAttribute('id')} = $enzymeNames;

        my @nodeIds = split(/ /,$enzymeNames);

        foreach my $id (@nodeIds) {
          # Here $id needs to include X and Y positions (be unique)

          my @graphicsNode = $entry->getChildrenByTagName('graphics');

          foreach my $gn (@graphicsNode) {
           my $gnName = $gn->getAttribute('name');
           my ($xPosition, $yPosition) = ($gn->getAttribute('x'), $gn->getAttribute('y'));
           my $verboseName = $id . "_X:" . $xPosition . "_Y:" . $yPosition;

          $pathway->{NODES}->{$uniqId}->{SOURCE_ID} = $id;
          $pathway->{NODES}->{$uniqId}->{UNIQ_ID} = $uniqId;
          $pathway->{NODES}->{$uniqId}->{VERBOSE_NAME} = $verboseName;
          $pathway->{NODES}->{$uniqId}->{TYPE} = $type;
          $pathway->{NODES}->{$uniqId}->{ENTRY_ID} = $entry->getAttribute('id');
          $pathway->{NODES}->{$uniqId}->{REACTION} = $entry->getAttribute('reaction');
          $pathway->{NODES}->{$uniqId}->{LINK} = $entry->getAttribute('link');

           $pathway->{NODES}->{$uniqId}->{GRAPHICS}->{NAME} = $gn->getAttribute('name');
           $pathway->{NODES}->{$uniqId}->{GRAPHICS}->{FGCOLOR} = $gn->getAttribute('fgcolor');
           $pathway->{NODES}->{$uniqId}->{GRAPHICS}->{BGCOLOR} = $gn->getAttribute('bgcolor');
           $pathway->{NODES}->{$uniqId}->{GRAPHICS}->{TYPE} = $gn->getAttribute('type');
           $pathway->{NODES}->{$uniqId}->{GRAPHICS}->{X} = $gn->getAttribute('x');
           $pathway->{NODES}->{$uniqId}->{GRAPHICS}->{Y} = $gn->getAttribute('y');
           $pathway->{NODES}->{$uniqId}->{GRAPHICS}->{WIDTH} = $gn->getAttribute('width');
           $pathway->{NODES}->{$uniqId}->{GRAPHICS}->{HEIGHT} = $gn->getAttribute('height');
           $pathway->{NODES}->{$uniqId}->{GRAPHICS}->{LINECOORDS} = $gn->getAttribute('coords');

          }
        }  # end entries
      }

      # read in the relations
      # ===================================

      my @relations = $doc->findnodes('/pathway/relation');

      foreach my $relation (@relations) {
        my $type = $relation->getAttribute('type');

        my $rtype = "Protein-Protein"; # if type = PPrel
        $rtype = "Enzyme-Enzyme" if $type eq "ECrel";
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

        ##### NB - 2019-Mar-11 - Ross - The RELATIONS part of the hash does not seem to be used in KEGGMetabolicPathway.pm.
        foreach my $e (@entries) {
          foreach my $a (@associatedEntries) {
          	if (!defined $subtype[0]) {
          	  $pathway->{RELATIONS}->{$rtype}->{$rid}->{ENTRY} = $e;
          	  $pathway->{RELATIONS}->{$rtype}->{$rid}->{ASSOCIATED_ENTRY} = $a;
          	  $pathway->{RELATIONS}->{$rtype}->{$rid}->{INTERACTION_TYPE} = $rtype;
          	  $rid++;
          	}
          	else {
          	  foreach my $st (@subtype) {
          	    $pathway->{RELATIONS}->{$rtype}->{$rid}->{ENTRY} = $e;
          	    $pathway->{RELATIONS}->{$rtype}->{$rid}->{ASSOCIATED_ENTRY} = $a;
          	    $pathway->{RELATIONS}->{$rtype}->{$rid}->{INTERACTION_TYPE} = $rtype;
          	    $pathway->{RELATIONS}->{$rtype}->{$rid}->{INTERACTION_ENTITY} = $st->getAttribute('name');
          	    $pathway->{RELATIONS}->{$rtype}->{$rid}->{INTERACTION_ENTITY_ENTRY} = $st->getAttribute('value');
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

          #a complex reaction key to uniquely identify an 'Interaction'. To be noted that a single reaction can have multiple interactions
          #like substrateA <-> Enzyme1 <-> ProductA and SubstrateA <->EnzymeB <-> ProductA
          #which is a single reaction in KEGG but two separate network interactions

        my $reactionId = $reaction->getAttribute('id');
          my $verboseName = $reactionId."_".$reaction->getAttribute('name');
          my $rnName = $reaction->getAttribute('name');
          $rnName =~ s/rn://g;

          my @enzymes = split(/ /,$reaction->getAttribute('id'));

          my (@substrates, @products);

          my @substrate = $reaction->getChildrenByTagName('substrate');
          foreach my $sbstr (@substrate) {
            my $substrId = $sbstr->getAttribute('id');
            my $name = $sbstr->getAttribute('name');
            $name =~ s/gl:|ec:|cpd:|dr://g;
            push (@substrates,({ENTRY => $substrId, NAME => $name}));
          }

          my @product = $reaction->getChildrenByTagName('product');
          foreach my $prd (@product) {
            my $prdId = $prd->getAttribute('id');
            my $name = $prd->getAttribute('name');
            $name =~ s/gl:|ec:|cpd:|dr://g;
            push (@products, ({ENTRY => $prdId, NAME => $name}));
          }

          $pathway->{REACTIONS}->{$reactionId} = {PRODUCTS => [@products],
                                                    SUBSTRATES => [@substrates],
                                                    ENZYMES => [@enzymes],
                                                    SOURCE_ID => $rnName,
                                                    VERBOSE_NAME => $verboseName,
                                                    TYPE => $reaction->getAttribute('type')};
      }



      foreach my $relation (values %{$pathway->{RELATIONS}->{'Enzyme-Enzyme'}}) {

        unless($relation->{INTERACTION_ENTITY} eq 'compound') {
          print  "WARN:  Only know about Compound->Enzyme Relations Here. Found $relation->{INTERACTION_ENTITY}\n" ;
          next;
        }

        my $c = $relation->{INTERACTION_ENTITY_ENTRY};
        my $e1 = $relation->{ENTRY};
        my $e2 = $relation->{ASSOCIATED_ENTRY};

        push @{$pathway->{EDGES}->{$c}}, $e1 unless(&alreadyExistsInArray($e1, $pathway->{EDGES}->{$c}));
        push @{$pathway->{EDGES}->{$c}}, $e2 unless(&alreadyExistsInArray($e2, $pathway->{EDGES}->{$c}));
      }


      foreach my $relation (values %{$pathway->{RELATIONS}->{Maplink}}) {
        unless($relation->{INTERACTION_ENTITY} eq 'compound') {
          print "WARN: Only know about Compound->Map Relations Here.  Found $relation->{INTERACTION_ENTITY}\n" ;
          next;
        }
        my $c = $relation->{INTERACTION_ENTITY_ENTRY};
        my $e1 = $relation->{ENTRY};
        my $e2 = $relation->{ASSOCIATED_ENTRY};

        push @{$pathway->{EDGES}->{$c}}, $e1 unless(&alreadyExistsInArray($e1, $pathway->{EDGES}->{$c}));
        push @{$pathway->{EDGES}->{$c}}, $e2 unless(&alreadyExistsInArray($e2, $pathway->{EDGES}->{$c}));
      }

      foreach my $reaction (values %{$pathway->{REACTIONS}}) {
        foreach my $enzymeId (@{$reaction->{ENZYMES}}) {

          foreach my $substrateHash(@{$reaction->{SUBSTRATES}}) {
            my $substrateId = $substrateHash->{ENTRY};
            push @{$pathway->{EDGES}->{$substrateId}}, $enzymeId unless(&alreadyExistsInArray($enzymeId, $pathway->{EDGES}->{$substrateId}));
          }

          foreach my $productHash (@{$reaction->{PRODUCTS}}) {
            my $productId = $productHash->{ENTRY};
            push @{$pathway->{EDGES}->{$productId}}, $enzymeId unless(&alreadyExistsInArray($enzymeId, $pathway->{EDGES}->{$productId}));
          }
        }
      }
    }
    #$self->setPathwayHash($pathway);
    return $pathway;
  }

  sub alreadyExistsInArray {
    my ($e, $ar) = @_;

    return 0 unless($ar);
    foreach(@$ar) {
      return 1 if($e == $_);
    }
    return 0;
  }

  my $ecHash = {}; # Hash of 'reaction' and EC numbers from the ec file to go into rn file. Only has complete EC numbers.
  # Updates hash from firstread() (original KEGGReader) with EC numbers from ec xml file.
  sub ecrnUpdate {
  	my ($level, $filename)  = @_;
    my $multipleECsID = {}; # Hash of all xml ids="" where name="ec:1.3.1.9 ec:1.3.1.10" (for example, not just 1 ec #)
  	my $parser = XML::LibXML->new(load_ext_dtd => 0);
    my $doc = $parser->parse_file($filename);
    my @nodes = $doc->findnodes('/pathway/entry');

  	foreach my $entry (@nodes){
  	  my $ecNumber = $entry->getAttribute('name');
      $ecNumber =~ s/gl:|ec:|cpd:|dr:|path://g;
      $ecHash->{$entry->getAttribute('id')} = $ecNumber;
    }
    foreach my $item (keys $level->{'NODES'}){
      if ($item =~ /^[\d]{1,3}/){
        for my $item2 (keys $level->{'NODES'}->{$item}){
          if ($item2 =~ /UNIQ_ID/){
            if ($level->{'NODES'}->{$item}->{$item2} ~~ $ecHash){
              $level->{'NODES'}->{$item}->{'GRAPHICS'}->{'NAME'} = $ecHash->{$level->{'NODES'}->{$item}->{$item2}};
              $level->{'NODES'}->{$item}->{'SOURCE_ID'} = $ecHash->{$level->{'NODES'}->{$item}->{$item2}};
            }
            else{
              #$level->{'NODES'}->{$item}->{'GRAPHICS'}->{'NAME'} = "ROSSTEST"; ;
              #$level->{'NODES'}->{$item}->{'SOURCE_ID'} = 'ROSSTEST';
            }
          }
        }
      }
    }
    return $level;
    }

  sub doubleECFix {
    my($level) = @_;

    my $edgesToRemove = [];

    foreach my $key (keys $level){
      if ($key eq 'NODES'){
        foreach my $nodeKey(keys $level->{$key}){
          my $name = $level->{'NODES'}->{$nodeKey}->{'GRAPHICS'}->{'NAME'};

          if #((($name =~ m/ec:/) && ($level->{'NODES'}->{$nodeKey}->{'GRAPHICS'}->{'NAME'}))
              #||
              (($name =~ m/(([\d]{1,3}\.){3})[\d]{1,3} (([\d]{1,3}\.){3})[\d]{1,3}/) && ($level->{'NODES'}->{$nodeKey}->{'GRAPHICS'}->{'NAME'}))
              #)
              {

              my @ecNumbers;
              @ecNumbers = split(/ /, $name);
              my $id = $nodeKey;
              push $edgesToRemove, $id;
              my $ecCount = scalar(@ecNumbers);

            for(my $i = 0; $i < $ecCount; $i++){
              my $tempLevel = $level->{'NODES'}->{$id};
              my $replacementID = $id . "_" . $i;

              # Update NODES hash.
              $level->{'NODES'}->{$replacementID} = $tempLevel;
              my $insertedEC = @ecNumbers[$i] =~ s/ //r;
              $level->{'NODES'}->{$replacementID}->{'GRAPHICS'}->{'NAME'} = $insertedEC;
              $level->{'NODES'}->{$replacementID}->{'SOURCE_ID'} = $insertedEC;
              $level->{'NODES'}->{$replacementID}->{'ENTRY_ID'} = $replacementID;
              $level->{'NODES'}->{$replacementID}->{'UNIQ_ID'} = $replacementID;
              ###~~~ If wanting to change the X,Y of the box add in here.~~~###

              #Update REACTIONS hash.
              if(%{$level->{'REACTIONS'}}){
                if($level->{'REACTIONS'}->{$id}){
                  my $tempReaction = dclone $level->{'REACTIONS'}->{$id};
                  $level->{'REACTIONS'}->{$replacementID} = $tempReaction;
                  $level->{'REACTIONS'}->{$replacementID}->{'ENZYMES'} = $replacementID;
                  $level->{'REACTIONS'}->{$replacementID}->{'VERBOSE_NAME'} = $replacementID . "_" . $level->{'REACTIONS'}->{$replacementID}->{'SOURCE_ID'};
                }
              }

              # #Update RELATIONS hash. # Doesn't look to be used in plugin so not complete.
              # my $tempRelation = dclone $level->{'RELATIONS'}->{'Enzyme-Enzyme'}->{$id};
              # $level->{'RELATIONS'}->{'Enzyme-Enzyme'}->{$replacementID} = $tempRelation;

              # Update EDGES hash.
              # NOTE - rn00514 has no EDGES. As of 2019-Mar-14 TriTryp does not show this pathway. Ross.
              # NOTE -  ec00601 is weird.

              if($level->{'EDGES'}){
                foreach my $edge (keys $level->{'EDGES'}){
                  foreach my $item (keys $level->{'EDGES'}->{$edge}){
                    for my $item2 ($item){
                      my $test = $level->{'EDGES'}->{$edge}[$item2]; #
                #      print STDERR "$test\n";
                      if ($test eq $id){
                        push $level->{'EDGES'}->{$edge}, $replacementID;
                      }
                    }
                  }
                } # End of foreach
              }
            }
            delete($level->{'NODES'}->{$id});
            delete($level->{'REACTION'}->{$id});
          }
        }
      }
    }

    if($level->{'EDGES'}){
      foreach my $i (@$edgesToRemove){
        foreach my $edge (keys $level->{'EDGES'}){
          foreach my $item (keys $level->{'EDGES'}->{$edge}){
            if ($level->{'EDGES'}->{$edge}[$item] eq $i){
              splice $level->{'EDGES'}->{$edge}, $item, 1;
            }
          }
        }
      } # End of foreach
    }
    return $level;
  }

  #Creates hash of rn----- => EC numbers from reactions.json.
  sub reactionsjson_tohash{
  	my $reactions = shift;
      my $temp_ec_name_stored;
  	open(my $fh,"<", $reactions)
  		or die "Could not open file '$reactions'";

  	my $file_content = do { local $/; <$fh> };
  	my $json_reactions = decode_json $file_content;
  	my $rn_ec; # hash of rn numbers : EC number.

  	sub json_traverse{
  		my $level = shift;
  	    foreach my $key (keys $level) {

  	        if ($level->{$key} =~ m/^R[\d]{5}/) {
  		        my @rn_value = split / /, $level->{'name'}, 2;
  		            if (exists $rn_ec->{@rn_value[0]}) {
  			            push $rn_ec->{@rn_value[0]}, $temp_ec_name_stored;
  		            } else {
  				        $rn_ec->{@rn_value[0]} = [];
  				        push $rn_ec->{@rn_value[0]}, $temp_ec_name_stored;
  			    	}
  		    }
  	    elsif ($key eq 'children'){
  		    foreach my $child_of_children (@{$level->{'children'}}){
  			    $temp_ec_name_stored = $level->{'name'};
  			    json_traverse($child_of_children);
  			    }
  		    }
   	    }
  	}
  	json_traverse($json_reactions);
  	return $rn_ec;
  }

  # Gets a list of EC numbers from the reference pathway (only complete e.g. 1.1.3.4 are in ref pathway)
  # to crossreference EC number to add to hash.
  my $ec_check = [];
  sub validECs {
      my $ec_file = shift;
  	#TODO path to EC file. Will have to give relative to the final folder, i.e. the workflow folder.
  	open(DATA, $ec_file) or die "No file to open. \n";
      while (<DATA>) {
  	    my $line = $_;
  	    if ($line =~ /([\d]{1,2}\.){3}[\d]{1,3}/) {
  		    if ($line =~ /(([\d]{1,2}\.){3}[\d]{1,3})/g){
  			    if ($1 ~~ $ec_check){;}
  			    else {
              push $ec_check, $1;
  					}
  		    }
      	}
      }
  }

  # Goes over the hash output from ecrnUpdate and replaces the rn---- numbers for EC numbers.
  my $double_rn_hash = {};
  my $rn_ec;
  sub hash_traverse {
  	my $level = shift;
  	my $rn_add_on = "...";

  	foreach my $key (keys $level->{'NODES'}){
  	    my $len_ec = 0;

  		# if (ref($level->{$key}) eq 'HASH'){
  		# 		hash_traverse($level->{$key});
  		# }
  		# else {
  				if($level->{'NODES'}->{$key}->{'GRAPHICS'}->{'NAME'} =~ /^R[\d]{5}/ ){
  						my $temp_rn = $level->{'NODES'}->{$key}->{'GRAPHICS'}->{'NAME'};
  						$temp_rn =~ s/\.\.\.//;
  						$len_ec = scalar (@{$rn_ec->{$temp_rn}});

  						if ($len_ec == 1) {
  							$level->{'NODES'}->{$key}->{'GRAPHICS'}->{'NAME'} = $rn_ec->{$temp_rn}[0];
                $level->{'NODES'}->{$key}->{'SOURCE_ID'} = $rn_ec->{$temp_rn}[0];
  							}
  						elsif($len_ec > 1) {
  							my @ec_array = @{$rn_ec->{$temp_rn}};
  							my $validated_ec = [];
  							foreach my $ec (@ec_array){
  								if ($ec ~~ $ec_check){
  									push $validated_ec, $ec;
  									} else {;} #  print "$ec not in, \n";}
  								}
  								my $validated_ec_len = scalar (@{$validated_ec});
  								if ($validated_ec_len == 1){
  									$level->{'NODES'}->{$key}->{'GRAPHICS'}->{'NAME'} = @{$validated_ec}[0];
                    $level->{'NODES'}->{$key}->{'SOURCE_ID'} = @{$validated_ec}[0];
  									}
  								else {
  									# Feeds into below.
  									#print $temp_rn, "\n";
  									$double_rn_hash->{$temp_rn . $rn_add_on} = $validated_ec;
  								}
  						}
  				}
  		}
  	return $level;
  }

  # If multiple reference path EC numbers exist for a r---- number, takes hash $double_rn_hash and assigns one to each instance of r---- number. They should be equally valid. Hash should return with contents of empty arrays if all are assigned.
  sub multi_ref_ec_update {
  	my $level = shift;
  	foreach my $item (keys $level->{'NODES'}){
  		if ($item =~ /^[\d]{1,3}/){
  			for my $item2 (keys $level->{'NODES'}->{$item}){
  				if ($item2 =~ /GRAPHICS/){
  					if ($level->{'NODES'}->{$item}->{$item2}->{'NAME'} ~~ $double_rn_hash){
  						#print $double_rn_hash->{$level->{'NODES'}->{$item}->{$item2}->{'NAME'}}[-1], " : EC in \n";
  						my $to_pop = $level->{'NODES'}->{$item}->{$item2}->{'NAME'};
              my $toAdd =  $double_rn_hash->{$level->{'NODES'}->{$item}->{$item2}->{'NAME'}}[-1];
              if (!$toAdd){;}
              else{

                $level->{'NODES'}->{$item}->{'GRAPHICS'}->{'NAME'} = $toAdd; # This is broken.
                $level->{'NODES'}->{$item}->{'SOURCE_ID'} = $toAdd;
    						#print Dumper $double_rn_hash->{$to_pop};
    						pop @{$double_rn_hash->{$to_pop}};
    						#print $to_pop, "\n";
    						#print Dumper $double_rn_hash->{$to_pop};
              }

  					}
  				}
  			}
  		}
  	}
  	return $level;
  }

#################################### START HERE.
  my ($self) = @_;
	my $filename = $self->getFile();

	my $workspacePath = $filename;
	my @workspacePath = split(/rn|ec/, $workspacePath, 2);
	$workspacePath = @workspacePath[0];

	my $ECFile = $filename;
	$ECFile =~m/([\d]{5})/;
	$ECFile = $1;
	my $commonECFile = $workspacePath ."ec/ec$ECFile.xml";
	print STDERR "Common EC: ", $commonECFile, "\n";
	my $returnedHash = {};

	my $ecFilesArray = [];
	   opendir (DIR, $workspacePath . "ec");
   	   while (my $file = readdir(DIR)){
       push $ecFilesArray, $file;
       }
  # Checks for another set of files (ec) in workspace. Runs original KEGGReader if no files found.
  # If files found runs new subs to update the output hash with incomplete ECs.
  if($filename =~ m/xml/ && (-z $commonECFile | !-e $commonECFile)){
  		$returnedHash = firstread($filename);
    }

  elsif ("ec" . $ECFile . ".xml" ~~ $ecFilesArray){
    if($filename =~ m/xml/ ){
      my $rxnDotJson =  $workspacePath . "reactions.json";
      $rn_ec = reactionsjson_tohash($rxnDotJson);
      my $zeroHash = firstread($filename); # update subs with new xml files.
      validECs($commonECFile);
      my $firstHash = ecrnUpdate($zeroHash, $commonECFile);
      my $secondHash = &hash_traverse($firstHash);
      my $thirdHash = doubleECFix($secondHash);
      $returnedHash = multi_ref_ec_update($thirdHash);
      #$returnedHash = $zeroHash;


      foreach my $key (keys $returnedHash->{'NODES'}){
        if ($returnedHash->{'NODES'}->{$key}->{'SOURCE_ID'} =~ m/R([\d]{5})/){
         print STDERR "Warning - missing EC number at $key.\n";
        }
      }

      # Testing for unassigned EC numbers. # This may not work now 20190311 - Ross
      # if (!%{$double_rn_hash}){
      #   print STDERR "For $filename: ";
      #   print STDERR "All ECs assigned.\n";
      # }
      # else{
      #   print STDERR "Unassigned EC numbers:\n";
      #   print STDERR Dumper $double_rn_hash;
      # }

    }
  }
  $self->setPathwayHash($returnedHash);
} # end of sub read {}

sub alreadyExistsInArray {
    my ($e, $ar) = @_;

    return 0 unless($ar);
    foreach(@$ar) {
      return 1 if($e == $_);
    }
  return 0;
}

package GUS::Supported::BioCycReader;
use lib "$ENV{GUS_HOME}/lib/perl";
use base qw(GUS::Supported::MetabolicPathwayReader);

use strict;
use warnings;

use List::MoreUtils qw(any);
use File::Basename;
use CBIL::Util::Utils;

use Data::Dumper;

############Read####################
#@override parses a biopax owl file
#Outputs a hash data structure that
#contains pathway, reaction, node
#and edge information
####################################

sub read {
    my ($self) = @_;
    my $biopaxFile = $self->getFile();
    die "Input file $biopaxFile cannot be found" unless (-e $biopaxFile);

    my ($file, $path, $ext) = fileparse($biopaxFile, '\..*');
    $file = "$file.rdf";

    #convert biopax owl to tabulated rdf (writes rdf file in same dir)
    runCmd("biopaxToRdf.R $biopaxFile $path"); 

    # reads rdf and extracts only required information as hash
    my $rdf = makeRdfHash("$path/$file");

    #parse rdf structure to make pathway hash
    my $pathway = {};
    my $count = 0; #to provide unique keys for edges
    foreach my $pathwayId (keys(%{$rdf->{'Pathway'}})) {

    #Add pathway information
        $pathway->{'Description'} = $rdf->{'Pathway'}->{$pathwayId}->{'standardName'};
        foreach my $xref (@{$rdf->{'Pathway'}->{$pathwayId}->{'xref'}}) {
            $xref =~ s/^#//;
            if ($rdf->{'UnificationXref'}->{$xref}->{'db'} =~ /Cyc/) {
                $pathway->{'SourceId'} = $rdf->{'UnificationXref'}->{$xref}->{'id'};
            }
        }

    #Get pathway steps
        foreach my $pathwayStep (@{$rdf->{'Pathway'}->{$pathwayId}->{'pathwayOrder'}}) {
            $pathwayStep =~ s/^#//;
            my $biochemicalPathway = $rdf->{'BiochemicalPathwayStep'}->{$pathwayStep};
            $pathway->{$pathwayStep}->{'Direction'} = $biochemicalPathway->{'stepDirection'};
            $pathway->{$pathwayStep}->{'nextStep'} = (defined($biochemicalPathway->{'nextStep'}) ? $biochemicalPathway->{'nextStep'} : "None");
           
            #Add reactions
            foreach my $reaction (@{$biochemicalPathway->{'stepConversion'}}) {
                $reaction =~ s/^#//;
                my $biochemicalReaction = $rdf->{'BiochemicalReaction'}->{$reaction};
                
                #Data for reaction table
                $pathway->{$pathwayStep}->{'Reactions'}->{$reaction}->{'Description'} = $biochemicalReaction->{'name'}[0];
                $pathway->{$pathwayStep}->{'Reactions'}->{$reaction}->{'Equation'} = $biochemicalReaction->{'equation'};
                my $xref = $biochemicalReaction->{'xref'};
                $xref =~ s/^#//;
                $pathway->{$pathwayStep}->{'Reactions'}->{$reaction}->{'SourceId'} = $rdf->{'UnificationXref'}->{$xref}->{'id'};

                #Data for node table
                $pathway->{$pathwayStep}->{'Reactions'}->{$reaction}->{'ecNumber'} = $biochemicalReaction->{'eCNumber'}; #use this for display name and soft link
                $pathway->{$pathwayStep}->{'Reactions'}->{$reaction}->{'NodeType'} = 'enzyme';

                $pathway->{$pathwayStep}->{'Reactions'}->{$reaction}->{'UniqueId'} = "$pathwayStep.$reaction";

                #Get all compounds
                getCompounds ($pathway, $rdf, $pathwayStep, $biochemicalReaction, "left");
                getCompounds ($pathway, $rdf, $pathwayStep, $biochemicalReaction, "right");


            }
            #Make edges
            my @reactionNode = (keys(%{$pathway->{$pathwayStep}->{'Reactions'}}));
            die "Pathway step $pathwayStep has more than one reaction\n" unless scalar(@reactionNode) == 1;
            my $reactionUniqueId = $pathway->{$pathwayStep}->{'Reactions'}->{$reactionNode[0]}->{'UniqueId'};
            $count = makeEdges ($pathway, $pathwayStep, $reactionUniqueId, $count);
        }
    }


    #Remove duplicate nodes for compounds that are passed to another reaction
    foreach my $pathwayStep (keys(%{$pathway})) {
        if ($pathwayStep =~ /BiochemicalPathwayStep/) { 
            if ($pathway->{$pathwayStep}->{'nextStep'} ne 'None') {
                my $nextSteps = $pathway->{$pathwayStep}->{'nextStep'};
                my @outgoingCompounds = ($pathway->{$pathwayStep}->{'Direction'} eq 'LEFT-TO-RIGHT') ? keys(%{$pathway->{$pathwayStep}->{'Compounds'}->{'right'}}) : keys(%{$pathway->{$pathwayStep}->{'Compounds'}->{'left'}});
                foreach my $nextStep (@{$nextSteps}) {
                    $nextStep =~ s/^#//;
                    my @incomingCompounds = ($pathway->{$nextStep}->{'Direction'} eq 'LEFT-TO-RIGHT') ? keys(%{$pathway->{$nextStep}->{'Compounds'}->{'left'}}) :  keys(%{$pathway->{$nextStep}->{'Compounds'}->{'right'}});
                    foreach my $outgoingCompound (@outgoingCompounds) {
                        if (any {$_ eq $outgoingCompound} @incomingCompounds) {
                            if ($pathway->{$pathwayStep}->{'Direction'} eq 'LEFT-TO-RIGHT') {
                                delete $pathway->{$pathwayStep}->{'Compounds'}->{'right'}->{$outgoingCompound};
                            } elsif ($pathway->{$pathwayStep}->{'Direction'} eq 'RIGHT-TO-LEFT') {
                                delete $pathway->{$pathwayStep}->{'Compounds'}->{'left'}->{$outgoingCompound};
                            }
                        }
                    }
                }
            }
        }
    }

    #Adjust edges to point to compound unique id (ensure correct fks when loading)
    foreach my $pathwayStep (keys(%{$pathway})) {
        if ($pathwayStep =~ /^BiochemicalPathwayStep/) {
            foreach my $edge (keys(%{$pathway->{$pathwayStep}->{'Edges'}})) {
                my $node = $pathway->{$pathwayStep}->{'Edges'}->{$edge}->{'Node'};
                if ($node =~ /SmallMoleculeReference/ || $node =~ /ProteinReference/ || $node =~ /Complex/ || $node =~ /Rna/) {
                    #incoming compounds - these should always be in the hash for this pathway step
                    my $side = ($pathway->{$pathwayStep}->{'Direction'} eq 'LEFT-TO-RIGHT') ? 'left' : 'right';
                    $pathway->{$pathwayStep}->{'Edges'}->{$edge}->{'Node'} = $pathway->{$pathwayStep}->{'Compounds'}->{$side}->{$node}->{'UniqueId'};

                }elsif ($node =~ /BiochemicalReaction/ || $node =~ /Transport/) {
                    #outgoing compounds
                    my $associatedNode = $pathway->{$pathwayStep}->{'Edges'}->{$edge}->{'AssociatedNode'};
                    my $side = ($pathway->{$pathwayStep}->{'Direction'} eq 'LEFT-TO-RIGHT') ? 'right' : 'left';

                    #If not passed to next reaction, will be in hash for this pathway step
                    if (exists $pathway->{$pathwayStep}->{'Compounds'}->{$side}->{$associatedNode}) {
                        $pathway->{$pathwayStep}->{'Edges'}->{$edge}->{'AssociatedNode'} = $pathway->{$pathwayStep}->{'Compounds'}->{$side}->{$associatedNode}->{'UniqueId'};

                    #otherwise, look in hash for next pathway step(s)
                    }else {
                        my $nextSteps = $pathway->{$pathwayStep}->{'nextStep'};
                        foreach my $nextStep (@{$nextSteps}) {
                            my $nextSide = ($pathway->{$nextStep}->{'Direction'} eq 'LEFT-TO-RIGHT') ? 'left' : 'right';
                            if (exists ($pathway->{$nextStep}->{'Compounds'}->{$nextSide}->{$associatedNode})) {
                                $pathway->{$pathwayStep}->{'Edges'}->{$edge}->{'AssociatedNode'} = $pathway->{$nextStep}->{'Compounds'}->{$nextSide}->{$associatedNode}->{'UniqueId'};
                            }
                        }
                    }
                }
            }
        }
    } 

    $self->setPathwayHash($pathway);
}


################Subroutines#######################

sub makeEdges {
    my ($pathway, $pathwayStep, $reaction, $count) = @_;
    if ($pathway->{$pathwayStep}->{'Direction'} eq 'LEFT-TO-RIGHT') {
        #incoming
        foreach my $compound (keys(%{$pathway->{$pathwayStep}->{'Compounds'}->{'left'}})) {
            makeEdge($pathway, $pathwayStep, $count, $compound, $reaction);
            $count ++;
        }
        #outgoing
        foreach my $compound (keys(%{$pathway->{$pathwayStep}->{'Compounds'}->{'right'}})) {
            makeEdge($pathway, $pathwayStep, $count, $reaction, $compound);
            $count ++;
        }

    }elsif ($pathway->{$pathwayStep}->{'Direction'} eq 'RIGHT-TO-LEFT') {
        #incoming
        foreach my $compound (keys(%{$pathway->{$pathwayStep}->{'Compounds'}->{'right'}})) {
            makeEdge($pathway, $pathwayStep, $count, $compound, $reaction);
            $count ++;
        }
        #outgoing
        foreach my $compound (keys(%{$pathway->{$pathwayStep}->{'Compounds'}->{'left'}})) {
            makeEdge($pathway, $pathwayStep, $count, $reaction, $compound);
            $count ++;
        }
    }
    return $count;
}

sub makeEdge {
    my ($pathway, $pathwayStep, $count, $node, $associatedNode) = @_;
    $pathway->{$pathwayStep}->{'Edges'}->{$count}->{'Node'} = $node;
    $pathway->{$pathwayStep}->{'Edges'}->{$count}->{'AssociatedNode'} = $associatedNode;
}
    
        

sub getCompounds {
    my ($pathway, $rdf, $pathwayStep, $reaction, $side) = @_;
    my $compounds = $reaction->{$side};
    foreach my $compound (@{$compounds}) {
        $compound =~ s/^#//;
        if (exists($rdf->{'SmallMolecule'}->{$compound}->{'entityReference'})) {
            my $smallMolRef = $rdf->{'SmallMolecule'}->{$compound}->{'entityReference'};
            $smallMolRef =~ s/^#//;
            $pathway->{$pathwayStep}->{'Compounds'}->{$side}->{$smallMolRef}->{'NodeType'} = 'compound';
            $pathway->{$pathwayStep}->{'Compounds'}->{$side}->{$smallMolRef}->{'standardName'} = $rdf->{'SmallMolecule'}->{$compound}->{'standardName'};
            $pathway->{$pathwayStep}->{'Compounds'}->{$side}->{$smallMolRef}->{'UniqueId'} = "$pathwayStep.$smallMolRef";
            foreach my $xref (@{$rdf->{'SmallMoleculeReference'}->{$smallMolRef}->{'xref'}}) {
                $xref =~ s/^#//;
                if ($xref =~ /UnificationXref/) {
                    if ($rdf->{'UnificationXref'}->{$xref}->{'db'} eq 'ChEBI')  {
                        $pathway->{$pathwayStep}->{'Compounds'}->{$side}->{$smallMolRef}->{'chEBI'} = $rdf->{'UnificationXref'}->{$xref}->{'id'};
                    }
                }
            }
        }else {
            $pathway->{$pathwayStep}->{'Compounds'}->{$side}->{$compound}->{'NodeType'} = 'compound';
            $pathway->{$pathwayStep}->{'Compounds'}->{$side}->{$compound}->{'standardName'} = $rdf->{'SmallMolecule'}->{$compound}->{'standardName'};
            $pathway->{$pathwayStep}->{'Compounds'}->{$side}->{$compound}->{'UniqueId'} = "$pathwayStep.$compound";
        }
    }
}

sub addPropToRdf {
    my ($rdf, $attributes, $propValue) = @_;
    my ($class, $id, $property) = @$attributes;
    $rdf->{$class}->{$id}->{$property} = $propValue;
}

sub pushPropToRdfArray {
    my ($rdf, $attributes, $propValue) = @_;
    my ($class, $id, $property) = @$attributes;
    push(@{$rdf->{$class}->{$id}->{$property}}, $propValue);
}

sub makeRdfHash {
    my ($file) = @_;
    my $rdf={};
    open(RDF, "<$file") or die "Cannot open file $file\n$!";
    while(<RDF>) {
        my @line = split("\t", $_);
        s/^"// for @line;
        s/"$// for @line;
        chomp @line;
        my ($no, $class, $id, $property, $propertyAttr, $propertyAttrVal, $propertyValue) = @line; 
        if ($class) {
            my $attributes = [$class, $id, $property];
            
            if ($class eq 'Pathway') {
                if ($property eq 'xref' || $property eq 'pathwayOrder' || ($property eq 'pathwayComponent' && $propertyAttrVal =~ /^#BiochemicalReaction/)) {
                    pushPropToRdfArray($rdf, $attributes, $propertyAttrVal);
                }elsif ($property eq 'standardName') {
                    addPropToRdf($rdf, $attributes, $propertyValue);
                } 
            
            }elsif ($class eq 'UnificationXref') {
                addPropToRdf($rdf, $attributes, $propertyValue);
            
            }elsif ($class eq 'BiochemicalPathwayStep') {
                if ($property eq 'nextStep' || $property eq 'stepConversion') {
                    pushPropToRdfArray($rdf, $attributes, $propertyAttrVal);
                }elsif ($property eq 'stepDirection') {
                    addPropToRdf($rdf, $attributes, $propertyValue);
                }
            
            }elsif ($class eq 'BiochemicalReaction' || $class eq 'TransportWithBiochemicalReaction' || $class eq 'Transport') {
                $attributes->[0] = 'BiochemicalReaction';
                if ($property eq 'eCNumber') {
                    addPropToRdf($rdf, $attributes, $propertyValue);
                }elsif ($property eq 'left' || $property eq 'right') {
                    pushPropToRdfArray($rdf, $attributes, $propertyAttrVal);
                }elsif ($property eq 'name') {
                    pushPropToRdfArray($rdf, $attributes, $propertyValue);
                }elsif ($property eq 'standardName') {
                    $rdf->{$class}->{$id}->{'equation'} = $propertyValue;
                }elsif ($property eq 'xref' && $propertyAttrVal =~ /^#UnificationXref/) {
                    addPropToRdf($rdf, $attributes, $propertyAttrVal);
                }
            
            }elsif ($class eq 'SmallMolecule' || $class eq 'Protein' || $class eq 'Complex' || $class eq 'Rna') {
                $attributes->[0] = 'SmallMolecule';
                if($property eq 'entityReference' || $property eq 'xref') {
                    addPropToRdf($rdf, $attributes, $propertyAttrVal);
                }elsif($property eq 'standardName') {
                    addPropToRdf($rdf, $attributes, $propertyValue);
                }
           
            }elsif ($class eq 'SmallMoleculeReference' || $class eq 'ProteinReference' || $class eq 'RnaReference') {
                $attributes->[0] = 'SmallMoleculeReference';
                if($property eq 'standardName') {
                    addPropToRdf($rdf, $attributes, $propertyValue);
                }elsif ($property eq 'xref') {
                    pushPropToRdfArray($rdf, $attributes, $propertyAttrVal);
                }
            }
        }
    }
    close(RDF);
    return($rdf);
}

sub setPathwayHash {
    my ($self, $pathwayHash) = @_;
    $self->{_pathway_hash} = $pathwayHash;
}

sub getPathwayHash {
    my ($self) = @_;
    return $self->{_pathway_hash};
}

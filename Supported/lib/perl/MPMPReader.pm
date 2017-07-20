package GUS::Supported::MPMPReader;
use lib "$ENV{GUS_HOME}/lib/perl";
use base qw(GUS::Supported::MetabolicPathwayReader);

use strict;
use warnings;

use File::Basename;
use JSON;

use Data::Dumper;

############Read####################
#@override parses JSON dump from
#download or MPMP
#Outputs a hash data structure that
#contains pathway, reaction, node
#and edge information
####################################

sub read {
    my ($self) = @_;

    my $jsonFile = $self->getFile();
    die "Input file $jsonFile cannot be found\n" unless (-e $jsonFile);

    my $jsonData;
    {
        local $/ = undef;
        open my $jsonFH, '<', $jsonFile;
        $jsonData = <$jsonFH>;
        close $jsonFH;
    }

    my $data = decode_json($jsonData);


    my ($file, $path, $ext) = fileparse($jsonFile, '\..*');
    my $pathwaySourceId = $file;

    my $count = 0;
    foreach my $node (@{$data->{'elements'}->{'nodes'}}) {
        my $nodeData = $node->{'data'};
        if ($nodeData->{'node_type'} eq 'pathway_internal') {
            $data->{'data'} = $nodeData;
            delete $data->{'elements'}->{'nodes'}->[$count];
        }
        $count ++;
    }

    $data->{'data'}->{'source_id'} = $pathwaySourceId;

    $self->setPathwayHash($data);
}


################Subroutines#######################

sub setPathwayHash {
    my ($self, $pathwayHash) = @_;
    $self->{_pathway_hash} = $pathwayHash;
}

sub getPathwayHash {
    my ($self) = @_;
    return $self->{_pathway_hash};
}


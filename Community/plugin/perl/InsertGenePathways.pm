package GUS::Community::Plugin::InsertGenePathways;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use warnings;

use Data::Dumper;
use GUS::PluginMgr::Plugin;
use GUS::Supported::KEGGReader;
use GUS::Supported::ParseMpmp;
use GUS::Supported::MetabolicPathway;
use GUS::Supported::MetabolicPathwayReader;
use GUS::Model::SRes::Pathway;
use GUS::Model::SRes::PathwayNode;


# use DBD::Oracle qw(:ora_types);

# ----------------------------------------------------------
# Load Arguments
# ----------------------------------------------------------

sub getArgsDeclaration {
  my $argsDeclaration  =
    [   
     stringArg({ name => 'pathwaysFileDir',
                 descr => 'full path to xml files',
                 constraintFunc=> undef,
                 reqd  => 1,
                 isList => 0,
                 mustExist => 1,
                }),

     enumArg({ name           => 'format',
               descr          => 'The file format for pathways (KEGG, MPMP, Biopax, Other); currently only handles KEGG',
               constraintFunc => undef,
               reqd           => 1,
               isList         => 0,
               enum           => 'KEGG, MPMP, Biopax, Other'
             }),

     stringArg({ name  => 'extDbRlsSpec',
                  descr => "The ExternalDBRelease specifier for the pathway database. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
                  constraintFunc => undef,
                  reqd           => 1,
                  isList         => 0 }),

  stringArg({ name  => 'geneExtDbRlsSpec',
                  descr => "The ExternalDBRelease specifier for the reference gene database. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
                  constraintFunc => undef,
                  reqd           => 1,
                  isList         => 0 }),
    ];

  return $argsDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------

sub getDocumentation {
  my $purposeBrief = "Inserts pathways from a set of KGML or XGMML (MPMP) files into Network schema.";

  my $purpose =  "Inserts pathways from a set of KGML or XGMML (MPMP) files into Network schema.";

  my $tablesAffected = [['Model.Pathway', 'One Row to identify each pathway'], ['Model.PathwayNode', 'One row to store network and graphical inforamtion about a pathway node (genes only)'],];

  my $tablesDependedOn = [['Core.TableInfo',  'To store a reference to tables that have Node records (ex. EC Numbers, Coumpound IDs']];

  my $howToRestart = "No restart";

  my $failureCases = "";

  my $notes = "";

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief, tablesAffected=>$tablesAffected, tablesDependedOn=>$tablesDependedOn, howToRestart=>$howToRestart, failureCases=>$failureCases,notes=>$notes};

  return $documentation;
}

#--------------------------------------------------------------------------------

sub new {
  my $class = shift;
  my $self = {};
  bless($self, $class);

  my $documentation = &getDocumentation();

  my $args = &getArgsDeclaration();

  my $configuration = { requiredDbVersion => 4.0,
                        cvsRevision => '$Revision: 13986 $',
                        name => ref($self),
                        argsDeclaration => $args,
                        documentation => $documentation
                      };

  $self->initialize($configuration);

  return $self;
}


#######################################################################
# Main Routine
#######################################################################

sub run {
  my ($self) = shift;

  my $inputFileDir = $self->getArg('pathwaysFileDir');
  die "$inputFileDir directory does not exist\n" if !(-d $inputFileDir); 

  my $pathwayFormat = $self->getArg('format');
  my $extension = ($pathwayFormat eq 'KEGG') ? 'kgml' : 'xml';

  my @pathwayFiles = <$inputFileDir/*.$extension>;
  die "No $extension files found in the directory $inputFileDir\n" if not @pathwayFiles;

  my $extDbRlsId = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));
  my $geneExtDbRlsId = $self->getExtDbRlsId($self->getArg('geneExtDbRlsSpec'));

  foreach my $p (@pathwayFiles) {
    $self->loadPathway($p, $extDbRlsId, $geneExtDbRlsId);
  }
}

sub loadPathway {
  my ($self, $pathwayFile, $extDbRlsId) = @_;

  my $preader = GUS::Supported::KEGGReader->new($pathwayFile);
  my $pathwayObj = $preader->read();
  my $name = $pathwayObj->{NAME};
  my $sourceId = $pathwayObj->{SOURCE_ID};
  $self->log("Processing: $name ($sourceId)") if $self->getArg('veryVerbose');

  my $pathway = GUS::Model::SRes::Pathway->new({ name => $name,
						 external_database_release_id => $extDbRlsId,
						 source_id => $sourceId,
						 url => $pathwayObj->{URL}
					       });
  
  my $nodes = $pathwayObj->{NODES};
  foreach my $n (keys %$nodes) {
    my $nodeType = $nodes->{$n}->{TYPE};
    next if ($nodeType ne 'gene');
    
    my @geneId = split /:/, $nodes->{$n}->{SOURCE_ID};
    die $geneId[1];
    
    $self->log(Dumper($nodes->{$n})) if ($nodes->{$n}->{TYPE} eq 'gene');
#    my $sourceId = $n->{SOURCE_ID};
#    my $uniqueId = $n->{UNIQ_ID};
#    my $nodeName = $n->{VERBOSE_NAME};
#    my $nodeType = $n->{TYPE};
#    my $graphicsName = $n->{GRAPHICS}->{NAME};
    
  }

  # $pathway->submit() if (! $pathway->retrieveFromDB());

  my $pathwayId = $pathway->getPathwayId();

}#subroutine


sub loadPathwayNode {
  my($self,$pathwayId, $node,$nodeGraphics) = @_;

  if ($node->{node_name}) {
    my $identifier = $pathwayId ."_" . $node->{node_name}; # eg: 571_1.14.-.-_X:140_Y:333
    
    my $node_type = 213766; # TODO: look up in SRes.OntologyTerm (gene, sequence ontology)
    
    my $tableId = 108; # TODO: lookup up DoTS.Gene from Core.TableInfo
    
    my $rowId = $node->{row_id};

    my $display_label = $node->{node_name};
    $display_label =~s/\_X:\d+(\.\d*)\_Y:\d+(\.\d*)//;  # remove coordinates

    my $nodeShape ='';
    if ($nodeGraphics->{shape}) {
      $nodeShape = ($nodeGraphics->{shape} eq 'round') ? 1 :
	($nodeGraphics->{shape} eq 'rectangle') ? 2 : ($nodeGraphics->{shape} eq 'roundrectangle') ? 3 : 4;
    }
    
    #if a parent Pathway Id is provided only then insert a new record.
    if ($pathwayId){
      my $pathwayNode = GUS::Model::SRes::PathwayNode->new({ parent_id => $pathwayId,
                                                             display_label => $display_label,
                                                             pathway_node_type_id => $node_type,
                                                             glyph_type_id => $nodeShape,
                                                             x => $nodeGraphics->{x},
                                                             y => $nodeGraphics->{y},
                                                             height => $nodeGraphics->{height},
                                                             width => $nodeGraphics->{width},
							     table_id => $tableId,
							     row_id => $rowId
                                                           });
      $pathwayNode->submit()  unless $pathwayNode->retrieveFromDB();
    }
   
  }
}


sub undoTables {
  my ($self) = @_;

  return (
	  'SRes.Pathway',
	  'SRes.PathwayNode',
	 );
}


1;

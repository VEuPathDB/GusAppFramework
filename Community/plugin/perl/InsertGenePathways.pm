package GUS::Community::Plugin::InsertGenePathways;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use warnings;

use Data::Dumper;
use GUS::PluginMgr::Plugin;
use GUS::Supported::KEGGReader;
use GUS::Model::SRes::Pathway;
use GUS::Model::SRes::PathwayNode;
use GUS::Model::DoTS::Gene;

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

  my $tablesDependedOn = [['Core.TableInfo',  'To store a reference to tables that have Node records (ex. EC Numbers, Coumpound IDs'], ['DoTS.Gene', 'To look up row_id for referenced genes']];

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
                        cvsRevision => '$Revision: 16643 $',
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
  my ($self, $pathwayFile, $extDbRlsId, $geneExtDbRlsId) = @_;

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
  my $geneTableId = $self->className2TableId("DoTS::Gene");
  my $nodeTypeId = 213766;  # TODO : lookup in SRes.OntologyTerm
  foreach my $n (keys %$nodes) {
    my $nodeType = $nodes->{$n}->{TYPE};
    next if ($nodeType ne 'gene');
    
    my ($taxon, $entrezGeneId) = split /:/, $nodes->{$n}->{SOURCE_ID};
    my ($geneSymbol, $geneId) = $self->fetchGeneDetails($entrezGeneId, $geneExtDbRlsId);
    if (!$geneSymbol) {
      $self->log("Unable to find GENE: $entrezGeneId in DB");
      next;
    }

    my $pathwayNode = GUS::Model::SRes::PathwayNode->new({display_label => $geneSymbol,
							  table_id => $geneTableId,
							  row_id => $geneId,
							  pathway_node_type_id => $nodeTypeId});

    $pathwayNode->setParent($pathway);
#     $self->log(Dumper($nodes->{$n})) if ($nodes->{$n}->{TYPE} eq 'gene');    
  }

  $pathway->submit() if (!$pathway->retrieveFromDB());
  $self->undefPointerCache();

}#subroutine

sub fetchGeneDetails {
  my ($self, $entrezGeneId, $extDbRlsId) = @_;
  my $gene = GUS::Model::DoTS::Gene->new({source_id => $entrezGeneId,
					  external_database_release_id => $extDbRlsId});
  my $geneSymbol = undef;
  my $geneId = undef;
  
  if ($gene->retrieveFromDB()) {
    $geneSymbol = $gene->getGeneSymbol();
    $geneId = $gene->getGeneId();
  }

  return $geneSymbol, $geneId
}





sub undoTables {
  my ($self) = @_;

  return (
	  'SRes.Pathway',
	  'SRes.PathwayNode',
	 );
}


1;

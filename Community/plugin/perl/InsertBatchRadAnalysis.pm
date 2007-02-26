package GUS::Community::Plugin::InsertBatchRadAnalysis;
use base qw(GUS::Supported::Plugin::InsertRadAnalysis);

use strict;

use GUS::PluginMgr::Plugin;

use GUS::Community::RadAnalysis::RadAnalysisError;

use XML::Simple;

use  GUS::ObjRelP::DbiDatabase;

use Data::Dumper;

my $purposeBrief = <<BRIEF;
The purpose of this plugin is to run some process and capture the Result
as a RAD::Analysis
BRIEF

my $purpose = <<PLUGIN_PURPOSE;
The purpose of this plugin is to run a GUS::Community::RadAnalysis Process and capture the Result
as a RAD::Analysis.  The xml config file contains everything the process
needs to run.  The module/class (specified in the config) is responsible
for tracking the inputs (creating RAD::Protocol and LogicalGroups), serves
as a wrapper around the process, and keeps track of the resulting file.  

This Plugin creates the Module and calls the process method.
For each result...it then submits the Inputs, Translates the Result file, and calls the run() from
the SUPERCLASS.
PLUGIN_PURPOSE

my $tablesAffected =  [['RAD::Analysis', 'Enters a row representing this analysis here'], 
                       ['RAD::AssayAnalysis', 'Enters rows here linking this analysis to all relevant assays, if the LogicalGroups input into the analysis consists of quantifications, or acquisitions, or assays'], 
                       ['RAD::AnalysisParam', 'Enters the values of the protocol parameters for this analysis here'], 
                       ['RAD::AnalysisQCParam', 'Enters the values of the protocol quality control parameters for this analysis here'], 
                       ['RAD::AnalysisInput', 'Enters the input(s) of this analysis here'], 
                       ['RAD::AnalysisResultImp', 'Enters the results of this analysis here'],
                       ['RAD::LogicalGroup', 'The input group(s) to the analysis'], 
                       ['RAD::LogicalGroupLink', 'The members of the logical group(s) input into the analysis'],
                       ['RAD::Protocol', 'The analysis protocol used'], ['RAD::ProtocolStep', 'The components of the analysis protocol used, if the latter is an ordered series of protocols'], 
                       ['RAD::ProtocolParam', 'The parameters for the protocol used or for its components'],
                       ['RAD::ProtocolQCParam', 'The quality control parameters for the protocol used or for its components'], 
                      ];

my $tablesDependedOn = [['SRes::Contact', 'The researcher or organization who performed this analysis'], 
                        ['Study::OntologyEntry', 'The protocol_type of the protocol used'],
                        ['Core::TableInfo', 'The table whose entries the analysis results refer to'], 
                        ['Core::DatabaseInfo', 'The name of the GUS space containing the table whose entries the analysis results refer to']
                       ]; 


my $howToRestart = <<PLUGIN_RESTART;
This plugin has no restart facility.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
PLUGIN_NOTES

my $documentation = { purpose          => $purpose,
		      purposeBrief     => $purposeBrief,
		      tablesAffected   => $tablesAffected,
		      tablesDependedOn => $tablesDependedOn,
		      howToRestart     => $howToRestart,
		      failureCases     => $failureCases,
		      notes            => $notes
		    };

my $argsDeclaration = 
  [
   fileArg({name           => 'configFile',
            descr          => 'Configuration for Analysis',
            reqd           => 1,
            constraintFunc => undef,
            isList         => 0, 
            format         => undef,
            mustExist      => 1,
           }),

  ];

# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self    = {};
  bless($self, $class);

  $self->initialize({requiredDbVersion => 3.5,
                     cvsRevision       => '$Revision: 4281 $',
                     name              => ref($self),
                     argsDeclaration   => $argsDeclaration,
                     documentation     => $documentation
                    });

  return $self;
}

# ----------------------------------------------------------------------

sub run {
  my ($self) = @_;

  my $config = $self->getArg('configFile');
  my $xml = XMLin($config,  'ForceArray' => 1);

  my $analysisCount;

  foreach my $process (@{$xml->{process}}) {
    my $class = $process->{class};
    my $properties = $process->{property};

    my $args = {};
    foreach my $property (keys %$properties) {
      $args->{$property} = $properties->{$property}->{value};
    }

    eval "require $class";

    my $processer = eval {
      $class->new($args);
    };
    if($@) {
      $self->error("Could not insantiate class [$class]:  $@");
    }

    my $results = $processer->process();
    $analysisCount = $analysisCount + scalar(@$results);

    # Each Process Result is an analysis
    foreach my $result (@$results) {
      unless($result->isValid()) {
        log($result->toString()) if($self->getArg('debug'));
        $self->error("The Process Did NOT yield a valid result\n");
      }

      $result->submit();

      my $dataFile = $result->writeAnalysisDataFile();
      my $configFile = $result->writeAnalysisConfigFile();
      my $resultView = $result->getResultView(); 

      # set the Args for the Superclass
      $self->setArg('subclass_view', $resultView);
      $self->setArg('cfg_file', $configFile);
      $self->setArg('data_file', $dataFile);

      $self->setArg('restart', undef);
      $self->setArg('analysis_id', undef);
      $self->setArg('testnum', undef);

      # Call the Run Method from the Superclass
      $self->SUPER::run();
    }
  }

  my $processNum = scalar(@{$xml->{process}});

  return "Completed $processNum Process Modules consisting of $analysisCount analyses";
}

#--------------------------------------------------------------------------------
# this undo is a little tricky because the subclass_view of AnalysisResultImp may be different 
# across db instances.
sub _undoTables {
  my ($self) = @_;

  my $database;
  unless($database = GUS::ObjRelP::DbiDatabase->getDefaultDatabase()) {
    $self->error("Must provide a Default DbiDatabase to run this Undo()");
  }

  my $dbh = $database->getQueryHandle();
  my $sql = "select distinct subclass_view from Rad.ANALYSISRESULTIMP";

  my $sh = $dbh->prepare($sql);
  $sh->execute();

  my @tables;

  while(my ($view) = $sh->fetchrow_array()) {
    push @tables, "RAD.$view";
  }

  $sh->finish();

  my @rest = ( 'RAD.LogicalGroupLink',
               'RAD.AnalysisInput',
               'RAD.AnalysisParam',
               'RAD.AnalysisQCParam',
               'RAD.AssayAnalysis',
               'RAD.Analysis',
               'RAD.LogicalGroupLink',
               'RAD.LogicalGroup',
             );

  return @tables, @rest;
}


1;


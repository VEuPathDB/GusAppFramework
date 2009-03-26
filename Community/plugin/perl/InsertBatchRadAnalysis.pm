package GUS::Community::Plugin::InsertBatchRadAnalysis;
use base qw(GUS::Supported::Plugin::InsertRadAnalysis);

use strict;

use GUS::PluginMgr::Plugin;

use GUS::Community::RadAnalysis::RadAnalysisError;

use XML::Simple;

use  GUS::ObjRelP::DbiDatabase;

use Error qw (:try);

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
   fileArg({name           => 'pathToExecutable',
            descr          => 'Path which is passed to the AbstractProcessor.  It becomes the responsibliity of the individual modules to use this',
            reqd           => 0,
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
                     cvsRevision       => '$Revision$',
                     name              => ref($self),
                     argsDeclaration   => $argsDeclaration,
                     documentation     => $documentation
                    });

  return $self;
}

# ----------------------------------------------------------------------

sub run {
  my ($self) = @_;

  my $analyses = $self->parseConfig();

  my $analysisCount;

  foreach my $analysis (@$analyses) {
    my $class = $analysis->{class};
    my $args = $analysis->{arguments};

    eval "require $class";

    my $processor = eval {
      $class->new($args);
    };
    if($@) {
      $self->error("Could not insantiate class [$class]:  $@");
    }

    if(my $pathToExecutable = $self->getArg('pathToExecutable')) {
      $processor->setPathToExecutable($pathToExecutable);
    }

    try {
      my $results = $processor->process();

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
        my $orderInput = $result->getOrderInput();

        # set the Args for the Superclass
        $self->setArg('subclass_view', $resultView);
        $self->setArg('cfg_file', $configFile);
        $self->setArg('data_file', $dataFile);
        $self->setArg('orderInput', $orderInput);

        $self->setArg('restart', undef);
        $self->setArg('analysis_id', undef);
        $self->setArg('testnum', undef);

        # Call the Run Method from the Superclass
        $self->SUPER::run();
      }
    } catch GUS::Community::RadAnalysis::DataFileEmptyError with {
      my $e = shift;
      $self->log($e->text());
    };
  }

  my $processNum = scalar(@$analyses);

  my $description = "Completed $processNum Process Modules consisting of $analysisCount analyses\n" . $self->getResultDescr();

  return $description;
}

#--------------------------------------------------------------------------------

sub parseConfig {
  my ($self) = @_;

  my $config = $self->getArg('configFile');
  my $xml = XMLin($config,  'ForceArray' => 1);

  my $defaults = $xml->{defaultArguments}->[0]->{property};
  my $analyses = $xml->{process};

  foreach my $analysis (@$analyses) {
    my $args = {};

    foreach my $default (keys %$defaults) {
      my $defaultValue = $defaults->{$default}->{value};

      if(ref($defaultValue) eq 'ARRAY') {
        my @ar = @$defaultValue;
        $args->{$default} = \@ar;
      }
      else {
        $args->{$default} = $defaultValue;
      }
    }

    my $properties = $analysis->{property};

    foreach my $property (keys %$properties) {
      my $value = $properties->{$property}->{value};
 
     if(ref($value) eq 'ARRAY') {
        push(@{$args->{$property}}, @$value);
      }
      else {
        $args->{$property} = $value;
      }
    }

    $analysis->{arguments} = $args;
  }

  return $analyses;
}

#--------------------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;

  return ('RAD.AnalysisResultImp', 
          'RAD.AnalysisQCParam', 
          'RAD.AnalysisParam', 
          'RAD.AnalysisInput', 
          'RAD.AssayAnalysis', 
          'RAD.Analysis',
          'RAD.LogicalGroupLink',
          'RAD.LogicalGroup',
         );
}

1;



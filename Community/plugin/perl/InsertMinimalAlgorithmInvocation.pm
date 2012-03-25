package GUS::Community::Plugin::InsertMinimalAlgorithmInvocation;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use GUS::PluginMgr::Plugin;

use GUS::Model::Core::Algorithm;
use GUS::Model::Core::AlgorithmImplementation;
use GUS::Model::Core::AlgorithmInvocation;

my $argsDeclaration =
[

   stringArg({name           => 'AlgorithmName',
              descr          => 'Unique Name for the Core::Algorithm',
              reqd           => 1,
              constraintFunc => undef,
              isList         => 0, }),

   stringArg({name           => 'AlgorithmDescription',
              descr          => 'Unique Name for the Core::Algorithm',
              reqd           => 0,
              constraintFunc => undef,
              isList         => 0, }),

   stringArg({name           => 'AlgImpVersion',
              descr          => 'Unique Version of the Core::AlgorithmImplementation',
              reqd           => 1,
              constraintFunc => undef,
              isList         => 0, }),

   stringArg({name           => 'AlgImpCvsRevision',
              descr          => 'CVS Revision of the Core::AlgorithmImplementation',
              reqd           => 0,
              constraintFunc => undef,
              isList         => 0, }),

   stringArg({name           => 'AlgImpCvsTag',
              descr          => 'Cvs Tag of the Core::AlgorithmImplementation',
              reqd           => 0,
              constraintFunc => undef,
              isList         => 0, }),

   stringArg({name           => 'AlgImpExecutable',
              descr          => 'Executable of the Core::AlgorithmImplementation',
              reqd           => 0,
              constraintFunc => undef,
              isList         => 0, }),

   stringArg({name           => 'AlgImpExecutableMD5',
              descr          => 'Executable MD5 of the Core::AlgorithmImplementation',
              reqd           => 0,
              constraintFunc => undef,
              isList         => 0, }),

   stringArg({name           => 'AlgImpDescription',
              descr          => 'Description of the Core::AlgorithmImplementation',
              reqd           => 0,
              constraintFunc => undef,
              isList         => 0, }),

   stringArg({name           => 'AlgInvocStart',
              descr          => 'Date for the AlgorithmInvocation start (xxxx-xx-xx)',
              reqd           => 1,
              constraintFunc => undef,
              isList         => 0, }),

   stringArg({name           => 'AlgInvocEnd',
              descr          => 'Date for the AlgorithmInvocation End (xxxx-xx-xx)',
              reqd           => 1,
              constraintFunc => undef,
              isList         => 0, }),

   stringArg({name           => 'AlgInvocCpusUsed',
              descr          => 'Cpus Used for the AlgorithmInvocation',
              reqd           => 0,
              constraintFunc => undef,
              isList         => 0, }),

   stringArg({name           => 'AlgInvocCpuTime',
              descr          => 'Cpu Time for the AlgorithmInvocation',
              reqd           => 0,
              constraintFunc => undef,
              isList         => 0, }),

   stringArg({name           => 'AlgInvocResult',
              descr          => 'Result for the AlgorithmInvocation',
              reqd           => 1,
              constraintFunc => undef,
              isList         => 0, }),

   stringArg({name           => 'AlgInvocCommentString',
              descr          => 'Comment String for the AlgorithmInvocation',
              reqd           => 0,
              constraintFunc => undef,
              isList         => 0, }),

];

my $purpose = <<PURPOSE;
Retrieves/adds Core::Algorithm and Core::AlgorithmImplemenation... then adds a row in Core::AlgorithmInvocation. 
PURPOSE

my $purposeBrief = <<PURPOSE_BRIEF;
Retrieves/adds Core::Algorithm and Core::AlgorithmImplemenation... then adds a row in Core::AlgorithmInvocation. 
PURPOSE_BRIEF

my $notes = <<NOTES;
The name for Core::Algorithm and the version of the Core::AlgorithmImplemenation should be unique and will be used to retrieve the rows.  (ie. If the rows in Algorithm and AlgorithmImplementation exist, then provide the Algorithm Name, AlgorithemImplementation Version, and the Invocation Stuff.  TODO:  Add code to handle Parameters and ParamKeys etc...
NOTES

my $tablesAffected = <<TABLES_AFFECTED;
Core::Algorithm
Core::AlgorithmImplementation
Core::AlgorithmInvocation
TABLES_AFFECTED

my $tablesDependedOn = <<TABLES_DEPENDED_ON;
TABLES_DEPENDED_ON

my $howToRestart = <<RESTART;
There are no restart facilities for this plugin
RESTART

my $failureCases = <<FAIL_CASES;
FAIL_CASES

my $documentation = { purpose          => $purpose,
		      purposeBrief     => $purposeBrief,
		      notes            => $notes,
		      tablesAffected   => $tablesAffected,
		      tablesDependedOn => $tablesDependedOn,
		      howToRestart     => $howToRestart,
		      failureCases     => $failureCases };

my ($algCount, $algImpCount, $algInvCount);

# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  $self->initialize({ requiredDbVersion => 3.6,
		      cvsRevision       => '$Revision$',
		      name              => ref($self),
		      argsDeclaration   => $argsDeclaration,
		      documentation     => $documentation});

  return $self;
}

# ======================================================================

sub run {
  my ($self) = @_;

  my $alg = $self->_getAlgorithm();
  my $algImp = $self->_getAlgorithmImplementation($alg);

  my $algInvocation = $self->_getAlgorithmInvocation($algImp);

  $alg->submit() if $algInvocation;

  return("Inserted $algCount rows into Core::Algorithm,$algImpCount into Core::AlgorithmImplementation, and $algInvCount into Core::AlgorithmInvocation.");
}

sub _getAlgorithm {
  my ($self) = @_;

  my $algName = $self->getArg('AlgorithmName');
  my $algDesc = $self->getArg('AlgorithmDescription');

  my $alg = GUS::Model::Core::Algorithm->
    new({ name => $algName });

  if(!$alg->retrieveFromDB()) {
    $alg->setDescription($algDesc);
    $self->log("Algorithm $algName not found...Creating new");
    $algCount++;
  }

  return($alg);
}

sub _getAlgorithmImplementation {
  my ($self, $alg) = @_;

  my $algImpVersion = $self->getArg('AlgImpVersion');

  my $algImpCvsRevision = $self->getArg('AlgImpCvsRevision');
  my $algImpCvsTag = $self->getArg('AlgImpCvsTag');
  my $algImpExecutable = $self->getArg('AlgImpExecutable');
  my $algImpExecutableMD5 = $self->getArg('AlgImpExecutableMD5');
  my $algImpDescription = $self->getArg('AlgImpDescription');

  my $algImp = GUS::Model::Core::AlgorithmImplementation->
    new({ VERSION => $algImpVersion });

  $algImp->setParent($alg);

  unless($algImp->retrieveFromDB()) {
    $self->log("AlgorithmImplementation version $algImpVersion not found...Creating new");
    $algImp->setCvsRevision($algImpCvsRevision);
    $algImp->setCvsTag($algImpCvsTag);
    $algImp->setExecutable($algImpExecutable);
    $algImp->setExecutableMd5($algImpExecutableMD5);
    $algImp->setDescription($algImpDescription);

    $algImpCount++;
  }

  return($algImp);
}

sub _getAlgorithmInvocation {
  my ($self, $algImp) = @_;

  my $algInvStart = $self->getArg('AlgInvocStart');
  my $algInvEnd = $self->getArg('AlgInvocEnd');
  my $algInvCpusUsed = $self->getArg('AlgInvocCpusUsed');
  my $algInvCpuTime = $self->getArg('AlgInvocCpuTime');
  my $algInvResult = $self->getArg('AlgInvocResult');
  my $algInvComment = $self->getArg('AlgInvocCommentString');

  my $algInv = GUS::Model::Core::AlgorithmInvocation->
    new({ START_TIME => $algInvStart,	
          END_TIME => $algInvEnd,	
          CPUS_USED => $algInvCpusUsed,
          CPU_TIME => $algInvCpuTime,
          RESULT => $algInvResult,
          COMMENT_STRING => $algInvComment,
        });

  $algInv->setParent($algImp);

  if($algInv->retrieveFromDB()) {
    $self->log("Identical Algorithm Invocation Exists Already\n");
    return 0;
}else{
  $algInvCount++;
  return($algInv);
}



}

sub undoTables {
  my ($self) = @_;

  return (
	 );
}

1;


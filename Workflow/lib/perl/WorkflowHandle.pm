package GUS::Workflow::WorkflowHandle;

@ISA = qw(GUS::Workflow::Base);
use strict;
use GUS::Workflow::Base;
use XML::Simple;
use Data::Dumper;

##
## lite workflow object (a handle on workflow row in db) used in three contexts:
##  - quick reporting of workflow state
##  - reseting the workflow
##  - workflowstep UI command changing state of a step
##
## (it avoids the overhead and stringency of parsing and validating
## all workflow steps)

# very light reporting of state of workflow
sub reportState {
  my ($self) = @_;

  $self->getDbState();

  print "
Workflow '$self->{name} $self->{version}'
workflow_id:           $self->{workflow_id}
state:                 $self->{state}
process_id:            $self->{process_id}
xml_file_digest:       $self->{xml_file_digest}
\n\n";
}

sub checkXmlFileDigest {
  my ($self) = @_;
  
  $self->error("One or more Workflow XML files have changed since controller startup.  Please start or restart controller.") unless
      $self->getDbXmlFileDigest() eq $self->getXmlFileDigest();
}

sub getDbXmlFileDigest {
  my ($self) = @_;

  $self->getDbState();
  return $self->{xml_file_digest};
}

sub getXmlFileDigest {
  my ($self) = @_;

  my $rootXmlFile = $self->getWorkflowConfig('workflowXmlFile');
  $rootXmlFile = "$ENV{GUS_HOME}/lib/xml/workflow/$rootXmlFile";
  my $xmlFiles = [$rootXmlFile];
  $self->findSubgraphXmlFiles($rootXmlFile, $xmlFiles);
  my @sortedFiles = sort @$xmlFiles;
  my $cmd = "cat " . join(" ", @sortedFiles) . " | md5sum";
  my $md5 = $self->runCmd($cmd);
  chomp $md5;
  $md5 =~ s/^(\S+).+/$1/;

  return $md5;
}

sub findSubgraphXmlFiles {
  my ($self, $parentXmlFile, $xmlFiles) = @_;
  my $simple = XML::Simple->new();
  my $data = $simple->XMLin($parentXmlFile, forcearray => 1);
#  print Dumper($data);

  # make each step object, remembering dependencies as a string
  foreach my $subgraph (values %{$data->{subgraph}}) {
    my $xmlFile = "$ENV{GUS_HOME}/lib/xml/workflow/$subgraph->{xmlFile}";
    push(@$xmlFiles, $xmlFile);
    $self->findSubgraphXmlFiles($xmlFile, $xmlFiles);
  }
}

sub getDbState {
  my ($self) = @_;
  if (!$self->{workflow_id}) {
    $self->{name} = $self->getWorkflowConfig('name');
    $self->{version} = $self->getWorkflowConfig('version');
    my $sql = "
select workflow_id, state, process_id, xml_file_digest, undo_step_id
from apidb.workflow
where name = '$self->{name}'
and version = '$self->{version}'
";
    ($self->{workflow_id}, $self->{state}, $self->{process_id},$self->{xml_file_digest}, $self->{undo_step_id})
      = $self->runSqlQuery_single_array($sql);
    $self->error("workflow '$self->{name}' version '$self->{version}' not in database")
      unless $self->{workflow_id};
  }
}

sub getStepNamesFromPattern {
    my ($self, $stepNamePattern) = @_;

    $self->getId();
    my $names;
    my $sql = 
"SELECT name
FROM apidb.WorkflowStep
WHERE name like '$stepNamePattern'
AND workflow_id = $self->{workflow_id}";

    my $stmt = $self->getDbh()->prepare($sql);
    $stmt->execute();
    while (my ($name) = $stmt->fetchrow_array()) {
	push(@$names, $name);
    }
    return $names;
}

sub getStepNamesFromFile {
  my ($self, $file) = @_;

  my $homeDir = $self->getWorkflowHomeDir();

  my $files = [];
  open(F, $file) || die "Cannot open steps file '$file'";
  while(<F>) {
    next if /^\#/;
    chomp;
    push(@$files, $_);
  }
  return $files;
}

sub getId {
  my ($self) = @_;

  $self->getDbState();
  return $self->{workflow_id};
}

# brute force reset of workflow.  for developers only
sub reset {
  my ($self) = @_;

  my $homeDir = $self->getWorkflowHomeDir();
  foreach my $dir ("logs", "steps", "externalFiles") {
    my $cmd = "rm -rf $homeDir/$dir";
    $self->runCmd($cmd) if -e "$homeDir/$dir";
    print "$cmd\n";
  }

  $self->getDbState();
  my $sql = "delete from apidb.workflowstep where workflow_id = $self->{workflow_id}";
  $self->runSql($sql);
  print "$sql\n";
  $sql = "delete from apidb.workflow where workflow_id = $self->{workflow_id}";
  $self->runSql($sql);
  print "$sql\n";
}

sub runCmd {
    my ($self, $cmd) = @_;

    my $output = `$cmd`;
    my $status = $? >> 8;
    $self->error("Failed with status $status running: \n$cmd") if ($status);
    return $output;
}


sub getInitOfflineSteps {
    my ($self) = @_;
    return $self->getStepNamesFromFile($self->getWorkflowHomeDir() . 'config/initOfflineSteps');
}

sub getInitStopAfterSteps {
    my ($self) = @_;
    return $self->getStepNamesFromFile($self->getWorkflowHomeDir() . 'config/initStopAfterSteps');
}

1;

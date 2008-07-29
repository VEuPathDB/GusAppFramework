package GUS::Pipeline::Workflow::SampleSteps::InsertSignalP;

@ISA = (GUS::Pipeline::Workflow::WorkflowStepInvoker);
use strict;
use GUS::Pipeline::Workflow::WorkflowStepInvoker;

sub run {
  my ($self) = @_;

  my $name = $self->getConfig('name');
  my $release = $self->getConfig('release');

  $self->runCmd("createDirs --projectDir $name --release $release");
}

sub restart {
}

sub undo {

}

sub getConfigDeclaration {
  my $properties =
    [
     # [name, default, description]
    ['inputFile', , ],
    ['soVersion', , ],
    ['soCvsVersion', , ],
    ['commit', , ],
    ];
  return $properties;
}

sub getDocumentation {
}

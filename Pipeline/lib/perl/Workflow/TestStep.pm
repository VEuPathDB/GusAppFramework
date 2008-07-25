package GUS::Pipeline::Workflow::TestStep;

@ISA = (GUS::Pipeline::Workflow::WorkflowStepInvoker);
use strict;
use GUS::Pipeline::Workflow::WorkflowStepInvoker;

sub run {
  my ($self) = @_;

  my $name = $self->getConfig('name');
  my $wait = $self->getConfig('wait');

  $self->runCmd("echo $name");
  sleep($wait);
}

sub restart {
}

sub undo {

}

sub getConfigDeclaration {
  my $properties =
    [
     # [name, default, description]
     ['name', "", ""],
     ['wait', "", ""],
    ];
  return $properties;
}

sub getDocumentation {
}

package GUS::Pipeline::Workflow::SampleSteps::Wget;

@ISA = (GUS::Pipeline::Workflow::WorkflowStepInvoker);
use strict;
use GUS::Pipeline::Workflow::WorkflowStepInvoker;

sub run {
  my ($self) = @_;

  my $name = $self->getConfig('wgetArgs');

  $self->runCmd("");
}

sub restart {
}

sub undo {

}

sub getConfigDeclaration {
  my $properties =
    [
     # [name, default, description]
    ['wgetArgs', , ],
    ];
  return $properties;
}

sub getDocumentation {
}

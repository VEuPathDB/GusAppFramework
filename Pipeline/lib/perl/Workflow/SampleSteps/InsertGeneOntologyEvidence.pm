package GUS::Pipeline::Workflow::SampleSteps::InsertGeneOntologyEvidence;

@ISA = (GUS::Pipeline::Workflow::WorkflowStepInvoker);
use strict;
use GUS::Pipeline::Workflow::WorkflowStepInvoker;

sub run {
  my ($self) = @_;

  my $oboFile = $self->getConfig('oboFile');
  my $wait = $self->getConfig('wait');

  my $args = "--oboFile $oboFile";

  $self->runPlugin("ApiCommonData::Load::Plugin::InsertGOEvidenceCodesFromObo", $args);
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
    ['oboFile', , ],
    ['wait', , ],
    ];
  return $properties;
}

sub getDocumentation {
}

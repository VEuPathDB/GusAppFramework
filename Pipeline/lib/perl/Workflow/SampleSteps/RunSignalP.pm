package GUS::Pipeline::Workflow::SampleSteps::RunSignalP;

@ISA = (GUS::Pipeline::Workflow::WorkflowStepInvoker);
use strict;
use GUS::Pipeline::Workflow::WorkflowStepInvoker;

sub run {
  my ($self) = @_;

  my $binPath = $self->getConfig('binPath');
  my $options = $self->getConfig('options');
  my $seqFile = $self->getConfig('seqFile');
  my $outFile = $self->getConfig('outFile');

  $self->runCmd("echo 'runSignalP --binPath $binPath --options $options --seqFile $seqFile --outFile $outFile' > output.txt");
}

sub restart {
}

sub undo {

}

sub getConfigDeclaration {
  my $properties =
    [
     # [name, default, description]
    ['binPath', , ],
    ['options', , ],
    ['seqFile', , ],
    ['outFile', , ],
    ];
  return $properties;
}

sub getDocumentation {
}

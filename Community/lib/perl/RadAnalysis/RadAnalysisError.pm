package GUS::Community::RadAnalysis::RadAnalysisError;
use base qw(Error);

use overload ('""' => 'stringify');

=head1 GUS::Community::RadAnalysis::RadAnalysisError

Error package for a Rad Analysis

=cut

sub new {
  my ($self, $m) = @_;

  my $name = $self;
  $name =~ s/^.+:://;

  my $text = "**** $name:  $m\n\n";

  my @args = ();

  local $Error::Depth = $Error::Depth + 1;
  local $Error::Debug = 1;  # Enables storing of stacktrace

  $self->SUPER::new(-text => $text, @args);
}
1;

#--------------------------------------------------------------------------------

package GUS::Community::RadAnalysis::ProcessorError;
use base qw(GUS::Community::RadAnalysis::RadAnalysisError);
1;

package GUS::Community::RadAnalysis::DataFileEmptyError;
use base qw(GUS::Community::RadAnalysis::ProcessorError);
1;

#--------------------------------------------------------------------------------

package GUS::Community::RadAnalysis::InputError;
use base qw(GUS::Community::RadAnalysis::RadAnalysisError);
1;

package GUS::Community::RadAnalysis::FileAccessError;
use base qw(GUS::Community::RadAnalysis::RadAnalysisError);
1;

package GUS::Community::RadAnalysis::DirectoryAccessError;
use base qw(GUS::Community::RadAnalysis::RadAnalysisError);
1;

package GUS::Community::RadAnalysis::SqlError;
use base qw(GUS::Community::RadAnalysis::RadAnalysisError);
1;

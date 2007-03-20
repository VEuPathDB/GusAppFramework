package GUS::PluginMgr::PluginError;
use base qw(Error);

use overload ('""' => 'stringify');

sub new {
  my ($class, $m) = @_;

  my $type = ($class =~ /User/)?  "USER ERROR" : "FATAL";
  my $text = "$type: $m";
  my @args = ();

  local $Error::Depth = $Error::Depth + 1;
  local $Error::Debug = 1;  # Enables storing of stacktrace

  $class->SUPER::new(-text => $text, @args);
}
1;

package GUS::PluginMgr::PluginUserError;
use base qw(GUS::PluginMgr::PluginError);
1;

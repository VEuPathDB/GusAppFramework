package GUS::Pipeline::NfsCluster;

use strict;
use File::Basename;
use CBIL::Util::Utils;
use GUS::Pipeline::Manager;

#############################################################################
#          Public Methods
#############################################################################

sub new {
    my ($class) = @_;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub setManager {
  my ($self, $mgr) = @_;

  $self->{mgr} = $mgr;
}

#  param fromDir  - the directory in which fromFile resides
#  param fromFile - the basename of the file or directory to copy
sub copyTo {
    my ($self, $fromDir, $fromFile, $toDir) = @_;

    $self->{mgr}->error("$fromDir/$fromFile doesn't exist\n") unless -e $fromFile;
    $self->{mgr}->error("$toDir doesn't exist\n") unless -d $toDir;

    $self->{mgr}->runCmd("cp $fromDir/$fromFile $toDir");
}

#  param fromDir  - the directory in which fromFile resides
#  param fromFile - the basename of the file or directory to copy
sub copyFrom {
    my ($self, $fromDir, $fromFile, $toDir) = @_;

    $self->copyTo($fromDir, $fromFile, $toDir);
}

sub runCmdOnCluster {
  my ($self, $cmd) = @_;

  $self->{mgr}->runCmd($cmd);
}

1;

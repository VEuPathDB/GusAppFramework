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
        # buildDir, release/speciesNickname, serverPath
        
    chdir $fromDir || $self->{mgr}->error("Can't chdir $fromDir\n" . __FILE__ . " line " . __LINE__ . "\n\n");

    $self->{mgr}->error("origin file or directory $fromDir/$fromFile doesn't exist\n" . __FILE__ . " line " . __LINE__ . "\n\n") unless -e "$fromDir/$fromFile";
    $self->{mgr}->error("destination directory $toDir doesn't exist\n" . __FILE__ . " line " . __LINE__ . "\n\n") unless -d $toDir;
    
    $self->{mgr}->runCmd("tar cf - $fromFile | (cd $toDir &&  tar xBf -)");
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

package GUS::Pipeline::SshCluster;

use strict;
use File::Basename;
use CBIL::Util::Utils;

#############################################################################
#          Public Methods
#############################################################################

sub new {
    my ($class, $server, $user) = @_;

    my $self = {};
    bless $self, $class;

    $self->{server} = $server;
    $self->{user} = $user;
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

    chdir $fromDir || $self->{mgr}->error("Can't chdir $fromDir\n");
    $self->{mgr}->error("destination directory $fromDir/$fromFile doesn't exist\n") unless -e "$fromDir/$fromFile";


    my $user = "$self->{user}\@" if $self->{user};
    my $ssh_to = "$user$self->{server}";

    # workaround scp problems
    $self->{mgr}->runCmd("tar cf - $fromFile | gzip -c | ssh -2 $ssh_to 'cd $toDir; gunzip -c | tar xf -'");

   # $self->runCmd("tar cf - $fromFile | ssh $server 'cd $toDir; tar xf -'");
}

#  param fromDir  - the directory in which fromFile resides
#  param fromFile - the basename of the file or directory to copy
sub copyFrom {
    my ($self, $fromDir, $fromFile, $toDir) = @_;

    # workaround scp problems
    chdir $toDir || $self->{mgr}->error("Can't chdir $toDir\n");

    my $user = "$self->{user}\@" if $self->{user};
    my $ssh_target = "$user$self->{server}";

    $self->{mgr}->runCmd("ssh -2 $ssh_target 'cd $fromDir; tar cf - $fromFile | gzip -c' | gunzip -c | tar xf -");

#    $self->runCmd("ssh $server 'cd $fromDir; tar cf - $fromFile' | tar xf -");
    $self->{mgr}->error("$toDir/$fromFile wasn't successfully copied from liniac\n") unless -e "$toDir/$fromFile";
}

sub runCmdOnCluster {
  my ($self, $cmd) = @_;

  my $user = "$self->{user}\@" if $self->{user};
  my $ssh_target = "$user$self->{server}";

  $self->{mgr}->runCmd("ssh -2 $ssh_target '$cmd'");
}

1;

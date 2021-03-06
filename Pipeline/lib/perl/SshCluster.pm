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
          # buildDIr, release/speciesNickname, serverPath
  
    chdir $fromDir || $self->{mgr}->error("Can't chdir $fromDir\n" . __FILE__ . " line " . __LINE__ . "\n\n");
    
    my @arr = glob("$fromFile");
    $self->{mgr}->error("origin directory $fromDir/$fromFile doesn't exist\n" . __FILE__ . " line " . __LINE__ . "\n\n") unless (@arr >= 1);


    my $user = "$self->{user}\@" if $self->{user};
    my $ssh_to = "$user$self->{server}";

    print STDERR "tar cf - $fromFile | gzip -c | ssh -2 $ssh_to 'cd $toDir; gunzip -c | tar xf -' \n" . __FILE__ . " line " . __LINE__ . "\n\n";
    
    # workaround scp problems
    $self->{mgr}->runCmd("tar cf - $fromFile | gzip -c | ssh -2 $ssh_to 'cd $toDir; gunzip -c | tar xf -'");

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
    my @arr = glob("$toDir/$fromFile");
    $self->{mgr}->error("$toDir/$fromFile wasn't successfully copied from liniac\n") unless (@arr >= 1);
}

sub runCmdOnCluster {
  my ($self, $cmd) = @_;

  my $user = "$self->{user}\@" if $self->{user};
  my $ssh_target = "$user$self->{server}";

  $self->{mgr}->runCmd("ssh -2 $ssh_target '$cmd'");
}

1;

#!@perl@

# -----------------------------------------------------------------------
# JavaCommandLineHelper.pm
#
# A utility for helping wrap Java apps in perl
#
# $Author:$
# $Id:$
# -----------------------------------------------------------------------

package GUS::DBAdmin::JavaCommandLineHelper;

use strict;
use Carp;

sub new {
    my ($class, $command, $GUS_HOME, $PROJECT_HOME) = @_;

    if ( $GUS_HOME eq '' ) { $GUS_HOME = $ENV{GUS_HOME}; }
    if ( $PROJECT_HOME eq '' ) {$PROJECT_HOME = $ENV{PROJECT_HOME}; }

    my $self = { 
	GUS_HOME => $GUS_HOME,
	PROJECT_HOME => $PROJECT_HOME,
	command => $command };
    bless $self, $class;

    $self->useArgs(1);

    return $self;
}

sub setClasspath {
    my ($self, @dirs) = @_;
    
    my $CLASSPATH = "";

    foreach my $dir (@dirs) {
	opendir (DIR, $dir) || &confess("Error: Could not open $dir.  Please check the directory exists and try again.");
	while (my $nextFileName = readdir(DIR)) {
	    if ($nextFileName =~ /.*\.jar$/){
		$CLASSPATH .= "$dir/$nextFileName" . ":"
	    }
	}
	closedir(DIR);
    }
    $self->{classpath} = $CLASSPATH;
    return $self->{classpath};
}

sub setCommandName {
    my ($self, $cmdName) = @_;
    $self->{commandName} = $cmdName;
}


sub setMaxMemory {
    my ($self, $maxMemory) = @_;
    $self->{maxMemory} = $maxMemory;
}

sub setLog4jConfig {
    my ($self, $log4jConfig) = @_;
    $self->{log4jConfig} = $log4jConfig;
}

sub useArgs {
    my ($self, $useArgs) = @_;
    my $args = "";

    if ( $useArgs ) {
	foreach my $arg (@ARGV) {
	    $args .= ($arg =~ /\-/ ? " $arg" : " \"$arg\"");
	}
    }

    $self->{args} = $args;
}

sub setPropertyFile {
    my ($self, $propFile ) = @_;
    $self->{propertyFile} = $propFile;
}

sub getCommand {
    my ($self) = @_;
    
    my $cmd = "java ";

    $cmd .= $self->{maxMemory} eq "" ? '' : "-Xmx".$self->{maxMemory}." ";

    $cmd .= $self->{commandName} eq "" ? '' : "-DcmdName=".$self->{commandName}." ";

    $cmd .= $self->{log4jConfig} eq "" ? "-Dlog4j.configuration=file:".$self->{GUS_HOME}."/config/log4j.properties " :
	"-Dlog4j.configuration=".$self->{log4jConfig}." ";

    $cmd .= $self->{propertyFile} eq "" ?  "-DPROPERTYFILE=".$self->{GUS_HOME}."/config/gus.config " : 
	"-DPROPERTYFILE=".$self->{propertyFile}." ";

    if ( ! $self->{classpath} ) {
	$self->setClasspath( $self->{GUS_HOME}."/lib/java", $self->{GUS_HOME}."/lib/java/db_driver");
    }

    $cmd .= "-classpath ".$self->{classpath}." ".$self->{command}." ".$self->{args};

    return $cmd;
}

sub run {
    my ($self) = @_;
    system($self->getCommand());
}

1;

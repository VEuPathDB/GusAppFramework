##
## InsertElementAnnotation Plugin
## $Id: $
##

package GUS::Community::Plugin::InsertElementAnnotation;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use GUS::PluginMgr::Plugin;

use GUS::Model::RAD::ElementAnnotation;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
    my $argumentDeclaration  =
	[
	 fileArg({name => 'inFile',
		  descr => 'The full path of the element_id to annotation mapping file.',
		  constraintFunc=> undef,
		  reqd  => 1,
		  isList => 0,
		  mustExist => 1,
		  format => ''
	     }),
      stringArg({ name  => 'annotationName',
	          descr => 'The value to set RAD.ElementAnnotation.name to for these entries.',
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 }),
     integerArg({name  => 'restart',
		 descr => 'Line number in the input file from which loading should be resumed (line 1 is the first line after the header, empty lines are counted).',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		}),
     integerArg({name  => 'testnum',
		 descr => 'The number of data lines to read when testing this plugin. Not to be used in commit mode.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		})
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------


sub getDocumentation {
    my $purposeBrief = 'Loads RAD.ElementAnnotation';
    
    my $purpose = "This plugin reads a file mapping element_ids to a specific type of annotation and populated RAD.ElementAnnotation.";
    
    my $tablesAffected = [['RAD::ElementAnnotation', 'Enters a row for each annotated element_id']];

    my $tablesDependedOn = [['RAD::ElementImp', 'Checks for valid element_ids']];

    my $howToRestart = "Loading can be resumed using the I<--restart n> argument where n is the line number in the annotation file of the first row to load upon restarting (line 1 is the first line after the header, empty lines are counted). Alternatively, one can use the plugin GUS::Community::Plugin::Undo to delete all entries inserted by a specific call to this plugin. Then this plugin can be re-run from fresh.";
    
    my $failureCases = "";
    
    my $notes = <<NOTES;
    
=head1 AUTHOR
	
Written by Elisabetta Manduchi.

=head1 COPYRIGHT

Copyright Elisabetta Manduchi, Trustees of University of Pennsylvania 2008. 
NOTES

    my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief, tablesAffected=>$tablesAffected, tablesDependedOn=>$tablesDependedOn, howToRestart=>$howToRestart, failureCases=>$failureCases, notes=>$notes};

  return $documentation;
}

# ----------------------------------------------------------------------
# create and initalize new plugin instance.
# ----------------------------------------------------------------------

sub new {
    my ($class) = @_;
    my $self = {};
    bless($self,$class);
    
    my $documentation = &getDocumentation();
    my $argumentDeclaration    = &getArgumentsDeclaration();
    
    $self->initialize({requiredDbVersion => 3.5,
		       cvsRevision => '$Revision: $',
		       name => ref($self),
		       revisionNotes => '',
		       argsDeclaration => $argumentDeclaration,
		       documentation => $documentation
		       });
    return $self;
}

# ----------------------------------------------------------------------
# run method to do the work
# ----------------------------------------------------------------------

sub run {
    my ($self) = @_;

    if (defined($self->getArg('testnum')) && $self->getArg('commit')) {
	$self->userError("The --testnum argument can only be provided if COMMIT is OFF.");
    }
    
    my $resultDescrip = $self->insertElementAnnotation();
    
    $self->setResultDescr($resultDescrip);
    $self->logData($resultDescrip);
}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------

sub insertElementAnnotation {
    my ($self) = @_;
    my $resultDescrip = '';
    my $file = $self->getArg('inFile');
    my $lineNum = 0;
    my $insertCount = 0;
    my $annotationName = $self->getArg('annotationName');
    my $dbh = $self->getQueryHandle();
    my $sth = $dbh->prepare("select count(*) from RAD.ElementImp where element_id=?") || die $dbh->errstr;
    
    my $fh = IO::File->new("<file") || die "Cannot open file $file";
    my $startLine = defined $self->getArg('restart') ? $self->getArg('restart') : 1;
    my $endLine;
    if (defined $self->getArg('testnum')) {
	$endLine = $startLine-1+$self->getArg('testnum');
    }
    my $line = <$fh>;
    while (my $line=<$fh>) {
	$lineNum++;
	if ($lineNum<$startLine) {
	    next;
	}
	if (defined $endLine && $lineNum>$endLine) {
	    last;
	}
	if ($lineNum % 200 == 0) {
	    $self->log("Working on line $lineNum-th.");
	}
	chomp($line);
	if ($line =~ /^\s+$/) {
	    next;
	}
	my @arr = split(/\t/, $line);
	for (my $i=0; $i<@arr; $i++) {
	    $arr[$i] =~ s/^\s+|\s+$//g;
	}
	my $elementId = $arr[0];
	my $annotation = $arr[1];
	if ($annotation =~ /^\s*$/) {
	    next;
	}
	else {
	    $sth->execute($elementId) || die $dbh->errstr;
	    my ($count) = $sth->fetchrow_array();
	    $sth->finish();
	    if ($count!=1) {
		STDERR->print("Invalid element_id $elementId.\n");
		next;
	    }
	    else {
		my $elementAnnotation = GUS::Model::RAD::ElementAnnotation->new({name => $annotationName, element_id => $elementId, value => $annotation});
		$elementAnnotation->submit();
		$insertCount++;
	    }
	}
    }
    $resultDescrip .= "Entered $insertCount rows in RAD.ElementAnnotation";
    return ($resultDescrip);
}


# ----------------------------------------------------------------------
# Undo
# ----------------------------------------------------------------------

sub undoTables {
  my ($self) = @_;

  return ('RAD.ElementAnnotation');
}

1;

package GUS::Pipeline::TaskRunAndValidate;

##############################################################################
# Subroutines that run and validate Liniac DistribJob Tasks
#
# These subroutines are designed to be called by a script which:
#   - is provided as the 'jobcmd' arg to submitPipelineJob
#   - is therefore called by submitPipelineJob (on the liniac)
#   - will run one or more tasks (ie, is a mini-pipeline on the liniac)
#   - by virtue of using the subroutines, may safely be restarted
#
# The subroutines provides these services:
#   - check for the prior existence of a task's output 
#   - if found, validate it
#   - only run the task if no valid prior output found
#   - after running a task, validate its output, and return validation status
#   - print to the log the details of what is happening, including validation
#
# This allows you to create a script which runs a pipeline of tasks,
# where subsequent tasks depend on the valid results of previous steps.
# Steps whose valid input exists can run; those without don't run.  After
# you correct the problems in the failed tasks, you can safely run the whole
# script again and only tasks which haven't completed run again.
#
# Assumes a "pipelineDir" with the following structure:
#  pipelineDir/
#    seqfiles/                (where input seq files are)
#    logs/                    (where logs go)
#    tasktype/                (eg, repeatmask, matrix, similarity)
#      name_of_dataset/       (eg, seqs-nrdb)
#        input/               (input for liniac run)
#          controller.prop
#          task.prop     
#        master/              (the master dir for the distribjob run)
##############################################################################

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(runRepeatMask runMatrix runSimilarity); 

use strict;

sub runRepeatMask {
    my ($pipelineDir, $name) = @_;
    
    my $blockedFile = 
	"$pipelineDir/repeatmask/$name/master/mainresult/blocked.seq";
    my $errFile = 
	"$pipelineDir/repeatmask/$name/master/mainresult/blocked.err";
    my $inputFile = "$pipelineDir/seqfiles/$name.fsa";

    print "\nRunning repeatmask on $name\n";

    my $valid = 0;
    my $propfile = "$pipelineDir/repeatmask/$name/input/controller.prop";

    if (-e $blockedFile || -e $errFile) {
	print "  previous result found\n";
	$valid = &validateRM($inputFile, $blockedFile, $errFile);
	if (!$valid) {
	    print "  trying again...\n";
	}
    }
    if (!$valid) {
	my $cmd = "liniacjob $propfile >& $pipelineDir/logs/$name.mask.log";
	system($cmd);
	die "failed running '$cmd' with stderr:\n $!" if ($? >> 8);
	$valid = &validateRM($inputFile, $blockedFile, $errFile);
	if  (!$valid) {
	    print "  please correct failures, and set restart=yes in $propfile\n";
	}
    }

    return $valid;
}

sub runMatrix {
    my ($pipelineDir, $queryname, $subjectname) = @_;
    
    my $name = "$queryname-$subjectname";
    print "\nRunning blastmatrix on $name\n";

    my $resultFile = 
	"$pipelineDir/matrix/$name/master/mainresult/blastMatrix.out";
    my $inputFile = 
	"$pipelineDir/repeatmask/$queryname/master/mainresult/blocked.seq";
    my $valid = 0;
	my $propfile = "$pipelineDir/matrix/$name/input/controller.prop";

    if (-e $resultFile) {
	print "  previous result found\n";
	$valid = &validateBM($inputFile, $resultFile);
	if (!$valid) {
	    print "  trying again...\n";
	}
    }
    if (!$valid) {
	my $cmd = "liniacjob $propfile >& $pipelineDir/logs/$name.matrix.log";
	system($cmd);
	die "failed running '$cmd' with stderr:\n $!" if ($? >> 8);
	my $valid = &validateBM($inputFile, $resultFile);
	if  (!$valid) {
	    print "  please correct failures, and set restart=yes in $propfile\n";
	}
    }

    return $valid;
}

sub runSimilarity {
    my ($pipelineDir, $queryname, $subjectname) = @_;
    
    my $name = "$queryname-$subjectname";
    print "\nRunning blastsimilarity on $name\n";

    my $resultFile = 
	"$pipelineDir/similarity/$subjectname/master/mainresult/blastSimilarity.out";
    my $inputFile = 
	"$pipelineDir/seqfiles/$queryname.fsa";
    my $valid = 0;
	my $propfile = "$pipelineDir/similarity/$subjectname/input/controller.prop";

    if (-e $resultFile) {
	print "  previous result found\n";
	$valid = &validateBM($inputFile, $resultFile);
	if (!$valid) {
	    print "  trying again...\n";
	}
    }

    if (!$valid) {
	my $cmd = "liniacjob $propfile >& $pipelineDir/logs/$name.sim.log";
	system($cmd);
	die "failed running '$cmd' with stderr:\n $!" if ($? >> 8);

	my $valid = &validateBM($inputFile, $resultFile);
	if  (!$valid) {
	    print "  please correct failures, and set restart=yes in $propfile\n";
	}
    
    }

    return $valid;
}

sub validateRM {
    my ($inputFile, $blockedFile, $errFile) = @_;

    print "  validating...\n";

    if (! -e $blockedFile) {
	print "  INVALID  ($blockedFile not found)\n";
	return 0;
    }

    if (! -e $errFile) {
	print "  INVALID  ($errFile not found)\n";
	return 0;
    }

    my $blockedCount = &countSeqs($blockedFile);
    my $errCount = &countSeqs($errFile);
    my $inputCount = &countSeqs($inputFile);
    my $missing = $inputCount - ($blockedCount + $errCount);
    if ($missing) {
	print "  INVALID (in: $inputCount blocked: $blockedCount reject: $errCount diff: $missing)\n";
	return 0;
    }
    print "  valid\n";
    return 1;
}

sub validateBM {
    my ($inputFile, $resultFile) = @_;

    print "  validating...\n";

    if (! -e $resultFile) {
	print "  INVALID  ($resultFile not found)\n";
	return 0;
    }

    my $inputCount = &countSeqs($inputFile);
    my $resultCount = &countSeqs($resultFile);
    my $missing = $inputCount - $resultCount;

    if ($missing) {
	print "  INVALID (in: $inputCount result: $resultCount diff: $missing)\n";
	return 0;
    }
    print "  valid\n";
    return 1;
}

sub countSeqs {
    my ($file) = @_;

    open(F, $file) || die "Couldn't open file $file";
    my $c =0;
    while(<F>) {
	$c++ if /\>/;
    }
    close(F);
    return $c;
}

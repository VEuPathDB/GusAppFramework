#!/usr/bin/perl

package GUS::Pipeline::MakeTaskDirs;


##############################################################################
# Subroutines for creating directories used to control Liniac DistribJob Tasks
#
# Supported tasks (for now) are:
#  RepeatMaskTask, BlastSimilarityTask, BlastMatrixTask
#
# The directories are created on the local machine with the expectation that 
# they will be copied to the liniac server.  They use $serverPath and
# $nodePath to describe the root paths on the liniac server and nodes.
#
# The main work done is the formatting of the controller.prop and task.prop
# files required by Liniac DistribJob Tasks
# 
# Directories created look like this:
# $localPath/$pipelineName/TASK/$datasetName/input/
#   controller.prop
#   task.prop
#
##############################################################################

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(makeRMDir makeMatrixDir makeSimilarityDir makeControllerPropFile);

use strict;

use CBIL::Util::Utils;

sub makeRMDir {
    my ($datasetName, $pipelineName, $localPath, $serverPath, $nodePath, 
	$taskSize, $rmOptions, $rmPath) = @_;
    
    my $localBase = "$localPath/$pipelineName/repeatmask/$datasetName";
    my $serverBase = "$serverPath/$pipelineName/repeatmask/$datasetName"; 
    my $inputDir = "$localBase/input";
    &runCmd("mkdir -p $inputDir");
    &makeControllerPropFile($inputDir, $serverBase, 2, $taskSize, 
			    $nodePath, 
			    "DJob::DistribJobTasks::RepeatMaskerTask");
    my $seqFileName = "$serverPath/$pipelineName/seqfiles/$datasetName.fsa"; 
    &makeRMTaskPropFile($inputDir, $seqFileName, $rmOptions, $rmPath);
}

sub makeMatrixDir {
    my ($queryName, $subjectName, $pipelineName, $localPath, $serverPath, 
	$nodePath, $taskSize, $blastBinPath) = @_;
    
    my $localBase = "$localPath/$pipelineName/matrix/$queryName-$subjectName";
    my $serverBase = "$serverPath/$pipelineName/matrix/$queryName-$subjectName"; 
    my $inputDir = "$localBase/input";
    &runCmd("mkdir -p $inputDir");
    &makeControllerPropFile($inputDir, $serverBase, 2, $taskSize, 
			    $nodePath, 
			    "DJob::DistribJobTasks::BlastMatrixTask");
    my $dbFileName = "$serverPath/$pipelineName/repeatmask/$subjectName/master/mainresult/blocked.seq"; 
    my $seqFileName = "$serverPath/$pipelineName/repeatmask/$queryName/master/mainresult/blocked.seq"; 
    &makeBMTaskPropFile($inputDir, $blastBinPath, $seqFileName, $dbFileName);
}

sub makeSimilarityDir {
    my ($queryName, $subjectName, $pipelineName, $localPath, $serverPath, 
	$nodePath, $taskSize, $blastBinPath,
	$dbName, $regex, $blast, $blastParams) = @_;
    
    my $localBase = "$localPath/$pipelineName/similarity/$queryName-$subjectName";
    my $serverBase = "$serverPath/$pipelineName/similarity/$queryName-$subjectName";
    my $inputDir = "$localBase/input";
    my $blastParamsFile = "$inputDir/blastParams";

    &runCmd("mkdir -p $inputDir");
    &makeControllerPropFile($inputDir, $serverBase, 1, $taskSize, 
			    $nodePath, "DJob::DistribJobTasks::BlastSimilarityTask");
    my $dbFileName = "$serverPath/$pipelineName/seqfiles/$dbName"; 
    my $seqFileName = "$serverPath/$pipelineName/seqfiles/finalDots.fsa"; 
    &makeBSTaskPropFile($inputDir, $blastBinPath, $seqFileName, $dbFileName, 
			$regex, $blast, "blastParams");

    open(F, ">$blastParamsFile");
    print F "$blastParams\n";
    close(F);
}

sub makeControllerPropFile {
    my ($inputDir, $baseDir, $slotsPerNode, $taskSize, $nodePath, 
	$taskClass) = @_;

    open(F, ">$inputDir/controller.prop") 
	|| die "Can't open $inputDir/controller.prop for writing";

    print F 
"masterdir=$baseDir/master
inputdir=$baseDir/input
nodedir=$nodePath
slotspernode=$slotsPerNode
subtasksize=$taskSize
taskclass=$taskClass
nodeclass=DJob::DistribJob::BprocNode
restart=no
";
    close(F);
}

sub makeRMTaskPropFile {
    my ($inputDir, $seqFileBasename, $rmOptions, $rmPath) = @_;

    open(F, ">$inputDir/task.prop") 
	|| die "Can't open $inputDir/task.prop for writing";

    print F 
"rmPath=$rmPath
inputFilePath=$seqFileBasename
trimDangling=y
rmOptions=$rmOptions
";
    close(F);
}

sub makeBMTaskPropFile {
    my ($inputDir, $blastBinDir, $seqFilePath,  $dbFileName) = @_;

    open(F, ">$inputDir/task.prop") 
	|| die "Can't open $inputDir/task.prop for writing";

    print F 
"blastBinDir=$blastBinDir
dbFilePath=$dbFileName
inputFilePath=$seqFilePath
";
    close(F);
}

sub makeBSTaskPropFile {
    my ($inputDir, $blastBinDir, $seqFilePath,  $dbFileName, 
	$regex, $blast, $blastParamsFile) = @_;

    open(F, ">$inputDir/task.prop") 
	|| die "Can't open $inputDir/task.prop for writing";

    print F 
"blastBinDir=$blastBinDir
dbFilePath=$dbFileName
inputFilePath=$seqFilePath
dbType=p
regex='$regex'
blastProgram=$blast
blastParamsFile=$blastParamsFile
";
    close(F);
}

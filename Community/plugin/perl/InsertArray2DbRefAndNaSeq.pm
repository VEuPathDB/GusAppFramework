#######################################################################
##                  InsertArray2DbRefAndNaSeq.pm
##
## $Id: $
#######################################################################

package GUS::Community::Plugin::InsertArray2DbRefAndNaSeq;
@ISA = qw(GUS::PluginMgr::Plugin);
 
use strict;


use FileHandle;
use GUS::ObjRelP::DbiDatabase;
use GUS::PluginMgr::Plugin;
use GUS::Model::SRes::DbRef;
use GUS::Model::SRes::ExternalDatabase;
use GUS::Model::SRes::ExternalDatabaseRelease;
use GUS::Model::DoTS::NASequence;
use GUS::Model::DoTS::Evidence;
use GUS::Model::RAD::CompositeElementDbRef;
use GUS::Model::RAD::ElementDbRef;

$| = 1;

my $argsDeclaration =
[
     
stringArg({name => 'evidenceExternalDbName',
	   descr => 'name of the external database corresponding to the annotation file used as evidence',
	   constraintFunc => undef,
	   reqd => 1,
	   isList => 0,
        }),

stringArg({name => 'evidenceExternalDbVersion',
	    descr => 'version of the external database corresponding to the annotation file used as evidence',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
	   }),


stringArg({name => 'arrayDesignName',
	    descr => 'name of the array design correponding to the array to annotate',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
	   }),


stringArg({name => 'arrayDesignVersion',
	    descr => 'version of the array design correponding to the array to annotate',
	    constraintFunc => undef,
	    reqd => 0,
	    isList => 0,
	   }),

stringArg({name => 'dbRefOrNASeqVersion',
	    descr => 'DBRef or NASeq database version',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
            mustExist => 1,
	   }),


stringArg({name => 'dbRefOrNASeqName',
	    descr => 'DBRef or NASeq database name',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
            mustExist => 1,
	   }),

stringArg({name => 'separator',
	    descr => 'File separator',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
            mustExist => 1,
	   }),

stringArg({name => 'subSeparator',
	    descr => 'Separator used in case of multiple IDs',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
            mustExist => 1,
	   }),

stringArg({name => 'refIDColumnName',
	    descr => 'reference ID column name (for example spot position or probe_id)',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
            mustExist => 1,
	   }),

stringArg({name => 'annotationIDColumnName',
	    descr => 'annotation ID column name',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
            mustExist => 1,
	   }),


fileArg({name => 'annotationFileName',
	 descr => 'annotation file name',
	 constraintFunc => undef,
	 reqd => 1,
	 isList => 0,
	 mustExist => 1,
	 format => 'Text'
        }),


enumArg({name => 'databaseName',
	    descr => 'Database to link the data to (DbRef or NASeq)',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
            mustExist => 1,
            enum => "DbRef,NASeq",
	   }),

 ];


my $purposeBrief = <<PURPOSEBRIEF;
Populate mappings in RAD.ElementDbRef and RAD.CompositeElementsDbRef between SRes.DbRef and DoTS.NaSequence and RAD.ShortOligoFamily or RAD.Spot from microarray annotations file.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Populate mappings between SRes.DbRef and DoTS.NaSequence and RAD.ShortOligoFamily or RAD.Spot from delimited microarray annotations file.  Mappings are inserted in RAD.CompositeElementDbRef or RAD.ElementDbRef.
PLUGIN_PURPOSE

my $tablesAffected = [
['RAD.CompositeElementDbRef','New entries are placed in this table', 'RAD.CompositeElementNaSequence', 'New entries are placed in this table', 'RAD.ElementDbRef', 'New entries are placed in this table', 'RAD.ElementNaSequence', 'New entries are placed in this table']
];

my $tablesDependedOn = ['SRes.DbRef', 'DoTS.NASequence', 'DoTS.Evidence'];

my $howToRestart = <<PLUGIN_RESTART;
This plugin is compliant with the undo API:
Run the plugin GUS::Community::Plugin::Undo to delete all entries inserted by a specific call to this plugin. Then re-run this plugin from fresh
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
unknown
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
PLUGIN_NOTES

my $documentation = {purposeBrief => $purposeBrief,
		     purpose => $purpose,
		     tablesAffected => $tablesAffected,
		     tablesDependedOn => $tablesDependedOn,
		     howToRestart => $howToRestart,
		     failureCases => $failureCases,
		     notes => $notes
		    };


sub new {
    my ($class) = @_;
    my $self = {};
    bless($self, $class);
    
    $self->initialize({requiredDbVersion => 3.5,
		       cvsRevision =>  '$Revision: 4134 $', #CVS fills this in
		       name => ref($self),
		       argsDeclaration   => $argsDeclaration,
		       documentation     => $documentation
		      });

    return $self;
}



########################################################################
# Main Program
########################################################################

sub run {
    my ($self) = @_;
    my $nrecords;
    
    my $technologyType = $self->getTechnologyType();
    my $databaseName = $self->getArg('databaseName');
    my $arrayDesignID = $self->getArrayDesignID();

    my $evidenceExternalDbID = $self->getExternalDbID($self->getArg('evidenceExternalDbName'), $self->getArg('evidenceExternalDbVersion'));
    my $dbRefOrNASeqExternalDbID = $self->getExternalDbID($self->getArg('dbRefOrNASeqName'), $self->getArg('dbRefOrNASeqVersion'));
    
    my $fileName = $self->getArg('annotationFileName');
    my $separator = $self->getArg('separator');
    my $subSeparator = $self->getArg('subSeparator');
    
    my $refIDColumnName = $self->getArg('refIDColumnName');
    my $annotIDColumnName = $self->getArg('annotationIDColumnName');
    
    my $hashRef = $self->parseAnnotationFile($fileName, $separator, $subSeparator, $refIDColumnName, $annotIDColumnName);


    my $logFile = "loadArray2DbRefAndNaSeq.log";
    
    $self->log("evidenceExternalDbID = $evidenceExternalDbID\n");
    $self->log("dbRefOrNASeqExternalDbID = $dbRefOrNASeqExternalDbID\n");
    $self->log("techno type = $technologyType - dbname = $databaseName\n");
    
    if($technologyType =~ /oligo/i) {
	if($databaseName eq "DbRef") {
	    $nrecords = $self->populateCompEleDbRef($hashRef, $arrayDesignID, $evidenceExternalDbID, $dbRefOrNASeqExternalDbID, $logFile);
	}
	elsif($databaseName eq "NaSeq")  {
	    $nrecords = $self->populateCompEleNaSeq($hashRef, $arrayDesignID, $evidenceExternalDbID, $dbRefOrNASeqExternalDbID, $logFile);
	}
	else {
	    die("$databaseName is an undefined type\n");
	}
    }
    elsif($technologyType =~ /spot/i) {
	if($databaseName eq "DbRef") {
	    $nrecords = $self->populateEleDbRef($hashRef, $arrayDesignID, $evidenceExternalDbID, $dbRefOrNASeqExternalDbID);
	}
	elsif($databaseName eq "NaSeq")  {
	    $nrecords = $self->populateEleNaSeq($hashRef, $arrayDesignID, $evidenceExternalDbID, $dbRefOrNASeqExternalDbID);
	}
	else {
	    die("$databaseName is an undefined type\n");
	}
    }
    else {
	die("$technologyType is an undefined type\n");
    }
    
    my $result = "$nrecords records created.";
    
    return $result ;
}


sub populateCompEleDbRef {
    my($self, $hash, $arrayDesignID, $evidenceExternalDbID, $dbRefOrNASeqExternalDbID, $logFile) = @_;
    
    my $nToPopulate = scalar keys(%$hash);
    
    my ($sql, $queryHandle, $sth, $compositeElementID, $dbRefID, $compEleID);
    my $nProbePopulated = 0;
    my $nCENotFound =0;
    my $nDbRefIDNotFound=0;
    
    open(LOGFILE, ">$logFile") ||  die ("Can't open $logFile\n");
    
    $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = 'CompositeElementDbRef' and d.name = 'RAD'";
    
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my ($targetTableID) = $sth ->fetchrow_array();
    if(!defined $targetTableID) { die "Cannot find RAD.CompositeElementDbRef' table\n"; }
    
    $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = 'ExternalDatabaseRelease' and d.name = 'SRes'";
    
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my ($factTableID) = $sth ->fetchrow_array();
    
    if(!$factTableID) { die "Cannot find SRes.ExternalDatabaseRelease\n"; }
    
    my $counter = 0;
    while (my ($probeID, $annotationListIDRef) = each(%$hash)) {
	
	$sql = "SELECT composite_element_id FROM RAD.shortoligofamily WHERE name = '$probeID' and array_design_id = $arrayDesignID";
	$queryHandle = $self->getQueryHandle();
	$sth = $queryHandle->prepareAndExecute($sql);
	($compositeElementID) = $sth ->fetchrow_array();
	
	if(defined $compositeElementID) {

	    my @annotationListID = @$annotationListIDRef;
	    foreach(@$annotationListIDRef) {
		
		my $annotationID= $_;
		
		$sql = "SELECT db_ref_id FROM SRes.dbref WHERE primary_identifier = '$annotationID' and external_database_release_id =$dbRefOrNASeqExternalDbID";
		
		$queryHandle = $self->getQueryHandle();
		$sth = $queryHandle->prepareAndExecute($sql);
		($dbRefID) = $sth ->fetchrow_array();
		
		if(defined $dbRefID) {
		    
		    $sql = "SELECT composite_element_db_ref_id FROM RAD.CompositeElementDbRef WHERE composite_element_id = $compositeElementID AND db_ref_id = $dbRefID";
		    $queryHandle = $self->getQueryHandle();
		    $sth = $queryHandle->prepareAndExecute($sql);
		    ($compEleID) = $sth ->fetchrow_array();
		    if(!defined $compEleID) {
			
			my $newCEDbRef = GUS::Model::RAD::CompositeElementDbRef->new({
			    'composite_element_id' => $compositeElementID,
			    'db_ref_id' => $dbRefID
			    });
			
			$newCEDbRef->submit();
			my $targetID = $newCEDbRef->getId();
			
			if(!defined $targetID) {
			    die "target_id undefined";
			}
			if(!defined $evidenceExternalDbID) {
			    die "evidenceExternalDbID  undefined";
			}
			
			my $newEvidence = GUS::Model::DoTS::Evidence->new({
			    'target_table_id' => $targetTableID,
			    'target_id' => $targetID,
			    'fact_table_id' => $factTableID,
			    'fact_id' => $evidenceExternalDbID
			    });
			
			if(!defined $newEvidence) {
			    die "Evidence undefined";
			}
			
			$newEvidence->submit();
			
			$nProbePopulated++;
			$self->undefPointerCache();
		    }
		}
		else {
		    $self->log("$annotationID not found in SRes.DBRef");
		    print LOGFILE "$annotationID not found in SRes.DBRef\n";
		    $nDbRefIDNotFound++;
		}
	    }
	}
	else {
	    $self->log("$probeID not found in RAD.ShortOligoFamily");
	    print LOGFILE "$probeID not found in RAD.ShortOligoFamily\n";
	    $nCENotFound++;
	}
	
	$counter++;
	if($counter % 100 ==0) { $self->log("$nProbePopulated entries populated in RAD.CompositeElementDbRef - $counter/$nToPopulate processed");}

    }
    close(LOGFILE);
    $self->log ("CompositeElement not found = $nCENotFound; DbRefID not found = $nDbRefIDNotFound; rows populated = $nProbePopulated");
    return $nProbePopulated;
}


sub populateEleDbRef {
    my($self, $hash, $arrayDesignID, $evidenceExternalDbID, $dbRefOrNASeqExternalDbID, $logFile) = @_;
    
    my $nToPopulate = scalar keys(%$hash);
    
    my ($sql, $queryHandle, $sth, $elementID, $dbRefID, $eleID);
    my $nProbePopulated = 0;
    my $nENotFound =0;
    my $nDbRefIDNotFound=0;

    open(LOGFILE, ">$logFile") ||  die ("Can't open $logFile\n");
    
    $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = 'ElementDbRef' and d.name = 'RAD'";
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my ($targetTableID) = $sth ->fetchrow_array();
    if(!$targetTableID) { die "Cannot find RAD.ElementDbRef\n"; }
    
    $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = 'ExternalDatabaseRelease' and d.name = 'SRes'";
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my ($factTableID) = $sth ->fetchrow_array();    
    if(!$factTableID) { die "Cannot find SRes.ExternalDatabaseRelease\n"; }
    
    my $counter = 0;

    while (my ($geneLocation, $annotationListIDRef) = each(%$hash)) {
	
	my @gc = split(/\./, $geneLocation);
	
	$sql = "SELECT element_id FROM RAD.spot WHERE array_row=$gc[0] and array_column=$gc[1] and grid_row=$gc[2] and grid_column=$gc[3] and sub_row=$gc[4] and sub_column=$gc[5] and array_design_id = $arrayDesignID";
	
	$queryHandle = $self->getQueryHandle();
	$sth = $queryHandle->prepareAndExecute($sql);
	($elementID) = $sth ->fetchrow_array();
	
	if(defined $elementID) {
	    
	    my @annotationListID = @$annotationListIDRef;
	    
	    foreach(@annotationListID) {
		my $annotationID = $_;
		
		$sql = "SELECT db_ref_id FROM SRes.dbref WHERE primary_identifier = '$annotationID' AND external_database_release_id =$dbRefOrNASeqExternalDbID";
		$queryHandle = $self->getQueryHandle();
		$sth = $queryHandle->prepareAndExecute($sql);
		($dbRefID) = $sth ->fetchrow_array();
		
		if(defined $dbRefID) {
		    
		    $sql = "SELECT element_db_ref_id FROM RAD.ElementDbRef WHERE element_id = $elementID AND db_ref_id = $dbRefID";
		    $queryHandle = $self->getQueryHandle();
		    $sth = $queryHandle->prepareAndExecute($sql);
		    ($eleID) = $sth ->fetchrow_array();
		    
		    if(!defined $eleID) {
			
			my $newEDbRef = GUS::Model::RAD::ElementDbRef->new({
			    'element_id' => $elementID,
			    'db_ref_id' => $dbRefID
			    });
			
			$newEDbRef->submit();
			my $targetID = $newEDbRef->getId();
			
			my $newEvidence = GUS::Model::DoTS::Evidence->new({
			    'target_table_id' => $targetTableID,
			    'target_id' => $targetID,
			    'fact_table_id' => $factTableID,
			    'fact_id' => $evidenceExternalDbID
			    });
			
			$newEvidence->submit();
			
			$nProbePopulated++;
			$self->undefPointerCache();
		    }
		}
		else {
		    $self->log("$annotationID not found in SRes.DBRef");
		    print LOGFILE "$annotationID not found in SRes.DBRef\n";
		    $nDbRefIDNotFound++;
		}
	    }
	}
	else {
	    $self->log("$geneLocation not found in RAD.Spot");
	    print LOGFILE "$geneLocation not found in RAD.Spot\n";
	    $nENotFound++;
	}
	$counter++;
	if($counter % 100 ==0) { $self->log("$nProbePopulated entries populated in RAD.ElementDbRef - $counter/$nToPopulate processed");}
	
    }
    
    close LOGFILE;
    
    $self->log ("Element not found = $nENotFound; DbRefID not found = $nDbRefIDNotFound; rows populated = $nProbePopulated");
    return $nProbePopulated;
}



sub populateCompEleNASeq {
    my($self, $hash, $arrayDesignID, $evidenceExternalDbID, $dbRefOrNASeqExternalDbID, $logFile) = @_;
    
    my $nToPopulate = scalar keys(%$hash);
    
    my ($sql, $queryHandle, $sth, $compositeElementID, $naSeqID, $compEleID);
    my $nProbePopulated = 0;
    my $nCENotFound =0;
    my $nNASeqIDNotFound=0;
    
    open(LOGFILE, ">$logFile") ||  die ("Can't open $logFile\n");
    
    $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = 'CompositeElementNASequence' and d.name = 'RAD'";
    
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my ($targetTableID) = $sth ->fetchrow_array();
    if(!defined $targetTableID) { die "Cannot find RAD.CompositeElementNASequence' table\n"; }
    
    $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = 'ExternalDatabaseRelease' and d.name = 'SRes'";
    
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my ($factTableID) = $sth ->fetchrow_array();
    
    if(!$factTableID) { die "Cannot find SRes.ExternalDatabaseRelease\n"; }
    
    my $counter = 0;
    while (my ($probeID, $annotationListIDRef) = each(%$hash)) {
	
	$sql = "SELECT composite_element_id FROM RAD.shortoligofamily WHERE name = '$probeID' and array_design_id = $arrayDesignID";
	$queryHandle = $self->getQueryHandle();
	$sth = $queryHandle->prepareAndExecute($sql);
	($compositeElementID) = $sth ->fetchrow_array();
	
	if(defined $compositeElementID) {

	    my @annotationListID = @$annotationListIDRef;
	    foreach(@$annotationListIDRef) {
		
		my $annotationID= $_;
		
		$sql = "SELECT na_sequence_id FROM DoTS.NASeqence WHERE source_na_sequence_id = '$annotationID' and external_database_release_id =$dbRefOrNASeqExternalDbID";
		
		$queryHandle = $self->getQueryHandle();
		$sth = $queryHandle->prepareAndExecute($sql);
		($naSeqID) = $sth ->fetchrow_array();
		
		if(defined $naSeqID) {
		    
		    $sql = "SELECT composite_element_na_seq_id FROM RAD.CompositeElementNASeqence WHERE composite_element_id = $compositeElementID AND na_sequence_id = $naSeqID";
		    $queryHandle = $self->getQueryHandle();
		    $sth = $queryHandle->prepareAndExecute($sql);
		    ($compEleID) = $sth ->fetchrow_array();
		    if(!defined $compEleID) {
			
			my $newCENASeq = GUS::Model::RAD::CompositeElementNASequence->new({
			    'composite_element_id' => $compositeElementID,
			    'na_sequence_id' => $naSeqID
			    });
			
			$newCENASeq->submit();
			my $targetID = $newCENASeq->getId();
			
			my $newEvidence = GUS::Model::DoTS::Evidence->new({
			    'target_table_id' => $targetTableID,
			    'target_id' => $targetID,
			    'fact_table_id' => $factTableID,
			    'fact_id' => $evidenceExternalDbID
			    });
			
			$newEvidence->submit();
			
			$nProbePopulated++;
			$self->undefPointerCache();
		    }
		}
		else {
		    $self->log("$annotationID not found in DoTS.NASequence");
		    print LOGFILE "$annotationID not found in DoTS.NASequence\n";
		    $nNASeqIDNotFound++;
		}
	    }
	}
	else {
	    $self->log("$probeID not found in RAD.ShortOligoFamily");
	    print LOGFILE "$probeID not found in RAD.ShortOligoFamily\n";
	    $nCENotFound++;
	}
	
	$counter++;
	if($counter % 100 ==0) { $self->log("$nProbePopulated entries populated in RAD.CompositeElementNaSequence - $counter/$nToPopulate processed");}
    }
    close(LOGFILE);
    $self->log ("CompositeElement not found = $nCENotFound; naSeqID not found = $nNASeqIDNotFound; rows populated = $nProbePopulated");
    return $nProbePopulated;
}


sub populateEleNASeq {
    my($self, $hash, $arrayDesignID, $evidenceExternalDbID, $dbRefOrNASeqExternalDbID, $logFile) = @_;
    
    my $nToPopulate = scalar keys(%$hash);
    
    my ($sql, $queryHandle, $sth, $elementID, $naSeqID, $eleID);
    my $nProbePopulated = 0;
    my $nENotFound =0;
    my $nNASeqIDNotFound=0;

    open(LOGFILE, ">$logFile") ||  die ("Can't open $logFile\n");
    
    $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = 'ElementNASequence' and d.name = 'RAD'";
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my ($targetTableID) = $sth ->fetchrow_array();
    if(!$targetTableID) { die "Cannot find RAD.ElementNASequence\n"; }
    
    $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = 'ExternalDatabaseRelease' and d.name = 'SRes'";
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my ($factTableID) = $sth ->fetchrow_array();    
    if(!$factTableID) { die "Cannot find SRes.ExternalDatabaseRelease\n"; }
    
    my $counter = 0;

    while (my ($geneLocation, $annotationListIDRef) = each(%$hash)) {
	
	my @gc = split(/\./, $geneLocation);
	
	$sql = "SELECT element_id FROM RAD.spot WHERE array_row=$gc[0] and array_column=$gc[1] and grid_row=$gc[2] and grid_column=$gc[3] and sub_row=$gc[4] and sub_column=$gc[5] and array_design_id = $arrayDesignID";
	
	$queryHandle = $self->getQueryHandle();
	$sth = $queryHandle->prepareAndExecute($sql);
	($elementID) = $sth ->fetchrow_array();
	
	if(defined $elementID) {
	    
	    my @annotationListID = @$annotationListIDRef;
	    
	    foreach(@annotationListID) {
		my $annotationID = $_;
		
		$sql = "SELECT na_sequence_id FROM DoTS.NASequence WHERE source_na_sequence_id = '$annotationID' AND external_database_release_id =$dbRefOrNASeqExternalDbID";
		$queryHandle = $self->getQueryHandle();
		$sth = $queryHandle->prepareAndExecute($sql);
		($naSeqID) = $sth ->fetchrow_array();
		
		if(defined $naSeqID) {
		    
		    $sql = "SELECT element_na_sequence_id FROM RAD.ElementNASequence WHERE element_id = $elementID AND na_sequence_id = $naSeqID";
		    $queryHandle = $self->getQueryHandle();
		    $sth = $queryHandle->prepareAndExecute($sql);
		    ($eleID) = $sth ->fetchrow_array();
		    
		    if(!defined $eleID) {
			
			my $newENASeq = GUS::Model::RAD::ElementNASequence->new({
			    'element_id' => $elementID,
			    'na-sequence_id' => $naSeqID
			    });
			
			$newENASeq->submit();
			my $targetID = $newENASeq->getId();
			
			my $newEvidence = GUS::Model::DoTS::Evidence->new({
			    'target_table_id' => $targetTableID,
			    'target_id' => $targetID,
			    'fact_table_id' => $factTableID,
			    'fact_id' => $evidenceExternalDbID
			    });
			
			$newEvidence->submit();
			
			$nProbePopulated++;
			$self->undefPointerCache();
		    }
		}
		else {
		    $self->log("$annotationID not found in DoTS.NASequence");
		    print LOGFILE "$annotationID not found in DoTS.NASequence\n";
		    $nNASeqIDNotFound++;
		}
	    }
	}
	else {
	    $self->log("$geneLocation not found in RAD.Spot");
	    print LOGFILE "$geneLocation not found in RAD.Spot\n";
	    $nENotFound++;
	}
	$counter++;
	if($counter % 100 ==0) { $self->log("$nProbePopulated entries populated in RAD.ElementNaSequence - $counter/$nToPopulate processed");}
    }
    
    close LOGFILE;
    
    $self->log ("Element not found = $nENotFound; NASequenceID not found = $nNASeqIDNotFound; rows populated = $nProbePopulated");
    return $nProbePopulated;
}



sub parseAnnotationFile {
    my ($self, $annotFile, $separator, $subSeparator, $columnRefIDName, $columnIDName)  = @_;
    
    open (FILE, $annotFile) ||  die ("Can't open $annotFile\n");
    
    my %hash;
    my @content = <FILE>;
    chomp @content;
    
    my @header;
    my $indexHeader = -1;
    
    for (my $i=0; $i<10; $i++) {
	
	if($content[$i] =~ /"$columnIDName"/ || $content[$i] =~ /"$columnRefIDName"/) {
	    
	    $content[$i] =~ s/\"//g;
	    @header = split(/$separator/, $content[$i]);
	    
	    $indexHeader = $i;
	    last;
	}
    }
    
    if($indexHeader == -1) {
	die "Could not find header\n";
    }

    $self->log("header found at line = $indexHeader");
    my $columnRefID = -1;
    my $columnID = -1;
    for( my $i=0; $i<=scalar @header; $i++) {
	if( $columnRefIDName=~ /$header[$i]/i ) { $columnRefID = $i;}
	if( $columnIDName=~ /$header[$i]/i ) { $columnID = $i; }
    }
    
    if($columnRefID ==-1) {
	die "Did not find '$columnRefIDName' in the file header\n";
    }
    
    if($columnID ==-1) {
	die "Did not find '$columnIDName' in the file header\n";
    }
    
    $self->log("ref col=$columnRefID  ref id = $columnID");
    
    for(my $i=$indexHeader+1; $i<scalar @content; $i++) {
	
	my @row = split(/\"$separator\"/, $content[$i]);
	foreach(@row) { $_ =~s/\ //g; }
	foreach(@row) { $_ =~s/\"//g; }
	my $k=0;
	
	if(defined $row[$columnRefID] & defined $row[$columnID] & !($row[$columnID] eq "---") ) {

	    my @list = split(/$subSeparator/, $row[$columnID]);
	    foreach(@list) { $_ =~s/\ //g; }
	    foreach(@list) { $_ =~s/\"//g; }
	    
	    $hash{$row[$columnRefID]} = [ @list ];
	}
    }
    
    close FILE;
    
    
    my $nRecords = scalar keys(%hash);
    $self->log("$nRecords records found in $annotFile");
    return (\%hash);
}


sub getArrayDesignID {
    my($self) = @_;
    my $arrayDesignName = $self->getArg('arrayDesignName');
    my $arrayDesignversion = $self->getArg('arrayDesignVersion');
    my $sql;
    
    if(defined $arrayDesignversion) {
	$sql = "SELECT array_design_id FROM RAD.arraydesign WHERE name='$arrayDesignName' and version ='$arrayDesignversion'";
    }
    else {
	$sql = "SELECT array_design_id FROM RAD.arraydesign WHERE name='$arrayDesignName'";
    }
    
    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);
    my ($arrayDesignID) = $sth ->fetchrow_array();
    
    if(!defined $arrayDesignID) {
	die("No ARRAY_DESIGN_ID corresponding to NAME '$arrayDesignName' (version '$arrayDesignversion')"); 
    }
    $self->log("array_design_id = $arrayDesignID"); 
    return $arrayDesignID;
}


sub getTechnologyType {
    my($self) = @_;
    
    my $arrayDesignName = $self->getArg('arrayDesignName');
    my $arrayDesignversion = $self->getArg('arrayDesignVersion');
    my $sql;
    
    if(defined $arrayDesignversion) {
	$sql = "SELECT o.value FROM study.ontologyentry o, rad.arraydesign a  where o.category='TechnologyType' AND o.ontology_entry_id=a.technology_type_id AND a.name = '$arrayDesignName' AND a.version = '$arrayDesignversion'";
    }
    else {
	$sql = "SELECT o.value FROM study.ontologyentry o, rad.arraydesign a  where o.category='TechnologyType' AND o.ontology_entry_id=a.technology_type_id AND a.name = '$arrayDesignName'";
    }
    
    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);
    my ($techTypeID) = $sth ->fetchrow_array();
    
    if(!defined $techTypeID) {
	die("No Technological Type ID corresponding to NAME '$arrayDesignName' (version '$arrayDesignversion')"); 
    }
    $self->log("technological type = $techTypeID"); 
    return $techTypeID;
}

sub getExternalDbID {
    my($self, $dbName, $dbVersion) = @_;
    
    my $sql = "SELECT i.external_database_release_id FROM SRes.externaldatabaserelease i, SRes.externaldatabase e where i.version = '$dbVersion' and e.name = '$dbName'";
    
    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);
    my ($externalDbID) = $sth ->fetchrow_array();
    
    if(!defined $externalDbID) {
	die("No External Database Release ID corresponding to NAME '$dbName' (version '$dbVersion')"); 
    }
    return $externalDbID;
}

sub undoTables {
    my ($self) = @_;

    return ('RAD.CompositeElementNASequence', 'RAD.ElementNASequence', 'RAD.CompositeElementDBRef', 'RAD.ElementDbRef');
}


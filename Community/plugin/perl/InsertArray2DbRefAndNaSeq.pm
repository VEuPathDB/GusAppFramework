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
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::Evidence;
use GUS::Model::RAD::CompositeElementDbRef;
use GUS::Model::RAD::CompositeElementNASequence;
use GUS::Model::RAD::ElementDbRef;
use GUS::Model::RAD::ElementNASequence;

$| = 1;

my $argsDeclaration =
[ 
 stringArg({name  => 'evidenceExternalDatabaseSpec',
	    descr => 'The name|version of the external database release corresponding to the annotation file used as evidence',
	    constraintFunc=> undef,
	    reqd  => 1,
	    isList => 0
	    }),
 
  stringArg({name  => 'dbRefOrNASeqExternalDatabaseSpec',
	     descr => 'The name|version of the external database release for RefSeq to point to',
	     constraintFunc=> undef,
	     reqd  => 1,
	     isList => 0
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
	    descr => 'reference ID column name (can be spot positions formatted as follows:1.2.1.1.10.12; or probe_id)',
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


enumArg({name => 'annotationType',
	    descr => 'Database to link the data to (DbRef or NASeq)',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
            mustExist => 1,
            enum => "DbRef,NASeq",
	   }),

 ];


my $purposeBrief = <<PURPOSEBRIEF;
Populate mappings in RAD.ElementDbRef and RAD.CompositeElementsDbRef between SRes.DbRef and DoTS.ExternalNaSequence and RAD.ShortOligoFamily or RAD.Spot from microarray annotations file.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Populate mappings between SRes.DbRef and DoTS.ExternalNaSequence and RAD.ShortOligoFamily or RAD.Spot from microarray annotations file.  Mappings are inserted in RAD.CompositeElementDbRef or RAD.ElementDbRef. Element and CompositeElements re supported, including MPSS Tags and RT-PCR.
PLUGIN_PURPOSE

my $tablesAffected = [
['RAD.CompositeElementDbRef','New entries are placed in this table', 'RAD.CompositeElementNaSequence', 'New entries are placed in this table', 'RAD.ElementDbRef', 'New entries are placed in this table', 'RAD.ElementNaSequence', 'New entries are placed in this table']
];

my $tablesDependedOn = ['SRes.DbRef', 'DoTS.ExternalNASequence', 'DoTS.Evidence'];

my $howToRestart = <<PLUGIN_RESTART;
This plugin is compliant with the undo API:
Run the plugin GUS::Community::Plugin::Undo to delete all entries inserted by a specific call to this plugin. Then re-run this plugin from fresh.
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
    
    $self->initialize({requiredDbVersion => 3.6,
		       cvsRevision =>  '$Revision$', #CVS fills this in
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
    my $annotationType = $self->getArg('annotationType');
    my $arrayDesignID = $self->getArrayDesignID();
    
    my $evidenceExternalDbID = $self->getExtDbRlsId($self->getArg('evidenceExternalDatabaseSpec'));
    my $dbRefOrNASeqExternalDbID = $self->getExtDbRlsId($self->getArg('dbRefOrNASeqExternalDatabaseSpec'));
    
    my $fileName = $self->getArg('annotationFileName');
    my $separator = $self->getArg('separator');
    my $subSeparator = $self->getArg('subSeparator');
    
    my $refIDColumnName = $self->getArg('refIDColumnName');
    my $annotIDColumnName = $self->getArg('annotationIDColumnName');
    
    my $hashRef = $self->parseAnnotationFile($fileName, $separator, $subSeparator, $refIDColumnName, $annotIDColumnName);


    my $logFile = "loadArray2DbRefAndNaSeq.log";
    
    $self->log("evidenceExternalDbID = $evidenceExternalDbID\n");
    $self->log("dbRefOrNASeqExternalDbID = $dbRefOrNASeqExternalDbID\n");
    $self->log("techno type = $technologyType\n");
    $self->log("dbtype = $annotationType\n");

    my @ar = ($hashRef, $arrayDesignID, $evidenceExternalDbID, $dbRefOrNASeqExternalDbID, $logFile);

    if($technologyType =~ /spot/i && $annotationType eq "DbRef") {
      $nrecords = $self->populateEleDbRef(@ar, "RAD.Spot");
    }

    elsif($technologyType =~ /spot/i && $annotationType eq "NASeq")  {
      $nrecords = $self->populateEleNaSeq(@ar, "RAD.Spot");
    }

    elsif($technologyType =~ /oligo/i && $annotationType eq "DbRef") {
      $nrecords = $self->populateCompEleDbRef(@ar, "RAD.ShortOligoFamily", "name");
    }

    elsif($technologyType =~ /oligo/i && $annotationType eq "NASeq")  {
      $nrecords = $self->populateCompEleNaSeq(@ar, "RAD.ShortOligoFamily", "name");
    }

    elsif($technologyType =~ /MPSS/i && $annotationType eq "DbRef") {
      $nrecords = $self->populateCompEleDbRef(@ar, "RAD.MPSSTag", "tag");
    }

    elsif($technologyType =~ /MPSS/i && $annotationType eq "NASeq")  {
      $nrecords = $self->populateCompEleNaSeq(@ar, "RAD.MPSSTag", "tag");
    }

    elsif($technologyType =~ /RT-PCR/i && $annotationType eq "DbRef") {
      $nrecords = $self->populateEleDbRef(@ar, "RAD.RTPCRElement");
    }

    elsif($technologyType =~ /RT-PCR/i && $annotationType eq "NASeq") {
      $nrecords = $self->populateEleNaSeq(@ar, "RAD.RTPCRElement");
    }

    else {
      die("$annotationType is an undefined annotation type for technology type of $technologyType\n");
    }
    
    my $result = "$nrecords records created.";
    
    return $result ;
}


sub populateCompEleDbRef {
    my($self, $hash, $arrayDesignID, $evidenceExternalDbID, $dbRefOrNASeqExternalDbID, $logFile, $view, $identifier) = @_;
    
    my $nToPopulate = scalar keys(%$hash);
    
    my ($sql, $queryHandle, $sth, $compositeElementID, $dbRefID, $compEleID);
    my $nProbePopulated = 0;
    my $nCENotFound =0;
    my $nDbRefIDNotFound=0;
    
    open(LOGFILE, ">$logFile") ||  die ("Can't open $logFile\n");
    
    my ($targetTableID, $factTableID) = $self->_getTargetAndFactTableIds('CompositeElementDbRef');
    
    my $counter = 0;
    while (my ($probeID, $annotationListIDRef) = each(%$hash)) {
	
	$sql = "SELECT composite_element_id FROM $view WHERE $identifier = '$probeID' and array_design_id = $arrayDesignID";
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
						
			my $newEvidence = GUS::Model::DoTS::Evidence->new({
			    'target_table_id' => $targetTableID,
			    'target_id' => $targetID,
			    'fact_table_id' => $factTableID,
			    'fact_id' => $evidenceExternalDbID,
			    'evidence_group_id' => 1
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
	    $self->log("$probeID not found in RAD.ShortOligoFamily");
	    print LOGFILE "$probeID not found in RAD.ShortOligoFamily\n";
	    $nCENotFound++;
	}
	
	$counter++;
	if($counter % 100 ==0) { $self->log("$counter/$nToPopulate rows processed - $nProbePopulated entries populated");}
    }
    
    close(LOGFILE);
    $self->log ("CompositeElement not found = $nCENotFound; DbRefID not found = $nDbRefIDNotFound; rows populated = $nProbePopulated in RAD.CompositeElementDbRef");
    return $nProbePopulated;
}


sub populateEleDbRef {
    my($self, $hash, $arrayDesignID, $evidenceExternalDbID, $dbRefOrNASeqExternalDbID, $logFile, $view) = @_;
    
    my $nToPopulate = scalar keys(%$hash);
    
    my ($sql, $queryHandle, $sth, $elementID, $dbRefID, $eleID);
    my $nProbePopulated = 0;
    my $nENotFound =0;
    my $nDbRefIDNotFound=0;

    open(LOGFILE, ">$logFile") ||  die ("Can't open $logFile\n");

    my ($targetTableID, $factTableID) = $self->_getTargetAndFactTableIds('ElementDbRef');
    
    my $counter = 0;

    while (my ($geneLocation, $annotationListIDRef) = each(%$hash)) {
      if(my $elementID = $self->_getElementId($geneLocation, $view, $arrayDesignID)) {
	    
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
			    'fact_id' => $evidenceExternalDbID,
			    'evidence_group_id' => 1
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
	    $self->log("$geneLocation not found in $view");
	    print LOGFILE "$geneLocation not found in $view\n";
	    $nENotFound++;
	}
	$counter++;
	if($counter % 100 ==0) { $self->log("$counter/$nToPopulate rows processed - $nProbePopulated entries populated");}

    }
    
    close LOGFILE;
    
    $self->log ("Element not found = $nENotFound; DbRefID not found = $nDbRefIDNotFound; rows populated = $nProbePopulated in RAD.ElementDbRef");
    return $nProbePopulated;
}



sub populateCompEleNaSeq {
    my($self, $hash, $arrayDesignID, $evidenceExternalDbID, $dbRefOrNASeqExternalDbID, $logFile, $view, $identifier) = @_;
    
    my $nToPopulate = scalar keys(%$hash);
    
    my ($sql, $queryHandle, $sth, $compositeElementID, $naSeqID, $compEleID);
    my $nProbePopulated = 0;
    my $nCENotFound =0;
    my $nNASeqIDNotFound=0;
    
    open(LOGFILE, ">$logFile") ||  die ("Can't open $logFile\n");

    my ($targetTableID, $factTableID) = $self->_getTargetAndFactTableIds('CompositeElementNASequence');
    
    my $counter = 0;
    while (my ($probeID, $annotationListIDRef) = each(%$hash)) {
	
	$sql = "SELECT composite_element_id FROM $view WHERE $identifier = '$probeID' and array_design_id = $arrayDesignID";
	$queryHandle = $self->getQueryHandle();
	$sth = $queryHandle->prepareAndExecute($sql);
	($compositeElementID) = $sth ->fetchrow_array();
	
	if(defined $compositeElementID) {

	    my @annotationListID = @$annotationListIDRef;
	    foreach(@$annotationListIDRef) {
		
		my @annot = split(/\./, $_);
		my $annotationID = @annot[0];
		
		$sql = "SELECT na_sequence_id FROM DoTS.ExternalNASequence WHERE source_id = '$annotationID' and external_database_release_id =$dbRefOrNASeqExternalDbID";
		
		$queryHandle = $self->getQueryHandle();
		$sth = $queryHandle->prepareAndExecute($sql);
		($naSeqID) = $sth ->fetchrow_array();
		
		if(defined $naSeqID) {
		    
		    $sql = "SELECT composite_element_na_seq_id FROM RAD.CompositeElementNASequence WHERE composite_element_id = $compositeElementID AND na_sequence_id = $naSeqID";
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
			    'fact_id' => $evidenceExternalDbID,
			    'evidence_group_id' => 1
			    });
			
			$newEvidence->submit();
			
			$nProbePopulated++;
			$self->undefPointerCache();
		    }
		}
		else {
		    $self->log("$annotationID not found in DoTS.ExternalNASequence");
		    print LOGFILE "$annotationID not found in DoTS.ExternalNASequence\n";
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
	if($counter % 100 ==0) { $self->log("$counter/$nToPopulate rows processed - $nProbePopulated entries populated");}
    }
    close(LOGFILE);
    $self->log ("CompositeElement not found = $nCENotFound; naSeqID not found = $nNASeqIDNotFound; rows populated = $nProbePopulated in RAD.CompositeElementNaSequence");
    return $nProbePopulated;
}


sub populateEleNaSeq {
    my($self, $hash, $arrayDesignID, $evidenceExternalDbID, $dbRefOrNASeqExternalDbID, $logFile, $view) = @_;
    
    my $nToPopulate = scalar keys(%$hash);
    
    my ($sql, $queryHandle, $sth, $elementID, $naSeqID, $eleID);
    my $nProbePopulated = 0;
    my $nENotFound =0;
    my $nNASeqIDNotFound=0;

    open(LOGFILE, ">$logFile") ||  die ("Can't open $logFile\n");

    my ($targetTableID, $factTableID) = $self->_getTargetAndFactTableIds('ElementNASequence');
    
    my $counter = 0;

    while (my ($geneLocation, $annotationListIDRef) = each(%$hash)) {	
	if(my $elementID = $self->_getElementId($geneLocation, $view, $arrayDesignID)) {
	    
	    my @annotationListID = @$annotationListIDRef;
	    
	    foreach(@annotationListID) {
		
		my @annot = split(/\./, $_);
		my $annotationID = @annot[0];
		
		$sql = "SELECT na_sequence_id FROM DoTS.ExternalNASequence WHERE source_id = '$annotationID' AND external_database_release_id =$dbRefOrNASeqExternalDbID";
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
			    'na_sequence_id' => $naSeqID
			    });
			
			$newENASeq->submit();
			my $targetID = $newENASeq->getId();
			
			my $newEvidence = GUS::Model::DoTS::Evidence->new({
			    'target_table_id' => $targetTableID,
			    'target_id' => $targetID,
			    'fact_table_id' => $factTableID,
			    'fact_id' => $evidenceExternalDbID,
			    'evidence_group_id' => 1
			    });
			
			$newEvidence->submit();
			
			$nProbePopulated++;
			$self->undefPointerCache();
		    }
		}
		else {
		    $self->log("$annotationID not found in DoTS.ExternalNASequence");
		    print LOGFILE "$annotationID not found in DoTS.ExternalNASequence\n";
		    $nNASeqIDNotFound++;
		}
	    }
	}
	else {
	    $self->log("$geneLocation not found in $view");
	    print LOGFILE "$geneLocation not found in $view\n";
	    $nENotFound++;
	}
	$counter++;
	if($counter % 100 ==0) { $self->log("$counter/$nToPopulate rows processed - $nProbePopulated entries populated");}
    }
    
    close LOGFILE;
    
    $self->log ("Element not found = $nENotFound; NASequenceID not found = $nNASeqIDNotFound; rows populated = $nProbePopulated in RAD.ElementNaSequence");
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
	
	if($content[$i] =~ /$columnIDName/ || $content[$i] =~ /$columnRefIDName/) {
	    
	    @header = split(/$separator/, $content[$i]);
	    
	    foreach(@header) { $_ =~ s/\"//g; }
	    
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
	
	my @row = split(/$separator/, $content[$i]);
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


sub _getTargetAndFactTableIds {
  my ($self, $tableInfoName) = @_;

  my $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = '$tableInfoName' and d.name = 'RAD'";

  my $queryHandle = $self->getQueryHandle();
  my $sth = $queryHandle->prepareAndExecute($sql);

  my ($targetTableID) = $sth ->fetchrow_array();
  if(!defined $targetTableID) { die "Cannot find RAD.$tableInfoName table\n"; }

  $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = 'ExternalDatabaseRelease' and d.name = 'SRes'";

  $queryHandle = $self->getQueryHandle();
  $sth = $queryHandle->prepareAndExecute($sql);
  my ($factTableID) = $sth ->fetchrow_array();

  if(!$factTableID) { die "Cannot find SRes.ExternalDatabaseRelease\n"; }

  return($targetTableID, $factTableID);
}


sub _getElementId {
  my ($self, $geneLocation, $view, $arrayDesignID) = @_;

  my @gc = split(/\./, $geneLocation);
  my $sql;

  if($view eq 'RAD.Spot') {
    $sql = "SELECT element_id FROM $view 
                 WHERE array_row=$gc[0] and array_column=$gc[1] and grid_row=$gc[2] and 
                       grid_column=$gc[3] and sub_row=$gc[4] and sub_column=$gc[5] and array_design_id = $arrayDesignID";
  }

  elsif($view eq 'RAD.RTPCRElement') {
    my ($externalDatabaseReleaseId, $sourceId) = @gc;
    $sql = "SELECT element_id FROM $view 
                 WHERE external_database_release_id = $externalDatabaseReleaseId and source_id = $sourceId and array_design_id = $arrayDesignID";
  }

  else {
    $self->log("Unrecognized View: $view");
    print LOGFILE "Unrecognized View: $view\n";
  }

  my $queryHandle = $self->getQueryHandle();
  my $sth = $queryHandle->prepareAndExecute($sql);
  my ($elementID) = $sth ->fetchrow_array();

  return($elementID);
}


sub undoTables {
    my ($self) = @_;

    return ('RAD.CompositeElementNASequence', 'RAD.ElementNASequence', 'RAD.CompositeElementDBRef', 'RAD.ElementDbRef', 'DoTS.Evidence');
}

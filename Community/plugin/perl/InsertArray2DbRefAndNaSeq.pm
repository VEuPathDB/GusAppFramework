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

#todo:restart, check if entry already there, multiple ids

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

# TODO: see insertradanalysis
my $purposeBrief = <<PURPOSEBRIEF;
Populate mappings in RAD.ElementDbRef and RAD.CompositeElementsDbRef between SRes.DbRef and DoTs.NaSequence and RAD.ShortOligoFamily or RAD.Spot from Affymetrix or PancChips annotations file.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Populate mappings between SRes.DbRef and DoTs.NaSequence and RAD.ShortOligoFamily or RAD.Spot from Affymetrix or PancChips annotations file.  Mappings are inserted in RAD.CompositeElementDbRef or RAD.ElementDbRef.
PLUGIN_PURPOSE

my $tablesAffected = [
['RAD.CompositeElementDbRef','New entries are placed in this table', 'RAD.CompositeElementNaSequence', 'New entries are placed in this table', 'RAD.ElementDbRef', 'New entries are placed in this table', 'RAD.ElementNaSequence', 'New entries are placed in this table']
];

my $tablesDependedOn = ['Sres.DbRef', 'Dots.NaSequence', 'Dots.Evidence'];

my $howToRestart = <<PLUGIN_RESTART;
TODO
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
unknown
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
TODO
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
		       cvsRevision =>  '$Revision: 4127 $', #CVS fills this in
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
    my $arrayDesignId = $self->getArrayDesignId();

    my $evidenceExternalDbId = $self->getExternalDbId($self->getArg('evidenceExternalDbName'), $self->getArg('evidenceExternalDbVersion'));
    my $dbRefOrNASeqExternalDbId = $self->getExternalDbId($self->getArg('evidenceExternalDbName'), $self->getArg('evidenceExternalDbVersion'));
    
    my $fileName = $self->getArg('annotationFileName');
    my $separator = $self->getArg('separator');
    my $refIDColumnName = $self->getArg('refIDColumnName');
    my $annotIDColumnName = $self->getArg('annotationIDColumnName');
    
    my $hashRef = $self->parseAnnotationFile($fileName, $separator, $refIDColumnName, $annotIDColumnName);
    
    $self->log("$technologyType - $databaseName\n");
    
    if($technologyType =~ /oligo/i) {
	if($databaseName eq "DbRef") {
	    $nrecords = $self->populateCompEleDbRef($hashRef, $arrayDesignId, $evidenceExternalDbId, $dbRefOrNASeqExternalDbId);
	}
	elsif($databaseName eq "NaSeq")  {
	    $nrecords = $self->populateCompEleNaSeq($hashRef, $arrayDesignId, $evidenceExternalDbId, $dbRefOrNASeqExternalDbId);
	}
	else {
	    die("$databaseName is an undefined type\n");
	}
    }
    elsif($technologyType =~ /spot/i) {
	if($databaseName eq "DbRef") {
	    $nrecords = $self->populateEleDbRef($hashRef, $arrayDesignId, $evidenceExternalDbId, $dbRefOrNASeqExternalDbId);
	}
	elsif($databaseName eq "NaSeq")  {
	    $nrecords = $self->populateEleNaSeq($hashRef, $arrayDesignId, $evidenceExternalDbId, $dbRefOrNASeqExternalDbId);
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
    my($self, $hash, $arrayDesignId, $evidenceExternalDbId, $dbRefOrNASeqExternalDbId) = @_;
    
    my $n = scalar keys(%$hash);
    
    my ($sql, $queryHandle, $sth, $compositeElementId, $dbRefId);
    my $nProbePopulated = 0;
    my $nCENotFound =0;
    my $nDbRefIdNotFound=0;
        
    $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = 'CompositeElementDbRef' and d.name = 'RAD'";
    
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my ($targetTableId) = $sth ->fetchrow_array();
    if(!defined $targetTableId) { die "Cannot find RAD.CompositeElementDbRef' table\n"; }
    
    $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = 'ExternalDatabaseRelease' and d.name = 'SRes'";
    
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my ($factTableId) = $sth ->fetchrow_array();
    
    if(!$factTableId) { die "Cannot find SRes.ExternalDatabaseRelease\n"; }
    
    my $counter = 0;
    while (my ($probe, $annotationId) = each(%$hash)) {
		
	$sql = "SELECT composite_element_id FROM RAD.shortoligofamily WHERE name = '$probe' and array_design_id = $arrayDesignId";
	$queryHandle = $self->getQueryHandle();
	$sth = $queryHandle->prepareAndExecute($sql);
	($compositeElementId) = $sth ->fetchrow_array();
	
	if(defined $compositeElementId) {
	    
	    $sql = "SELECT db_ref_id FROM sres.dbref WHERE primary_identifier = '$annotationId' and external_database_release_id =$dbRefOrNASeqExternalDbId";
	    
	    $queryHandle = $self->getQueryHandle();
	    $sth = $queryHandle->prepareAndExecute($sql);
	    ($dbRefId) = $sth ->fetchrow_array();
	    
	    if(defined $dbRefId) {
		
		my $newCEDbRef = GUS::Model::RAD::CompositeElementDbRef->new({
		    'composite_element_id' => $compositeElementId,
		    'db_ref_id' => $dbRefId
		    });
		$newCEDbRef->submit();
		my $targetId = $newCEDbRef->getID();
		
		my $newEvidence = GUS::Model::DoTs::Evidence->new({
		    'target_table_id' => $targetTableId,
		    'target_id' => $targetId,
		    'fact_table_id' => $factTableId,
		    'fact_id' => $evidenceExternalDbId
		    });
		
		$newEvidence->submit();
		
		$nProbePopulated++;
		$self->undefPointerCache();
	    }
	    else {
		$self->log("Db Ref ID [$dbRefId] not found");
		$nDbRefIdNotFound++;
	    }
	}
	else {
	    $self->log("CompositeElementID [$compositeElementId] not found");
	    $nCENotFound++;
	}
	
	if($counter % 100 ==0 and $counter!=0) { $self->log("$counter entries populated in RAD.CompositeElementDbRef");}
	$counter++;
    }
    # TODO
    # generate a file with list of composite_ele_id/annotation_id not found

    $self->log ("CompositeElement not found = $nCENotFound; DbRefId not found = $nDbRefIdNotFound; rows populated = $nProbePopulated");
    return $nProbePopulated;
}


sub populateEleDbRef {
    my($self, $hash, $arrayDesignId, $evidenceExternalDbId, $dbRefOrNASeqExternalDbId) = @_;
    
    my $n = scalar keys(%$hash);
    
    my ($sql, $queryHandle, $sth, $elementId, $dbRefId);
    my $nProbePopulated = 0;
    my $nENotFound =0;
    my $nDbRefIdNotFound=0;
    
    $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = 'ElementDbRef' and d.name = 'RAD'";
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my ($targetTableId) = $sth ->fetchrow_array();
    if(!$targetTableId) { die "Cannot find RAD.ElementDbRef\n"; }
    
    $sql = "SELECT t.table_id from Core.tableinfo t, Core.databaseinfo d WHERE t.database_id= d.database_id and t.name = 'ExternalDatabaseRelease' and d.name = 'SRes'";
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my ($factTableId) = $sth ->fetchrow_array();    
    if(!$factTableId) { die "Cannot find SRes.ExternalDatabaseRelease\n"; }
    
    my $counter = 0;

    while (my ($geneLocation, $annotationId) = each(%$hash)) {
	
	my @gc = split(/\./, $geneLocation);
	
	$sql = "SELECT element_id FROM RAD.spot WHERE array_row=$gc[0] and array_column=$gc[1] and grid_row=$gc[2] and grid_column=$gc[3] and sub_row=$gc[4] and sub_column=$gc[5] and array_design_id = $arrayDesignId";
	
	$queryHandle = $self->getQueryHandle();
	$sth = $queryHandle->prepareAndExecute($sql);
	($elementId) = $sth ->fetchrow_array();
	
	if(!$elementId) { 
	    
	    $sql = "SELECT db_ref_id FROM sres.dbref WHERE primary_identifier = '$annotationId' AND external_database_release_id =$dbRefOrNASeqExternalDbId";
	    
	    $queryHandle = $self->getQueryHandle();
	    $sth = $queryHandle->prepareAndExecute($sql);
	    ($dbRefId) = $sth ->fetchrow_array();
	    
	    if(!$dbRefId) {

		my $newEDbRef = GUS::Model::RAD::ElementDbRef->new({
		    'element_id' => $elementId,
		    'db_ref_id' => $dbRefId
		    });
		
		my $newEvidence = GUS::Model::DoTs::Evidence->new({
		    'target_table_id' => $targetTableId,
		    'target_id' => $newEDbRef,
		    'fact_table_id' => $factTableId,
		    'fact_id' => $dbRefOrNASeqExternalDbId
		    });
		
		$nProbePopulated++;
		$self->undefPointerCache();
	    }
	    else {
		$nDbRefIdNotFound++;	
	    }
	}
	else {
	    $nENotFound++;
	}
	if($counter % 100 ==0) { $self->log("$counter entries populated in RAD.ElementDbRef");}
	$counter++;
	
    }

    
    $self->log ("Element not found = $nENotFound; DbRefId not found = $nDbRefIdNotFound; rows populated = $nProbePopulated");
    return $nProbePopulated;
}


sub parseAnnotationFile {
    my ($self, $annotFile, $separator, $columnRefIDName, $columnIDName)  = @_;
    
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

    print "indexheader = $indexHeader\n";
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
    
    print "ref col=$columnRefIDName  ref id = $columnIDName\n";
    for(my $i=$indexHeader+1; $i<scalar @content; $i++) {
	$content[$i] =~ s/\"//g;
	
	my @row = split(/$separator/, $content[$i]);
	print "@row\n";
	
	print "data: $row[$columnRefID]  $row[$columnID]\n";
	
	if(defined $row[$columnRefID] & defined $row[$columnID]) {
	    $hash{$row[$columnRefID]} = $row[$columnID];
	}
    }
    
    close FILE;


    my $nRecords = scalar keys(%hash);
    $self->log("$nRecords records found in $annotFile");
    return (\%hash);
}


sub getArrayDesignId {
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
    my ($arrayDesignId) = $sth ->fetchrow_array();
    
    if(!defined $arrayDesignId) {
	die("No ARRAY_DESIGN_ID corresponding to NAME '$arrayDesignName' (version '$arrayDesignversion')"); 
    }
    $self->log("array_design_id = $arrayDesignId"); 
    return $arrayDesignId;
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

sub getExternalDbId {
    my($self, $dbName, $dbVersion) = @_;
    
    my $sql = "SELECT i.external_database_release_id FROM SRes.externaldatabaserelease i, SRes.externaldatabase e where i.version = '$dbVersion' and e.name = '$dbName'";
    
    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);
    my ($externalDbID) = $sth ->fetchrow_array();
    
    if(!defined $externalDbID) {
	die("No External Database Release Id corresponding to NAME '$dbName' (version '$dbVersion')"); 
    }
    $self->log("external_db_id = $externalDbID"); 
    return $externalDbID;
}

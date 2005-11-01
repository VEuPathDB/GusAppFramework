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
     
stringArg({name => 'externalDbName',
	   descr => 'name of the external database corresponding to the annotation file',
	   constraintFunc => undef,
	   reqd => 1,
	   isList => 0,
        }),

stringArg({name => 'externalDbVersion',
	    descr => 'version of the external database corresponding to the annotation file',
	    constraintFunc => undef,
	    reqd => 0,
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

integerArg({name => 'dbRefExternalDatabaseReleaseId',
	    descr => 'External Database Release ID of the Entrez Gene Database to link to',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
            mustExist => 1,
	   }),

enumArg({name => 'dataType',
	    descr => 'data type to be used (PancChip or Affymetrix)',
	    constraintFunc => undef,
	    reqd => 1,
	    isList => 0,
            mustExist => 1,
            enum => "PancChip,Affymetrix",
	   }),

 ];


my $purposeBrief = <<PURPOSEBRIEF;
Populate mappings in Rad.ElementDbRef and Rad.CompositeElementsDbRef between SRes.DbRef and DoTs.NaSequence and Rad.ShortOligoFamily or Rad.Spot from Affymetrix or PancChips annotations file.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Populate mappings between SRes.DbRef and DoTs.NaSequence and Rad.ShortOligoFamily or Rad.Spot from Affymetrix or PancChips annotations file.  Mappings are inserted in Rad.CompositeElementDbRef or Rad.ElementDbRef.
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
		       cvsRevision =>  '$Revision: 3956 $', #CVS fills this in
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
    
    my $dataType = $self->getArg('dataType'),
    my $nrecords;
    
    my $annotFileName = $self->getAnnotationFileName();
    my $arrayDesignId = $self->getArrayDesignId();
        
    if($dataType eq "Affymetrix") {
	
	my $hash_ref = $self->parseAffyFile($annotFileName);
	$nrecords = $self->populateCompEleDbREf($hash_ref, $arrayDesignId);	
    }
    elsif($dataType eq "PancChip") {
	my $hash_ref = $self->parsePancChipFile($annotFileName);
	$nrecords = $self->populateEleDbREf($hash_ref, $arrayDesignId);
    }
    else {
	die("$self->getArg('dataType') is an undefined type\n");
    }
    
    my $result = "$nrecords records created.";
    
    return $result ;
}


################################
# populate CompEleDbREf  table
################################
sub populateCompEleDbREf {
    my($self, $hash, $arrayDesignId) = @_;
    
    my $n = scalar keys(%$hash);
    
    my ($sql, $queryHandle, $sth, $compositeElementId, $dbRefId);
    my $nProbePopulated = 0;
    my $nCENotFound =0;
    my $nDbRefIdNotFound=0;

    my $dbRefExtDbRelId = $self->getArg('dbRefExternalDatabaseReleaseId');
    
    $sql = "SELECT table_id from core.tableinfo where name ='CompositeElementDbRef'";
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my $targetTableId = $sth ->fetchrow_array();
    
    $sql = "SELECT table_id from core.tableinfo where name ='ExternalDatabaseRelease'";
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my $factTableId = $sth ->fetchrow_array();
    
    while (my ($probe, $geneId) = each(%$hash)) {
	$sql = "SELECT composite_element_id FROM rad.shortoligofamily WHERE name = '$probe' and array_design_id = $arrayDesignId";
	$queryHandle = $self->getQueryHandle();
	$sth = $queryHandle->prepareAndExecute($sql);
	$compositeElementId = $sth ->fetchrow_array();
	
	if(!$compositeElementId) {
	    $nCENotFound++;
	    next;
	}
	
	$sql = "SELECT db_ref_id FROM sres.dbref WHERE primary_identifier = '$geneId' and external_database_release_id =$dbRefExtDbRelId";
	
	$queryHandle = $self->getQueryHandle();
	$sth = $queryHandle->prepareAndExecute($sql);
	$dbRefId = $sth ->fetchrow_array();
	
	if(!$dbRefId) {
	    $nDbRefIdNotFound++;
	    next;
	}
	
	my $newCEDbRef = GUS::Model::RAD::CompositeElementDbRef->new({
	    'composite_element_id' => $compositeElementId,
	    'db_ref_id' => $dbRefId
	    });
	
	my $newEvidence = GUS::Model::DoTs::Evidence->new({
	    'target_table_id' => $targetTableId,
	    'target_id' => $newCEDbRef,
	    'fact_table_id' => $factTableId,
	    'fact_id' => $dbRefExtDbRelId
	    });
	
	$nProbePopulated++;
	$self->undefPointerCache();
    }
    $self->log ("CompositeElement not found = $nCENotFound; DbRefId not found = $nDbRefIdNotFound; rows populated = $nProbePopulated");
    return $nProbePopulated;
}


##################################################
# populate EleDbREf table
##################################################
sub populateEleDbREf {
    my($self, $hash, $arrayDesignId) = @_;
    
    my $n = scalar keys(%$hash);
    
    my ($sql, $queryHandle, $sth, $elementId, $dbRefId);
    my $nProbePopulated = 0;
    my $nENotFound =0;
    my $nDbRefIdNotFound=0;
    
    
    $sql = "SELECT table_id from core.tableinfo where name ='ElementDbRef'";
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my $targetTableId = $sth ->fetchrow_array();
    
    $sql = "SELECT table_id from core.tableinfo where name ='ExternalDatabaseRelease'";
    $queryHandle = $self->getQueryHandle();
    $sth = $queryHandle->prepareAndExecute($sql);
    my $factTableId = $sth ->fetchrow_array();    
    
    my $dbRefExtDbRelId = $self->getArg('dbRefExternalDatabaseReleaseId');
    
    while (my ($geneLocation, $geneId) = each(%$hash)) {
	
	my @gc = split(/\./, $geneLocation);
	
	$sql = "SELECT element_id FROM rad.spot WHERE array_row=$gc[0] and array_column=$gc[1] and grid_row=$gc[2] and grid_column=$gc[3] and sub_row=$gc[4] and sub_column=$gc[5] and array_design_id = $arrayDesignId";
	
	$queryHandle = $self->getQueryHandle();
	$sth = $queryHandle->prepareAndExecute($sql);
	$elementId = $sth ->fetchrow_array();
	
	if(!$elementId) { 
	    $nENotFound++;
	    next;
	}
	
	$sql = "SELECT db_ref_id FROM sres.dbref WHERE primary_identifier = '$geneId' and external_database_release_id =$dbRefExtDbRelId";
	
	
	$queryHandle = $self->getQueryHandle();
	$sth = $queryHandle->prepareAndExecute($sql);
	$dbRefId = $sth ->fetchrow_array();
	
	if(!$dbRefId) {
	    #$self->log("Cannot find db_ref_id for '$geneId'");
	    $nDbRefIdNotFound++;
	    next;
	}
    	
	my $newEDbRef = GUS::Model::RAD::ElementDbRef->new({
	'element_id' => $elementId,
	'db_ref_id' => $dbRefId
	});
	
	my $newEvidence = GUS::Model::DoTs::Evidence->new({
	    'target_table_id' => $targetTableId,
	    'target_id' => $newEDbRef,
	    'fact_table_id' => $factTableId,
	    'fact_id' => $dbRefExtDbRelId
	    });
	
	$nProbePopulated++;
	$self->undefPointerCache();
    }
    $self->log ("Element not found = $nENotFound; DbRefId not found = $nDbRefIdNotFound; rows populated = $nProbePopulated");
    return $nProbePopulated;
}


sub parseAffyFile {
     my($self, $fileName) = @_;
     
     open(FILE, $fileName) || (die "could not open file '$fileName'\n");
     
     my %hash;
     my @content = <FILE>;
     chomp @content;
     
     for(my $i=1; $i<scalar @content; $i++) {
	 
	 my @row = split(/\",\"/, $content[$i]);
	 
	 if(defined $row[0] & defined $row[8]) {
	     $row[0]=~s/\"//g;
	     $row[8]=~s/\"//g;
	     $hash{$row[0]} = $row[8];
	 }
     }
          
     close FILE;
     
     my $nRecords = scalar keys(%hash);
     $self->log("$nRecords records found in $fileName");
     return (\%hash);
}


#################################################
# parser for pancChip files
#################################################
sub parsePancChipFile {
    my($self, $fileName) = @_;
    
    open(FILE, $fileName) || (die "could not open file '$fileName'\n");
    
    my %hash;
    my @content = <FILE>;
    chomp @content;
    
    for(my $i=2; $i<scalar @content; $i++) {
	
	my @row = split(/\t/, $content[$i]);
	if(defined $row[0] & defined $row[5]) {
	    $row[0]=~s/\"//g;
	    $row[5]=~s/\"//g;
	    $hash{$row[0]} = $row[5];
	}
    }
    close FILE;
    
    my $nRecords = scalar keys(%hash);
    $self->log("$nRecords records found in $fileName");
    
    return (\%hash);
}


######################################################
# return arraydesignid from arrayDesignName
# and arrayDesignVersion
######################################################
sub getArrayDesignId {
    my($self) = @_;
    my $arrayDesignName = $self->getArg('arrayDesignName');
    my $arrayDesignversion = $self->getArg('arrayDesignVersion');

    if(defined $arrayDesignversion) {
	my $sql = "SELECT array_design_id FROM rad.arraydesign WHERE name='$arrayDesignName' and version ='$arrayDesignversion'";
    }
    else {
	my $sql = "SELECT array_design_id FROM rad.arraydesign WHERE name='$arrayDesignName'";
    }
    
    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);
    my $arrayDesignId = $sth ->fetchrow_array();
    
    if(!$arrayDesignId) {
	die("No ARRAY_DESIGN_ID corresponding to NAME '$arrayDesignName' (version '$arrayDesignversion')"); 
    }
    $self->log("array_design_id = $arrayDesignId"); 
    return $arrayDesignId;
}


######################################################
# return getAnnotationFileName from externalDbName
# and externalDbVersion
######################################################
sub getAnnotationFileName {
    my($self) = @_;
    
    my $externalDbName = $self->getArg('externalDbName');
    my $externalDbVersion = $self->getArg('externalDbVersion');

    if(defined $externalDbVersion) {
	my $sql = "SELECT file_name FROM sres.externaldatabaserelease ed, sres.externaldatabase e WHERE e.name='$externalDbName' and ed.external_database_id=e.external_database_id and ed.version='$externalDbVersion'";
    }
    else {
	my $sql = "SELECT file_name FROM sres.externaldatabaserelease ed, sres.externaldatabase e WHERE e.name='$externalDbName' and ed.external_database_id=e.external_database_id";
    }
    
    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);
    
    my $externalDbFileName = $sth ->fetchrow_array();
    
    if(!$externalDbFileName) {
	die("No filename corresponding to database $externalDbName (release $externalDbVersion)"); 
    }
    
    $self->log("file name = $externalDbFileName");
    return $externalDbFileName;
}

1;

package GUS::GOPredict::Plugin::FixDeletedProteins;
@ISA = qw( GUS::PluginMgr::Plugin);


use GUS::Model::DoTS::GOAssociation;
use GUS::Model::DoTS::GOAssociationInstance;

use lib "$ENV{GUS_HOME}/lib/perl";

use strict 'vars';

use FileHandle;

my $ruleTableId = 330;
my $simTableId = 219;
my $instanceTableId = 3177;


my $manuallyReviewedLOE = 4;
my $proteinTableId = 180;
my $curatorLoeId = 4;
my $goExtDb = 6918;
my $output = FileHandle->new('>>DeletedAssociations');

my $reviewedId = 1;

#Note:  This plugin is intended to be run as a preprocess before implementing
#the new style GO Association system.  It will likely not be run again; however
#it may be kept for posterity.

sub new{
    my $class = shift;
    my $self = bless{}, $class;
    
    my $usage = "Recover deleted associations between proteins and GO Terms"; 
    my $easycsp =
	[
	 {o=> 'file_path',
	  h=> 'if set, get proteins to recover associations for from this file',
          t=> 'string',
      }, 
	 {o=> 'recover_deleted',
	  h=> 'used to recover deleted associations between proteins and GO Terms',
          t=> 'boolean',
      },
	 {o=> 'deprecate_automated_instances',
	  h=> 'used to deprecate all instances that are not manually reviewed',
          t=> 'boolean',
      },
	 {o=> 'deprecate_old_instances',
	  h=> 'used to deprecate instances older than the current go version',
          t=> 'boolean',
      },
	 {o=> 'reassign_evidence',
	  h=> 'used to switch old evidence pointing to TranslatedAASequence Associations to Instances',
	  t=> 'boolean',
      },
	 {o=> 'reassign_predicted_evidence',
	  h=> 'used to switch old predicted evidence pointing to TranslatedAASequence Associations to Instances',
	  t=> 'boolean',
      },

	 {o=> 'update_is_not_policy',
	  h=> 'Used to adjust Associations to conform to new policy of not allowing a descendent of a rejected association to be verified',
	  t=> 'boolean',
      },

	 

	 ];
    
    $self->initialize({requiredDbVersion => {},
		       cvsRevision => '$Revision$', # cvs fills this in!
	 		   cvsTag => '$Name$', # cvs fills this in!
 	 	       name => ref($self),
		       revisionNotes => '',
		       easyCspOptions => $easycsp,
		       usage => $usage,
		   });
    
    return $self;
}

sub isReadOnly {0};

sub run {
    my ($self) = @_;
    
    my $msg;
    if ($self->getCla->{recover_deleted}){
	
	my $gusGoMap = $self->_makeGoMap();
	my $filePath = $self->getCla->{file_path};
	my $proteinGoMap;
	if ($filePath){
	    $proteinGoMap = $self->_getProteinGoMapFromFile($filePath);
	}
	else{
	    $proteinGoMap = $self->_getProteinGoMap();
	}
	$msg = $self->_findMissingProteins($proteinGoMap, $gusGoMap);
	return $msg;
    }
    elsif ($self->getCla->{deprecate_automated_instances}){
	
	#$self->_setAllInstancesToPrimary();
	my $msg = $self->_deprecateAutomatedInstances();
	return $msg;
    }
    
    elsif ($self->getCla->{deprecate_old_instances}){
	
	my $msg = $self->_deprecateOldInstances();
	return $msg;
    }

    elsif ($self->getCla->{reassign_evidence}){
	my $msg = $self->_reassignEvidence();
	return $msg;
    }

    elsif ($self->getCla->{reassign_predicted_evidence}){
	my $msg = $self->_reassignPredictedEvidence();
	return $msg;
    }

    elsif ($self->getCla->{update_is_not_policy}){
	my $msg = $self->_updateIsNots();
	return $msg;
    }

    else {
	$self->userError("please select a valid mode");
    }
}



sub _updateIsNots{

    my ($self) = @_;
    
    my $queryHandle = $self->getQueryHandle();
    my $db = $self->getDb(); #for undef pointer cache
    my $databaseAdapter = GUS::GOPredict::DatabaseAdapter->new($queryHandle, $db);

    my $goManager = GUS::GOPredict::GoManager->new($databaseAdapter);
    $goManager->setNewFunctionRootGoId("GO:0003674");

    my $proteinIds = $self->getProteinIdsForIsNotFix();

    $goManager->fixIsNots($proteinIds, $goExtDb, $proteinTableId);


}

sub getProteinIdsForIsNotFix{
    my ($self) = @_;
    my $sql = "select distinct p.protein_id
               from dots.protein p, dots.goassociation ga
               where ga.row_id = p.protein_id
               and ga.table_id = $proteinTableId
               and ga.is_deprecated != 1
               and ga.review_status_id != 0";
    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);
    
    my $proteinIds;

    while (my ($proteinId) = $sth->fetchrow_array()){
	push (@$proteinIds, $proteinId);
    }
    return $proteinIds;
}


################################
#Begin Reassign Evidence Methods
################################


#reassigns all similarities that have been assigned as evidence for a manually reviewed association
#(these similarities are facts for predicted TranslatedAASequence GO Associations which are themselves
#facts for manually reviewed Protein GO Associations).  The similarities become facts for evidence
#where the target is a newly created GO association instance. 

sub _reassignEvidence{

    my ($self) = @_;
    my $proteinHash = _getProteinInfo();

    foreach my $assocId (keys %$proteinHash) {

	my $allEvdInfo = $proteinHash->{$assocId};
	foreach my $evdId (keys %$allEvdInfo){
	    my $instance = $self->_initializeInstance($assocId);

	    my $evdInfo = $allEvdInfo->{$evdId};
	    my $factId = $evdInfo->{factId};
	    my $factTableId = $evdInfo->{factTableId};
	    my $factObject;
	    if ($factTableId == $simTableId){
		$factObject = GUS::Model::DoTS::Similarity->new();
		$factObject->setSimilarityId($factId);
		$factObject->retrieveFromDb();
		if ($factObject->getSubjectTableId()){  #some evidence points to similarities that have been deleted
		    $self->_submitNewEvidence($instance, $factObject);
		}
	    }
	    elsif ($factTableId == $ruleTableId){
		$factObject = GUS::Model::DoTS::AAMotifGoTermRule->new();
		$factObject->setAaMotifGoTermRuleId($factId);
		$factObject->retrieveFromDb();
		$self->_submitNewEvidence($instance, $factObject);
	    }
	    else {
		die ("error: received an unknown fact table id: $factTableId");
	    }
		    
	}
    }
}

sub _submitNewEvidence{

    my ($self, $instance, $factObject) = @_;
    $instance->addEvidence($factObject);
    $instance->setIsDeprecated(0);
    $instance->submit();
}

#was going to use this method but not anymore because similarities are not versioned, only deleted
sub _handleVersionedSim{
    my ($self, $instance, $factId) = @_;
    my $evdObject = GUS::Model::DoTS::Evidence->new();
    $instance->setIsDeprecated(1);
    $instance->submit();
    my $instanceId = $instance->getGoAssociationInstanceId();
    $evdObject->setFactId($factId);
    #$evdObject->setFactTableId($factTableId);
    $evdObject->setTargetId($instanceId);
    $evdObject->setTargetTableId($instanceTableId);
    $evdObject->submit();
}

sub _getProteinInfo{

    my ($self) = @_;
    my $sql = "select ga2.go_association_id, e1.evidence_id, e1.fact_table_id, e1.fact_id 
               from dots.goassociation ga1, dots.goassociation ga2, dots.evidence e1, dots.evidence e2 
               where e2.target_id = ga2.go_association_id and e2.target_table_id = 2844 and 
               e2.fact_id = ga1.go_association_id and e2.fact_table_id = 2844 and e1.target_table_id = 2844 and 
               e1.target_id = ga1.go_association_id and ga2.table_id = 180 and ga2.is_deprecated != 1";
    
    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);

    my $proteinHash;

    while (my ($assocId, $evidenceId, $factTableId, $factId) = $sth->fetchrow_array()){
	$proteinHash->{$assocId}->{$evidenceId}->{factTableId} = $factTableId;
	$proteinHash->{$assocId}->{$evidenceId}->{factId} = $factId;
    }
    return $proteinHash;


}

sub _initializeInstance{

    my ($self, $assocId) = @_;

    my $instance = GUS::Model::DoTS::GoAssociationInstance->new();
    $instance->setReviewStatusId($reviewedId);
    $instance->setGoAssocInstLoeId($manuallyReviewedLOE);
    $instance->setGoAssociationId($assocId);
    $instance->setIsNot(0);
    $instance->setIsPrimary(1);
}


#reassigns 
sub _reassignPredictedEvidence{

    my ($self) = @_;
    
    my $tasProteinMap = $self->_getTasProteinMap();

    my $tasSimMap = $self->_getTasSimMap();
    

}

sub _getTasSimMap{
    
    my ($self) = @_;




}

sub _getTasProteinMap{

    my ($self) = @_;

    my $sql = "select ts.aa_sequence_id, p.protein_id
               from dots.translatedAAsequence ts, dots.rnaInstance rs, dots.NaFeature f,
               dots.TranslatedAAfeature tf, dots.rna rna, dots.protein p
               where ts.aa_sequence_id = tf.aa_sequence_id
               and tf.na_feature_id = f.na_feature_id
               and f.na_feature_id = rs.na_feature_id
               and rs.rna_id = rna.rna_id
               and p.rna_id = rna.rna_id";

    my $tasProteinMap;
    
    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);
    while (my ($tasId, $proteinId) = $sth->fetchrow_array()){
	$tasProteinMap->{$tasId} = $proteinId;
    }
    return $tasProteinMap;
}


################################
#End Reassign Evidence Methods
################################






#used for getting proteins that have no remaining associations
sub _getProteinGoMapFromFile{
    
    my ($self, $filePath) = @_;
    
    my $proteinGoMap;
    
    $self->log("attempting to open $filePath");
    my $remainingProteinFile = FileHandle->new("$filePath") || $self->userError ("could not open $filePath");
    
    while (<$remainingProteinFile>){
	
	chomp;
	$proteinGoMap->{$_} = 1;
    }
    
    return $proteinGoMap;
}

sub _findMissingProteins{
    
    my ($self, $proteinGoMap, $gusGoMap) = @_;
    
    my $changeCount = 0;
    
    my $queryHandle = $self->getQueryHandle();
    my $sql = "select distinct ga.row_id, ga.go_term_id 
               from sres.goterm gt, dots.goAssociation ga, 
               sres.externaldatabaserelease r,
               dots.translatedAAsequence ts, dots.rnaInstance rs, dots.NaFeature f,
               dots.TranslatedAAfeature tf, dots.rna rna, dots.protein p
               where ts.aa_sequence_id = ga.row_id
               and ga.table_id = 337
               and gt.go_term_id = ga.go_term_id
               and gt.external_database_release_id = $goExtDb
               and ts.aa_sequence_id = tf.aa_sequence_id
               and tf.na_feature_id = f.na_feature_id
               and f.na_feature_id = rs.na_feature_id
               and rs.rna_id = rna.rna_id
               and p.rna_id = rna.rna_id
               and p.protein_id in ?";
    
    my $sth = $queryHandle->prepare($sql);
    
    my $proteinChangeCount;
    
    foreach my $proteinId (keys %$proteinGoMap){
	$sth->execute($proteinId);
	
	while (my ($taasId, $goTermId) = $sth->fetchrow_array()){
	    
	    if (!$proteinGoMap->{$proteinId}->{$goTermId}){
		$proteinChangeCount->{$proteinId} = 1;
		$changeCount++;
		
		$self->_makeGoAssociation($proteinId, $goTermId, $gusGoMap->{$goTermId});
	    }
	}
    }
    my $proteinsChanged = scalar keys %$proteinChangeCount;
    
    my $msg = "Made $changeCount new assocations and instances with is_not set to 1 for $proteinsChanged Proteins";
    
    return $msg;
}


#used for getting proteins that have remaining associations set to 'is'
sub _getProteinGoMap{
    
    my ($self) = @_;
    
    my $queryHandle = $self->getQueryHandle();
    my $sql = "select ga.row_id, ga.go_term_id
               from DoTS.GOAssociation ga, SRes.GOTerm gt 
               where ga.table_id = $proteinTableId
               and ga.go_term_id = gt.go_term_id
               and gt.external_database_release_id = $goExtDb
               and ga.review_status_id = 1";
    
    my $sth = $queryHandle->prepareAndExecute($sql);

    my $proteinGoMap;

    while (my ($proteinId, $goTermId) = $sth->fetchrow_array()){
	
	$proteinGoMap->{$proteinId}->{$goTermId} = 1;
    }

    return $proteinGoMap;
}

sub _makeGoMap{

    my ($self) = @_;

    my $queryHandle = $self->getQueryHandle();
    
    my $sql = "select go_term_id, go_id
               from sres.goterm
               where external_database_release_id = $goExtDb";
    
    my $sth = $queryHandle->prepareAndExecute($sql);

    my $gusGoMap;

    while (my ($gusId, $realId) = $sth->fetchrow_array()){
	$gusGoMap->{$gusId} = $realId;
    }
    return $gusGoMap;
}


sub _makeGoAssociation{

    my ($self, $proteinId, $goTermId, $realGoId) = @_;
    
    my $assoc = GUS::Model::DoTS::GOAssociation->new();
    $assoc->setTableId($proteinTableId);
    $assoc->setRowId($proteinId);
    $assoc->setGoTermId($goTermId);
    $assoc->setIsNot(1);
    $assoc->setDefining(0);
    $assoc->setReviewStatusId(1);
    $assoc->setIsDeprecated(0);

    my $instance = GUS::Model::DoTS::GOAssociationInstance->new();
    $instance->setGoAssocInstLoeId($curatorLoeId);
    $instance->setExternalDatabaseReleaseId($goExtDb);
    $instance->setIsNot(1);
    $instance->setIsPrimary(1); #what if not primary before?
    $instance->setIsDeprecated(0);
    $instance->setReviewStatusId(1);

    print $output "protein id:\t$proteinId\tgo term id:\t$realGoId\tgo term gus id: $goTermId\n";

    $assoc->addChild($instance);

    $assoc->submit();

    $self->undefPointerCache();
}


sub _setAllInstancesToPrimary{

    my ($self) = @_;

    my $queryHandle = $self->getQueryHandle();
    my $sql = "update DoTS.GOAssociationInstance gai
               set gai.is_primary = 1
               where gai.go_association_instance_id in 
               (select gait.go_association_instance_id
                from DoTS.GOAssociationInstance gait, DoTS.GOAssociation ga
                where ga.go_association_id = gai.go_association_id
                and ga.table_id = 180)";

    my $sth = $queryHandle->prepareAndExecute($sql);

#    my ($result) = $sth->fetchrow_array();
#    print STDERR "setAllInstancesToPrimary: affectd $result rows\n";

}

sub _deprecateAutomatedInstances{

    my ($self) = @_;

    my $queryHandle = $self->getQueryHandle();
  #  my $sql = "update DoTS.GOAssociationInstance gai
  #             set gai.is_deprecated = 1
  #             where gai.go_association_instance_id in 
  #             (select gait.go_association_instance_id
  #              from DoTS.GOAssociationInstance gait, DoTS.GOAssociation ga               
  #              where ga.go_association_id = gait.go_association_id
  #              and ga.table_id = 180
  #              and gait.review_status_id != 1
  #              and gait.is_deprecated = 0)"
#	      ;
    my $sql = "select go_association_instance_id, row_alg_invocation_id, go_assoc_inst_loe_id, go_association_id,
               review_status_id, is_not, is_primary, is_deprecated 
               from dots.goAssociationInstance
               where row_alg_invocation_id in (192173, 192005, 191935)";

    my $counter = 0;
    my $fh = FileHandle->new(">>storedAssociations");
    my $sth = $queryHandle->prepareAndExecute($sql);
    while (my @row = $sth->fetchrow_array()){
	foreach my $item (@row){
	    print $fh $item . " ";
	}
	print $fh "\n";
    }
    
#    my ($result) = $sth->fetchrow_array();
#    print STDERR "_deprecateAutomatedInstances: affectd $result rows\n";
    return "deleted $counter instances";
#    return "set is_deprecated = 1 for all non-manually reviewed instances of associations to proteins"; 

}

sub _deprecateOldInstances{

    my ($self) = @_;
    
    my $queryHandle = $self->getQueryHandle();
    
    my $sql = "update DoTS.GOAssociationInstance gai
               SET gai.is_deprecated = 1
               where gai.go_association_instance_id in 
               (select distinct gait.go_association_instance_id
               from DoTS.GOAssociationInstance gait, DoTS.GOAssociation ga, SRes.GOTerm gt
               where ga.go_association_id = gait.go_association_id
               and ga.go_term_id = gt.go_term_id
               and ga.table_id = 180
               and gt.external_database_release_id != $goExtDb)";

   
    my $sth = $queryHandle->prepareAndExecute($sql);
    
#    my ($result) = $sth->fetchrow_array();
#    print STDERR "_deprecateOldInstances: affectd $result rows\n";
    
    return "set is_deprecated = 1 for all non-manually reviewed instances of associations to proteins"; 
  
    
}

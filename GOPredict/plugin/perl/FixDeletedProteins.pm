package GUS::GOPredict::Plugin::FixDeletedProteins;
@ISA = qw( GUS::PluginMgr::Plugin);


use GUS::Model::DoTS::GOAssociation;
use GUS::Model::DoTS::GOAssociationInstance;

use lib "$ENV{GUS_HOME}/lib/perl";

use strict 'vars';

use FileHandle;

my $proteinTableId = 180;
my $curatorLoeId = 4;
my $goExtDb = 6529;
my $output = FileHandle->new('>>DeletedAssociations');


sub new{
    my $class = shift;
    my $self = bless{}, $class;
    
    my $usage = "Recover deleted associations between proteins and GO Terms"; 
    my $easycsp =
	[
	 
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
	my $proteinGoMap = $self->_getProteinGoMap();
#	my $proteinGoMap = $self->_getProteinGoMapFromFile();
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
    else {
	$self->userError("please select a valid mode");
    }
}

#used for getting proteins that have no remaining associations
sub _getProteinGoMapFromFile{

    my ($self) = @_;
    my $proteinGoMap;
    my $remainingProteinFile = FileHandle->new("<JoanProtein") || $self->userError ("could not open file");

    while (<$remainingProteinFile>){

	chomp;
	$proteinGoMap->{$_} = 1;
    }

    foreach my $protein (keys %$proteinGoMap){
	print STDERR "$protein\n";
    }
    print STDERR "total: " . scalar (keys %$proteinGoMap) . "\n";

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
    my $sql = "update DoTS.GOAssociationInstance gai
               set gai.is_deprecated = 1
               where gai.go_association_instance_id in 
               (select gait.go_association_instance_id
                from DoTS.GOAssociationInstance gait, DoTS.GOAssociation ga               
                where ga.go_association_id = gait.go_association_id
                and ga.table_id = 180
                and gait.review_status_id != 1
                and gait.is_deprecated = 0)"
	      ;

    my $sth = $queryHandle->prepareAndExecute($sql);

#    my ($result) = $sth->fetchrow_array();
#    print STDERR "_deprecateAutomatedInstances: affectd $result rows\n";

    return "set is_deprecated = 1 for all non-manually reviewed instances of associations to proteins"; 

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

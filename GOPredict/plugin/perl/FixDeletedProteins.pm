package GUS::GOPredict::Plugin::FixDeletedProteins;
@ISA = qw( GUS::PluginMgr::Plugin);


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
	 
#	 {o=> 'flat_file',
#	  h=> 'read data from this flat_file.  If blank, read data from all .ontology files in filepath',
#          t=> 'string',
#      }

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

    my $proteinGoMap = $self->_getProteinGoMap();
    my $gusGoMap = $self->_makeGoMap();
    $self->_findMissingProteins($proteinGoMap, $gusGoMap);
}

sub _findMissingProteins{
    
    my ($self, $proteinGoMap, $gusGoMap) = @_;
    
    my $queryHandle = $self->getQueryHandle();
    my $sql = "select ga.row_id, ga.go_term_id 
               from sres.goterm gt, dots.goAssociation ga, 
               sres.externaldatabaserelease r,
               dots.translatedAAsequence ts, dots.rnaInstance rs, dots.NaFeature f,
               dots.TranslatedAAfeature tf, dots.rna rna, dots.protein p
               where ts.aa_sequence_id = ga.row_id
               and ga.table_id = 337
               and gt.go_term_id = ga.go_term_id
               and r.external_database_release_id = $goExtDb
               and ts.aa_sequence_id = tf.aa_sequence_id
               and tf.na_feature_id = f.na_feature_id
               and f.na_feature_id = rs.na_feature_id
               and rs.rna_id = rna.rna_id
               and p.rna_id = rna.rna_id
               and p.protein_id in ?";

    my $sth = $queryHandle->prepare();
    foreach my $proteinId (keys %$proteinGoMap){
	$sth->execute($proteinId);

	while (my ($taasId, $goTermId) = $sth->fetchrow_array()){
	    
	    if (!$proteinGoMap->{$proteinId}->{$goTermId}){
		$self->_makeGoAssociation($proteinId, $goTermId, $gusGoMap->{$goTermId});
	    }
	}
    }
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



sub _getProteinGoMap{

    my ($self) = @_;

    my $queryHandle = $self->getQueryHandle();
    my $sql = "select ga.row_id, ga.go_term_id
               from DoTS.GOAssociation ga, DoTS.GOTerm gt, 
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



sub _makeGoAssociation{

    my ($self, $proteinId, $goTermId, $realGoId) = @_;
    
    my $assoc = GUS::Model::DoTS::GoAssociation->new();
    $assoc->setTableId($proteinTableId);
    $assoc->setRowId($proteinId);
    $assoc->setGoTermId($goTermId);
    $assoc->setIsNot(1);
    $assoc->setDefining(0);
    $assoc->setReviewStatusId(1);

    my $instance = GUS::Model::DoTS::GoAssociationInstance->new();
    $instance->setGoAssocInstLoeId($curatorLoeId);
    $instance->setExternalDatabaseReleaseId($goExtDb);
    $instance->setIsNot(1);
    $instance->setIsPrimary(1); #what if not primary before?
    $instance->setIsDeprecated(0);
    $instance->setReviewStatusId(1);

    print $output "protein id:\t$proteinId\tgo term id:\t$realGoId\n";

    $assoc->addChild($instance);

    $assoc->submit();

}

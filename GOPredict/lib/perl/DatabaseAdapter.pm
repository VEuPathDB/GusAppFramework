package GUS::GOPredict::DatabaseAdapter;

use GUS::GOPredict::Association;
use GUS::Model::DoTS::AAMotifGOTermRule;
use GUS::Model::DoTS::Similarity;
use GUS::Model::DoTS::MotifAASequence;

use strict;
use Carp;

#################################### DatabaseAdapter.pm ######################################

#################################### Constructor #############################################

sub new{

    my ($class, $queryHandle, $db) = @_;
    my $self = {};
    bless $self, $class;
    $self->setQueryHandle($queryHandle);
    $self->setDb($db);
    $self->setDbHandle($db->getDbHandle());
    #set this so that we will be working with the same session for all db interaction
    return $self;
}

#################################### Statement Handle Accessors ##############################

#These methods return statement handles that can be subsequently iterated through by the 
#calling method.  


#Retrieves all Protein IDs from the DoTS.Protein table that have GOAssociations
#with GO Terms from a particular GO Term release.
#
#param $taxonId:           If set, will only return protein IDs for a particular organisim
#                          specified by this ID.
#param $excludeAlgIdList:  If set, will ignore Protein IDs that have any GOAssociations
#                          that were processed in previous Plugin runs specified by this
#                          list.  Note that Protein IDs that were previously processed by
#                          these plugins, but had no GOAssociations that were created or
#                          modified at that time, will be processed again (generally, these
#                          Protein IDs take much less time to re-process, however).
sub getGusProteinIdResultSet{

    my ($self, $proteinTableId, $goVersion, $taxonId, $excludeAlgIdList) = @_;

    my $testIdSql ="";
    my $testProteinIds = $self->getTestProteinIds();
    my $excludeAlgIdsSql ="";

    if ($testProteinIds){
	$testIdSql = "and ga.row_id in (" . $testProteinIds . ")";
    }

    if ($excludeAlgIdList){
	$excludeAlgIdsSql = " and ga.row_id not in (select distinct ga.row_id from dots.goassociation ga 
                                 where row_alg_invocation_id in (" . join(",", @{$excludeAlgIdList}) . ")";
    }
    
    my $sql = "select distinct(p.protein_id) 
               from DoTS.Protein p, DoTS.GOAssociation ga, SRes.GoTerm gt,
                    dots.rnainstance rnai, dots.rnafeature rnaf, dots.assembly am
	       where ga.table_id = $proteinTableId
                    and ga.row_id = p.protein_id
                    and ga.is_deprecated != 1
                    and gt.go_term_id = ga.go_term_id
                    and gt.external_database_release_id = $goVersion 
                    and p.rna_id = rnai.rna_id and rnai.na_feature_id = rnaf.na_feature_id
                    and rnaf.na_sequence_id = am.na_sequence_id and am.taxon_id = $taxonId
               $excludeAlgIdsSql
               $testIdSql";


    print STDERR "DatabaseAdapter: executing \n $sql \n to get proteins to process\n";

    my $sth = $self->getDbHandle()->prepareAndExecute($sql);
    return $sth;
}

#param cla: hash of bulky command line arguments for running queries
#includes queryTableId, queryTablePkAtt, subjectDbList,
#queryDbList, queryTaxonId, proteinTableId
sub runProteinSimQuery{
   
    my ($self, $cla, $filePath, $createNewFile, $excludeInvocationIdList) = @_;
    if ($filePath){
	if (!$createNewFile){
	    my $testSth = $self->_getSimSthFromFile($filePath);
	    return $testSth;
	}
    }
    my $motifTableId = $self->getGusTableId("DoTS", "MotifAASequence");
    my $excludeInvocationIdString;
    my $testSqlString;
    my $queryDbString;
    $queryDbString = "and q.external_database_release_id in (" . $cla->{queryDbList} . ")" 
	if $cla->{queryDbList};
    $excludeInvocationIdString = $self->_makeExcludeInvocationIdString($excludeInvocationIdList, $cla->{queryTablePkAtt},
								       $cla->{queryTable}) if $excludeInvocationIdList;
    $testSqlString = $self->_getTestProteinSimSql();
    
    my $sql = "select  sim.query_id, sim.subject_id, sim.similarity_id 
	       from DoTS.Similarity sim,
	            DoTS.MotifAASequence s, 
                 " .  $cla->{queryTable} . " q
               where sim.subject_table_id           = $motifTableId
		     and sim.query_table_id         = " . $cla->{queryTableId} .
			 " and sim.number_of_matches      < 5
	             and sim.query_id               = q." . $cla->{queryTablePkAtt} .
			 " and sim.subject_id             = s.aa_sequence_id
		     and s.external_database_release_id in (" . $cla->{subjectDbList} . ") 
                     and q.taxon_id = " . $cla->{queryTaxonId} . "
                     $testSqlString  $queryDbString $excludeInvocationIdString  order by sim.query_id";
    
    print STDERR "DatabaseAdapter:  executing \n $sql \n to get proteins for apply rules\n";
    my $sth = $self->getDbHandle()->prepareAndExecute($sql);
    if ($createNewFile){
	open (SIMQUERY, ">>" . $filePath);
	while (my ($queryId, $subjectId, $simId) = $sth->fetchrow_array()){
	    print SIMQUERY $queryId . " " . $subjectId . " " . $simId . "\n";
	}
	$sth = $self->_getSimSthFromFile($filePath);
    }
    return $sth;
}


#Retrieves all IDs for all non-deprecated GO Associations 
#of a given Protein that are not deprecated.
sub getGusAssocIdResultSet{

    my ($self, $proteinId, $proteinTableId) = @_;

    my $sql = "select distinct ga.go_association_id
               from dots.goassociation ga
               where  ga.table_id = $proteinTableId
                     and ga.row_id = $proteinId
                     and ga.is_deprecated != 1";

    my $sth = $self->getDbHandle()->prepareAndExecute($sql);
    return $sth;
    
}

sub getGoResultSet{
    
    my ($self, $goVersion) = @_;
    
    my $sql = "
     select term.go_id, term.go_term_id, hier.child_term_id
     from SRes.GOTerm term, SRes.GORelationship hier
     where term.external_database_release_id = $goVersion
     and term.name != 'Gene_Ontology'
     and term.go_term_id = hier.parent_term_id (+) 
";
    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    return $sth;
}

sub getProteinsToDeprecate{

    my ($self, $raidList, $proteinTableId, $taxonId) = @_;

    my $sql = "select distinct p.protein_id
               from dots.protein p, dots.goassociation ga,
                    dots.rnainstance rnai, dots.rnafeature rnaf, 
                    dots.assembly am 
               where ga.is_deprecated != 1 and ga.table_id = $proteinTableId
                    and ga.row_id = p.protein_id and p.rna_id = rnai.rna_id 
                    and rnai.na_feature_id = rnaf.na_feature_id
                    and rnaf.na_sequence_id = am.na_sequence_id and am.taxon_id = $taxonId
                    and p.protein_id not in 
               (select distinct p.protein_id
               from dots.protein p, dots.goassociation ga
               where ga.row_id = p.protein_id
                    and ga.row_alg_invocation_id in ($raidList))";
    
    print STDERR "DatabaseAdapter.getProteinsToDeprecate: returning \n $sql\n";

    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    
    return $sth;
}

sub getGoRuleResultSet{

    my ($self, $goDbRelId) = @_;
    my $sql = "select rs.aa_sequence_id_1,
                      r.aa_motif_go_term_rule_id,		
		      r.go_term_id,	              
                      rs.p_value_threshold_mant,
         	      rs.p_value_threshold_exp
	       from   DoTS.AAMotifGOTermRuleSet rs,
		      DoTS.AAMotifGOTermRule    r,
		      SRes.GOTerm               f
	       where  r.aa_motif_go_term_rule_set_id      = rs.aa_motif_go_term_rule_set_id
		      and r.go_term_id                    = f.go_term_id
		      and f.external_database_release_id  = $goDbRelId
                      and r.defining = 1
                      and f.name != 'Gene_Ontology'";
                      

    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    return $sth;

}


#################################### Mapping Initializers ##############################

#These methods execute a query and do all the processing immediately, returning a result
#(usually a map) to the calling class or setting it here.

#given a protein, create an AssociationGraph representing all GO Terms associated with the protein
#param goGraph:         goGraph required to create the AssociationGraph (see AssociationGraph.pm)
#param proteinId:       id of protein for which we are creating the AssociationGraph
#param proteinTableId:  ID in GUS of the DoTS.Protein table (could be extended to handle Associations to 
#                       other things than proteins.
#param goVersion:       external database release id of the GO Function terms which will be retrieved
#param extent:          extent that will give GUS GoAssociation objects when asked (see GoExtent.pm)

sub getAssociationGraph{

    my ($self, $goGraph, $proteinId, $proteinTableId, $goVersion, $extent) = @_;
    
    my $gusAssocIdResultSet = $self->getGusAssocIdResultSet($proteinId, $proteinTableId, $goVersion);

    my $gusAssocObjectList;

    while (my ($assocId) = $gusAssocIdResultSet->fetchrow_array()){
	my $gusAssocObject = $extent->getGusAssociationFromId($assocId);

	push (@$gusAssocObjectList, $gusAssocObject);
    }
    
    my $associationGraph;
    if ($gusAssocObjectList){   # why would there not be an assoc list?
	if (scalar @$gusAssocObjectList > 0){
	    $associationGraph = GUS::GOPredict::AssociationGraph->newFromGusObjects($gusAssocObjectList, $goGraph);
	}
    }

    $gusAssocIdResultSet->finish();
    return $associationGraph;
}


#method that adds evidence objects to an Association Graph to be displayed in the toString() method of the graph.
#currently will cause GoAssociationInstance objects to resubmit their evidence, so should not be called in commit()
#mode until this issue is addressed.
sub addEvidenceToGraph{

    my ($self, $associationGraph) = @_;
    my $allAssoc = $associationGraph->getAsList();
    foreach my $association (@$allAssoc){
	my $instances = $association->getInstances();
	foreach my $instance(@$instances){
	    my $gusId = $instance->getGusInstanceObject()->getGoAssociationInstanceId();
	    my $sql = "select ruleset.aa_sequence_id_1
                       from dots.aamotifgotermruleset ruleset, 
                            dots.aamotifgotermrule rule, dots.evidence e 
                            where e.fact_table_id = 330 and e.target_table_id = 3177 and e.target_id = $gusId
                                  and e.fact_id = rule.aa_motif_go_term_rule_id
                                  and rule.aa_motif_go_term_rule_set_id = ruleset.aa_motif_go_term_rule_set_id";
                                  
 	    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
	     while (my ($motifId) = $sth->fetchrow_array()){
		 my $motifObject = GUS::Model::DoTS::MotifAASequence->new();
		 $motifObject->setAaSequenceId($motifId);
		 $motifObject->retrieveFromDB();
		 my $evidence = GUS::GOPredict::Evidence->new($motifObject);
		 $instance->addEvidence($evidence);
	     }
	} 
    } 
} 


#called by plugin.  Will have to be altered if not doing dots
sub initializeTranslations{

    my ($self, $taxonId, $filePath, $createNewFile) = @_;

    if ($filePath && !$createNewFile){
	print STDERR "reading translations in from pre-existing file $filePath\n";
	$self->_setTranslationsFromFile($filePath);
	return;
    }
    
    my $sql = "select am.na_sequence_id, p.protein_id
               from dots.protein p, dots.rnainstance rnai, 
               dots.rnafeature rnaf, dots.assembly am
               where p.rna_id = rnai.rna_id
               and rnai.na_feature_id = rnaf.na_feature_id
               and rnaf.na_sequence_id = am.na_sequence_id";
    
    $sql .= " and p.protein_id in (" . $self->getTestProteinIds() . ")" if $self->getTestProteinIds();
    $sql .= " and am.taxon_id = $taxonId" if $taxonId;
    
    print STDERR "DatabaseAdapter: executing\n $sql \n to get translations from assemblies to proteins\n";

    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    
    if ($createNewFile){

	open (TRANSLATIONS, ">>" . $filePath);
	while (my ($assemblyId, $proteinId) = $sth->fetchrow_array()){
	 	 
	    print TRANSLATIONS $assemblyId . " " . $proteinId . "\n";
	}
	$self->_setTranslationsFromFile($filePath);
    }
    else{
	while (my ($assemblyId, $proteinId) = $sth->fetchrow_array()){
	    $self->{dotsToProtein}->{$assemblyId} = $proteinId;
	    $self->{proteinToDots}->{$proteinId} = $assemblyId;
	}
    }
}

sub getTranslatedProteinId{

    my ($self, $queryId) = @_;
    my $proteinId = $self->{dotsToProtein}->{$queryId};
    &confess("no translated protein for assembly $queryId") if !$proteinId;
    return $proteinId;
}

#makes a hash where the keys are Synonyms to GO Terms in the current release,
#and the values are the GO Terms to which they are synonyms.
sub makeGoSynMap{

    my ($self, $goVersion) = @_;
   
    my $goSynMap;
    my $sql = "select gt.go_id, gs.source_id
               from sres.goterm gt, sres.gosynonym gs
               where gt.go_term_id = gs.go_term_id
               and gs.source_id like 'GO%'
               and gt.external_database_release_id = $goVersion";

    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);

    while (my ($realGoId, $synonymId) = $sth->fetchrow_array()){
	$goSynMap->{$synonymId} = $realGoId;
	
    }
    return $goSynMap;
}

#returns a map of the form
#proteinId->{GoId}->{AssocId}
#                 ->{goVersion}
#Each entry of AssocId is a deprecated Association between the protein and Go Term
#If there are multiple Associations between a protein and a GO ID because of multiple
#releases of the GO ID, then the Association to the latest version is returned and stored
#in {goVersion}
sub getDeprecatedAssociations{
    my ($self, $taxonId, $proteinTableId, $filePath, $createNewFile) = @_;
    my $deprecatedAssociations;
    my $from = "";
    my $where = "";
    
    if ($filePath && !$createNewFile){
	print STDERR "reading deprecated associatoins in from pre existing file $filePath\n";
	$deprecatedAssociations = $self->_getDeprecatedFromFile($filePath);
	return $deprecatedAssociations;
    }

    if ($taxonId){
	$from = ", dots.rnainstance rnai, dots.rnafeature rnaf, dots.assembly am ";
	$where = " and p.rna_id = rnai.rna_id and rnai.na_feature_id = rnaf.na_feature_id
                  and rnaf.na_sequence_id = am.na_sequence_id and am.taxon_id = $taxonId";
    }
    
    my $sql = "select ga.row_id, gt.go_id, gt.external_database_release_id, ga.go_association_id 
               from dots.goassociation ga, dots.protein p, sres.goterm gt " .  $from . " where 
               p.protein_id = ga.row_id and ga.table_id = $proteinTableId
               and gt.go_term_id = ga.go_term_id
               and ga.is_deprecated = 1 "
               . $where; 
    
    print STDERR "DatabaseAdapter: executing\n $sql \n to get deprecated associations\n";
    
    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    if ($createNewFile){
	open (DEPRECATED, ">>" . $filePath);
	
	while (my ($proteinId, $goId, $goVersion, $goAssociationId) = $sth->fetchrow_array()){

	    print DEPRECATED "$proteinId $goId $goVersion $goAssociationId\n";
	}
	$deprecatedAssociations = $self->_getDeprecatedFromFile($filePath);
    }
    
    else{
	while (my ($proteinId, $goId, $goVersion, $goAssociationId) = $sth->fetchrow_array()){
	    my $existingGoVersion = $deprecatedAssociations->{$proteinId}->{$goId}->{goVersion};
	    
	    if (!$existingGoVersion || $goVersion > $existingGoVersion){
		
		$deprecatedAssociations->{$proteinId}->{$goId}->{assocId} = $goAssociationId;
		$deprecatedAssociations->{$proteinId}->{$goId}->{goVersion} = $goVersion;
	    }
	}
    }
    return $deprecatedAssociations;
}

#################################### Utility Methods ##############################

#These methods complement methods above to add extra SQL or provide other functionality.
sub _setTranslationsFromFile{

    my ($self, $filePath) = @_;
    open (TRANSLATIONS, "<" . $filePath);
    while (<TRANSLATIONS>){
	my $line = $_;
	if ($line =~ /(\d+)\s(\d+)/){
	    my $assemblyId = $1;
	    my $proteinId = $2;

	    $self->{dotsToProtein}->{$assemblyId} = $proteinId;
	    $self->{proteinToDots}->{$proteinId} = $assemblyId;
	}
    }
}

sub _getDeprecatedFromFile{

    my ($self, $filePath) = @_;
    my $deprecatedAssociations;
    open (DEPRECATED, "<" . $filePath);

    while (<DEPRECATED>){
	my $line = $_;
	    if ($line =~ /(\S+)\s(\S+)\s(\S+)\s(\S+)/){
		my $proteinId = $1;
		my $goId = $2;
		my $goVersion = $3;
		my $goAssociationId = $4;
		my $existingGoVersion = $deprecatedAssociations->{$proteinId}->{$goId}->{goVersion};
		
		if (!$existingGoVersion || $goVersion > $existingGoVersion){
		    
		    $deprecatedAssociations->{$proteinId}->{$goId}->{assocId} = $goAssociationId;
		    $deprecatedAssociations->{$proteinId}->{$goId}->{goVersion} = $goVersion;
		}
	    }
    }
    return $deprecatedAssociations;
}
	

sub _getSimSthFromFile{

    my ($self, $filePath) = @_;

    my $testSth = GUS::GOPredict::TestSth->new();
    open (SIMS, "<" . $filePath);
    while (<SIMS>){
	my $line = $_;
	if ($line =~ /(\d+)\s(\d+)\s(\d+)/){
	    my @simArray = ($1, $2, $3);
	    $testSth->addRow(\@simArray);
	}
    }
    return $testSth;
}


#only works for dots.assembly right now
sub _makeExcludeInvocationIdString{
    my ($self, $excludeInvocationIdList, $queryTablePkAtt, $queryTable) = @_;
    my $sql = " and q.na_sequence_id not in (
                select am.na_sequence_id
                from dots.assembly am, dots.rnainstance rnai,
                dots.rnafeature rnaf, dots.protein p,
                dots.goassociation ga
                where ga.row_id = p.protein_id
                and ga.row_alg_invocation_id in (" . join(",", @{$excludeInvocationIdList}) . ")
                and p.rna_id = rnai.rna_id and rnai.na_feature_id = rnaf.na_feature_id
                and rnaf.na_sequence_id = am.na_sequence_id) ";

    return $sql;
}

sub _getTestProteinSimSql{
    my ($self) = @_;
    my $idSql;
    if ($self->getTestProteinIds()){
	my @testQueryIds;
	my @testProteinIds = split /,/, $self->getTestProteinIds();
	while (my $proteinId = shift @testProteinIds){
	    push (@testQueryIds, $self->{proteinToDots}->{$proteinId});
	}
	$idSql = "and sim.query_id in (" . join(',', @testQueryIds) . ")";
    }
    return $idSql;
}


#########################################  Object Layer Functionality ##################################

#These methods provide various forms of interaction with GUS Objects

sub undefPointerCache{

    my ($self) = @_;
    $self->getDb()->undefPointerCache();

}

sub submitGusObject{

    my ($self, $gusObject) = @_;


    my $children = $gusObject->{'children'};
    foreach my $classname (keys %$children){

	my $ch = $gusObject->{'children'}->{$classname};
    }
    $gusObject->submit();
}

sub getRuleObjectFromId{

    my ($self, $ruleId) = @_;

    my $ruleObject = GUS::Model::DoTS::AAMotifGOTermRule->new();
    $ruleObject->setAaMotifGoTermRuleId($ruleId);
    $ruleObject->retrieveFromDB();
    $ruleObject->retrieveAllChildrenFromDB(0);
    return $ruleObject;
}

sub getGusAssociationFromId{

    my ($self, $assocId) = @_;

    my $gusAssocObject = GUS::Model::DoTS::GOAssociation->new();
    $gusAssocObject->setGoAssociationId($assocId);
    $gusAssocObject->retrieveFromDB();
    $gusAssocObject->retrieveAllChildrenFromDB(0);

 

    return $gusAssocObject;
}

sub getSimObjectFromId{

    my ($self, $simId) = @_;

    my $gusSimObject = GUS::Model::DoTS::Similarity->new();
    $gusSimObject->setSimilarityId($simId);
    $gusSimObject->retrieveFromDB();

    return $gusSimObject;
}

######################################### Miscellaneous #######################################

sub getGusTableId {
    my ($self, $owner, $table) = @_;
    my $queryHandle = $self->getQueryHandle();
    my $sql = "select table_id 
               from core.tableinfo c, core.databaseinfo d
               where d.name = '$owner' and c.name = '$table' 
               and c.database_id = d.database_id
              ";
    
    my $sth = $queryHandle->prepareAndExecute($sql);
    my ($tableId) = $sth->fetchrow_array();
    return $tableId;
}



######################################## Accessor Methods ########################################

sub setQueryHandle{
    my ($self, $queryHandle) = @_;
    $self->{QueryHandle} = $queryHandle;
}

sub getQueryHandle{
    my ($self) = @_;
    return $self->{QueryHandle};
}

sub setDbHandle{
    my ($self, $dbHandle) = @_;
    $self->{DbHandle} = $dbHandle;
}

sub getDbHandle{
    my ($self) = @_;
    return $self->{DbHandle};
}

sub setDb{
    my ($self, $db) = @_;
    $self->{Db} = $db;
}

sub getDb{
    my ($self) = @_;
    return $self->{Db};
}

#testing

sub setTestAssemblyIds{
    my ($self, $testAssemblyIds) = @_;
    $self->{TestAssemblyIds} = $testAssemblyIds;
}

sub getTestAssemblyIds{
    my ($self) = @_;
    return $self->{TestAssemblyIds};
}


sub setTestProteinIds{
    my ($self, $testProteinIds) = @_;

    $self->{TestProteinIds} = $testProteinIds;
}

sub getTestProteinIds{
    my ($self) = @_;
    return $self->{TestProteinIds};
}


sub loadProteinsToSkip{

    my ($self) = @_;
    my $skipped;
    open (SKIP, "</home/dbarkan/projects/GUS/GOPredict/plugin/perl/skip.txt");
    while (<SKIP>){
	chomp;
	my $line = $_;
#	print STDERR "DB adapter: adding $line to skipped\n";
	$skipped->{$line} = 1;
    }
    return $skipped;
}

     
1;

package GUS::GOPredict::DatabaseAdapter;

use GUS::GOPredict::Association;
use GUS::Model::DoTS::AAMotifGOTermRule;
use GUS::Model::DoTS::Similarity;

use strict;
use Carp;

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

#called by plugin.  Will have to be altered if not doing dots
sub initializeTranslations{

    my ($self, $taxonId, $filePath, $createNewFile) = @_;

    if ($filePath){
	if (!$createNewFile){
	    $self->_setTranslationsFromFile($filePath);
	    return;
	}

    }
    my $idSql;
    $idSql = "and p.protein_id in (" . $self->getTestProteinIds() . ")" if $self->getTestProteinIds();
    
    my $sql = "select am.na_sequence_id, p.protein_id
               from dots.protein p, dots.rnainstance rnai, 
               dots.rnafeature rnaf, dots.assembly am
               where p.rna_id = rnai.rna_id
               and rnai.na_feature_id = rnaf.na_feature_id
               and rnaf.na_sequence_id = am.na_sequence_id
               $idSql";
    
    
    $sql .= " and am.taxon_id = $taxonId" if $taxonId;
    
    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    
    if ($createNewFile){

	while (my ($assemblyId, $proteinId) = $sth->fetchrow_array()){
	    
	    open (TRANSLATIONS, ">>" . $filePath);
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

sub getGusProteinIdResultSet{

    my ($self, $proteinTableId, $goVersion) = @_;
    
    my $idSql;
    my $testProteinIds = $self->getTestProteinIds();
    $idSql = "and ga.row_id in (" . $testProteinIds . ")" if $testProteinIds;

    my $sql = "select distinct(p.protein_id) 
               from   DoTS.Protein p, DoTS.GOAssociation ga, SRes.GoTerm gt
               where ga.table_id =  $proteinTableId
               and ga.row_id = p.protein_id
               and ga.is_deprecated != 1
               and gt.go_term_id = ga.go_term_id
               and gt.external_database_release_id = $goVersion
               $idSql 
";    

#gets associations for deleted proteins
#    my $sql = "select distinct(row_id) 
#               from  DoTS.GOAssociation ga, SRes.GoTerm
#               where ga.table_id =  $proteinTableId
#               and ga.is_deprecated != 1
#               and gt.go_term_id = ga.go_term_id
#               and gt.external_database_release_id = $goVersion
#               $idSql 
#";    
  
    my $sth = $self->getDbHandle()->prepareAndExecute($sql);
    return $sth;
}

sub submitGusObject{

    my ($self, $gusObject) = @_;
    $gusObject->submit();
}

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


#param cla: hash of bulky command line arguments for running queries
#includes queryTableId, queryTablePkAtt, subjectDbList,
#queryDbList, queryTaxonId, proteinTableId
sub runProteinSimQuery{
   
    my ($self, $cla, $filePath, $createNewFile) = @_;
    if ($filePath){
	if (!$createNewFile){
	    my $testSth = $self->_getSimSthFromFile($filePath);
	    
	    return $testSth;
	}
    }
    my $motifTableId = $self->getGusTableId("DoTS", "MotifAASequence");
    
    my $testSqlString;
    my $queryDbString;
    my $queryTaxonString;
    $queryDbString = "and q.external_database_release_id in (" . $cla->{queryDbList} . ")" 
	if $cla->{queryDbList};
    $queryTaxonString = "and q.taxon_id = " . $cla->{queryTaxonId} if $cla->{queryTaxonId};
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
                     $testSqlString
                     $queryDbString
                     $queryTaxonString
                order by sim.query_id";
    
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


sub getGusAssocIdResultSet{

    my ($self, $proteinId, $proteinTableId, $goVersion) = @_;
    #will need to include go version if go assoc's for previous
    #go versions have not been deprecated
    my $sql = "select distinct ga.go_association_id
               from dots.goassociation ga
               where  ga.table_id = $proteinTableId
                     and ga.row_id = $proteinId
                     and ga.is_deprecated != 1";
    #include go version if necessary
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
    my $stmt = $self->getQueryHandle()->prepareAndExecute($sql);
        
}

sub makeGoSynMap{

    my ($self, $goVersion, $oldGoRootId, $newGoRootId) = @_;

   
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
    $goSynMap->{$oldGoRootId} = $newGoRootId; #not sure if we need to have this after 
                                                 #root id = 'GO:-00001' problem has been fixed
    
    print STDERR "adapter: makegorealIdmap: entry for $newGoRootId is " . $goSynMap->{$newGoRootId} . "\n";
    return $goSynMap;
}
    
sub getProteinsToDeprecate{

    my ($self, $raidList, $proteinTableId) = @_;
    
    my $sql = "select distinct p.protein_id
               from dots.protein p, dots.goassociation ga
               where ga.is_deprecated != 1 and ga.table_id = $proteinTableId
               and ga.row_id = p.protein_id
               and p.protein_id not in 
               (select distinct p.protein_id
               from dots.protein p, dots.goassociation ga
               where ga.row_id = p.protein_id
               and ga.row_alg_invocation_id in ($raidList))";
    
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

sub getTranslatedProteinId{

    my ($self, $queryId) = @_;
    my $proteinId = $self->{dotsToProtein}->{$queryId};
    &confess("no translated protein for assembly $queryId") if !$proteinId;
    #decide if we want to keep this or just skip if can't find translation
    return $proteinId;
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

    my @children = $gusAssocObject->getChildren("DoTS::GOAssociationInstance");

    return $gusAssocObject;
}

sub getSimObjectFromId{

    my ($self, $simId) = @_;

    my $gusSimObject = GUS::Model::DoTS::Similarity->new();
    $gusSimObject->setSimilarityId($simId);
    $gusSimObject->retrieveFromDB();

    return $gusSimObject;
}

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

sub deleteCachedInstances{
    
    my ($self, $proteinTableId, $goVersion) = @_;
#    my $sql = "delete 
#               from DoTS.GOAssociationInstance gai
#               where gai.go_association_instance_id in 
#               (select gait.go_association_instance_id
#                from DoTS.GOAssociationInstance gait,
#               DoTS.GOAssociation ga
#               where gait.go_association_id = ga.go_association_id
#               and ga.table_id = $proteinTableId
#               and gait.is_primary = 0)
#               ";
    
    my $sql = "delete 
               from DoTS.GOAssociationInstance gai
               where gai.go_association_instance_id in 
               (select gait.go_association_instance_id
               from DoTS.GOAssociationInstance gait, SRes.GoTerm gt,
               DoTS.GOAssociation ga
               where gait.go_association_id = ga.go_association_id
               and ga.go_term_id = gt.go_term_id
               and gt.external_database_release_id = $goVersion
               and ga.is_deprecated != 1
               and ga.table_id = $proteinTableId
               and gait.is_primary = 0)
               ";
    

    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    
}

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

sub undefPointerCache{

    my ($self) = @_;
    $self->getDb()->undefPointerCache();

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

     
1;

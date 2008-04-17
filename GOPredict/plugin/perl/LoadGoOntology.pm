package GUS::GOPredict::Plugin::LoadGoOntology;
@ISA = qw(GUS::PluginMgr::Plugin);
use GUS::PluginMgr::Plugin;
use CBIL::Bio::GeneOntologyParser::Parser;

use lib "$ENV{GUS_HOME}/lib/perl";
use strict 'vars';

use FileHandle;

use GUS::Model::SRes::GOTerm;
use GUS::Model::SRes::GORelationship;
use GUS::Model::SRes::GORelationshipType;
use GUS::Model::SRes::GOSynonym;
use GUS::Model::SRes::ExternalDatabaseRelease;

# ---------------------------------------------------------------------- #
# --------------------------------------------------------------------- #

sub new {
    
    # create
    my $class = shift;
    my $self = {};
    bless($self,$class);
    # initialize

    my $purposeBrief = "Loads GO Terms into GUS and creates relationships among them"; 
    
    my $purpose = "This plugin uses CBIL's Gene Ontology parser to parse one or more files provided by the Gene Ontology Consortium and load them into the database.  It preserves all ontology relationships and loads parent-child pairs, as well as the synonyms provided for each GO Term.\n\n";

    my $tablesAffected =
	[['SRes.GOTerm', 'Writes information about each GO Term here'],
	 ['SRes.GORelationship', 'Writes GO Term parent-child pairs here'], 
	 ['SRes.GOSynonym', 'Writes synonyms listed for each GO Term here'], 
	 ['SRes.ExternalDatabaseRelease', 'The user can optionally specify to create a new entry in this table when loading a branch of the ontology']];

    my $tablesDependedOn =
	[['SRes.GORelationshipType', 'Must have entries for names \'isa\' and \'partof\', the two different types of parent-child relationships'],
	 ['SRes.ExternalDatabase', 'If the user wishes to create a new entry in ExternalDatabaseRelease, this table must be populated with entries for each branch of the ontology the user loads'],
	 ['SRes.ExternalDatabaseRelease', 'If the user is not creating a new entry in ExternalDatabaseRelease, they must provide the existing entry for each branch they are trying to load']];
    
    my $howToRestart = "set the --loadAgain flag and provide the External Database Release Id of the interrupted branch of the ontology.  If you chose to allow the plugin to create a new release in the previous iteration, the id was written to the log file";
    
    my $notes = "Assumes that the \"Obsolete\" GO Term Ids (that is, the parent, in each branch, of all GO Terms that have become obsolete) have IDs that don't vary between releases of the ontology.  If this is not the case, the IDs must be updated below.";

    my $failureCases = "None that we've found so far.";
    
    my $documentation = { purpose=>$purpose,
			  purposeBrief=>$purposeBrief,
			  tablesAffected=>$tablesAffected,
			  tablesDependedOn=>$tablesDependedOn,
			  howToRestart=>$howToRestart,
			  failureCases=>$failureCases,
			  notes=>$notes
			  };

    my $argsDeclaration =
	[
	 stringArg({name=> 'file_path',
		    descr=> 'fully qualified path where .ontology files to read are located',
		    reqd => 1,
		    constraintFunc => undef,
		    isList =>0,
		}),
	 #dtb: technically mustExist should be true here, but that expects the full file path 
	 #in addition to the file name.  The full file path is provided above in case
	 #the user wants to load more than one .ontology file at a time, so it would be 
	 #redundant to provide it here again.  
	 fileArg({name => 'flat_file',
		  descr => 'read data from this flat file.  If blank, read data from all .ontology files in filepath',
		  reqd => 0,
		  constraintFunc => undef,
		  isList => 0,
		  mustExist => 0,
		  format => 'One of the .ontology files available at ftp://ftp.geneontology.org/pub/go/ontology/.  The file name must remain in the <branch>.ontology format.',
	      }),
	 
         booleanArg({ name => 'create_release',
		      descr => 'Set this to automatically create an external database release id for this version of the GO branch you are loading',
		      reqd => 0,
		  }),	
	 
	 integerArg({name => 'function_db_id',
		     descr => 'External database Id in GUS of the molecular function GO branch.  Required if loading GO Functions and creating a new external database release id with --create_release.',
		     reqd => 0,
		     constraintFunc => undef,
		     isList => 0,
		 }),
	 
	 integerArg({name => 'process_db_id',
		     descr => 'External database Id in GUS of the biological process GO branch.  Required if loading GO Processes and creating a new external database release id with --create_release.',
		     reqd => 0,
		     constraintFunc => undef,
		     isList => 0,
		 }),
	 
	 integerArg({name => 'component_db_id',
		     descr => 'External database Id in GUS of the cellular component function GO branch.  Required if loading GO Components and creating a new external database release id with --create_release.',
		     reqd => 0,
		     constraintFunc => undef,
		     isList => 0,
		 }),
	 integerArg({name => 'function_ext_db_rel',
		     descr => 'Existing external database release id in GUS of the molecular function GO branch, if not creating a new one',
		     reqd => 0,
		     constraintFunc => undef,
		     isList =>0,
		 }),	
	 
	 integerArg({name => 'component_ext_db_rel',
		     descr => 'Existing external database release id in GUS of the cellular component GO branch, if not creating a new one',
		     reqd => 0,
		     constraintFunc => undef,
		     isList =>0,
		 }),	
	 
	 integerArg({name => 'process_ext_db_rel',
		     descr => 'Existing external database release id in GUS of the biological process GO branch, if not creating a new one',
		     reqd => 0,
		     constraintFunc => undef,
		     isList =>0,
		 }),	
	 
	 booleanArg({name=> 'loadAgain',
		     descr => 'set this to reload a version of the GO Ontology that has been previously loaded.  The external database release id of the branch you are reloading must also be provided',
		     reqd => 0,
		 }),
	 

	 ];

    $self->initialize({requiredDbVersion => 3.5,
		       cvsRevision => '$Revision$', # cvs fills this in!
 	 	       name => ref($self),
		       argsDeclaration => $argsDeclaration,
		       documentation => $documentation
		   });
	  
    
    # return object.
    $self->{levelGraph} = {};
    $self->{branchInfo} = {
	function => {db_name => "GO Function",
		     obsoleteGoId => "GO:0008369",
		 },
	process => {db_name => "GO Process",
		    obsoleteGoId => "GO:0008371",
		},
	component => {db_name => "GO Component",
                      obsoleteGoId => "GO:0008370",
		  },
    };
    
    return $self;
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub isReadOnly { 0 }

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub run {
    my $self = shift;

    my $path = $self->getArg('file_path');
    my $parser = CBIL::Bio::GeneOntologyParser::Parser->new($path);

    $self->{'rootLoaded'} = 0;

    $self->__loadExtDbIds();
   
    my $fileName = $self->getArg('flat_file');
    if ($fileName){
	$self->log("loading $fileName in preparation for parsing");
	$parser->loadFile($fileName);
    }
    
    else {
	$self->log("loading all .ontology files in $path in preparation for parsing");
	$parser->loadAllFiles();
    }
    $self->log("parsing all .ontology files in preparation for inserting into database");
    $parser->parseAllFiles();

    $self->log("parsing finished; loading ontology into database");

    my $msg = $self->__load_ontology($parser);
    
    # return value
  
    return $msg
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub __load_ontology {
    my ($self, $parser) = @_;

    my $logFile;

    my $skipCount = 0;
    my $entryCount = 0;
    my $relationshipEntryCount = 0;
    my $synonymEntryCount = 0;
        
    my $stores = $parser->getFileCaches();

    #for each branch of the ontology
    foreach my $file (keys %$stores){
	
	my $store = $stores->{$file};
	my $newEntries;
	my ($branch) = $file =~ /^(\w+).ontology$/;

	my $extDbRelId = $self->__getExtDbRelId($branch, $store);
	my $obsoleteGoId = $self->{branchInfo}->{$branch}->{obsoleteGoId};

	my ($gus2go, $go2gus, $processedEntries) = $self->__loadProcessedEntries($extDbRelId) if $self->getArg('loadAgain');

	my $entries = $store->getEntries();
	
	#make graph to help determine depth of entries in GO Tree. 
	my $goGraph = $self->__make_go_graph($entries);
	
	my $levelGraph = $self->__make_level_graph($store->getRoot(), $goGraph);
	
	$self->log("making root node for $branch");
	($gus2go, $go2gus, $newEntries) = $self->__makeRoots ($entries, $store, 
								 $extDbRelId, $processedEntries,
								 $logFile);
	
	$entryCount += $newEntries;
	
	my $ancestorGusId = $go2gus->{$store->getBranchRoot()};
	
	$self->log("loading GO Terms into SRes.GOTerm");

	#make entry in SRes.GOTerm for each entry in the go file
	foreach my $entryId(keys %$entries){
	    
	    next if (($entryId eq $store->getBranchRoot())||($entryId eq $store->getRoot()));
	    
	    if ($processedEntries->{Term}->{$entryId}){
		$skipCount++;  next;
	    }
	    
	    $entryCount++;
	    my $entry = $entries->{$entryId};
	    my $gusGoTerm = $self->__makeNewGoTerm($entry, $goGraph, $levelGraph, 
						   $obsoleteGoId, $extDbRelId, $ancestorGusId);

	    #write to successfully processed id list
	    $processedEntries->{Term}->{$entryId} = 1;

            # update translation tables between GO and GUS ids.
	    $gus2go->{ $gusGoTerm->getId() } = $entry->getId();
	    $go2gus->{ $entryId } = $gusGoTerm->getId();
	    $self->undefPointerCache();
	}
	
	my ($isaId, $partOfId) = $self->__getRelationshipTypeIds();
	
	$self->log("loading hierarchy and synonyms into SRes.GORelationship and SRes.GOSynonym");

	#make hierarchy representation in SRes.GORelationship
	foreach my $entryGoId(keys %$entries){
	    
	    my $entry = $entries->{$entryGoId};
	    my ($relSkipCount, $newRelCount) = 
		$self->__makeGoRelationshipsForChild($entry, $processedEntries, $go2gus, $isaId, $partOfId);

	    $skipCount += $relSkipCount;
	    $relationshipEntryCount += $newRelCount;

	    #make entry in GOSynonym if necessary
	    my ($synSkipCount, $newSynCount) = $self->__makeGoSynonymsForGoTerm($entry, $processedEntries, $go2gus, $extDbRelId);

	    $skipCount += $synSkipCount;
	    $synonymEntryCount += $newSynCount;
	}      
    }
    
    return "Created $entryCount entries in GOTerm, $relationshipEntryCount entries in GORelationship, and $synonymEntryCount entries in GOSynonym.  Skipped $skipCount total entries";
}
    
# ---------------------------------------------------------------------- #

sub __makeNewGoTerm{
    my ($self, $entry, $goGraph, $levelGraph, 
	$obsoleteGoId, $extDbRelId, $ancestorGusId) = @_;

    my $entryId = $entry->getId();

    my $l = $levelGraph->{$entryId};
    my @levelList = sort { $a <=> $b} @$l;
    my $obsolete = 0;
    my $numberOfLevels = $self->__distinctLevels(\@levelList);
    if ($goGraph->{childToParent}->{$entryId}->{"$obsoleteGoId"})
    {$obsolete = 1};
    
    my $gusGoTerm = GUS::Model::SRes::GOTerm->new({
	go_id  => $entry->getId(), 
	external_database_release_id   => $extDbRelId,
	source_id => $entry->getId(), 
	name  => $entry->getName(), 
	definition   => $entry->getName(),
	minimum_level => $levelList[0],
	maximum_level => $levelList[scalar(@levelList)-1],
	number_of_levels => $numberOfLevels,
	ancestor_go_term_id => $ancestorGusId,
	is_obsolete => $obsolete,
    } );
    
    #submit new term
    $gusGoTerm->submit();

    $self->logVeryVerbose("submitted new GO Term " . $gusGoTerm->toXML() . "\n");
    
    return $gusGoTerm;
}

sub __makeGoRelationshipsForChild{

    my ($self, $entry, $processedEntries, $go2Gus, $isaId, $partOfId) = @_;
    
    my ($skipCount, $relationshipEntryCount);

    my $classes = $entry->getClasses();
    my $containers = $entry->getContainers();
    my $entryGoId = $entry->getId();

    if ($classes){
	foreach my $parentGoId (@$classes){
	    
	    my $goRelationship = 
		$self->__makeNewGoRelationship($entryGoId, $parentGoId, $processedEntries, $go2Gus, $isaId);
	    if ($goRelationship == 0){
		$skipCount++;
	    }
	    else{
		$relationshipEntryCount++;
	    }
	    $self->undefPointerCache();
	}
    }
    if ($containers){
	foreach my $parentGoId (@$containers){
	    
	    my $goRelationship = 	
		$self->__makeNewGoRelationship($entryGoId, $parentGoId, $processedEntries, $go2Gus, $partOfId);
	    if ($goRelationship == 0){
		$skipCount++;
	    }
	    else{
		$relationshipEntryCount++;
	    }
	    $self->undefPointerCache();
	}
    }

    return ($skipCount, $relationshipEntryCount);

}

sub __makeNewGoRelationship{

    my ($self, $childGoId, $parentGoId, $processedEntries, $go2gus, $typeId) = @_;

    my $goRelationship;

    if (!$processedEntries->{Relationship}->{$childGoId}->{$parentGoId}){
	$goRelationship = GUS::Model::SRes::GORelationship->new({
	    parent_term_id => $go2gus-> {$parentGoId},
	    child_term_id => $go2gus-> {$childGoId},
	    go_relationship_type_id => $typeId,
	});
       
	$goRelationship->submit();

	$self->logVeryVerbose("submitted new GO Relationship " . $goRelationship->toXML() . "\n");
	$processedEntries->{Relationship}->{$childGoId}->{$parentGoId} = 1;
    }

    return $goRelationship;
}

sub __makeGoSynonymsForGoTerm{
    my ($self, $entry, $processedEntries, $go2gus, $extDbRelId) = @_;
    
    my $skipCount, 
    my $synCount;
    my $altIds = $entry->getAlternateIds();
    my $synonyms = $entry->getSynonyms();
    
    my $entryGoId = $entry->getId();

    if ($altIds){
	foreach my $altId (@$altIds){
	    if ($processedEntries->{Synonym}->{$entryGoId}->{$altId}){
		$skipCount++; next;
	    }
	    my $goSynonym = GUS::Model::SRes::GOSynonym->new({
		source_id => $altId,
		go_term_id => $go2gus-> {$entryGoId},
		text => "$altId is an alternate GO Id for " . $entryGoId,
		external_database_release_id => $extDbRelId,
	    });
	    $goSynonym->submit();
	    $self->logVeryVerbose("submitted new GO Synonym " . $goSynonym->toXML() . "\n");
	    $processedEntries->{Synonym}->{$entryGoId}->{$altId} = 1;
	    
	    $self->undefPointerCache();
	    $synCount++;
	}
    }
    if ($synonyms){
	foreach my $synonym (@$synonyms){
	    
	    if ($processedEntries->{Synonym}->{$entryGoId}->{$synonym}){
		$skipCount++; next;
	    }
	    my $goSynonym= GUS::Model::SRes::GOSynonym->new({
		go_term_id => $go2gus-> {$entryGoId},
		text => $synonym,
		external_database_release_id => $extDbRelId,
	    });
	    $goSynonym->submit();
	    $self->logVeryVerbose("submitted new GO Synonym " . $goSynonym->toXML() . "\n");
	    $processedEntries->{Synonym}->{$entryGoId}->{$synonym} = 1;
	    
	    $self->undefPointerCache();
	    $synCount++;
	}
    }
    return ($skipCount, $synCount);
}

sub __getExtDbRelId{
    my ($self, $branch, $store) = @_;

    my $extDbRelId;
    my $version = $store->getVersion();
    my $branchDescription = $store->getDescription();
    my $branchReleaseDate = $store->getReleaseDate();

    if (!($self->getArg('create_release'))) { 
	#db's passed in from cla

        my $relArg = $branch . "_ext_db_rel";
        $extDbRelId = $self->getArg($relArg);
	if (!($extDbRelId)){
	    $self->userError("no external database release passed in for $branch branch.\n Either pass in --" . $branch . "_ext_db_rel or create a new one by setting --create_release to true");
	}
    }
    #dtb should also check to see if release that was passed in already loaded

    else{  #create new db
	my $queryHandle = $self->getQueryHandle();
	
	my $dbId = $self->{branchInfo}->{$branch}->{db_id};

	if (!$dbId){
	    $self->userError("Could not find external database id for ontology branch go $branch.  Please supply it with the command line options for this plugin.");
	}
	my $sql = "select external_database_release_id 
               from sres.externalDatabaseRelease
               where version = \'$version\' and external_database_id = $dbId";

	my $sth = $queryHandle->prepareAndExecute($sql);
	
	while ( ($extDbRelId) = $sth->fetchrow_array()) {} #should only be one entry
	if (($extDbRelId) && !($self->getArg('loadAgain'))){
	    $self->userError("This version of GO (version $version) already exists in SRes.ExternalDatabaseRelease.\n  If you want to load the terms for this version again, please set the --loadAgain flag in the command line\n");
	}
	unless ($extDbRelId) {   #this release doesn't exist and needs to be insertd
	    my $extDbRelEntry = GUS::Model::SRes::ExternalDatabaseRelease->new({
		external_database_id => $dbId,
		version => $version,
		description=> $branchDescription,
	#	release_date=> $branchReleaseDate,
		file_name=> $branch . "ontology",
	    });
	    
	    $extDbRelEntry->submit();
	    $extDbRelId = $extDbRelEntry->getId();
	    $self->log("successfully submitted new entry for branch $branch into SRes.ExternalDatabaseReleaseId with primary key of $extDbRelId\n");
	}
    }
    return $extDbRelId;
}
# ---------------------------------------------------------------------- #
sub __make_level_graph{

    my ($self, $rootId, $goGraph) = @_;

    $self->__add_level_count(0, $rootId, $goGraph);
    
    return $self->{levelGraph};
}

sub __distinctLevels{
    my ($self, $levelList) = @_;
    my %levelsHash;
    foreach my $level (@$levelList){
	%levelsHash->{$level} = 1;
    }
    return scalar(keys %levelsHash);
}

sub __add_level_count{

    my ($self, $currentLevel, $currentNode, $goGraph) = @_;

    push (@{$self->{levelGraph}->{$currentNode}}, $currentLevel);
    
    my $nextLevel = $currentLevel + 1;
    my $children = $goGraph->{parentToChild}->{$currentNode};
    foreach my $childOfCurrentNode (keys %$children){
	$self->__add_level_count($nextLevel, $childOfCurrentNode, $goGraph);
    }
}

sub __makeRoots{
    my ($self, $entries, $store, $extDbRelId, $processedEntries, $logFile) = @_;

    my $gus2go;
    my $go2gus;

    my $rootGoId = $store->getRoot();
    my $rootGusId = $self->{'rootLoaded'};
    my $newEntries = 0;
    my $branchRootGoId = $store->getBranchRoot();
    my $branchRootGusId;
    
    if (($rootGusId == 0) && !($processedEntries->{Term}->{$rootGoId})){

	$rootGusId = $self->__makeOntologyRoot($entries, $rootGoId, $extDbRelId);
	$processedEntries->{Term}->{$rootGoId} = 1;
	$newEntries++;
    }
   
    if (!$processedEntries->{Term}->{$branchRootGoId}){
	
	$branchRootGusId = $self->__makeBranchRoot($entries, $branchRootGoId, $extDbRelId);
	$processedEntries->{Term}->{$branchRootGoId} = 1;
	$newEntries++;
    }

    $go2gus->{$rootGoId} = $rootGusId;
    $go2gus->{$branchRootGoId} = $branchRootGusId;
    $gus2go->{$rootGusId} = $rootGoId;
    $gus2go->{$branchRootGusId} = $branchRootGoId;

    return ($gus2go, $go2gus, $newEntries);

}

sub __makeBranchRoot{
    my ($self, $entries, $branchRootGoId, $extDbRelId) = @_;
    
    my $branchRootEntry = $entries->{$branchRootGoId};

    my $branchGoTerm = GUS::Model::SRes::GOTerm->new({
	go_id  => $branchRootGoId, 
	external_database_release_id => $extDbRelId,
	source_id => $branchRootEntry->getId(), 
	name  => $branchRootEntry->getName(), #just the name
	definition   => $branchRootEntry->getName(),
	minimum_level => 1,
	maximum_level => 1,
	number_of_levels => 1,
    } );
    
    #submit new term
    

    $branchGoTerm->submit();
    $self->logVeryVerbose("submitted branch go term " . $branchGoTerm->toXML() . "\n");
  
    my $gusId = $branchGoTerm->getId();
    
    #set self referential fk
    my $sql = "Update SRes.GOTerm Set ancestor_go_term_id = $gusId
               where external_database_release_id = $extDbRelId
               and go_term_id = $gusId";

    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);
    
    return  $gusId;
}


sub __makeOntologyRoot{
    my ($self, $entries, $rootGoId, $extDbRelId) = @_;
    my $rootEntry = $entries->{$rootGoId};
    
    my $ontologyGoTerm = GUS::Model::SRes::GOTerm->new({
	go_id  => $rootGoId, 
	external_database_release_id => $extDbRelId,
	source_id => $rootEntry->getId(), 
	name  => $rootEntry->getName(), #just the name
	definition   => $rootEntry->getName(),
	minimum_level => 0,
	maximum_level => 0,
	number_of_levels => 1,
    } );
    
    #submit new term
    $ontologyGoTerm->submit();

    $self->logVeryVerbose("submitted Root Ontology go term " . $ontologyGoTerm->toXML() . "\n");

    my $gusId = $ontologyGoTerm->getId();

    $self->{'rootLoaded'} = $gusId;

    return  $gusId;
}

sub __loadProcessedEntries{
    my ($self, $extDbRelId) = @_;

    my $processedEntries;  
    my ($go2gus, $gus2go);

    my $sqlTerm = "select go_id from SRes.GoTerm where external_database_release_id = $extDbRelId";
    my $queryHandle = $self->getQueryHandle();
    my $sthTerm = $queryHandle->prepareAndExecute($sqlTerm);
    
    while (my ($goId) = $sthTerm->fetchrow_array()){
	$processedEntries->{Term}->{$goId} = 1;
    }

    my $sqlRel = "select child.go_id, parent.go_id, child.go_term_id, parent.go_term_id
               from SRes.GOTerm child, SRes GOTerm parent, SRes.GORelationship rel
               where child.go_term_id = rel.child_term_id 
               and parent.go_term_id = rel.parent_term_id
               and child.external_database_release_id = $extDbRelId";
  
    my $sthRel = $queryHandle->prepareAndExecute($sqlRel);

    while (my ($childGoId, $parentGoId, $childGusId, $parentGusId) = $sthRel->fetchrow_array()){
	$processedEntries->{Relationship}->{$childGoId}->{$parentGoId} = 1;
	$go2gus->{$childGoId} = $childGusId;
	$go2gus->{$parentGoId} = $parentGusId;
	$gus2go->{$childGusId} = $childGoId;
	$gus2go->{$parentGusId} = $parentGoId;
    }


    my $sqlSyn = "select syn.go_term_id, syn.source_id, syn.text
                  from SRes.GoSynonym syn, SRes.GoTerm gt
                  where syn.go_term_id = gt.go_term_id
                  and gt.external_database_release_id = $extDbRelId";

    my $sthSyn = $queryHandle->prepareAndExecuts($sqlSyn);

    while (my ($goTermId, $sourceId, $text) = $sthSyn->fetchrow_array()){
	if ($sourceId != 0){       #'synonym'
	    $processedEntries->{Synonym}->{$goTermId}->{$sourceId} = 1;
	}
	else {          #'alternate id'
	    $processedEntries->{Synonym}->{$goTermId}->{$text} = 1;
	}
    }
    return ($gus2go, $go2gus, $processedEntries);
}

	
sub __make_go_graph{

    my ($self, $entries) = @_;
    my $graph;

    foreach my $entryId (keys %$entries){
	my $entry = $entries->{$entryId};

	my $classes = $entry->getClasses();
	my $containers = $entry->getContainers();
	my @parents = (@{$classes}, @{$containers});
	
	foreach my $parent (@parents){
	    if ($parent){ #classes or containers might be empty array
		$graph-> {childToParent} -> {$entryId} -> {$parent} = 1;
		$graph-> {parentToChild} -> {$parent} -> {$entryId} = 1;
	    }
	}
    }
    return $graph;
}

sub __getRelationshipTypeIds{
    my ($self) = @_;
       
    my ($isaId, $partOfId);
    my ($isaName, $partOfName);

    my $queryHandle = $self->getQueryHandle();
    my $sql = "select go_relationship_type_id, name 
               from sres.gorelationshiptype";
    
    my $sth = $queryHandle->prepareAndExecute($sql);
    while (my ($id, $name) = $sth->fetchrow_array()){
	if (lc($name) eq "isa"){
	    $isaId = $id;
	    $isaName = $name;
	}
	elsif (lc($name) eq "partof"){
	    $partOfId = $id;
	    $partOfName = $name;
	}
    }
    if ($isaName eq "" || $partOfName eq ""){
	die "LoadGoOntology Error:  Please populate SRes.GoRelationshipType.  The two entries should have their \"name\" attributes be equal to \"isa\" and \"partof\" (note that for the purposes of this plugin, case doesn't matter)";
    }
    return ($isaId, $partOfId);
}


sub __loadExtDbIds{

    my ($self) = @_;

    $self->{branchInfo}->{"function"}->{db_id} = $self->getArg('function_db_id');
    $self->{branchInfo}->{"process"}->{db_id} = $self->getArg('process_db_id');
    $self->{branchInfo}->{"component"}->{db_id} = $self->getArg('component_db_id');

}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

1;



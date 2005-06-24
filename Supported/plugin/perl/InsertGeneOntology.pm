#######################################################################
##           InsertGeneOntology.pm
##
## $Id$
##
#######################################################################

package GUS::Supported::Plugin::InsertGeneOntology;
@ISA = qw(GUS::PluginMgr::Plugin);

use CBIL::Bio::GeneOntologyParser::Parser;
use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";
use GUS::Model::SRes::GOTerm;
use GUS::Model::SRes::GORelationship;
use GUS::Model::SRes::GORelationshipType;
use GUS::Model::SRes::GOSynonym;
use GUS::Model::SRes::ExternalDatabaseRelease;
use GUS::Model::SRes::ExternalDatabase;
use FileHandle;

use strict 'vars';

my $purposeBrief = <<PURPOSEBRIEF;
Loads GO Terms into GUS and creates relationships among them.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
This plugin uses CBIL's Gene Ontology parser to parse one or more files provided by the Gene Ontology Consortium and load them into the database.  It preserves all ontology relationships and loads parent-child pairs, as well as the synonyms provided for each GO Term.
PLUGIN_PURPOSE

my $tablesAffected =
	[['SRes.GOTerm', 'Writes information about each GO Term here'],
	 ['SRes.GORelationship', 'Writes GO Term parent-child pairs here'], 
	 ['SRes.GOSynonym', 'Writes synonyms listed for each GO Term here'], 
	 ['SRes.ExternalDatabaseRelease', 'The user can optionally specify to create a new entry in this table when loading a branch of the ontology']];

my $tablesDependedOn =
	[['SRes.GORelationshipType', 'Must have entries for names \'isa\' and \'partof\', the two different types of parent-child relationships'],
	 ['SRes.ExternalDatabase', 'If the user wishes to create a new entry in ExternalDatabaseRelease, this table must be populated with entries for each branch of the ontology the user loads'],
	 ['SRes.ExternalDatabaseRelease', 'If the user is not creating a new entry in ExternalDatabaseRelease, they must provide the existing entry for each branch they are trying to load']];

my $howToRestart = <<PLUGIN_RESTART;
set the --loadAgain flag and provide the External Database Release Id of the interrupted branch of the ontology.  If you chose to allow the plugin to create a new release in the previous iteration, the id was written to the log file
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
None that we've found so far.
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
Assumes that the \"Obsolete\" GO Term Ids (that is, the parent, in each branch, of all GO Terms that have become obsolete) have IDs that don't vary between releases of the ontology.  If this is not the case, the IDs must be updated below.
The queries to SRes.GORelationshipType is case sensitive.  If you do not have the values 'isa' and 'partof' in all lowercase in the table they will be created by the plugin.
There is a conditional requirement for this plugin:  you must provide either the (component, function, process)ExtDbName argument or set --create and provide the (component, function, process)ExtDbName argument for every branch you are loading.
PLUGIN_NOTES


my $documentation = {purposeBrief => $purposeBrief,
		     purpose => $purpose,
		     tablesAffected => $tablesAffected,
		     tablesDependedOn => $tablesDependedOn,
		     howToRestart => $howToRestart,
		     failureCases => $failureCases,
		     notes => $notes
		    };



my $argsDeclaration =
  [

   stringArg({name=> 'filePath',
	      descr=> 'the file path to the directory where .ontology files to read are located. The path should not include the file names.',
	      reqd => 1,
	      constraintFunc => undef,
	      isList =>0
	     }),

   fileArg({name => 'flatFile',
	    descr => 'This is an optional argument in case the user wants to load only one of the .ontology files found in the directory specified by filePath.  Only the name of the file, NOT the full file path, should be included here, since the file path should be specified in the filePath argument.  If blank, read data from all .ontology files in filepath. ',
	    reqd => 0,
	    constraintFunc => undef,
	    isList => 0,
	    mustExist => 0,
	    format => 'One of the .ontology files available at ftp://ftp.geneontology.org/pub/go/ontology/.  The file name must remain in the <branch>.ontology format.'
	   }),
	 
   booleanArg({ name => 'createRelease',
		descr => 'Set this to automatically create an external database release id for this version of the GO branch you are loading',
		reqd => 0,
		default => 0
	      }),	
	 
   stringArg({name => 'functionExtDbName',
	    descr => 'external database name in GUS of the molecular function GO branch. Required if inserting this branch.',
	    constraintFunc => undef,
	    reqd => 0,
	    isList => 0
	    }),
 
   stringArg({name => 'processExtDbName',
	    descr => 'external database name in GUS of the biological process GO branch. Required if inserting this branch.',
	    constraintFunc => undef,
	    reqd => 0,
	    isList => 0
	    }),
 
   stringArg({name => 'componentExtDbName',
	    descr => 'external database name in GUS of the cellular component function GO branch. Required if inserting this branch.',
	    constraintFunc => undef,
	    reqd => 0,
	    isList => 0
	    }),
 
   booleanArg({name=> 'loadAgain',
	       descr => 'set this to reload a version of the GO Ontology that has been previously loaded.  The external database release id of the branch you are reloading must also be provided',
	       reqd => 0,
	       default =>0
	      })
  ];

sub new {
    
    my ($class) = @_;
    my $self = {};
    bless($self,$class);

    $self->initialize({requiredDbVersion => 3.5,
		       cvsRevision => '$Revision$', # cvs fills this in!
		       name => ref($self),
		       argsDeclaration => $argsDeclaration,
		       documentation => $documentation
		      });

    return $self;
}


#######################################################################
# Main Routine
#######################################################################

sub run {
    my ($self) = @_;
    $self->initializeOntology();
    my $path = $self->getArg('filePath');
    my $parser = CBIL::Bio::GeneOntologyParser::Parser->new($path);

    $self->{'rootLoaded'} = 0;
   
    my $fileName = $self->getArg('flatFile');

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

    my $msg = $self->loadOntology($parser);
    
    return $msg
}

#######################################################################
# Subroutines
#######################################################################

# ---------------------------------------------------------------------
# isReadOnly - doen't return anything
# ---------------------------------------------------------------------

sub isReadOnly { 0 }

# ---------------------------------------------------------------------
# initializeOntology
# ---------------------------------------------------------------------

sub initializeOntology{
    my ($self) = @_;

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
		  }
    };

}
    
# ---------------------------------------------------------------------
# loadOntology
# ---------------------------------------------------------------------

sub loadOntology {
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
	my $extDbRelId = $self->getExtDbRelId($branch, $store);
	my $obsoleteGoId = $self->{branchInfo}->{$branch}->{obsoleteGoId};
	my ($gus2go, $go2gus, $processedEntries) = $self->loadProcessedEntries($extDbRelId) if $self->getArg('loadAgain');
	my $entries = $store->getEntries();
	
	#make graph to help determine depth of entries in GO Tree. 
	my $goGraph = $self->makeGoGraph($entries);
	
	my $levelGraph = $self->makeLevelGraph($store->getRoot(), $goGraph);
	
	$self->log("making root node for $branch");
	($gus2go, $go2gus, $newEntries) = $self->makeRoots ($entries, $store, 
								 $extDbRelId, $processedEntries,
								 $logFile);
	
	$entryCount += $newEntries;
	
	my $ancestorGusId = $go2gus->{$store->getBranchRoot()};
	
	$self->log("loading GO Terms into SRes.GOTerm");

	#make entry in SRes.GOTerm for each entry in the go file
	foreach my $entryId(keys %$entries){
	    next if (($entryId eq $store->getBranchRoot())||($entryId eq $store->getRoot()));
	    
	    if ($processedEntries->{Term}->{$entryId}){
		$skipCount++;
		next;
	    }
	    $entryCount++;

	    my $entry = $entries->{$entryId};


	    my $gusGoTerm = $self->makeNewGoTerm($entry, $goGraph, $levelGraph, 
						   $obsoleteGoId, $extDbRelId, $ancestorGusId);
	    #write to successfully processed id list
	    $processedEntries->{Term}->{$entryId} = 1;

            # update translation tables between GO and GUS ids.
	    $gus2go->{ $gusGoTerm->getId() } = $entry->getId();

	    $go2gus->{ $entryId } = $gusGoTerm->getId();
	    $self->undefPointerCache();
	}
	
	my ($isaId, $partOfId) = $self->getRelationshipTypeIds();
	
	$self->log("loading hierarchy and synonyms into SRes.GORelationship and SRes.GOSynonym");

	#make hierarchy representation in SRes.GORelationship
	foreach my $entryGoId(keys %$entries){
	    
	    my $entry = $entries->{$entryGoId};
	    my ($relSkipCount, $newRelCount) = 
		$self->makeGoRelationshipsForChild($entry, $processedEntries, $go2gus, $isaId, $partOfId);

	    $skipCount += $relSkipCount;
	    $relationshipEntryCount += $newRelCount;

	    #make entry in GOSynonym if necessary
	    my ($synSkipCount, $newSynCount) = $self->makeGoSynonymsForGoTerm($entry, $processedEntries, $go2gus, $extDbRelId);

	    $skipCount += $synSkipCount;
	    $synonymEntryCount += $newSynCount;
	}      
    }
    
    return "Created $entryCount entries in GOTerm, $relationshipEntryCount entries in GORelationship, and $synonymEntryCount entries in GOSynonym.  Skipped $skipCount total entries";
}
    
# ---------------------------------------------------------------------
# makeNewGoTerm
# ---------------------------------------------------------------------

sub makeNewGoTerm{
    my ($self, $entry, $goGraph, $levelGraph, 
	$obsoleteGoId, $extDbRelId, $ancestorGusId) = @_;
    my $entryId = $entry->getId();
    my $l = $levelGraph->{$entryId};
    my @levelList = sort { $a <=> $b} @$l;
    my $obsolete = 0;
    my $numberOfLevels = $self->distinctLevels(\@levelList);
    if ($goGraph->{childToParent}->{$entryId}->{"$obsoleteGoId"}){
	$obsolete = 1
	};
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
       });

    #submit new term
    $gusGoTerm->submit();

    $self->logVeryVerbose("submitted new GO Term " . $gusGoTerm->toXML() . "\n");
    
    return $gusGoTerm;
}

# ---------------------------------------------------------------------
# makeGoRelationshipsForChild
# ---------------------------------------------------------------------
sub makeGoRelationshipsForChild{
    my ($self, $entry, $processedEntries, $go2Gus, $isaId, $partOfId) = @_;
    my ($skipCount, $relationshipEntryCount);
    my $classes = $entry->getClasses();
    my $containers = $entry->getContainers();
    my $entryGoId = $entry->getId();

    if ($classes){
	foreach my $parentGoId (@$classes){
	    my $goRelationship = 
		$self->makeNewGoRelationship($entryGoId, $parentGoId, $processedEntries, $go2Gus, $isaId);

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
		$self->makeNewGoRelationship($entryGoId, $parentGoId, $processedEntries, $go2Gus, $partOfId);

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

# ---------------------------------------------------------------------
# makeNewGoRelationship
# ---------------------------------------------------------------------

sub makeNewGoRelationship{
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

# ---------------------------------------------------------------------
# makeGoSynonymsForGoTerm
# ---------------------------------------------------------------------

sub makeGoSynonymsForGoTerm{
    my ($self, $entry, $processedEntries, $go2gus, $extDbRelId) = @_;
    my $skipCount, 
    my $synCount;
    my $altIds = $entry->getAlternateIds();
    my $synonyms = $entry->getSynonyms();
    my $entryGoId = $entry->getId();

    if ($altIds){
	foreach my $altId (@$altIds){
	    if ($processedEntries->{Synonym}->{$entryGoId}->{$altId}){
		$skipCount++;
		next;
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
		$skipCount++;
		next;
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

# ---------------------------------------------------------------------
# getExtDbRelId
# ---------------------------------------------------------------------

sub getExtDbRelId{
    my ($self, $branch, $store) = @_;
    my $extDbRelId;
    my $dbId;
    my $version = $store->getVersion();
    my $branchDescription = $store->getDescription();
    my $branchReleaseDate = $store->getReleaseDate();

    if (!($self->getArg('createRelease'))) { 
	$extDbRelId = $self->getExtDbRlsId($self->getArg($branch . "ExtDbName"),$version);

	if (!($extDbRelId)){
	    $self->userError("either no external database name passed in for $branch branch, or version didn't match the database.\n Either pass in --" . $branch . "ExtDbName or create a new one by setting --createRelease to true");
	}
    }
    #dtb should also check to see if release that was passed in is already loaded
    else{  #create new db
	my $dbName = $self->getArg($branch . "ExtDbName") || die "no external database name passed in for $branch branch.\n Pass in --" . $branch . "ExtDbName from command line.";

	my $extDb = GUS::Model::SRes::ExternalDatabase->new({
	                                                     name => $dbName
							    });

	if($extDb->retrieveFromDB()){
	    $dbId = $extDb->getExternalDatabaseId();
	}
	else{
	    $self->userError("Couldn't find external database " . $dbName . ". Use the plugin InsertExternalDatabase to insert this information into the database.\n");
	}

	my $extDbRls = GUS::Model::SRes::ExternalDatabaseRelease->new({
	                                                               external_database_id => $dbId,
								       version => $version
								      });

	if (($extDbRls->retrieveFromDB()) && !($self->getArg('loadAgain'))){
	    $self->userError("This version of GO (version $version) already exists in SRes.ExternalDatabaseRelease.\n  If you want to load the terms for this version again, please set the --loadAgain flag in the command line\n");
	}

	unless ($extDbRls->retrieveFromDB()) {   #this release doesn't exist and needs to be insertd
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

# ---------------------------------------------------------------------
# makeLevelGraph
# ---------------------------------------------------------------------

sub makeLevelGraph{
    my ($self, $rootId, $goGraph) = @_;

    $self->addLevelCount(0, $rootId, $goGraph);
    
    return $self->{levelGraph};
}

# ---------------------------------------------------------------------
# distinctLevels
# ---------------------------------------------------------------------

sub distinctLevels{
    my ($self, $levelList) = @_;
    my %levelsHash;

    foreach my $level (@$levelList){
	%levelsHash->{$level} = 1;
    }

    return scalar(keys %levelsHash);
}

# ---------------------------------------------------------------------
# add_level_count
# ---------------------------------------------------------------------

sub addLevelCount{
    my ($self, $currentLevel, $currentNode, $goGraph) = @_;

    push (@{$self->{levelGraph}->{$currentNode}}, $currentLevel);
    
    my $nextLevel = $currentLevel + 1;
    my $children = $goGraph->{parentToChild}->{$currentNode};

    foreach my $childOfCurrentNode (keys %$children){
	$self->addLevelCount($nextLevel, $childOfCurrentNode, $goGraph);
    }
}

# ---------------------------------------------------------------------
# makeRoots
# ---------------------------------------------------------------------

sub makeRoots{
    my ($self, $entries, $store, $extDbRelId, $processedEntries, $logFile) = @_;
    my $gus2go;
    my $go2gus;
    my $rootGoId = $store->getRoot();
    my $rootGusId = $self->{'rootLoaded'};
    my $newEntries = 0;
    my $branchRootGoId = $store->getBranchRoot();
    my $branchRootGusId;
    
    if (($rootGusId == 0) && !($processedEntries->{Term}->{$rootGoId})){

	$rootGusId = $self->makeOntologyRoot($entries, $rootGoId, $extDbRelId);
	$processedEntries->{Term}->{$rootGoId} = 1;
	$newEntries++;
    }
   
    if (!$processedEntries->{Term}->{$branchRootGoId}){
	
	$branchRootGusId = $self->makeBranchRoot($entries, $branchRootGoId, $extDbRelId);
	$processedEntries->{Term}->{$branchRootGoId} = 1;
	$newEntries++;
    }

    $go2gus->{$rootGoId} = $rootGusId;
    $go2gus->{$branchRootGoId} = $branchRootGusId;
    $gus2go->{$rootGusId} = $rootGoId;
    $gus2go->{$branchRootGusId} = $branchRootGoId;

    return ($gus2go, $go2gus, $newEntries);

}

# ---------------------------------------------------------------------
# makeBranchRoot
# ---------------------------------------------------------------------

sub makeBranchRoot{
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
       });
    
    #submit new term
    $branchGoTerm->submit();

    $self->logVeryVerbose("submitted branch go term " . $branchGoTerm->toXML() . "\n");
  
    my $gusId = $branchGoTerm->getId();
    
    #set self referential fk
    my $sql = "Update SRes.GOTerm Set ancestor_go_term_id = $gusId
               where external_database_release_id = $extDbRelId
               and go_term_id = $gusId";

    my $sth = $self->prepareAndExecute($sql);
    
    return  $gusId;
}

# ---------------------------------------------------------------------
# makeOntologyRoot
# ---------------------------------------------------------------------

sub makeOntologyRoot{
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
       });
    
    #submit new term
    $ontologyGoTerm->submit();

    $self->logVeryVerbose("submitted Root Ontology go term " . $ontologyGoTerm->toXML() . "\n");

    my $gusId = $ontologyGoTerm->getId();

    $self->{'rootLoaded'} = $gusId;

    return  $gusId;
}

# ---------------------------------------------------------------------
# loadProcessedEntries
# ---------------------------------------------------------------------

sub loadProcessedEntries{
    my ($self, $extDbRelId) = @_;
    my $processedEntries;  
    my ($go2gus, $gus2go);

    my $sqlTerm = "select go_id from SRes.GoTerm where external_database_release_id = $extDbRelId";
    my $sthTerm = $self->prepareAndExecute($sqlTerm);
   
    while (my ($goId) = $sthTerm->fetchrow_array()){
	$processedEntries->{Term}->{$goId} = 1;
    }
 
    my $sqlRel = "select child.go_id, parent.go_id, child.go_term_id, parent.go_term_id
               from SRes.GOTerm child, SRes.GOTerm parent, SRes.GORelationship rel
               where child.go_term_id = rel.child_term_id 
               and parent.go_term_id = rel.parent_term_id
               and child.external_database_release_id = $extDbRelId";
  
    my $sthRel = $self->prepareAndExecute($sqlRel);

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

    my $sthSyn = $self->prepareAndExecute($sqlSyn);

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

# ---------------------------------------------------------------------
# makeGoGraph
# ---------------------------------------------------------------------
	
sub makeGoGraph{
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

# ---------------------------------------------------------------------
# getRelationshipTypeIds
# ---------------------------------------------------------------------

sub getRelationshipTypeIds{
    my ($self) = @_;
    my ($isaId, $partOfId);

    my $isaNameObj = 
	GUS::Model::SRes::GORelationshipType->new({
	                                           name => 'isa', #this makes the following search case sensitive!!!
						  });

    if($isaNameObj->retrieveFromDB()) {
	$isaId = $isaNameObj->getGoRelationshipTypeId();
    }
    else{
	$isaNameObj->submit();
	$isaId = $isaNameObj->getGoRelationshipTypeId();
    }

    my $partOfNameObj = 
	GUS::Model::SRes::GORelationshipType->new({
	                                           name => 'partof', #this makes the following search case sensitive!!!
						  });

    if($partOfNameObj->retrieveFromDB()) {
	$partOfId = $partOfNameObj->getGoRelationshipTypeId();
    }
    else{
	$partOfNameObj->submit();
	$partOfId = $partOfNameObj->getGoRelationshipTypeId();
    }


    return ($isaId, $partOfId);
}

1;



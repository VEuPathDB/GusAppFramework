package GUS::GOPredict::Plugin::LoadGoOntology;
@ISA = qw( GUS::PluginMgr::Plugin);

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
    my $self = bless{}, $class;
    # initialize

    my $usage = "Loads GO Terms into GUS and creates relationships among them"; 
    my $easycsp =
	[
	 
	 {o=> 'flat_file',
	  h=> 'read data from this flat_file.  If blank, read data from all .ontology files in filepath',
          t=> 'string',
      },
	
	 {o => 'id_file',
	  h => 'read and append successfully processed ID here (necessary for crash-recovery)',
	  t => 'string',
	  r => 1,
      },
	 {o => 'create_release',
	  h => 'Set this to automatically create an external database release id for this GO Term version',
	  t => 'boolean',
      },	
	 {o => 'function_ext_db_rel',
	  h => 'External database release id in GUS of the molecular function GO branch',
	  t => 'int',
      },	
	 {o => 'component_ext_db_rel',
	  h => 'External database release id in GUS of the cellular component GO branch',
	  t => 'int',
      },	
	 {o => 'process_ext_db_rel',
	  h => 'External database release id in GUS of the biological process GO branch',
	  t => 'int',
      },	
	 {o => 'loadAgain',
	  h => 'set this to reload a version of the GO Ontology that has been previously loaded',
	  t => 'boolean',
      },
		 
	 {o=> 'file_path',
	  h=> 'location of .ontology files to read',
	  t=> 'string',
	  r=> 1,
      }
	 ];

    $self->initialize({requiredDbVersion => {},
		       cvsRevision => '$Revision$', # cvs fills this in!
	 		   cvsTag => '$Name$', # cvs fills this in!
 	 	       name => ref($self),
		       revisionNotes => 'make consistent with GUS 3.0',
		       easyCspOptions => $easycsp,
		       usage => $usage,
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

    my $path = $self->getCla->{file_path};
    my $parser = CBIL::Bio::GeneOntologyParser::Parser->new($path);

    $self->{'rootLoaded'} = 0;

    $self->__loadExtDbIds();
   
    my $fileName = $self->getCla->{flat_file};
    if ($fileName){
	$parser->loadFile($fileName);
    }
    else {
	$parser->loadAllFiles();
    }
	
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

    my $processedEntries = $self->__loadProcessedEntries();
    
    $self->__checkIfLoaded("Relationship", "GO:0016912", $processedEntries, "GO:0016909");
    my $id_file = $self->getCla->{id_file}; 
    
    #id file where successfully created db entries will be written to
    if ($id_file){
	$logFile = FileHandle->new( '>>'. $self->getCla->{ id_file } ); 
    }
    my $skipCount = 0;
    my $entryCount = 0;
    my $relationshipEntryCount = 0;
    my $synonymEntryCount = 0;
        
    my $stores = $parser->getFileCaches();

    #for each branch of the ontology
    foreach my $file (keys %$stores){
	
	my $store = $stores->{$file};
	
	my ($branch) = $file =~ /^(\w+).ontology$/;
	my $goVersion = $store->getVersion();

	my $extDbRelId = $self->__getExtDbRelId($branch, $goVersion);

	my $entries = $store->getEntries();
	
	#make graph to help determine depth of entries in GO Tree. 
	my $goGraph = $self->__make_go_graph($entries);
	
	my $levelGraph = $self->__make_level_graph($store->getRoot(), $goGraph);
	
	my $obsoleteGoId = $self->{branchInfo}->{$branch}->{obsoleteGoId};
	
	$self->log("making root node for $branch");
	my ($gus2go, $go2gus, $newEntries) = $self->__makeRoots ($entries, $store, 
								 $extDbRelId, $processedEntries,
								 $logFile);
	
	$entryCount += $newEntries;
	
	my $ancestorGusId = $go2gus->{$store->getBranchRoot()};
	
	$self->log("loading GO Terms into SRes.GOTerm");

	#make entry in SRes.GOTerm for each entry in the go file
	foreach my $entryId(keys %$entries){
	    
	    next if (($entryId eq $store->getBranchRoot())||($entryId eq $store->getRoot()));
	    
	    if ($self->__checkIfLoaded("Term", $entryId, $processedEntries)){
		$skipCount++;  next;
	    }
	    $entryCount++;
	    my $entry = $entries->{$entryId};
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
	    
	    #write to successfully processed id file
	    my $goId = $entry->getId();
	    print $logFile ("Term = $goId = $goId\n");

            # make translation tables between GO and GUS ids.
	    
	    $gus2go->{ $gusGoTerm->getId() } = $entry->getId();
	    $go2gus->{ $entry->getId() } = $gusGoTerm->getId();
	    $self->undefPointerCache();
	}
	
	my ($isaId, $partOfId) = $self->__getRelationshipTypeIds();
	
	$self->log("loading hierarchy and synonyms into SRes.GORelationship and SRes.GOSynonym");

	#make hierarchy representation in SRes.GORelationship
	foreach my $entryId(keys %$entries){
	    my $entry = $entries->{$entryId};
	    my $classes = $entry->getClasses();
	    my $containers = $entry->getContainers();
	    if ($classes){
		foreach my $class (@$classes){
		    
		    if ($self->__checkIfLoaded("Relationship", $entryId, $processedEntries, $class)) {
			$skipCount++; next;
		    }
		    
		    my $goRelationship = GUS::Model::SRes::GORelationship->new({
			parent_term_id => $go2gus-> {$class},
			child_term_id => $go2gus-> {$entryId},
			go_relationship_type_id => $isaId,
		    });

		    $goRelationship->submit();
		    print $logFile "Relationship = $entryId = $class\n";
		    $self->undefPointerCache();
		    $relationshipEntryCount++;
		}
	    }
	    if ($containers){
		foreach my $container (@$containers){
		    
		    if ($self->__checkIfLoaded("Relationship", $entryId, $processedEntries, $container)){
			$skipCount++; next;
		    }
		    my $goRelationship = GUS::Model::SRes::GORelationship->new({
			parent_term_id => $go2gus-> {$container},
			child_term_id => $go2gus-> {$entryId},
			go_relationship_type_id => $partOfId,
		    });

		    $goRelationship->submit();
		    print $logFile "Relationship = $entryId = $container\n";

		    $self->undefPointerCache();
		    $relationshipEntryCount++;
		    
		}
	    }
	    #make entry in GOSynonym if necessary
	    my $altIds = $entry->getAlternateIds();
	    my $synonyms = $entry->getSynonyms();
	    
	    if ($altIds){
		foreach my $altId (@$altIds){
		    if ($self->__checkIfLoaded("Synonym", $entryId, $processedEntries, $altId)){
			$skipCount++; next;
		    }
		    my $goSynonym = GUS::Model::SRes::GOSynonym->new({
			source_id => $altId,
			go_term_id => $go2gus-> {$entryId},
			text => "$altId is an alternate GO Id for " . $entryId,
			external_database_release_id => $extDbRelId,
		    });
		    $goSynonym->submit();
		    print $logFile "Synonym = $entryId = $altId\n";

		    $self->undefPointerCache();
		    $synonymEntryCount++;
		}
	    }
	    if ($synonyms){
		foreach my $synonym (@$synonyms){

		    if ($self->__checkIfLoaded("Synonym", $entryId, $processedEntries, $synonym)){
			$skipCount++; next;
		    }
		    my $goSynonym= GUS::Model::SRes::GOSynonym->new({
			go_term_id => $go2gus-> {$entryId},
			text => $synonym,
			external_database_release_id => $extDbRelId,
		    });
		    $goSynonym->submit();
		    print $logFile "Synonym = $entryId = $synonym\n";

		    $self->undefPointerCache();
		    $synonymEntryCount++;
		}
	    }
	}      
    }
    
    
    return "Test Plugin: Created (but did not insert) $entryCount entries in GOTerm, $relationshipEntryCount entries in GORelationship, and $synonymEntryCount entries in GOSynonym.  Skipped $skipCount total entries";
}
    
# ---------------------------------------------------------------------- #

sub __getExtDbRelId{
    my ($self, $branch, $version) = @_;

    my $extDbRelId;

    if (!($self->getCla->{create_release})) { 
	#db's passed in from cla
        $extDbRelId = $self->getCla->{$branch . "_ext_db_rel"};
	if (!($extDbRelId)){
	    $self->userError("no external database release passed in for $branch branch.\n Either pass in --" . $branch . "_ext_db_rel or create a new one by setting --create_release to true");
	}
    }
    #dtb should also check to see if release that was passed in already loaded

    else{  #create new db
	my $queryHandle = $self->getQueryHandle();
	
	my $dbId = $self->{branchInfo}->{$branch}->{db_id};
	
	my $sql = "select external_database_release_id 
               from sres.externalDatabaseRelease
               where version = \'$version\' and external_database_id = $dbId";

	my $sth = $queryHandle->prepareAndExecute($sql);
	
	while ( ($extDbRelId) = $sth->fetchrow_array()) {} #should only be one entry
	if (($extDbRelId) && !($self->getCla->{ loadAgain })){
	    $self->userError("This version of GO already exists in SRes.ExternalDatabaseRelease.\n  If you want to load the terms for this version again, please set the --loadAgain flag in the command line\n");
	}
	unless ($extDbRelId) {   #this release doesn't exist and needs to be insertd
	    my $extDbRelEntry = GUS::Model::SRes::ExternalDatabaseRelease->new({
		external_database_id => $dbId,
		version => $version,
	    });
	    
	    $extDbRelEntry->submit();
	    $extDbRelId = $extDbRelEntry->getId();
	    $self->log("successfully submitted new entry into SRes.ExternalDatabaseReleaseId with primary key of $extDbRelId\n");
	}
    }
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
    my $ancestorGoId = $store->getBranchRoot();
    my $ancestorGusId;
    
    if (($rootGusId == 0) && !($self->__checkIfLoaded("Term", $rootGoId, $processedEntries))){

	$rootGusId = $self->__makeOntologyRoot($entries, $rootGoId, $extDbRelId);
	print $logFile ("Term = $rootGoId = $rootGoId\n");
	$newEntries++;
    }
   
    if (!($self->__checkIfLoaded("Term", $ancestorGoId, $processedEntries))){
	
	$ancestorGusId = $self->__makeBranchRoot($entries, $ancestorGoId, $extDbRelId);
	print $logFile ("Term = $ancestorGoId = $ancestorGoId\n");

	$newEntries++;
    }

    $go2gus->{$rootGoId} = $rootGusId;
    $go2gus->{$ancestorGoId} = $ancestorGusId;
    $gus2go->{$rootGusId} = $rootGoId;
    $gus2go->{$ancestorGusId} = $ancestorGoId;

    return ($gus2go, $go2gus, $newEntries);

}

sub __makeBranchRoot{
    my ($self, $entries, $ancestorGoId, $extDbRelId) = @_;
    
    my $branchRootEntry = $entries->{$ancestorGoId};

    my $tempGusId = 1;
    my $branchGoTerm = GUS::Model::SRes::GOTerm->new({
	go_id  => $ancestorGoId, 
	external_database_release_id => $extDbRelId,
	source_id => $branchRootEntry->getId(), 
	name  => $branchRootEntry->getName(), #just the name
	definition   => $branchRootEntry->getName(),
	minimum_level => 1,
	maximum_level => 1,
	number_of_levels => 1,
	ancestor_go_term_id => $tempGusId,
    } );
    
    #submit new term
    $branchGoTerm->submit();
  
    my $gusId = $branchGoTerm->getId();
    
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
    
    my $tempAncestorId = 1;

    my $ontologyGoTerm = GUS::Model::SRes::GOTerm->new({
	go_id  => $rootGoId, 
	external_database_release_id => $extDbRelId,
	source_id => $rootEntry->getId(), 
	name  => $rootEntry->getName(), #just the name
	definition   => $rootEntry->getName(),
	minimum_level => 0,
	maximum_level => 0,
	number_of_levels => 1,
	ancestor_go_term_id => $tempAncestorId,
    } );
    
    #submit new term
    $ontologyGoTerm->submit();


    my $gusId = $ontologyGoTerm->getId();

    my $sql = "Update SRes.GOTerm Set ancestor_go_term_id = $gusId
               where external_database_release_id = $extDbRelId
               and go_term_id = $gusId";

   
    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);

    $self->{'rootLoaded'} = $gusId;

    return  $gusId;
}

sub __loadProcessedEntries{
    my ($self) = @_;
  
    my $logFile = FileHandle->new( '<'. $self->getCla->{ id_file } ); 

    my $processedEntries;

    if ($logFile){
	while (<$logFile>){
	    chomp;
	    my $line = $_;
	    
	    my ($type, $id, $relation) = $line =~ /^(\w+)\s=\s(\S+)\s=\s(.+)/;
	    $processedEntries->{$type}->{$id}->{id} = 1;
	    if ($type ne "Term"){
		$processedEntries->{$type}->{$id}->{relation}->{$relation} = 1;
	    }
	}
	$logFile->close();
    }

    return $processedEntries;
}

sub __checkIfLoaded{
    my ($self, $type, $entryId, $processedEntries, $relation) = @_;
    

    if (!($processedEntries->{$type}->{$entryId}->{id})){
	return 0;
    }
    elsif (($type ne "Term")&&($processedEntries->{$type}->{$entryId}->{relation}->{$relation} == 0)){
	return 0;
    }
    else{
	return 1;
    }
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
    my $queryHandle = $self->getQueryHandle();
    my ($isaId, $partOfId);
    my $sql = "select go_relationship_type_id, name 
               from sres.gorelationshiptype";
    
    my $sth = $queryHandle->prepareAndExecute($sql);
    while (my ($id, $name) = $sth->fetchrow_array()){
	if ($name eq "isa"){
	    $isaId = $id;
	}
	elsif ($name eq "partof"){
	    $partOfId = $id;
	}
	else { die "LoadGoOntology Error:  relationship type is neither isa nor partof.  Check to see if other relationship types have been added to SRes.GoRelationshipType";}

    }
    return ($isaId, $partOfId);
}


sub __loadExtDbIds{

    my ($self) = @_;
    
    $self->__loadExtDbId("function", "GO Function");
    $self->__loadExtDbId("component", "GO Component");
    $self->__loadExtDbId("process", "GO Process");

}


sub __loadExtDbId{
    my ($self, $branch, $name) = @_;

    my $queryHandle = $self->getQueryHandle();

    my $sth = $queryHandle->prepare("Select external_database_id from sres.externaldatabase where name = ?");
    
    my $db_id = $branch . "_db_id";
    if (!($self->getCla->{$db_id})){
	$sth->execute($name);
	my ($id) = $sth->fetchrow_array();
	$self->{branchInfo}->{$branch}->{db_id} = $id;
	
    }
    else{
	$self->{branchInfo}->{$branch}->{db_id} = $self->getCla->{$db_id};
    }
}






# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

1;



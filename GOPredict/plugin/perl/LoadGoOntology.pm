package GUS::GOPredict::Plugin::LoadGoOntology;
@ISA = qw( GUS::PluginMgr::Plugin);
use CBIL::Bio::DbFfWrapper::GeneOntology::Parser;

use lib "$ENV{GUS_HOME}/lib/perl";

use strict 'vars';

use FileHandle;

use GUS::Model::SRes::GOTerm;
use GUS::Model::SRes::GORelationship;
use GUS::Model::SRes::GORelationshipType;
use GUS::Model::SRes::GOSynonym;
use GUS::Model::SRes::ExternalDatabaseRelease;

#use V;

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
	function => {db_id => 227,
	              db_name => "GO Function",
		     obsoleteGoId => "GO:0008369",
		 },
	process => {db_id => 229,
		    db_name => "GO Process",
		    obsoleteGoId => "GO:0008371",
		},
	component => {db_id => 228,
		      db_name => "GO Component",
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

# ------------------------------

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub run {
    my $self = shift;

    my $path = $self->getCla->{file_path};
    my $parser = CBIL::Bio::DbFfWrapper::GeneOntology::Parser->new($path);


    my $fileName = $self->getCla->{flat_file};
    if ($fileName){
	$parser->loadFile($fileName);
    }
    else {
	$parser->loadAllFiles();
    }
	
    $parser->parseAllFiles();

    my $msg = $self->__load_ontology($parser);
    
    # return value
  
    return $msg
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub __load_ontology {
    my ($self, $parser) = @_;

    my $fakeGusId = 1;
    
    # increase the number of objects allowed in memory
    
    open (ontLOG, ">>logs/OntologyLog");
    my $entryCount = 0;
    my $relationshipEntryCount = 0;
    my $synonymEntryCount = 0;
    
    
    my $stores = $parser->getFileCaches();
    foreach my $file (keys %$stores){
	my $store = $stores->{$file};
	
	
#    $parser->loadAllFiles();
	# dictionary of terms go_id -> hash ref
	
	my ($branch) = $file =~ /^(\w+).ontology$/;
	my $goVersion = $store->getVersion();

	my $extDbRelId = $self->__getExtDbRelId($branch, $goVersion);
    

 
	#  my $my_id = 1;
	#for readonly stuff, not sure how this comes into play, ask
	#   my $get_my_id = sub { $my_id++ };
	
	
	my $gus2go;
	my $go2gus;
	my $gus_terms;
	
	
	my $entries = $store->getEntries();
	
	#make graph to help determine depth of entries in GO Tree. 
	my $goGraph = $self->__make_go_graph($entries);
	my $levelGraph = $self->__make_level_graph($store->getRoot(), $goGraph);
	my $obsoleteGoId = $self->{branchInfo}->{$branch}->{obsoleteGoId};
	my $ancestor;
	
	print STDERR "got $obsoleteGoId as obsolete Id for $branch \n";
	foreach my $entryId(keys %$entries){
	    $fakeGusId++;
	    my $entry = $entries->{$entryId};
	    my $l = $levelGraph->{$entryId};
	    my @levelList = sort { $a <=> $b} @$l;
	    my $obsolete = 0;
	    my $numberOfLevels = $self->__distinctLevels(\@levelList);
	    if ($goGraph->{childToParent}->{$entryId}->{"$obsoleteGoId"})
	    {$obsolete = 1};
	    
	    
	    $entryCount++;
	    
	    unless ($entry->getRoot()){
		$ancestor = $store->getBranchRoot();
	    }
	    
	    my $gusGoTerm = GUS::Model::SRes::GOTerm->new({
		go_id  => $entry->getId(), 
		external_database_release_id   => $extDbRelId,
		source_id => $entry->getId(), 
		name  => $entry->getName(), #just the name
		definition   => $entry->getName(),
		minimum_level => $levelList[0],
		maximum_level => $levelList[scalar(@levelList)-1],
		number_of_levels => $numberOfLevels,
		ancestor_go_term_id => $ancestor,
		is_obsolete => $obsolete,
	    } );
	    
	    
	    #submit new term
	    #$gusGoTerm->submit();
	    $gusGoTerm->setId($fakeGusId);
	    $gusGoTerm->{gus_id} = $fakeGusId;
	    print ontLOG $gusGoTerm->toString();
	    print ontLOG "levels: ";
	    foreach my $level (@levelList) { print ontLOG "$level ";}
	    print ontLOG "\n";
	    
	    # update the temporary structure to have the new gus id -- dtb does submit() assign the gusid back to the object? 
	    #ask shug but assume yes for now
	    #$gusGoTerm->{ gus_id } = $gusGoTerm->getId();
	    
	    # make translation tables between GO and GUS ids.
	    
	    $gus2go->{ $gusGoTerm->getId() } = $entry->getId();#easy enough
		$go2gus->{ $entry->getId() } = $gusGoTerm->getId();
	    $self->undefPointerCache();
	    
	}
	
	my ($isaId, $partOfId) = $self->__getRelationshipTypeIds();
	
	#make hierarchy representation in SRes.GORelationship
	foreach my $entryId(keys %$entries){
	    my $entry = $entries->{$entryId};
	    my $classes = $entry->getClasses();
	    my $containers = $entry->getContainers();
	    if ($classes){
		foreach my $class (@$classes){
		    my $goRelationship = GUS::Model::SRes::GORelationship->new({
			parent_term_id => $go2gus-> {$class},
			child_term_id => $go2gus-> {$entryId},
			go_relationship_type_id => $isaId,
		    });
		    print ontLOG $goRelationship->toString();
		    $self->undefPointerCache();
		    $relationshipEntryCount++;
		}
	}
	    if ($containers){
		foreach my $container (@$containers){
		    my $goRelationship = GUS::Model::SRes::GORelationship->new({
			parent_term_id => $go2gus-> {$container},
			child_term_id => $go2gus-> {$entryId},
			go_relationship_type_id => $partOfId,
		    });
		    print ontLOG $goRelationship->toString();
		    $self->undefPointerCache();
		    $relationshipEntryCount++;
		    
		}
	    }
	    #make entry in GOSynonym if necessary
	    my $altIds = $entry->getAlternateIds();
	    my $synonyms = $entry->getSynonyms();
	    
	    if ($altIds){
		foreach my $altId (@$altIds){
		    my $goSynonym = GUS::Model::SRes::GOSynonym->new({
			source_id => $altId,
			go_term_id => $go2gus-> {$entryId},
			text => "$altId is an alternate GO Id for " . $entryId,
			external_database_release_id => $extDbRelId,
		    });
		    print ontLOG $goSynonym->toString();
		    $self->undefPointerCache();
		    $synonymEntryCount++;
		}
	    }
	    if ($synonyms){
		foreach my $synonym (@$synonyms){
		    my $goSynonym= GUS::Model::SRes::GOSynonym->new({
			go_term_id => $go2gus-> {$entryId},
			text => $synonym,
			external_database_release_id => $extDbRelId,
		    });
		    print ontLOG $goSynonym->toString();
		    $self->undefPointerCache();
		    $synonymEntryCount++;
		}
	    }
	    
	}      
    }
    
    
	return "Test Plugin: Created (but did not insert) $entryCount entries in GOTerm, $relationshipEntryCount entries in GORelationship, and $synonymEntryCount entries in GOSynonym.";
}
    
# ---------------------------------------------------------------------- #

sub __getExtDbRelId{
    my ($self, $branch, $version) = @_;
    open (LOG, ">>logs/extdblog");
    my $queryHandle = $self->getQueryHandle();
    my $dbName = $self->{branchInfo}->{$branch}->{dbName};
    my $dbId = $self->{branchInfo}->{$branch}->{db_id};
    print STDERR "got dbid $dbId for $branch";
    my $sql = "select external_database_release_id 
               from sres.externalDatabaseRelease
               where version = \'$version\' and external_database_id = $dbId";
    print STDERR "executing " . $sql;
    my $sth = $queryHandle->prepareAndExecute($sql);
    my $extDbRelId;
    while ( ($extDbRelId) = $sth->fetchrow_array()) {} #should only be one entry
    
    unless ($extDbRelId) {   #this release doesn't exist and needs to be insertd
	my $extDbRelEntry = GUS::Model::SRes::ExternalDatabaseRelease->new({
	    external_database_id => $dbId,
	    version => $version,
	});
	# $extDbRelEntry->submit();
	$extDbRelId = $extDbRelEntry->getId();
	$extDbRelId = $dbId;
	print LOG $extDbRelEntry->toString();
	return $extDbRelId;
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




# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

1;



package GUS::GOPredict::Plugin::LoadGoOntology;
@ISA = qw( GUS::PluginMgr::Plugin);
use CBIL::Bio::DbFfWrapper::GeneOntology::Parser;

use Env qw(GUS_HOME); #this will have to change obviously
use strict 'vars';
use FileHandle;
use GUS:Model::SRES::GOTerm;
use GUS:Model::SRES::GORelationship;
use GUS:Model::SRES::GORelationshipType;
use GUS:Model::SRES::GOSynonym;


package LoadGoOntology;

#use V;

# ---------------------------------------------------------------------- #
# --------------------------------------------------------------------- #

sub new {
    
    # create
    my $classs = shift;
    my $self = bless{}, $class;
    # initialize

    my $usage = "Loads GO Terms into GUS and creates relationships among them"; 
    my $easycsp =
	[
	 
	 {o=> 'flat_file',
	  h=> 'read data from this flat file',
          t=> 'string',
          r=> 1,     
      },
	 { o=> 'cvs_version',
	   h=> 'go version to be entered as go_cvs_version in GOFunction',
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
		       usage => $usage
		       });
	  
    
    # return object.
    $self->{levelHash} = {};
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
    
    my $queryHandle = $self->getQueryHandle();
    
    open (LOG, ">>OntologyLog")
    
    # open the file
    # .................................................................
    
    my $fh = FileHandle->new( '<'. $self->getCla->{ flat_file } );
    unless ( $fh ) {
	my @msg = 'unable to open file', $self->getCla->{ flat_file }, $!;
    
	return join( "\t", 'no terms loaded', @msg );
    }
    
    my $msg;
    my $fileName = $self->getCla->{flat_file};
    $msg = $self->__load_ontology($fileName);
    
    # return value
  
    return $msg
}

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

sub __load_ontology {
    my ($self, $file) = @_;

    my $fakeGusId = 1;
    
    # increase the number of objects allowed in memory
    #..................................................................
    #need to figure out the equivalent for this
    $C->{'self_inv'}->setMaximumNumberOfObjects(30000);
    
    # parse the file
    # .................................................................
    
    #make path to file configurable, eventually go into data
    my $parser = CBIL::Bio::DbFfWrapper::GeneAssoc::Parser->new("$GUS_HOME/lib/perl/GUS/GOPredict/Plugin");
    $parser->loadFile("function.ontology");
    $parser->parseFile("function.ontology");
#    $parser->loadAllFiles();
    # dictionary of terms go_id -> hash ref
   
##above already done?
    
    # make GUS objects
    # .................................................................
    #objects to make:
    #SRES : GO Term
       #GO_ID, External_database_release_id, source_id, name, definition, comment_string, min_level, 
       #max_level, number of levels, ancestor_go_term_id, is_obselete
    #SRES : GoRelationshiop
       #parent_term_id, child_term_id, go_relationship_type_id
    #SRES : GoSynonym
       #exteranl_database_relaease_id, source_id, go_term_id, text
    #SRES : GORelationshipType: 
       #  name--isa or partof

  #  my $my_id = 1;
    #for readonly stuff, not sure how this comes into play, ask
 #   my $get_my_id = sub { $my_id++ };
    
    # branch is either GOFunction, GOProcess, or GOComponent
#    eval("require Objects::GUSdev::".$C->{ cla }->{ 'branch' });
    
    my $gus2go;
    my $go2gus;
    my $gus_terms;
    my $entryCount = 0;
    my $entries = $store->getEntries();

    #make graph to help determine depth of entries in GO Tree. 
    my $goGraph = $self->__make_go_graph($entries);
    my $levelGraph = $self->__make_level_graph($store->getRoot->getId(), $goGraph);

    foreach my $entryId(keys %$entries){
	$fakeGusId++;
	my $entry = $entries->{$entryId};
	my $l = $levelGraph->{$entryId};
	my @levelList = sort { $a <=> $b} @$l;
	my $obsolete = 0;
	if ($goGraph->{childToParent}->{$entryId}->{GO:0008369})
	{$obsolete = 1};
	

	$entryCount++;
	my $tempExtDb = 255;
	my $gusGoTerm = GUS::Model::SRes::GOTerm->new({
	    go_id  => $entry->getId(), 
	    external_database_release_id   => $tempExtDb,
	    source_id => $entry->getId(), 
	    name  => $entry->getName(), #just the name
	    definition   => $entry->getName(),
	    minimum_level => $levelList[0],
	    maximum_level => $levelList[scalar(@levelList)-1],
	    number_of_levels => scalar(@levelList),
	    ancestor_go_term_id => $store->getRoot->getId(),
	    is_obsolete => $obsolete,
	} );
	
	#not in new schema
	#if ($C->{ cla }->{ 'branch' } eq 'GOFunction'){
	#    $gusGoTerm->setGoCvsVersion( $C->{ cla }->{ 'cvs_ver' });
	#}
	
	#submit new term
	#$gusGoTerm->submit();
	print LOG $gusGoTerm->toString();
	
	
	# update the temporary structure to have the new gus id -- dtb does submit() assign the gusid back to the object? 
         #ask shug but assume yes for now
	#$gusGoTerm->{ gus_id } = $gusGoTerm->getId();
	$gusGoTerm->setId($fakeGusid);
	$gusGoTerm->{gus_id} = $fakeGusId;
	# make translation tables between GO and GUS ids.
	
	$gus2go->{ $gusGoTerm->getId() } = $entry->getId();#easy enough
	$go2gus->{ $entry->getId() } = $gusGoTerm->getId();
	
    }
    #make hierarchy representation in SRES.GORelationship
    foreach my $entryId(keys %$entries){
	my $entry = $entries->{$entryId};
	my $classes = $entry->getClasses();
	my $containers = $entry->getContainers();
	if ($classes){
	    foreach my $class (@$classes){
		my $goRelationship = GUS::Model::SRes::GORelationship->new({
		    parent_term_id => $go2gus-> {$class},
		    child_term_id => $go2gus-> {$entryId},
		    go_relationship_type_id => 1,
		});
		print LOG $goRelationship->toString();
	    }
	}
	if ($containers){
	    foreach my $container (@$containers){
		my $goRelationship = GUS::Model::SRes::GORelationship->new({
		    parent_term_id => $go2gus-> {$container},
		    child_term_id => $go2gus-> {$entryId},
		    go_relationship_type_id => 2,
		});
		print LOG $goRelationship->toString();
	    }
	}
	#make entry in GOSynonym if necessary
	my $altIds = $entry->getAlternateids();
	my $synonyms = $entry->getSynonyms();
	
	if ($altIds){
	    foreach my $altId (@$altIds){
		my $goSynonym = GUS::Model::SRes::GOSynonym->new({
		    source_id => $altId,
		    go_term-id => $go2gus-> {$entryId},
		    text => "$altId is an alternate GO Id for " . $go2gus->{$entryId},
		    external_database_release_id => 255,
		});
		print LOG $goSynonym->toString();
	    }
	}
	if ($synonyms){
	    foreach my $synonym (@$synonyms){
		my $goSynoym= GUS::Model::SRes::GOSynonym->new({
		    go_term-id => $go2gus-> {$entryId},
		    text => $synonym,
		    external_database_release_id => 255,
		});
		print LOG $goSynonym->toString();
	    }
	}
	
    }      
    
    # make the hierarchy
  
    return "Test Plugin: Created (but did not insert) $entryCount GO Entries,  GO Hierarchy Entries.";
}

# ---------------------------------------------------------------------- #


# ---------------------------------------------------------------------- #
sub __make_level_graph{

    my ($self, $rootId, $goGraph) = @_;

    $self->__add_level_count(0, $rootId, $goGraph);
    
    return $self->{levelGraph};

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




# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

1;

__END__

General loading commands:

set o = mgi ; \
ga --commit \
   --mode associations \
   --org $o \
   --version '%1.114%' \
   --flat Associations/gene_association.$o \
   --id-file Logs/lgo.$o.ids LoadGoOntology \
   > ! Logs/lgo.$o.log


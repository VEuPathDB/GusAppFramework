package GUS::GOPredict::Plugin::GoPlugin;
@ISA = qw( GUS::PluginMgr::Plugin);

use GUS::PluginMgr::Plugin;

use lib "$ENV{GUS_HOME}/lib/perl";

use strict;

use GUS::Model::DoTS::AAMotifGOTermRule;
use GUS::Model::DoTS::AAMotifGOTermRuleSet;
use GUS::Model::DoTS::Evidence;
use GUS::Model::SRes::GOTerm;
use GUS::Model::SRes::GORelationship;
use GUS::Model::DoTS::RNAInstance;
use GUS::Model::DoTS::Similarity;
use GUS::Model::DoTS::GOAssociation;
use GUS::GOPredict::DatabaseAdapter;
use GUS::GOPredict::GoManager;

use FileHandle;

$| = 1;

# ---------------------------------------------------------------------- #
#                                new                                     #
# ---------------------------------------------------------------------- #

#verbosity levels to pass to objects.  Kind of a hack because they are redefined in each module.
my $verboseLevel = 1;
my $veryVerboseLevel = 2;
my $noVerboseLevel = 0;


sub new {
    my $class = shift;
    print STDERR "class: $class";
    my $self = bless {}, $class;

    # initialize counters

    my $purposeBrief =  "Creates and manages Associations between DoTS and GO Functions";
    
    my $purpose = "This plugin is the starting point for a number of operations involving GO Function Associations to DoTS Assemblies and their translated proteins.  The plugin uses CBIL's GO Predictor Algorithm to apply GO prediction rules based on protein domains to the translated proteins.  It also manages these predictions by keeping them up-to-date with respect to the evolving GO Hierarchy, as well as tracking a number of other annotations on the Associations, both manually assigned and computationally predicted, to ensure the data is consistent the rules CBIL has devised for relationships among all GO Functions associated with one particular protein.";

    my $tablesAffected = 
	[['DoTS.GOAssociation', 'Creates and modifies associations between Proteins and GO Terms here'],
	 ['DoTS.GOAssociationInstance', 'An entry is put here for each change to a GOAssociation'],
	 ['DoTS.Evidence', 'Each GOAssociationInstance has an entry in this table reflecting the evidence for its existence'],
	 ['DoTS.Comments', 'Occasionally a new entry is put into the Comments table and used as Evidence for a GOAssociationInstance']];

    my $tablesDependedOn=[['SRes.GOTerm', 'Reads GO Functions in from this table'],
			  ['SRes.GORelationship', 'Uses this table to create a data structure representing relationships between GO Terms in the hierarchy'],
			  ['DoTS.AAMotifGOTermRule', 'Reads in GO Terms associated with a particular protein domain to make a prediction from this table'],
			  ['DoTS.MotifAASequence', 'Uses entries in this table as evidence for a prediction'],
			  ['DoTS.AAMotifGOTermRuleSet', 'Entries in this table are links between Rules and a domain; they are used in the prediction process'],
			  ['DoTS.Similarity', 'Represents a BLAST similarity between a protein and a domain; used in the prediction process and as Evidence for the prediction'],
			  ['DoTS.Protein', 'Translated protein of an Assembly to which the Association is explicitly made'],
			  ['DoTS.RNAInstance', 'Linking table to make a translation between a Protein and an Assembly'],
			  ['DoTS.RNAFeature', 'Linking table to make a translation between a Protein and an Assembly'],
			  ['DoTS.Assembly', 'DoTS assemblies to which the prediction is ultimately made through its translated protein']];

    my $howToRestart = "I think there is a way but need to figure it out.";

    my $notes = "See the wiki, as well as method headers in the modules this plugin uses, for extensive documentation on the process.";

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
     booleanArg({name=> 'evolve_go_hierarchy',
		 descr=> 'Set this flag to have the plugin update existing associations to a new release of the go hierarchy, and scrub the proteins afterwards',
		 reqd => 0,
		 constraintFunc => undef,
	     }),
     
     booleanArg({ name => 'apply_rules',
		  descr => 'Set this flag to have the plugin make new predictions on proteins based on generated rules, and scrub the proteins afterwards.  Always deletes non-primary instances and recaches',
		  reqd => 0,	
		  constraintFunc => undef,
	      }),
     
     booleanArg({ name => 'scrub_proteins_only',
		  reqd => 0,
		  descr => 'Set this flag to have the plugin make sure all association data is consistent, without evolving the GO hierarchy or applying rules.  By default, deletes and recaches non-primary instances',
		  constraintFunc => undef,
	     }),

     booleanArg({ name => 'do_not_scrub_proteins',
		  reqd => 0,
		  descr => 'Set this flag in conjunction with evolve_go_hierarchy or apply_rules to have the plugin skip the data consistency check at the end.  This is rarely necessary; make sure you have a good reason to do this.  Note that setting this will also skip recaching primary instances.',
		  constraintFunc => undef,
	      }),

     booleanArg({ name => 'do_not_recache_instances',
		  reqd => 0,
		  descr => 'Set this flag to skip the caching of primary instances for an association to its ancestors.',
		  constraintFunc => undef,
	      }),
     booleanArg({ name => 'do_not_delete_instances',
		  reqd => 0,
		  descr => 'Set this flag to skip the step of deleting non-primary instances of an association',
		  constraintFunc => undef,
	      }),

     booleanArg({ name => 'deprecate_associations',
		  reqd => 0,
		  descr => 'Set this flag to deprecate associations that have only deprecated instances.  Must be done as a separate process (generally after new rules have been applied)',
		  constraintFunc => undef,
	      }),
     stringArg({ name => 'apply_rules_raid_list',
		 reqd => 0,
		 descr => 'Comma separated list of row_alg_invocation_ids of associations whose proteins we will not consider when running deprecate_associations.  The associations to deprecate in this case are those that were not hit by previous runs of apply_rules (whose raids are those passed in with this parameter) and thus need to be deprecated, if they were not reviewed',
		 isList => 0,
		 constraintFunc => undef,
	     }),
     
     integerArg({ name => 'old_go_release_id',
		  reqd => 0,
		  descr => 'GUS external database release id of old GO version (to upgrade from)',	
		  constraintFunc => undef,
		  isList => 0,
	      }),
     
     integerArg({ name => 'new_go_release_id',
		  reqd => 1,
		  descr => 'GUS external database release id of new GO version (to upgrade to) or current if not upgrading',
		  constraintFunc => undef,
		  isList => 0,
	      }),
     
     stringArg({ name => 'function_root_go_id',
		 reqd => 1,
		 descr => 'GO Id (GO:XXXX format) of root of molecular function branch of GO Hierarchy',
		 constraintFunc => undef,
		 isList => 0,
	     }),
    
     stringArg({ name => 'test_protein_id_list',
		 reqd => 0,
		 isList => 1,
		 descr => 'if testing, comma separated list of proteins to perform algorithms on',
		 constraintFunc => undef,
	     }),
     
     integerArg({ name => 'test_number',
		  reqd => 0,
		  descr => 'if testing, limit the number of proteins to test to this number',
		  constraintFunc => undef,
		  isList => 0,
	      }),
     
     integerArg({ name => 'protein_table_id',
		  descr => 'id in Core.TableInfo for the DoTS.Protein Table',
		  reqd => 1,
		  constraintFunc => undef,
		  isList => 0,
	      }),
     
     stringArg({ name => 'subject_db_release_list',
		 descr => 'comma separated external database release id of motif database(s)',
		 isList => 1,
		 reqd => 0,
		 constraintFunc => undef,
	     }),
     
     stringArg({ name => 'query_db_release_list',
		 descr => 'comma separated external database release id of similarity query db(s), not used for Assembly queries',
		 reqd => 0,
		 isList => 1,
		 constraintFunc => undef,
	     }),
     
     stringArg({ name => 'query_table',
		 descr => 'name of table (in schema.table format) from which to select query sequences',
		 reqd => 0,
		 constraintFunc => undef,
		 isList => 0,
	     }),
     
     integerArg({ name => 'query_table_id',
		  descr => 'Id of table from which to select query sequences',
		  reqd => 0,
		  default => 56,
		  constraintFunc => undef,
		  isList => 0,
	      }),
     
     stringArg({ name => 'query_primary_attribute',
		 descr => 'name of primary key column for query sequence table ',
		 reqd => 0,
		 default => 'na_sequence_id',
		 constraintFunc => undef,
		 isList => 0,
	     }),
     
     integerArg({ name => 'query_taxon_id',
		  descr => 'taxon id for query sequences ',
		  reqd => 1,
		  constraintFunc => undef,
		  isList => 0,
	      }),
     
     # pv-ratio and/or threshold 
     floatArg({ name => 'ratio_cutoff',
		reqd => 0,
		descr => 'p-value ratio threshold for sim/rule',
		default => 0.8,  #this is what we have always used when applying rules
		constraintFunc => undef,
		isList => 0,
	    }),
     
     floatArg({ name => 'absolute_cutoff',
		reqd => 0,
		descr => 'p-value absolute threshold for sim/rule',
		default => 0.0001, #this is what we have always used when applying rules 	
		constraintFunc => undef,
		isList => 0,
	    }),

     booleanArg({ name => 'create_new_translations_file',
		  reqd => 0,
		  descr => 'set this flag to have the Database Adapter write a new result set of the Assembly-Protein translations to a file; used in conjunction with --translations_file_path',
		  constraintFunc => undef,
	      }),
     
     booleanArg({ name => 'create_new_similarities_file',
		  reqd => 0,
		  descr => 'set this flag to have the Database Adapter write a new result set of the Assembly-Motif similarities to a file; used in conjunction with --similarities_file_path',
		  constraintFunc => undef,
	      }),
     
     
     fileArg({ name => 'translations_file',
	       reqd => 0,
	       descr => 'File that stores the result set of the Assembly-Protein translations returned by the Database Adapter.  Use while testing',
	       mustExist => 0,
	       format => 'Each line of the file consists of the AssemblyId and its ProteinId, separated by a space',
     		    constraintFunc => undef,
		 isList => 0,
	 }),

     fileArg({ name => 'similarities_file',
	      reqd => 0,
	      mustExist => 0,
	      descr => 'File that stores the result set of the Assembly-Motif similarities returned by the Database Adapter.  Use while testing.',
	      format => 'Each line of the file is a space-separated triplet representing one similarity in the order QueryId SubjectId SimilarityId',
		    constraintFunc => undef,
		 isList => 0,
	   }),

	 stringArg({ name => 'skip_protein_raid_list',
		    reqd => 0,
		    descr => 'comma separated list of Algorithm Invocation Ids of Associations that were created during a run of apply_rules that was unexpectedly interrupted.',
  		    constraintFunc => undef,
		  isList => 0,
	 }),

	       booleanArg({ name => 'validate',
       reqd => 0,
       descr => 'set this flag to validate data after it has been processed (more time consuming but helps with level of correctness',
		    constraintFunc => undef,
	   }),
     
     ];


      $self->initialize({requiredDbVersion => {},
		       cvsRevision => '$Revision$', #cvs fills this in!
                       cvsTag => '$Name$', #cvs fills this in!
		       name => ref($self),
		       revisionNotes => 'makeConsistent with GUS 3.0',
		       argsDeclaration => $argsDeclaration,
		       documentation => $documentation
		   });

    # return the new plugin
    return $self;
 }

 sub run {
    my ($self) = @_;

    $self->logAlgInvocationId();
    $self->_validateCla();
    my $queryHandle = $self->getQueryHandle();
    my $db = $self->getDb(); #for undef pointer cache
    my $databaseAdapter = GUS::GOPredict::DatabaseAdapter->new($queryHandle, $db);
    
    my $proteinTableId = $self->getCla->{protein_table_id};
    my $newGoVersion = $self->getCla->{new_go_release_id};
    my $oldGoVersion = $self->getCla->{old_go_release_id};
    my $testProteinIds = $self->getCla->{test_protein_id_list};
    my $rootGoId = $self->getCla->{function_root_go_id};
    my $validate = $self->getCla->{validate};

    my ($deleteInstances, $recacheInstances, $doNotScrub) = $self->_determineInstanceManagement();
        
    $databaseAdapter->setTestProteinIds($testProteinIds) if $testProteinIds;
    $self->log("initializing translations");
    $databaseAdapter->initializeTranslations($self->getCla()->{query_taxon_id}, 
					     $self->getCla()->{translations_file_path}, 
					     $self->getCla()->{create_new_translations_file}) if $self->getCla->{apply_rules};

    
    $self->log("creating new go manager");
    my $goManager = GUS::GOPredict::GoManager->new($databaseAdapter);
    $goManager->setFunctionRootGoId($rootGoId);
    $goManager->setVerbosityLevel($self->_getVerbosityLevel());

    $goManager->setDeprecatedAssociations($databaseAdapter->getDeprecatedAssociations($self->getCla()->{query_taxon_id},
										      $proteinTableId));
    
    my $returnString = "GoPlugin ran successfully.  ";
        
    if ($self->getCla->{scrub_proteins_only}){
	
	$self->log("scrubbing proteins with go version $newGoVersion without evolving the go hiearchy or applying new rules");
	my $proteinsAffected = $goManager->scrubProteinsOnly($newGoVersion, $proteinTableId, $self->getCla()->{query_taxon_id},
							     $deleteInstances, $recacheInstances, $validate);
	
	$returnString .= "Scrubbed $proteinsAffected proteins.  ";
    }
    else{

	if ($self->getCla->{evolve_go_hierarchy}){

	    $self->log("GoPlugin: evolving Go Hierarchy");
	    my $proteinsChanged = $goManager->evolveGoHierarchy($oldGoVersion, $newGoVersion, $deleteInstances, 
								$recacheInstances, $proteinTableId, $doNotScrub, 
								$self->getCla()->{test_number}, $self->getCla()->{query_taxon_id},
								$self->getCla()->{skip_protein_raid_list}, $validate);
	    $returnString .= "Evolved go terms for associations with $proteinsChanged proteins.  ";
	}

	if ($self->getCla->{apply_rules}){
	    my $cla = $self->_makeClaHashForRules();

	    my $proteinsAffected = $goManager->applyRules($newGoVersion, $cla, $doNotScrub, 
							  $self->getCla()->{similarities_file_path},
							  $self->getCla()->{create_new_similarities_file},
							  $self->getCla()->{skip_protein_raid_list},
							  $self->getCla()->{test_number}, $validate); 
	    
	    $returnString .= "Applied rules to $proteinsAffected proteins.  ";
	}
	if ($self->getCla->{deprecate_associations}){
	    my $raidList = $self->getCla()->{apply_rules_raid_list};
	    my $proteinsAffected = $goManager->deprecateAssociations($raidList, $proteinTableId,
								     $newGoVersion, $self->getCla->{query_taxon_id});
	    
	    $returnString .= "Processed $proteinsAffected proteins for deprecating.  ";
	}

	$self->log("plugin all done!");
    }
    
    return $returnString;
}

sub _determineInstanceManagement{

    my ($self) = @_;
    
    my $deleteInstances = 1;
    my $recacheInstances = 1;
    my $doNotScrubProteins = 0;
    
    $deleteInstances = 0 if $self->getCla->{do_not_delete_instances};
    $recacheInstances = 0 if $self->getCla->{do_not_recache_instances};
    $doNotScrubProteins = 1 if $self->getCla->{do_not_scrub_proteins};


    return ($deleteInstances, $recacheInstances, $doNotScrubProteins);
}


sub _makeClaHashForRules{

    my ($self) = @_;
    
    my $queryTable = $self->getCla->{query_table};
    my $proteinTableId = $self->getCla->{protein_table_id};
    my $queryTableId = $self->getCla->{query_table_id};
    my $queryTablePkAtt = $self->getCla->{query_primary_attribute};
    my $subjectDbList =   $self->getCla->{subject_db_release_list};
    my $queryDbList =   $self->getCla->{query_db_release_list};
    my $queryTaxonId = $self->getCla->{query_taxon_id};
    my $ratioCutoff = $self->getCla->{ratio_cutoff};
    my $absoluteCutoff = $self->getCla->{absolute_cutoff};

    my $cla;
    $cla->{queryDbList} = $queryDbList;
    $cla->{proteinTableId} = $proteinTableId;
    $cla->{queryTableId} = $queryTableId;
    $cla->{queryTablePkAtt} = $queryTablePkAtt;
    $cla->{subjectDbList} = $subjectDbList;
    $cla->{queryTaxonId} = $queryTaxonId;
    $cla->{ratioCutoff} = $ratioCutoff;
    $cla->{absoluteCutoff} = $absoluteCutoff;
    $cla->{queryTable} = $queryTable;
    return $cla;
}


sub _validateCla{

    my ($self) = @_;

    if ($self->getCla()->{do_not_delete_instances} && !$self->getCla()->{do_not_recache_instances}){
	$self->userError("If --do_not_delete_instances is set, --do_not_recache_instances must also be set in order to avoid making duplicate instances");
    }
        
    if ($self->getCla()->{create_new_translations_file} && !$self->getCla()->{translations_file_path}){
	$self->userError("Please set --translations_file_path when creating a new file to store translations in");
    }

    if ($self->getCla()->{create_new_similarities_file} && !$self->getCla()->{similarities_file_path}){
	$self->userError("Please set --similarities_file_path when creating a new file to store similarities in");
    }

    if ($self->getCla()->{evolve_go_hierarchy} && !$self->getCla()->{old_go_release_id}){

	my $goErrMsg = "Please pass in external db release id of old go hierarchy if --evolve_go_hierarchy is set";
	$self->userError($goErrMsg);
    }

    if ($self->getCla()->{scrub_proteins_only}){
	
	if ($self->getCla()->{evolve_go_hierarchy} || $self->getCla()->{apply_rules}){
	    $self->userError("do not set --evolve_go_hierarchy or --apply_rules if --scrub_proteins_only is set.  --apply_rules and --evolve_go_hierarchy automatically scrub proteins unless --do_not_scrub_proteins is set");
    	}  
	
	if ($self->getCla()->{do_not_scrub_proteins}){
	    $self->userError("do not set --scrub_proteins_only and --do_not_scrub_proteins; it doesn't make sense!");
	}
    }

    if ($self->getCla()->{apply_rules}){

	my $queryTable = $self->getCla->{query_table};
	my $proteinTableId = $self->getCla->{protein_table_id};
	my $queryTableId = $self->getCla->{query_table_id};
	my $queryTablePkAtt = $self->getCla->{query_primary_attribute};
	my $subjectDbList =   $self->getCla->{subject_db_release_list};
       
	my $ratioCutoff = $self->getCla->{ratio_cutoff};
	my $absoluteCutoff = $self->getCla->{absolute_cutoff};

	my $errMsg = "When applying rules, you need to set all of --protein_table_id, --query_table_id,\n";
	$errMsg .= "--query_primary_attribute, --subject_db_release_list, --query_table";

	$self->userError($errMsg) if !($queryTableId && $queryTablePkAtt && $subjectDbList
				       && $proteinTableId && $queryTable);
	if (!($ratioCutoff || $absoluteCutoff)){
	    $self->userError("When applying rules, please specify at least one threshold (--ratio_cutoff or --absolute_cutoff) for a good similarity");
	}
	
	if ($self->getCla()->{do_not_delete_instances} || $self->getCla()->{do_not_recache_instances}){
	    $self->userError("When applying rules, the plugin will always delete and recache instances so deprecation occurs properly.  Do not set --do_not_delete_instances or --do_not_recache_instances when --apply_rules is set");
	} 

    }
}

sub _getVerbosityLevel{

    my ($self) = @_;

    my $tempVerboseLevel = $noVerboseLevel;
    $tempVerboseLevel = $verboseLevel if $self->getCla()->{verbose};
    $tempVerboseLevel = $veryVerboseLevel if $self->getCla()->{veryVerbose};
    return $tempVerboseLevel;

}

1;

package GUS::GOPredict::Plugin::GoPlugin;
@ISA = qw( GUS::PluginMgr::Plugin);

use lib "$ENV{GUS_HOME}/lib/perl";

use strict 'vars';

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
    my $self = bless {}, $class;
    
    # initialize counters
    $self->{n_predictions} = 0;
    $self->{n_rnas}        = 0;

    my $usage =  'Creates and manages Associations between DoTS and GO Terms';
    
    my $easycsp = 
    [
     
     { o => 'evolve_go_hierarchy',
       t => 'boolean',
       h => 'Set this flag to have the plugin update existing associations to a new release of the go hierarchy, and scrub the proteins afterwards',
   },

     { o => 'apply_rules',
       t => 'boolean',
       h => 'Set this flag to have the plugin make new predictions on proteins based on generated rules, and scrub the proteins afterwards.  Always deletes non-primary instances and recaches',
   },

     { o => 'scrub_proteins_only',
       t => 'boolean',
       h => 'Set this flag to have the plugin make sure all association data is consistent, without evolving the GO hierarchy or applying rules.  By default, deletes and recaches non-primary instances',
   },

     { o => 'do_not_scrub_proteins',
       t => 'boolean',
       h => 'Set this flag in conjunction with evolve_go_hierarchy or apply_rules to have the plugin skip the data consistency check at the end.  This is rarely necessary; make sure you have a good reason to do this.  Note that setting this will also skip recaching primary instances.',
   },

     { o => 'do_not_recache_instances',
       t => 'boolean',
       h => 'Set this flag to skip the caching of primary instances for an association to its ancestors.',
    },

     { o => 'do_not_delete_instances',
       t => 'boolean',
       h => 'Set this flag to skip the step of deleting non-primary instances of an association',
   },

#     { o => 'deprecate_associations',
#       t => 'boolean',
#       h => 'Set this flag to deprecate associations that have only deprecated instances.  Must be done as a separate process (generally after new rules have been applied)',
#   },
    
     { o => 'old_go_release_id',
       t => 'int',
       h => 'GUS external database release id of old GO version (to upgrade from)',
   },
   
     { o => 'new_go_release_id',
       t => 'int',
       h => 'GUS external database release id of new GO version (to upgrade to) or current if not upgrading',
       r => 1,
   },
    
     { o => 'old_function_root_go_id',
       t => 'string',
       h => 'GO Id (GO:XXXX format) of root of molecular function branch of old GO Hierarchy',
       d => 'GO:-0000001',
   },
 
     { o => 'new_function_root_go_id',
       t => 'string',
       h => 'GO Id (GO:XXXX format) of root of molecular function branch of new GO Hierarchy',
       d => 'GO:0003674',
   },
    
     { o => 'test_protein_id_list',
       t => 'string',
       h => 'if testing, comma separated list of proteins to perform algorithms on',
   },

     { o => 'protein_table_id',
       h => 'id in Core.TableInfo for the DoTS.Protein Table',
       t => 'string',
       d => '180',
       r => 1,
   },

     { o => 'subject_db_release_list',
       h => 'comma separated external database release id of motif database(s)',
       t => 'string',
       d => '2293', # prodom 2001.1, was previously 148.
   },

     { o => 'query_db_release_list',
       h => 'comma separated external database release id of similarity query db(s), not used for Assembly queries',
       t => 'string',
   },
    
     { o => 'qs_old_date',
       t => 'string',
       h => 'date of oldest sequence allowable',
       d => '01/01/1900',
   },
	
     { o => 'query_table',
       h => 'name of table (in schema.table format) from which to select query sequences',
       t => 'string',
   },

     { o => 'query_table_id',
       h => 'Id of table from which to select query sequences',
       t => 'int',
   },

     { o => 'query_primary_attribute',
       h => 'name of primary key column for query sequence table ',
       t => 'string',
   },


     { o => 'query_taxon_id',
       h => 'taxon id for query sequences ',
       t => 'string',
   },
#duplicate CLA!
     { o => 'query_xdbr',
       h => 'External database release of query sequences if they have one (used for applying rules to external sequences) ',
       t => 'string',
   },

     #template cla, only used for plasmo
     { o => 'qs_project',
       h => 'select sequences with this project',
       t => 'string',
   },
     
     # pv-ratio and/or threshold 
     { o => 'ratio_cutoff',
       t => 'float',
       h => 'p-value ratio threshold for sim/rule',
       d => 1.0,
   },
			      
     { o => 'absolute_cutoff',
       t => 'float',
       h => 'p-value absolute threshold for sim/rule',
   },

     { o => 'create_new_translations_file',
       t => 'boolean',
       h => 'set this flag to have the Database Adapter write a new result set of the Assembly-Protein translations to a file; used in conjunction with --translations_file_path',
   },

     { o => 'create_new_similarities_file',
       t => 'boolean',
       h => 'set this flag to have the Database Adapter write a new result set of the Assembly-Motif similarities to a file; used in conjunction with --similarities_file_path',
   },

     { o => 'similarities_file_path',
       t => 'string',
       h => 'fully qualified path, including the file name, of the file that stores the result set of the Assembly-Motif similarities returned by the Database Adapter.  Use while testing.',
   },

     { o => 'translations_file_path',
       t => 'string',
       h => 'fully qualified path, including the file name, of the file that stores the result set of the Assembly-Protein translations returned by the Database Adapter.  Use while testing',
   },


     
    
     #dtb: don't know why we'd use these sql filters but keep for now
	
     #verify this and put in documentation
	# guide for PlasmoDB predictions. NOTE:  you should also provide 
	# appropriate --sql-from and --sql-filter options on the command 
	# line.  For example:
	#     --sql-from "TranslatedAAFeature tf,
	#                 RNAFeature rf,
	#                 ProjectLink pl
	#     --sql-filter "sim.p_value_exp <= -5                  and 
	#                   q.aa_sequence_id = tf.aa_sequence_id and 
	#                   tf.na_feature_id = rf.na_feature_id  and 
	#                   pl.id = rf.parent_id                 and
	#                   pl.table_id = 108                    and 
	#                   pl.project_id = 113
	# Will allow you to generate predictions for PlasmoDB 3.1.


     { o => 'rule_sql_filter',
       t => 'string',
       h => 'extra where clause terms used for rule selection, OVERRIDES the raid parameter; remember ruleset table is called "rs"',
   },
     
     # extra filter for SQL similarity selection
     { o => 'sql_filter',
       t => 'string',
       h => 'extra where clause terms used for similarity selection; remember query sequence table is called "q"',
       
   },
     # extra FROM for similarity selection
     { o => 'sql-from',
       t => 'string',
       h => 'extra FROM clause terms used for similarity selection.',
   }

     ];


    $self->initialize({requiredDbVersion => {},
		       cvsRevision => '$Revision$', #cvs fills this in!
                       cvsTag => '$Name$', #cvs fills this in!
		       name => ref($self),
		       revisionNotes => 'makeConsistent with GUS 3.0',
		       easyCspOptions => $easycsp,
		       usage => $usage,
		   });

    # return the new plugin
    return $self;
}

sub run {
    my ($self) = @_;
    
    $self->_validateCla();
    my $queryHandle = $self->getQueryHandle();
    my $db = $self->getDb(); #for undef pointer cache
    my $databaseAdapter = GUS::GOPredict::DatabaseAdapter->new($queryHandle, $db);
    
    my $proteinTableId = $self->getCla->{protein_table_id};
    my $newGoVersion = $self->getCla->{new_go_release_id};
    my $oldGoVersion = $self->getCla->{old_go_release_id};
    my $testProteinIds = $self->getCla->{test_protein_id_list};
    my $oldGoRootId = $self->getCla->{old_function_root_go_id};
    my $newGoRootId = $self->getCla->{new_function_root_go_id};
        
    my ($deleteInstances, $recacheInstances, $doNotScrub) = $self->_determineInstanceManagement();
        
    $databaseAdapter->setTestProteinIds($testProteinIds) if $testProteinIds;
    $self->log("initializing translations");
    $databaseAdapter->initializeTranslations($self->getCla->{query_taxon_id}, 
					     $self->getCla()->{translations_file_path}, 
					     $self->getCla()->{create_new_translations_file}) if $self->getCla->{apply_rules};
    
    $self->log("creating new go manager");
    my $goManager = GUS::GOPredict::GoManager->new($databaseAdapter);
    $goManager->setOldFunctionRootGoId($oldGoRootId) if $oldGoRootId;
    $goManager->setNewFunctionRootGoId($newGoRootId) if $newGoRootId;
    $goManager->setVerbosityLevel($self->_getVerbosityLevel());

    my $msg = "GoPlugin ran successfully.  ";

    if ($self->getCla->{scrub_proteins_only}){

	$self->log("scrubbing proteins with go version $newGoVersion without evolving the go hiearchy or applying new rules");
	my $proteinsAffected = $goManager->scrubProteinsOnly($newGoVersion, $proteinTableId, 
							 $deleteInstances, $recacheInstances);

	$msg .= "Scrubbed $proteinsAffected proteins.  ";
    }

    else{

	if ($self->getCla->{evolve_go_hierarchy}){

	    $self->log("GoPlugin: evolving Go Hierarchy");
	    my $proteinsChanged = $goManager->evolveGoHierarchy($oldGoVersion, $newGoVersion, $deleteInstances, 
								$recacheInstances, $proteinTableId, $doNotScrub);
	    $msg .= "Evolved go terms for associations with $proteinsChanged proteins.  ";
	}

	if ($self->getCla->{apply_rules}){
	    
	    my $cla = $self->_makeClaHashForRules();
	    my $proteinsAffected = $goManager->applyRules($newGoVersion, $cla, $doNotScrub, 
							  $self->getCla()->{similarities_file_path},
							  $self->getCla()->{create_new_similarities_file}); 
	    
	    $msg .= "Applied rules to $proteinsAffected proteins.  ";
	}

	$self->log("plugin all done!");
    }
    
    return $msg;
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
	$errMsg .= "--query_primary_attribute, --subject_db_release_list";

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

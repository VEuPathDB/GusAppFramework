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
       h => 'Set this flag to have the plugin update existing associations to a new release of the go hierarchy',
   },

     { o => 'apply_rules',
       t => 'boolean',
       h => 'Set this flag to have the plugin make new predictions on proteins based on generated rules',
   },

     { o => 'scrub_proteins',
       t => 'boolean',
       h => 'Set this flag to have the plugin make sure all association data is consistent (automaticaly performed in conjunction with apply_rules and evolve_go_hierarchy',
   },
     
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
       
       t => 'string',
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
    
    my $queryHandle = $self->getQueryHandle();
    my $db = $self->getDb(); #for undef pointer cache
    my $databaseAdapter = GUS::GOPredict::DatabaseAdapter->new($queryHandle, $db);
    
    my $proteinTableId = $self->getCla->{protein_table_id};
    my $newGoVersion = $self->getCla->{new_go_release_id};
    my $testProteinIds = $self->getCla->{test_protein_id_list};
    my $oldGoRootId = $self->getCla->{old_function_root_go_id};
    my $newGoRootId = $self->getCla->{new_function_root_go_id};

    $databaseAdapter->setTestProteinIds($testProteinIds) if $testProteinIds;

    $databaseAdapter->initializeTranslations($self->getCla->{query_taxon_id});

    my $goManager = GUS::GOPredict::GoManager->new($databaseAdapter);
    $goManager->setOldFunctionRootGoId($oldGoRootId) if $oldGoRootId;
    $goManager->setNewFunctionRootGoId($newGoRootId) if $newGoRootId;
    
    my $msg;
    # get method name

    if ($self->getCla->{scrub_proteins} && !($self->getCla->{evolve_go_hierarchy} && $self->getCla->{apply_rules})){
	#only scrubbing
	$goManager->scrubProteins($newGoVersion, $proteinTableId);
    }
    else{

	if ($self->getCla->{evolve_go_hierarchy}){

	    my $oldGoVersion = $self->getCla->{old_go_release_id};
	    my $goErrMsg = "Please pass in external db release id of old go hierarchy if --evolve_go_hierarchy is set";
	    $self->userError($goErrMsg) if !$oldGoVersion;
	    
	    my $recache = 1;
	    $recache = 0 if $self->getCla->{apply_rules}; #don't recache if applying rules right afterwards
#	    my $deleteCache = 1;
	    my $deleteCache = 0;

	    $goManager->evolveGoHierarchy($oldGoVersion, $newGoVersion, $deleteCache, $recache, $proteinTableId);
	}

	if ($self->getCla->{apply_rules}){
	    
	    my $deleteCache = 1;
	    $deleteCache = 0 if ($self->getCla->{evolve_go_hierarchy}); #don't delete cache if already done so
	    my $recache = 1;
	    my $cla = $self->_makeClaHashForRules();
	    $goManager->applyRules($newGoVersion, $deleteCache, $recache, $cla);
	}

	$goManager->scrubProteins($newGoVersion, $proteinTableId);
	
    }
    
    return "plugin worked!";
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


    my $errMsg = "When applying rules, you need to set all of --protein_table_id, --query_table_id,\n";
    $errMsg .= "--query_primary_attribute, --subject_db_release_list";

    $self->userError($errMsg) if !($queryTableId && $queryTablePkAtt && $subjectDbList
				   && $proteinTableId && $queryTable);

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


package GUS::PluginMgr::GusApplication;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;

use CBIL::Util::EasyCsp;

use GUS::PluginMgr::Plugin;

use GUS::Model::Core::Algorithm;
use GUS::Model::Core::AlgorithmImplementation;
use GUS::Model::Core::AlgorithmInvocation;
use GUS::Model::Core::AlgorithmParamKey;
use GUS::Model::Core::AlgorithmParam;

use constant FLAG_DEBUG => 0;

# ----------------------------------------------------------------------

# [name, default (or null if reqd), comment]
my @properties =
(
 ["md5sum",         "",  "full path of md5sum executable (for check summing)"],
 );

sub new {
  my $C = shift;
  my $A = shift;

  my $m = bless {}, $C;

  $m->initialize({requiredDbVersion => { Core => '3' },
		  cvsRevision => '$Revision$',
		  cvsTag => '$Name$',
		  name => ref($m),
		  revisionNotes => 'update for GUS 3.0',
		  easyCspOptions => {},
		  usage => ""
		 });

  my $configFile = "$ENV{GUS_HOME}/config/GUS-PluginMgr.prop";

  $m->userError("Config file $configFile does not exist.  Please copy $configFile.sample to $configFile and edit to reflect your configuration") unless -e $configFile;

  $m->{propertySet}= CBIL::Util::PropertySet->new($configFile, \@properties);

  $m->initName(ref $m);
  $m->initMd5Executable($m->{propertySet}->getProp('md5sum'));

  return $m
}

# ----------------------------------------------------------------------

# what is the run mode
sub getMode       { $_[0]->{__gus__plugin__mode} }
sub setMode       { $_[0]->{__gus__plugin__mode} = $_[1]; $_[0] }

# ----------------------------------------------------------------------

sub findAlgorithm {
  my $M = shift;
  my $P = shift;

  my $alg_gus = GUS::Model::Core::Algorithm->new({ name => $P->getName });
  $alg_gus->retrieveFromDB;

  $P->initAlgorithm($alg_gus->getId ? $alg_gus : undef)
}

# ----------------------------------------------------------------------

sub findImplementation {
  my $M = shift;
  my $P = shift;

  my $implementation = $M->findSomeImplementation($P);
  $P->initImplementation($implementation) if $implementation;

  $P->logVerbose('DEBUG', ref $implementation) if FLAG_DEBUG;
}

sub findSomeImplementation {
  my $M = shift;
  my $P = shift;

  my $e = $P->getName;
  my $cvsRevision = $P->getCVSRevision;

  # can either be done in +create/+update mode as ga or in +run mode as plugin
  my $sql = <<SQL;
    SELECT *
      FROM Core.AlgorithmImplementation
     WHERE executable = '$e'
       AND cvs_revision    = '$cvsRevision'

SQL
  my $imps = $P->sql_get_as_hash_refs($sql);

  # none found
  if (scalar @$imps == 0) {
    $sql = "select * from core.algorithmimplementation where executable = '$e'";
    my $imps_again = $P->sql_get_as_hash_refs($sql);

    if (scalar @$imps_again == 0) {
      $M->userError("No Core.AlgorithmImplementation found for $e.\nPlease use 'ga +create $e --commit'");
    } else {
      $M->userError("No Core.AlgorithmImplementation found for $e cvs revision $cvsRevision. \nPlease use 'ga +update $e --commit'");
    }
  }

  # too many found
  elsif ( scalar @$imps > 1 ) {
    my $err = "Found more than one Core.AlgorithmImplementation for exe=$e cvsRev=$cvsRevision:\n";
    foreach (@$imps) {
      $err .= "  algimp_id:$_->{ALGORITHM_IMPLEMENTATION_ID}  md5:$_->{EXECUTABLE_MD5}  rev:$_->{CVS_REVISION}  tag:$_->{CVS_TAG}\n";
    }
    $M->userErr($err);
  }

  elsif ($M->getArgs->{commit} &&
	 $imps->[0]->{EXECUTABLE_MD5} ne $P->getCheckSum()) {
    my $run = "ga +update $e";
    $run = "ga +meta" if $e =~ /GusApplication/;
    $M->userError("The md5 checksum of ${e}'s executable file (cvs revision $cvsRevision) doesn't match the md5 checksum in the database for that plugin and revision. IE, the plugin has been changed but not commited and updated.  Please:
                   - cvs commit the plugin file
                   - use the build system to install it
                   - run '$run --commit'\nAborting");
  }

  # just right
  else {
    my $imp = GUS::Model::Core::AlgorithmImplementation
      ->new({
	     algorithm_implementation_id => $imps->[0]->{ALGORITHM_IMPLEMENTATION_ID}
	    });
    if (!$imp->retrieveFromDB) {
      CBIL::Util::Disp::Display($imps->[0]);
      $M->error("findSomeImplementation failed retrieving from db");
    }
    return $imp;
  }
}


# ----------------------------------------------------------------------

sub parseAndRun {
  my $M = shift;
  my $A = shift;

  my $ga_mode_str;
  my $plugin_class_str;

  # no arguments; we can't do anything.
  if (scalar @$A == 0) {
    ;
  }

  # first argument begins with a '+'; this is new mode.
  elsif ($A->[0] =~ /^\+(.+)/) {

    # save the matched mode name and toss the cla
    $ga_mode_str      = $1;
    shift @$A;

    # grab the plugin class name
    $plugin_class_str = shift @$A unless $A->[0] =~ /^-/;
  }

  # first argument begins with a '-'; this the old mode, show help
  elsif ($A->[0] =~ /^-/) {
    ;
  }

  # new mode with implied +run.
  else {

    # run-mode
    $ga_mode_str = 'run';

    # get plugin class name from the end of the cla list
    $plugin_class_str = shift @$A;
  }

  if (defined $ga_mode_str) {
    $M->setMode($ga_mode_str);
    $M->doMajorMode($plugin_class_str)
  } else {
    $M->showUsage;
  }
}

# ----------------------------------------------------------------------

sub showUsage {
  my $M = shift;

  print <<USAGE;

ga runs a plugin in one of the possible modes.

ga [<mode>] <plugin-class-name> [<options>]

  <mode> is one of +run, +history, +create, or +update.  The default value is +run.
  <options> is a list of --option value pairs
  <plugin-class-name> is the name of the plugin to process.

  +run     - run the plugin so it can perform its algorithm.

  +meta    - create Core.Algorithm and Core.AlgorithmImplementation for self.

  +create  - create rows for Core.Algorithm and Core.AlgorithmImplementation.

	+update  - create a new Core.AlgorithmImplementation for and existing
             Core.Algorithm.

  +history - list any Core.Algorithm, Core.AlgorithmImplementation, and
             CoreAlgorithmInvocation rows for the plugin.

For example,

  ga UpdateGusFromXML --file my_new_data.xml --commit

The legal options depend on the mode and plugin.  To get help use a command like this:

  ga +update --help

  ga UpdateGusFromXML --help

USAGE

}

# ----------------------------------------------------------------------

sub newFromPluginName {
  my $M = shift;
  my $C = shift;		# plugin-class name

  my $require_p = "{require $C; $C->new }";
  my $plugin = eval $require_p;

  $M->error($@) if $@;

  $plugin->initName($C);
  $plugin->initMd5Executable($M->{propertySet}->getProp('md5sum'));
  return $plugin;
}

# Reads parameter key/value pairs from a file.  Tries a bunch of
# different places and names.
sub getConfig {
  my ($self) = @_;

  if (!$self->{config}) {
    my $cla = $self->getArgs();
    $self->{config} = GUS::Common::GusConfig->new($cla->{gusconfigfile});
  }

  $self->{config};
}

# ----------------------------------------------------------------------
# A dispatcher for main running modes.
# ----------------------------------------------------------------------

sub doMajorMode {
  my $M = shift;
  my @A = @_;

  my @modes    = qw( meta create update history run );
  my $modes_rx = '^('. join('|',@modes). ')$';

  if ($M->getMode =~ /$modes_rx/) {

    # make method name and run
    my $method = 'doMajorMode_'. ucfirst lc $M->getMode;
    $M->$method(@A);
  }

  # bad mode or mood
  else {
    $M->userError($M->getMode() . " is not a supported mode; should be one of" . join(', ', @modes));
  }

}

# ----------------------------------------------------------------------
# Create info for self
# ----------------------------------------------------------------------

#! GA
sub doMajorMode_Meta {
  my $M = shift;

  my $ecd = { %{$M->getGlobalEasyCspOptions} };
  my $cla = CBIL::Util::EasyCsp::DoItAll($ecd,$M->getUsage) || die;

  $M->initArgs($cla);

  # connect to the database
  $M->connect_to_database($M);

  # what versions does the plugin want?
  $M->_check_schema_version_requirements($M);

  # create/find a Core.Algorithm, Core.AlgorithmImplementation, and Core.AlgorithmInvocation
  my $alg_go = GUS::Model::Core::Algorithm
    ->new({ name        => 'GA-Plugin',
	    description => 'GUS application framework for plugins'
	  });
  $alg_go->retrieveFromDB;

  my $imp_go = GUS::Model::Core::AlgorithmImplementation
    ->new({ cvs_revision   => $M->getCVSRevision,
	    cvs_tag        => $M->getCVSTag,
	    executable     => $M->getName,
	    executable_md5 => $M->getCheckSum,
	    description    => $M->getRevisionNotes,
	  });
  $imp_go->setParent($alg_go);

  my $now = 'sysdate';
  my $inv_go = GUS::Model::Core::AlgorithmInvocation->new({ start_time  => $now,
							    end_time    => $now,
							    machine_id  => 0,
							    cpus_used   => 1,
							    result      => 'meta',
							  });
  $inv_go->setParent($imp_go);

  $M->set_defaults($alg_go);
  print $alg_go->toXML(2);
  $alg_go->submit;
  print $alg_go->toXML(2);

  # update with invocation's newly set id and resubmit
  $alg_go->setRowAlgInvocationId($inv_go->getId);
  $imp_go->setRowAlgInvocationId($inv_go->getId);
  $inv_go->setRowAlgInvocationId($inv_go->getId);

  $alg_go->setGlobalNoVersion(1);
  $alg_go->submit;

}


# ----------------------------------------------------------------------
# Run the plugin
# ----------------------------------------------------------------------

sub doMajorMode_Run {
  my $M = shift;
  my $C = shift;

  my $pu = $M->newFromPluginName($C);

  # get command line arguments from combined CBIL::Util::EasyCsp options structure
  my $ecd = {
	     %{$M->getGlobalEasyCspOptions},
	     %{$pu->getEasyCspOptions},
	    };
  my $cla = CBIL::Util::EasyCsp::DoItAll($ecd,$pu->getUsage) || die;
  $pu->initArgs($cla);
  $M->initArgs($cla);

  # what versions does the plugin want?
  $M->connect_to_database($M);

  $M->_check_schema_version_requirements($pu);

  # connect to the database
  $M->connect_to_database($pu);

  # get PI's version to find the AlgorithmImplementation.
  $M->findImplementation($pu);

  # the application context
  eval {
    $M->openInvocation($pu);
    my $resultDescrip;
    # include the args for legacy plugins
    $resultDescrip = $pu->run({ cla      => $pu->getCla,
				self_inv => $pu->getSelfInv,
			      });
    if ($resultDescrip) { $pu->setResultDescr($resultDescrip); }
    $M->logAlert("RESULT", $pu->getResultDescr());
  };

  # clean up.
  $M->closeInvocation($pu, $@);

  $M->disconnect_from_database($M);

  die "$@" if $@;
}

# ----------------------------------------------------------------------

#! GA
sub doMajorMode_Create {
  my $M = shift;
  my $C = shift;

  $M->create_or_update_implementation(0,$C)
}

# ----------------------------------------------------------------------

#! GA
sub doMajorMode_Update {
  my $M = shift;
  my $C = shift;

  $M->create_or_update_implementation(1,$C)
}

# ----------------------------------------------------------------------

#! GA
sub doMajorMode_History {
  my $M = shift;
  my $C = shift;

  my $p = $M->newFromPluginName($C);
  my $plugin_name_s = $p->getName;

  # command line arguments
  my $usg = "reports history of Core tables for plug-in $plugin_name_s";
  my %ecd = ((
	      map {($_->{o},$_)}
	      (
	      )
	     ),

	     # global options -- are they needed ?
	     %{$M->getGlobalEasyCspOptions}
	    );
  my $cla = CBIL::Util::EasyCsp::DoItAll(\%ecd,$usg) || exit 0;
  $M->initArgs($cla);

  # do preps
  $M->connect_to_database($M);

  my $q = $M->getQueryHandle;

  # what algorithm
  my $alg_sql = "select * from Core.Algorithm where name = '$plugin_name_s'";

  # what implementations
  my $imp_sql = <<SQL;
    select *
      from Core.AlgorithmImplementation
     where algorithm_id = ?
     order by algorithm_implementation_id
SQL

  # what parameters
  my $par_sql = <<SQL;
    select *
      from Core.AlgorithmParamKey     k
         , Core.AlgorithmParamKeyType t
     where k.algorithm_implementation_id = ?
       and k.algorithm_param_key_type_id = t.algorithm_param_key_type_id
     order by algorithm_param_key
SQL

  # how many invocations
  my $inv_n_sql = <<SQL;
    select count(algorithm_invocation_id)
      from Core.AlgorithmInvocation
     where algorithm_implementation_id = ?
SQL

  # what about invocations
  my $inv_sql = <<SQL;
    select *
      from Core.AlgorithmInvocation
     where algorithm_implementation_id = ?
SQL

  # what parameter values
  my $val_sql = <<SQL;
    select *
      from Core.AlgorithmParam    p
         , Core.AlgorithmParamKey k
     where p.algorithm_invocation_id = ?
       and p.algorithm_param_key_id  = k.algorithm_param_key_id
     order by k.algorithm_param_key, order_num
SQL

  # ......................................................................

  my $sh       = $q->prepareAndExecute($alg_sql);
  my $imp_sh   = $q->prepare($imp_sql);
  my $par_sh   = $q->prepare($par_sql);
  my $inv_n_sh = $q->prepare($inv_n_sql);
  my $inv_sh   = $q->prepare($inv_sql);
  my $val_sh   = $q->prepare($val_sql);

  my $algs_n = 0;
  while (my $alg_h = $sh->fetchrow_hashref) {

    # just to see if we got any.
    $algs_n++;

    # show columns for this algorithm
    $M->logData('ALG',
	    ( map { $alg_h->{$_} } qw(ALGORITHM_ID NAME DESCRIPTION) ),
	   );

    # get implementations
    $imp_sh->execute($alg_h->{ALGORITHM_ID});
    while (my $imp_h = $imp_sh->fetchrow_hashref) {

      # get count of invocations
      $inv_n_sh->execute($imp_h->{ALGORITHM_IMPLEMENTATION_ID});
      my ($inv_n) = $inv_n_sh->fetchrow_array;
      $inv_n_sh->finish;

      # show columns for this implementation
      $M->logData('IMP',
	      #$alg_h->{ALGORITHM_ID},
	      ( map {$imp_h->{$_}} qw(ALGORITHM_IMPLEMENTATION_ID CVS_REVISION, CVS_TAG)),
	      $inv_n,
	      ( map {$imp_h->{$_}} qw(EXECUTABLE EXECUTABLE_MD5 MODIFICATION_DATE DESCRIPTION)),
	     );

      # get parameter definitions
      $par_sh->execute($imp_h->{ALGORITHM_IMPLEMENTATION_ID});
      while (my $par_h = $par_sh->fetchrow_hashref) {
	$par_h->{IS_LIST_VALUED} = $par_h->{IS_LIST_VALUED} ? 'list  ' : 'scalar';
	$M->logData('PRMKEY',
		#$alg_h->{ALGORITHM_ID},
		#( map {$imp_h->{$_}} qw(ALGORITHM_IMPLEMENTATION_ID VERSION)),
		sprintf('%8.8s %s : %-24.24s %s',
			map {$par_h->{$_}}
			qw(TYPE IS_LIST_VALUED ALGORITHM_PARAM_KEY DESCRIPTION)
		       ),
	       );
      }
      $par_sh->finish;

      # details of invocations
      $inv_sh->execute($imp_h->{ALGORITHM_IMPLEMENTATION_ID});
      while (my $inv_h = $inv_sh->fetchrow_hashref) {
	$M->logData('INV',
		#$alg_h->{ALGORITHM_ID},
		#$imp_h->{ALGORITHM_IMPLEMENTATION_ID},
		( map {$inv_h->{$_}} qw(ALGORITHM_INVOCATION_ID START_TIME END_TIME RESULT COMMENT_STRING)),
	       );

				# values of parameters
	$val_sh->execute($inv_h->{ALGORITHM_INVOCATION_ID});
	while (my $val_h = $val_sh->fetchrow_hashref) {
	  $M->logData('PARVAL',
		  ( map {$val_h->{$_}} qw(ALGORITHM_PARAM_KEY ORDER_NUM STRING_VALUE))
		 );
	}
	$val_sh->finish;

      }
      $inv_sh->finish;

    }				# eo implementations 
    $imp_sh->finish;

  }				# eo  algorithms
  $sh->finish;

  # say something if we found no Algorithms
  if ($algs_n <= 0) {
    $M->logData('INFO', 'No Core.Algorithms were found for this plugin');
  }
}

# ----------------------------------------------------------------------
# SUPPORT methods
# ----------------------------------------------------------------------

#! GA
sub create_or_update_implementation {
  my $M = shift;
  my $U = shift;		# allow update?
  my $C = shift;		# plugin class name

  # verbs of various forms for what we are doing
  my $what = $U ? 'updates' : 'creates';
  my $What = ucfirst $what;

  # get any remaining arguments
  # ......................................................................

  my $usg = "$what GUS::Model::Core::Algorithm-related entries for a plugin.";
  my %ecd = (
	     %{$M->getGlobalEasyCspOptions},
	     ( map {($_->{o},$_)}
	       ( { h => "just survery what would be done",
		   t => 'boolean',
		   o => 'Survey',
		 },
	       ) )
	    );
  CBIL::Util::Disp::Display(\%ecd) if FLAG_DEBUG;
  my $cla = CBIL::Util::EasyCsp::DoItAll(\%ecd,$usg) || die;
  $M->initArgs($cla);

  # do preps
  $M->connect_to_database($M);
  $M->findImplementation($M);

  # create plugin
  my $pu = $M->newFromPluginName($C);
  $pu->initArgs($cla);

  # what versions does the plugin want?
  $M->_check_schema_version_requirements($pu);

  # make an algorithminvocation for self
  # ......................................................................

  my $alg_inv_gus = GUS::Model::Core::AlgorithmInvocation
    ->new({ algorithm_implementation_id => $M->getImplementation->getId,
	    start_time                  => $M->getDb->getDateFunction(),
	    end_time                    => $M->getDb->getDateFunction(),
	    machine_id                  => 0,
	    cpus_used                   => 1,
	    cpu_time                    => 0,
	    result                      => 'pending',
	    comment_string              => substr($cla->{comment},0,255),
	  });
  $M->initAlgInvocation($alg_inv_gus);
  $M->set_defaults($alg_inv_gus);

  # things we might need.
  # ......................................................................

  # terse access to plugin name since we use it all the time
  my $plugin_name_s = $pu->getName;

  # check to see if Algorithm with this name already exists.
  # ......................................................................

  my $alg_h;
  $M->findAlgorithm($pu);
  my $alg_gus = $pu->getAlgorithm;
  my $cvsRevision = $pu->getCVSRevision;
  my $cvsTag = $pu->getCVSTag;

  # we want to create a new Algorithm
  if ($U ) {

    my $sql =
      "SELECT *
       FROM Core.AlgorithmImplementation
       WHERE executable = '$plugin_name_s'
       AND cvs_revision    = '$cvsRevision'";

    my $imps = $M->sql_get_as_hash_refs($sql);

    if (scalar(@$imps) !=0) {
      print STDERR "Error:   $plugin_name_s with CVS revision $cvsRevision is already registered.  You don't need to do a +update.\n";
      exit 0;
    }
  } else {

    # algorithm already exists; tell user about it.
    if ($alg_gus) {
      print STDERR join("\n",
			"$plugin_name_s is already registered.",
			"Use '+update' if you need to register a new version."
		       ), "\n";
#      $M->doMajorMode_History($C);
      exit 0;
    }

    # gather the attributes we need and make sure everything checks out first 
    else {

      my $description = $pu->getUsage;
      if (not defined $description) {
	print STDERR "You have not overridden the getUsage method in your plugin.\n";
	exit 0;
      }

      $alg_h = { name        => $plugin_name_s,
		 description => $description,
	       };
    }
  }

  # implementation data
  # ......................................................................,


  my $imp_description = $pu->getRevisionNotes;

  use Sys::Hostname;
  my $host = hostname();

  # AlgorithmParamKeys
  my $apkt_cache = $M->load_AlgorithmParamKeyType_cache;
  CBIL::Util::Disp::Display($apkt_cache, '$apkt_cache') if FLAG_DEBUG;
  my $pu_ecd     = {
		    %{$M->getGlobalEasyCspOptions},
		    %{$pu->getEasyCspOptions},
		   };

  CBIL::Util::Disp::Display($pu_ecd, '$pu_ecd') if FLAG_DEBUG;
  my @bad_types;
  foreach my $ecd (values %$pu_ecd) {
    my $apkt_id = $apkt_cache->{lc(substr($ecd->{t},0,3))};
    if (defined $apkt_id) {
      $ecd->{APKT_ID} = $apkt_id;
    } else {
      push(@bad_types, $ecd);
    }
  }
  if (scalar @bad_types) {
    foreach my $ecd (@bad_types) {
      print STDERR "'$ecd->{t}' is not a legal param type for option $ecd->{o}.\n";
    }
    exit 0;
  }

  # start making objects
  # ......................................................................

  my $alg_imp_h = { cvs_revision        => $cvsRevision,
		    cvs_tag             => $cvsTag,
		    description         => $imp_description,
		    executable          => $pu->getName,
		    executable_md5      => $pu->getCheckSum,
		  };
  my @apks = map { {
    algorithm_param_key         => $_->{o},
      algorithm_param_key_type_id => $_->{APKT_ID},
	is_list_valued              => $_->{l} || 0,
	  description                 => $_->{h},
	}
		 } values %$pu_ecd;

  if ($cla->{Survey}) {
    CBIL::Util::Disp::Display($alg_h,     '$alg_h: ');
    CBIL::Util::Disp::Display($alg_imp_h, '$alg_imp_h: ');
    CBIL::Util::Disp::Display(\@apks,     '\@apks: ');
  } else {
    $alg_gus = GUS::Model::Core::Algorithm->new($alg_h) if $alg_h;
    my $alg_imp_gus = GUS::Model::Core::AlgorithmImplementation->new($alg_imp_h);
    $alg_imp_gus->setParent($alg_gus);
    foreach my $apk (sort {
      lc $a->{algorithm_param_key} cmp lc $b->{algorithm_param_key}
    } @apks) {
      my $apk_gus = GUS::Model::Core::AlgorithmParamKey->new($apk);
      $apk_gus->setParent($alg_imp_gus);
    }
    $alg_gus->submit;
    $M->logData('INFO', "Plugin $plugin_name_s registered with cvs revision '$cvsRevision' and cvs tag '$cvsTag'");
    $M->logData('INFO', "...Just kidding: you didn't --commit")
      unless ($M->getArgs->{commit});
  }
}


# ----------------------------------------------------------------------

sub set_defaults {
  my $M = shift;
  my $O = shift;

  my $cla = $M->getArgs;

  CBIL::Util::Disp::Display($cla, 'cla:'.  ref$M) if FLAG_DEBUG;

  # global parameters
  $O->setCommitOff()     unless $cla->{commit};
  $O->setDebuggingOn()   if $cla->{debug};

  # default values for GUS overhead columns
  $O->setDefaultAlgoInvoId( $cla->{algoinvo} );
  $O->setDefaultUserId(     $M->sql_translate('Core.UserInfo',
					      'user_id',
					      'login',$M->getUser()));
  $O->setDefaultGroupId(    $M->sql_translate('Core.GroupInfo',
					      'group_id',
					      'name',$M->getGroup()));
  $O->setDefaultProjectId(  $M->sql_translate('Core.ProjectInfo',
					      'project_id',
					      'name',$M->getProject()));

}

# ----------------------------------------------------------------------

sub getUser {
  my $M = shift;

  my $cla = $M->getArgs;
  $cla->{user}? $cla->{user} : $M->getConfig()->getUserName();

}

sub getGroup {
  my $M = shift;

  my $cla = $M->getArgs;
  $cla->{group}? $cla->{group} : $M->getConfig()->getGroup();

}

sub getProject {
  my $M = shift;

  my $cla = $M->getArgs;
  $cla->{project}? $cla->{project} : $M->getConfig()->getProject();

}

#! GA
sub load_AlgorithmParamKeyType_cache {
  my $M = shift;

  my $RV;

  # if we don't have a db handle use these that I copied from the DB.
  if (not defined $M->getQueryHandle) {
    $RV = { 'str' => 0,
	    'flo' => 1,
	    'int' => 2,
	    'ref' => 3,
	    'boo' => 4,
	    'dat' => 5,
	  };
  }

  # we have a db query handle, go for it.
  else {
    my $sql = 'select algorithm_param_key_type_id, type from Core.AlgorithmParamKeyType';
    my $types = $M->sql_get_as_array_refs($sql);
    foreach (@$types) {
      $RV->{lc(substr($_->[1],0,3))} = $_->[0];
    }
  }

  # RETURN
  $RV
}

# ----------------------------------------------------------------------
# Opens invocation structure.

# SOON: when alg inv. gets new 'status' attribute, this will set it to 'running'
sub openInvocation {
  my $M = shift;
  my $P = shift;		# the plugin

  my $cla = $P->getArgs;

  # get implementation pointer for self.
  # ........................................

  my $alg_inv_gus = GUS::Model::Core::AlgorithmInvocation
    ->new({
	   algorithm_implementation_id => $P->getImplementation->getId,
	   start_time                  => $P->getDb->getDateFunction(),
	   end_time                    => $P->getDb->getDateFunction(),
	   machine_id                  => 0,
	   cpus_used                   => 1,
	   cpu_time                    => 0,
	   result                      => 'pending',
	   comment_string              => substr($cla->{comment},0,255),
	  });
  $P->initAlgInvocation($alg_inv_gus);

  # global parameters
  $alg_inv_gus->setCommitOff()     unless $cla->{commit};
  $alg_inv_gus->setDebuggingOn()   if $cla->{debug};

  # default values for GUS overhead columns
  $alg_inv_gus->setDefaultAlgoInvoId($cla->{algoinvo});
  $alg_inv_gus->setDefaultUserId(  $P->sql_translate('Core.UserInfo',
						     'user_id',
						     'login',$M->getUser()));
  $alg_inv_gus->setDefaultGroupId( $P->sql_translate('Core.GroupInfo',
						     'group_id',
						     'name',$M->getGroup()));
  $alg_inv_gus->setDefaultProjectId($P->sql_translate('Core.ProjectInfo',
						      'project_id',
						      'name',$M->getProject()));
  $alg_inv_gus->submit();
  $alg_inv_gus->setDefaultAlgoInvoId($alg_inv_gus->getId);

  # set parameter values in the DB.
  # ......................................................................

  # get children, then make a hash of algorithm_param_key => object
  my @param_keys = 
    $P->getImplementation->getChildren('GUS::Model::Core::AlgorithmParamKey',1);
  my %key_to_obj = map { ($_->getAlgorithmParamKey,$_) } @param_keys;

  # note whether we had any problems.
  my @any_bad;

  # process each actual parameter
  #CBIL::Util::Disp::Display($cla, '$cla');
  #CBIL::Util::Disp::Display([sort keys %key_to_obj], '[sort keys %key_to_obj');

  foreach my $param_name (sort keys %$cla) {

    # skip CBIL::Util::EasyCsp options which we do not record.
    next if$param_name =~ /(debug|verbose|veryVerbose|usage)/;

    # get the Core.AlgorithmParamKey object
    my $apk_go      = $key_to_obj{$param_name};

    # this param is expected
    if (defined $apk_go) {

      # find out what type this param is
      my $apkt_go         = $apk_go->getParent('GUS::Model::Core::AlgorithmParamKeyType',1);
      if ($apkt_go) {

	my $type            = $apkt_go->getType;

	# get a list of its values (list or not originally)
	my $typed_value_key = $type.'_value';
	my $param_value     = $cla->{$param_name};
	my @values = ref $param_value ? @$param_value : ($param_value);

	# process each value for param in (posible) list.  Note that we
	# store value in string_value as well as its native type.
	for (my $v_i = 0; $v_i < @values; $v_i++) {
	  my $ap_h = { algorithm_param_key_id  => $apk_go->getId,
		       string_value            => $values[$v_i],
		       $typed_value_key        => $values[$v_i],
		       order_num               => $v_i,
		       algorithm_invocation_id => $P->getAlgInvocation->getId,
		       is_default              => 0,
		     };
	  my $ap_go = GUS::Model::Core::AlgorithmParam->new($ap_h);
	  $ap_go->submit;
	}
      } else {
	$P->error("A Core.AlgorithmParamKeyType was not found for this param $param_name");
      }
    }

    # an unexpected parameter, let the user know.
    else {
	$P->error("A Core.AlgorithmParamKey was not found for this param $param_name");
      }
  }
}

# ----------------------------------------------------------------------

# SOON: when alg inv. gets new 'status' attribute, this will set it to 
# 'succeeded' or 'failed' based on $failmsg;
sub closeInvocation {
  my $M = shift;
  my $P = shift;
  my $failmsg;

  $P->setResultDescr($failmsg) if $failmsg;  # until we add an errmsg attribute

  $P->getAlgInvocation->setGlobalNoVersion(1);
  $P->getAlgInvocation->setResult($P->getResultDescr);
  $P->getAlgInvocation->setEndTime($P->getAlgInvocation->getDatabase()->getDateFunction());
  $P->getAlgInvocation->submit(1);

  ##logout
  $M->disconnect_from_database($P);

  return undef;
}

# ----------------------------------------------------------------------
# Sets up a standard minimal connect to the database.  Initializes the
# db and dbh attributes.

sub connect_to_database {
  my $M = shift;
  my $P = shift;		# active plugins

  my $config = $M->getConfig();

  my $login    = $M->getConfig->getDatabaseLogin();
  my $password = $M->getConfig->getDatabasePassword();
  my $core     = $M->getConfig->getCoreSchemaName();
  my $dbiDsn   = $M->getConfig->getDbiDsn();

  $P->initDb(new GUS::ObjRelP::DbiDatabase($dbiDsn,
					   $login,$password,
					   $P->getArgs->{verbose},0,1,
					   $core));

  # return self.
  $M
}

sub disconnect_from_database {
  my $M = shift;
  my $P = shift;

  $P->getDb()->logout()
}


# ----------------------------------------------------------------------
# Private functions
# ----------------------------------------------------------------------

sub _check_schema_version_requirements {
  my $M = shift;
  my $P = shift;		# the plugin

  my $ver_h = $P->getRequiredDbVersion;
  my $sql = "select count(database_id) from Core.DatabaseInfo where name = ? and version = ?";
  my $sh  = $M->getQueryHandle->prepare($sql);

  my @bad_ones;

  foreach my $schema (sort keys %$ver_h) {
    $sh->execute($schema, $ver_h->{$schema});
    my ($count_n) = $sh->fetchrow_array;
    $sh->finish;
    if ($count_n < 1) {
      push(@bad_ones, $schema);
    }
  }

  # let the user know what went wrong.
  if (scalar @bad_ones) {
    my $errMsg = 'Actual version does not match required version for these schemas:' . join (" ", @bad_ones) . "\n";

    # report actual and requested versions
    my $vers = $M->sql_get_as_hash_refs('select name, version, from Core.DatabaseInfo order by name');
    $errMsg .= "\t#NAME\t#DB-VER\t#RQ-VER\n";
    foreach my $schema (@$vers) {
      $errMsg .= "\t$schema->{NAME}\t$schema->{VERSION}\t$ver_h->{$schema->{NAME}}\n";
    }
    $M->error($errMsg);
  }
}

sub getGlobalEasyCspOptions {
  my $M = shift;

  my $RV =
    {
     map {($_->{o},$_)}
     (
      { h => 'actually commit changes to database',
	t => 'boolean',
	o => 'commit',
      },

      { h => 'set the user name in new or changed rows with this GUS user name (from Core.UserInfo table) [default is value in gus config file]',
	t => 'string',
	o => 'user',
      },

      { h => 'set the group name in new or changed rows with this GUS group name (from Core.GroupInfo table) [default is value in gus config file]',
	t => 'string',
	o => 'group',
      },

      { h => 'set the project name in new or changed rows with this GUS project name (from Core.Project table) [default is value in gus config file]',
	t => 'string',
	o => 'project',
      },

      { h => 'use this algorithm invocation id in the event that a new algorithm invocation id cannot be generated automatically',
	t => 'integer',
	d => 1,
	o => 'algoinvo',
      },

      { h => 'set Core.AlgorithmInvocation.comment with this comment',
	t => 'string',
	o => 'comment',
      },

      { h => 'the gus config file to use [default is $GUS_CONFIG_FILE]',
	t => 'string',
	o => 'gusconfigfile',
	d => "$ENV{GUS_CONFIG_FILE}"
      },
     )
    };

  # RETURN
  return $RV
}

1;



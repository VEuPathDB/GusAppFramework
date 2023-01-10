
package GUS::Community::Plugin::LoadEnzymeDatabase;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;

use CBIL::Util::Disp;

use GUS::Model::SRes::EnzymeClass;
use GUS::Model::SRes::EnzymeClassAttribute;
use GUS::Model::SRes::ExternalDatabase;
use GUS::Model::SRes::DbRef;

use GUS::Model::DoTS::AASequenceEnzymeClass;

use CBIL::Bio::Enzyme::Parser;

use GUS::PluginMgr::Plugin;
use GUS::PluginMgr::PluginUtilities;
use GUS::PluginMgr::PluginUtilities::ConstraintFunction;

use Data::Dumper;

$| = 1;

# ----------------------------------------------------------------------
sub getArgumentsDeclaration {

  my $argsDeclaration =
    [ booleanArg({ name   => 'Survey',
		   descr  => 'just survey what is to be done',
		   reqd   => 0,
		   isList => 0,
		   constraintFunc => sub { CfIsAnything(@_); },
		 }),
      booleanArg({ name   => 'Update',
		   descr  => 'add some entries without creating new database',
		   reqd   => 0,
		   isList => 0,
		   constraintFunc => sub { CfIsAnything(@_); },
		 }),
      stringArg ({ name    => 'InPath',
		   descr   => 'find data files here',
		   reqd    => 0,
		   default => '.',
		   isList  => 0,
		   constraintFunc => sub { CfIsDirectory(@_); },
		 }),
      stringArg ({ name    => 'enzymeDbName',
		   descr   => 'name in sres.externaldatabase.name for EnzymeDB',
		   reqd    => 1,
		   isList  => 0,
		   constraintFunc => sub { CfIsAnything(@_); },
		 }),
      stringArg ({ name    => 'enzymeDbRlsVer',
		   descr   => 'version in sres.externaldatabaserelease.version for EnzymeDB',
		   reqd    => 1,
		   isList  => 0,
		   constraintFunc => sub { CfIsAnything(@_); },
		 }),
      stringArg ({ name    => 'SwissProt',
		   descr   => 'name,version of SwissProt database',
		   reqd    => 0,
		   isList  => 1,
		   constraintFunc => sub { CfIsAnything(@_); },
		 }),
      stringArg ({ name    => 'Prosite',
		   descr   => 'name,version of Prosite database',
		   reqd    => 0,
		   isList  => 1,
		   constraintFunc => sub { CfIsAnything(@_); },
		 }),
      stringArg ({ name    => 'Omim',
		   descr   => 'name,version of Omim database',
		   reqd    => 0,
		   isList  => 1,
		   constraintFunc => sub { CfIsAnything(@_); },
		 }),
      integerArg({ name    => 'EntriesN',
		   descr   => 'process at most this many entries',
		   reqd    => 0,
		   default => 1_000_000_000,
		   isList  => 0,
		   constraintFunc => sub { CfIsPositive(@_); },
		 })
    ];

return $argsDeclaration;

}

sub getDocumentation {

  my $purposeBrief = <<PURPOSEBRIEF;
loads data from Enzyme database
PURPOSEBRIEF

  my $purpose = <<PLUGIN_PURPOSE;
loads data from Enzyme database
PLUGIN_PURPOSE

  my $tablesAffected = [['GUS::Model::SRes::Taxon', 'A single row is added'],['GUS::Model::SRes::TaxonName', 'A single row is added']];

  my $tablesDependedOn = [['GUS::Model::SRes::Taxon', 'If parent is invoked, parent taxon_id must exist']];

  my $howToRestart = <<PLUGIN_RESTART;
No explicit restart procedure.
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
unknown
PLUGIN_FAILURE_CASES

  my $notes = <<PLUGIN_NOTES;
A flat file release of the EC database is available at
http://www.expasy.org/enzyme/.  Use the 'Downloading ENZYME by FTP'
link which links to http://tw.expasy.org/ftp/databases/enzyme.  You
need to download only enzclass.txt and enzyme.dat.  They should be
placed together in a directory.  Point the plugin to this directory
using the --InPath option.

We have observed that some of the parent nodes in the EC database are
missing.  For example, if there is an EC entry 1.2.3.4, there should
be a parent 1.2.3.-.  When a parent is missing, the plugin will create
them as needed.

The EC database has various class attributes that GUS does not
structure, but does enter into the SRes.EnzymeClassAttribute table.
These are:
Alternate Name (AN lines),
Catalytic Activity (CA lines),
Comment (CC lines),
Cofactor (CF lines),
Database Reference (DR lines).

This plugin also attempts to make links to DoTS.ExternalAASequences
that are refered to in the EC release.  This is done via a
DoTS.AASequenceEnzymeClass row.

Several of the options of this plugin are specifications of a row in
SRes.ExternalDatabaseRelease.  While this could be done using the
external_database_release_id, we have tried to be a little more symbolic
and use a comma-delimited list of the
SRes.ExternalDatabase.name and
SRes.ExternalDatabaseRelease.version, e.g., 'swissprot,5.4'.

The --Enzyme option must be used to set the
SRes.ExternalDatabaseRelease for the SRes.EnzymeClass entries.Make
sure you have entries for your release of Enzyme in
SRes.ExternalDatabase and SRes.ExternalDatabaseRelease.

The ideal: The --Prosite, --SwissProt, and --Omim options let the user
indicate which SRes.ExternalDatabaseRelease to link PROSITE,
SWISSPROT, and OMIM references to.

The actual: At the moment the --Omim flag is not used and all OMIM
references are stored in SRes.EnzymeClassAttribute.

Warnings will be issued for missing Prosite, SwissProt and Omim
specifications, but they can be ignored.  Only the Enzyme link is
required.
PLUGIN_NOTES

  my $documentation = {purposeBrief => $purposeBrief,
		     purpose => $purpose,
		     tablesAffected => $tablesAffected,
		     tablesDependedOn => $tablesDependedOn,
		     howToRestart => $howToRestart,
		     failureCases => $failureCases,
		     notes => $notes
		    };

  return $documentation;
}


sub new {
   my ($class) = @_;

   my $self = {};

   bless ($self,$class);

   my $documentation = &getDocumentation();
   my $argsDeclaration = &getArgumentsDeclaration();

   $self->initialize({requiredDbVersion => 4.0,
		      cvsRevision => '$Revision$', # cvs fills this in!
		      name => ref($self),
		      argsDeclaration   => $argsDeclaration,
		      documentation     => $documentation
		     });

  return $self;
}

sub run {
   my ($self) = @_;

   $self->logAlgInvocationId();
   $self->logCommit();
   $self->logArgs();

   # RETURN
   my $RV = 'programmar did not set a message';

   # find external database objects;
   my $db_cache = $self->_getExtDbRelCache();
   return $@ if $@;

   # parse the input file.
   my $ezp = CBIL::Bio::Enzyme::Parser
   ->new({ InPath => $self->getArg('InPath'),
         });
   $ezp->assemble;
   return $@ if $@;

   # make sure we can hold everything.
   $self->setPointerCacheSize(500_000);

   if ($self->getArg('Update')) {
      my $enzymes = $ezp->getFileCache('enzymes')->getEntries();
      CBIL::Util::Disp::Display($enzymes);
   } else {

      # get the parsed entries as a list of objects
      my $all_gus = {};
      my $all_ec  = { %{$ezp->getFileCache('classes')->getEntries},
                      %{$ezp->getFileCache('enzymes')->getEntries},
                    };

      my $things_n = 0;
      foreach my $thing (values %$all_ec) {
         $self->_process($db_cache->{ENZYME},
                         $all_ec,$all_gus,$thing
                        );
         last if ++$things_n >= $self->getArg('EntriesN');
      }

      # display tree of ECs
      if ($self->getArg('Survey')) {
         my $root_g = $all_gus->{'-.-.-.-'};
         print $root_g->toXML;
      } else {
         $db_cache->{ENZYME}->submit();
         $all_gus->{'-.-.-.-'}->submit();
      }
   }

   return $self->_return_message;
}

# ----------------------------------------------------------------------

sub _incEnzymeClass { $_[0]->{_enzyme_class_n}++; $_[0] }
sub _getEnzymeClass { $_[0]->{_enzyme_class_n}++ }

sub _getProcessCount         { $_[0]->{ __PACKAGE__ . 'ProcessCount' }++ }

sub _incEnzymeClassAttribute { $_[0]->{_enzyme_class_attribute_n}++; $_[0] }
sub _getEnzymeClassAttribute { $_[0]->{_enzyme_class_attribute_n}++ }

sub _incAASequenceEnzymeClass { $_[0]->{_aa_sequence_enzyme_class_n}++; $_[0] }
sub _getAASequenceEnzymeClass { $_[0]->{_aa_sequence_enzyme_class_n}++ }

sub _setDbCache     { $_[0]->{_db_cache} = $_[1]; $_[0] }
sub _getDbCache     { $_[0]->{_db_cache} }

# ----------------------------------------------------------------------

sub _getExtDbRelCache {
  my ($self) = @_;
  my $RV;

  # cheat:  transform standard args into non-standard for legacy code compatibility
  $self->getArgs()->{'Enzyme'} = [$self->getArg('enzymeDbName'),$self->getArg('enzymeDbRlsVer')];

  my $ok = 1;
  foreach my $db ( qw( Enzyme SwissProt Prosite Omim ) ) {

    #my @arg =$self->getArg($db);

    next if (! $self->getArg($db));

    my $db_lcn = $self->getArg($db)->[0];
    my $db_ver = $self->getArg($db)->[1];

    #my $db_lcn = $arg[0];
    #my $db_ver = $arg[1];

    if ($db_lcn && $db_ver) {
      $self->userError("missing db name or db rls version in comma delimited list for $db") if (length ($db_lcn)==0 || length ($db_ver)==0);

      my $_xdb = GUS::Model::SRes::ExternalDatabase->new
	({ name => $db_lcn });
      if ($_xdb->retrieveFromDB()) {

	my @allXdbrs = $_xdb->getChildren('SRes::ExternalDatabaseRelease',1);
	my $the_xdbr;
	foreach my $_xdbr (@allXdbrs) {
	  if ($_xdbr->getVersion() eq $db_ver) {
	    $the_xdbr = $_xdbr;
	    last;
	  }
	}

	if ($the_xdbr) {
	  $RV->{uc $db} = $the_xdbr;
	} else {
	  $self->log('WARN',
		     sprintf("Could not locate release '%s' for database '%s' for %s",
			     $db_ver, $db_lcn, $db
			    )
		    );
	  $ok = 0 if $db eq 'Enzyme';
	}

      }
      else {
	$self->log('WARN',
		   sprintf("Could not locate database '%s' for %s",
			   $db_lcn, $db
			  )
		  );
	$ok = 0 if $db eq 'Enzyme';
      }
    }

    elsif ($db eq 'Enzyme') {
      $self->userError("Must specify database name and release version for Enzyme");
    }
  }


  if ($ok) {
    $self->_setDbCache($RV)->_getDbCache();
  } 
  else {
    die 'Could not locate all ExternalDatabaseReleases';
  }
}

# ----------------------------------------------------------------------

sub _process {
   my ($self,$ExDbRl,$EnzCache,$GusCache,$EnzymeClass) = @_;

   # make a EnzymeClass with most columns set
   # ......................................................................

   my $ec         = $EnzymeClass->getNumber;
   my $ec_key     = $ec->toString;

   return if $GusCache->{$ec_key};

#   $self->log('INFO', '_process',  $self->_getProcessCount(), $EnzymeClass->getDescription() );  # creates a huge log

   my $ez_class_h = { depth       => $ec->getDepth,
                      ec_number   => $ec->toString,
                      description => $EnzymeClass->getDescription,
                    };
   my $depth = $ec->getDepth;

   # if this is a preliminary enzyme in the format 4.2.3.n10, don't load the 4th part
   if ($depth == 4 && $ec_key =~ /n\d+$/) {
        for (my $i = 1; $i <= 3; $i++) {
            $ez_class_h->{"ec_number_$i"} = $ec->getList->[$i-1];
        }
    }
    else {
        for (my $i = 1; $i <= $depth; $i++) {
            $ez_class_h->{"ec_number_$i"} = $ec->getList->[$i-1];
        }
    }

   my $ez_class_g = GUS::Model::SRes::EnzymeClass->new($ez_class_h);

   # reset description for root
   if ($ec_key eq '-.-.-.-') {
       $ez_class_g->setDescription('Unknown enzyme');
   }

   $self->_incEnzymeClass;

   # process attribues
   $self->_process_attributes($ez_class_g, $EnzymeClass);

   # process DB refs
   $self->_process_dbrefs($ez_class_g, $EnzymeClass);

   # store GUS object in cache.
   $GusCache->{$ec->toString} = $ez_class_g;

   # add to ExternalDatabaseRelease
   $ez_class_g->setParent($ExDbRl);

   # parent : if exists then connect, otherwise make the connect
   # ......................................................................

 ADD_PARENT: {
      if ($ec->getDepth >= 1) {

         # make sure we will find a parent if one is expected.
         my $parent_ec = $EnzymeClass->getParent;
         if ($ec->getDepth > 1 && not $parent_ec) {
            print join("\t", ref $self,
                       'no parent',
                       $ec->getDepth, $ec->toString
                      ), "\n";
            last ADD_PARENT;
         }

         # ec string for parent
         my $parent_id = $ec->getDepth == 1 ? '-.-.-.-' : $EnzymeClass->getParent->getId;

         # cached GUS object for parent
         my $parent_gus = $GusCache->{$parent_id};

         # not yet made, make it
         unless ($parent_gus) {
            $self->_process($ExDbRl,$EnzCache,$GusCache,$EnzCache->{$parent_id});
            $parent_gus = $GusCache->{$parent_id};
         }

         if ($parent_gus) {
            $parent_gus->addChild($ez_class_g);
            #$ez_class_g->setParent($parent_gus);
         } else {
            print join("\t", ref $self,
                       'Could not make GUS parent',
                       $ec->toString
                      ), "\n";
         }
      }
   }


   #  if ($self->getArg('Survey')) {
   #    print '-' x 70, "\n";
   #    print $ez_class_g->toXML;
   #  }
}

# ----------------------------------------------------------------------

sub _process_attributes {
   my ($self,$GusZyme,$EnzymeClass) = @_;

   # does not apply to ::Classes
   return unless ref $EnzymeClass eq 'CBIL::Bio::Enzyme::Enzyme';

   # make EnzymeClassAttributes to cover the other stuff.
   # ........................................

   my @ez_atts_h;

   foreach (@{$EnzymeClass->getAlternateNames||[]}) {
      push(@ez_atts_h,
           { attribute_name  => 'AlternateName',
             attribute_value => $_,
           });
   }

   foreach (@{$EnzymeClass->getCatalyticActivities||[]}) {
      push(@ez_atts_h,
           { attribute_name  => 'CatalyticActivity',
             attribute_value => $_->toString,
           });
   }

   foreach (@{$EnzymeClass->getCofactors||[]}) {
      push(@ez_atts_h,
           { attribute_name  => 'Cofactor',
             attribute_value => $_,
           });
   }

   foreach (@{$EnzymeClass->getComments||[]}) {
      push(@ez_atts_h,
           { attribute_name  => 'Comment',
             attribute_value => $_,
           });
   }

   foreach my $ez_att_h (@ez_atts_h) {
      my $ez_att_g = GUS::Model::SRes::EnzymeClassAttribute->new($ez_att_h);
      $ez_att_g->setParent($GusZyme);
      $self->_incEnzymeClassAttribute;
      #print $ez_att_g->toXML if $self->getArg('Survey');
   }
}


# ----------------------------------------------------------------------

sub _process_dbrefs {
   my ($self,$GusZyme,$EnzymeClass) = @_;

   return unless ref $EnzymeClass eq 'CBIL::Bio::Enzyme::Enzyme';

   foreach my $dbref (@{$EnzymeClass->getDbRefs||[]}) {

      # string : database name
      my $db_c = $dbref->getDatabase;

			my $save_as_attribute = 1;

      # ExternalDatabase : by name
      if (my $db_g = $self->_getDbCache->{$db_c}) {

         # sequence things
         if ($db_c eq 'PROSITE' || $db_c eq 'SWISSPROT' ) {
            #print '-' x 40, $GusZyme->getEcNumber, "\n";
            #$self->{C}->{self_inv}->setDebuggingOn;
            $db_g->removeChildrenInClass('DoTS::ExternalAASequence');
            $db_g->retrieveChildrenFromDB('DoTS::ExternalAASequence',
                                          0,
                                          { source_id => $dbref->getPrimaryId },
                                         );
            my @eas_g = $db_g->getChildren('DoTS::ExternalAASequence');
            #$self->{C}->{self_inv}->setDebuggingOff;

            # we got some sequences to annotate, make the links
            if (scalar @eas_g) {
               foreach my $eas_g (@eas_g) {
                  my $asec_h = { evidence_code     => 'TAS',
                                 review_status_id  => 0, # not reviewed.
                                 aa_sequence_id    => $eas_g->getId,
                               };
                  my $asec_g = GUS::Model::DoTS::AASequenceEnzymeClass->new($asec_h);
                  $self->_incAASequenceEnzymeClass;
                  $asec_g->setParent($GusZyme);
               }
               $save_as_attribute = 0;
            }
         }
			} # eo able to find a db object

			if ($save_as_attribute) {
				 my $eca_h = { attribute_name  => 'DatabaseReference',
											 attribute_value => sprintf('%s:%s:%s',
																									$dbref->getDatabase,
																									$dbref->getPrimaryId,
																									$dbref->getSecondaryId,
																								 ),
										 };
				 my $eca_g = GUS::Model::SRes::EnzymeClassAttribute->new($eca_h);
				 $self->_incEnzymeClassAttribute;
				 $eca_g->setParent($GusZyme);
			}
   } # eo dbref list
}

# ----------------------------------------------------------------------

sub _return_message {
   my ($self) = @_;

   return sprintf(join(', ',
                       '%s %d EnzymeClass entries',
                       '%d EnzymeClassAttribute entries',
                       '%d AASequenceEnzymeClass entries',
                      ),
		  $self->getArg('Survey') ? 'Pretended to make' : 'Made',
                  $self->_getEnzymeClass,
                  $self->_getEnzymeClassAttribute,
                  $self->_getAASequenceEnzymeClass,
                 );
}

# ----------------------------------------------------------------------


sub undoTables {
   qw(
      DoTS.AASequenceEnzymeClass
      SRes.EnzymeClassAttribute
      SRes.EnzymeClass
      SRes.ExternalDatabaseRelease
      SRes.ExternalDatabase
   );
}


1;

__END__

The enzyme data structure (rendered in C) is about as follows:

typedef struct {

   /* lefthand side terms */
   char ** lhs;

   /* righthand side terms */
   char ** rhs;

   /* description, used as an alternative */
   char *  description;

} Reaction;

typedef struct {

   /* database name */
   char     *  database;

   /* primary id */
   char     *  primary_id;

   /* secondary id */
   char     *  secondary_id;

} DbRef;

typedef struct {

   /* the EC number */
   int         ec_number[4];

   /* canonical description */
   char     *  designation;

   /* alternate descriptions */
   char     ** alternate_names;

   /* unstructured comments */
   char     ** comments;

   /* names of cofactors involved in catalysis */
   char     ** cofactor_names;

   /* descriptions of reactions catalyzed */
   Reaction *  activities;

   /* disease (OMIM), protein (SWISSPROT), domains (PROSITE)
  DbRef    *  db_refs;

} Enzyme;

typedef struct {

  /* the actual depth of the class, a number from 1 to 3.
  int         depth;

   /* the EC number */
   int         ec_number[4];

   /* a description */
   char     *  designation;

} Class;


The fixed attributes of Enzyme and Class can be collapsed into a
single EnzymeClassification table which contains the union of the
attributes from the two tables.

Additional EnzymeClassification attributes can be put into tables
EnzymeClassificationCofactors, EnzymeClassificationActivities,
EnzymeClassificationAlternateNames, and EnzymeClassificationComments.

The table for Cofactors, AlternateNames and Comments can be simple
link, ordinal, text table.  Activities could be done this way as well,
though it loses possible parsing of the reaction.

We can put DbRefs in GUSdev::DbRefs.

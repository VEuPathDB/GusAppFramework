
package GUS::Common::Plugin::LoadEnzymeDatabase;

@ISA = qw(GUS::PluginMgr::Plugin);

# ----------------------------------------------------------------------

use strict;

use CBIL::Util::Disp;

use GUS::Model::SRes::EnzymeClass;
use GUS::Model::SRes::EnzymeClassAttribute;
use GUS::Model::SRes::ExternalDatabase;
use GUS::Model::SRes::DbRef;

use GUS::Model::DoTS::AASequenceEnzymeClass;

use CBIL::Bio::Enzyme::Parser;

# ----------------------------------------------------------------------

sub new {
   my $Class = shift;

   my $self = bless {}, $Class;

   $self->initialize
   ({ requiredDbVersion => {},
      cvsRevision       => '$Revision$',
      cvsTag            => '$Name$',
      name              => ref($self),

      # just expand these
      revisionNotes     => '',
      revisionNotes     => 'initial conversion to GUS3.0',

      # user info
      usage             => 'loads data from Enzyme database',
      easyCspOptions    =>
      [ { h => 'just survey what is to be done',
          t => 'boolean',
          o => 'Survey',
        },

        { h => 'add some entries without creating new database',
          t => 'boolean',
          o => 'Update',
        },

        { h => 'find data files here',
          t => 'string',
          o => 'InPath',
        },

        # finding referenced databases
        { h => '',
          t => 'string',
          d => '',
          l => 1,
          o => 'Enzyme',
        },

        { h => 'lowercase_name and version for Prosite',
          t => 'string',
          d => '',
          l => 1,
          o => 'Prosite',
        },

        { h => 'lowercase_name and version for SwissProt',
          t => 'string',
          d => '',
          l => 1,
          o => 'SwissProt',
        },

        { h => 'lowercase_name and version for OMIM',
          t => 'string',
          d => '',
          l => 1,
          o => 'Omim',
        },

        # protection
        { h => 'process this many entries',
          t => 'int',
          d => 1e6,
          o => 'EntriesN',
        },
      ],
    });

   return $self;
}

# ----------------------------------------------------------------------

sub run {
   my $Self = shift;

   # make sure STDOUT is hot.
   $| = 1;

   # log stuff we always want to see.
   $Self->logCommit();
   $Self->logRAIID();

   # RETURN
   my $RV = 'programmar did not set a message';

   # find external database objects;
   my $db_cache = $Self->_getExtDbRelCache();
   return $@ if $@;

   # parse the input file.
   my $ezp = CBIL::Bio::Enzyme::Parser
   ->new({ InPath => $Self->getCla()->{InPath},
         });
   $ezp->assemble;
   return $@ if $@;

   # make sure we can hold everything.
   $Self->getSelfInv()->setMaximumNumberOfObjects(100000);

   if ($Self->getCla()->{Update}) {
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
         $Self->_process($db_cache->{ENZYME},
                         $all_ec,$all_gus,$thing
                        );
         last if ++$things_n >= $Self->getCla()->{EntriesN};
      }

      # display tree of ECs
      if ($Self->getCla()->{Survey}) {
         my $root_g = $all_gus->{'-.-.-.-'};
         print $root_g->toXML;
      } else {
         $db_cache->{ENZYME}->submit();
         $all_gus->{'-.-.-.-'}->submit();
      }
   }

   return $Self->_return_message;
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
   my $Self = shift;
   my $RV;

   my $ok = 1;
   foreach my $db ( qw( Enzyme SwissProt Prosite Omim ) ) {

      my $db_lcn = $Self->getCla()->{$db}->[0];
      my $db_ver = $Self->getCla()->{$db}->[1];

      my $_xdb = GUS::Model::SRes::ExternalDatabase->new
      ({ lowercase_name => $db_lcn });
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
            $Self->log('WARN',
                       sprintf("Could not locate release '%s' for database '%s' for %s",
                               $db_ver, $db_lcn, $db
                              )
                      );
            $ok = 0 unless $db eq 'Omim' || $db eq 'Prosite';
         }

      } else {
         $Self->log('WARN',
                    sprintf("Could not locate database '%s' for %s",
                            $db_lcn, $db
                           )
                   );
         $ok = 0 unless $db eq 'Omim' || $db eq 'Prosite';
      }
   }

   if ($ok) {
      $Self->_setDbCache($RV)->_getDbCache();
   } else {
      die 'Could not locate all ExternalDatabaseReleases';
   }
}

# ----------------------------------------------------------------------

sub _process {
   my $Self        = shift;
   my $ExDbRl      = shift;     # ExternalDatabase :
   my $EnzCache    = shift;  # hash ref : all EC objects by id string.
   my $GusCache    = shift; # hash ref : all GUS objects by id string.
   my $EnzymeClass = shift;     # EC obj : the one to process

   # make a EnzymeClass with most columns set
   # ......................................................................

   my $ec         = $EnzymeClass->getNumber;
   my $ec_key     = $ec->toString;

   return if $GusCache->{$ec_key};

   $Self->log('INFO', '_process',  $Self->_getProcessCount(), $EnzymeClass->getDescription() );

   my $ez_class_h = { depth       => $ec->getDepth,
                      ec_number   => $ec->toString,
                      description => $EnzymeClass->getDescription,
                    };
   my $depth = $ec->getDepth;
   for (my $i = 1; $i <= $depth; $i++) {
      $ez_class_h->{"ec_number_$i"} = $ec->getList->[$i-1];
   }
   my $ez_class_g = GUS::Model::SRes::EnzymeClass->new($ez_class_h);
   $Self->_incEnzymeClass;

   # process attribues
   $Self->_process_attributes($ez_class_g, $EnzymeClass);

   # process DB refs
   $Self->_process_dbrefs($ez_class_g, $EnzymeClass);

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
            print join("\t", ref $Self,
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
            $Self->_process($ExDbRl,$EnzCache,$GusCache,$EnzCache->{$parent_id});
            $parent_gus = $GusCache->{$parent_id};
         }

         if ($parent_gus) {
            $parent_gus->addChild($ez_class_g);
            #$ez_class_g->setParent($parent_gus);
         } else {
            print join("\t", ref $Self,
                       'Could not make GUS parent',
                       $ec->toString
                      ), "\n";
         }
      }
   }

   #  if ($Self->getCla()->{Survey}) {
   #    print '-' x 70, "\n";
   #    print $ez_class_g->toXML;
   #  }
}

# ----------------------------------------------------------------------

sub _process_attributes {
   my $Self = shift;
   my $GusZyme = shift;
   my $EnzymeClass = shift;

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
      $Self->_incEnzymeClassAttribute;
      #print $ez_att_g->toXML if $Self->getCla()->{Survey};
   }
}


# ----------------------------------------------------------------------

sub _process_dbrefs {
   my $Self = shift;
   my $GusZyme = shift;         # GUSdev::Objects::EnzymeClass
   my $EnzymeClass = shift;     # CBIL::Bio::Enzyme::DbRef

   return unless ref $EnzymeClass eq 'CBIL::Bio::Enzyme::Enzyme';

   foreach my $dbref (@{$EnzymeClass->getDbRefs||[]}) {

      # string : database name
      my $db_c = $dbref->getDatabase;

      # ExternalDatabase : by name
      my $db_g = $Self->_getDbCache->{$db_c};
      if ($db_g) {

         my $save_as_attribute = 1;

         # sequence things
         if ($db_c eq 'PROSITE' || $db_c eq 'SWISSPROT' ) {
            #print '-' x 40, $GusZyme->getEcNumber, "\n";
            #$Self->{C}->{self_inv}->setDebuggingOn;
            $db_g->removeChildrenInClass('DoTS::ExternalAASequence');
            $db_g->retrieveChildrenFromDB('DoTS::ExternalAASequence',
                                          0,
                                          {
                                           source_id => $dbref->getPrimaryId },
                                         );
            my @eas_g = $db_g->getChildren('DoTS::ExternalAASequence');
            #$Self->{C}->{self_inv}->setDebuggingOff;

            # we got some sequences to annotate, make the links
            if (scalar @eas_g) {
               foreach my $eas_g (@eas_g) {
                  my $asec_h = { evidence_code     => 'TAS',
                                 review_status_id  => 0, # not reviewed.
                                 aa_sequence_id    => $eas_g->getId,
                               };
                  my $asec_g = GUS::Model::DoTS::AASequenceEnzymeClass->new($asec_h);
                  $Self->_incAASequenceEnzymeClass;
                  $asec_g->setParent($GusZyme);
               }
               $save_as_attribute = 0;
            }
         }

         if ($save_as_attribute) {
            my $eca_h = { attribute_name  => 'DatabaseReference',
                          attribute_value => sprintf('%s:%s:%s',
                                                     $dbref->getDatabase,
                                                     $dbref->getPrimaryId,
                                                     $dbref->getSecondaryId,
                                                    ),
                        };
            my $eca_g = GUS::Model::SRes::EnzymeClassAttribute->new($eca_h);
            $Self->_incEnzymeClassAttribute;
            $eca_g->setParent($GusZyme);
         }
      }                         # eo able to find a db object
   }                            # eo dbref list
}

# ----------------------------------------------------------------------

sub _return_message {
   my $Self = shift;

   return sprintf(join(', ',
                       'Made %d EnzymeClass entries',
                       '%d EnzymeClassAttribute entries',
                       '%d AASequenceEnzymeClass entries',
                      ),
                  $Self->_getEnzymeClass,
                  $Self->_getEnzymeClassAttribute,
                  $Self->_getAASequenceEnzymeClass,
                 );
}

# ----------------------------------------------------------------------

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

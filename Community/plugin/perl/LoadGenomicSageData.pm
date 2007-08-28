
package GUS::Community::Plugin::LoadGenomicSageData;

=pod

=head1 Purpose Brief

Generate SAGE data from sequences and genes or from saco-matic
(trp-compare) output.

=head1 Purpose

This plugin generates SAGE data from genomic data.  Specifically, it
finds SAGE tags in ExternalNaSequences, and creates
GeneFeatureSageTagLinks to associate SAGE tags with genes.  These
associations are made by the findLinks method.  This method, written
by Jonathan Crabtree for an earlier version of this plugin, links each
SAGE tag to any genes found within a given distance (by default, 1000
bp).

A recent additional mode C<--load_saco_tags> reads through a file in
the saco-matic format and adds any of the tags in the file as
necessary.

=head1 Failure Cases

=head1 How to Restart

This plugin has no restart facility.

=head1 Notes

Plugin is currently hardwired for the NlaIII restriction enzyme.
However, the hardwiring is done in such a way that it can be upgraded
easy.

=head2 SA (SAGE/SACO) Arrays

These arrays are handled in a somewhat odd way in GUS.  The array is
defined by the tuple of genome, restriction enzyme, and tag length.
The number of potential tags in a genome is quite large and in
addition an experiment may yield tags not present in the genome.  Thus
we do not pre-define all of the 'spots', i.e., tags, in a SA array.
Rather we add them, uniquely, as they are encountered in an experiment
that uses the array.

Thus in this plugin, code that locates a C<RAD.SageTag> must try to
retrieve the tag from the database before submitting the object.  This
will ensure that the plugin reuses exising tags.

=cut

# ========================================================================
# ----------------------------- Declarations -----------------------------
# ========================================================================

use strict;

use vars qw( @ISA );

@ISA = qw(GUS::PluginMgr::Plugin);

use CBIL::Util::Files;
use CBIL::Util::V;

use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::SAGETagFeature;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::GeneFeatureSAGETagLink;
use GUS::Model::DoTS::NALocation;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::RAD::SAGETag;
use GUS::Model::RAD::SAGETagMapping;
use GUS::Model::Core::DatabaseInfo;
use GUS::Model::Core::TableInfo;

use GUS::Model::DoTS::NAFeatureRelationship;
use GUS::Model::DoTS::Miscellaneous;
use GUS::Model::DoTS::NAFeatRelationshipType;

# ========================================================================
# -------------------------- Required Methodsa ---------------------------
# ========================================================================

# --------------------------------- new ----------------------------------

sub new {
   my ($class) = @_;

   my $Self = bless {}, $class;

   $Self->initialize
   ({ requiredDbVersion    => '3.5',
      cvsRevision          => '$Revision$',
      cvsTag               => '$Name: $',
      name                 => ref($Self),

      revisionNotes        => '',
      revisionNotes        => 'code cleanup and support for SACO tags',
      revisionNotes        => 'saco cluster loading',
      revisionNotes        => 'oops, forgot to set na_sequence_id in cluster features',

      documentation        => 
      { $Self->extractDocumentationFromMyPod(),
        tablesAffected   =>  [ ['DoTS::GeneFeatureSAGETagLink', 'Insert a record for each predicted link'],
                               ['DoTS::SAGETagFeature',         'Insert a record for each predicted SAGE tag feature'],
                               ['DoTS::NALocation',             'Insert three records for each predicted tag or one for each cluster'],
                               ['RAD::SAGETag',                 'Insert a record for any novel tag sequence'],
                               ['RAD::SAGETagMapping',          'Map DoTS sourceId-ExtDbRelId to RAD CompositeElementId'],
                               ['DoTS::Miscellaneous',          'Inserts clusters here', ],
                               ['DoTS::NAFeatureRelationship',  'Inserts connection between clusters and tags here', ],
                             ],

        tablesDependedOn => [ ['DoTS::ProjectLink',             'Identify sequences to scan for tags'],
                              ['DoTS::ExternalNASequence',      'Get sequences to scan for SAGE tag features'],
                              ['DoTS::SAGETagFeature',          'Get SAGE tag features to link'],
                              ['DoTS::GeneFeature',             'Get gene features to link'],
                              ['DoTS::NALocation',              'Get locations within ExternalNaSequence of SAGE tags and genes'],
                              ['Core::DatabaseInfo',            'Look up table IDs by database/table names'],
                              ['Core::TableInfo',               'Look up table IDs by database/table names'],
                            ],
      },

      argsDeclaration    =>
      [
       # common arguments
       integerArg({ name  => 'project_id',
                    descr => 'project_id',
                    reqd  => 0,
                    constraintFunc=> undef,
                    isList=> 0,
                  }),
       integerArg({ descr => 'sres.externalDatabaseRelease_id for genome sequences',
                    name  => 'sequence_edrid',  reqd  => 0,  constraintFunc=> undef, isList=> 0,
                  }),
       integerArg({ descr => 'sres.externalDatabaseRelease_id for features and other tables',
                    name  => 'features_edrid',  reqd  => 0,  constraintFunc=> undef, isList=> 0,
                  }),
       integerArg({ name  => 'taxon_id',
                    descr => 'taxon_id',
                    reqd  => 1,
                    constraintFunc=> undef,
                    isList=> 0,
                  }),
       integerArg({ name  => 'array_design_id',
                    descr => 'array_design_id',
                    reqd  => 0,
                    constraintFunc=> undef,
                    isList=>0,
                  }),
       stringArg({ name  => 'enzymeName',
                   descr => 'name of restriction enzyme used to cut DNA',
                   reqd  => 0,
                   default => 'NlaIII',
                   constraintFunc => undef,
                   isList => 0,
                 }),

       stringArg({ name    => 'enzymeCutSite',
                   descr   => 'sequence at which the enyzme cuts',
                   reqd    => 0,
                   default => 'CATG',
                   constraintFunc => undef,
                   isList => 0,
                 }),

       # finding tags arguments
       booleanArg({ name  => 'find_tags',
                    descr => 'find_tags',
                    reqd  => 0,
                    constraintFunc=> undef,
                    isList=> 0,
                  }),

       # gene linking arguments
       booleanArg({ name  => 'find_links',
                    descr => 'find_links',
                    reqd  => 0,
                    constraintFunc=> undef,
                    isList=> 0,
                  }),
        integerArg({ name  => 'max_distance',
                     descr => 'max_distance',
                     reqd  => 0,
                     default  => 1000,
                     constraintFunc=> undef,
                     isList=> 0,
                   }),

       # saco-mode args.
       booleanArg({ name  => 'load_saco_tags',
                    descr => 'load tags from a file',
                    reqd  => 0,
                    constraintFunc => undef,
                    isList         => 0,
                   }),
       stringArg({ name   => 'saco_file',
                   descr  => 'load tags from this file',
                   reqd   => 0,
                   format => 'sacomatic trp-compare',
                   mustExist => 1,
                   constraintFunc => undef,
                   isList         => 0,
                 }),

       # saco-cluster-mode args.
       booleanArg({ name  => 'load_saco_clusters',
                    descr => 'load SACO tag clusters from a file',
                    reqd  => 0,
                    constraintFunc => undef,
                    isList         => 0,
                   }),
       stringArg({ name   => 'saco_cluster_file',
                   descr  => 'load clusters from this file',
                   reqd   => 0,
                   format => 'cluster.pl clusters',
                   mustExist => 1,
                   constraintFunc => undef,
                   isList         => 0,
                 }),
       integerArg({ descr => 'minimum abundance for loadable clusters',
                    name  => 'saco_cluster_abundance',
                    reqd  => 0,
                    default => 1,
                    constraintFunc=> undef,
                    isList => 0,
                  }),

      ]
    });

   return $Self;
}

# ------------------------------ undoTables ------------------------------

sub undoTables {
   return qw( DoTS.NAFeatureRelationship DoTS.NALocation DoTS.Miscellaneous RAD.SAGETagMapping DoTS.SAGETagFeature RAD.SAGETag );
}

# --------------------------------- run ----------------------------------

sub run {
   my ($Self) = @_;

   #$Self->logAlgInvocationId;
   #$Self->logCommit;

   # ................... validate command line arguments ....................

   if (!( $Self->getArg('find_tags') ||
          $Self->getArg('find_links') ||
          $Self->getArg('load_saco_tags') ||
          $Self->getArg('load_saco_clusters')
        )
      ) {
      $Self->userError('--find_tags, --find_links, --load_saco_tags or --load_saco_clusters must be specified');
   }

   if ($Self->getArg('find_tags') || $Self->getArg('load_saco_tags')) {
      if (!$Self->getArg('array_design_id')) {
         $Self->userError('an array_design_id must be specified to find or load tags');
      }
      $Self->{tagsN}  = 0;
   }

   if ($Self->getArg('find_links')) {
      $Self->{linksFound} = 0;
   }

   # ............................. do the work ..............................

   if ($Self->getArg('find_links')) {
      $Self->prepareQuery($Self->getArg('max_distance'));
   }

   if ($Self->getArg('load_saco_clusters')) {
      $Self->loadSacoClusters();
   }

   elsif ($Self->getArg('load_saco_tags')) {
      $Self->loadSacomaticTags();
   }

   else {
      $Self->processSequencesByProjectId($Self->getArg('project_id'),
                                         $Self->getArg('taxon_id')
                                        );
   }

   # ....................... generate status message ........................

   my $logString = "LoadGenomicSageData finished.";
   if ($Self->getArg('load_saco_tags')) {
      $logString = "$logString $Self->{tagsN} tags loaded.";
   } elsif ($Self->getArg('load_saco_clusters')) {
      $logString = "$logString  $Self->{clustersN} clusters of $Self->{tagsN} tags loaded.";
   } else {
      if ($Self->getArg('find_tags')) {
         $logString = $logString . " " . $Self->{tagsN} . " tags found.";
      }
      if ($Self->getArg('find_links')) {
         $logString = $logString . " " . $Self->{linksFound} . " links found.";
      }
   }

   $Self->log($logString);
}

# ========================================================================
# --------------------------- Support Methods ----------------------------
# ========================================================================

# -------------------------- loadSacomaticTags ---------------------------

=pod

=head1 Processing SACO-matic Tags

Tags are extracted from a file generated by trp-compare.

=head2 trp-compare Format

The first four colums of each row are the observed tag, its abundance,
number of exact matches and number of inexact matches.  The rest of
the row are the matches to the genome which are specified in 4-tuples
of the genomic tag, the cut site location, strand of the tag and
chromosome.

=cut

sub loadSacomaticTags {
   my $Self = shift;

   # this is a work-around until the version table schema is fixed.
   $Self->getDb()->setGlobalNoVersion(1);

   my $saco_f = $Self->getArg('saco_file');
   if (my $saco_fh = FileHandle->new("<$saco_f")) {

      my $chrToGus_dict = $Self->findSequencesByEdrId();

      # track tags we've seen so that we don't double map them (these are from mismatches).
      my %seen_b;

      while (<$saco_fh>) {
         my ($tag, $abund, $exact_n, $inexact_n, @_matches) = my @cols = split /\s+/;

         # is a real tag, not header junk
         if ($tag =~ /^[a-z]+$/i) {

            # make a tag for the exact observed tag
            my $_sageTag = GUS::Model::RAD::SAGETag->new({ tag             => $tag,
                                                           array_design_id => $Self->getArg('array_design_id'),
                                                         });
            if (!$_sageTag->retrieveFromDB()) {
               $_sageTag->submit();
            }

            # make sure counts are acceptable for processing matches
            if ($Self->isaLoadableTag($exact_n, $inexact_n)) {

               # process each match
               for (my $match_i = 0; $match_i < @_matches; $match_i += 4) {

                  my ($gtag, $location, $strand, $chromosome)
                  = my @_match
                  = @_matches[$match_i .. $match_i+3];

                  my $key = join('-', @_match);

                  # process novel matches.
                  if ($seen_b{$key}++ == 0) {

                     # get the genomic sequence entry
                     my $_vs   = $chrToGus_dict->{$chromosome}
                     || die "Can not find a dots.virtualSequence chromosome for '$chromosome'.";

                     # create the arguments
                     $Self->createSageObjects( enzymeName       => $Self->getArg('enzymeName'),
                                               sequenceSourceId => $chromosome,
                                               sequenceObject   => $_vs,
                                               leftEnd          => $location,
                                               rightEnd         => $location + length($Self->getArg('enzymeCutSite')) - 1,
                                               isReversed       => $strand eq 'f' ? 0 : 1,
                                               sense            => $strand,
                                               tag              => $tag,
                                               tagSize          => length($tag),
                                               trailerSize      => 0,
                                               gtag             => $gtag,
                                               radTag           => $_sageTag,
                                             );
                  }
                  else {
                     $Self->log('SEEN', $key);
                  }
               }

               $Self->undefPointerCache();
            }
         }
      }

      $saco_fh->close();
   }

   #
   else {
      die "Can not open saco file '$saco_f': $!";
   }
}

# ------------------------- processSacoTagMatch --------------------------

=pod

=head2 Processing a SACO Tag Match



=cut

sub processSacoTagMatch {
   my $Self = shift;
   my $Dict = shift;
   my $Obs  = shift;
   my $Gtag = shift;

}

# ---------------------------- isaLoadableTag ----------------------------

=pod

=head2 Loadable Tags

Tags are loaded only if the number of exact and inexact matches meet
certain criteria.

Here they are:

  ExactN  InexactN  Class
    0        0      no matches anyway
    1       <5      exact match and not too many inexact matches
    0        1      no exact match but a likely inexact match

=cut

sub isaLoadableTag {
   my $Self     = shift;
   my $ExactN   = shift;
   my $InexactN = shift;

   my $Rv = ( $ExactN == 0 && $InexactN == 0 ||
              $ExactN == 1 && $InexactN < 5  ||
              $ExactN == 0 && $InexactN == 1
            );

   return $Rv;
}

# ========================================================================
# ------------------------ Loading SACO Clusters -------------------------
# ========================================================================

=pod

=head1 Loading SACO Clusters

A cluster is a group of SACO tags that are thought to represent the
same biological event.  The clusters are defined with an external
program.  They are defined in terms of tags that must already be
loaded (e.g., using C<load_saco_tags>.

A cluster is represented by a C<GUS::Model::DoTS::Miscellaneous>
feature.  Details are provided by
C<GUS::Model::DoTS::NAFeatureRelationship> links to the consituent
C<GUS::Model::DoTS::SageTagFeature> rows.

Information (abundances) about the clusters is logged to a
tab-delimited file so that it can be loaded into a view of
C<RAD::AnalysisResultImp>.

=cut

sub loadSacoClusters {
   my $Self = shift;

   $Self->{tagsN}     = 0;
   $Self->{clustersN} = 0;

   my $cluster_f  = $Self->getArg('saco_cluster_file') || die "The --saco_cluster_file must be specified.";
   my $cluster_fh = CBIL::Util::Files::SmartOpenForRead($cluster_f);

   my $naFeatRelType_id = $Self->findOrCreateRelationType();

   while (my $_cluster = $Self->nextCluster($cluster_fh)) {

      next if $_cluster->{abund_n} < $Self->getArg('saco_cluster_abundance');

      my @_tags = @{$_cluster->{tags}};

      my @_info = eval { map { $Self->findSacoTag($_cluster, $_) } @_tags };

      if ($@) {
         $Self->logData('ERROR',
                        $_cluster->{ord}, $@
                       );
      }

      else {
         my $feature_gus = GUS::Model::DoTS::Miscellaneous->new
         ({ external_database_release_id => $Self->getArg('features_edrid'),
          });

         # location of cluster, ready for min/max updates
         my $beg = 1e10;
         my $end = -1e10;
         my $na_seq_id;

         # store relations here for later attachment to the cluster.
         my @relationships_gus = ();

         # process each tag
         for (my $tag_i = 0; $tag_i < scalar @_tags; $tag_i++) {
            my $_tag  = $_tags[$tag_i];
            my $_info = $_info[$tag_i];

            # find the corresponding feature.
            my $_info = $Self->findSacoTag($_cluster, $_tag);

            # track the chromosomal sequence and make sure it's consistent.
            if (not defined $na_seq_id) {
               $na_seq_id = $_info->{na_sequence_id};
            }
            elsif ($na_seq_id != $_info->{na_sequence_id}) {
               die "Tag for cluster $_cluster->{ord} not located on same sequence as rest of cluster.";
            }

            # make the relationship
            my $relation_gus = GUS::Model::DoTS::NAFeatureRelationship->new
            ({ child_na_feature_id          => $_info->{na_feature_id},
               ordinal                      => $_tag->{ord},
               na_feat_relationship_type_id => $naFeatRelType_id,
             });

            $beg = CBIL::Util::V::min($beg, $_info->{start_min});
            $end = CBIL::Util::V::max($end, $_info->{end_min});

            push(@relationships_gus, $relation_gus);
         }


         # update cluster with name now that we know the boundaries
         my $name      = join('-',
                              $_cluster->{chr},
                              $beg,
                              $end,
                              'x',
                             );
         $name = substr($name, 0, 30);

         my $source_id = join('-',
                              $_cluster->{chr},
                              $Self->getArg('sequence_edrid'),
                              $beg,
                              $end,
                              'x',
                              $Self->getArg('enzymeName'),
                             );
         $feature_gus->setName($name);
         $feature_gus->setSourceId($source_id);
         $feature_gus->setNaSequenceId($na_seq_id);

         # create and attach cluster location.
         my $location_gus = GUS::Model::DoTS::NALocation->new
         ({ start_min => $beg,
            start_max => $beg,
            end_min   => $end,
            end_max   => $end,
          });

         $location_gus->setParent($feature_gus);

         # submit cluster feature.
         $feature_gus->submit();

         # connect and submit relationships
         foreach (@relationships_gus) {
            $_->setParentNaFeatureId($feature_gus->getId());
            $_->submit();
         }

         $Self->{clustersN}++;
         $Self->{tagsN}    += $_cluster->{tags_n};

         # add to log for RAD loading.
         $Self->logData('CLUSTER',
                        $_cluster->{ord},
                        $feature_gus->getId(), $feature_gus->getSourceId(),
                        $_cluster->{tags_n}, $_cluster->{abund_n}
                       );

         $Self->undefPointerCache();
      }
   }

   $cluster_fh->close();

}

# ----------------------- findOrCreateRelationType -----------------------

=pod

=head2 NAFeatRelationshipType

The plugin finds or creates a C<ClusterMember> entry in
C<GUS::Model::DoTS::NAFeatRelationshipType>.  Description must
match as well.

=cut

sub findOrCreateRelationType {
   my $Self = shift;

   my $Rv;

   my $_gus = GUS::Model::DoTS::NAFeatRelationshipType->new
   ({ name        => 'ClusterMember' });

   if (!$_gus->retrieveFromDB()) {
      $_gus->setDescription('Membership of child feature in parent feature by clustering, i.e., parent is a cluster of child features.');
      $_gus->submit();
   }

   $Rv = $_gus->getId();

   return $Rv;
}

# ----------------------------- nextCluster ------------------------------

=pod

=head2 Cluster File Format

=cut

sub nextCluster {
   my $Self = shift;
   my $Fh   = shift;

   my $Rv;

   if (my $line = <$Fh>) {
      chomp $line;
      ($Rv->{cluster_kw}, $Rv->{ord},
       $Rv->{chr}, $Rv->{chr_n}, $Rv->{beg}, $Rv->{end},
       $Rv->{tags_n}, $Rv->{abund_n}, $Rv->{size}
      ) = my @_cluster = split /\t/, $line;

      for (my $tag_i = 0; $tag_i < $Rv->{tags_n}; $tag_i++) {
         my $line = <$Fh>;
         chomp $line;
         my %_tag;
         ($_tag{hit_kw},
          $_tag{tag}, $_tag{pos}, $_tag{dir},
          $_tag{tagAbund_n}) = my @_tag = split /\t/, $line;
         $_tag{ord} = 1;
         push(@{$Rv->{tags}}, \%_tag);
      }
   }

   return $Rv;
}

# ----------------------------- findSacoTag ------------------------------

=pod

=head2 Finding Tags

=cut

sub findSacoTag {
   my $Self    = shift;
   my $Cluster = shift;
   my $Tag     = shift;

   my $Rv;

   my $sequence_edrid = $Self->getArg('sequence_edrid');

   my $cut_bp         = length($Self->getArg('enzymeCutSite'));
   my $tag_bp         = length($Tag->{tag});

   my $bind_start     = $Tag->{pos};
   my $bind_end       = $Tag->{pos} + $cut_bp - 1;

   my $tag_start      = $Tag->{dir} eq 'r' ? $Tag->{pos} - $tag_bp : $Tag->{pos} + $cut_bp;
   my $tag_end        = $Tag->{dir} eq 'r' ? $Tag->{pos} - 1       : $Tag->{pos} + $cut_bp + $tag_bp - 1;

   my $isRev_b        = $Tag->{dir} eq 'r' ? 1 : 0;

   my $source_id      = join('-',
                             $Cluster->{chr},
                             $sequence_edrid,
                             $tag_start,
                             $tag_end,
                             $Tag->{dir},
                             $Self->getArg('enzymeName')
                            );

   my $_sql = <<SQL;

   SELECT  stf.na_sequence_id
   ,       stf.na_feature_id
   ,       nalB.start_min
   ,       nalB.end_min
   FROM    dots.naLocation      nalT
   ,       dots.naLocation      nalB
   ,       dots.sageTagFeature  stf
   ,       dots.virtualSequence vs
   WHERE   nalT.start_min                  = $tag_start
   AND     nalT.end_min                    = $tag_end
   AND     nalT.is_reversed                = $isRev_b
   AND     nalT.na_feature_id              = nalB.na_feature_id
   AND     nalB.start_min                  = $bind_start
   AND     nalB.end_min                    = $bind_end
   AND     nalB.na_feature_id              = stf.na_feature_id
   AND     stf.source_id                   = '$source_id'
   AND     stf.na_sequence_id              = vs.na_sequence_id
   AND     vs.external_database_release_id = $sequence_edrid

SQL

   my $_tags = $Self->sqlAsHashRefs( Sql => $_sql );
   my $tags_n = @$_tags;
   if (1 != $tags_n) {
      die "Found $tags_n matching tags instead of 1: $_sql";
   }

   $Rv = $_tags->[0];

   return $Rv;
}


# ========================================================================
# -------------------- Other Support or Mode Methods ---------------------
# ========================================================================


# ----------------------------------------------------------------------
# Given a projectId, use ProjectLink to find and process
# the correspoding ExternalNaSequences

sub processSequencesByProjectId {
   my ($Self, $project_id, $taxon_id) = @_;

   my $table_id = getTableId('DoTS', 'ExternalNASequence');

   my $sql = <<SQL;
    select pl.id
    from DoTS.ProjectLink pl, DoTS.ExternalNaSequence ens
    where pl.project_id = $project_id
      and pl.table_id = $table_id
      and pl.id = ens.na_sequence_id
      and ens.taxon_id = $taxon_id
SQL

   $Self->logVerbose($sql);

   my $dbh = $Self->getQueryHandle();
   $Self->logVerbose("preparingAndExecuting sequenceId query");
   my $stmt = $dbh->prepareAndExecute($sql);
   $Self->logVerbose("finished prepareAndExecute()");

   while (my ($na_sequence_id) = $stmt->fetchrow_array()) {
      $Self->processSequence($na_sequence_id);
   }
}

sub findSequencesByEdrId {
   my $Self = shift;

   my %Rv;

   my $edr_id = $Self->getArg('sequence_edrid');

   # get a dictionary of source_id -> na_sequence_id
   my $_dict  = $Self->sqlAsDictionary( Sql => <<Sql );

     select vs.source_id
     ,      vs.na_sequence_id
     from   dots.VirtualSequence vs
     where  vs.external_database_release_id = $edr_id

Sql

   # convert na_sequence_id to object.
   foreach my $source_id (keys %$_dict) {
      $Rv{$source_id} = GUS::Model::DoTS::VirtualSequence->new({ na_sequence_id => $_dict->{$source_id} });
      $Rv{$source_id}->retrieveFromDB(['sequence']);
   }

   return wantarray ? %Rv : \%Rv;
}

# ----------------------------------------------------------------------
# given a sequence (by its naSequenceId), process it
# (i.e. find its SageTagFeatures or link them to Gene features)

sub processSequence {
   my ($Self, $na_sequence_id) = @_;
   $Self->logVerbose("processing NaSequenceId $na_sequence_id");

   if ($Self->getArg('find_tags')) {
      $Self->findTags($na_sequence_id);
   }

   if ($Self->getArg('find_links')) {
      $Self->findLinks($na_sequence_id);
   }

   $Self->undefPointerCache();
}

# ========================================================================
# ----------------------------- Finding Tags -----------------------------
# ========================================================================

# ------------------------------- findTags -------------------------------

=pod

=head1 Finding Tags in the Genome

This mode retrieves each sequence for the genome, then performs an in
silico digest and records the tags that it finds.

Since it retrieves the entire sequence, it should not be used for
large mammalian genomes.

This code assumes the restriction site is symmetric and generates tags
in both directions from the restriction site.

=cut

sub findTags {
   my ($Self, $na_sequence_id) = @_;

   my $externalNaSequence = GUS::Model::DoTS::ExternalNASequence->new
     ({ na_sequence_id => $na_sequence_id
      });
   $externalNaSequence->retrieveFromDB();

   my $sequence = $externalNaSequence->getSequence();
   my $sourceId = $externalNaSequence->getSourceId();

   # previously hardwired for the restriction enzyme NlaIII, which recognizes CATG
   my $enzymeName  = $Self->getArg('enzymeName');   # 'NlaIII';
   my $recogSeq    = $Self->getArg('enzymCutSite'); # 'CATG';
   my $recogLength = length($recogSeq);

   my $siteCount = 0;

   while ($sequence =~ m/($recogSeq)/ig) {

      # these are coordinates of binding site in 1-based system
      my $rightEnd = pos ($sequence);
      my $leftEnd  = $rightEnd - $recogLength + 1;

      # since the enzyme recognition sequence is its own reverse complement
      # (which it is, at least, for NlaIII) each site makes two tags.

      my %common = ( rightEnd         => $rightEnd,
                     leftEnd          => $leftEnd,
                     enzymeName       => $enzymeName,
                     sequenceObject   => $externalNaSequence,
                     sequenceString   => \$sequence,
                     tagSize          => 10,
                     trailerSize      => 4,
                     sequenceSourceId => $sourceId,
                   );

      $Self->createSageObjects( { isReversed => 0, sense => 'G', %common } );
      $Self->createSageObjects( { isReversed => 1, sense => 'g', %common } );

      if ( 20 * $siteCount++ >= 10000 ) {
         $Self->undefPointerCache();
         $siteCount = 0;
      }
   }
}

# -------------------------- createSageObjects ---------------------------

=pod

=head1 Creating SageTagFeatures

A C<dots.sageTagFeature> has three locations: the restriction size,
the adjacent tag, and a flanking 'trailer'.

The source_id of the tag is the concatenation of the chromosome source
id, genome release id, tag start, tag end, and a sense indicator.

The name is similar to the source id, but need not be unique so we
only use the chromosome, start, end, and sense.  In addition we
truncate this to 30 chars.

We make the SAGETagFeature.

We make the binding NALocation and point it at the SAGETagFeature.

We make the tag NALocation and point it at the SAGETagFeature.  If the
caller has supplied a genomic_tag value, then this is set in the
literal_sequence attribute of the NALocation.  The point of this is to
indicate whether this is an exact or inexact match to the observed
tag.

We make the trailer NALocation if its length is non-zero.

We submit the SAGETagFeature to get its primary key, and more
importantly the primary keys of the NALocations.  We then poke these
in to the SAGETagFeature which points at them.

We finally make a C<rad.sageTag> if is has not been passed in from the
beginning.

=cut

sub createSageObjects {
   my $Self = shift;
   my $Args = ref $_[0] ? shift : {@_};

   my $bind_start    = $Args->{leftEnd};
   my $bind_end      = $Args->{rightEnd};

   my $tag_start     = $Args->{isReversed} ? $bind_start - $Args->{tagSize} : $bind_end + 1 ;
   my $tag_end       = $Args->{isReversed} ? $bind_start - 1  : $bind_end + $Args->{tagSize};

   my $trailer_start = $Args->{isReversed}
   ? $bind_start - ($Args->{tagSize} + $Args->{trailerSize})
   : $bind_end   + ($Args->{tagSize} + 1);
   my $trailer_end   = $Args->{isReversed}
   ? $bind_start - ($Args->{tagSize} + 1)
   : $bind_end   + ($Args->{tagSize} + $Args->{trailerSize});

   my $senseChar          = $Args->{sense};

   my $externalNaSequence = $Args->{sequenceObject};

   my $features_edrid      = $Self->getArg('features_edrid');

   # Make source_id unique, even if the same NaSequence.SourceId occurs
   # in two different ExternalDatabaseReleases
   my $sourceId = join('-',
                       $Args->{sequenceSourceId},
                       $externalNaSequence->getExternalDatabaseReleaseId(),
                       $tag_start,
                       $tag_end,
                       $senseChar,
                       $Args->{'enzymeName'},
                      );

   # Name should be in the same familiar format, but needn't be unique
   my $name = join('-',
                   $Args->{sequenceSourceId},
                   $tag_start,
                   $tag_end,
                   $senseChar,
                  );
   $name = substr($name, 0, 30);

   # make the database entries.
   my $sageTagFeature = GUS::Model::DoTS::SAGETagFeature->new
   ({ name                         => $name,
      source_id                    => $sourceId,
      external_database_release_id => $features_edrid,
      is_predicted                 => 1,
      restriction_enzyme           => $Args->{enzymeName},
    });
   #$sageTagFeature->setParent($Args->{sequenceObject});
   $sageTagFeature->setNaSequenceId($externalNaSequence->getId());

   my $bnd_nalg = GUS::Model::DoTS::NALocation->new
   ({ start_min      => $bind_start,
      start_max      => $bind_start,
      end_min        => $bind_end,
      end_max        => $bind_end,
      is_reversed    => $Args->{isReversed},
      loc_order      => 0,
    });
   $bnd_nalg->setParent( $sageTagFeature );

   my $tag_nalg = GUS::Model::DoTS::NALocation->new
   ({ start_min      => $tag_start,
      start_max      => $tag_start,
      end_min        => $tag_end,
      end_max        => $tag_end,
      is_reversed    => $Args->{isReversed},
      $Args->{gtag} ? ( literal_sequence => $Args->{gtag} ) : (),
      loc_order      => 1,
    });
   $tag_nalg->setParent( $sageTagFeature );

   my $trl_nalg = $Args->{trailerSize} > 0
   ? GUS::Model::DoTS::NALocation->new
   ({ start_min      => $trailer_start,
      start_max      => $trailer_start,
      end_min        => $trailer_end,
      end_max        => $trailer_end,
      is_reversed    => $Args->{isReversed},
      loc_order      => 2,
    })
   : undef ;
   $trl_nalg && $trl_nalg->setParent( $sageTagFeature );

   $sageTagFeature->submit();

   if ($sageTagFeature->getNaSequenceId() == 0) {
      $Self->log('ERROR', 'null feature na_sequence_id');
   }

   $Self->{tagsN} += 1;

   $sageTagFeature->setBindingLocationId($bnd_nalg->getId());
   $sageTagFeature->setTagLocationId($tag_nalg->getId());
   $trl_nalg && $sageTagFeature->setTrailerLocationId($trl_nalg->getId());

   $sageTagFeature->submit();

   if ($Args->{radTag}) {
      $Self->updateRad($Args->{radTag}, $sageTagFeature);
   }
   else {
      my $tag = $Args->{tag} || substr(${$Args->{sequenceString}}, $tag_start - 1, $Args->{tagSize} );
      $tag = reverseComplement($tag) if $Args->{isReversed};
      $tag = uc($tag);
      $Self->updateRad($tag, $sageTagFeature);
   }

   $Self->log('TAG', $Self->{tagsN}, $Args->{tag} || 'tag', $sourceId);
}

# ------------------------------ updateRad -------------------------------

=pod

=head1 Updating RAD

This plugin also connects the C<dots.sageTagFeature> to C<rad.sageTag>
via C<rad.sageTagMapping>.

Depending on the context, we may already have a C<rad.sageTag> or may
just have the tag sequence.

If we just have the tag sequence, we create/retrieve a new/old object
from the database.

=cut

sub updateRad {
   my ($Self, $tag, $sageTagFeature) = @_;

   my $sageTag;

   # use existing object
   if (ref $tag) {
      $sageTag = $tag;
   }

   # create/retrieve object
   else {
      $sageTag = GUS::Model::RAD::SAGETag->new({ tag             => $tag,
                                                 array_design_id => $Self->getArg('array_design_id'),
                                               });
      if (!$sageTag->retrieveFromDB()) {
         $sageTag->submit();
      }
   }

   my $sageTagMapping = GUS::Model::RAD::SAGETagMapping->new
   ({ composite_element_id         => $sageTag->getCompositeElementId(),
      array_design_id              => $sageTag->getArrayDesignId(),
      source_id                    => $sageTagFeature->getSourceId(),
      external_database_release_id => $Self->getArg('features_edrid'),
    });

   $sageTagMapping->submit();
}

# ----------------------------------------------------------------------
# returns the reverse complement of a nucleic acid sequence

sub reverseComplement {
   my $s = $_[0];
   $s =~ tr/ACGT/TGCA/;
   my $rs = reverse $s;

   return $rs;
}
# ----------------------------------------------------------------------
# prepares a query to find linked genes and tags on a given NaSequence
# (the prepare is done separately, since the query will be executed
#  for each NaSequenceId in the big loop)

sub prepareQuery {
   my ($Self, $maxDistance) = @_;

   # This join gets ids and locations for close pairs of features.
   # The ugly expression that gets selected as "same_strand" should be
   # 1 if both records have the same value in "is_reversed", 0 otherwise.

   my $sql = <<SQL;
        select tf.na_feature_id as tag_id,
               gf.na_feature_id as gene_id,
               tfl.start_min,
               tfl.end_max,
               tfl.is_reversed,
	       gfl.start_min,
               gfl.end_max,
               gfl.is_reversed,
               (nvl(tfl.is_reversed, 0) * nvl(gfl.is_reversed, 0)
                + (1 - nvl(tfl.is_reversed, 0) )
                   * (1 - nvl(gfl.is_reversed, 0)))
                 as same_strand
	from DoTS.SAGETagFeature tf,
             DoTS.NALocation tfl,
	     DoTS.GeneFeature gf,
             DoTS.NALocation gfl
	where gf.na_sequence_id = ?
	and tf.na_sequence_id = gf.na_sequence_id
	and tf.na_feature_id = tfl.na_feature_id
	and gf.na_feature_id = gfl.na_feature_id
	and (abs(gfl.end_min - tfl.start_max) <= $maxDistance
	     or abs(gfl.start_max - tfl.end_min) <= $maxDistance
	     or (gfl.start_max <= tfl.end_min and gfl.end_min >= tfl.start_max))
SQL

   $Self->logVerbose($sql);

   my $dbh = $Self->getQueryHandle();
   $Self->{geneTagLinksQuery} = $dbh->prepare($sql);
}

# ----------------------------------------------------------------------
# Given an na_sequence_id, use SQL to find linked gene/SAGE tag pairs.
# This is just a copy of the _storeLinks method from the old version
# of this plugin, modified to work with GUS v. 3 objects.

sub findLinks {
   my ($Self, $na_sequence_id) = @_;

   $Self->logVerbose("finding links for NaSequenceId $na_sequence_id");

   my $queryHandle = $Self->{geneTagLinksQuery};
   $queryHandle->execute($na_sequence_id);

   while (my($tagId, $geneId, $tagStart, $tagEnd, $tagIsReversed, $geneStart,
             $geneEnd, $geneIsReversed, $sameStrand)
          = $queryHandle->fetchrow_array()) {

      $Self->logVerbose("linking GeneFeatureId " . $geneId
                        . " to SageTagFeatureId " . $tagId);
      my($tt5p, $tt3p);

      if (!$geneIsReversed) {
         if (($tagStart <= $geneStart) && ($tagEnd >= $geneStart)) {
            $tt5p = 0;
         } else {
            $tt5p = ($tagEnd <= $geneStart)
            ? $geneStart - $tagEnd
            : $geneStart - $tagStart;
         }
         if (($tagStart <= $geneStart) && ($tagEnd >= $geneStart)) {
            $tt3p = 0;
         } else {
            $tt3p = ($tagStart >= $geneEnd)
            ? $tagStart - $geneEnd
            : $tagEnd - $geneEnd;
         }
      } else {
         if (($tagStart <= $geneEnd) && ($tagEnd >= $geneEnd)) {
            $tt5p = 0;
         } else {
            $tt5p = ($tagStart >= $geneEnd)
            ? $tagStart - $geneEnd
            : $tagEnd - $geneEnd;
         }
         if (($tagStart <= $geneEnd) && ($tagEnd >= $geneEnd)) {
            $tt3p = 0;
         } else {
            $tt3p = ($tagEnd <= $geneStart)
            ? $geneStart - $tagEnd
            : $geneStart - $tagStart;
         }
      }

      my $geneFeatureSageTagLink =
      GUS::Model::DoTS::GeneFeatureSAGETagLink->new
        ( {
           genomic_na_sequence_id => $na_sequence_id,
           gene_na_feature_id => $geneId,
           tag_na_feature_id => $tagId,
           five_prime_tag_offset => $tt5p,
           three_prime_tag_offset => $tt3p,
           same_strand => $sameStrand,
           experimentally_verified => 0
          } );

      if ($geneFeatureSageTagLink->retrieveFromDB()) {
         die("SageTagLink already exists between geneFeature " . $geneId .
             " and sageTagFeature " . $tagId);
      }
      $geneFeatureSageTagLink->submit();
      $Self->undefPointerCache();

      $Self->{linksFound} += 1;
   }
   $queryHandle->finish();
}

# ----------------------------------------------------------------------
# look up tableId by database/table name

sub getTableId {
   my ($dbName, $tableName) = @_;

   my $db =
   GUS::Model::Core::DatabaseInfo->new( { name => $dbName } );
   $db->retrieveFromDB();

   my $table =
   GUS::Model::Core::TableInfo->new
     ( {
        name => $tableName,
        database_id => $db->getDatabaseId()
       } );

   $table->retrieveFromDB();

   my $id = $table->getTableId();

   if (! $id ) {
      die("can't get tableId for '$dbName\.$tableName'");
   }

   return $id;

}

# ========================================================================
# ---------------------------- End of Package ----------------------------
# ========================================================================

1;

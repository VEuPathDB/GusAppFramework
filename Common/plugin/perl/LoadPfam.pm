#!/usr/bin/perl

# -------------------------------------------------------------
# ImportPfam.pm
#
# Load a release of Pfam into GUS.  Assumes that the 
# ExternalDatabase table has already been populated with
# entries for the databases to which Pfam links (see below
# for the full list.)
# 
# Most recently tested on 9/9/2002 against Pfam Release 7.5,
# specifically the following file:
#  <ftp://ftp.sanger.ac.uk/pub/databases/Pfam/Pfam-A.full.gz>
#
# Created: Wed May 24 20:05:51 EDT 2000
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -------------------------------------------------------------
#
#
# For testing only;
#
# ga GUS::Common::Plugin::LoadPfam --parse_only --flat_file=/nfs/team81/pjm/temp/Pfam-A.full.gz --release=8.0
#
# NOTES
# -----
#
# Now extra middle table for DB version
#
# Was: DbRef -> ExternalDatabase
# Now: SRes.DBRef -> SRes::ExternalDatabaseRelease -> SRes::ExternalDatabase
#
# If I want to link to PRINTS, how do I know which version???
# I only know the version of PFam from the cmd line.
#
# Is is safe to assume that loadign the latest PFam means linking to the
# latest OTHER DBs???  
#
#
#

package GUS::Common::Plugin::LoadPfam;
@ISA = qw(GUS::PluginMgr::Plugin); #defines what is inherited

use strict;

use DBI;

use GUS::Model::DoTS::PfamEntry;
use GUS::Model::DoTS::DbRefPfamEntry;
use GUS::Model::SRes::DbRef;
use GUS::Model::SRes::ExternalDatabase;

# ----------------------------------------------------------
# Configuration
# ----------------------------------------------------------

# ----------------------------------------------------------
# GUSApplication
# ----------------------------------------------------------

sub new {
    my $class = shift;
    my $self  = {};
    bless($self,$class);

    my $usage   = 'Import a release of Pfam into GUS.';
    my $easycsp =
        [{
             o => 'release',
             r => 1,
             t => 'string',
             h => ('Pfam release number.'),
         },
         {
             o => 'flat_file',
             r => 1,
             t => 'string',
             h => ("Flat file containing the release of Pfam to load.  Expects\n" .
                   "\t\t\tthe file containing the annotation and full alignments in Pfam\n" .
                   "\t\t\tformat of all Pfam-A families (called \"Pfam-A.full\" in release 5.2)\n" .
                   "\t\t\tThe specified file may be in gzip (.gz) or compressed (.Z) format."),
         },
         {
             o => 'parse_only',
             h => ("Parse the Pfam input file without submitting any information into the \n" .
                   "\t\t\tdatabase; can be used to validate the parser against a new Pfam \n" .
                   "\t\t\trelease before actually trying to load the data.\n"),
             t => 'boolean',
         }];

    $self->initialize({requiredDbVersion => {},
                       cvsRevision    => '$Revision$', # cvs fills this in!
                       cvsTag         => '$Name$', # cvs fills this in!
                       name           => ref($self),
                       revisionNotes  => 'make consistent with GUS 3.0',
                       easyCspOptions => $easycsp,
                       usage          => $usage
                       });

    return $self;
}

sub run {
    my $self      = shift;
    my $flatFile  = $self->getCla->{'flat_file'};
    my $release   = $self->getCla->{'release'};
    my $parseOnly = $self->getCla->{'parse_only'};

    die "No release specified"   if (not defined($release));
    die "No flat file specified" if (not defined($flatFile));

    print STDERR "ImportPfam: COMMIT ", $self->getCla->{'commit'} ? "****ON****" : "OFF", "\n";
    print STDERR "ImportPfam: reading Pfam release $release from $flatFile\n";

    die "Unable to read $flatFile" if (not -r $flatFile);

    # Uncompress Pfam file on the fly if necessary, using gunzip
    # NOTE;
    # This should be specified in the $GUS_HOME/config/GUS-PluginMgr.prop
    #
    my $openCmd =
        ($flatFile =~ /\.(gz|Z)$/) ? "gunzip -c $flatFile |" : $flatFile;

    # Read ExternalDatabase table into memory
    # 
    my $dbh    = $self->getQueryHandle;
    my $extDbs = $self->readExternalDbReleases($dbh);

    # Statement used to look up DbRef entries for a given DB name
    #
    my $dbrefSth = $dbh->prepare("select db_ref_id from SRes.DbRef " .
				 "where  external_database_release_id = ? ".
                                 "and    lowercase_primary_identifier = ?");

    my $entry    = {};
    my $lastCode = undef;

    my $numEntries = 0;
    my $numRefs    = 0;

    open(PFAM, $openCmd);

  OUTER:
    while(<PFAM>) {

	# Skip these lines
	#
	next if (/^\# STOCKHOLM 1\.0$/);

	if (/^\#=GF (\S\S)\s+(\S.*)$/) {
	    my $code = $1;
	    my $value = $2;

	    # Single-valued attributes
	    #
	    # AC One word in the form PFxxxxx or PBxxxxxx
	    # ID One word less than 16 characters
	    # DE 80 characters or less.
	    # AU Author of the entry.
	    # AL The method used to align the seed members.
	    # PI A single line, with semi-colon separated old identifiers
	    #
	    if ($code =~ /^(AC|ID|DE|AU|AL|PI)$/) {
		die "Multiple line entry with code '$code'" if ($lastCode eq $code);
		$entry->{$code} = $value;
	    } 
	    
	    # List-valued attributes
	    #
	    # RM MEDLINE UIs
	    # DR DB references
	    #
	    elsif ($code =~ /^(RM|DR)$/) {
		my $cur = $entry->{$code};

		if (not(defined($cur))) {
		    $entry->{$code} = [$value];
		} else {
		    push(@$cur, $value);
		}
	    }

	    # CC comment section; multiple lines
	    #
	    elsif ($code eq 'CC') {
		my $cur = $entry->{'CC'};

		if (not(defined($cur))) {
		    $entry->{'CC'} = $value;
		} else {
		    $entry->{'CC'} .= " " . $value;
		}
	    }

	    # Alignment -> end of entry
	    # 
	    elsif ($code eq 'SQ') {
		$entry->{'SQ'} = $value;  # number of sequences

		while(<PFAM>) {
		    
		    # End of entry
		    #
		    if (/^\/\/$/) {
			
			print STDERR "$numEntries: ", $entry->{'AC'}, "\n";

			# Write Pfam entry to the database
			#
			my $pe = GUS::Model::DoTS::PfamEntry->new();

			# Mandatory attributes
			#
			$pe->set('release', $release);
			$pe->set('accession', $entry->{'AC'});

			# escape single quotes
			#
			$entry->{'ID'} =~ s/'/''/g;
			$entry->{'DE'} =~ s/'/''/g;

			$pe->set('identifier', $entry->{'ID'});
			$pe->set('definition', $entry->{'DE'});
			$pe->set('number_of_seqs', $entry->{'SQ'});

			# Optional attributes
			#
			$pe->set('author', $entry->{'AU'}) if (defined($entry->{'AU'}));
			$pe->set('alignment_method', $entry->{'AL'}) if (defined($entry->{'AL'}));

			if (defined($entry->{'CC'})) {

			    # escape single quotes
			    #
			    $entry->{'CC'} =~ s/'/''/g;          # ' <- for syntax highlighter
			    $pe->set('comment_string', $entry->{'CC'});
			} 

                        print STDERR "  Submitting PfamEntry\n";

			$pe->submit() if (!$parseOnly);
			my $entryId = $pe->get('pfam_entry_id');
			my $links = {};

			# MEDLINE references
			#
			my $mrefs = $entry->{'RM'};
			my $mlDbId = &getExtDbRelId($extDbs, 'medline');

			foreach my $mref (@$mrefs) {
			    my($muid) = ($mref =~ (/^(\d+)$/));
			    
			    my $ref = $self->getDbRefId($dbrefSth, $parseOnly, $mlDbId, $muid);

			    my $link =
                              GUS::Model::DoTS::DbRefPfamEntry->new({'pfam_entry_id' => $entryId,
                                                                     'db_ref_id'     => $ref});

			    if (not(defined($links->{$ref}))) {
                                print STDERR "  Submitting DbRefPfamEntry for Medline\n";

				$link->submit() if (!$parseOnly);
				++$numRefs;
				$links->{$ref} = 1;
			    } elsif (!$parseOnly) {
				print STDERR "Duplicate reference to db_ref_id $ref from pfam_entry_id $entryId\n";
			    }
			}

			# Other database references
			#
			#        DR   EXPERT; jeisen@leland.stanford.edu;
			#        DR   MIM; 236200;
			#        DR   PFAMB; PB000001;
			#        DR   PRINTS; PR00012;
			#        DR   PROSITE; PDOC00017;
			#        DR   PROSITE_PROFILE; PS50225;
			#        DR   SCOP; 7rxn; sf;
			#        DR   SCOP; 1pii; fa;
			#        DR   PDB; 2nad A; 123; 332;
			#        DR   SMART; CBS;
			#        DR   URL; http://www.gcrdb.uthscsa.edu/;

			my $dbrefs = $entry->{'DR'};
			foreach my $dbref (@$dbrefs) {
			    my($db, $id, $rest) = ($dbref =~ /^([^;]+);\s*([^;]+);(.*)$/);
			    die "Unable to parse $dbref" if (not defined($id));
			    my $ref;

			    if ($db eq 'EXPERT') {
				$ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'Pfam expert'), $id);
			    }
			    elsif ($db eq 'MIM') {
				$ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'mim'), $id);
			    }
			    elsif ($db eq 'PFAMB') {
				$ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'Pfam-B'), $id);
			    }
			    elsif ($db eq 'PRINTS') {
				$ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'PRINTS'), $id);
			    }
			    elsif (($db eq 'PROSITE') || ($db eq 'PROSITE_PROFILE')) {
				$ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'prosite'), $id);
			    }
			    elsif ($db eq 'SCOP') {
				$ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'SCOP'), $id, undef, $rest);
			    }
			    elsif ($db eq 'PDB') {
				$ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'pdb'), $id, undef, $rest);
			    }
			    elsif ($db eq 'SMART') {
				$ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'SMART'), $id);
			    }
			    elsif ($db eq 'URL') {
				$ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'URL'), $id);
			    }
			    elsif ($db eq 'INTERPRO') {
				$ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'INTERPRO'), $id);
			    }
			    elsif ($db eq 'MEROPS') {
				$ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'MEROPS'), $id);
			    }
			    elsif ($db eq 'HOMSTRAD') {
				$ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'HOMSTRAD'), $id);
			    }
			    elsif ($db eq 'CAZY') {
                                $ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'CAZy'), $id);
			    }
			    elsif ($db eq 'LOAD') {
                                $ref = $self->getDbRefId($dbrefSth, $parseOnly, &getExtDbRelId($extDbs, 'LOAD'), $id);
			    }
			    else {
				print STDERR "WARNING - unrecognized database in external dbref: $db\n";
			    }

			    if (defined($ref)) {
                                my $link =
                                    GUS::Model::DoTS::DbRefPfamEntry->new({'pfam_entry_id' => $entryId,
                                                                           'db_ref_id'     => $ref});

				if (not(defined($links->{$ref}))) {
                                    print STDERR "  Submitting link for ",$ref->get('lowercase_secondary_id'),"\n";
				    $link->submit() if (!$parseOnly);
				    ++$numRefs;
				    $links->{$ref} = 1;
				} else {
				    print STDERR "Duplicate reference to db_ref_id $ref from pfam_entry_id $entryId\n";
				}
			    }
			}
			
			# Reset for next entry.
			#
			$entry = {};
			++$numEntries;
                        $self->undefPointerCache();
			next OUTER;
		    }
		}
	    }
	    $lastCode = $code;
	} 
    }
    close(PFAM);

    my $summary = undef;


    if ($parseOnly) {
	$summary = "Parsed $numEntries entries and $numRefs new database references from Pfam release $release.";
    } else {
	$summary = "Loaded $numEntries entries and $numRefs database references from Pfam release $release.";
    }
    print STDERR $summary, "\n";
    return $summary;
}

# ----------------------------------------------------------
# Other subroutines
# ----------------------------------------------------------

# Reads ExternalDatabase table into a hash indexed on 'name'
#
sub readExternalDbs_OLD_VERSION() {
    my($dbh) = @_;
    
    my $dbHash = {};
    my $sth = $dbh->prepare("select * from SRes.ExternalDatabase");
    $sth->execute();

    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
	my %copy = %$row;
	my $name = $row->{'name'};
	# normalize to lowercase
	$name =~ tr/A-Z/a-z/;
	$dbHash->{$name} = \%copy;
    }
    $sth->finish();
    return $dbHash;
}


# Reads ExternalDatabase and ExternalDatabaseRelease tables into a hash
# indexed on 'name' with value of the last release by date.
#
sub readExternalDbReleases() {
    my($self, $dbh) = @_;
    my $verbose     = $self->getCla->{'verbose'};

    print "In readExternalDbReleases()\n" if $verbose;

    my $dbHash = {};
    my $sth    = $dbh->prepare("select * from SRes.ExternalDatabase");
    $sth->execute();

    my $sth2   = $dbh->prepare("select * ".
                               "from   SRes.ExternalDatabaseRelease ".
                               "where  external_database_id = ? ".
                               "order by release_date desc");

    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
	my $name    = $row->{'name'};
        my $extDbId = $row->{'external_database_id'};

        # Make sure only the last release is fetched and used
        $sth2->execute($extDbId);
        my $exDbRelRow = $sth2->fetchrow_hashref('NAME_lc');
        my %copy       = %$exDbRelRow;

	# normalize to lowercase
	$name            =~ tr/A-Z/a-z/;
	$dbHash->{$name} = \%copy;
    }
    $sth->finish();
    return $dbHash;
}

# Return the external_db_id of an ExternalDatabase given its name.
#
# TO BE REMOVED

sub getExtDbId_OLD_VERSION {
    my($extDbs, $name) = @_;

    # Normalize to lowercase
    $name =~ tr/A-Z/a-z/;

    my $db = $extDbs->{$name};
    my $dbId = $db->{'external_db_id'} if defined($db);
    
    die "Unable to find ID for ExternalDatabase $name" if (not defined($dbId));
    return $dbId;
}

# Return the external_db_id of an ExternalDatabase given its name.
#
sub getExtDbRelId {
    my($extDbRels, $name) = @_;

    $name     =~ tr/A-Z/a-z/; # Normalize to lowercase

    my $db    = $extDbRels->{$name};
    my $relId = $db->{'external_database_release_id'} if defined($db);
    
    die "Unable to find ID for ExternalDatabase $name" if (not defined($relId));
    return $relId;
}

# Return the ID of a DbRef, if it already exists.  Otherwise
# create the DbRef and submit it before returning the newly-
# generated ID.
#
sub getDbRefId {
    my($self, $dbrefSth, $parseOnly, $extDbRelId, $primaryId, $secondaryId, $remark) = @_;

    my $verbose     = $self->getCla->{'verbose'};
    my $lcPrimaryId = $primaryId;
    $lcPrimaryId    =~ tr/A-Z/a-z/;
    
    my $ids = [];
    $dbrefSth->execute($extDbRelId, $lcPrimaryId);
    while (my($id) = $dbrefSth->fetchrow_array()) { push(@$ids, $id); }
    my $idCount = scalar(@$ids);

    #print STDERR "  getDbRefId: \$idCount = $idCount\n";

    # Not in the database; create and add a new entry
    #
    if ($idCount == 0) {
	my $dbRef = GUS::Model::SRes::DbRef->new({
	    'external_database_release_id' => $extDbRelId,
	    'primary_identifier'   => $primaryId,
	    'lowercase_primary_identifier' => $lcPrimaryId,
	});
	
	if (defined($secondaryId)) {
	    my $lcSecondaryId = $secondaryId;
	    $lcSecondaryId    =~ tr/A-Z/a-z/;
	    $dbRef->set('secondary_identifier',   $secondaryId);
	    $dbRef->set('lowercase_secondary_id', $lcSecondaryId);
	}

	$dbRef->set('remark', $remark) if (defined($remark));

        #print STDERR "  Submitting DbRef where \$extDbRelId = $extDbRelId, \$primaryId = $primaryId, \$lcPrimaryId = $lcPrimaryId\n";

	if ($parseOnly) {
	    return 1; 
	} else {
	    $dbRef->submit();
	    return $dbRef->get('db_ref_id');
	}
    }
    
    # One copy in the database
    #
    elsif ($idCount == 1) {
	return $ids->[0];
    }

    # Multiple copies in the database; use the first one and 
    # print a warning message
    #
    else {
	print STDERR "WARNING - multiple rows ($idCount) for DbRef with external_db_id=$extDbRelId, primary_id=$primaryId\n";
	return $ids->[0];
    }
}

1;


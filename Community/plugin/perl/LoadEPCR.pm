package GUS::Community::Plugin::LoadEPCR;


@ISA = qw(GUS::PluginMgr::Plugin);
use strict;
use GUS::Model::DoTS::EPCR;
use GUS::PluginMgr::Plugin;
use GUS::PluginMgr::PluginUtilities;
use FileHandle;
use DirHandle;

sub new {
  my ($class) = @_;

  my $self = {};
  bless($self,$class);



  my $purposeBrief = 'insert new Primer pairs using a  datafile';

  my $purpose = <<PLUGIN_PURPOSE;
This plugin parses and inserts a row for an EPCR result.  It uses a datafile in specified format, see NOTES.
PLUGIN_PURPOSE

  my $tablesAffected = 
    [['DoTS::EPCR','One row for a primer pair EPCR result']
    ];

  my $tablesDependedOn =
    [
    ];

  my $howToRestart = <<PLUGIN_RESTART;
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
=head2 <data_file>
The data file should be in tab-delimited format.  The columns should be in the following order:
seq_id: chromosome
location: on chromosome
map_id: id in maptableid
source_id
order: orientation on chromosome

PLUGIN_NOTES

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
     #stringArg({name => 'idcol',
		#descr => 'Name of column from NASequenceImp to search for external ids',
		#reqd => 1,	
		#constraintFunc => undef,
		#isList => 0,
     #}),
     fileArg({name => 'file',
	      reqd => 1,
	      descr => 'File name to load data from',
	      constraintFunc => undef,
	      mustExist =>1,
	      isList => 0,
	      format => 'see NOTES for requirements',
     }),
     integerArg({name => 'externalDatabaseReleaseId',
		 reqd => 1,
		 descr => 'external_database_release_id for genome and genome version used for epcr',
		 constraintFunc => undef,
		 isList => 0
     }),
     stringArg({name => 'dir',
		reqd => 1,	
		descr => 'Working directory',
		constraintFunc => undef,
		isList => 0
     }),
     fileArg({name => 'log',
	      reqd => 0,
	      descr => 'Log file location (full path).',
	      constraintFunc => undef,
	      mustExist =>0,
	      isList => 0,
	      format => 'inserted info?'
     }),
     integerArg({name => 'maptableid',
		   reqd => 1,
		   descr => 'Id for mapping table, i.e. 245 for DoTS::VirtualSequence ',
		   constraintFunc => undef,
		   isList => 0
     }),
     tableNameArg({name => 'seqsubclassview',
		   descr =>  'Subclass view: Assembly for DoTS, ExternalNASequence or VirtualSequence for others',
		   reqd => 1,
		   constraintFunc => undef,
		   isList => 0
     }),
     integerArg({name => 'testnumber',
		 reqd => 0,
		 descr => 'number of iterations for testing',
		 constraintFunc => undef,
		 isList => 0
     }),
     integerArg({name => 'start',
		 reqd => 0,
		 descr => 'Line number to start entering from',
		 constraintFunc => undef,
		 isList => 0
     }),
    ];

  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision: 3879 $', # cvs fills this in!
		     name => ref($self),
		     revisionNotes => 'make consistent with GUS 3.5',
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });


  return $self;
}

my $debug = 0;

sub run {
	my $self   = shift;
	my $args = $self->getArgs;
	my $algoInvo = $self->getAlgInvocation;

  print $args->{'commit'} ? "***COMMIT ON***\n" : "***COMMIT TURNED OFF***\n";
  print "Testing on $args->{'testnumber'}\n" if $args->{'testnumber'};

	############################################################
	# Put loop here...remember to undefPointerCache()!
	############################################################
	my ($fh,$dir,$file,$count,$log,$maptableid,$is_reversed,$extDbRelId);
	#$idcol = $args->{ idcol };
	$dir = $args->{ dir };
	$file = $args->{ file };
	$fh = new FileHandle("$file", "<") || die "File $dir$file not open";
	$log = new FileHandle("$args->{ log }", ">") || die "Log not open";
        $maptableid = $args->{maptableid};
	my ($space, $subclassView) = split(/::/,$args->{seqsubclassview});	

	my $oracleName = $self->className2oracleName($args->{seqsubclassview});
	$extDbRelId = $args->{externalDatabaseReleaseId};	
	while (my $l = $fh->getline()) {
		$count++;

		## Start seq_id; parese file until it is reached
		next if (defined $args->{ start } && $args->{ start } > $count);

		## Only interested sequence id, location, position, and map id 
		#my ($seq_id, $loc, $order, $map_id) = split(/\s+/,$l);  #old version of plugin
		my ($seq_id, $loc, $map_id, $source_id, $order) = split(/\s+/,$l); 
		$order =~ s/\(|\)//g;
                if ($order eq "+")
		{
		$is_reversed = 0;
		}
		else {
		$is_reversed = 1;
		}
	
		## Split location into start and stop
		my @locs = split /\.\./, $loc;
                

		## Build entry
		my $sgm = GUS::Model::DoTS::EPCR->new( {'start_pos' => $locs[0], 'stop_pos' => $locs[1]});
			$sgm->setIsReversed($is_reversed);
			$sgm->setMapId($map_id);
		
		## Grab na_sequence_id
		my $naid;
		$seq_id =~ s/^DT\.//;
		$seq_id="'".$seq_id."'";
		# get na_sequence_id from seq_subclass_view

		my $sql = qq[SELECT distinct sv.na_sequence_id FROM $oracleName sv
			     WHERE sv.external_database_release_id  = $extDbRelId
			     AND sv.source_id = $seq_id];


		my @na_seq_id = @{$self->sql_get_as_array($sql)};
		$naid = $na_seq_id[0];


		if (defined $naid){
			$sgm->setNaSequenceId($naid);
		}else {
			$log->print("No na_seq_id: $l\n");
			$algoInvo->undefPointerCache();
			next;
		}
                $sgm->setMapTableId($maptableid);
		$sgm->setSeqSubclassView($subclassView);

		## Submit entry
		$log->print("SUBMITTED: $maptableid\t$map_id\t$is_reversed\t$locs[0]\t$locs[1]\t$naid\t$count\n");
		$sgm->submit();

		$algoInvo->undefPointerCache();
		last if (defined $args->{testnumber} && $count >= $args->{testnumber});
		print STDERR "ENTERED: $count \n" if ($count % 1000 == 0);
	} #end while()

	print STDERR "ENTERED: $count\n";
	return "Entered $count.";
}



1;

__END__

=pod
=head1 Description
B<LoadEPCR> - Parses epcr output files for EPCR table in GUS. No notion of updates currently

=head1 Purpose
Parses epcr output files for EPCR table in GUS. No notion of updates currently

=cut

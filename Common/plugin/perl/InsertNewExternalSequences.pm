package GUS::Common::Plugin::InsertNewExternalSequences;

@ISA = qw(GUS::PluginMgr::Plugin); 
use strict;


sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $usage = 'insert new ExternalSequences (NA or AA) from a FASTA file';
  my $easycsp =
    [{o => 'testnumber=i',
      h => 'number of iterations for testing',
     },
     {o => 'writeFile',
      t => 'string',
      h => 'writes a sequence file of the new entries',
     },
     {o => 'external_database_release_id=i',
      h => 'ExternalDatabase release id for these sequences',
     },
     {o => 'log_frequency=i',
      h => 'frequency to print log',
      d => 10,
     },
     {o => 'sequence_type_id=i',
      h => 'sequence type id for these sequences',
     },
     {o => 'taxon_id=i',
      h => 'taxon id for these sequences',
     },
     {o => 'sequencefile=s',
      h => 'name of file containing the sequences',
     },
     {o => 'no_sequence!',
      h => 'if on command line, will not set sequence',
     },
     {o => 'regex_source_id=s',
      h => 'regular expression to pick the source_id of the sequence from the defline',
     },
     {o => 'regex_secondary_id=s',
      h => 'regular expression to pick the secondary id of the sequence from the defline',
     },
     {o => 'regex_name=s',
      h => 'regular expression to pick the name of the sequence from the defline',
     },
     {o => 'regex_desc=s',
      h => 'regular expression to pick the description of the sequence from the defline',
     },
     {o => 'regex_chromosome=s',
      h => 'regular expression to pick the chromosome from the defline',
     },
     {o => 'regex_mol_wgt=s',
      h => 'regular expression to pick the molecular weight of the sequence from the defline',
     },
     {o => 'regex_contained_seqs=s',
      h => 'regular expression to pick the number of contained sequences from the defline',
     },
     {o => 'table_name=s',
      h => 'Table name to insert sequences into',
      e => [ qw( DoTS::ExternalNASequence DoTS::VirtualSequence DoTS::ExternalAASequence DoTS::MotifAASequence) ],
     },
     {o => 'update',
      t => 'boolean',
      h => 'if true, checks to see if row is updated...',
     },
     {o => 'update_longest',
      t => 'boolean',
      h => 'if true, checks to see if sequence is longer than that currently loaded, if so, updates the entry...',
     },
     {o => 'no_check',
      t => 'boolean',
      h => 'if true, does NOT check to see if external_database_release_id,source_id is already in db...',
     },
     {o => 'startAt',
      t => 'integer',
      h => 'ignores entries in fasta file prior to this number...',
     },
    ];

  $self->initialize({requiredDbVersion => {},
		     cvsRevision => '$Revision$', # cvs fills this in!
		     cvsTag => '$Name$', # cvs fills this in!
		     name => ref($self),
		     revisionNotes => 'make consistent with GUS 3.0',
		     easyCspOptions => $easycsp,
		     usage => $usage
		    });
  return $self;
}

my $countInserts = 0;
my $ctx;
my $checkStmt;
my $prim_key;
$| = 1;

sub run {
  my $M   = shift;
  $ctx = shift;

  if (!$ctx->{'external_database_release_id'} || !-e "$ctx->{'sequencefile'}" || !$ctx->{cla}->{table_name}) {
    die "you must provide --external_database_release_id, --table_name and valid fasta sequencefile on the command line\n";
  }
  
  print $ctx->{'commit'} ? "*** COMMIT ON ***\n" : "*** COMMIT TURNED OFF ***\n";
  print "Testing on $ctx->{'testnumber'}\n" if $ctx->{'testnumber'};

  eval("require GUS::Model::".$ctx->{cla}->{table_name});

  ##open sequence file
  if ($ctx->{'sequencefile'} =~ /gz$/) {
    open(F, "gunzip -c $ctx->{'sequencefile'} |");
  } else {
    open(F,"$ctx->{'sequencefile'}");
  }

  # get primary key for table_name
  $prim_key = $ctx->{self_inv}->getTablePKFromTableId($ctx->{self_inv}->getTableIdFromTableName($ctx->{cla}->{table_name}));

  if ($ctx->{cla}->{writeFile}) {
    open(WF,">>$ctx->{cla}->{writeFile}");
  }

  if ($ctx->{cla}->{table_name} eq 'DoTS::VirtualSequence') {
    $ctx->{cla}->{sequence_type_id} = 20;
  }

  #	my $sql = "select $prim_key from ExternalNASequence where source_id = '$source_id' and external_db_id = $ctx->{'external_db_id'}";
  $ctx->{cla}->{table_name} =~ /(\w+)::(\w+)/ || die "table_name not in schema::table format";
  my ($sc, $tbl) = ($1, $2);
  $checkStmt = $ctx->{self_inv}->getQueryHandle()->prepare("select $prim_key from $sc.$tbl where source_id = ? and external_database_release_id = $ctx->{'external_database_release_id'}");

  my $source_id;
  my $name;
  my $description;
  my $secondary_id;
  my $chromosome;
  my $mol_wgt;
  my $contained_seqs;
  my $seq;
  my $count = 0;
  my $countGets = 0;
  my $start = 1;
  while (<F>) {
    if (/^\>/) {                ##have a defline....need to process!

      ##following must be in loop to allow garbage collection...
      $ctx->{'self_inv'}->undefPointerCache();

      last if($ctx->{'testnumber'} && $count > $ctx->{'testnumber'});

      $count++;

      next if ($ctx->{cla}->{startAt} && $count < $ctx->{cla}->{startAt});

      &process($source_id,$secondary_id,$name,$description,$mol_wgt,$contained_seqs,$chromosome,$seq) if ($source_id);

      print STDERR "$source_id  $count, inserted ".($ctx->{self_inv}->getTotalInserts() - 1)." and updated ".$ctx->{self_inv}->getTotalUpdates() ." " . ($count % ($ctx->{cla}->{log_frequency} * 10) == 0 ? `date` : "\n") if $count % $ctx->{cla}->{log_frequency} == 0;

      ##now get the ids etc for this defline...
      if (/$ctx->{'regex_source_id'}/) { 
        $source_id = $1; 
      } else {
        print STDERR "ERROR: unable to parse source_id from $_"; $source_id = "";
      }

      $secondary_id = ""; $name = ""; $description = ""; $mol_wgt = ""; $contained_seqs= ""; $chromosome="";##in case can't parse out of this defline...
      if ($ctx->{'regex_secondary_id'} && /$ctx->{'regex_secondary_id'}/) {
        $secondary_id = $1;
      }
      if ($ctx->{'regex_name'} && /$ctx->{'regex_name'}/) {
        $name = $1;
      }
      if ($ctx->{'regex_chromosome'} && /$ctx->{'regex_chromosome'}/) {
        $chromosome = $1;
      }
      if ($ctx->{'regex_desc'} && /$ctx->{'regex_desc'}/){ 
        $description = $1; 
      }
      if($ctx->{'regex_mol_wgt'} && /$ctx->{'regex_mol_wgt'}/){ 
        $mol_wgt = $1; 
      }
      if($ctx->{'regex_contained_seqs'} && /$ctx->{'regex_contained_seqs'}/){ 
        $contained_seqs = $1; 
      }

			##reset the sequence..
			$seq = "";
		}else{
			$seq .= $_;
		}
	}
	&process($source_id,$secondary_id,$name,$description,$mol_wgt,$contained_seqs,$chromosome,$seq) if ($source_id);


	# return status
	# ........................................
	
  my $res = "Run finished: Processed $count, inserted ".($ctx->{self_inv}->getTotalInserts() - 1)." and updated ".$ctx->{self_inv}->getTotalUpdates()." sequences from file $ctx->{'sequencefile'}";
  print STDERR "$res\n";
  return $res;
}

##SUBS

sub process {
	my($source_id,$secondary_id,$name,$description,$mol_wgt,$contained_seqs,$chromosome,$sequence) = @_;
#  print STDERR "process($source_id,$secondary_id,$name,$description,$sequence)\n";
  my $id;
	$id = &checkIfHave($source_id) unless $ctx->{cla}->{no_check};
  my $aas;
  if($id && $ctx->{cla}->{update}){
    my $className = "GUS::Model::$ctx->{cla}->{table_name}";
    $aas = $className->new({$prim_key => $id});
    $aas->retrieveFromDB();
    $aas->setSecondaryIdentifier($secondary_id) unless !$secondary_id || $aas->getSecondaryIdentifier() eq $secondary_id;
    $aas->setDescription($description) unless !$description || $aas->getDescription() eq $description;
    $aas->setName($name) unless !$name || $aas->getName() eq $name;
    $aas->setChromosome($chromosome) unless !$chromosome || $aas->getChromosome() eq $chromosome;
    $aas->setMolecularWeight($mol_wgt) unless ((!$aas->isValidAttribute('molecular_weight')) || (!$mol_wgt || $aas->getMolecularWeight() eq $mol_wgt));  
    $aas->setNumberOfContainedSequences($contained_seqs) unless ((!$aas->isValidAttribute('number_of_contained_sequences')) || (!$contained_seqs || $aas->getNumberOfContainedSequences() eq $contained_seqs));  
    $aas->setSequence($sequence) if $sequence;
  }else{
    return if $id; ##already have and am not updating..
    $aas = &createNewExternalSequence($source_id,$secondary_id,$name,$description,$chromosome,$mol_wgt,$contained_seqs,$sequence);
  }
  $aas->submit() if $aas->hasChangedAttributes();
	if($ctx->{cla}->{'writeFile'}){
		print WF ">",$aas->getId()," $source_id $description\n$sequence\n";
	}
	$countInserts++;
}


sub createNewExternalSequence {
	my($source_id,$secondary_id,$name,$description,$chromosome,$mol_wgt,$contained_seqs,$sequence) = @_;
	my $className = "GUS::Model::$ctx->{cla}->{table_name}";
	$className =~ /GUS::Model::\w+::(\w+)/ || die "can't parse className";
	my $tbl = $1;

	my $aas = $className->
	  new({'external_database_release_id' => $ctx->{cla}->{'external_database_release_id'},
	       'source_id' => $source_id,
	       'subclass_view' => $tbl });
	if($secondary_id && $aas->isValidAttribute('name')){ $aas->set('secondary_identifier',$secondary_id);}
	if ($aas->isValidAttribute('sequence_type_id')) {
    $aas->setSequenceTypeId($ctx->{cla}->{'sequence_type_id'} ? $ctx->{cla}->{'sequence_type_id'} : 11);
  }
	#if($ctx->{cla}->{'taxon_id'}){ $aas->setTaxonId($ctx->{cla}->{'taxon_id'});}
  if($ctx->{cla}->{'taxon_id'}){ 
    if ($aas->isValidAttribute('taxon_id')){
      $aas->setTaxonId($ctx->{cla}->{'taxon_id'});
    }elsif ($ctx->{cla}->{table_name} eq 'DoTS::ExternalAASequence'){
      eval ("require GUS::Model::DoTS::AASequenceTaxon");
      my $aast =  GUS::Model::DoTS::AASequenceTaxon->
	new({taxon_id => $ctx->{cla}->{'taxon_id'}});
      $aas->addChild($aast);
    }else{
      print STDERR "Cannot set taxon_id for table_name " . $ctx->{cla}->{table_name} . "\n";
    }
  }   
	if($description){ 
		$description =~ s/\"//g; $description =~ s/\'//g;
		$aas->set('description',substr($description,0,255)); 
	}
	if($name && $aas->isValidAttribute('name') ){ 
		$name =~ s/\"//g; $name =~ s/\'//g;
		$aas->set('name',$name);
	}
	if($chromosome && $aas->isValidAttribute('chromosome') ){ 
		$aas->setChromosome($chromosome);
	}
  if($mol_wgt && $aas->isValidAttribute('molecular_weight')){ 
		$aas->setMolecularWeight($mol_wgt); 
	}
  if($contained_seqs && $aas->isValidAttribute('number_of_contained_sequences')){ 
		$aas->setNumberOfContainedSequences($contained_seqs); 
	}
	if($sequence && !$ctx->{'no_sequence'}){
		$aas->setSequence($sequence);
	}
	print STDERR $aas->toString() if $ctx->{'debug'};
	return $aas;
}
 
sub checkIfHave {
	my($source_id) = @_;
	$checkStmt->execute($source_id);
	if(my($id) = $checkStmt->fetchrow_array()){
		print STDERR "Entry already inserted for '$source_id'\n" unless $ctx->{cla}->{update};
		$checkStmt->finish();
		return $id;
	}
	return 0;
}


1;

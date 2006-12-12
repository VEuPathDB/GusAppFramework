package GUS::Community::Plugin::InsertPrimerPairExternalNASequence;

@ISA = qw(GUS::PluginMgr::Plugin); 
use strict;
use GUS::PluginMgr::Plugin;
use GUS::Model::DoTS::SequenceType;
use GUS::Model::SRes::SequenceOntology;
use GUS::Model::DoTS::ExternalNASequence;
use GUS::Model::DoTS::SequencePiece;
use GUS::Model::DoTS::VirtualSequence;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $purposeBrief = 'insert new Primer pairs and their predicted amplicons using a  datafile';;

  my $purpose = <<PLUGIN_PURPOSE;
This plugin inserts primer pairs and their predicted amplicons. Primers are are inserted into SequencePiece and ExternalNASequence. One row is inserted for each primer.  One row for the predicted amplicon for the primer pair is inserted into VirtualSequence.  This plugin uses a datafile in specified format, see NOTES.
PLUGIN_PURPOSE

  my $tablesAffected = 
    [['DoTS::ExternalNASequence','One row for each primer (2 rows per primer pair)'],
     ['DoTS::SequencePiece','One row for each primer (2 rows per primer pair)'],
     ['DoTS::VirtualSequence','One for each predicted amplicon']
    ];

  my $tablesDependedOn =
    [
    ];

  my $howToRestart = <<PLUGIN_RESTART;
This plugin has no restart facility.
PLUGIN_RESTART

  my $failureCases = <<PLUGIN_FAILURE_CASES;
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
=head2 <data_file>
The data file should be in tab-delimited format.  The columns should be in the following order:
external_db_rel_id
taxon_id
source_id: amplicon source_id, will also be used as prefix for primer source_ids
amplicon_description: will also be used in primer description
forward_primer: sequence of left primer
reverse_primer: sequence of right primer
forward_primer_length: length of left primer
reverse_primer_length: length of right primer
amplicon_sequence: representative product sequence
amplicon_length: length of predicted amplicon
All columns are required.

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
       integerArg({name => 'testnumber',
                   descr => 'number of iterations for testing',
                   reqd => 0,
                   constraintFunc => undef,
                   isList => 0
                  }),
      
       fileArg({name => 'dataFile',
                descr => 'Data file',
                reqd => 1,
                mustExist => 1,
                constraintFunc => undef,
                isList => 0,
                format => 'see NOTES for format requirements of the datafile'

               }),

       fileArg({name => 'writeFile',
                descr => 'records new entries',
                reqd => 0,
                mustExist => 0,
                constraintFunc => undef,
                isList => 0,
                format => 'list of rows inserted into table'
               }),

       stringArg({name => 'soCvsVersion',
                  descr => 'SequenceOntology cvs version currently used',
                  reqd => 1,
                  mustExist => 1,
                  constraintFunc => undef,
                  isList => 0
                 }),

       enumArg({name => 'AmpliconType',
                descr => 'Dots::SequenceType.name for the PCR Products generated.  ss-DNA for spotted DNA microarrays.',
                constraintFunc => undef,
                reqd => 1,
                isList => 0,
                mustExist => 1,
                enum => "ss-DNA, ds-DNA",
               }),
      ];

  $self->initialize({requiredDbVersion => 3.5,
                     cvsRevision => '$Revision: 4233 $', # cvs fills this in!
                     name => ref($self),
                     argsDeclaration => $argsDeclaration,
                     documentation => $documentation
                    });
  return $self;
}

#my $countInserts = 0;
#my $ctx;
#my $checkStmt;
#my $prim_key;
$| = 1;


sub run {

  my ($self) = @_;

  my $algInv = $self->getAlgInvocation();
  my $dbh = $self->getDb()->getDbHandle();

  print $self->getArg('commit') ? "*** COMMIT ON ***\n" : "*** COMMIT TURNED OFF ***\n";
  print "Testing on " . $self->getArg('testnumber') . "\n" if $self->getArg('testnumber');

 if ($self->getArg('writeFile')) {
    open(WF,">>" . $self->getArg('writeFile'));
  }

  my $count = 0;

  my $dataFile = $self->getArg('dataFile');
  my $so_cvs_version = $self->getArg('soCvsVersion');
  $count = $self->processPrimerPairFile($dataFile,$so_cvs_version);

  my $result = "Processed $count rows of datafile\n";

  return $result;


}

sub processPrimerPairFile{

  my ($self, $dataFile, $so_cvs_version) = @_;

  open(F,"$dataFile") || die "Can't open $dataFile for reading";


  my $external_db_rel_id;
  my $taxon_id;

  # Amplicon info
  my $name;
  my $source_id;
  my $amplicon_desc;
  my $amplicon_length;
  my $amplicon_seq;

  # Primer info for ExternalNASequence
  my $for_primer;
  my $rev_primer;
  my $for_primer_length;
  my $rev_primer_length;

  my $count = 0;
  my $countGets = 0;
  my $start = 1;

  while (<F>) {
	    
    ##following must be in loop to allow garbage collection...
    $self->undefPointerCache();
    last if($self->getArg('testnumber') && $count > $self->getArg('testnumber'));
    chomp;
    $count++;
    ($external_db_rel_id,$taxon_id,$source_id,$amplicon_desc,$for_primer,$rev_primer,$for_primer_length,$rev_primer_length,$amplicon_seq,$amplicon_length) = split(/\t/,$_);

    die "Incorrect number of columns" 
      unless  (($external_db_rel_id)&&($source_id)&&($amplicon_desc)&&($for_primer)&&($rev_primer)&&($for_primer_length)&&($rev_primer_length)&&($amplicon_length)&&($amplicon_seq)&&($taxon_id));

    $self->processPrimerPair($external_db_rel_id,$source_id,$amplicon_desc,$for_primer,$rev_primer,$for_primer_length,$rev_primer_length,$amplicon_length,$amplicon_seq,$taxon_id,$so_cvs_version);

	
  }

  return $count;

}


sub processPrimerPair{

  my ($self,$ext_db_rel_id,$source_id,$desc,$for_primer,$rev_primer,$for_primer_length,$rev_primer_length,$amplicon_length,$amplicon_seq,$taxon_id,$so_cvs_version) = @_;

  my $amplicon_seq_version = 1;
  my $primer_seq_version = 1;

  # Primer info for SequencePiece
  my $for_seq_order = 1;
  my $rev_seq_order = 2;
  my $for_dist_from_left = 0;
  #my $rev_dist_from_left; # ????
  my $for_strand = "forward";
  my $rev_strand = "reverse";

  #my $so_cvs_version = "1.35";

  #my $amplicon_type = "ss-DNA";
  my $amplicon_type = $self->getArgs()->{AmpliconType};
  my $aSequenceType = GUS::Model::DoTS::SequenceType->new({'name' => $amplicon_type});
  $aSequenceType->retrieveFromDB() || die "Unable to obtain sequence_type_id from DoTS.sequencetype with name = $amplicon_type";
  my $amplicon_seq_type_id= $aSequenceType->getId();

  my $amplicon_ont = "PCR_product";
  my $aSequenceOntId = GUS::Model::SRes::SequenceOntology->new({ 'term_name' => $amplicon_ont, 'so_cvs_version' => $so_cvs_version });
  #my $aSequenceOntId = GUS::Model::SRes::SequenceOntology->new({ 'term_name' => $amplicon_ont });
  $aSequenceOntId->retrieveFromDB() || die "Unable to obtain sequence_ontology_id from sres.sequenceontology with term_name = $amplicon_ont";
  my $amplicon_seq_ontology_id= $aSequenceOntId->getId();
  $desc=~s/\"//g;

  #print "amplicon:<$amplicon_seq_version>\t<$desc>\t<$amplicon_seq_type_id>\t<$amplicon_seq_ontology_id>\t<$taxon_id>\t<$amplicon_seq>\t<$amplicon_length>\t<$ext_db_rel_id>\t<$source_id>\n";

  my $amplicon = GUS::Model::DoTS::VirtualSequence->new
    ({'sequence_version'=>$amplicon_seq_version,
      'description'=>$desc,
      'sequence_type_id'=>$amplicon_seq_type_id,
      'sequence_ontology_id'=>$amplicon_seq_ontology_id, 
      'taxon_id'=>$taxon_id,
      'sequence'=>$amplicon_seq,
      'length'=>$amplicon_length,
      'external_database_release_id'=>$ext_db_rel_id,
      'source_id'=>$source_id});
  $amplicon->submit();


  my $primer_type = "oligonucleotide";
  my $pSequenceType = GUS::Model::DoTS::SequenceType->new({"name" => $primer_type});
  $pSequenceType->retrieveFromDB() || die "Unable to obtain sequence_type_id from DoTS.sequencetype with name = $primer_type";
  my $primer_seq_type_id= $pSequenceType->getId();

  my $for_primer_ont = "forward_primer";
  my $fSequenceOntId = GUS::Model::SRes::SequenceOntology->new({ 'term_name' => $for_primer_ont, 'so_cvs_version' => $so_cvs_version  });
  $fSequenceOntId->retrieveFromDB() || die "Unable to obtain sequence_ontology_id from sres.sequenceontology with term_name = $for_primer_ont";
  my $for_seq_ontology_id= $fSequenceOntId->getId();

  my $for_desc = "forward primer for ".$desc; #???
  my $for_source_id = $source_id."_F";
  my $for_name = "forward primer for ".$source_id; #???

  #print "for_primer:<$primer_seq_version>\t<$for_desc>\t<$primer_seq_type_id>\t<$for_seq_ontology_id>\t<$taxon_id>\t<$for_primer>\t<$for_primer_length>\t<$ext_db_rel_id>\t<$for_source_id>\t<$for_name>\n";

  my $fprimer  = GUS::Model::DoTS::ExternalNASequence->new
    ({'sequence_version'=>$primer_seq_version,
      'sequence_type_id'=>$primer_seq_type_id,
      'external_database_release_id'=>$ext_db_rel_id,
      'sequence_ontology_id'=>$for_seq_ontology_id, 
      'taxon_id'=>$taxon_id,
      'sequence'=>$for_primer,
      'length'=>$for_primer_length,
      'description'=>$for_desc,
      'source_id'=>$for_source_id,
      'name'=>$for_name}
    );


  my $rev_primer_ont = "reverse_primer";
  my $rSequenceOntId = GUS::Model::SRes::SequenceOntology->new({ 'term_name' => $rev_primer_ont, 'so_cvs_version' => $so_cvs_version  });
  $rSequenceOntId->retrieveFromDB() || die "Unable to obtain sequence_ontology_id from sres.sequenceontology with term_name = $rev_primer_ont";
  my $rev_seq_ontology_id= $rSequenceOntId->getId();

  my $rev_desc = "reverse primer for ".$desc; # ????
  my $rev_source_id = $source_id."_R";
  my $rev_name = "reverse primer for ".$source_id; #???
  my $rev_dist_from_left = ($amplicon_length - $rev_primer_length + 1); #???

  #print "rev_primer:<$primer_seq_version>\t<$rev_desc>\t<$primer_seq_type_id>\t<$rev_seq_ontology_id>\t<$taxon_id>\t<$rev_primer>\t<$rev_primer_length>\t<$ext_db_rel_id>\t<$rev_source_id>\t<$rev_name>\n";

  my $rprimer  = GUS::Model::DoTS::ExternalNASequence->new
    ({'sequence_version'=>$primer_seq_version,
      'sequence_type_id'=>$primer_seq_type_id,
      'external_database_release_id'=>$ext_db_rel_id,
      'sequence_ontology_id'=>$rev_seq_ontology_id,
      'taxon_id'=>$taxon_id,
      'sequence'=>$rev_primer,
      'length'=>$rev_primer_length,
      'description'=>$rev_desc,
      'source_id'=>$rev_source_id,
      'name'=>$rev_name}
    );

  $fprimer->submit();
  $rprimer->submit();
  
  #print "fpiece:<$for_seq_order>\t<$for_dist_from_left>\t<$for_strand>\n";
  #print "rpiece:<$rev_seq_order>\t<$rev_dist_from_left>\t<$rev_strand>\n";

  my $fpiece   = GUS::Model::DoTS::SequencePiece->new
    ({'virtual_na_sequence_id' => $amplicon->getId(),
      'piece_na_sequence_id' => $fprimer->getId(),
      'sequence_order'=>$for_seq_order,
      'distance_from_left'=>$for_dist_from_left,
      'strand_orientation'=>$for_strand});

  my $rpiece   = GUS::Model::DoTS::SequencePiece->new
    ({'virtual_na_sequence_id' => $amplicon->getId(),
      'piece_na_sequence_id' => $rprimer->getId(),
      'sequence_order'=>$rev_seq_order,
      'distance_from_left'=>$rev_dist_from_left,
      'strand_orientation'=>$rev_strand}); 

  $fpiece->submit();
  $rpiece->submit();

  if ($self->getArg('writeFile')) {
    #print WF $fprimer->getId(),"\t" ,$rprimer->getId(),"\t", $fpiece->getId(),"\t", $rpiece->getId(),"\t", $amplicon->getId(),"\n";
    print WF $fprimer->getId(), "\t$primer_seq_version\t$for_desc\t$primer_seq_type_id\t$for_seq_ontology_id\t$taxon_id\t$for_primer\t$for_primer_length\t$ext_db_rel_id\t$for_source_id\t$for_name\t";
    print WF $rprimer->getId(), "\t$primer_seq_version\t$rev_desc\t$primer_seq_type_id\t$rev_seq_ontology_id\t$taxon_id\t$rev_primer\t$rev_primer_length\t$ext_db_rel_id\t$rev_source_id\t$rev_name\t";
    print WF $fpiece->getId(), "\t$for_seq_order\t$for_dist_from_left\t$for_strand\t";
    print WF $rpiece->getId(), "\t$rev_seq_order\t$rev_dist_from_left\t$rev_strand\t";
    print WF $amplicon->getId(), "\t$amplicon_seq_version\t$desc\t$amplicon_seq_type_id\t$amplicon_seq_ontology_id\t$taxon_id\t$amplicon_seq\t$amplicon_length\t$ext_db_rel_id\t$source_id\n";

  }

}


1;

package GUS::Common::Plugin::GBParser;

@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use FileHandle;
use DBI;

use CBIL::Bio::GenBank::Entry;
use CBIL::Bio::GenBank::IoStream;
use CBIL::Bio::GenBank::ArrayStream;

## Standard tables
use GUS::Model::DoTS::NASequence; ## View -> NASequenceImp
use GUS::Model::DoTS::ExternalNASequence; ## View -> NASequenceImp
use GUS::Model::DoTS::NAComment;
use GUS::Model::DoTS::NAEntry;
use GUS::Model::DoTS::NALocation;
use GUS::Model::DoTS::NAGene;
use GUS::Model::DoTS::NAProtein;
use GUS::Model::DoTS::NAPrimaryTranscript;
use GUS::Model::SRes::DbRef;
use GUS::Model::SRes::ExternalDatabase;
use GUS::Model::SRes::ExternalDatabaseRelease;
use GUS::Model::DoTS::Keyword;
use GUS::Model::DoTS::Organelle;
use GUS::Model::SRes::Reference;
use GUS::Model::DoTS::SecondaryAccs;
use GUS::Model::DoTS::SequenceType;
use GUS::Model::SRes::Taxon;
use GUS::Model::SRes::TaxonName;
use GUS::Model::DoTS::NAFeatureComment;

## many-to-many
use GUS::Model::DoTS::NASequenceRef;
use GUS::Model::DoTS::NASequenceOrganelle;
use GUS::Model::DoTS::NASequenceKeyword; 
use GUS::Model::DoTS::NAFeatureNAGene;
use GUS::Model::DoTS::NAFeatureNAPT;
use GUS::Model::DoTS::NAFeatureNAProtein;
use GUS::Model::DoTS::DbRefNAFeature; 
use GUS::Model::DoTS::DbRefNASequence; 
use GUS::Model::SRes::ExternalDatabaseKeyword; 

## NAFeature and assoc. views
use GUS::Model::DoTS::NAFeatureImp;
use GUS::Model::DoTS::NAFeature;
use GUS::Model::DoTS::DNARegulatory;
use GUS::Model::DoTS::DNAStructure;
use GUS::Model::DoTS::STS;
use GUS::Model::DoTS::GeneFeature;
use GUS::Model::DoTS::RNAType;
use GUS::Model::DoTS::Repeats;
use GUS::Model::DoTS::Miscellaneous;
use GUS::Model::DoTS::Immunoglobulin;
use GUS::Model::DoTS::ProteinFeature;
use GUS::Model::DoTS::SeqVariation;
use GUS::Model::DoTS::RNAStructure;
use GUS::Model::DoTS::Source;
use GUS::Model::DoTS::Transcript;
use GUS::Model::DoTS::ExonFeature;

my $Cfg;			##global configuration object....passed into constructor as second arg
sub new {
  my ($class) = @_;
    
  my $self = {};
  bless($self,$class);
    
  my $usage = 'Module used to parse GenBank records into the DB';
    
  my $easycsp =
    [{o => 'gbRel',
      t => 'string',
      h => 'GenBank release',
     },
     {o => 'updateAll',
      t => 'boolean',
      h => 'Update ALL entries, regardless of release date',
     },
     {o => 'file',
      t => 'string',
      h => 'GenBank formatted file to read',
     },
     {o => 'db_rel_id',
      t => 'int',
      h => 'GUS ExternalDatabaseRelease id.',
     },
     {o => 'start',
      t => 'int',
      h => 'Entry number in specified file to start at.',
     },
     {o => 'testnumber',
      t => 'int',
      h => 'number of iterations for testing',
     },
     {o => 'div',
      t => 'string',
      h => 'OPTIONAL: If given, entries will be filtered on DIV. (Ex: div="PRI")',
     },
    ];
    
#     {o => 'failDir',
 #     t => 'string',
  #    h => 'directory to write failed entries and their error messages',
   #  },
    # {o => 'failTolerance',
     # t => 'int',
  #    h => 'number of entries that can fail before aborting',
   #   d => '100'
    # }
  $self->initialize({requiredDbVersion => {},
		     cvsRevision => '$Revision$',	# cvs fills this in!
		     cvsTag => '$Name$', # cvs fills this in!
		     name => ref($self),
		     revisionNotes => 'make consistent with GUS 3.0',
		     easyCspOptions => $easycsp,
		     usage => $usage
		    });
    
  return $self;
}

my $ctx;
my $debug = 0;


#---------------------------------------------------------
# Setup global hashes to cache the tables for controlled vocabulatory
#---------------------------------------------------------
#whole table caching
my (%OrganelleCache, %ExternalDatabaseRelHash, %KeywordHash, %SequenceTypeHash); 
#on-demand caching
my ( %KeywordCache, $NaGeneCache, %TaxonHash, %MedlineCache,%DbRefCache,%featureCache, %NAGeneCache, %NaProteinCache);

sub run {
  $| = 1;	

  my $M  = shift;
  $ctx = shift;
  if (!$ctx->{cla}->{gbRel}) {
    die "--gbRel is a required argument. See --help option\n";
  }
  if (!$ctx->{cla}->{file}) {
    die "--file is a required argument. See --help option\n";
  }
  $ctx->{cla}->{failDir} = "/home/sfischer/gbtest";
  $ctx->{cla}->{failTolerance} = 100;
  if (!$ctx->{cla}->{failDir}) {
    die "--failDir is a required argument. See --help option\n";
  }
  mkdir $ctx->{cla}->{failDir} || die "Can't mkdir $ctx->{cla}->{failDir} (--failDir)";

  $M->logCommit();
  $M->logAlert("", "Testing on $ctx->{cla}->{'testnumber'}") if $ctx->{ cla }->{'testnumber'};

  $ctx->{ self_inv }->setMaximumNumberOfObjects(50000);
  &setWholeTableCache();
  my $fh  = $ctx->{cla}->{file} =~ /\.gz$|\.Z$/ ?
    FileHandle->new( "zcat $ctx->{cla}->{file}|" )
      : FileHandle->new( '<'. $ctx->{cla}->{file} );
  
  die "Can't open file $ctx->{cla}->{file}" unless $fh;

  $M->logAlert("RELEASE", "$ctx->{ cla }->{ gbRel }\n");
  $M->logAlert("FILE", "$ctx->{ cla }->{ file }\n");
  if ($ctx->{ cla }->{ start }) {
    $M->logAlert("START", "$ctx->{ cla }->{ start }\n");
  }

  $M->{entryCnt} = 0;
  $M->{updateCnt} = 0;
  $M->{insertCnt} = 0;
  $M->{failCnt} = 0;

  while ( my $entryLines = &getEntryLines($fh)) {
    last unless scalar (@$entryLines);
    $M->{entryCnt}++;
    my $entryStream = CBIL::Bio::GenBank::ArrayStream->new($entryLines);

    last if ($ctx->{cla}->{testnumber}
	     && $M->{entryCnt} > $ctx->{cla}->{testnumber});
    next if ($ctx->{ cla }->{ start }
	     && $M->{entryCnt} < $ctx->{ cla }->{ start }) ;

    eval {
      $M->processEntry($entryStream);
    };
    $M->handleFailure($entryLines, $ctx->{cla}, $@) if ($@);
  }
  ## Close DBI handle
  $ctx->{'self_inv'}->closeQueryHandle();

  print STDERR "Genbank entries inserted= $M->{insertCnt};  updated= $M->{updateCnt}; total #(inserted::updated::deleted)=" . $ctx->{self_inv}->getTotalInserts() . "::" . $ctx->{self_inv}->getTotalUpdates() . "::" . $ctx->{self_inv}->getTotalDeletes() .  "\n";
  return "Genbank entries inserted= $M->{insertCnt};  updated= $M->{updateCnt}";
}

sub processEntry {
  my($M, $ios) = @_;

  my $e = CBIL::Bio::GenBank::Entry->new( { ios => $ios } );

  if (!$e->getValidity()) {
    die "INVALID ENTRY N=$M->{entryCnt} ACC=" .
      $e->{ACCESSION}->[0]->getAccession();
  }

  if (defined $ctx->{cla}->{div}) {
    my $div = $ctx->{cla}->{div};
    my $e_div = $e->{LOCUS}->[0]->getDivision();
    return unless ($div eq $e_div);
  }

  ## Print the status of the script to LOG
  if ($M->{entryCnt} % 1 == 0 ) { 
    $M->logAlert("STATUS", "N=$M->{entryCnt} ACC=" .
		 $e->{ACCESSION}->[0]->getAccession(),
		 " TOTAL_OBJECTS=" . ($ctx->{self_inv}->getTotalInserts() + $ctx->{self_inv}->getTotalUpdates()));
  }

  ## Check NAEntry for update
  my $naentry = GUS::Model::DoTS::NAEntry->new({'source_id' => $e->{'ACCESSION'}->[0]->getAccession(),
						#'version' => $e->{VERSION}->[0]->getSeqVersion()
					       });
 
  my $chkdif = ($naentry->retrieveFromDB()) ? 1 : 0 ;
  if ($chkdif && !$ctx->{ cla }->{ updateAll }) { 
    my $dbDate = ($naentry->getUpdateDate()) ? $naentry->getUpdateDate() : $naentry->getCreatedDate();
    $dbDate =~ s/^(\S+)\s+.+$/$1/;
    return if( &dbDateMoreRecent($dbDate,$e->{LOCUS}->[0]->getDate()));
  }

  ## Entry must either be new or need an update if we get to this point
  ## Following the strategy of building the complete entry and then 
  ## comparing it to the DB entry, applying changes where needed. 
	    
  my $seqobj = &buildNASeq($e);
  $seqobj->addChild(&buildNAEntry($e, $naentry, $chkdif));
  my ($c,@C) ;			# temp vars to see if build subs return anything valid
	    
  #### Scrap keywords for now, since they are giving me a hard time
  #		@C = &buildKeyword($e);
  #		$seqobj->addChildren(@C) if @C; undef @C;
	    
  $c = &buildOrganelle($e);
  $seqobj->addChild($c) if $c; undef $c;
  $c = &buildComment($e);
  $seqobj->addChild($c) if $c; undef $c;
  @C = $M->buildFeatures($e,$seqobj);
  $seqobj->addChildren(@C) if @C; undef @C;

  # References are really screwed up in GUS so leave this for later.
  #$seqobj->addChild(&buildReference($e));
  # DbRef is part of the Features --> moved to &buildFeatures() 
  # $seqobj->addChild(&buildDbRef($e));		
	    
  if ($chkdif) { 
    my $dbSeq = $naentry->getParent('GUS::Model::DoTS::ExternalNASequence',1);
    ## First check if sequence object needs update
    # print $dbSeq->toXML();0
    # print $seqobj->toXML();
    &updateObj($dbSeq,$seqobj);
		
    ## Now let's do the checks in a civil manner
    my $childList = &getProperChildList($dbSeq);
    my(@dbChildren, @newChildren);
    foreach my $class (@$childList) {
      @dbChildren = $dbSeq->getChildren($class, 1);
      @newChildren = $seqobj->getChildren($class);
      &processChildren($dbSeq,\@dbChildren, \@newChildren);
    }

    $dbSeq->submit();
    if ($dbSeq->getDbHandle()->getRollBack()) {
      $M->logAlert('FAILED ENTRY', "Acc:", $e->{ACCESSION}->[0]->getAccession());
      die "dbSeq submit caused a rollback";
    } else {
      $M->logAlert( "UPDATED", $e->{ACCESSION}->[0]->getAccession(), "; N=$M->{entryCnt}\n");
      $M->{updateCnt}++;
    }
  } else {    
    $seqobj->submit();
    if ($seqobj->getDbHandle()->getRollBack()) {
      $M->logAlert('FAILED ENTRY', "Acc:", $e->{ACCESSION}->[0]->getAccession());
      die "seqobj submit caused a rollback";
    } else {
      $M->logAlert( "INSERTED", $e->{ACCESSION}->[0]->getAccession(), "; N=$M->{entryCnt}\n");
      $M->{insertCnt}++;
    }
  }
  #&undefCache(%DbRefCache);
	    
  $ctx->{self_inv}->undefPointerCache();
}


sub buildNASeq {
  my $e = shift;
	
  # get the sequence type
  my $seqtype = &getSequenceTypeId($e->{LOCUS}->[0]->getType());
  my $taxon = &getTaxonId($e->{SOURCE}->[0]->{ORG}->getSpecies());
  if (!$taxon) {
    my $s = $e->{FEATURES}->[0]->getSingleFeature("source"); 
    my $org = $s->getSingleQualifier('organism');
    if ($org) {
      $taxon = &getTaxonId($org->getValue());
    }
  }
  my $h = {'source_id'=> $e->{ACCESSION}->[0]->getAccession(), 
	   'external_database_release_id' => $ctx->{ cla }->{ db_rel_id },
	   'sequence_type_id' => $seqtype,
	   'taxon_id' => $taxon,
	   'name' => $e->{LOCUS}->[0]->getId(),
	   'description' => substr($e->{DEFINITION}->[0]->{STR},0,499),
	   'sequence' => $e->{Sequence}->getSequence(),
	   'sequence_version' => $e->{VERSION}->[0]->getSeqVersion(),
	   'a_count' => $e->{'BASE COUNT'}->[0]->{CNT}->{a},
	   'c_count' => $e->{'BASE COUNT'}->[0]->{CNT}->{c},
	   'g_count' => $e->{'BASE COUNT'}->[0]->{CNT}->{g},
	   't_count' => $e->{'BASE COUNT'}->[0]->{CNT}->{t},
	   'length' => $e->{LOCUS}->[0]->getLength()    };
	
  my $seq = GUS::Model::DoTS::ExternalNASequence->new($h);
  ## Set other_count only if present
  if ($e->{"BASE COUNT"}->[0]->{other}) { 
    $seq->setOtherCount($e->{'BASE COUNT'}->[0]->{other});
  }
  ## Set secondary identifier only if present
  if ($e->{VERSION}->[0]->getGiNumber()) { 
    $seq->setSecondaryIdentifier(($e->{VERSION}->[0]->getGiNumber()));
  }
	
  return $seq;
	
}

sub buildNAEntry {
  my ($e,$nae,$chkdif) = shift;

  my %h = ('source_id' =>  $e->{ACCESSION}->[0]->getAccession(), 
	   'division' => $e->{LOCUS}->[0]->getDivision(),
	   'version' => $e->{VERSION}->[0]->getSeqVersion(),
	  ) ;
  my $date = &formatDate($e->{LOCUS}->[0]->getDate());
  if ($chkdif) { 
    $h{'update_date'} = $date;
    $h{'update_rel_ver'}  =  $ctx->{cla}->{gbRel};
    $h{'created_date'} = $nae->get('created_date');
    $h{'created_rel_ver'}  =  $nae->get('created_rel_ver');
  } else {
    $h{'created_date'} = $date;
    $h{'created_rel_ver'}  =  $ctx->{cla}->{gbRel};
  }		
  my $o = GUS::Model::DoTS::NAEntry->new(\%h);

  if ($e->{ACCESSION}->[0]->getSecondaryAccession()) {
    $o->addChild(&buildSecondaryAccs($e->{ACCESSION}->[0]));
  }
  return $o;
}

sub buildSecondaryAccs {
  my $a = shift;
  my $h = {'external_database_release_id' => $ctx->{ cla }->{ db_rel_id },
	   'source_id' => $a->getAccession(),
	   'secondary_accs' => $a->getSecondaryAccession() };
					 
  return GUS::Model::DoTS::SecondaryAccs->new($h);
}

sub buildKeyword {
  my $e = shift;
  my $A =  $e->{KEYWORDS}->[0]->getKeywords();
  my @K;
	
  foreach my $k (@$A) {
    my $kid = &getKeywordId($k);
    my $nk = GUS::Model::DoTS::NASequenceKeyword->new({'keyword_id' => $kid});
    $nk->retrieveFromDB();
    my $ek = GUS::Model::SRes::ExternalDatabaseKeyword->new({'keyword_id' => $kid, 'external_database_release_id' => $ctx->{ cla }->{db_rel_id}});
    if (!$ek->retrieveFromDB()) {
      $nk->addToSubmitList($ek);
    }
    push @K, $nk;
  }
  return @K;
}

sub buildOrganelle {
  my $e = shift;
  ## Organelle information is buried in the source feature.
  my $s = $e->{FEATURES}->[0]->getSingleFeature("source");
  my ($on, $pn);
	
  if ($s->getQualifiers('organelle')) {
    $on = $s->getSingleQualifier('organelle')->getValue();
  }
  if ($s->getQualifiers('plasmid')) {
    $pn = $s->getSingleQualifier('plasmid')->getValue();
  }	
  my $organelle = &getOrganelleId($on, $pn)		;
  if ($organelle) {
    my $seqorg = GUS::Model::DoTS::NASequenceOrganelle->new();
    $seqorg->setOrganelleId($organelle);
    return $seqorg;
  }
  return undef;
}

sub getOrganelleId {
  my ($on, $pn) = @_;
  unless ($OrganelleCache{ "$on$pn" }) {
    my %h; 
    ($on) ? $h{'name'} = $on: 0;
    ($pn) ? $h{'plasmid_name'} = $pn: 0;
    my $o = GUS::Model::DoTS::Organelle->new(\%h);
    $o->submit();
    $OrganelleCache{ "$on$pn" } = $o->getId();
  }
  return $OrganelleCache{"$on$pn"};
}		

sub buildReference {
  my $e = shift;
  my @R;
  foreach my $r (@{$e->{ REFERENCE }}) {
    my %h = ('title' => $r->getTitle(),
	     'author' => $r->getAuthorString(),
	     'position' => ($r->getFrom() . '..' . $r->getTo()),
	    );	
    if ($r->getRemark()) {
      $h{'remark'} = (join ';' , @{$r->getRemark()});
    }
    if ($r->getJournal() == 1) {
      $r->getJournal()->[0] =~ /^(.+)\,\s(\S+)\s\((\d+)\)/;
      my @j = split /\s/,$1;
      my ($p,$y) = ($2, $3);
					
      $h{'journal_or_book_title'} = (splice @j, 0, ((scalar @j)- 2));
      $h{'journal_vol'} = join '', @j;
      $h{'journal_page'} = $p;
      if ($y > -4713 && $y < 9999) {
	$h{'year'} = $y;
      }
    }
		
    my $ref = GUS::Model::SRes::Reference->new(\%h);

    ## Take care of external refs
    if ($r->getPubMed()) { 
      my $o = GUS::Model::SRes::DbRef->new({'external_database_release_id' => &getDbRelId('PubMed'), 'primary_identifier' => $r->getPubMed()});
      $o->retrieveFromDB();
      $o->addChild($ref);
    } elsif ($r->getMEDLINE()) { 
      my $o = GUS::Model::SRes::DbRef->new({'external_database_release_id' => &getDbRelId('MEDLINE'), 'primary_identifier' => $r->getMEDLINE()});
      $o->retrieveFromDB();
      $o->addChild($ref);
    }
    push @R, $ref;
  }
  return @R;
}


sub buildComment {
  my $e = shift;
  my $c = $e->{COMMENT}->[0];
  return undef unless $c;
  my $h = {'comment_string' => substr($c->getString(), 0, 4000)};
  return GUS::Model::DoTS::NAComment->new($h);
}

sub buildFeatures {
  my ($M, $e,$seq) = @_;

  my @F;			## Array of NAFeature objects to return
  # grab the array of hashrefs representing the features
  my $a = $e->{FEATURES}->[0]->getAllFeatures();
	
  foreach my $f (@$a) {
    my $subclass_view = &getFeatureViewName($f->getType());
    my $h = {'name' => $f->getType()};
    my $o = $subclass_view->new($h);
    #print $o->getClassName();
    ## set location tuple
    $o->addChildren(&buildLocations($f));
    ## PrimaryTranscript
    if ($f->getType() =~ /precursor_RNA|prim_transcript/ ) {
      $o->addChild(&buildPrimaryTranscript());			
    }

    ## set qualifiers
    my $Q = $f->getAllQualifiers();
    foreach my $q (@$Q) {
      ## Assign proper tag & value to cover GUS col renames and bits
      &getProperQualifier($q);
      if ($o->isValidAttribute($q->getTag())) {
	$o->set($q->getTag(), $q->getValue());
      }
      if ($q->getTag() eq 'note' ) {
	$o->addChild(&buildNAFeatureComment($q));
      } elsif ($q->getTag() eq 'gene') {
	$o->addChild(&buildGene($q, $f));
      } elsif ($q->getTag() eq 'product') {
	$o->addChild(&buildProtein($q));
      } elsif ($q->getTag() eq 'db_xref') {
	$o->addChild(&buildDbXRef($q, $seq));
      } elsif (!($o->isValidAttribute($q->getTag()))) {
	$M->logAlert("INVALID QUALIFIER", $o->getClassName(),
		    "::", $q->getTag(),"::",$q->getValue(), "\n");
      }
    }
    push @F, $o;		
  }
  return @F;
}

sub getProperQualifier {
  my $q = shift;
  my $t = $q->getTag();
  my %h = ('number' => 'num', 
	   'replace' => 'substitute',
	   'exception' => 'transl_except',
	   'country' => 'note',
	   'pseudo' => 'is_pseudo',
	   'partial' => 'is_partial'
	  );
	
  ($h{$t}) ? ($q->setTag($h{$t})) : ($q->setTag(lc $t)) ;
  my %vals = ('is_pseudo' => 1,
	      'is_partial' => 1,
	      'frequency' => &NumberFy($q->getValue()),
	      'function' => substr($q->getValue(),0,255),
	      'transl_except' => substr($q->getValue(),0,255));
	
  if ($vals{$q->getTag()}) {
    $q->setValue($vals{$q->getTag()});
  }
}

# Stupid sub to format decimals correctly in 'frequency' qualifier
sub NumberFy {
  my $n = shift;
  $n =~ s/\~//;
  if ($n =~ /(d+)\:(d+)/) {	#DP's change-2/14/02
    $n = $1/$2;
  }              
  return $n;
}

sub buildLocations {
  my $f = shift;
  my $debug = $f->getLocString;
  if ((length $debug) > 4000) {
    $debug = "TRUNCATED:" . (substr $debug, 0, 3900);
  }
  my $lp = $f->getLocParse();
  my $type= shift @$lp;
  #	print "**T=$type, L=", (join " : ", $loc->[0]->[0]), "\n";
  my @O =  &buildComplexLoc($lp,$type,$debug);
  #	print "**LOCS=", scalar @O, "\n";
  return  @O;

}

sub buildComplexLoc {
  my ($loc,$type,$debug,$isRev,$dbId,$remark,$order, $lit_seq) =@_;
  my (@O,$o);
  if ($type =~ /span/) {
    ## Account for "one-of" 
    if ($loc->[0]->[0] =~ /one\-of/ || $loc->[1]->[0] =~ /one\-of/ ) {
      # do nothing. They were idiots.
    } else {
      $o =  &buildLoc($loc,$debug,$isRev,$dbId,$remark,$order, $lit_seq);
      push @O,$o;
    }
  } elsif ($type =~ /^exact|midpoint|above|below/) {
    print "********Building point location\n @$loc\n";
    $o =  &buildPointLoc($loc,$type,$debug,$isRev,$dbId,$remark,$order, $lit_seq);
    push @O,$o;	
  } elsif ($type eq 'replace') {
    my $l = $loc->[0];
    $lit_seq = $loc->[1]->[1];
    my $t = shift @$l;
    push @O, &buildComplexLoc($l,$t,$debug,$isRev,$dbId,$remark,$order,$lit_seq);
  } elsif ($type eq 'complement') {
    my $l = $loc->[0];
    my $t = shift @$l;
    push @O, &buildComplexLoc($l,$t,$debug, 1,$dbId,$remark,$order,$lit_seq);
  } elsif ($type eq 'xref') {
    my ($ref,$l) = @$loc;
    my $t = shift @$l;
    push @O, &buildComplexLoc($l, $t, $debug, $isRev, (join '.', @$ref), $remark,$order, $lit_seq);
  } elsif ($type =~ /join|order|group/) {
    #		my $a = shift @$loc;
    for (my $i=0; $i < @$loc; $i++) {
      my $l = $loc->[$i];
      my $t = shift @$l;
      push @O, &buildComplexLoc($l,$t,$debug,$isRev,$dbId,$type,$i+1,$lit_seq);
    }
  } elsif ($type =~ /one\-of/) {
    for (my $i=0; $i < @$loc; $i++) {
      my $l = $loc->[$i];
      my $t = shift @$l;
      push @O, &buildComplexLoc($l,$t,$debug,$isRev,$dbId,$type,$order,$lit_seq);
    }
  } else {			## $type is something else
    my $l = $loc->[0];
    my $t = shift @$l;
    push @O,  &buildComplexLoc($l, $t, $debug,$isRev,$dbId,$type,$order,$lit_seq);
  }
  return @O;
}

sub buildLoc {

  my ($loc,$debug,$isRev,$dbId,$remark,$order,$lit_seq) = @_;
  my ($sm, $sx, $isex1, $e1) = &getStartPos($loc->[0]);
  my ($em, $ex, $isex2, $e2) = &getEndPos($loc->[1]);
	
  my $h = { 'debug_field' => $debug,
	    'start_max' => $sx,
	    'end_min' => $em,
	  };
	
  ($sm) ?  ($h->{'start_min'}) = $sm : 0 ;
  ($ex) ? ($h->{'end_max'} = $ex) : 0 ;
  ($isex1 || $isex2) ? ($h->{'is_excluded'} = 1) : 0 ;
  ## locations exact
  ($e1 && $e2) ? ($h->{'location_type'} = 'exact') : 0 ;

  ## set the rest of the columns
  ($isRev) ? ($h->{ is_reversed } = 1) : 0 ; 
  ($dbId) ? ($h->{ db_identifier } = $dbId) : 0 ;
  ($remark) ? ($h->{ remark } = $remark) : 0 ; 
  ($order) ? ($h->{ loc_order } = $order) : 0 ; 
  ## account for literal sequences
  ($lit_seq) ? ($h->{literal_sequence} = $lit_seq) : 0;

  return GUS::Model::DoTS::NALocation->new($h);
}

sub buildPointLoc {
  my ($l,$t,$debug,$isRev,$dbId,$remark,$order, $lit_seq) =  @_;
  my %h = ( 'debug_field' => $debug,
	    'is_reversed' => 0,
	    'location_type' => $t);

  if ($t =~ /midpoint|exact/) {
    $h{'start_min'} = $l->[0];
    $h{'start_max'} = $l->[0];
		
    $h{'end_min'} = ($l->[1]) ? $l->[1] : $l->[0];
    $h{'end_max'} = ($l->[1]) ? $l->[1] : $l->[0];
  } elsif ($t =~ /above/) {
    $h{'start_min'} = $l->[0];
  } elsif ($t =~ /below/) {
    $h{'end_max'} = $l->[0];
  }
  ## set the rest of the columns
  ($isRev) ? ($h{'is_reversed'} = 1) : 0 ; 
  ($dbId) ? ($h{'db_identifier'} = $dbId) : 0 ;
  ($remark) ? ($h{ 'remark' } = $remark) : 0 ; 
  ($order) ? ($h{ 'loc_order' } = $order) : 0 ;
  ($lit_seq) ? ($h{'literal_sequence'} = $lit_seq):0;
	
  return GUS::Model::DoTS::NALocation->new(\%h);
}

sub getStartPos {
  my $l = shift;
  ## $l is an array_ref
  my @a;
  if ( @$l == 1) {		# this means a complicated span location
    print "********GEtting loc complex   @$l\n";
    @a = ($l->[0]->[1]->[1],$l->[0]->[2]->[1],1);
  } else {
    if ($l->[0] eq 'below') {
      print "\n\n********GEtting loc below", $l->[1],"\n\n";
      @a = (undef, $l->[1]);
    } elsif ( $l->[1] =~ /\((\d+)\.(\d+)/) {
      print "********GEtting loc DOT $l->[1]\n";
      @a = ($1, $2, 1) ;
    } else {
      @a = ($l->[1],$l->[1], undef, 1);
    }
  }
  return @a;
}

sub getEndPos {
  my $l = shift;
  ## $l is an array_ref of array_refs
  my @a;
  if ( @$l == 1) {		# this means a complicated span location
    @a = ($l->[0]->[1]->[1],$l->[0]->[2]->[1], 1);
  } else {
    if ($l->[0] eq 'above') {
      @a = ($l->[1], undef);
    } elsif ( $l->[1] =~ /\((\d+)\.(\d+)/) {
      @a = ($1, $2, 1) ;
    } else {
      @a = ($l->[1],$l->[1], undef, 1);
    }
  }
  return @a;
}

sub buildGene {
  my $q = shift;
  my $g = &getNAGeneId( $q->getValue());
  my $o = GUS::Model::DoTS::NAFeatureNAGene->new();
  $o->setNaGeneId($g);
  return $o;
}

sub getNAGeneId {		## On-demand caching
  my $t = shift;
  my $n = substr($t,0,300);
  if (!$NAGeneCache{$n}) {
    my $g = GUS::Model::DoTS::NAGene->new({'name' => $n});										
    unless ($g->retrieveFromDB()){
      $g->set('is_verified', 0);
      $g->submit();
    }
    $NAGeneCache{$n} = $g->getId();
  }
  return $NAGeneCache{$n};
}

	
sub buildProtein {
  my $q = shift ;
  my $n = substr($q->getValue(),0,300);
  my $p = &getNaProteinId($n);
  my $o = GUS::Model::DoTS::NAFeatureNAProtein->new();
  $o->setNaProteinId($p);
  return $o;
}

sub getNaProteinId {
  my $n = shift;
  if (!$NaProteinCache{$n}) {
    my $p = GUS::Model::DoTS::NAProtein->new({'name' => $n});	
    unless ($p->retrieveFromDB()){
      $p->set('is_verified', 0);
      $p->submit();
    }
    $NaProteinCache{$n} = $p->getId();
  }
  return $NaProteinCache{$n};
}

sub buildPrimaryTranscript {
  my $p = GUS::Model::DoTS::NAPrimaryTranscript->new({'is_verified' => 0});
  my $o = GUS::Model::DoTS::NAFeatureNAPT->new();
  $o->setParent($p);
  return $o;
}

sub buildNAFeatureComment {
  my $q = shift;
  my %h = ('comment_string' => substr($q->getValue(), 0, 4000));
  return GUS::Model::DoTS::NAFeatureComment->new(\%h);
}

sub buildDbXRef {
  my $q = shift;
  my $seq = shift;
  my $o = GUS::Model::DoTS::DbRefNAFeature->new();
  my $v = $q->getValue();
  my $id = &getDbXRefId($v);
  $o->setDbRefId($id);
  ## If DbRef is outside of Genbank, then link directly to sequence
  if (!($v =~ /taxon|GI|pseudo|dbSTS|dbEST/i)) {
    my $o2 = GUS::Model::DoTS::DbRefNASequence->new();
    $o2->setDbRefId($id);
    $seq->addChild($o2);
  }
  return $o;
}

sub getDbXRefId {
  my $k = shift;
  if (!$DbRefCache{$k}) {
    my ($db,$id,$sid)= split /\:/, $k;
    my $dbref = GUS::Model::SRes::DbRef->new({'external_database_release_id' => &getDbRelId($db),'primary_identifier' => $id});
    if ($sid) {
      $dbref->set('secondary_identifier',$sid);
    }
    unless ($dbref->retrieveFromDB()) {
      $dbref->submit();
    }
    ;
    $DbRefCache{$k} = $dbref->getId();
  }
  return ($DbRefCache{$k});
}

##############scream for more work right here!!!!!!!!!!!!!

sub getFeatureViewName {
  my $n = shift;

  my %featureNameTableMapping = (
				 "allele" => "GUS::Model::DoTS::SeqVariation",
				 "-" => "GUS::Model::DoTS::Miscellaneous",
				 "attenuator" => "GUS::Model::DoTS::DNARegulatory",
				 "C_region" => "GUS::Model::DoTS::Immunoglobulin",
				 "CAAT_signal" => "GUS::Model::DoTS::DNARegulatory",
				 "CDS" => "GUS::Model::DoTS::Transcript",
				 "conflict" => "GUS::Model::DoTS::SeqVariation",
				 "D-loop" => "GUS::Model::DoTS::DNAStructure",
				 "D_segment" => "GUS::Model::DoTS::Immunoglobulin",
				 "enhancer" => "GUS::Model::DoTS::DNARegulatory",
				 "exon" => "GUS::Model::DoTS::Transcript",
				 "GC_signal" => "GUS::Model::DoTS::DNARegulatory",
				 "gene" => "GUS::Model::DoTS::GeneFeature",
				 "iDNA" => "GUS::Model::DoTS::Immunoglobulin",
				 "intron" => "GUS::Model::DoTS::Transcript",
				 "J_segment" => "GUS::Model::DoTS::Immunoglobulin",
				 "LTR" => "GUS::Model::DoTS::Repeats",
				 "mat_peptide" => "GUS::Model::DoTS::ProteinFeature",
				 "misc_binding" => "GUS::Model::DoTS::Miscellaneous",
				 "misc_difference" => "GUS::Model::DoTS::SeqVariation",
				 "misc_feature" => "GUS::Model::DoTS::Miscellaneous",
				 "misc_recomb" => "GUS::Model::DoTS::SeqVariation",
				 "misc_RNA" => "GUS::Model::DoTS::RNAStructure",
				 "misc_signal" => "GUS::Model::DoTS::Miscellaneous",
				 "misc_structure" => "GUS::Model::DoTS::Miscellaneous",
				 "modified_base" => "GUS::Model::DoTS::SeqVariation",
				 "mRNA" => "GUS::Model::DoTS::Transcript",
				 "mutation" => "GUS::Model::DoTS::SeqVariation",
				 "N_region" => "GUS::Model::DoTS::Immunoglobulin",
				 "old_sequence" => "GUS::Model::DoTS::SeqVariation",
				 "polyA_signal" => "GUS::Model::DoTS::Transcript",
				 "polyA_site" => "GUS::Model::DoTS::Transcript",
				 "precursor_RNA" => "GUS::Model::DoTS::Transcript",
				 "prim_transcript" => "GUS::Model::DoTS::Transcript",
				 "primer_bind" => "GUS::Model::DoTS::DNAStructure",
				 "promoter" => "GUS::Model::DoTS::DNARegulatory",
				 "protein_bind" => "GUS::Model::DoTS::Miscellaneous",
				 "RBS" => "GUS::Model::DoTS::RNAStructure",
				 "repeat_region" => "GUS::Model::DoTS::Repeats",
				 "repeat_unit" => "GUS::Model::DoTS::Repeats",
				 "rep_origin" => "GUS::Model::DoTS::DNAStructure",
				 "rRNA" => "GUS::Model::DoTS::RNAType",
				 "S_region" => "GUS::Model::DoTS::Immunoglobulin",
				 "satellite" => "GUS::Model::DoTS::Repeats",
				 "scRNA" => "GUS::Model::DoTS::RNAType",
				 "sig_peptide" => "GUS::Model::DoTS::ProteinFeature",
				 "snRNA" => "GUS::Model::DoTS::RNAType",
				 "snoRNA" => "GUS::Model::DoTS::RNAType",
				 "source" => "GUS::Model::DoTS::Source",
				 "stem_loop" => "GUS::Model::DoTS::Miscellaneous",
				 "STS" => "GUS::Model::DoTS::STS",
				 "TATA_signal" => "GUS::Model::DoTS::DNARegulatory",
				 "terminator" => "GUS::Model::DoTS::DNARegulatory",
				 "transit_peptide" => "GUS::Model::DoTS::ProteinFeature",
				 "tRNA" => "GUS::Model::DoTS::RNAType",
				 "unsure" => "GUS::Model::DoTS::Miscellaneous",
				 "V_region" => "GUS::Model::DoTS::Immunoglobulin",
				 "V_segment" => "GUS::Model::DoTS::Immunoglobulin",
				 "variation" => "GUS::Model::DoTS::SeqVariation",
				 "3'clip" => "GUS::Model::DoTS::Transcript",
				 "3'UTR" => "GUS::Model::DoTS::Transcript",
				 "5'clip" => "GUS::Model::DoTS::Transcript",
				 "5'UTR" => "GUS::Model::DoTS::Transcript",
				 "-10_signal" => "GUS::Model::DoTS::DNARegulatory",
				 "-35_signal" => "GUS::Model::DoTS::DNARegulatory"
				);

  return $featureNameTableMapping{$n};

} 

###################################################################
### Old GenbankParser.pm methods that I don't want to re-write  ###
###################################################################

sub setWholeTableCache{
  my $dbh = $ctx->{'self_inv'}->getQueryHandle();
  
  ##setup global hash for ExternalDatabaseRelease
  my $st = $dbh->prepare("select e.lowercase_name, r.external_database_release_id 
                          from sres.ExternalDatabase e, sres.ExternalDatabaseRelease r 
                          where r.external_database_id = e.external_database_id and r.version = 'unknown'");
  $st->execute() || die $st->errstr;
  
  while (my ($lowercase_name, $external_db_rel_id) = $st->fetchrow_array()) {
    $lowercase_name = lc $lowercase_name; ##just in case not real lowercase ;-))
    $ExternalDatabaseRelHash{"$lowercase_name"} = $external_db_rel_id;
  }
  
  ##setup global hash for SequenceType
  $st = $dbh->prepare("select name, sequence_type_id from dots.SequenceType");
  $st->execute() || die $st->errstr;
  while (my ($name, $sequence_type_id) = $st->fetchrow_array()) {
    $SequenceTypeHash{"$name"} = $sequence_type_id;
  }
  
  ### Organelle 
  $st = $dbh->prepare("select name || plasmid_name, organelle_id  from dots.Organelle");
  $st->execute() || die $st->errstr;
  while (my ($name, $sequence_type_id) = $st->fetchrow_array()) {
    $OrganelleCache{"$name"} = $sequence_type_id;
  }
  # $dbh->disconnect();
}

sub getDbRelId 
  {
    my $name = shift;

    my $lcname = lc $name;
  
    my $external_db_rel_id;

    my $external_db_id;

    if ($ExternalDatabaseRelHash{"$lcname"}) {
      $external_db_rel_id = $ExternalDatabaseRelHash{"$lcname"};
    } else {
      my $externalDatabaseRow = GUS::Model::SRes::ExternalDatabase->new({"name" => $name,
									 "lowercase_name" => $lcname});
      $externalDatabaseRow->retrieveFromDB();

      if (! $externalDatabaseRow->getId()) {
	$externalDatabaseRow->submit();
      }

      $external_db_id = $externalDatabaseRow->getId();
      
      my $version = 'unknown';

      my $release_date = 'sysdate'; 
      
      my $externalDatabaseRelRow = GUS::Model::SRes::ExternalDatabaseRelease->new ({'external_database_id'=>$external_db_id,'release_date'=>$release_date, 'version'=>$version});
      $externalDatabaseRelRow->submit();
      $external_db_rel_id = $externalDatabaseRelRow->getExternalDatabaseReleaseId();
      
      $ExternalDatabaseRelHash{"$lcname"} = $external_db_rel_id;
    }

    return $external_db_rel_id;
  }

sub getTaxonId			#this is on-demand caching
  {
    my $sci_name = shift;
    my $name_class = 'scientific name';
    my $taxon_id;
    if ($TaxonHash{"$sci_name"}) {
      $taxon_id = $TaxonHash{"$sci_name"};
    } else {
      my $taxonRow = GUS::Model::SRes::TaxonName->new({"name" => $sci_name, "name_class" => $name_class});
      if ($taxonRow->retrieveFromDB()) {
	$taxon_id = $taxonRow->getTaxonId();
	$TaxonHash{"$sci_name"} = $taxon_id;
      } else {
	$taxon_id = 0;
      }
    }
    return $taxon_id;
  }

sub getKeywordId
  {
    my $keyword = shift;
    my $keyword_id;
    if ($KeywordHash{"$keyword"}) {
      $keyword_id = $KeywordHash{"$keyword"};
    } else {
      my $keywordRow = GUS::Model::DoTS::Keyword->new({"keyword" => "$keyword" });
      $keywordRow->submit();
      $keyword_id = $keywordRow->getId();
      $KeywordHash{"$keyword"} = $keyword_id;
    }
    return $keyword_id;
  }

sub getKeywordId
  {
    my $keyword = shift;
    my $keyword_id;
    if ($KeywordHash{"$keyword"}) {
      $keyword_id = $KeywordHash{"$keyword"};
    } else {
      my $keywordRow = GUS::Model::DoTS::Keyword->new({"keyword" => "$keyword" });
      $keywordRow->submit();
      $keyword_id = $keywordRow->getId();
      $KeywordHash{"$keyword"} = $keyword_id;
    }
    return $keyword_id;
  }

## Check to see if entry has been updated more recently than the DB
## If so return 0;
sub dbDateMoreRecent {
  my ($dbDate, $entryDate) = @_;
  my @ed = split /-/, $entryDate;
  my @dbd = split /-/, $dbDate;
  
  #    print "DB: $dbDate; ENTRY:  $entryDate\n";
  #    print "YEAR OK\n"  if ($ed[2] >= $dbd[2]);
  #    print "MONTH OK \n" if ($$month{$ed[1]} >= $dbd[1]);
  #    print "DAY OK\n" if ($ed[0] > $dbd[0]);

  return 0 if ($ed[2] > $dbd[0]);
  return 0 if (&getNumMonth($ed[1]) > $dbd[1]);
  return 0 if ($ed[0] > $dbd[2]);
  return 1;
}

sub formatDate {
  my $d = shift;
  # 23-AUG-1999 --> 1999-03-15 00:00:00
  my @A = split /-/, $d;
  return $A[2] . "-" . &getNumMonth($A[1]) . "-" . $A[0] . " 00:00:00";
}
sub getNumMonth { 
  my $m = shift;
  my %month = ("JAN" => 1,
               "FEB" => 2,
               "MAR" => 3,
               "APR" => 4,
               "MAY" => 5,
               "JUN" => 6,
               "JUL" => 7,
               "AUG" => 8,
               "SEP" => 9,
               "OCT" => 10,
               "NOV" => 11,
               "DEC" => 12
	      );

  return  $month{$m};
}

sub getSequenceTypeId		#this is on-demand caching
  {
    my $name = shift;
    my $sequence_type_id;
    if (!exists $SequenceTypeHash{"$name"}) {
      my $sequenceTypeRow = GUS::Model::DoTS::SequenceType->new({"name" => $name});
      if ($sequenceTypeRow->retrieveFromDB()) {
	$sequence_type_id= $sequenceTypeRow->getId();
	$SequenceTypeHash{"$name"} = $sequence_type_id;
      } else {
	$sequence_type_id = 11;
      }
    } else {
      $sequence_type_id = $SequenceTypeHash{"$name"};
    }
    return $sequence_type_id;
  }

#####################################
## Methods for dealing with updates
#####################################

#  mondoCheck - method to retrieve db child entries and send them 
#  off for processing on a per-class basis
sub mondoCheck {
  my ($db_obj, $new_obj) = @_;
  ## Now let's do the checks in a civil manner
  my $childList = &getProperChildList($db_obj); # ->getChildList();
  if (&manyToManyObj($db_obj->getClassName())) {
    ## print  "******IN MANY TO MANY METHOD****\n";
    my $dbp = $db_obj->getParent(&getTheOtherParent($db_obj->getClassName()),1);
    if ($new_obj && $db_obj->getAttributeDifferences($new_obj)) {
      $db_obj->markDeleted(1);
      $db_obj->submit();
      $new_obj->setParent($dbp);
    } 
  } elsif ($childList) {
    my(@dbChildren, @newChildren);
    foreach my $class (@$childList) {
      @dbChildren = $db_obj->getChildren($class, 1);
      @newChildren = $new_obj->getChildren($class);
      &processChildren($db_obj,\@dbChildren, \@newChildren);
    }
  } else {
    ## put this additional condition in for empty leaves
    if ($new_obj) { 
      &updateObj($db_obj,$new_obj);
    }
  }
}

sub processChildren {
  my ($db_obj, $dbChildren, $newChildren) = @_;
  my($dbChild, $newChild,$atts,); # @matched, @unmatched, @new, @old
  foreach $dbChild (@$dbChildren) {
    # print "Processing child: ", $dbChild->toString(), "\n";
    $newChild = &getMatch($dbChild, $newChildren);
    if ($newChild) {		#if child defined, update
      &updateObj($dbChild,$newChild);
      &mondoCheck($dbChild, $newChild);
    } else {			#  match not found, recursively delete old db_child
      my $cl = &getProperChildList($dbChild);
      if ($cl) {
	foreach my $c (@$cl) {
	  $dbChild->retrieveChildrenFromDB($c);
	}
      }
      $dbChild->markDeleted(1);
      $dbChild->submit();
    }				# end if ($newChild)
  }				#end foreach ($dbchildren)
	
  ## If we have leftover new children, add to $db_obj
  $db_obj->addChildren(@$newChildren);
}

# getMatch -- method that returns exact matches for objects 
sub getMatch {
  my ($dbo, $new) = @_;
  my (@diffs,$vals);
  for (my $i = 0; $i < @$new; $i++) {
		
    my $o = $new->[$i];

    @diffs = $dbo->getAttributeDifferences($o);
    $vals = $o->getAttributes();
		
    print "DIFFS:" . (scalar @diffs) . " VALS:" . (scalar keys %$vals) . "\n" if ($ctx->{ cla }->{verbose}); 
    if ((scalar @diffs) == 0 && (scalar keys %$vals) > 0) {
      if ($ctx->{ cla }->{verbose}) {
	print "DB = " . $dbo->toXML();
	print "NEW = " . $o->toXML() . "\n"; 
      }
      return splice @$new,$i,1; ## splice out exact match

    }
  }
}

sub updateObj {
  my ($dbo,$n) = @_;
  my @A = $dbo->getAttributeDifferences($n) ;
  foreach my $k (@A) {
    if ($dbo->isValidAttribute($k)) {
      $dbo->set($k,$n->get($k));
    }
  }
}

# getProperChildList - method to obtain a limmited childList due to weird 
# view to view relationships, and how they inherit childList from Imp table
sub getProperChildList {
  my ($obj) = @_;
  my %classChildList = 
    ('GUS::Model::DoTS::NASequenceImp' => [ 'GUS::Model::DoTS::NASequenceOrganelle', 'GUS::Model::DoTS::DNARegulatory','GUS::Model::DoTS::DNAStructure','GUS::Model::DoTS::STS','GUS::Model::DoTS::GeneFeature','GUS::Model::DoTS::RNAType','GUS::Model::DoTS::Repeats','GUS::Model::DoTS::Miscellaneous','GUS::Model::DoTS::Immunoglobulin','GUS::Model::DoTS::ProteinFeature','GUS::Model::DoTS::SeqVariation','GUS::Model::DoTS::RNAStructure','GUS::Model::DoTS::Source','GUS::Model::DoTS::Transcript', 'GUS::Model::DoTS::NAEntry', 'GUS::Model::DoTS::NAComment',  'GUS::Model::DoTS::DbRefNASequence', 'GUS::Model::DoTS::NASequenceKeyword'], #'NASequenceRef',
     'GUS::Model::DoTS::NASequence' =>  [ 'GUS::Model::DoTS::NASequenceOrganelle', 'GUS::Model::DoTS::DNARegulatory','GUS::Model::DoTS::DNAStructure','GUS::Model::DoTS::STS','GUS::Model::DoTS::GeneFeature','GUS::Model::DoTS::RNAType','GUS::Model::DoTS::Repeats','GUS::Model::DoTS::Miscellaneous','GUS::Model::DoTS::Immunoglobulin','GUS::Model::DoTS::ProteinFeature','GUS::Model::DoTS::SeqVariation','GUS::Model::DoTS::RNAStructure','GUS::Model::DoTS::Source','GUS::Model::DoTS::Transcript', 'GUS::Model::DoTS::NAEntry', 'GUS::Model::DoTS::NAComment', 'GUS::Model::DoTS::DbRefNASequence', 'GUS::Model::DoTS::NASequenceKeyword'], #'NASequenceRef',
     'GUS::Model::DoTS::ExternalNASequence' => [ 'GUS::Model::DoTS::NASequenceOrganelle', 'GUS::Model::DoTS::DNARegulatory','GUS::Model::DoTS::DNAStructure','GUS::Model::DoTS::STS','GUS::Model::DoTS::GeneFeature','GUS::Model::DoTS::RNAType','GUS::Model::DoTS::Repeats','GUS::Model::DoTS::Miscellaneous','GUS::Model::DoTS::Immunoglobulin','GUS::Model::DoTS::ProteinFeature','GUS::Model::DoTS::SeqVariation','GUS::Model::DoTS::RNAStructure','GUS::Model::DoTS::Source','GUS::Model::DoTS::Transcript', 'GUS::Model::DoTS::NAEntry', 'GUS::Model::DoTS::NAComment', 'GUS::Model::DoTS::DbRefNASequence', 'GUS::Model::DoTS::NASequenceKeyword'], #'NASequenceRef',
     #'NAComment' => [], # Standard Tables
     'GUS::Model::DoTS::NAEntry' => ['GUS::Model::DoTS::SecondaryAccs'],
     #'NALocation' => [], 
     'GUS::Model::DoTS::NAGene' => ['GUS::Model::DoTS::NAFeatureNAGene', 'GUS::Model::DoTS::NAPrimaryTranscript'],
     'GUS::Model::SRes::DbRef' => ['GUS::Model::DoTS::DbRefNASequence', 'GUS::Model::SRes::Reference', 'GUS::Model::DoTS::DbRefNAFeature'],
     #'ExternalDatabase' => [],
     'GUS::Model::DoTS::Keyword' => ['GUS::Model::DoTS::NASequenceKeyword', 'GUS::Model::SRes::ExternalDatabaseKeyword'],
     #'Organelle' => [],
     'GUS::Model::SRes::Ref' => ['GUS::Model::DoTS::NASequenceRef'],
     #'SecondaryAccs' => [],
     #'SequenceType' => [],
     #'NAFeatureComment' => [],
     #'NASequenceRef' => [], # Many to Many
     #'NASequenceOrganelle' => [],
     #'NASequenceKeyword' =>[],
     #'DbRefNASequence' => [],
     #'ExternalDatabaseKeyword' => [],
     #'NAFeatureNAGene' => [],
     #'NAFeatureNAProtein' =>  [],
     #'NAFeatureNAPT' => [],
     #'DbRefNAFeature' => [], # NAFeatureImp plus views
     'GUS::Model::DoTS::NAFeatureImp' => ['GUS::Model::DoTS::RNATranslation', 'GUS::Model::DoTS::TranscriptUnitSequence', 'GUS::Model::DoTS::NAFeatureComment', 'GUS::Model::DoTS::RNAFeatureExon', 'GUS::Model::DoTS::NALocation', 'GUS::Model::DoTS::NAFeatureNAGene','GUS::Model::DoTS::RNASequence', 'GUS::Model::DoTS::NAFeatureNAProtein', 'GUS::Model::DoTS::DbRefNAFeature', 'GUS::Model::DoTS::NAFeatureNAPT'], 
     #'NAFeature' =>  ['RNATranslation', 'TranscriptUnitSequence', 'NAFeatureComment', 'RNAFeatureExon',  'NALocation', 'NAFeatureNAGene','RNASequence', 'NAFeatureNAProtein', 'DbRefNAFeature', 'NAFeatureNAPT'],
     'GUS::Model::DoTS::DNARegulatory' => ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::NAFeatureNAGene', 'GUS::Model::DoTS::DbRefNAFeature'],
     'GUS::Model::DoTS::DNAStructure' => ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::NAFeatureNAGene', 'GUS::Model::DoTS::DbRefNAFeature'],
     'GUS::Model::DoTS::STS' =>  ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::NAFeatureNAGene', 'GUS::Model::DoTS::DbRefNAFeature'],
     'GUS::Model::DoTS::GeneFeature' =>  ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::NAFeatureNAGene', 'GUS::Model::DoTS::NAFeatureNAProtein','GUS::Model::DoTS::DbRefNAFeature'],
     'GUS::Model::DoTS::RNAType' =>  ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::NAFeatureNAGene', 'GUS::Model::DoTS::NAFeatureNAProtein','GUS::Model::DoTS::DbRefNAFeature'],
     'GUS::Model::DoTS::Repeats' =>  ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::NAFeatureNAGene', 'GUS::Model::DoTS::DbRefNAFeature'],
     'GUS::Model::DoTS::Miscellaneous' =>  ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::NAFeatureNAGene','GUS::Model::DoTS::NAFeatureNAProtein','GUS::Model::DoTS::DbRefNAFeature'],
     'GUS::Model::DoTS::Immunoglobulin' =>  ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::NAFeatureNAGene', 'GUS::Model::DoTS::NAFeatureNAProtein','GUS::Model::DoTS::DbRefNAFeature'],
     'GUS::Model::DoTS::ProteinFeature' =>  ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::NAFeatureNAGene', 'GUS::Model::DoTS::NAFeatureNAProtein','GUS::Model::DoTS::DbRefNAFeature'],
     'GUS::Model::DoTS::SeqVariation' =>  ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::NAFeatureNAGene', 'GUS::Model::DoTS::NAFeatureNAProtein','GUS::Model::DoTS::DbRefNAFeature'],
     'GUS::Model::DoTS::RNAStructure' => ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::DbRefNAFeature','GUS::Model::DoTS::NAFeatureNAGene','GUS::Model::DoTS::NAFeatureNAProtein'],
     'GUS::Model::DoTS::Source' => ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::DbRefNAFeature'],
     'GUS::Model::DoTS::Transcript' =>  ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::NAFeatureNAGene', 'GUS::Model::DoTS::NAFeatureNAPT','GUS::Model::DoTS::NAFeatureNAProtein','GUS::Model::DoTS::DbRefNAFeature'],
     'GUS::Model::DoTS::ExonFeature' =>  ['GUS::Model::DoTS::NAFeatureComment','GUS::Model::DoTS::NALocation','GUS::Model::DoTS::NAFeatureNAGene', 'GUS::Model::DoTS::NAFeatureNAProtein','GUS::Model::DoTS::DbRefNAFeature']);
	
  return ($classChildList{$obj->getClassName()}) ? $classChildList{$obj->getClassName()} : undef; 
 
}

### Methods for dealing with many-to-many relations
sub getManyToManyParent {
  my ($class_name) = @_;
  my %h = ('GUS::Model::DoTS::NASequenceRef' => 'GUS::Model::SRes::Reference',
	   'GUS::Model::DoTS::NASequenceOrganelle' => 'GUS::Model::DoTS::Organelle',
	   'GUS::Model::DoTS::NASequenceKeyword' => 'GUS::Model::DoTS::Keyword', 
	   'GUS::Model::DoTS::NAFeatureNAGene' => 'GUS::Model::DoTS::NAGene',
	   'GUS::Model::DoTS::NAFeatureNAPT' => 'GUS::Model::DoTS::NAPrimaryTranscript',
	   'GUS::Model::DoTS::NAFeatureNAProtein' => 'GUS::Model::DoTS::NAProtein',
	   'GUS::Model::DoTS::DbRefNAFeature' => 'GUS::Model::SRes::DbRef', 
	   'GUS::Model::DoTS::DbRefNASequence' => 'GUS::Model::SRes::DbRef', 
	   'GUS::Model::SRes::ExternalDatabaseKeyword' => 'GUS::Model::SRes::ExternalDatabaseRelease', 
	  );
  return $h{$class_name} ? $h{$class_name} : undef;
}
sub getTheOtherParent {
  my ($class_name) = @_;
  my %h = ('GUS::Model::DoTS::NASequenceRef' => 'GUS::Model::DoTS::NASequenceImp',
	   'GUS::Model::DoTS::NASequenceOrganelle' => 'GUS::Model::DoTS::NASequenceImp',
	   'GUS::Model::DoTS::NASequenceKeyword' => 'GUS::Model::DoTS::NASequenceImp', 
	   'GUS::Model::DoTS::NAFeatureNAGene' => 'GUS::Model::DoTS::NAFeatureImp',
	   'GUS::Model::DoTS::NAFeatureNAPT' => 'GUS::Model::DoTS::NAFeatureImp',
	   'GUS::Model::DoTS::NAFeatureNAProtein' => 'GUS::Model::DoTS::NAFeatureImp',
	   'GUS::Model::DoTS::DbRefNAFeature' => 'GUS::Model::DoTS::NAFeatureImp', 
	   'GUS::Model::DoTS::DbRefNASequence' => 'GUS::Model::DoTS::NASequenceImp', 
	   'GUS::Model::SRes::ExternalDatabaseKeyword' => 'GUS::Model::DoTS::Keyword', 
	  );
  return $h{$class_name} ? $h{$class_name} : undef;
}
### Methods for dealing with many-to-many relations
sub manyToManyObj {
  my ($class_name) = @_;
  my %h = ('GUS::Model::DoTS::NASequenceRef' => 1,
	   'GUS::Model::DoTS::NASequenceOrganelle' => 1,
	   'GUS::Model::DoTS::NASequenceKeyword' => 1, 
	   'GUS::Model::DoTS::NAFeatureNAGene' => 1,
	   'GUS::Model::DoTS::NAFeatureNAPT' => 1,
	   'GUS::Model::DoTS::NAFeatureNAProtein' => 1,
	   'GUS::Model::DoTS::DbRefNAFeature' => 1, 
	   'GUS::Model::DoTS::DbRefNASequence' => 1, 
	   'GUS::Model::SRes::ExternalDatabaseKeyword' => 1, 
	  );
  return ($h{$class_name} ? 1 : 0);
}

sub checkObjectForReplace {
  my ($dbO, $dbP, $newP) = @_;
  my @atts = $dbP->getAttributeDifferences($newP);
  if (scalar @atts) {
    my $cn = $dbP->getClassName();
    $cn =~ s/^NA(.+)/Na$1/;
    my $cmd = 'set' . $cn . 'Id';
    $dbO->$cmd(undef);
    $dbO->removeParent($dbP);
    $dbO->setParent($newP);
  }
}

sub undefCache {
  my (%cache) = @_;
  delete @cache{(keys %cache)};
}

sub getEntryLines {
  my ($fh) = @_;

  my @lines;
  while ( <$fh> ) {
    push(@lines, $_);
    last if /^\/\//;
  }
  return \@lines;
}

sub handleFailure {
  my ($self, $entryLines, $cla, $errMsg) = @_;

  my $failureDir = $cla->{failDir};
  my $failTol = $cla->{failTolerance};

  die "More than $failTol entries failed.  Aborting."
    if ($self->{failCount}++ > $failTol);
  my $failFile = "$failureDir/$self->{entryCnt}.gb";
  open(F, ">$failFile") || die "Can't open failure file $failFile";
  print F join("", @$entryLines);
  close(F);

  my $errFile = "$failureDir/errors";
  open(F, ">>$errFile") || die "Can't open error file $errFile";
  print F " ------------------ entry number $self->{entryCnt} -----------------\n";
  print F "$errMsg\n\n\n";
  close(F);
}

1;

package GUS::Community::FileTranslator::CfgParser;

use strict;
use XML::Simple;
use Tie::IxHash;
use Data::Dumper;

use GUS::Community::FileTranslator::FileReader;

my @xmloptions = ('keyattr' =>  [],
                  'forcearray'=> 1,
                  );

sub new {
  my ($M, $cfgfile, $dbg) = @_;
  unless ($cfgfile) {
    die "ERR: Did not give config file\nCfgFile->new(<cfg file path>)\n" ; 
  }
  my $slf = bless {}, $M;
  $slf->cfgFile($cfgfile);
  $slf->dbg($dbg);
  eval {
    $slf->{PARSER} = XML::Simple->new(@xmloptions);
    my $CFG =  $slf->{PARSER}->XMLin($cfgfile);
    $slf->cfg($CFG);
  };
  die "ERR: Config file $cfgfile error: $@\n" if ($@);
  
  $slf->initializeInputs();
  $slf->initializeOutputs();
  $slf->functionsClass($slf->cfg()->{functions_class});
  print "CfgParser OBJECT DUMP : " . Dumper($slf)     if ($slf->dbg) ;
  return $slf;
}

sub initializeInputs {
  my $slf = shift ;
  
  my $qual =  $slf->cfg->{inputs}->[0]->{qualifier_row_present};
  $slf->qualifier($qual);
  
  my $hdrs = $slf->cfg->{inputs}->[0]->{header}->[0]->{col};
  
  $slf->headers(Tie::IxHash->new());
  $slf->mandatoryHeaders({});
  
  for (my $i = 0; $i < scalar @$hdrs; $i++) {
    my $h = $hdrs->[$i];
    #dos2unix 
    $h->{header_val} =~ s/\r\n/\n/g;
    # take out non-ascii characters
    $h->{header_val} =~ s/[^\x00-\x7f]//g;
    # do header look-up reverse hash
    $slf->header($h->{name},$h);

  }
  $slf;
}

sub header {
    my ($slf,$key,$h) = @_;
    if ($h) {
        # we are defining a header
        $slf->headers()->Push($key => { name => $h->{name},
                                        header_val => $h->{header_val},
                                        req => $h->{req},
                                        qualifier=> $h->{qualifier},
                                    }
                              );
        if ($h->{req}) {
            $slf->mandatoryHeaders()->{ $h->{header_val} } = $h->{header_val}  ;
        }
        
        # do the reverse map
        $slf->headerMap($h->{header_val},$key);
    } else {
        # send value by key 
        return $slf->headers()->FETCH($key) ;
    }
}

sub initializeOutputs {
    my $slf = shift ;
    # the optional IDMAP
    if ($slf->cfg->{outputs}->[0]->{idmap}) {
        my $idmap = $slf->cfg->{outputs}->[0]->{idmap};
        $slf->initializeIdMap($idmap);
    }
    # other MAPS
    my @maps = @{$slf->cfg->{outputs}->[0]->{map}};
    $slf->mappings(Tie::IxHash->new());
    
    for (my $i = 0; $i < scalar @maps; $i++) {
        my $m = $maps[$i];
        $slf->mapping($m->{name},$m);
    }
    $slf;
}

sub initializeIdMap {
    my ($slf,$idmaps) =@_;

    if ($idmaps) {

      foreach my $idmap (@$idmaps) {
        my $tempMap =  { function => $idmap->{function},
                         mapkey => $idmap->{mapkey},
                         output_header => $idmap->{output_header},
                         in => [],
                       };
        foreach my $in (@{ $idmap->{in} } ) {
          push @{ $tempMap->{in} } , $in->{name};
        }

        push @{$slf->{IDMAP}}, $tempMap;
      }
    }

    return $slf->{IDMAP};
}

sub mapping {
    my ($slf, $key , $m) = @_;
    if ($m) {
        # insert a map into mappings
        $slf->mappings()->Push($key => { name => $m->{name},
                                         do => $m->{do},
                                         in => [] ,
                                     });
        foreach my $in (@{ $m->{in} } ) {
            push @{ $slf->mappings->FETCH($key)->{in} } , $in->{name};
        }
    }
    return $slf->mappings->FETCH($key);
}


=pod

=item $boolean = $cfgfile->validate($filereader)

Validates the C<GUS::RAD::FileTranslator::FileReader> input file against 
the mapping configuration file. For now, the only check is that 
the mandatory headers are present.

=cut


sub  validate {
    my ($slf,$in_fh) = @_;
    print "VALIDATING $in_fh \n" if $slf->dbg;
    return 0 unless (UNIVERSAL::isa($in_fh,'GUS::Community::FileTranslator::FileReader'));
    
    my $mand_hdrs = $slf->mandatoryHeaders();
    print "Mandatory headers length = " . (values %$mand_hdrs) . "\n" if $slf->dbg;
    print "Mandatory headers  = ( " . (join " : " , keys  %$mand_hdrs) . " )\n" if $slf->dbg;
    # get to header line off input file 
    my $valid_input = 0;
    while (!$in_fh->eof && !$valid_input ) {
        my @H = split "\t", $in_fh->getline();
        # dos2unix
        @H = map {$_ =~ s/\r\n/\n/g; $_ } @H;
        # take out non-ascii characters
        @H = map {$_ =~ s/[^\x00-\x7f]//g; $_ } @H;
        # take out leading and suffixed whitepspace
        @H = map {$_ =~ s/^\s+|\s+$//g; $_ } @H;
        chomp @H;
        my $mandHeaderCount = 0;
        my $seen = {};
        for (my $i = 0; $i <= @H; $i++) {
            my $h = $H[$i];
            $h =~ s/\"|\'//g;
            $seen->{$h}++;
            if ( $mand_hdrs->{$h}) {
                print STDERR "MAND HDR FOUND $h\n" if $slf->dbg;
                $mandHeaderCount++;
            }
            # assign the index mapping output
            # from the input file, IF the header was mappped.
            if ($slf->headerMap($h)) {
                $slf->headers()->FETCH($slf->headerMap($h)->[ $seen->{$h} - 1 ])->{idx} = $i;
            }
        }
        if ($mandHeaderCount >= scalar values  %$mand_hdrs) {
            # I have all the mandatory headers
            $valid_input = 1;
            last;
        }
    }
    return $valid_input;
}

########################
# Util get/set methods
########################

sub headers { 
  my ($slf, $h ) = @_;
  $slf->{HEADERS} = $h  if (defined $h);
  return $slf->{HEADERS};
}

sub mandatoryHeaders { 
  my ($slf, $h ) = @_;
  $slf->{MAND_HEADERS} = $h  if (defined $h);
  $slf->{MAND_HEADERS};
}

sub mappings {
  my ($slf, $h ) = @_;
  $slf->{MAPS} = $h  if (defined $h);
  $slf->{MAPS};
}

sub idmap {
  my ($slf, $h ) = @_;
  $slf->{IDMAP} = $h  if (defined $h);

  return $slf->{IDMAP};
}

sub idMap { shift()->idmap(@_); }

sub headerMap {
    my ($slf, $key, $val) = @_;
    unless (exists $slf->{HDR_MAP}) {
        $slf->{HDR_MAP} = {};
    }
    if ($val) {
        push @{ $slf->{HDR_MAP}->{$key} },$val;
    } else {
        return $slf->{HDR_MAP}->{$key};
    }
}

sub qualifier { 
  my ($slf, $q ) = @_;
  $slf->{QUAL} = $q  if (defined $q);
  $slf->{QUAL};
}


sub functionsClass { 
  my ($slf, $f ) = @_;
  $slf->{FUNC} = $f  if (defined $f);
  $slf->{FUNC};
}

sub cfg {
  my ($slf, $c ) = @_;
  $slf->{CFG} = $c  if (defined $c);
  $slf->{CFG};
}

sub cfgFile {
  my ($slf, $c ) = @_;
  $slf->{CFG_F} = $c  if (defined $c);
  $slf->{CFG_F};
}

sub dbg {
  my ($slf, $d ) = @_;
  $slf->{DBG} = $d  if (defined $d);
  $slf->{DBG};
}

1;

__END__

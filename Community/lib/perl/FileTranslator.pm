#########################################################################
#vvvvvvvvvvvvvvvvvvvvvvvvv GUS4_STATUS vvvvvvvvvvvvvvvvvvvvvvvvv
  # GUS4_STATUS | SRes.OntologyTerm              | auto   | absent
  # GUS4_STATUS | SRes.SequenceOntology          | auto   | absent
  # GUS4_STATUS | Study.OntologyEntry            | auto   | absent
  # GUS4_STATUS | SRes.GOTerm                    | auto   | absent
  # GUS4_STATUS | Dots.RNAFeatureExon            | auto   | absent
  # GUS4_STATUS | RAD.SageTag                    | auto   | absent
  # GUS4_STATUS | RAD.Analysis                   | auto   | absent
  # GUS4_STATUS | ApiDB.Profile                  | auto   | absent
  # GUS4_STATUS | Study.Study                    | auto   | absent
  # GUS4_STATUS | Dots.Isolate                   | auto   | absent
  # GUS4_STATUS | DeprecatedTables               | auto   | absent
  # GUS4_STATUS | Pathway                        | auto   | absent
  # GUS4_STATUS | DoTS.SequenceVariation         | auto   | absent
  # GUS4_STATUS | RNASeq Junctions               | auto   | absent
  # GUS4_STATUS | Simple Rename                  | auto   | absent
  # GUS4_STATUS | ApiDB Tuning Gene              | auto   | absent
  # GUS4_STATUS | Rethink                        | auto   | absent
  # GUS4_STATUS | dots.gene                      | manual | unreviewed
#die 'This file has broken or unreviewed GUS4_STATUS rules.  Please remove this line when all are fixed or absent';
#^^^^^^^^^^^^^^^^^^^^^^^^^ End GUS4_STATUS ^^^^^^^^^^^^^^^^^^^^
# package GUS::RAD::FileTranslator
#
#   Module to translate one tab-delimited format to another, basically
# for the most part changing the header information and checking that 
# the number of columns stays constant throughout the entire input file.
# Perl code can be embedded into the configuration file, which would 
# evaluate said on the input column value.
#   There is also a special mapping to produce RAD coordinates from 
# an external file format, since this has been primarily produced 
# for parsing data and array design files.
#
# Author: Angel Pizarro (2004)
#
# $Revision$ $Date$ $Author$
#
##########################################################################


package GUS::Community::FileTranslator;

use strict 'vars';
use FileHandle;

use GUS::Community::FileTranslator::FileReader;
use GUS::Community::FileTranslator::CfgParser;


use Data::Dumper;

=pod

=head1 GUS::Community::FileTranslator


  Module to translate one tab-delimited format to another, basically
for the most part changing the header information and checking that 
the number of columns stays constant throughout the entire input file.
Perl code can be embedded into the configuration file, which would 
evaluate said on the input column value.

There is also a special mapping to produce RAD coordinates from 
an external file format, since this has been primarily produced 
for parsing data and array design files.

=head2 Methods

=item $translator = GUS::Community::FileTranslator->new($cfgfile)

Constructor. Takes a an XML file defining a GUS::Community::CfgFile object 
as an argument. 

=cut

sub new {
    my ($M, $cfgfile,$logfile,$dbg) = @_;
    my $slf = bless {}, $M;
    $slf->dbg($dbg);
    $slf->fhlog($logfile);
    unless ($cfgfile) {
        $slf->fhlog()->print("ERR: Did not give config file\nFileTranslator->new(<cfg file path>)\n" );
        die "ERR: Did not give config file\nFileTranslator->new(<cfg file path>)\n" ; 
    }
    eval {
        $slf->cfg( GUS::Community::FileTranslator::CfgParser->new($cfgfile,$dbg) );
    };
    if ($@) {  
        $slf->fhlog->print("ERR: FileTranslator->new($cfgfile): Config file $cfgfile error: $@\n" );
        die "ERR:\tGUS::RAD::FileTranslator->new($cfgfile)Config file $cfgfile error: $@\n" ;
    }

    $slf;
}

=pod 

=item $outputfile = $translator->translate([$filename],[$output_filename])

Translates the input file to the output format 
as specified by the mapping configuration file.
Optional C<$filename> if given sets the input file. 
Optional  C<$outputfile> if given sets the output file,
which defaults to appending ".out" to the input file\'s name

=cut

sub translate {
  my ($slf,$functionArgs, $in, $out) = @_;

  $slf->setInput($in,$out) ;

  my $config = $slf->cfg();
  my $idMaps = $config->idMap();

  my $fileReader = $slf->fhin();
  my $writer = $slf->fhout();
  my $log = $slf->fhlog();

  unless ($slf->validate()) {
    $log->print( "WARN: FileTransalator->translate(): Invalid input file " . $slf->inputfile() . " \n");
    return -1
  }

  $log->print ("#######################################\n");
  $log->print ("Translating file $in\n");
  $log->print ("#######################################\n");

  my @rawHeaders =  split "\t" , $fileReader->currline();
  my $num_hdrs = scalar(@rawHeaders);

  my $functions = $idMaps ? $slf->createMapFunctions($config, $idMaps, $functionArgs) : undef;

  my $headerValues = $slf->makeHeaderArrayRef($config, $idMaps);

  $writer->print(join("\t", @$headerValues) . "\n");

  while ((!$fileReader->eof())) {
    my $line = $fileReader->getline();
    #dos2unix 
    $line =~ s/\r\n/\n/g;

    my @A = split /\t/, $line;
    chomp @A;

    if ($num_hdrs !=  scalar @A) {
      $slf->fhlog->print("WARNING: The following line does not have same number of columns as header (line=" . scalar @A .", header=$num_hdrs)\n");
      $slf->fhlog->print("LN=" . $slf->fhin()->linenum() . ":\t$line\n");
    }

    # rest of MAPS
    my @V ;

    foreach my $mapkey ($config->mappings()->Keys) {
      my $input = $config->mappings()->FETCH($mapkey)->{in}->[0];
      my $val = "" ;
      if (exists $config->header($input)->{idx}) {
        $val = $A[$config->header($input)->{idx}];
      }
      push @V, $val ;
    }
    $writer->print( (join "\t" , @V) );

    if ($idMaps) {

      for(my $i = 0; $i < scalar(@$idMaps); $i++) {
        my $idMap = $idMaps->[$i];
        my $function = $functions->[$i];

        my $mapkey = $idMap->{mapkey};
        my $values = $slf->translateMapKey(\@A, $mapkey, $idMap, $config);


        # Allow the Funtion to give a coderef OR hashref 
        if(ref($function) eq 'CODE') {
          $writer->print("\t" . $function->( join "\t", @$values ) );
        }
        else {
          $writer->print("\t" . $function->{ join "\t", @$values } );
        }

      }

    }
    $writer->print( "\n" ); 


  }
  # all parsing successful 
  $log->print("File translated to " . $slf->outputfile . " \n\n");

  return $slf->outputfile;
}

sub translateMapKey {
  my ($slf, $A, $mapkey, $idMap, $config) = @_;

  my @V ;

  my @MK = split /\\t/, $mapkey ;

  foreach my $k (@MK) {
    my $found;
    foreach my $in (@{ $idMap->{in} } ) {
      if ('$' . $in  eq $k ) {
        push @V, $A->[$config->header($in)->{idx}];
        $found++;
      }
      else {
        push @V, $k;
      }
    }
    push @V, $k unless $found;
  }
  return \@V;
}




sub createMapFunctions {
  my ($slf, $config, $idMaps, $functionArgs) = @_;

  my @functions;

  my $log = $slf->fhlog();

  foreach my $idmap(@$idMaps) {
    my $idfunc = $idmap->{function};

    my $functionClassName =  $config->functionsClass();

    eval "require $functionClassName";

    my $function = eval {my $functionClass = $functionClassName->new(); 
                         $functionClass->$idfunc($functionArgs);
                       };
    if ($@) {
      $log->print("ERR: sub=translate: $@\n");
      die "ERR: FileTranslator->translate() : $@\n" ;
    } 

    push(@functions, $function);
  }
  return \@functions;
}



sub makeHeaderArrayRef {
  my ($slf, $config, $idMaps) = @_;

  my @headers;

  push(@headers, $config->mappings()->Keys);

  if ($idMaps) {

    foreach my $idMap (@$idMaps) {
      my @idh = split /\\t/ , $idMap->{output_header};
      push(@headers, @idh); 
    }
  }



  return \@headers;
}



=pod 

=item $boolean = $translator->validate([$filename])

Validates the input file against the mapping configuration file.
For now, the only check is that the mandatory headers are present. 
If a file is given as an argument, it will validate this file
BUT NOT set it as the input file!

=cut

sub validate {
  my ($slf,$file) = @_;
  my $in_fh;
  if ($file) {
    $in_fh = GUS::Community::FileTranslator::FileReader->new($file);
  }else {
    $in_fh = $slf->fhin();
  }
  return $slf->cfg()->validate($in_fh);
}

=pod 

=item $boolean = $translator->setInput($input_filename_path, [$output_filename_path])

Opens C<$input_filename_path> in a FileReader buffer.
Optional  C<$output_filename_path> if given sets the output file,
which defaults to appending ".out" to C<$input_filename_path> .

=cut

sub setInput {
  my ($slf , $in_file, $out_file) = @_;
  
  # set optional $out_file arg
  $out_file = $out_file ? $out_file : $in_file . ".out" ;
  
  eval {
    $slf->inputfile( $in_file);
    $slf->fhin( GUS::Community::FileTranslator::FileReader->new($in_file));
  };
  $slf->fhlog()->print("ERR: Input file $in_file error: $@\n" ) if ($@);
  
  eval {
    $slf->outputfile($out_file);
    $slf->fhout(FileHandle->new($out_file, ">" ));
  };
  $slf->fhlog()->print( "ERR: Output file $out_file error: $@\n") if ($@);
  
  return $slf;
}


#######################
# UTil functions
#######################

sub fhin {
  my ($slf, $f ) = @_;
  $slf->{IN} = $f  if ($f);
  $slf->{IN};
}

sub fhout {
  my ($slf, $f ) = @_;
  $slf->{OUT} = $f  if ($f);
  $slf->{OUT};
}

sub fhlog {
  my ($slf, $f ) = @_;
  if ($f) {
    print STDERR "LOGFILE=$f\n" if $slf->dbg;
    $slf->{LOG} = FileHandle->new($f, ">") or die "lof file $f not open \n";
  }
  $slf->{LOG};
}

sub inputfile {
  my ($slf, $f ) = @_;
  $slf->{IN_F} = $f  if ($f);
  $slf->{IN_F};
}

sub outputfile {
  my ($slf, $f ) = @_;
  $slf->{OUT_F} = $f  if ($f);
  $slf->{OUT_F};
}

sub cfg {
  my ($slf, $c ) = @_;
  $slf->{CFG} = $c  if ($c);
  $slf->{CFG};
}

sub dbg {
  my ($slf, $d ) = @_;
  $slf->{DBG} = $d  if ($d);
  $slf->{DBG};
}


1; 

__END__


#########################################################################
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
    my ($slf,$functionSpecificHash, $in, $out) = @_;
    
    if ($in) {
        $slf->setInput($in,$out) ;
    }
    
    $slf->fhlog->print ("#######################################\n");
    $slf->fhlog->print ("Translating file $in\n");
    $slf->fhlog->print ("#######################################\n");
    #first make sure we have a file to parse & someplace to write
    return undef unless (defined $slf->fhin);
    return undef unless (defined $slf->fhout);
    unless ($slf->validate()) {
        $slf->fhlog->print( "WARN: FileTransalator->translate(): Invalid input file " . $slf->inputfile() . " \n");
        return -1;
    }
    
    # header line(s)
    my @QUALHDRS = split "\t" , $slf->fhin->prevline();
    my @HDRS =  split "\t" , $slf->fhin->currline();
    my $num_hdrs = scalar @HDRS;
    # output the header line
    # optional ID MAP
    # while we are at it, might as well set get the 
    # idmap hash from the function 
    my $idmaphash;

    if ($slf->cfg->idMap()) {
        my @idh = split /\\t/ , $slf->cfg->idMap()->{output_header};
        $slf->fhout->print(  (join "\t" , @idh ) . "\t" );
        my $idfunc = $slf->cfg->idMap()->{function};
        my $funcclass =  $slf->cfg->functionsClass();
        $funcclass =~ s/\:\:/\//g;
        $funcclass .= ".pm";
        $idmaphash = eval {require  $funcclass;
                           my $f = $slf->cfg->functionsClass()->new(); 
                           $idmaphash  = $f->$idfunc($functionSpecificHash);
                           return $idmaphash;
                          };
        if ($@) {
            $slf->fhlog()->print("ERR: sub=translate: $@\n");
            die "ERR: FileTranslator->translate() : $@\n" ;
        } 
    }
    # rest of MAPS
    $slf->fhout->print( (join "\t", $slf->cfg->mappings()->Keys) . "\n");
  
    # now do the row translation 
    
    while ((!$slf->fhin->eof())) {
        my $line = $slf->fhin->getline();
        #dos2unix 
        $line =~ s/\r\n/\n/g;
        # split columns
        my @A = split /\t/, $line;
        chomp @A;

        if ($num_hdrs !=  scalar @A) {
            $slf->fhlog->print("WARNING: The following line does not have same number of columns as header (line=" . scalar @A .", header=$num_hdrs)\n");
            $slf->fhlog->print("LN=" . $slf->fhin()->linenum() . ":\t$line\n");
            # next;
        }
        
        # optional ID MAP
        if ($slf->cfg->idMap()) {
            my $mapkey = $slf->cfg->idMap->{mapkey};
            $mapkey =~ s/\$//g; # replace all dollar signs
            my @MK = split /\\t/, $mapkey ;
            my @V ;
            foreach my $k (@MK) {
                foreach my $in (@{ $slf->cfg->idMap->{in} } ) {
                    if ($in  eq $k ) {
                        push @V, $A[$slf->cfg->header($in)->{idx}];
                    }
                }
            }

            # Allow the Funtion to give a coderef instead of hashref 
            if(ref($idmaphash) eq 'CODE') {
              $slf->fhout->print($idmaphash->( join "\t", @V ) . "\t");
            }
            else {
              $slf->fhout->print($idmaphash->{ join "\t", @V } . "\t");
            }
        }
    
        # rest of MAPS
        my @V ;
        foreach my $mapkey ($slf->cfg->mappings()->Keys) {
            # we can take a shortcut, cause I know that all the other maps are simple.
            my $input = $slf->cfg->mappings()->FETCH($mapkey)->{in}->[0];
            my $val = "" ;
            if (exists $slf->cfg->header($input)->{idx}) {
                $val = $A[$slf->cfg->header($input)->{idx}];
            }
            push @V, $val ;
        }
        $slf->fhout->print( (join "\t" , @V) . "\n" );
    }
    # all parsing successful 
    $slf->fhlog->print("File translated to " . $slf->outputfile . " \n\n");
    return $slf->outputfile;
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


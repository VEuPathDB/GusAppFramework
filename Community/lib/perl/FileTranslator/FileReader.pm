package GUS::RAD::FileTranslator::FileReader;

# GUS::RAD::FileTranslator::FileReader
#
# A front end for C<FileHandle> with a simple one-line read buffer. 
# 
# Author: Angel Pizarro
# $Revision$ $Date$ $Author$ 

use strict 'vars';
use FileHandle; 

sub new {
  my ($M,$f) = @_;
  my $slf = bless {}, $M;
  $slf->{FH} = new FileHandle $f;
  $slf->{CURRLINE} = undef;
  $slf->{PREVLINE} = undef;
  return $slf;
}

sub linenum { $_[0]->{FH}->input_line_number }

sub eof {
  my $slf = shift;
  return $slf->{FH}->eof;
}

sub getline {
  my $slf = shift;
  if ($slf->eof) { return  $slf->eof ; }
  $slf->prevline( $slf->currline() );
  $slf->currline( $slf->{FH}->getline() );
  return $slf->currline();
}

sub prevline {
  my ($slf,$l) = @_; 
  if ($l) { 
    $slf->{PREVLINE}=$l; 
  }
  $slf->{PREVLINE};
}

sub currline {
  my ($slf,$l) = @_; 
  if ($l) {
    $slf->{CURRLINE} = $l; 
  }
  $slf->{CURRLINE};
}


1;

__END__

=pod 

=head1 RAD::DataLoad::FileReader

A simple wrapper for C<FileHandle> with a 
one line buffer for the previous line encountered.

=head2 USAGE 

  $filereader = FileReader->new($file) ;
  $newline = $filereader->getline();
  $currline = $filereader->currline(); # same as $newline
  $newline = $filereader->getline();
  $currline = $filereader->currline(); # same as $newline
  $prevline = $filereader->prevline(); # got line before $newline, 
                                       # eg. the first getline() call

=head2 METHODS


=item $fr->new(<filename>)

Constructor. takes in a file path to open. 
Dies with error if unable to open file.

=item $fr->eof()

Returns true if EOF is reached

=item $fr->getline()

Same as FileHandle->getline(), but sticks previous line into 
the one line buffer

=item $fr->currline()

Retrieves the last line from getline() call 

=item $fr->prevline()

Retrieves the line from next-to-last getline() call 


=cut



 



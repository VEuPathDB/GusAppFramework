#  $Revision$   $Date$   $Author$

package GUS::Community::FileTranslator::Functions;

use strict;

sub new {
  my ($M) = @_;
  my $self = {};
  bless $self,$M;
  
  return $self;
}

#--------------------------------------------------------------------------------

sub qPercentToConfidence {

  my $qPercent2Conf; $qPercent2Conf = sub {
    my $confidence = shift;

    return (100 - $confidence) / 100;
  };

  return $qPercent2Conf;
}

#--------------------------------------------------------------------------------

sub maxConfAndFoldChange {
  my ($self, $hash) = @_;

  my $baseX = $hash->{baseX};

  my $maxConfAndFc; $maxConfAndFc = sub {
    my $valuesString = shift;

    my ($conf0, $conf1, $mean0, $mean1) = split(/\t/, $valuesString);

    my $max = $conf0 >= $conf1 ? $conf0 : $conf1;

    if($baseX) {
      $mean0 = $baseX ** $mean0;
      $mean1 = $baseX ** $mean1 if(defined($mean1));
    }

    my $foldChange;
    if(!$mean1) {
      $foldChange = $mean0 < 1 ? -(1/$mean0) : $mean0;
    }
    else {
      $foldChange = $mean0 > $mean1 ? -($mean0/$mean1) : $mean1/$mean0;
    }
    return "$max\t$foldChange";
  };

  return $maxConfAndFc;
}


# Why does the mapping need to be a hash??  Why not give it a subroutine
# to calculate a value?
#--------------------------------------------------------------------------------

sub max {

  my $findMax; $findMax = sub {
    my $valuesString = shift;

    my @values = split(/\t/, $valuesString);

    my $max = shift(@values);

    foreach(@values) {
      $max = $_ if $max < $_;
    }
    return $max;
  };

  return $findMax;
}


#--------------------------------------------------------------------------------

sub foldChange {
  my ($self, $hash) = @_;

  if($hash->{numberOfChannels} != 1) {
    die "Only One channel data currently can calculate fold change";
  }

  my $fc; $fc = sub {
    my $valuesString = shift;

    my ($mean0, $mean1) = split(/\t/, $valuesString);

    if($mean0 >= $mean1) {
      return $mean0/$mean1;
    }

    return -($mean1/$mean0);
  };

  return $fc;
}

#--------------------------------------------------------------------------------

sub nameToElementId {
  my ($self, $hash) = @_;

  my %mapping;

  unless($hash->{dbh}) {
    die "Function [nameToCompositeElementId] must give a database handle";
  }

  unless($hash->{arrayDesignName}) {
    die "Function [nameTOCompositeElementId] must give an arrayDesignName";
  }

  my $sql = "select s.name, s.element_id 
             from  Rad.Spot s, Rad.ArrayDesign a
             where s.array_design_id = a.array_design_id
              and (a.name = ? OR a.source_id = ?)";

  my $arrayDesignName = $hash->{arrayDesignName};

  my $sh = $hash->{dbh}->prepare($sql);
  $sh->execute($arrayDesignName, $arrayDesignName);

  while(my ($name, $id) = $sh->fetchrow_array()) {
    $mapping{$name} = $id;
  }
  $sh->finish();

  return \%mapping;
}


#--------------------------------------------------------------------------------

sub nameToCompositeElementId {
  my ($self, $hash) = @_;

  my %mapping;

  unless($hash->{dbh}) {
    die "Function [nameToCompositeElementId] must give a database handle";
  }

  unless($hash->{arrayDesignName}) {
    die "Function [nameTOCompositeElementId] must give an arrayDesignName";
  }

  my $sql = "select s.name, s.composite_element_id 
             from  Rad.ShortOligoFamily s, Rad.ArrayDesign a
             where s.array_design_id = a.array_design_id
              and (a.name = ? OR a.source_id = ?)";

  my $arrayDesignName = $hash->{arrayDesignName};

  my $sh = $hash->{dbh}->prepare($sql);
  $sh->execute($arrayDesignName, $arrayDesignName);

  while(my ($name, $id) = $sh->fetchrow_array()) {
    $mapping{$name} = $id;
  }
  $sh->finish();

  return \%mapping;
}

#--------------------------------------------------------------------------------

sub featureLocationToElementId {
  my ($self, $hash) = @_;

  my %mapping;

  unless($hash->{dbh}) {
    die "Function [featureLocationElementId] must give a database handle";
  }

  unless($hash->{arrayDesignName}) {
    die "Function [nameTOCompositeElementId] must give an arrayDesignName";
  }

  my $sql = "select s.array_row, s.array_column, s.grid_row, s.grid_column, s.sub_row, s.sub_column, s.element_id
             from Rad.SPOT s, Rad.ARRAYDESIGN a
             where a.array_design_id = s.array_design_id 
              and (a.name = ? OR a.source_id = ?)";

  my $arrayDesignName = $hash->{arrayDesignName};

  my $sh = $hash->{dbh}->prepare($sql);
  $sh->execute($arrayDesignName, $arrayDesignName);

  while(my ($ar, $ac, $gr, $gc, $sr, $sc, $id) = $sh->fetchrow_array()) {
    my $featureLocation = "$ar.$ac.$gr.$gc.$sr.$sc";

    $mapping{$featureLocation} = $id;
  }
  $sh->finish();

  return \%mapping;
}


#--------------------------------------------------------------------------------

sub coordGenePix2RAD{
  my ($self, $hash) = @_;

  my $n_ar = $hash->{num_array_rows};
  my $n_ac = $hash->{num_array_columns};
  my $n_gr = $hash->{num_grid_rows};
  my $n_gc = $hash->{num_grid_columns};
  my $n_sr = $hash->{num_sub_rows};
  my $n_sc = $hash->{num_sub_columns};

  my $mapping;
  
  for (my $ar=1; $ar<=$n_ar; $ar++) {
    for (my $ac=1; $ac<=$n_ac; $ac++) {
      for (my $gr=1; $gr<=$n_gr; $gr++) {
        for (my $gc=1; $gc<=$n_gc; $gc++) {
          for (my $sr=1; $sr<=$n_sr; $sr++) {
            for (my $sc=1; $sc<=$n_sc; $sc++) {
              my $b = ($ar-1)*$n_ac*$n_gr*$n_gc+($gr-1)*$n_ac*$n_gc+($ac-1)*$n_gc+$gc;
              $mapping->{"$b\t$sr\t$sc"} = "$ar\t$ac\t$gr\t$gc\t$sr\t$sc";
            }
          }
        }
      }
    }
  }
  return $mapping;
}

sub coordArrayVision2RAD{
  my ($self, $hash) = @_;

  my $n_ar = $hash->{num_array_rows};
  my $n_ac = $hash->{num_array_columns};
  my $n_gr = $hash->{num_grid_rows};
  my $n_gc = $hash->{num_grid_columns};
  my $n_sr = $hash->{num_sub_rows};
  my $n_sc = $hash->{num_sub_columns};

  my $mapping;

  if ($n_ar==1 && $n_ac==1 && $n_gr==1 && $n_gc==1) {
    for (my $sr=1; $sr<=$n_sr; $sr++) {
      for (my $sc=1; $sc<=$n_sc; $sc++) {
        $mapping->{"$sr - $sc"} = "1\t1\t1\t1\t$sr\t$sc";
        # below are 2 safety nets
        $mapping->{"1 - 1 : $sr - $sc"} = "1\t1\t1\t1\t$sr\t$sc";
        $mapping->{"1 - 1 : 1 - 1 : $sr - $sc"} = "1\t1\t1\t1\t$sr\t$sc";
      }
    }
  }
  elsif ($n_ar==1 && $n_ac==1) {
    for (my $gr=1; $gr<=$n_gr; $gr++) {
      for (my $gc=1; $gc<=$n_gc; $gc++) {
        for (my $sr=1; $sr<=$n_sr; $sr++) {
          for (my $sc=1; $sc<=$n_sc; $sc++) {
            $mapping->{"$gr - $gc : $sr - $sc"} = "1\t1\t$gr\t$gc\t$sr\t$sc";
            # below is a safety net
            $mapping->{"1 - 1 : $gr - $gc : $sr - $sc"} = "1\t1\t$gr\t$gc\t$sr\t$sc";
          }
        }
      }
    }
  }
  else {
    for (my $ar=1; $ar<=$n_ar; $ar++) {
      for (my $ac=1; $ac<=$n_ac; $ac++) {
        for (my $gr=1; $gr<=$n_gr; $gr++) {
          for (my $gc=1; $gc<=$n_gc; $gc++) {
            for (my $sr=1; $sr<=$n_sr; $sr++) {
              for (my $sc=1; $sc<=$n_sc; $sc++) {
                $mapping->{"$ar - $ac : $gr - $gc : $sr - $sc"} = "$ar\t$ac\t$gr\t$gc\t$sr\t$sc";
              }
            }
          }
        }
      }
    }
  }
  return $mapping;
}

sub lineNum2RAD{
  my ($self, $hash) = @_;

  my $n_ar = $hash->{num_array_rows};
  my $n_ac = $hash->{num_array_columns};
  my $n_gr = $hash->{num_grid_rows};
  my $n_gc = $hash->{num_grid_columns};
  my $n_sr = $hash->{num_sub_rows};
  my $n_sc = $hash->{num_sub_columns};

  my $mapping;
 
  my $lineNum = 0;
  for (my $ar=1; $ar<=$n_ar; $ar++) {
    for (my $ac=1; $ac<=$n_ac; $ac++) {
      for (my $gr=1; $gr<=$n_gr; $gr++) {
        for (my $gc=1; $gc<=$n_gc; $gc++) {
          for (my $sr=1; $sr<=$n_sr; $sr++) {
            for (my $sc=1; $sc<=$n_sc; $sc++) {
              $lineNum++;
              $mapping->{"$lineNum"} = "$ar\t$ac\t$gr\t$gc\t$sr\t$sc";
            }
          }
        }
      }
    }
  }
  return $mapping;
}

1;
__END__

=head1 GUS::Community::FileTranslator::Functions

=head2 Methods

=head3 sub new();

 Purpose:
  Creates a new instance of GUS::Community::FileTranslator::Functions
 Returns:
  GUS::Community::FileTranslator::Functions object instance.

=head3 sub coordGenePix2RAD($num_array_rows, $num_array_columns, $num_grid_rows, $num_grid_columns, $num_sub_rows, $num_sub_columns);

 Purpose:
  Creates a hash for the mapping of GenePix coordinates (Block, Row, Columns) to RAD coordinates (array_row, array_column, grid_row, grid_column, sub_row, sub_column), using information on the array layout.
 Returns:
  A reference to a hash whose keys are tab-delimited triplets of GenePix coordinates and whose values are tab-delimited 6-ples of RAD coordinates.

=head3 sub coordArrayVision2RAD($num_array_rows, $num_array_columns, $num_grid_rows, $num_grid_columns, $num_sub_rows, $num_sub_columns);

 Purpose:
  Creates a hash for the mapping of ArrayVision Spot Labels column (with dashes and colons) to RAD coordinates (array_row, array_column, grid_row, grid_column, sub_row, sub_column), using information on the array layout.
 Returns:
  A reference to a hash whose keys are the strings in the Spot Labels column of an ArrayVision output file and whose values are tab-delimited 6-ples of RAD coordinates.

=head3 sub lineNum2RAD($num_array_rows, $num_array_columns, $num_grid_rows, $num_grid_columns, $num_sub_rows, $num_sub_columns);

 Purpose:
  Creates a hash for the mapping of line numbers (such as the Agilent FeatureNum) to RAD coordinates (array_row, array_column, grid_row, grid_column, sub_row, sub_column), using information on the array layout.
 Returns:
  A reference to a hash whose keys are the line numbers of a data file (e.g. the strings in the Agilent FeatureNum column) and whose values are tab-delimited 6-ples of RAD coordinates.

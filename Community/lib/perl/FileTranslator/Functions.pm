#  $Revision$   $Date$   $Author$

package GUS::Community::FileTranslator::Functions;

use strict;

use lib "$ENV{GUS_HOME}/lib/perl";

use Date::Parse;

use Data::Dumper;

sub new {
  my ($M) = @_;
  my $self = {};
  bless $self,$M;
  
  return $self;
}


#--------------------------------------------------------------------------------

sub formatDate {
  my ($self,$hash) = @_;
  my $formatDate; $formatDate = sub {
    my $valuesString = shift;
    my ($date,$char) = split("\t",$valuesString);
    return undef unless $date;
    my  ($junk1,$junk2,$junk3,$day,$month,$year) = strptime($date);
    print stderr $day; 
    $month += 1;
    die "invalid month $date, $year-$month-$day " unless (0< $month &&  $month<13);
    die "invalid day for $date, $year-$month-$day " unless (0< $day &&  $day <32);
    $day = "0".$day if length($day) == 1;
    $month = "0".$month if $month <10;
    $year = $year < 16 ? $year +2000 : $year+1900;
    my $formatted_date = $year.$month.$day;
    die "date is messed up $formatted_date"  unless (length($year.$month.$day) == 8);
    return $formatted_date;
  };
return $formatDate;
}

#--------------------------------------------------------------------------------

sub formatEuroDate {
  my ($self,$hash) = @_;
  my $formatEuroDate; $formatEuroDate = sub {
    my $valuesString = shift;
    my ($date,$char) = split("\t",$valuesString);
    return undef unless $date;
    ($date) = split(' ',$date);
    my @tokens = split ("/",$date);
    my $token_holder = $tokens[2];
    $tokens[2] = $tokens[0];
    $tokens[0] = $token_holder;
    $date = join ("-",@tokens);
    ($date) = split(' ',$date);
    my  ($junk1,$junk2,$junk3,$day,$month,$year) = strptime($date);
    $month += 1;
    die "invalid month $date, $year-$month-$day " unless (0< $month &&  $month<13);
    die "invalid day for $date, $year-$month-$day " unless (0< $day &&  $day <32);
    $day = "0".$day if length($day) == 1;
    $month = "0".$month if $month <10;
    $year = $year < 16 ? $year +2000 : $year+1900;
    my $formatted_date = $year.$month.$day;
    die "date is messed up $formatted_date"  unless (length($year.$month.$day) == 8);
    return $formatted_date;
  };
return $formatEuroDate;
}

#--------------------------------------------------------------------------------

sub swapMappedValues {
  my ($self,$hash) = @_;
  my $mapHash = $hash->{'map_hash'};
  my $swapMappedValues; $swapMappedValues = sub {
    my $valuesString = shift;
    my ($value,$char) = split("\t",$valuesString);
    return undef unless defined  $value ;
    return $value unless defined $char;
    
    $char = lc($char);
    my $lv = lc($value);
    open ( TEST, '>>', "/home/jcade/tester1.out");
    print TEST "start point \n";
    if (defined ($mapHash->{$char})) {
      if (defined ($mapHash->{$char}->{$lv})) {
        print TEST $char."\t". $value."\n";
        $value = $mapHash->{$char}->{$lv};
        $value = '' if $value =~/^null$/; 
        print TEST $char."\t". $value."\n";
      }
    }
    print TEST "final answer $value\n";
    return $value;
  };
  return $swapMappedValues;
}


#--------------------------------------------------------------------------------

sub swapMappedValueSet {
  my ($self,$hash) = @_;
  my $mapHash = $hash->{'map_hash'};
  my $swapMappedValues; $swapMappedValues = sub {
    my $valuesString = shift;
    my ($valueSet,$char) = split("\t",$valuesString);
    return undef unless defined  $valueSet;
    return $valueSet unless defined $char;
    
    my @values = split(",",$valueSet);
    $char = lc($char);
    my @RV;
    foreach my $value (@values) {
      my $lv = lc($value);
      open ( TEST, '>>', "/home/jcade/tester1.out");
      print TEST "start point \n";
      if (defined ($mapHash->{$char})) {
        if (defined ($mapHash->{$char}->{$lv})) {
          print TEST $char."\t". $value."\n";
          $value = $mapHash->{$char}->{$lv};
          $value = '' if $value =~/^null$/; 
          print TEST $char."\t". $value."\n";
        }
      }
      print TEST "final answer $value\n";
      push @RV, $value;
    }
    @RV = sort@RV;
    print Dumper \@RV;
    $valueSet = join(",",@RV);
    print STDERR $valueSet;
    return $valueSet;
  };
  return $swapMappedValues;
}
#--------------------------------------------------------------------------------

sub formatHouseholdId {
  my ($self,$hash) = @_;

  my $formatHouseholdId; $formatHouseholdId = sub {
    my $valuesString = shift;
    my ($value,$char) = split("\t",$valuesString);
    if ($value=~/^HH\d+$/i) {
      $value = uc($value);
    }
    else {
      $value = "HH$value";
    }
    return $value;
  };
  return $formatHouseholdId;
}

#--------------------------------------------------------------------------------

sub replaceValues {
  my ($self,$hash) = @_;
  my $replaceValues; $replaceValues = sub {
    my $valuesString = shift;
    my ($value,$replaceString) = split("\t",$valuesString);
    $value = $replaceString if defined $value;
    return $value;
  };
  return $replaceValues;
}

#--------------------------------------------------------------------------------

sub stripLeadingRegex {
  my ($self,$hash) = @_;
  my $stripLeadingRegex; $stripLeadingRegex = sub {
    my $valuesString = shift;
    my ($value,$regex) = split("\t",$valuesString);
    $value =~s/^$regex//i;
    return $value;
  };
  return $stripLeadingRegex;
}

#--------------------------------------------------------------------------------


sub stripTrailingRegex {
  my ($self,$hash) = @_;
  my $stripTrailingRegex; $stripTrailingRegex = sub {
    my $valuesString = shift;
    my ($value,$regex) = split("\t",$valuesString);
    $value =~s/$regex$//i;
    return $value;
  };
  return $stripTrailingRegex;
}

#--------------------------------------------------------------------------------

sub makeCompositeId {
  my ($self,$hash) = @_;
  my $makeCompositeId; $makeCompositeId = sub {
    my $valuesString = shift;
    my ($parent,$month, $year) = split("\t",$valuesString);
    my $id = $parent.$year.$month;
    $id =~ s/\W//g;
    return $id;
  };
  return $makeCompositeId;
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

## The below function will not map correctly when array layout is non-trivial
## Make sure all array_row	array_col	grid_row	grid_col are 1 before apply
sub agilentLocationToElementId {
  my ($self, $hash) = @_;

  my %mapping;

  unless($hash->{dbh}) {
    die "Function [agilentLocationElementId] must give a database handle";
  }

  unless($hash->{arrayDesignName}) {
    die "Function [agilentLocationElementId] must give an arrayDesignName";
  }

  my $sql = "select s.sub_row, s.sub_column, s.element_id
             from Rad.SPOT s, Rad.ARRAYDESIGN a
             where a.array_design_id = s.array_design_id 
              and (a.name = ? OR a.source_id = ?)";

  my $arrayDesignName = $hash->{arrayDesignName};

  my $sh = $hash->{dbh}->prepare($sql);
  $sh->execute($arrayDesignName, $arrayDesignName);

  while(my ($row, $col, $id) = $sh->fetchrow_array()) {
    my $featureLocation = "$row\t$col";

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

#--------------------------------------------------------------------------------

# requires row\tcol\t to be passed in
sub coordAgilent2RAD {
  my $coord; $coord = sub {
    my $valuesString = shift;


    return "1\t1\t1\t1\t$valuesString";
  };
  return $coord;  
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

package GUS::RAD::Utils::InformationQueries;

sub new {
  my ($M,$dbh,$dbg) = @_;
  my $slf = {};
  bless $slf,$M;
  $slf->dbh($dbh);
  $slf->dbg($dbg);
  return $slf;
}

sub getStudyInfo{
  my ($slf,$id) = @_;
  my $sql = qq[select s.study_id, s.name, sa.assay_id
              from rad3.study s, rad3.studyassay sa
              where s.study_id = sa.study_id
              and s.study_id = $id ];
  my $result = $slf->runquery($sql);
  my $study  = {};
  foreach my $r (@$result) {
    $study->{study_id}  = $r->{study_id};
    $study->{name} = $r->{name};
    push @{$study->{assays}} , $r->{assay_id};
  }
  return $study;
}

sub getArrayInfo{
  my ($slf,$id) = @_;
  my $sql = qq[select a.array_id, a.name, a.platform_type_id, 
              oept.value as platform_type, a.substrate_type_id, 
              oest.value as substrate_type, 
              a.array_dimensions, a.element_dimensions, a.num_array_rows,
              a.num_array_columns ,a.num_grid_rows, a.num_grid_columns,
              a.num_sub_rows, a.num_sub_columns, a.num_array_rows, 
              a.num_array_rows
              from rad3.array a , rad3.ontologyentry oept, 
              rad3.ontologyentry oest
              where a.array_id = $id
              and oept.ontology_entry_id = a.platform_type_id
              and oest.ontology_entry_id (+) = a.substrate_type_id
              ];
  my $result = $slf->runquery($sql);
  my $array = {};
  foreach my $r (@$result) {
    $array = $r;
  }
  
  #get the subclass_view for the array features or reporters
  my $table = "" ; 
  if ($array->{platform_type_id } == 10 ) {
    # This is affy array, query compositeelementimp
    $table = 'rad3.compositeelementimp';
  }elsif ($array->{platform_type_id } == 3 ) {
    # This is spotted dna array, query elementimp
    $table = 'rad3.elementimp';
  }
  $sql = qq[select subclass_view from $table where array_id = $id and rownum = 1];
  $array->{subclass_view} =   $slf->runquery($sql)->[0]->{subclass_view};
  return $array;
}

sub getAssayInfo{
  my ($slf,$id) = @_;
  my $sql = qq[select a.assay_id, a.name, a.array_id, a.protocol_id, a.assay_date,
               a.array_identifier, a.array_batch_identifier, a.operator_id,
               edb.external_database_id, a.external_database_release_id,
               a.source_id, a.description, acq.acquisition_id
               from rad3.acquisition acq , rad3.assay a, sres.externaldatabaserelease edb
               where a.assay_id = $id
               and a.assay_id = acq.assay_id (+)
               and a.external_database_release_id =edb.external_database_release_id (+) ];
  my $result = $slf->runquery($sql);
  my $assay  = {};
  foreach my $r (@$result) {
    foreach my $k (keys %$r) {
      if ($k eq 'acquisition_id' ) {
        push @{$assay->{acquisitions}} , $r->{$k};
      }else {
        $assay->{$k} = $r->{$k};
      }
    }
  }
  return $assay;
}

sub getAcquisitionInfo{
  my ($slf,$id) = @_;
  my $sql = qq[select a.acquisition_id, ra.associated_acquisition_id as assoc_acquisition_id,
               a.channel_id, c.name as channel, a.uri, q.quantification_id
               from rad3.acquisition a, rad3.relatedacquisition ra, rad3.channel c,
               rad3.quantification q
               where a.acquisition_id = $id
               and a.acquisition_id = ra.acquisition_id (+)
               and a.acquisition_id = q.acquisition_id (+)
               and c.channel_id (+) = a.channel_id
               ];
  my $result = $slf->runquery($sql);
  my $acq = {} ;
  foreach my $r (@$result) {
    foreach my $k (keys %$r) {
      if ($k eq 'quantification_id' ) {
        push @{$acq->{quantifications}} , $r->{$k};
      }else {
        $acq->{$k} = $r->{$k};
      }
    }
  }
  return $acq;
}

sub getQuantificationInfo{
  my ($slf,$id) = @_;
  my $sql = qq[select q.quantification_id, pr.name as project_name, g.name as group_name,
              rq.associated_quantification_id as assoc_quantification_id,
              q.acquisition_id , q.name, q.uri, p.protocol_id, p.name as protocol_name
              from rad3.quantification q, rad3.relatedquantification rq, rad3.protocol p, core.projectinfo pr, core.groupinfo g
              where q.quantification_id = $id
              and  q.quantification_id = rq.quantification_id (+)
              and q.protocol_id = p.protocol_id (+)
              and q.row_project_id= pr.project_id
              and q.row_group_id=g.group_id
              ];
  my $result = $slf->runquery($sql);
  my $quant ={};
  foreach my $r (@$result) {
    foreach my $k (keys %$r) {
      $quant->{$k} = $r->{$k};
    }
  }
  return $quant;
}

##########################################
# SUPPORT FUNCTIONS
##########################################

sub runquery {
  my ($slf,$q) = @_;
  print STDERR "QUERY=$q\n" if $slf->dbg;
  my $A;
  eval {
    my $st = $slf->dbh->prepare($q);
    
    $st->execute() ;
    while (my $r = $st->fetchrow_hashref('NAME_lc')) {
      push @$A, $r;
    }
    $st->finish;
  };
  $slf->err("$slf -> runquery($q):" . $@) if $@;
  return $A;
}

sub err {
  my ($slf,$m) = @_;
  print STDERR "ERR [" . (localtime) . "]\t$m\n";
}

sub dbh {
  my ($slf,$dbh) = @_;
  $slf->{__DBH} = $dbh if $dbh;
  return $slf->{__DBH};
}

sub dbg {
  my ($slf,$dbg) = @_;
  $slf->{__DBG} = $dbg if $dbg;
  return $slf->{__DBG};
}

1;

__END__

=pod 

=head1 GUS::RAD::Plugin::Utils::InformationQueries

=head2 Methods

=head3 sub new($database_handle);

 Purpose:
  Creates a new instance of GUS::RAD::Utils::InformationQueries
  and assigns it the DBI handle $database_handle.
 Returns:
  intitialized GUS::RAD::Utils::InformationQueries object instance.


=head3 sub getStudyInfo($study_id);

 Purpose: get information about a study

 Returns: 
  $study->{
    study_id => $study_id,
    name     => $study_name,
    assays   => $arrayref_of_assay_ids,
  }

=head3 sub getArrayInfo($array_id);

 Purspose: Get the Array information (layout,etc.) for an array_id, as well as the {Composite}ElementIMP view that the array elements are.

 Returns: 
  $array->{ 
    array_id         => $array_id,
    name             => $array_name,
    version          =>$array_verion,
    platform_type_id => $platform_type_id,
    platform_type    => $platform_type_str,
    substrate_type_id =>  $substrate_type_id,
    substrate_type   =>  $substrate_type_str,
    array_dimensions => $array_dimensions,
    element_dimensions => $element_dimensions,
    num_array_rows   =>$num_array_rows,
    num_array_columns =>$num_array_columns,
    num_grid_rows    =>$num_array_rows,
    num_grid_columns =>$num_array_columns,
    num_sub_rows     =>$num_array_rows,
    num_sub_columns  =>$num_array_columns,
    num_array_rows   =>$array_verion,
    num_array_rows   =>$array_verion,
    subclass_view    => $element_subclass_view,
  }

=head3 sub getAssayInfo($assay_id);

 Purpose: Retrieve information about the assay

 Returns: 
  $assay->{
    assay_id                 => $assay_id,
    name                     => $name,
    array_id	               => $array_id,
    protocol_id	             => $protocol_id ,
    assay_date	             => $assay_date,
    array_identifier         => $array_identifier_str,
    array_batch_identifier   => $array_batch_identifier_str,
    operator_id	             => $sres_contact_id,
    external_database_id     => $external_database_id,
    external_database_release_id    => $external_database_release_id,
    source_id	 	             => $source_id,
    description              => $description_str,
    acquisitions             => $arrayref_of_acq_ids,
  }

=head3 sub getAcquisitionInfo($acquisition_id);
 
 Purpose:  Retrieve information about an Acquisition

 Returns:
  $acquisitons->{
    acquisition_id       => $acquisition_id,
    assoc_acquisition_id => $associated_acquisition_id,
    channel_id           => $channel_id,
    channel              => $channel_name_str,
    uri                  => $uri,
    quantifications      => $arrayref_of_quant_ids,
  }

=head3 sub getQuantificationInfo($quantification_id);

 Purpose:  Retrieve information about a Quantification

 Returns:
  $quants->{
   quantification_id => $quant_id,
   asssoc_quantification_id => $assoc_quant_id,
   acquisition_id => $acq_id,
   name => $name,
   uri => $uri,
   protocol_id => $protocol_id,
   protocol_name => $protocol_name,
 }

=cut


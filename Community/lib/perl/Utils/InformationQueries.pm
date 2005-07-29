package GUS::Community::Utils::InformationQueries;

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
               from Study.Study s, RAD.StudyAssay sa
               where s.study_id = sa.study_id
               and s.study_id = $id
              ];
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
  my $sql = qq[select a.array_design_id, a.name, a.version,
               a.technology_type_id, oett.value as technology_type,
               a.substrate_type_id, oest.value as substrate_type,
               a.surface_type_id, oesft.value as surface_type,
               a.array_dimensions, a.element_dimensions,
               a.num_array_rows, a.num_array_columns,
               a.num_grid_rows, a.num_grid_columns,
               a.num_sub_rows, a.num_sub_columns,
               from RAD.ArrayDesign a , Study.OntologyEntry oett,
               Study.OntologyEntry oest, Study.OntologyEntry oesft
               where a.array_design_id = $id
               and oett.ontology_entry_id = a.technology_type_id
               and oest.ontology_entry_id (+) = a.substrate_type_id
               and oesft.ontology_entry_id (+) = a.surface_type_id
              ];
  my $result = $slf->runquery($sql);
  my $array = {};
  foreach my $r (@$result) {
    $array = $r;
  }

  #get the subclass_view for the array features or reporters
  my $table = "" ;
  if ($array->{technology_type} eq 'in_situ_oligo_features' ) {
    # This is Affy array, query RAD::CompositeElementimp
    $table = 'RAD.CompositeElementImp';
  }
  elsif ($array->{technology_type} eq 'spotted_ds_DNA_features') {
    # This is spotted ds dna array, query RAD::ElementImp
    $table = 'RAD.ElementImp';
  }
  elsif ($array->{platform_type} eq 'spotted_ss_oligo_features') {
    # This is spotted ss dna array, query RAD::ElementImp
    $table = 'RAD.ElementImp';
  }

  $sql = qq[select subclass_view from $table where array_design_id = $id and rownum = 1];
  $array->{subclass_view} =   $slf->runquery($sql)->[0]->{subclass_view};
  return $array;
}

sub getAssayInfo{
  my ($slf,$id) = @_;
  my $sql = qq[select a.assay_id, a.name, a.array_design_id,
               a.protocol_id, a.assay_date,
               a.array_identifier, a.array_batch_identifier, a.operator_id,
               edb.external_database_id, a.external_database_release_id,
               a.source_id, a.description, acq.acquisition_id
               from RAD.Acquisition acq , RAD.Assay a,
               SRes.ExternalDatabaseRelease edb
               where a.assay_id = $id
               and a.assay_id = acq.assay_id (+)
               and a.external_database_release_id =edb.external_database_release_id (+)
              ];
  my $result = $slf->runquery($sql);
  my $assay  = {};
  foreach my $r (@$result) {
    foreach my $k (keys %$r) {
      if ($k eq 'acquisition_id' ) {
        push @{$assay->{acquisitions}} , $r->{$k};
      }
      else {
        $assay->{$k} = $r->{$k};
      }
    }
  }
  return $assay;
}

sub getAcquisitionInfo{
  my ($slf,$id) = @_;
  my $sql = qq[select a.acquisition_id, 
               ra.associated_acquisition_id as assoc_acquisition_id,
               a.ontology_entry_id, oe.value as channel, a.uri,
               q.quantification_id
               from RAD.Acquisition a, RAD.RelatedAcquisition ra, 
               Study.OntologyEntry oe, RAD.Quantification q
               where a.acquisition_id = $id
               and a.acquisition_id = ra.acquisition_id (+)
               and a.acquisition_id = q.acquisition_id (+)
               and oe.ontology_entry_id (+) = a.channel_id
               ];
  my $result = $slf->runquery($sql);
  my $acq = {} ;
  foreach my $r (@$result) {
    foreach my $k (keys %$r) {
      if ($k eq 'quantification_id' ) {
        push @{$acq->{quantifications}} , $r->{$k};
      }
      else {
        $acq->{$k} = $r->{$k};
      }
    }
  }
  return $acq;
}

sub getQuantificationInfo{
  my ($slf,$id) = @_;
  my $sql = qq[select q.quantification_id,
               pr.name as project_name, g.name as group_name,
               rq.associated_quantification_id as assoc_quantification_id,
               q.acquisition_id , q.name, q.uri, p.protocol_id,
               p.name as protocol_name
               from RAD.Quantification q, RAD.RelatedQuantification rq,
               RAD.Protocol p, Core.ProjectInfo pr, Core.GroupInfo g
               where q.quantification_id = $id
               and q.quantification_id = rq.quantification_id (+)
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

=head1 GUS::Community::Plugin::Utils::InformationQueries

=head2 Methods

=head3 sub new($database_handle);

 Purpose:
  Creates a new instance of GUS::Community::Utils::InformationQueries
  and assigns it the DBI handle $database_handle.
 Returns:
  intitialized GUS::Community::Utils::InformationQueries object instance.


=head3 sub getStudyInfo($study_id);

 Purpose: get information about a study

 Returns: 
  $study->{
    study_id => $study_id,
    name     => $study_name,
    assays   => $arrayref_of_assay_ids,
  }

=head3 sub getArrayInfo($array_id);

 Purpose: Get the ArrayDesign information (layout,etc.) for an array_design_id,
 as well as the {Composite}ElementIMP view that the array elements are.

 Returns: 
  $array->{ 
    array_design_id    => $array_design_id,
    name               => $array_name,
    version            => $array_version,
    technology_type_id => $technology_type_id,
    technology_type    => $technology_type_str,
    substrate_type_id  => $substrate_type_id,
    substrate_type     => $substrate_type_str,
    surface_type_id    => $surface_type_id,
    surface_type       => $surface_type_str,
    array_dimensions   => $array_dimensions,
    element_dimensions => $element_dimensions,
    num_array_rows     => $num_array_rows,
    num_array_columns  => $num_array_columns,
    num_grid_rows      => $num_array_rows,
    num_grid_columns   => $num_array_columns,
    num_sub_rows       => $num_array_rows,
    num_sub_columns    => $num_array_columns,
    subclass_view      => $element_subclass_view,
  }

=head3 sub getAssayInfo($assay_id);

 Purpose: Retrieve information about the assay

 Returns: 
  $assay->{
    assay_id                     => $assay_id,
    name                         => $name,
    array_design_id	         => $array_design_id,
    protocol_id	                 => $protocol_id ,
    assay_date	                 => $assay_date,
    array_identifier             => $array_identifier_str,
    array_batch_identifier       => $array_batch_identifier_str,
    operator_id	                 => $sres_contact_id,
    external_database_id         => $external_database_id,
    external_database_release_id => $external_database_release_id,
    source_id	 	         => $source_id,
    description                  => $description_str,
    acquisitions                 => $arrayref_of_acq_ids,
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
   quantification_id        => $quant_id,
   asssoc_quantification_id => $assoc_quant_id,
   acquisition_id           => $acq_id,
   name                     => $name,
   uri                      => $uri,
   protocol_id              => $protocol_id,
   protocol_name            => $protocol_name,
 }

=cut


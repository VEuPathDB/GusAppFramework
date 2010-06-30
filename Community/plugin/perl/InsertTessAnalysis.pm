##
## InsertTessAnalysis Plugin
## $Id:$
##

package GUS::Community::Plugin::InsertTessAnalysis;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;

use GUS::Model::TESS::Analysis;
use GUS::Model::SRes::Contact;
use GUS::Model::TESS::Protocol;
use GUS::Model::Study::OntologyEntry;
use GUS::Model::TESS::AnalysisParam;
use GUS::Model::TESS::ProtocolParam;
use GUS::Model::TESS::AnalysisQCParam;
use GUS::Model::TESS::ProtocolQCParam;
use GUS::Model::TESS::LogicalGroup;
use GUS::Model::TESS::AnalysisInput;
use GUS::Model::TESS::AssayAnalysis;
use GUS::Model::Core::TableInfo;
use GUS::Model::Core::DatabaseInfo;
use GUS::Model::TESS::SequenceFeature;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration  =
    [
     fileArg({name => 'cfg_file',
	      descr => 'The full path of the cfg_file.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => 'See the NOTES for the format of this file'
	     }),
     fileArg({name => 'data_file',
	      descr => 'The full path of the data_file.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => 'See the NOTES for the format of this file'
	     }),
     integerArg({name  => 'skip',
		 descr => 'The number of head lines to skip in the data file.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0,
		 default=>0
		}),
     stringArg({ name  => 'extDbRlsSpec',
		  descr => "The ExternalDBRelease specifier for the genome build to which reads refer. Must be in the format 'name|version', where the name must match an name in SRes::ExternalDatabase and the version must match an associated version in SRes::ExternalDatabaseRelease.",
		  constraintFunc => undef,
		  reqd           => 1,
		  isList         => 0 
	       }),
     integerArg({name  => 'analysis_id',
		 descr => 'The analysis_id of the analysis whose results loading should be resumed. If this argument is provided then the --skip option should be used to specify where to restart.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		}),
     integerArg({name  => 'testnum',
		 descr => 'The number of data lines to read when testing this plugin. Not to be used in commit mode.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		}),
     booleanArg({ name  => 'orderInput',
		  descr => 'If true, TESS.AnalysisInput.order_num will be populated',
		  constraintFunc => undef,
		  reqd           => 0,
		  isList         => 0 
		})
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------

sub getDocumentation {
  my $purposeBrief = 'Loads inputs, parameter settings, and results of high-throughput sequencing data analyses into the appropriate group of TESS tables.';

  my $purpose = "This plugin reads a configuration file and a data file (representing the results of some high-thoughput sequencing data analysis) and inserts inputs, parameter settings, and results into the appropriate tables in TESS.";

  my $tablesAffected = [['TESS::Analysis', 'Enters a row representing this analysis here'], ['TESS::AssayAnalysis', 'Enters rows here linking this analysis to all relevant assays'], ['TESS::AnalysisParam', 'Enters the values of the protocol parameters for this analysis here'], ['TESS::AnalysisQCParam', 'Enters the values of the protocol quality control parameters for this analysis here'], ['TESS::AnalysisInput', 'Enters the input(s) of this analysis here'], ['TESS::SequenceFeature', 'Enters the results of this analysis here']];

  my $tablesDependedOn = [['SRes::Contact', 'The researcher or organization who performed this analysis'], ['TESS::Protocol', 'The analysis protocol used'], ['TESS::ProtocolStep', 'The components of the analysis protocol used, if the latter is an ordered series of protocols'], ['Study::OntologyEntry', 'The protocol_type of the protocol used'], ['TESS::ProtocolParam', 'The parameters for the protocol used or for its components'], ['TESS::ProtocolQCParam', 'The quality control parameters for the protocol used or for its components'], ['TESS::LogicalGroup', 'The input group(s) to the analysis'], ['TESS::LogicalGroupLink', 'The members of the logical group(s) input into the analysis']]; 

  my $howToRestart = "Loading can be resumed using the I<--skip n> argument where n is the line number in the data file of the first row to load upon restarting (line 1 is the first line, empty lines are counted). This argument should be given when the I<analysis_id> argument is given. Alternatively, one can use the plugin GUS::Community::Plugin::Undo to delete all entries inserted by a specific call to this plugin. Then this plugin can be re-run from fresh.";

  my $failureCases = "";

  my $notes = <<NOTES;

=head2 F<cfg_file>

This should be a tab-delimited text file with 2 columns: I<name> and I<value>.
The names should be spelled exactly as described below. The order of the rows is not important.

Empty lines are ignored.

Each (non-empty) line should contain B<exactly one> tab.

Do not use special symbols (like NA or similar) for empty fields: either leave the field empty or delete the entire line.

The names of each field and instructions for their values are as follows:

B<I<analysis_name>>

A name (max 200 chars) which will identify this analysis.

B<I<description>>

A description (max 1000 chars) of the analysis.

B<I<protocol_id>> [Mandatory]

The protocol_id (in TESS.Protocol) of the protocol for this analysis.

B<I<protocol_param_idN>>

The protocol_parameter_id (in TESS.ProtocolParam) of the I<N>th parameter whose value is being assigned (possibly overwriting a specified default value). Start with I<N>=1, for the first parameter you want to set, and continue up to the number of parameters you want to set.

B<I<protocol_param_valueN>>

The value to be assigned to the I<N>th parameter, whose id is specified by I<protocol_param_idN>.

B<I<protocol_qc_param_idN>>

The protocol_qc_parameter_id (in TESS.ProtocolQCParam) of the I<N>th quality control parameter whose value is being assigned (possibly overwriting a specified default value). Start with I<N>=1, for the first qc parameter you want to set, and continue up to the number of qc parameters you want to set.

B<I<protocol_qc_param_valueN>>

The value to be assigned to the I<N>th quality control parameter, whose id is specified by I<protocol_qc_param_idN>.

B<I<logical_group_idN>>

The logical_group_id (in TESS.LogicalGroup) of the I<N>th input group to this analysis. Start with 1, for the first input group, and continue till you have exhausted all input groups. B<At least one> logical group id should be provided. If --orderInput is true, I<N> will be used to populate TESS.AnalysisInput.order_num for that logical group.
B<I<chr>> [Mandatory]
The column in the data file containing the chromosome info, with values 'chr*'. 
Start counting columns from 0.

B<I<start_position>> [Mandatory]
The column in the data file containing the start positions. Start counting columns from 0.

B<I<end_position>> [Mandatory]
The column in the data file containing the end positions. Start counting columns from 0.

B<I<strand>>
The (optional) column in the data file containing the strand. Start counting columns from 0.

B<I<sequence_ontology_id>>
The (optional) column in the data file containing the sequence_ontology_ids. Start counting columns from 0.

B<I<score>>
The (optional) column in the data file containing the score. Start counting columns from 0.

B<I<p_value>>
The (optional) column in the data file containing the p-value. Start counting columns from 0.

B<I<fdr>>
The (optional) column in the data file containing the FDR. Start counting columns from 0.

=head2 F<data_file>

The data file would tpically be a bed, or bedgraph file or other tab-delimited file with columns containing: chromosome (mandatory), start_position (mandatory), end_position (mandatory), strand, sequence_ontology_id, score, p_vaue, fdr.
Empty lines will be ignored.

Missing values in a field can be left empty or set to na or NA or n/a or N/A.

=head1 AUTHOR

Written by Elisabetta Manduchi.

=head1 COPYRIGHT

Copyright Elisabetta Manduchi, Trustees of University of Pennsylvania 2009. 
NOTES

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief, tablesAffected=>$tablesAffected, tablesDependedOn=>$tablesDependedOn, howToRestart=>$howToRestart, failureCases=>$failureCases, notes=>$notes};

  return $documentation;
}

# ----------------------------------------------------------------------
# create and initalize new plugin instance.
# ----------------------------------------------------------------------

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);

  my $documentation = &getDocumentation();
  my $argumentDeclaration    = &getArgumentsDeclaration();

  $self->initialize({requiredDbVersion => 3.5,
		     cvsRevision => '$Revision: 8447 $',
		     name => ref($self),
		     revisionNotes => '',
		     argsDeclaration => $argumentDeclaration,
		     documentation => $documentation
		    });
  return $self;
}


# ----------------------------------------------------------------------
# run method to do the work
# ----------------------------------------------------------------------

sub run {
  my ($self) = @_;

  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();
  my $ids = $self->checkArgs();

  my $cfgInfo = $self->readCfgFile();
  my $analysisId;
  my $resultDescrip = "";
  if (defined $self->getArg('analysis_id')) {
    $analysisId = $self->getArg('analysis_id');
  }
  else {
    ($resultDescrip, $analysisId) = $self->insertAnalysis($cfgInfo);
  }
  $self->setResultDescr($resultDescrip);

  $resultDescrip .= " ". $self->insertAnalysisResults($analysisId, $cfgInfo, $ids);

  $self->setResultDescr($resultDescrip);
  $self->logData($resultDescrip);
}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------

sub checkArgs {
  my ($self) = @_;
  my $extDbRls = $self->getExtDbRlsId($self->getArg('extDbRlsSpec'));
  my $ids;
  my $dbh = $self->getQueryHandle();

  my $sth = $dbh->prepare("select na_sequence_id, chromosome from DoTS.VirtualSequence where external_database_release_id=$extDbRls");
  $sth->execute();
  while (my ($id, $chr)=$sth->fetchrow_array()) {
    $chr =~ /^.*(chr.+)$/;
    $ids->{$1} = $id;
  }
  if (!scalar(keys %{$ids})) {
    $self->userError('There are no data in DoTS.VirtualSequence for the specified External Database Release');
  }

  if (defined($self->getArg('testnum')) && $self->getArg('commit')) {
    $self->userError("The --testnum argument can only be provided if COMMIT is OFF.");
  }
  if (defined($self->getArg('analysis_id')) && defined(!$self->getArg('skip'))) {
    $self->userError('The --analysis_id argument requires that the --skip argument is also provided.');
  }
  if (defined($self->getArg('skip')) && $self->getArg('skip')<0) {
    $self->userError('The value of the --skip argument should be an integer greater than or equal to 0.');
  }
  if (defined($self->getArg('testnum')) && $self->getArg('testnum')<1) {
    $self->userError('The value of the --testnum argument should be an integer greater than or equal to 1.');
  }
  if (defined($self->getArg('analysis_id'))) {
    my $analysis = GUS::Model::TESS::Analysis->new({'analysis_id' => $self->getArg('analysis_id')});
    if (!$analysis->retrieveFromDB()) {
      $self->userError('Invalid analysis_id.');
    }
  }
  return($ids);
}

sub readCfgFile {
  my ($self) = @_;
  my $cfgInfo;

  my $dbh = $self->getQueryHandle();
  my $fh = new IO::File;
  my $file = $self->getArg('cfg_file');
  unless ($fh->open("<$file")) {
    $self->error("Could not open file $file.");
  }
  my $analysisNameGiven = 0;
  my $descriptionGiven = 0;
  my $protocolIdGiven = 0;
  my $analysisDateGiven = 0;
  my $logicalGroupIdGiven = 0;
  my $chrGiven = 0;
  my $startGiven = 0;
  my $endGiven = 0;
  my $strandGiven = 0;
  my $soGiven = 0;
  my $scoreGiven = 0;
  my $pGiven = 0;
  my $fdrGiven = 0;

  while (my $line=<$fh>) {
    my ($name, $value) = split(/\t/, $line);
    $name =~ s/^\s+|\s+$//g;
    $value =~ s/^\s+|\s+$//g;
    if ($name ne '' && $value ne '') {
      if ($name eq 'analysis_name') {
	if (!$analysisNameGiven) {
	  $cfgInfo->{'analysis_name'} = $value;
	  $analysisNameGiven = 1;
	}
	else {
	  $self->userError('Only one analysis_name should be provided in the cfg_file.');
	}
      }
      elsif ($name eq 'description') {
	if (!$descriptionGiven) {
	  $cfgInfo->{'description'} = $value;
	  $descriptionGiven = 1;
	}
	else {
	  $self->userError('Only one description should be provided in the cfg_file.');
	}
      }
      elsif ($name eq 'protocol_id') {
	if (!$protocolIdGiven) {
	  my $protocol = GUS::Model::TESS::Protocol->new({'protocol_id' =>$value});
	  if (!$protocol->retrieveFromDB()) {
	    $self->userError("protocol_id $value, provided in the cfg_file, is not a valid protocol_id.");
	  }
	  $cfgInfo->{'protocol_id'} = $value;
	  $protocolIdGiven = 1;
	}
	else {
	  $self->userError('Only one protocol_id should be provided in the cfg_file.');
	}
      }
      elsif ($name =~ /^protocol_param_id(\d+)$/) {
	my $index = $1;
	if ($index<1) {
	  $self->userError('In the cfg_file, each protocol_param_idN must have N>0.');
	}
	$cfgInfo->{'protocol_param_id'}->[$index] = $value;
      }
      elsif ($name =~ /^protocol_param_value(\d+)$/) {
	my $index = $1;
	if ($index<1) {
	  $self->userError('In the cfg_file, each protocol_param_valueN must have N>0.');
	}
	$cfgInfo->{'protocol_param_value'}->[$index] = $value;
      }
      elsif ($name =~ /^protocol_qc_param_id(\d+)$/) {
	my $index = $1;
	if ($index<1) {
	  $self->userError('In the cfg_file, each protocol_qc_param_idN must have N>0.');
	}
	$cfgInfo->{'protocol_qc_param_id'}->[$index] = $value;
      }
      elsif ($name =~ /^protocol_qc_param_value(\d+)$/) {
	my $index = $1;
	if ($index<1) {
	  $self->userError('In the cfg_file, each protocol_qc_param_valueN must have N>0.');
	}
	$cfgInfo->{'protocol_qc_param_value'}->[$index] = $value;
      }
      elsif ($name =~ /^logical_group_id(\d+)$/) {
	my $index = $1;
	if ($index<1) {
	  $self->userError('In the cfg_file, each logical_group_idN must have N>=1.');
	}
	my $group = GUS::Model::TESS::LogicalGroup->new({'logical_group_id' => $value});
	if (!$group->retrieveFromDB()) {
	  $self->userError("logical_group_id $value, provided in the cfg_file, is not a valid logical_group_id.");
	}
	$cfgInfo->{'logical_group_id'}->[$index] = $value;
	$logicalGroupIdGiven++;
      }
      elsif ($name eq 'chr') {
	if (!$chrGiven) {
	  $cfgInfo->{'chr'} = $value;
	  $chrGiven = 1;
	}
	else {
	  $self->userError('chr should be provided only once in the cfg_file.');
	}
      } 
      elsif ($name eq 'start_position') {
	if (!$startGiven) {
	  $cfgInfo->{'start_position'} = $value;
	  $startGiven = 1;
	}
	else {
	  $self->userError('start_position should be provided only once in the cfg_file.');
	}
      }
       elsif ($name eq 'end_position') {
	if (!$endGiven) {
	  $cfgInfo->{'end_position'} = $value;
	  $endGiven = 1;
	}
	else {
	  $self->userError('end_position should be provided only once in the cfg_file.');
	}
      } 
      elsif ($name eq 'strand') { 
	if (!$strandGiven) {
	  $cfgInfo->{'strand'} = $value;
	  $strandGiven = 1;
	}
	else {
	  $self->userError('strand should be provided only once in the cfg_file.');
	}
      }
      elsif ($name eq 'sequence_ontology_id') { 
	if (!$soGiven) {
	  $cfgInfo->{'sequence_ongoloty_id'} = $value;
	  $soGiven = 1;
	}
	else {
	  $self->userError('sequence_ontology_id should be provided only once in the cfg_file.');
	}
      } 
      elsif ($name eq 'score') { 
	if (!$scoreGiven) {
	  $cfgInfo->{'score'} = $value;
	  $scoreGiven = 1;
	}
	else {
	  $self->userError('score should be provided only once in the cfg_file.');
	}
      } 
      elsif ($name eq 'p_value') { 
	if (!$pGiven) {
	  $cfgInfo->{'p_value'} = $value;
	  $pGiven = 1;
	}
	else {
	  $self->userError('p_value should be provided only once in the cfg_file.');
	}
      } 
      
      elsif ($name eq 'fdr') { 
	if (!$fdrGiven) {
	  $cfgInfo->{'fdr'} = $value;
	  $fdrGiven = 1;
	}
	else {
	  $self->userError('fdr should be provided only once in the cfg_file.');
	}
      }       
      else {
	$self->userError('The only valid names in the cfg_file are: analysis_name, description, protocol_id, protocol_param_idN, protocol_param_valueN, protocol_qc_param_idN, protocol_qc_param_valueN, logical_group_idN, chr, start_position, end_position, strand, score, p_value, fdr.');
      }
    }
  }
  $fh->close();
  if (!defined($self->getArg('analysis_id')) && (!$protocolIdGiven || !$logicalGroupIdGiven)) {
    $self->userError('The cfg_file must contain values for protocol_id and at least one logical_group_id.');
  }
  if (defined($cfgInfo->{'protocol_param_id'}) && defined($cfgInfo->{'protocol_param_value'}) && scalar(@{$cfgInfo->{'protocol_param_id'}}) != scalar(@{$cfgInfo->{'protocol_param_value'}})) {
    $self->userError("The number or protocol_param_id's given in the cfg_file does not match the number of protocol_param_value's.");
  }
  if (defined($cfgInfo->{'protocol_qc_param_id'}) && defined($cfgInfo->{'protocol_qc_param_value'}) && scalar(@{$cfgInfo->{'protocol_qc_param_id'}}) != scalar(@{$cfgInfo->{'protocol_qc_param_value'}})) {
    $self->userError("The number or protocol_qc_param_id's given in the cfg_file does not match the number of protocol_qc_param_value's.");
  }
  if (defined($cfgInfo->{'protocol_param_id'})) {
     my $sth1 = $dbh->prepare("select o.value from Study.OntologyEntry o, TESS.Protocol p where p.protocol_type_id=o.ontology_entry_id and p.protocol_id=$cfgInfo->{'protocol_id'}");
    $sth1->execute();
    my ($protocolType) = $sth1->fetchrow_array();
    my @protocolIds = ($cfgInfo->{'protocol_id'});
    if ($protocolType eq "transformation_protocol_series") {
      my $sth2 = $dbh->prepare("select child_protocol_id from TESS.ProtocolStep where parent_protocol_id=$cfgInfo->{'protocol_id'}");
      $sth2->execute();
      while (my ($id) = $sth2->fetchrow_array()) {
	push(@protocolIds, $id);
      }
    }
    for (my $i=1; $i<scalar(@{$cfgInfo->{'protocol_param_id'}}); $i++) {
      my $isValidProtocol = 0;
      for (my $j=0; $j<@protocolIds; $j++) {
	my $protocolParam = GUS::Model::TESS::ProtocolParam->new({'protocol_param_id' =>$cfgInfo->{'protocol_param_id'}->[$i], 'protocol_id'=>$protocolIds[$j]});
	if ($protocolParam->retrieveFromDB()) {
	  $isValidProtocol = 1;
	  last;
	}
      }
      if (!$isValidProtocol) {
	$self->userError("protocol_param_id $cfgInfo->{'protocol_param_id'}->[$i], provided in the cfg_file for the $i-th protocol parameter, is not a valid protocol_param_id for protocol_id $cfgInfo->{'protocol_id'} or its components.");
      }
    }
  }
  if (defined($cfgInfo->{'protocol_qc_param_id'})) {
     my $sth1 = $dbh->prepare("select o.value from Study.OntologyEntry o, TESS.Protocol p where p.protocol_type_id=o.ontology_entry_id and p.protocol_id=$cfgInfo->{'protocol_id'}");
    $sth1->execute();
    my ($protocolType) = $sth1->fetchrow_array();
    my @protocolIds = ($cfgInfo->{'protocol_id'});
    if ($protocolType eq "transformation_protocol_series") {
      my $sth2 = $dbh->prepare("select child_protocol_id from TESS.ProtocolStep where parent_protocol_id=$cfgInfo->{'protocol_id'}");
      $sth2->execute();
      while (my ($id) = $sth2->fetchrow_array()) {
	push(@protocolIds, $id);
      }
    }
    for (my $i=1; $i<scalar(@{$cfgInfo->{'protocol_qc_param_id'}}); $i++) {
      my $isValidProtocol = 0;
      for (my $j=0; $j<@protocolIds; $j++) {
	my $protocolQcParam = GUS::Model::TESS::ProtocolQCParam->new({'protocol_qc_param_id' =>$cfgInfo->{'protocol_qc_param_id'}->[$i], 'protocol_id'=>$protocolIds[$j]});
	if ($protocolQcParam->retrieveFromDB()) {
	  $isValidProtocol = 1;
	  last;
	}
      }
      if (!$isValidProtocol) {
	$self->userError("protocol_qc_param_id $cfgInfo->{'protocol_qc_param_id'}->[$i] for the $i-th protocol qc parameter, provided in the cfg_file, is not a valid protocol_qc_param_id for protocol_id $cfgInfo->{'protocol_id'} or its components.");
      }
    }
  }
  return $cfgInfo;
}

sub insertAnalysis {
  my ($self, $cfgInfo) = @_;
  my ($resultDescrip, $analysisId);
  my $numAnalysisInput = 0;
  my $numAnalysisParam = 0;
  my $numAnalysisQcParam = 0;
  my $numAssayAnalysis = 0;
  my $dbh = $self->getQueryHandle();
  my @assayIds;
  my %assayCounted;

  my $analysis = GUS::Model::TESS::Analysis->new({protocol_id => $cfgInfo->{'protocol_id'}});
  if (defined $cfgInfo->{'description'}) {
    $analysis->set('description', $cfgInfo->{'description'});
  }
  if (defined $cfgInfo->{'analysis_name'}) {
    $analysis->set('name', $cfgInfo->{'analysis_name'});
  }
  my $sth =$dbh->prepare("select t.table_id from Core.TableInfo t, Core.DatabaseInfo d where t.name='Assay' and d.name='TESS' and t.database_id=d.database_id");
  $sth->execute();
  my ($assayTableId) = $sth->fetchrow_array();

  $sth =$dbh->prepare("select t.table_id from Core.TableInfo t, Core.DatabaseInfo d where t.name='Acquisition' and d.name='TESS' and t.database_id=d.database_id");
  $sth->execute();
  my ($acquisitionTableId) = $sth->fetchrow_array();

  $sth =$dbh->prepare("select t.table_id from Core.TableInfo t, Core.DatabaseInfo d where t.name='Quantification' and d.name='TESS' and t.database_id=d.database_id");
  $sth->execute();
  my ($quantificationTableId) = $sth->fetchrow_array();

  for (my $i=0; $i<@{$cfgInfo->{'logical_group_id'}}; $i++) {
    if (defined $cfgInfo->{'logical_group_id'}->[$i]) {
      my $sth1 = $dbh->prepare("select distinct row_id from TESS.LogicalGroupLink where table_id=$assayTableId and logical_group_id= $cfgInfo->{'logical_group_id'}->[$i]");
      $sth1->execute();
      while (my ($assayId)= $sth1->fetchrow_array()) {
	if (!$assayCounted{$assayId}) {
	  push (@assayIds, $assayId);
	  $assayCounted{$assayId} = 1;
	}
      }
      my $sth2 = $dbh->prepare("select distinct a.assay_id from TESS.Acquisition a, TESS.LogicalGroupLink l where l.table_id=$acquisitionTableId and l.logical_group_id= $cfgInfo->{'logical_group_id'}->[$i] and l.row_id=a.acquisition_id");
      $sth2->execute();
      while (my ($assayId)= $sth2->fetchrow_array()) {
	if (!$assayCounted{$assayId}) {
	  push (@assayIds, $assayId);
	  $assayCounted{$assayId} = 1;
	}
      }

      my $sth3 = $dbh->prepare("select distinct a.assay_id from TESS.Acquisition a, TESS.Quantification q, TESS.LogicalGroupLink l where l.table_id=$quantificationTableId and l.logical_group_id= $cfgInfo->{'logical_group_id'}->[$i] and l.row_id=q.quantification_id and q.acquisition_id=a.acquisition_id");
      $sth3->execute();
      while (my ($assayId)= $sth3->fetchrow_array()) {
	if (!$assayCounted{$assayId}) {
	  push (@assayIds, $assayId);
	  $assayCounted{$assayId} = 1;
	}
      }

      my $analysisInput = GUS::Model::TESS::AnalysisInput->new({logical_group_id => $cfgInfo->{'logical_group_id'}->[$i]});
      if ($self->getArg('orderInput')) {
	$analysisInput->set('order_num', $i);
      }
      $analysisInput->setParent($analysis);
      $numAnalysisInput++;
    }
  }
  for (my $i=0; $i<@assayIds; $i++) {
    my $assayAnalysis = GUS::Model::TESS::AssayAnalysis->new({assay_id => $assayIds[$i]});
    $assayAnalysis->setParent($analysis);
    $numAssayAnalysis++;
  }

  if (defined($cfgInfo->{'protocol_param_id'})) {
    for (my $i=1; $i<@{$cfgInfo->{'protocol_param_id'}}; $i++) {
      my $analysisParam = GUS::Model::TESS::AnalysisParam->new({protocol_param_id => $cfgInfo->{'protocol_param_id'}->[$i], value => $cfgInfo->{'protocol_param_value'}->[$i]});
      $analysisParam->setParent($analysis);
      $numAnalysisParam++;
    }
  }
  if (defined($cfgInfo->{'protocol_qc_param_id'})) {
    for (my $i=1; $i<@{$cfgInfo->{'protocol_qc_param_id'}}; $i++) {
      my $analysisQcParam = GUS::Model::TESS::AnalysisQCParam->new({protocol_qc_param_id => $cfgInfo->{'protocol_qc_param_id'}->[$i], value => $cfgInfo->{'protocol_qc_param_value'}->[$i]});
      $analysisQcParam->setParent($analysis);
      $numAnalysisQcParam++;
    }
  }

  $analysis->submit();
  $resultDescrip .= "Entered 1 row in TESS.Analysis, $numAnalysisInput rows in TESS.AnalysisInput, $numAssayAnalysis rows in TESS.AssayAnalysis, $numAnalysisParam rows in TESS.AnalysisParam, $numAnalysisQcParam rows in TESSx.AnalysisQCParam.";
  $analysisId = $analysis->getId();
  return ($resultDescrip, $analysisId);
}

sub insertAnalysisResults {
  my ($self, $analysisId, $cfgInfo, $ids) = @_;
  my $resultDescrip;
  my $numResults = 0;

  my $dataFile = $self->getArg('data_file');
  my $fh = IO::File->new("<$dataFile");
  
  for (my $i=0; $i<$self->getArg('skip'); $i++) {
    my $line = <$fh>;
  }
  my $lineNum = 0;
  while (my $line=<$fh>) {
    $lineNum++;
    if (defined $self->getArg('testnum') && $lineNum>$self->getArg('testnum')) {
      last;
    }
    if ($lineNum % 5000 == 0) {
      $self->log("Working on the $lineNum-th data line.");
    }
    chomp($line);
    if ($line =~ /^\s*$/) {
      next;
    }
    my @arr = split(/\t/, $line);
    my $analysisResult = GUS::Model::TESS::SequenceFeature->new({analysis_id => $analysisId}, na_sequence_id => $ids->{$arr[$cfgInfo->{'chr'}]}, start_position => $arr[$cfgInfo->{'start_position'}], end_position => $arr[$cfgInfo->{'end_position'}]);

    if (defined $cfgInfo->{'strand'}) {
      my $isReversed;
      if ($arr[$cfgInfo->{'strand'}] eq '+') {
	$isReversed = 0;
      }
      elsif ($arr[$cfgInfo->{'strand'}] eq '-') {
	$isReversed = 1;
      }
      else {
	$self->userError("incorrect strand info at data line $lineNum");
      }
      $analysisResult->set('is_reversed', $isReversed);
    }
    if (defined $cfgInfo->{'score'}) {
      $analysisResult->set('score', $arr[$cfgInfo->{'score'}]);
    }
    if (defined $cfgInfo->{'sequence_ontology_id'}) {
      $analysisResult->set('sequence_ontology_id', $arr[$cfgInfo->{'sequence_ontology_id'}]);
    }
    if (defined $cfgInfo->{'p_value'}) {
      $analysisResult->set('p_value', $arr[$cfgInfo->{'p_value'}]);
    }
    if (defined $cfgInfo->{'fdr'}) {
      $analysisResult->set('fdr', $arr[$cfgInfo->{'fdr'}]);
    }
    $analysisResult->submit();
    $numResults++;
    $self->undefPointerCache();
  }

  $resultDescrip = "Entered $numResults rows in TESS.SequenceFeature.";
  return $resultDescrip;
}

sub undoTables {
  my ($self) = @_;

  return ('TESS.SequenceFeature', 'TESS.AnalysisQCParam', 'TESS.AnalysisParam', 'TESS.AnalysisInput', 'TESS.AssayAnalysis', 'TESS.Analysis');
}

1;

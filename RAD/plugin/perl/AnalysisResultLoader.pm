# ----------------------------------------------------------
# AnalysisResultLoader.pm
#
# Created: Aug-26-2003
#
# Author: Elisabetta Manduchi
#
# ----------------------------------------------------------

package GUS::RAD::Plugin::AnalysisResultLoader;
@ISA = qw( GUS::PluginMgr::Plugin );

use strict;
use IO::File;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;

use GUS::Model::RAD3::Analysis;
use GUS::Model::SRes::Contact;
use GUS::Model::RAD3::Protocol;
use GUS::Model::RAD3::OntologyEntry;
use GUS::Model::RAD3::AssayAnalysis;
use GUS::Model::RAD3::AnalysisParam;
use GUS::Model::RAD3::ProtocolParam;
use GUS::Model::RAD3::AnalysisQCParam;
use GUS::Model::RAD3::ProtocolQCParam;
use GUS::Model::RAD3::LogicalGroup;
use GUS::Model::RAD3::AnalysisInput;
use GUS::Model::Core::TableInfo;
use GUS::Model::Core::DatabaseInfo;

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self,$class);
  my $purposeBrief = 'Loads inputs, parameter settings, and results of gene expression data analyses (pre-processing or down-stream) into the appropriate group of RAD3 tables.';

  my $purpose = <<PURPOSE;
This plugin reads a configuration file and a data file (representing the results of some gene expression data pre-processing or down-stream analysis) and inserts inputs, parameter settings, and results into the appropriate tables in RAD3.
PURPOSE

  my $tablesAffected = [['RAD3::Analysis', 'Enters a row representing this analysis here'], ['RAD3::AssayAnalysis', 'Enters rows here linking this analysis to all relevant assays, if the LogicalGroups input into the analysis consists of quantifications, or acquisitions, or assays'], ['RAD3::AnalysisParam', 'Enters the values of the protocol parameters for this analysis here'], ['RAD3::AnalysisQCParam', 'Enters the values of the protocol quality control parameters for this analysis here'], ['RAD3::AnalysisInput', 'Enters the input(s) of this analysis here'], ['RAD3::AnalysisResultImp', 'Enters the results of this analysis here']];

  my $tablesDependedOn = [['RAD3::Contact', 'The researcher or organization who performed this analysis'], ['RAD3::Protocol', 'The analysis protocol used'], ['RAD3::ProtocolStep', 'The components of the analysis protocol used, if the latter is an ordered series of protocols'], ['RAD3::ProtocolParam', 'The parameters for the protocol used or for its components'], ['RAD3::ProtocolQCParam', 'The quality control parameters for the protocol used or for its components'], ['RAD3::LogicalGroup', 'The input group(s) to the analysis'], ['RAD3::LogicalGroupLink', 'The memberss of the logical group(s) input into the analysis'],['Core::TableInfo', 'The table whose entries the analysis results refer to'], ['Core::DatabaseInfo', 'The name of the GUS space containing the table whose entries the analysis results refer to']]; 

  my $howToRestart = <<RESTART;
Loading can be resumed using the I<--restart n> argument where n is the line number in the data file of the first row to load upon restarting (line 1 is the first line after the header, empty lines are counted). If this argument is given then the I<analysis_id> argument should be given too.
RESTART

  my $failureCases = <<FAILURE_CASES;
FAILURE_CASES

  my $notes = <<NOTES;

=head2 F<cfg_file>

This should be a tab-delimited text file with 2 columns: I<name> and I<value>.
The names should be spelled exactly as described below. The order of the rows is not important.

See the sample config file F<sample_AnalysisResultLoader.cfg> in the GUS/RAD/config directory.

Empty lines are ignored.

Each (non-empty) line should contain B<exactly one> tab.

Do not use special symbols (like NA or similar) for empty fields: either leave the field empty or delete the entire line.

The names of each field and instructions for their values are as follows:

B<I<table>> [Mandatory]

The table (or view) whose entries the analysis results refer to. The format should be I<space.name>, e.g. RAD3.SpotFamily. Both I<space> and I<name> must be spelled B<exactly> (case sensitive) as spelled in Core.DatabaseInfo.name and Core.TableInfo.name.

B<I<operator_id>>

The contact_id (in SRes.Contact) of the researcher or organization who performed this analysis.

B<I<protocol_id>> [Mandatory]

The protocol_id (in RAD3.Protocol) of the protocol for this analysis. If I<--subclass_view> is RAD3::DataTransformationResult, then the type of this protocol should be in the DataTransformationProtocolType category. In all other cases, it should be in the HigherLevelAnalysisProtocolType category.

B<I<analysis_date>> [Mandatory]

The date when the specific analysis was performed. The correct format is YYYY-MM-DD.

B<I<protocol_param_idN>>

The protocol_parameter_id (in RAD3.ProtocolParam) of the I<N>th parameter whose value is being assigned (possibly overwriting a specified default value). Start with I<N>=1, for the first parameter you want to set, and continue up to the number of parameters you want to set.

B<I<protocol_param_valueN>>

The value to be assigned to the I<N>th parameter, whose id is specified by I<protocol_param_idN>.

B<I<protocol_qc_param_idN>>

The protocol_qc_parameter_id (in RAD3.ProtocolQCParam) of the I<N>th quality control parameter whose value is being assigned (possibly overwriting a specified default value). Start with I<N>=1, for the first qc parameter you want to set, and continue up to the number of qc parameters you want to set.

B<I<protocol_qc_param_valueN>>

The value to be assigned to the I<N>th quality control parameter, whose id is specified by I<protocol_qc_param_idN>.

B<I<logical_group_idN>>

The logical_group_id (in RAD3.LogicalGroup) of the I<N>th input group to this analysis. Start with I<N>=1, for the first input group, and continue up to the number of input groups. B<At least one> logical group id should be provided.

=head2 F<data_file>

The data file should be in tab-delimited text format with one header line and a line for each result to be entered in the appropriate view of AnalysisResultImp.
All lines should contain the same number of tab/fields. Empty lines will be ignored.

The header should contain a field called I<row_id>, to hold the primary keys
(in the table I<table>, given in the F<cfg_file>), for the entries the results refer to.

The other fields should have B<lower case> names spelled B<exactly> as the field names in the view specified by the I<--subclass_view> argument.

The fields I<subclass_view>, I<analysis_id>, and I<table_id> do not have to be specified in the F<data_file>, as this plugin derives their values from its arguments (including the F<cfg_file>).

Missing values in a field can be left empty or set to na or NA or n/a or N/A. If all (non row_id) values for a row are missing, that row is not entered.

=head1 AUTHOR

Written by Elisabetta Manduchi.

=head1 COPYRIGHT

Copyright Elisabetta Manduchi, Trustees of University of Pennsylvania 2003. 
NOTES

  my $documentation = {purpose=>$purpose, purposeBrief=>$purposeBrief, tablesAffected=>$tablesAffected, tablesDependedOn=>$tablesDependedOn, howToRestart=>$howToRestart, failureCases=>$failureCases, notes=>$notes};

  my $argsDeclaration  =
    [
     tableNameArg({name => 'subclass_view',
		   descr => 'The name of the view of RAD3.AnalysisResultImp in which the results of the analysis should be loaded. Format should be RAD3::viewname.',
	           constraintFunc=> undef,
		   reqd => 1,
		   isList => 0
		  }),
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
     integerArg({name  => 'restart',
		 descr => 'Line number in data_file from which loading should be resumed (line 1 is the first line after the header, empty lines are counted). If this argument is given the analysis_id should also be given.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		}),
     integerArg({name  => 'analysis_id',
		 descr => 'The analysis_id of the analysis whose results loading should be resumed with the --restart option. This argument should be provided if and only if the restart option is used.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		}),
     integerArg({name  => 'testnum',
		 descr => 'The number of data lines to read when testing this plugin. Not to be used in commit mode.',
		 constraintFunc=> undef,
		 reqd  => 0,
		 isList => 0
		})
    ];

  $self->initialize({requiredDbVersion => {RAD3 => '3', Core => '3'},
		     cvsRevision => '$Revision$',
		     cvsTag => '$Name$',
		     name => ref($self),
		     revisionNotes => '',
		     argsDeclaration => $argsDeclaration,
		     documentation => $documentation
		    });
  return $self;
}

sub run {
  my ($self) = @_;

  $self->logAlgInvocationId();
  $self->logCommit();
  $self->logArgs();
  $self->checkArgs();

  my $cfg_info = $self->readCfgFile();
  my $sv = $self->getArgs->{'subclass_view'};
  my $view = "GUS::Model::$sv";
  eval "require $view";
  my ($data, $line_count) = $self->readDataFile($view, $cfg_info->{'pk'}, $cfg_info->{'table'});
  $self->logData("There are $line_count lines in data_file after the header, counting empty lines.");

  my $analysis_id;
  my $resultDescrip = "";
  if (defined $self->getArgs->{'analysis_id'}) {
    $analysis_id = $self->getArgs->{'analysis_id'};
  }
  else {
    ($resultDescrip, $analysis_id) = $self->insertAnalysis($cfg_info);
  }
  $self->setResultDescr($resultDescrip);

  $resultDescrip .= " ". $self->insertAnalysisResults($view, $analysis_id, $cfg_info->{'table_id'}, $data, $line_count);

  $self->setResultDescr($resultDescrip);
  $self->logData($resultDescrip);
}

sub checkArgs {
  my ($self) = @_;

  my $dbh = $self->getQueryHandle();
  my $sth = $dbh->prepare("select t.table_id from Core.TableInfo t, Core.DatabaseInfo d where t.name='AnalysisResultImp' and d.name='RAD3' and t.database_id=d.database_id");
  $sth->execute();
  my ($id) = $sth->fetchrow_array();

  my ($space, $name) = split(/::/, $self->getArgs->{'subclass_view'});
  if ($space eq "RAD3") {
    my $table = GUS::Model::Core::TableInfo->new({name => $name, is_view => 1, view_on_table_id => $id});
    if (!$table->retrieveFromDB()) {
      $self->userError("$space\:\:$name is not a valid view of RAD3.AnalysisResultImp.");
    }
  }
  else {
    $self->userError("The format for --subclass_view should be RAD3::viewname.");
  }

  if (defined($self->getArgs->{'testnum'}) && $self->getArgs->{'commit'}) {
    $self->userError("The --testnum argument can only be provided if COMMIT is OFF.");
  }
  if (!defined($self->getArgs->{'restart'}) && defined($self->getArgs->{'analysis_id'})) {
    $self->userError('The --restart argument must be provided only if the --analysis_id argument is provided.');
  }
  if (!defined($self->getArgs->{'analysis_id'}) && defined($self->getArgs->{'restart'})) {
    $self->userError('The --analysis_id argument must be provided only if the --restart argument is provided.');
  }
  if (defined($self->getArgs->{'restart'}) && $self->getArgs->{'restart'}<1) {
    $self->userError('The value of the --restart argument should be an integer greater than or equal to 1.');
  }
  if (defined($self->getArgs->{'testnum'}) && $self->getArgs->{'testnum'}<1) {
    $self->userError('The value of the --testnum argument should be an integer greater than or equal to 1.');
  }
  if (defined($self->getArgs->{'analysis_id'})) {
    my $analysis = GUS::Model::RAD3::Analysis->new({'analysis_id' => $self->getArgs->{'analysis_id'}});
    if (!$analysis->retrieveFromDB()) {
      $self->userError('Invalid analysis_id.');
    }
  }
}

sub readCfgFile {
  my ($self) = @_;
  my $cfg_info;

  my $dbh = $self->getQueryHandle();
  my $fh = new IO::File;
  my $file = $self->getArgs->{'cfg_file'};
  unless ($fh->open("<$file")) {
    $self->error("Could not open file $file.");
  }
  my $table_given = 0;
  my $operator_id_given = 0;
  my $protocol_id_given = 0;
  my $analysis_date_given = 0;
  my $logical_group_id_given = 0;

  while (my $line=<$fh>) {
    my ($name, $value) = split(/\t/, $line);
    $name =~ s/^\s+|\s+$//g;
    $value =~ s/^\s+|\s+$//g;
    if ($name ne '' && $value ne '') {
      if ($name eq 'table') {
	if (!$table_given) {
	  my ($space, $tablename) = split(/\./, $value);
	  my $db = GUS::Model::Core::DatabaseInfo->new({'name' =>$space});
	  if (!$db->retrieveFromDB()) {
	    $self->userError("The space name $space, provided in the cfg_file for the table field, is not a valid name in Core.DatabaseInfo.");
	  }
	  else {
	    my $db_id = $db->getId();
	    my $table = GUS::Model::Core::TableInfo->new({'name' =>$tablename, 'database_id' => $db_id});
	    if (!$table->retrieveFromDB()) {
	      $self->userError("The table name $tablename with database $space, as provided in the cfg_file for the table field, is not a valid entry in Core.TableInfo.");
	    }
	    else {
	      $cfg_info->{'table_id'} = $table->getId();
	      $cfg_info->{'pk'} = $table->get('primary_key_column');
	      $cfg_info->{'table'} = $value;
	      $table_given = 1;
	    }
	  }
	}
	else {
	  $self->userError('Only one table should be provided in the cfg_file.');
	}
      }
      elsif ($name eq 'operator_id') {
	if (!$operator_id_given) {
	  my $contact = GUS::Model::SRes::Contact->new({'contact_id' =>$value});
	  if (!$contact->retrieveFromDB()) {
	    $self->userError("operator_id $value, provided in the cfg_file, is not a valid contact_id.");
	  }
	  $cfg_info->{'operator_id'} = $value;
	  $operator_id_given = 1;
	}
	else {
	  $self->userError('Only one operator_id should be provided in the cfg_file.');
	}
      }
      elsif ($name eq 'protocol_id') {
	if (!$protocol_id_given) {
	  my $protocol = GUS::Model::RAD3::Protocol->new({'protocol_id' =>$value});
	  if (!$protocol->retrieveFromDB()) {
	    $self->userError("protocol_id $value, provided in the cfg_file, is not a valid protocol_id.");
	  }
	  my $oe_id = $protocol->get('protocol_type_id');
	  my $oe = GUS::Model::RAD3::OntologyEntry->new({'ontology_entry_id' =>$oe_id});
	  $oe->retrieveFromDB();
	  if ($self->getArgs->{'subclass_view'} eq 'RAD3::DataTransformationResult' && $oe->get('category') ne 'DataTransformationProtocolType') {
	    $self->userError("You are trying to load into the view RAD3::DataTransformationResult, but the protocol type for the protocol_id provided in the cfg_file is not in the DataTransformationProtocolType category.");
	  }
	  if ($self->getArgs->{'subclass_view'} ne 'RAD3::DataTransformationResult' && $oe->get('category') ne 'HigherLevelAnalysisProtocolType') {
	    $self->userError("The protocol type for the protocol_id provided in the cfg_file is not in the HigherLevelAnalysisProtocolType category.");
	  }
	  $cfg_info->{'protocol_id'} = $value;
	  $protocol_id_given = 1;
	}
	else {
	  $self->userError('Only one protocol_id should be provided in the cfg_file.');
	}
      }
      elsif ($name eq 'analysis_date') {
	if (!$analysis_date_given) {
	  if ($value =~ /^(\d\d\d\d)\-(\d\d)\-(\d\d)$/) {
	    $cfg_info->{'analysis_date'} = $value.' 00:00:00'; 
	    $analysis_date_given = 1;
	  } 
	  else {
	    $self->userError("Invalid date format for analysis_date in the cfg_file. The correct format is YYYY-MM-DD."); 
	  }
	}
	else {
	  $self->userError('Only one analysis_date should be provided in the cfg_file.');
	}
      }
      elsif ($name =~ /^protocol_param_id(\d+)$/) {
	my $index = $1;
	if ($index<1) {
	  $self->userError('In the cfg_file, each protocol_param_idN must have N>0.');
	}
	$cfg_info->{'protocol_param_id'}->[$index] = $value;
      }
      elsif ($name =~ /^protocol_param_value(\d+)$/) {
	my $index = $1;
	if ($index<1) {
	  $self->userError('In the cfg_file, each protocol_param_valueN must have N>0.');
	}
	$cfg_info->{'protocol_param_value'}->[$index] = $value;
      }
      elsif ($name =~ /^protocol_qc_param_id(\d+)$/) {
	my $index = $1;
	if ($index<1) {
	  $self->userError('In the cfg_file, each protocol_qc_param_idN must have N>0.');
	}
	$cfg_info->{'protocol_qc_param_id'}->[$index] = $value;
      }
      elsif ($name =~ /^protocol_qc_param_value(\d+)$/) {
	my $index = $1;
	if ($index<1) {
	  $self->userError('In the cfg_file, each protocol_qc_param_valueN must have N>0.');
	}
	$cfg_info->{'protocol_qc_param_value'}->[$index] = $value;
      }
      elsif ($name =~ /^logical_group_id(\d+)$/) {
	my $index = $1;
	if ($index<1) {
	  $self->userError('In the cfg_file, each logical_group_idN must have N>0.');
	}
	my $group = GUS::Model::RAD3::LogicalGroup->new({'logical_group_id' => $value});
	if (!$group->retrieveFromDB()) {
	  $self->userError("logical_group_id $value, provided in the cfg_file, is not a valid logical_group_id.");
	}
	$cfg_info->{'logical_group_id'}->[$index] = $value;
	$logical_group_id_given++;
      }
      else {
	$self->userError('The only valid names in the cfg_file are: table, operator_id, protocol_id, analysis_date, protocol_param_idN, protocol_param_valueN, protocol_qc_param_idN, protocol_qc_param_valueN, logical_group_idN.');
      }
    }
  }
  $fh->close();
  if (!$table_given) {
    $self->userError->('The cfg_file must contain a value for table.');
  }
  if (!defined($self->getArgs->{'analysis_id'}) && (!$protocol_id_given || !$analysis_date_given || !$logical_group_id_given)) {
    $self->userError('The cfg_file must contain values for protocol_id, analysis_date, and at least one logical_group_id.');
  }
  if (defined($cfg_info->{'protocol_param_id'}) && defined($cfg_info->{'protocol_param_value'}) && scalar(@{$cfg_info->{'protocol_param_id'}}) != scalar(@{$cfg_info->{'protocol_param_value'}})) {
    $self->userError("The number or protocol_param_id's given in the cfg_file does not match the number of protocol_param_value's.");
  }
  if (defined($cfg_info->{'protocol_qc_param_id'}) && defined($cfg_info->{'protocol_qc_param_value'}) && scalar(@{$cfg_info->{'protocol_qc_param_id'}}) != scalar(@{$cfg_info->{'protocol_qc_param_value'}})) {
    $self->userError("The number or protocol_qc_param_id's given in the cfg_file does not match the number of protocol_qc_param_value's.");
  }
  if (defined($cfg_info->{'protocol_param_id'})) {
     my $sth1 = $dbh->prepare("select o.category, o.value from RAD3.OntologyEntry o, RAD3.Protocol p where p.protocol_type_id=o.ontology_entry_id and p.protocol_id=$cfg_info->{'protocol_id'}");
    $sth1->execute();
    my ($category, $protocol_type) = $sth1->fetchrow_array();
    my @protocol_ids = ($cfg_info->{'protocol_id'});
    if ($category eq "DataTransformationProtocolType" && $protocol_type eq "transformation_protocol_series") {
      my $sth2 = $dbh->prepare("select child_protocol_id from RAD3.ProtocolStep where parent_protocol_id=$cfg_info->{'protocol_id'}");
      $sth2->execute();
      while (my ($id) = $sth2->fetchrow_array()) {
	push(@protocol_ids, $id);
      }
    }
    for (my $i=1; $i<scalar(@{$cfg_info->{'protocol_param_id'}}); $i++) {
      my $is_valid_protocol = 0;
      for (my $j=0; $j<@protocol_ids; $j++) {
	my $protocol_param = GUS::Model::RAD3::ProtocolParam->new({'protocol_param_id' =>$cfg_info->{'protocol_param_id'}->[$i], 'protocol_id'=>$protocol_ids[$j]});
	if ($protocol_param->retrieveFromDB()) {
	  $is_valid_protocol = 1;
	  last;
	}
      }
      if (!$is_valid_protocol) {
	$self->userError("protocol_param_id $cfg_info->{'protocol_param_id'}->[$i], provided in the cfg_file for the $i-th protocol parameter, is not a valid protocol_param_id for protocol_id $cfg_info->{'protocol_id'} or its components.");
      }
    }
  }
  if (defined($cfg_info->{'protocol_qc_param_id'})) {
     my $sth1 = $dbh->prepare("select o.category, o.value from RAD3.OntologyEntry o, RAD3.Protocol p where p.protocol_type_id=o.ontology_entry_id and p.protocol_id=$cfg_info->{'protocol_id'}");
    $sth1->execute();
    my ($category, $protocol_type) = $sth1->fetchrow_array();
    my @protocol_ids = ($cfg_info->{'protocol_id'});
    if ($category eq "DataTransformationProtocolType" && $protocol_type eq "transformation_protocol_series") {
      my $sth2 = $dbh->prepare("select child_protocol_id from RAD3.ProtocolStep where parent_protocol_id=$cfg_info->{'protocol_id'}");
      $sth2->execute();
      while (my ($id) = $sth2->fetchrow_array()) {
	push(@protocol_ids, $id);
      }
    }
    for (my $i=1; $i<scalar(@{$cfg_info->{'protocol_qc_param_id'}}); $i++) {
      my $is_valid_protocol = 0;
      for (my $j=0; $j<@protocol_ids; $j++) {
	my $protocol_qc_param = GUS::Model::RAD3::ProtocolQCParam->new({'protocol_qc_param_id' =>$cfg_info->{'protocol_qc_param_id'}->[$i], 'protocol_id'=>$protocol_ids[$j]});
	if ($protocol_qc_param->retrieveFromDB()) {
	  $is_valid_protocol = 1;
	  last;
	}
      }
      if (!$is_valid_protocol) {
	$self->userError("protocol_qc_param_id $cfg_info->{'protocol_qc_param_id'}->[$i] for the $i-th protocol qc parameter, provided in the cfg_file, is not a valid protocol_qc_param_id for protocol_id $cfg_info->{'protocol_id'} or its components.");
      }
    }
  }
  return $cfg_info;
}

sub readDataFile {
  my ($self, $view, $pk, $table) = @_;
  my $data;
  my $line_num = 0;

  my $fh = new IO::File;
  my $file = $self->getArgs->{'data_file'};
  unless ($fh->open("<$file")) {
    $self->error("Could not open the file $self->getArgs->{'data_file'}.");
  }

  my %header;
  my %position;
  my $line = "";
  $self->log("Checking the data file header".);
  while ($line =~ /^\s*$/) {
    last unless $line = <$fh>;
  }

  my @arr = split(/\t/, $line);
  my $num_fields = scalar(@arr);
  for (my $i=0; $i<@arr; $i++) {
    $arr[$i] =~ s/^\s+|\s+$//g;
    $arr[$i] =~ s/\"|\'//g;
    if ($header{$arr[$i]}) {
      $self->userError('No two columns can have the same name in the data file header.');
    }
    else {
      $header{$arr[$i]} = 1;
      $position{$arr[$i]} = $i;
    }
  }
  if (!$header{'row_id'}) {
    $self->userError('The data file should contain one column with header \"row_id\".');
  }
  my $v = $view->new();
  my $attribute;
  foreach my $key (keys %header) {
    if ($v->isValidAttribute($key)) {
      if ($key ne 'analysis_result_id' && $key ne 'subclass_view' && $key ne 'analysis_id' && $key ne 'table_id' && $key ne 'row_id') {
	$attribute->{$key} = $position{$key};
      }
    }
  }

  $self->logData("Valid attributes in the header:");
  my $num_attr = 0;
  foreach my $key (keys %{$attribute}) {
    $self->logData("$key");
    $num_attr++;
  }

  my $dbh = $self->getQueryHandle();
  while ($line=<$fh>) {
    $line_num++;
    if ($line_num % 200 == 0) {
      $self->log("Reading line $line_num in the data file, after the header .");
    }
    if ($line =~ /^\s*$/) {
      next;
    }
    my @arr = split(/\t/, $line);
    if (scalar(@arr) != $num_fields) {
      $self->userError("The number of fields on the $line_num-th line after the header in data_file does not equal $num_fields, the number of header fields.");
    }
    for (my $i=0; $i<@arr; $i++) {
      $arr[$i] =~ s/^\s+|\s+$//g;
      $arr[$i] =~ s/\"|\'//g;
      if ($arr[$i] eq "na" || $arr[$i] eq "NA" || $arr[$i] eq "n/a" || $arr[$i] eq "N/A") {
	$arr[$i] = "";
      }
    }
    if ($arr[$position{'row_id'}] ne "") {
      $data->[$line_num]->{'row_id'} = $arr[$position{'row_id'}];
      my $row_id = $data->[$line_num]->{'row_id'};
      my $sth = $dbh->prepare("select $pk from $table where $pk=$row_id");
      $sth->execute();
      if (!$sth->fetchrow_array()) {
	$self->userError("The row_id on line $line_num is not a valid $pk for $table.");
      }
    }
    $data->[$line_num]->{'discard'} = 0;
    my $num_missing = 0;
    foreach my $key (keys %{$attribute}) {
      if ($arr[$attribute->{$key}] ne "") {
	$data->[$line_num]->{$key} = $arr[$attribute->{$key}];
      } 
      else {
	$num_missing++;
      }
    }
    if ($num_missing == $num_attr) {
      $data->[$line_num]->{'discard'} = 1;
    }
  }
  $fh->close();
  return ($data, $line_num);
}

sub insertAnalysis {
  my ($self, $cfg_info) = @_;
  my ($resultDescrip, $analysis_id);
  my $num_analysis_input = 0;
  my $num_analysis_param = 0;
  my $num_analysis_qc_param = 0;
  my $num_assay_analysis = 0;
  my $dbh = $self->getQueryHandle();
  my @assay_ids;
  my %assay_counted;

  my $analysis = GUS::Model::RAD3::Analysis->new({protocol_id => $cfg_info->{'protocol_id'}, analysis_date => $cfg_info->{'analysis_date'}});
  if (defined $cfg_info->{'operator_id'}) {
    $analysis->set('operator_id', $cfg_info->{'operator_id'});
  }

  my $sth =$dbh->prepare("select t.table_id from Core.TableInfo t, Core.DatabaseInfo d where t.name='Assay' and d.name='RAD3' and t.database_id=d.database_id");
  $sth->execute();
  my ($assay_table_id) = $sth->fetchrow_array();

  $sth =$dbh->prepare("select t.table_id from Core.TableInfo t, Core.DatabaseInfo d where t.name='Acquisition' and d.name='RAD3' and t.database_id=d.database_id");
  $sth->execute();
  my ($acquisition_table_id) = $sth->fetchrow_array();

  $sth =$dbh->prepare("select t.table_id from Core.TableInfo t, Core.DatabaseInfo d where t.name='Quantification' and d.name='RAD3' and t.database_id=d.database_id");
  $sth->execute();
  my ($quantification_table_id) = $sth->fetchrow_array();

  for (my $i=1; $i<@{$cfg_info->{'logical_group_id'}}; $i++) {
    if (defined $cfg_info->{'logical_group_id'}->[$i]) {
      my $sth1 = $dbh->prepare("select distinct row_id from RAD3.LogicalGroupLink where table_id=$assay_table_id and logical_group_id= $cfg_info->{'logical_group_id'}->[$i]");
      $sth1->execute();
      while (my ($assay_id)= $sth1->fetchrow_array()) {
	if (!$assay_counted{$assay_id}) {
	  push (@assay_ids, $assay_id);
	  $assay_counted{$assay_id} = 1;
	}
      }
      my $sth2 = $dbh->prepare("select distinct a.assay_id from RAD3.Acquisition a, RAD3.LogicalGroupLink l where l.table_id=$acquisition_table_id and l.logical_group_id= $cfg_info->{'logical_group_id'}->[$i] and l.row_id=a.acquisition_id");
      $sth2->execute();
      while (my ($assay_id)= $sth2->fetchrow_array()) {
	if (!$assay_counted{$assay_id}) {
	  push (@assay_ids, $assay_id);
	  $assay_counted{$assay_id} = 1;
	}
      }

      my $sth3 = $dbh->prepare("select distinct a.assay_id from RAD3.Acquisition a, RAD3.Quantification q, RAD3.LogicalGroupLink l where l.table_id=$quantification_table_id and l.logical_group_id= $cfg_info->{'logical_group_id'}->[$i] and l.row_id=q.quantification_id and q.acquisition_id=a.acquisition_id");
      $sth3->execute();
      while (my ($assay_id)= $sth3->fetchrow_array()) {
	if (!$assay_counted{$assay_id}) {
	  push (@assay_ids, $assay_id);
	  $assay_counted{$assay_id} = 1;
	}
      }

      my $analysis_input = GUS::Model::RAD3::AnalysisInput->new({logical_group_id => $cfg_info->{'logical_group_id'}->[$i]});
      $analysis_input->setParent($analysis);
      $num_analysis_input++;
    }
  }
  for (my $i=0; $i<@assay_ids; $i++) {
    my $assay_analysis = GUS::Model::RAD3::AssayAnalysis->new({assay_id => $assay_ids[$i]});
      $assay_analysis->setParent($analysis);
      $num_assay_analysis++;
  }
  if (defined($cfg_info->{'protocol_param_id'})) {
    for (my $i=1; $i<@{$cfg_info->{'protocol_param_id'}}; $i++) {
      my $analysis_param = GUS::Model::RAD3::AnalysisParam->new({protocol_param_id => $cfg_info->{'protocol_param_id'}->[$i], value => $cfg_info->{'protocol_param_value'}->[$i]});
      $analysis_param->setParent($analysis);
      $num_analysis_param++;
    }
  }
  if (defined($cfg_info->{'protocol_qc_param_id'})) {
    for (my $i=1; $i<@{$cfg_info->{'protocol_qc_param_id'}}; $i++) {
      my $analysis_qc_param = GUS::Model::RAD3::AnalysisQCParam->new({protocol_qc_param_id => $cfg_info->{'protocol_qc_param_id'}->[$i], value => $cfg_info->{'protocol_qc_param_value'}->[$i]});
      $analysis_qc_param->setParent($analysis);
      $num_analysis_qc_param++;
    }
  }

  $analysis->submit();
  $resultDescrip .= "Entered $num_analysis_input rows in RAD3.AnalysisInput, $num_assay_analysis rows in RAD3.AssayAnalysis, $num_analysis_param rows in RAD3.AnalysisParam, $num_analysis_qc_param rows in RAD3.AnalysisQCParam.";
  $analysis_id = $analysis->getId();
  return ($resultDescrip, $analysis_id);
}

sub insertAnalysisResults {
  my ($self, $view, $analysis_id, $table_id, $data, $line_count) = @_;
  my $resultDescrip;
  my $num_results = 0;

  my ($space, $subclass_view) = split(/::/, $self->getArgs->{'subclass_view'});
  my $start_line = defined $self->getArgs->{'restart'} ? $self->getArgs->{'restart'} : 1;

  my $end_line = defined $self->getArgs->{'testnum'} ? $start_line-1+$self->getArgs->{'testnum'} : $line_count;

  for (my $i=$start_line; $i<=$end_line; $i++) {
    if ($i % 200 == 0) {
      $self->log("Inserting data from the $i-th line.");
    }
    if (defined $data->[$i] && $data->[$i]->{'discard'} == 0) {
      $num_results++;
      my $analysis_result = $view->new({subclass_view => $subclass_view, analysis_id => $analysis_id});
      if (defined($data->[$i]->{'row_id'})) {
	$analysis_result->set('table_id', $table_id);
      }
      foreach my $key (keys %{$data->[$i]}) {
	if ($key ne "discard") {
	  $analysis_result->set($key, $data->[$i]->{$key});
	}
      }
      $analysis_result->submit();
    }
    $self->undefPointerCache();
  }

  $resultDescrip = "Entered $num_results rows in RAD3.$subclass_view.";
  return $resultDescrip;
}

1;

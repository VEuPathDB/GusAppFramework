package GUS::Common::Plugin::LoadDocumentation;
@ISA = qw(GUS::PluginMgr::Plugin); #defines what is inherited

use strict;

use FileHandle;
use GUS::Model::Core::DatabaseInfo;
use GUS::Model::Core::TableInfo;
use GUS::Model::Core::DatabaseDocumentation;

############################################################
###########################################################
### LoadDocumentation.pm
###
### Loads documentation for tables and attributes for 
###    the GUS project into the DatabaseDocumentation table
###
### Mandatory input: tab-delimited file formated as follows:
###
###    Table documentation: "table_name\t\ttable_documentation\n"
###
###    Attribute documentation: "table_name\tattribute_name\t
###       attribute_documentation\n"
###
### Created Apr-1-2002 - Originally named GUSDoc.pm
### 
### Matt Mailman
###
### Modifications:
###    - Summer 2002 - made compliant with new object layer -
###         renamed: GUS30Doc.pm
###    - Feb-10-2003 
###         - made compliant with new CVS structure and
###              recent changes in the object layer
###         - added checks against the database to ensure that
###              attribute name exists before loading documentation
###    - May-15-2003
###         - fixed $easycsp for 'inputFile' and removed 'testnumber'
###    - November-10-2003
###         - fixed so that an additional check is done to see if 
###              table documentation already exists
###    - December-09-2003
###         - fixed bug in table doc fetchrow
###
### Last modified December-09-2003
###
### usage: ga LoadDocumentation --inputFile [file]
###   run from inside directory containing file to upload 
############################################################

############################################################
sub new {
    my ($class) = @_;
    my $self = {};
    bless($self, $class);
    my $usage = 'Loads documentation for tables and attributes of the GUS project';
    my $easycsp =
	[{o => 'inputFile',
	  t => 'string',
	  h => 'name of the documentation file to load',
	 }];
    $self->initialize({requiredDbVersion => {Core => '3'},
		       cvsRevision => '$Revision$', #CVS fills this in
		       cvsTag => '$Name$', #CVS fills this in
		       name => ref($self),
		       revisionNotes => 'make consistent with GUS 3.0',
		       easyCspOptions => $easycsp,
		       usage => $usage
		      });
    return $self;
} # end sub new

my $ctx;
my $countInserts = 0;

############################################################
############################################################
sub run {
	my $self = shift;
	$ctx = shift;
	
	if (!$ctx->{cla}->{'inputFile'}) {
	  die "you must provide --inputFile on the command line\n";
	}

	print $ctx->{cla}->{'commit'} ? "*** COMMIT ON ***\n" : "*** COMMIT TURNED OFF ***\n";

	$self->logRAIID;
	$self->logCommit;
	$self->logArgs;
	
	my $doc_fh = FileHandle->new('<' . $self->getCla->{inputFile});
	return sprintf('documentation file %s was not found %s',
								 $self->getCla->{inputFile},
								 $!) unless $doc_fh;

	while (<$doc_fh>){ # read in line of documentation and parse from tab-delimited file
	  chomp;
	  my ($table_name, $attribute_name, $html_doc) = split (/\t/, $_);
	  $self->process($table_name, $attribute_name, $html_doc);
	}
	$doc_fh->close;

	return "Inserted $countInserts rows";
} # end sub run

############################################################
############################################################
sub process {
	my $self = shift;
	my ($table_nm, $attribute_nm, $html_dc) = @_;
	$self->logVerbose("Reading table: $table_nm\tAttribute: $attribute_nm\tDocumentation: $html_dc");

	my $verbose = $self->getCla->{verbose};
	my $db = $self->getDb;
        $db->setGlobalNoVersion(1);
	my $doc = GUS::Model::Core::DatabaseDocumentation->new();
	$self->logVerbose("Created new DatabaseDocumentation object");

	if ($db->checkTableExists($table_nm)){ # if table exists

	    ## skip identical attribute documentation
	    if ($attribute_nm =~ /\w/) {
		my $dbh = $ctx->{'self_inv'}->getDbHandle();
		my $t_id = $doc->getTableIdFromTableName($table_nm); #get table_id from table name
		my $query = "SELECT table_id, attribute_name, html_documentation FROM Core.DatabaseDocumentation WHERE table_id=$t_id AND attribute_name='$attribute_nm'";
		$self->logVerbose("Querying Core.DatabaseDocumentation for duplicate attribute documentation");
		my $stmt = $dbh->prepare($query);
		$stmt->execute();
		my ($tb_id, $att_name, $html);

		while (my @ary = $stmt->fetchrow_array() ){
		    chomp;
		    $tb_id = $ary[0]; #queried table id
		    $att_name = $ary[1]; #queried attribute name
		    $html = $ary[2]; #queried html documentation

		    ## SKIP if documentation is identical to what is already in db
		    if (($att_name eq $attribute_nm) && ($html eq $html_dc)){ 
			$self->logAlert("ALREADY EXISTS! Documentation for $table_nm" .
					"." ."$attribute_nm NOT OVERWRITTEN!");
			return; # SKIP
		    } # end if same doc
		} # end while
	    }# end if  

	    ## skip identical table documentation
	    elsif ($attribute_nm =~ /\W/) { # NULL attribute
		my $dbh2 = $ctx->{'self_inv'}->getDbHandle();
		my $t_id2 = $doc->getTableIdFromTableName($table_nm); #get table_id from table name
		my $query2 = "SELECT table_id, html_documentation " .
		             "FROM Core.DatabaseDocumentation " .
                             "WHERE table_id=$t_id2 " .
			     "AND attribute_name IS NULL";
		$self->logVerbose("Querying Core.DatabaseDocumentation for duplicate table documentation");
		my $stmt2 = $dbh->prepare($query2);
		$stmt2->execute();
		my ($tb_id2, $html2);

		while (my @ary2 = $stmt2->fetchrow_array() ){
		    chomp;
		    $tb_id = $ary2[0]; #queried table id
		    $html = $ary2[1]; #queried html documentation

		    ## SKIP if documentation is identical to what is already in db
		    if ($html eq $html_dc){ 
			$self->logAlert("ALREADY EXISTS! Documentation for $table_nm NOT OVERWRITTEN!");
			return; # SKIP
		    }
		} # end while
	    } # end elsif attribute_nm NULL

	  ## attribute is valid for this table - SUBMIT
	  if ($db->getTable($table_nm)->isValidAttribute($attribute_nm)){ # if column exists

	    ## bind table id to DatabaseDocumentation object
	    $doc->setTableId($doc->getTableIdFromTableName($table_nm));
	    $self->logVerbose("Set table ID");

	    ## bind attribute name to DatabaseDocumentation object
	    $doc->setAttributeName($attribute_nm) unless $table_nm eq $attribute_nm;
	    $self->logVerbose("Set attribute name");

	    ## bind html documentation to DatabaseDocumentation object
	    $doc->setHtmlDocumentation($html_dc);
	    $self->logVerbose("Set HTML Documentation");

	    ## submit to db
	    $doc->submit();
	    $countInserts++;
	    $self->logData("Inserted documentation for attribute: $table_nm" . "." ."$attribute_nm");
	    $self->undefPointerCache();
	    $self->logVerbose("UndefPointerCache()");
	  }#end if

	  ## documentation for the table (attribute name is NULL) - SUBMIT
	  elsif ($attribute_nm eq "NULL" || $attribute_nm eq "null"  || $attribute_nm eq ""){
	    $self->logVerbose("Documentation for table (no attribute supplied)");

	    ## bind table id to DatabaseDocumentation object
	    $doc->setTableId($doc->getTableIdFromTableName($table_nm));
	    $self->logVerbose("Set table ID");

	    ## bind html documentation to DatabaseDocumentation object
	    $doc->setHtmlDocumentation($html_dc);
	    $self->logVerbose("Set HTML Documentation");

	    ## submit to db
	    $doc->submit();
	    $countInserts++;
	    $self->logData("Inserted documentation for table: $table_nm");
	    $self->undefPointerCache();
	    $self->logVerbose("UndefPointerCache()");
	  }#end elsif

	  ## attribute is not valid for this table - DON'T SUBMIT
	  elsif (! $db->getTable($table_nm)->isValidAttribute($attribute_nm)){
	    $self->logAlert("NOT INSERTED! $attribute_nm is not a valid attribute for $table_nm");
	  }

	}#end if table exists

	## no table name in db
	else {
	  $self->logAlert("NOT INSERTED! $table_nm does not exist");
	  return;
        }
	$db->setGlobalNoVersion(0);
	
} # end sub process
1;

############################################################
############################################################
__END__

=pod
=head1 Description
B<Template> - a template plug-in for C<ga> (GUS application) package.

=head1 Purpose
B<Template> is a minimal 'plug-in' GUS application.

=cut

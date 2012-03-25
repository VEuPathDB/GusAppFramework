package GUS::Community::Plugin::LoadDocumentation;
@ISA = qw(GUS::PluginMgr::Plugin);
use strict;
use FileHandle;
use GUS::Model::Core::DatabaseInfo;
use GUS::Model::Core::TableInfo;
use GUS::Model::Core::DatabaseDocumentation;

############################################################################
############################################################################
### LoadDocumentation.pm
###
### Loads documentation for tables and attributes for 
###    the GUS project into the DatabaseDocumentation table
###
### Mandatory input: tab-delimited file formated as follows:
###    Table documentation: "namespace::table_name\t\ttable_documentation\n"
###    Attribute documentation: "namespace::table_name\tattribute_name\t
###       attribute_documentation\n"
###
### Created Apr-1-2002 - Originally named GUSDoc.pm
### 
### Matt Mailman
###
### Last modified March-01-2004
###
### usage: ga GUS::Community::Plugin::LoadDocumentation --inputFile [file]
###   run from inside directory containing file to upload 
############################################################################
############################################################################
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

    ### READ IN LINE FROM DOCUMENTATION
    while (<$doc_fh>){
	chomp;
	my ($table_name, $attribute_name, $html_doc) = split (/\t/, $_);

	### SEND TO &PROCESS
	$self->process($table_name, $attribute_name, $html_doc);
    }
    $doc_fh->close;
    return "$countInserts rows inserted, updated, or overwritten";
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

    ### TABLE EXISTS
    if ($db->checkTableExists($table_nm)){ # if table exists

	### DOCUMENTATION IS FOR TABLE (NOT ATTRIBUTE)
	if ($attribute_nm eq "NULL" || $attribute_nm eq "null"  || $attribute_nm eq "") {
	    $doc->setTableId($doc->getTableIdFromTableName($table_nm));

	    ### QUERY FOR PRIMARY KEY OF TABLE DOCUMENTATION IN DB
	    my $dbh = $ctx->{'self_inv'}->getDbHandle();
	    my $t_id = $doc->getTableIdFromTableName($table_nm); #get table_id from table name
	    my $query = "SELECT database_documentation_id, table_id, attribute_name, html_documentation " . 
	         	"FROM Core.DatabaseDocumentation " .
		        "WHERE table_id = $t_id " .
		        "AND attribute_name IS NULL";
	    my $stmt = $dbh->prepare($query);
	    $stmt->execute();
	    my ($database_documentation_id, $tb_id, $att_name, $html);
	    while (my @ary = $stmt->fetchrow_array()){
		chomp;
		$database_documentation_id = $ary[0]; #queried primary key
		$tb_id = $ary[1]; #queried table id
		$att_name = $ary[2]; #queried attribute name
		$html = $ary[3]; #queried html documentation
		$doc->setDatabaseDocumentationId($database_documentation_id);
		$doc->retrieveFromDB();

		### DOCUMENTATION NEEDS TO BE UPDATED
		if ($doc->getHtmlDocumentation($html_dc) ne $html_dc) {
		    $doc->setHtmlDocumentation($html_dc);
		    $doc->submit();
		    $countInserts++;
		    $self->logVerbose("Updated table documentation for: $table_nm\t$html_dc");
		    return();
		}

		### SKIP BECAUSE DOCUMENTATION IS IDENTICAL TO WHAT IS IN DB
		elsif ($doc->setHtmlDocumentation($html_dc) eq $html_dc) {
		    $self->logAlert("Documentation already exists: $table_nm.$attribute_nm\t$html_dc\n");
		    return();
		}
	    } # end while ary
	    
	    ### DOCUMENT IF NOT ALREADY IN DATABASE (NEW)
	    $doc->setHtmlDocumentation($html_dc);
	    $doc->submit();
	    $countInserts++;
	    $self->logVerbose("Submitted new table documentation for: $table_nm\t$html_dc");
	    return();
	} # end if table documentation

	### VALID ATTRIBUTE
	elsif ($db->getTable($table_nm)->isValidAttribute($attribute_nm)){
	    $doc->setTableId($doc->getTableIdFromTableName($table_nm));
	    $doc->setAttributeName($attribute_nm);
	    $doc->retrieveFromDB();

	    ### DOCUMENTATION SHOULD BE UPDATED
	    if ($doc->getHtmlDocumentation($html_dc) ne $html_dc) {
		$doc->setHtmlDocumentation($html_dc);
		$doc->submit();
		$countInserts++;
		$self->logVerbose("Submitted documentation: $table_nm.$attribute_nm\t$html_dc");
		return();
	    }

	    ### SKIP BECAUSE DOCUMENTATION IS IDENTICAL TO WHAT IS IN DB
	    elsif ($doc->setHtmlDocumentation($html_dc) eq $html_dc) {
		$self->logAlert("Documentation already exists for: $table_nm.$attribute_nm\t$html_dc\n");
		return();
	    }

	    ### PREVIOUSLY UNDOCUMENTATED ATTRIBUTE
	    else {
		$doc->submit();
		$countInserts++;
		$self->logVerbose("Submitted documentation: $table_nm.$attribute_nm\t$html_dc");
		return();
	    }
	} # end if valid attribute

	### SKIP BECAUSE ATTRIBUTE IS NOT VALID
	else {
	    $self->logAlert("Attribute $attribute_nm is not valid for $table_nm");
	    return;
	}
    } # end if table exists

    ### SKIP BECAUSE TABLE IS NOT VALID
    else {
	$self->logAlert("Table $table_nm does not exist");
	return;
    }
    $db->setGlobalNoVersion(0);
    return();
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

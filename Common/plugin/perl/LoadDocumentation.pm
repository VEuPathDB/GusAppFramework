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
###    - May-17-2003
###         - added 1; to end of file
###
### Last modified May-17-2003
###
### usage: ga LoadDocumentation --inputFile [file]
###   run from inside directory containing file to upload 
############################################################
############################################################
package GUS::Common::Plugin::LoadDocumentation;
@ISA = qw(GUS::PluginMgr::Plugin); #defines what is inherited

use strict;

use FileHandle;
use GUS::Model::Core::DatabaseInfo;
use GUS::Model::Core::TableInfo;
use GUS::Model::Core::DatabaseDocumentation;

############################################################
############################################################
sub new {
    my ($class) = @_;
    my $self = {};
    bless($self, $class);
    my $usage = 'Loads documentation for tables and attributes of the GUS project';
    my $easycsp =
	[{o => 'inputFile',
	  t => 'string',#	$self->logData("Test: table name = $table_nm attribute name = $attribute_nm html documentation = $html_dc\n") if $verbose;
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
	}#	$self->logData("Test: table name = $table_nm attribute name = $attribute_nm html documentation = $html_dc\n") if $verbose;

	print $ctx->{cla}->{'commit'} ? "*** COMMIT ON ***\n" : "*** COMMIT TURNED OFF ***\n";

	$self->logRAIID;
	$self->logCommit;
	$self->logArgs;
	
	my $ctTables = 0; #counter for number of tables
	my $ctAtts   = 0; #counter for number of attributes

	my $doc_fh = FileHandle->new('<' . $self->getCla->{inputFile});
	return sprintf('documentation file %s was not found %s',
								 $self->getCla->{inputFile},
								 $!) unless $doc_fh;

	while (<$doc_fh>){ # read in line of documentation and parse from tab-delimited file
		my ($table_name, $attribute_name, $html_doc) = split (/\t/, $_);
#		print "Table: $table_name\nAttribute: $attribute_name\nDocumentation: $html_doc\n";
		$self->process($table_name, $attribute_name, $html_doc);
	}
	$doc_fh->close;

	return "processed $ctTables rows";
} # end sub run

############################################################
############################################################
sub process {
	my $self = shift;
	my ($table_nm, $attribute_nm, $html_dc) = @_;
	$self->logData("Table: $table_name\nAttribute: $attribute_name\nDocumentation: $html_doc\n");

	my $verbose = $self->getCla->{verbose};

	$self->logData("Test: table name = $table_nm attribute name = $attribute_nm html documentation = $html_dc\n") if $verbose;

	my $db = $self->getDb;
        $db->setGlobalNoVersion(1);

	my $doc = GUS::Model::Core::DatabaseDocumentation->new();
	$self->logData("Created new DatabaseDocumentation object\n\n") if $verbose;

	if ($db->checkTableExists($table_nm)){ # if table exists

	    if ($db->getTable($table_nm)->isValidAttribute($attribute_nm)){ # if column exists
		$doc->setTableId($doc->getTableIdFromTableName($table_nm));
	        $self->logVerbose("Set table ID\n\n");
		$doc->setAttributeName($attribute_nm) unless $table_nm eq $attribute_nm;
	        $self->logVerbose("Set attribute name\n\n");
		$doc->setHtmlDocumentation($html_dc) unless $html_dc eq $doc->getHtmlDocumentation(); #only set if different
		$countInserts++;
	        $self->logVerbose("Set HTML Documentation\n\n");
		$doc->submit();
	        $self->logVerbose("Submit object to database\n\n");
		$self->undefPointerCache();
	        $self->logVerbose("UndefPointerCache()\n\n");
	    }
	    elsif ($attribute_nm == "NULL"){ #attribute name is null
	      	$doc->setTableId($doc->getTableIdFromTableName($table_nm));
	        $self->logVerbose("Set table ID\n\n");
		$doc->setAttributeName($attribute_nm) unless $table_nm eq $attribute_nm;
	        $self->logVerbose("Set attribute name\n\n");
		$doc->setHtmlDocumentation($html_dc) unless $html_dc eq $doc->getHtmlDocumentation(); #only set if different
		$countInserts++;
	        $self->logVerbose("Set HTML Documentation\n\n");
		$doc->submit();
	        $self->logVerbose("Submit object to database\n\n");
		$self->undefPointerCache();
	        $self->logVerbose("UndefPointerCache()\n\n");
	    }
	    else{ # no attribute name in table
		$self->logAlert("Attribute $attribute_nm does not exist in $table_nm\n");
		next;
	    }
	}
	else { # no table name in db
	    $self->logAlert("Table $table_nm does not exist in database\n"); 
	    next;
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

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

	return "processed $countInserts rows";
} # end sub run

############################################################
############################################################
sub process {
	my $self = shift;
	my ($table_nm, $attribute_nm, $html_dc) = @_;
	$self->logData("\tTable: $table_nm\tAttribute: $attribute_nm\tDocumentation: $html_dc");

	my $verbose = $self->getCla->{verbose};
	my $db = $self->getDb;
        $db->setGlobalNoVersion(1);
	my $doc = GUS::Model::Core::DatabaseDocumentation->new();
	$self->logVerbose("Created new DatabaseDocumentation object");
	
	if ($db->checkTableExists($table_nm)){ # if table exists

	    if ($db->getTable($table_nm)->isValidAttribute($attribute_nm)){ # if column exists
		$doc->setTableId($doc->getTableIdFromTableName($table_nm));
	        $self->logVerbose("Set table ID");
		$doc->setAttributeName($attribute_nm) unless $table_nm eq $attribute_nm;
	        $self->logVerbose("Set attribute name");
#		$doc->setHtmlDocumentation($html_dc) unless $html_dc eq $doc->getHtmlDocumentation(); #only set if different

		## want to skip identical documentation - query to see if already stored
		my $dbh = $ctx->{'self_inv'}->getDbHandle();
		my $t_id = $doc->getTableIdFromTableName($table_nm); #get table_id from table name
		my $query = "SELECT table_id, attribute_name, html_documentation FROM Core.DatabaseDocumentation WHERE table_id=$t_id";
		$self->logVerbose("Querying Core.DatabaseDocumentation for duplicate entry");
		my $stmt = $dbh->prepare($query);
		$stmt->execute();
		while (my @ary = $stmt->fetchrow_array() ){
		  chomp;
		  my $tb_id = $ary[0]; #queried table id
		  my $att_name = $ary[1]; #queried attribute name
		  my $html = $ary[2]; #queried html documentation

		  print "tb_id: $tb_id\tatt_name: $att_name\thtml: $html\n";

		  if ($html eq $html_dc){ #documentation is identical to what is already in db - SKIP
		    $self->logAlert("Identical documentation already exists for Table: $table_nm\tAttribute: $attribute_nm\tNot overwritten!");
		    return;
		  }
		}
		
		my $test_dc = $doc->getHtmlDocumentation();
		print "\nhtml: $test_dc\n\n";

		if ($html_dc eq $doc->getHtmlDocumentation()){
		  $self->logAlert("This documentation is identical to what is already stored for attribute: $attribute_nm in table: $table_nm. Not inserted.");
		  next;
		}
		else{
		  $doc->setHtmlDocumentation($html_dc);
		}

		$countInserts++;
	        $self->logVerbose("Set HTML Documentation");
		$doc->submit();
	        $self->logVerbose("Submit object to database");
		$self->undefPointerCache();
	        $self->logVerbose("UndefPointerCache()");
	    }

	    elsif ($attribute_nm == "NULL" || $attribute_nm == "null"  || $attribute_nm == ""){ #attribute name is null
	      	$doc->setTableId($doc->getTableIdFromTableName($table_nm));
	        $self->logVerbose("Set table ID");
		$doc->setAttributeName($attribute_nm) unless $table_nm eq $attribute_nm;
	        $self->logVerbose("Set attribute name");
		$doc->setHtmlDocumentation($html_dc) unless $html_dc eq $doc->getHtmlDocumentation(); #only set if different

		if ($html_dc eq $doc->getHtmlDocumentation()){
		  $self->logAlert("This documentation is identical to what is already stored for table: $table_nm. Not inserted.");
		  next;
		}

		else{
		  $doc->setHtmlDocumentation($html_dc);
		}

		$countInserts++;
	        $self->logVerbose("Set HTML Documentation");
		$doc->submit();
	        $self->logVerbose("Submit object to database");
		$self->undefPointerCache();
	        $self->logVerbose("UndefPointerCache()");
	    }

	    else{ # no attribute name in table
		$self->logAlert("Attribute $attribute_nm does not exist in $table_nm");
		next;
	    }
	}

	else { # no table name in db
	    $self->logAlert("Table $table_nm does not exist in database");
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

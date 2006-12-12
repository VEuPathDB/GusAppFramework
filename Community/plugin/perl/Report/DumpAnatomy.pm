###################################################################
##           DumpAnatomy.pm
##
## This scripts generates a dump of the SRes.Anatomy table.
###################################################################



package GUS::Community::Plugin::Report::DumpAnatomy;
@ISA = qw(GUS::PluginMgr::Plugin);
 
use strict;

use FileHandle;
use GUS::ObjRelP::DbiDatabase;
use GUS::PluginMgr::Plugin;

use GUS::Model::SRes::Anatomy;

my $argsDeclaration = [
		       stringArg({name  => 'fileName',
				  descr => 'The name of the output file in which SRes.Anatomy will be dumped',
				  constraintFunc=> undef,
				  reqd  => 1,
				  isList => 0,
				  format => 'See the NOTES',
				  })
		       ];


my $purposeBrief = <<PURPOSEBRIEF;
Dump the content of SRes.Anatomy Table.
PURPOSEBRIEF

my $purpose = <<PLUGIN_PURPOSE;
Dump the content of SRes.Anatomy Table in a file.
PLUGIN_PURPOSE

my $tablesAffected = [];

my $tablesDependedOn = ['SRes.Anatomy'];

my $howToRestart = <<PLUGIN_RESTART;
This is a read-only plugin: Just restart the plugin.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
unknown
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
The file format is the following: No ID is dumped in the file, just the full hierarchy for each entry of SRes.Anatomy, separated by semicolons, followed by source and descriptions, separated by colons.
PLUGIN_NOTES

my $documentation = {purposeBrief => $purposeBrief,
		     purpose => $purpose,
		     tablesAffected => $tablesAffected,
		     tablesDependedOn => $tablesDependedOn,
		     howToRestart => $howToRestart,
		     failureCases => $failureCases,
		     notes => $notes
		    };


##################################################################
# new
##################################################################
sub new {
    my ($class) = @_;
    my $self = {};
    bless($self, $class);
    
    $self->initialize(
		      {requiredDbVersion => 3.5,
		       cvsRevision =>  '$Revision: 4495 $', #CVS fills this in
		       name => ref($self),
		       argsDeclaration   => $argsDeclaration,
		       documentation     => $documentation,
		   });
    
    return $self;
}

##################################################################
# run
##################################################################
sub run {	
    my ($self) = @_;
    
    open (FILE, ">" . $self->getArg('fileName'));
    
    my $sql = "SELECT NAME,HIER_LEVEL,PARENT_ID,SOURCE,DESCRIPTION FROM SRes.Anatomy ORDER BY HIER_LEVEL";
    
    my $sth = $self->getQueryHandle()->prepareAndExecute($sql);
    my $r=0;
    
    while (my @arr = $sth->fetchrow_array())  {
	
	my $name = $arr[0];
	my $hierLevel = $arr[1];
	my $parentID = $arr[2];
	my $source = $arr[3];
	my $description = $arr[4];
	
	my @array;
	
	#print "name = $name  hier level = $hierLevel\n";
	
	push(@array, $name);
	
	my $arrayref;

	if(defined $parentID) {
	    $arrayref = $self->getParent($parentID, \@array); }
	else {
	    $arrayref = \@array;
	}
	
	my @finalarray = @$arrayref;
	
	for(my $i=$#finalarray; $i>0; $i--) {
	    print FILE "$finalarray[$i];;";
	}
	print FILE "$finalarray[0]\t$source\t$description\n";
	$r++;
    }
    
    close (FILE);
    return "$r rows dumped\n";
}

sub getParent {
    my($self, $parentID, $arrayref) = @_;
    
    my $sql ="SELECT NAME,PARENT_ID FROM SRes.Anatomy WHERE ANATOMY_ID = $parentID";
    my $queryHandle = $self->getQueryHandle();
    my $sth = $queryHandle->prepareAndExecute($sql);
    my @arr = $sth ->fetchrow_array();
    
    my $name = $arr[0];
    my $parentID = $arr[1];
        
    push(@$arrayref, $name);
    
    if(defined $parentID) { return $self->getParent($parentID, $arrayref); }
    else { return $arrayref; }
}

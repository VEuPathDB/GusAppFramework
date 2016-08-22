package GUS::Supported::Plugin::InsertContact;
@ISA = qw( GUS::PluginMgr::Plugin);

use strict 'vars';

use GUS::PluginMgr::Plugin;
use lib "$ENV{GUS_HOME}/lib/perl";
use Carp;
use GUS::Model::SRes::Contact;

my $argsDeclaration = 
  [
   stringArg({name => 'first',
	      descr => 'first name',
	      reqd => 0,
	      constraintFunc => undef,
	      isList => 0,
	     }),
   stringArg({name => 'last',
	      descr => 'last name',
	      reqd => 0,
	      constraintFunc => undef,
	      isList => 0,
	     }),
   stringArg({name => 'name',
	      descr => 'full name',
	      reqd => 1,
	      constraintFunc => undef,
	      isList => 0,
	     }),
   stringArg({name => 'city',
	      descr => 'city',
	      reqd => 0,
	      constraintFunc => undef,
	      isList => 0,
	     }),
   stringArg({name => 'state',
	      descr => 'state',
	      reqd => 0,
	      constraintFunc => undef,
	      isList => 0,
	     }),
   stringArg({name => 'country',
	      descr => 'country',
	      reqd => 0,
	      constraintFunc => undef,
	      isList => 0,
	     }),
   stringArg({name => 'zip',
	      descr => 'zip code',
	      reqd => 0,
	      constraintFunc => undef,
	      isList => 0,
	     }),
   stringArg({name => 'address1',
	      descr => 'address1',
	      reqd => 0,
	      constraintFunc => undef,
	      isList => 0,
	     }),
   stringArg({name => 'address2',
	      descr => 'address2',
	      reqd => 0,
	      constraintFunc => undef,
	      isList => 0,
	     }),
   stringArg({name => 'email',
	      descr => 'email',
	      reqd => 0,
	      constraintFunc => undef,
	      isList => 0,
	     }),
   stringArg({name => 'phone',
	      descr => 'phone',
	      reqd => 0,
	      constraintFunc => undef,
	      isList => 0,
	     }),
   stringArg({name => 'fax',
	      descr => 'fax',
	      reqd => 0,
	      constraintFunc => undef,
	      isList => 0,
	     }),
  ];


my $purposeBrief = <<PURPOSEBRIEF;
Creates a new SRes.Contact
PURPOSEBRIEF
    
my $purpose = <<PLUGIN_PURPOSE;
Creates a new SRes.Contact
PLUGIN_PURPOSE
    
my $tablesAffected = 
	[['SRes.Contact', 'The entry representing the new sres contact is created here']];

my $tablesDependedOn = [];

my $howToRestart = <<PLUGIN_RESTART;
Only one row is created, so if the plugin fails, restart by running it again with the same parameters (accounting for any errors that may have caused the failure.
PLUGIN_RESTART

my $failureCases = <<PLUGIN_FAILURE_CASES;
If the entry already exists, based on the --name flag and a corresponding name in the table, then the plugin does not submit a new row.  This is not a failure case per se, but will result in no change to the database where one might have been expected.
PLUGIN_FAILURE_CASES

my $notes = <<PLUGIN_NOTES;
The way the plugin checks to make sure there is not already an entry representing this database is by case-insensitive matching against the name.  There is a chance, however, that the user could load a duplicate entry, representing the same database, but with different names, because of a misspelling or alternate naming convention.  This cannot be guarded against, so it is up to the user to avoid duplicate entries when possible.
PLUGIN_NOTES

my $documentation = { purpose=>$purpose,
		      purposeBrief=>$purposeBrief,
		      tablesAffected=>$tablesAffected,
		      tablesDependedOn=>$tablesDependedOn,
		      howToRestart=>$howToRestart,
		      failureCases=>$failureCases,
		      notes=>$notes
		    };

sub new {
    my ($class) = @_;
    my $self = {};
    bless($self,$class);
 

    $self->initialize({requiredDbVersion => 4.0,
		       cvsRevision => '$Revision: 5359 $', # cvs fills this in!
		       name => ref($self),
		       argsDeclaration => $argsDeclaration,
		       documentation => $documentation
		      });

    return $self;
}

#######################################################################
# Main Routine
#######################################################################

sub run {
    my ($self) = @_;
    my $name = $self->getArg('name');

    my $msg;

    my $sql = "select contact_id from sres.contact where lower(name) like '" . lc($name) ."'";
    my $sth = $self->prepareAndExecute($sql);
    my ($id) = $sth->fetchrow_array();

    if ($id){
	$msg = "Not creating a new entry for $name as one already exists in the database (id $id)";
    }

    else {
      my $contact = GUS::Model::SRes::Contact->
        new({name => $name,
             first => $self->getArg('first'),
             last => $self->getArg('last'),
             city => $self->getArg('city'),
             state => $self->getArg('state'),
             country => $self->getArg('country'),
             zip => $self->getArg('zip'),
             address1 => $self->getArg('address1'),
             address2 => $self->getArg('address2'),
             email => $self->getArg('email'),
             phone => $self->getArg('phone'),
             fax => $self->getArg('fax'),
	   });
	$contact->submit();
	my $newPk = $contact->getId();
	$msg = "created new entry for contact $name with primary key $newPk";
    }

    return $msg;
}

1;

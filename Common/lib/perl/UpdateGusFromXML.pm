
package GUS30::GA_plugins::Utils::UpdateGusFromXML;
@ISA = qw(GUS::PluginMgr::Plugin);
use strict;

use FileHandle;

# ----------------------------------------------------------------------
# create and initalize new plugin instance.

sub new {
	my $Class = shift;

	my $m = bless {}, $Class;

	$m->setUsage('module that parses an XML file and updates GUS: "// on newline delimits submits');
	$m->setVersion('2.0');
	$m->setRequiredDbVersion({});
	$m->setDescription('updated for GUS30 and placed in Utils section');
	$m->setEasyCspOptions({ h => 'if true then will update the row with new modification data and algorithmInvocation regardless if has changed from the database',
                                t => 'boolean',
                                o => 'refresh',
                              },
                              
                              {	h => 'name of file containing XML',
                                t => 'string',
                                d => '-',
                                o => 'filename',
                              },
                             );
        
	# RETURN
	$m
}

# ----------------------------------------------------------------------
# plugin-global variables.

my $countObjs = 0;
my $countUpdates = 0;

# ----------------------------------------------------------------------
# run method to do the work

sub run {
	my $M   = shift;

	my $RV;

	my $fh = FileHandle->new('<'.$M->getCla->{'filename'});
	if ($fh) {

		$M->log('COMMIT', $M->getCla->{commit} ? 'ON' : 'OFF' );

		##testing exitOnFailure...
		$M->getDb()->setExitOnSQLFailure(0);

		# process XML file.
		my @xml;
		while(<$fh>){
			if(/^\/\/\s*$/){  ##"//" on a newline defines entry
				$M-process(\@xml) if scalar(@xml) > 1;  ##must be at least 3 actually to be valid...
				undef @xml; ##reset for the new one...
			}else{
				push(@xml,$_);
			}
		}
		$M->process(\@xml) if scalar(@xml) > 1;  ##must be at least 3 actually to be valid...
		$fh->close;

		# create, log, and return result string.
		$RV = join(' ',
							 "processed $countObjs objects, inserted",
							 $M->getSelfInv->getTotalInserts(),
							 'and updated',
							 $M->getSelfInv->getTotalUpdates() || 0,
							);
	}

	# no file.
	else {
		$RV = join(' ',
							 'a valid --filename <filename> must be on the commandline',
							 $M->getCla->{filename},
							 $!);
	}

	$M->log('RESULT', $RV);
	return $RV;
}

# ----------------------------------------------------------------------
# do the real work.
sub process {
	my $M    = shift;
	my($xml) = @_;

	$M->getSelfInv->parseXML($xml);
	$M->countChangedObjs($M->getSelfInv);

	##now submit the sucker...
	##must first remove invocation parent before submitting immediate children
	$M->getSelfInv->manageTransaction(undef,'begin');
	foreach my $c ($M->getSelfInv->getAllChildren()){
		$c->removeParent($M->getSelfInv);
		$c->submit(undef,1);
		$c->setParent($M->getSelfInv);  ##add back so can see at the end...
	}
	$M->getSelfInv->manageTransaction(undef,'commit');
	if(!$M->getCla->{commit}){
		$M->log('ERROR', "XML that was not committed to the database\n\n");
		foreach my $c ($M->getSelfInv->getAllChildren()){
			$M->log('BAD-XML', $c->toXML());
		}
	}
	$M->getSelfInv->removeAllChildren();
	$M->getSelfInv->undefPointerCache();
}

sub countChangedObjs {
	my $M = shift;
	my($par) = @_;

	foreach my $c ($par->getAllChildren()){
		$M->log('DEBUG',
						"Checking to see if has changed attributes\n".$c->toXML()) if $M->getCla->{debug};
		$countObjs++;
		$countUpdates++;
		if(!$M->getCla->{refresh} && !$c->hasChangedAttributes()){
			$M->log('DEBUG','There are no changed attributes') if $M->getCla->{debug};
			$countUpdates--;
		}
		$M->countChangedObjs($c);
	}
}

1;


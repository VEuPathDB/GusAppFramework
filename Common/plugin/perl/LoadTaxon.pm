#################################################################################################
##LoadTaxon.pm 
##
##This is a ga plug_in to populate the Taxon  and TaxonNames tables with entries from the ncbi nodes.dmp table  
##
##Created Nov 1, 2001 NEED TO ADD WRITING TO LOG-OTHER VERIFICATIONS AND SAFEGUARDS
##
##Deborah Pinney 
##
##algorithm_id=4889       
##algorithm_imp_id=5825
##################################################################################################
package GUS::Common::Plugin::LoadTaxon;

@ISA = qw(GUS::PluginMgr::Plugin);
use strict;

use FileHandle;

use GUS::Model::SRes::Taxon;
use GUS::Model::SRes::TaxonName;
use GUS::Model::SRes::GeneticCode;


my $dbh;
my $count = 0;

sub new {
  my ($class) = @_;

  my $self = {};
  bless($self,$class);

  my $usage = 'Plug_in to populate the Taxon, GeneticCode, and TaxonName tables using files downloaded from NCBI';

  my $easycsp =
    [
     {o => 'nodes',
      t => 'string',
      h => 'file from ncbi with tax_id,parent_id,rank,etc e.g. /usr/local/db/local/taxonomy/nodes.dmp',
     },
     {o => 'names',
      t => 'string',
      h => 'file from ncbi with tax_id,name,name_class,etc
            e.g. /usr/local/db/local/taxonomy/names.dmp',
     },
     {o => 'gencode',
      t => 'string',
      h => 'file from ncbi with genetic_code_id,abbreviation,ame,code,starts
            e.g./usr/local/db/local/taxonomy/gencode.dmp',
     },
     {o => 'restart',
      t => 'int',
      h => 'tax_id of parent for restart',
     },
    ];

  $self->initialize({requiredDbVersion => {},
		     cvsRevision => '$Revision$', # cvs fills this in!
		     cvsTag => '$Name$', # cvs fills this in!
		     name => ref($self),
		     revisionNotes => 'make consistent with GUS 3.0',
		     easyCspOptions => $easycsp,
		     usage => $usage
		    });

  return $self;
}

sub Run {
    my $M   = shift;
    my $ctx = shift;
    $dbh = $ctx->{'self_inv'}->getQueryHandle();
    if (!$ctx->{'cla'}->{'names'} || !$ctx->{'cla'}->{'nodes'} || !$ctx->{'cla'}->{'gencode'}) {
	print STDERR ("Provide the names of the names.dmp, nodes.dmp, and gencode.dmp files on the command line\n");
    }
    
    print STDERR $ctx->{'commit'} ? "***COMMIT ON***\n" : "***COMMIT TURNED OFF***\n";
    print STDERR "Testing on $ctx->{'cla'}->{'testnumber'}\n" if $ctx->{'cla'}->{'testnumber'};

    my $genCodes = &makeGeneticCode();
    
    my $namesDmp = &getNames(); 
    
    my $nodesHash = &makeNodesHash();
    
    my $rootAttArray = &getRootAttArray($genCodes);

    &makeTaxonEntry($rootAttArray);
    
    if ($ctx->{'cla'}->{'restart'}) {
	&getTaxonAtt($ctx->{'cla'}->{'restart'},$nodesHash);
    }
    else {
	&getTaxonAtt($rootAttArray->[0],$nodesHash); 
    }
    &makeTaxonName($namesDmp);
    
}

sub makeGeneticCode {
    my %genCodes;  #$genCodes{ncbi_gencode_id}=GUS genetic_code_id
    open (GENCODE,$ctx->{'cla'}->{'gencode'}) || die "Can't open gencode file\n";
    while (<GENCODE>) {
	chomp;
	my @nodeArray = split(/\s*\|\s*/, $_);
	my $abbreviation = $nodeArray[1];
	my $ncbi_gencode_id = $nodeArray[0];
	my $name = $nodeArray[2];
	my $code = $nodeArray[3];
	if (!$code) {
	    $code = 'Unspecified';
	}
	my $starts = $nodeArray[4];
	if (!$starts) {
	    $starts = 'Unspecified';
	}
	my $newGeneticCode = GUS::Model::SRes::GeneticCode->new({'ncbi_genetic_code_id'=> $ncbi_gencode_id});
	$newGeneticCode->retrieveFromDB();
	if ($newGeneticCode->get('abbreviation') ne $abbreviation) {
	    $newGeneticCode->set('abbreviation',$abbreviation);
	}
	if ($newGeneticCode->get('name') ne $name) {
	    $newGeneticCode->set('name',$name);
	}
	if ($newGeneticCode->get('code') ne $code) {
	    $newGeneticCode->set('code',$code);
	}
	if ($newGeneticCode->get('starts') ne $starts) {
	    $newGeneticCode->set('starts',$starts);
	}
	$newGeneticCode->submit();
	$genCodes{$ncbi_gencode_id} = $newGeneticCode->get('genetic_code_id');
	$newGeneticCode->undefPointerCache();
    }
    return \%genCodes;
}

sub getNames { 
    my %namesDmp;
    open (NAMES,$ctx->{'cla'}->{'names'}) || die "Can't open names file\n";                   
    while (<NAMES>) {
	chomp;
	my @nameArray = split(/\s*\|\s*/, $_);
	$namesDmp{$nameArray[0]}->{$nameArray[1]}->{$nameArray[3]}->{$nameArray[2]}++; #namesDmp{tax_id}->{name}->{name class}->{unique name **mostly null}
    }
    return (\%namesDmp);
}

sub makeNodesHash {
    my %nodesHash; #nodesHash{parent ncbi tax_id}->{child ncbi tax_id}=(rank,genetic_code_id,mitochondrial_genetic_code_id) 
    open (NODES,$ctx->{'cla'}->{'nodes'}) || die "Can't open nodes file\n";
    while (<NODES>) {
	chomp;
	my @nodeArray = split(/\s*\|\s*/, $_);
	my $tax_id = $nodeArray[0];
	my $parent_tax_id = $nodeArray[1];
	my $rank = $nodeArray[2]; 
	my $gen_code = $nodeArray[6]; 
	my $mit_code = $nodeArray[8]; 
	if (!$mit_code) {  #some mit_gen_code_id are null, set to unspecified here
	    $mit_code=0;
	}
	if ($tax_id == $parent_tax_id) {   #the root has tax_id and parent_id equal to 1, causes problems with the recursive sub getTaxonAtt
	    $tax_id = 0;
	}
	$nodesHash{$parent_tax_id}->{$tax_id} = [$rank,$genCodes{$gen_code},$genCodes{$mit_code}];
    }
    return (\%nodesHash);
}

sub getRootAttArray {
    my ($genCodes) = @_;
    my $tax_id=1;
    my $rank='no rank';
    my $gen_code = 0;
    my $mit_code = 0;
    my $parent_tax_id = -1;
    my @rootArray = ($tax_id,$rank,$parent_tax_id,$genCodes->{$gen_code},$genCodes->{$mit_code});
    return \@rootArray;
}

sub makeTaxonEntry {
    my ($attArray) = @_;
    my $tax_id = $attArray->[0];
    my $rank = $attArray->[1];
    my $parent_id = $attArray->[2];
    my $gen_code = $attArray->[3];
    my $mit_code = $attArray->[4];

    my $newTaxon  = GUS::Model::SRes::Taxon->new({'ncbi_tax_id'=>$tax_id});
    $newTaxon ->retrieveFromDB();
    
    if ($newTaxon->get('rank') ne $rank) {
	$newTaxon->set('rank',$rank);
    }
    if ($parent_id != -1 && $newTaxon->get('parent_id') != $parent_id ) {
	$newTaxon->set('parent_id',$parent_id);
    }
    if ($newTaxon->get('genetic_code_id') != $gen_code) {
	$newTaxon->set('genetic_code_id',$gen_code);
    }
    if ($newTaxon->get('mitochondrial_genetic_code_id') != $mit_code) { 
	$newTaxon->set('mitochondrial_genetic_code_id',$mit_code);
    }  
    
    
    $newTaxon->submit();
    $newTaxon->undefPointerCache();
    print STDERR ("processed ncbi_tax_id : $tax_id\n");
    $count++;
    my $time = `date`;
    if ($count % 100 == 0) {
	print STDERR ("Number processed: $count   $date");
    }
}


sub getTaxonAtt {
  my ($parent_tax_id,$nodesHash) = @_;
  foreach my $tax_id (keys %{$nodesHash->{$parent_tax_id}}) {
    my $parent_taxon_id = &getTaxon($parent_tax_id);
    my $rank = $nodesHash{$parent_tax_id}->{$tax_id}[0];
    my $gen_code = $nodesHash{$parent_tax_id}->{$tax_id}[1];
    my $mit_code = $nodesHash{$parent_tax_id}->{$tax_id}[2];
    my @attArr=($tax_id,$rank,$parent_taxon_id,$gen_code,$mit_code);
    &makeTaxonEntry(\@attArr);
    &getTaxonAtt($tax_id);
  }
}

sub getTaxon{
  my ($tax_id) = @_;
  my $taxon_id;
  my $st = $dbh->prepare("select taxon_id from taxon where ncbi_tax_id = ?");
  $st->execute($tax_id);
  $taxon_id = $st->fetchrow_array();
  $st->finish();
  return $taxon_id;
}

sub makeTaxonName {
    my ($namesDmp) = @_; 
    my $num = 0;
    foreach my $tax_id (keys %$namesDmp) {
	my $taxon_id = &getTaxon($tax_id);;
	foreach my $name (keys %{$namesDmp->{$tax_id}}) {
	    foreach my $name_class (keys %{$namesDmp->{$tax_id}->{$name}}) {
		foreach my $unique_name_variant (keys %{$namesDmp->{$tax_id}->{$name}->{$name_class}}) {
		    my $newTaxonName = GUS::Model::SRes::TaxonName->new('taxon_id'=>$taxon_id);
		    $newTaxonName->retrieveFromDB();
		    if ($newTaxonName->get('name') ne $name) {
			$newTaxonName->set('name',$name);
		    }
		    if ($newTaxonName->get('unique_name_variant') ne $unique_name_variant) {
			$newTaxonName->set('unique_name_variant',$unique_name_variant);
		    }
		    if ($newTaxonName->get('name_class') ne $name_class) {
			$newTaxonName->set('name_class',$name_class);
		    }
		    $newTaxonName->submit();
		    $newTaxonName->undefPointerCache();
		    $num++;
		}
	    }
	}
    }
    print STDERR ("$num taxon names processed\n");
}


    
1;

__END__

=pod
=head1 Description
B<LoadTaxon> - a plug-in that creates Taxon, TaxonName,and GeneticCode entries from ncbi files.

=head1 Purpose
B<LoadTaxon> is a  GUS application that creates Taxon, TaxonName,and GeneticCode entries from ncbi files-original GUS taxon_ids have been retained.

      

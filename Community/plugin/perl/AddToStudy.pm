##
## AddToStudy Plugin
## $Id: AddToStudy.pm manduchi $
##


package GUS::Community::Plugin::AddToStudy;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;
use LWP::Simple;
use XML::LibXML;
use Data::Dumper;

use GUS::Model::SRes::Contact;
use GUS::Model::Study::StudyContact;
use GUS::Model::SRes::BibliographicReference;
use GUS::Model::SRes::OntologyTerm;
use GUS::Model::SRes::TaxonName;
use GUS::Model::Study::StudyBibRef;
use GUS::Model::Study::StudyDesign;
use GUS::Model::Study::StudyFactor;
use GUS::Model::Study::StudyFactorValue;
use GUS::Model::Study::StudyLink;
use GUS::Model::Study::Protocol;
use GUS::Model::Study::ProtocolParam;
use GUS::Model::Study::ProtocolSeriesLink;
use GUS::Model::Study::ProtocolApp;
use GUS::Model::Study::ProtocolAppParam;
use GUS::Model::Study::ProtocolAppContact;
use GUS::Model::Study::ProtocolAppNode;
use GUS::Model::Study::Characteristic;
use GUS::Model::Study::Input;
use GUS::Model::Study::Output;

# ----------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------

sub getArgumentsDeclaration {
  my $argumentDeclaration  =
    [
     fileArg({name => 'xmlFile',
	      descr => 'The full path of the filtered xml file.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     })
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------

sub getDocumentation {
  my $purposeBrief = 'Adds to a study already present in the database';

  my $purpose = 'This plugin reads a filtered xml file, which can be obtained from appropriately parsing additions to a MAGE-TAB file, and inserts these additions into the database.';

  my $tablesAffected = [['Study::StudyDesign', 'Adds applicable study designs for this study'], ['Study::StudyFactors', 'Adds applicable study factors for this study'], ['SRes::Contact', 'Adds missing applicable contacts'], ['Study::StudyContact', 'Inserts links between this study and the added contacts'], ['SRes::BibliographicReference', 'Adds missing applicable bibliographic references'], ['Study::StudyBibRef', 'Inserts links between this study and the added bibliographic references'], ['Study::Protocol', 'Adds missing applicable protocols'], ['Study::ProtocolParam', 'Adds missing applicable protocol parameters'], ['Study::ProtocolSeriesLinks', 'Adds missing applicable protocol series links'], ['Study::ProtocolApp', 'Adds applicable protocol applications'], ['Study::ProtocolAppParam', 'Adds applicable protocol application parameters'], ['Study::ProtocolAppContact', 'Inserts links between added protocols and contacts'], ['Study::ProtocolAppNode', 'Adds applicable protocol application nodes'], ['Study::Characteristic', 'Inserts characteristics for the added protocol app. nodes'], ['Study::StudyFactorValues', 'Inserts links between added study factors and protocol application nodes'], ['Study::StudyLink', 'Inserts links between this study and the added application nodes'], ['Study::Input', 'Inserts links between added protocol applications and their inputs'], ['Study::Output', 'Inserts links between added protocol applications and their outputs']];

  my $tablesDependedOn = [['SRes::OntologyTerm', 'All ontology terms pointed to by additions to this study'], ['SRes::Taxon', 'All taxa pointed to by additions to this study'], ['SRes::ExternalDatabaseRelease', 'All external database releases referred to by additions to this study'], ['Core::DatabaseInfo', 'All database schemas referred to'], ['Core::TableInfo', 'All tables referred to']]; 

  my $howToRestart = '';

  my $failureCases = '';

  my $notes = <<NOTES;

=head2 F<xmlFile>

=head1 AUTHOR

Written by Elisabetta Manduchi.

=head1 COPYRIGHT

Copyright Elisabetta Manduchi, Trustees of University of Pennsylvania 2013. 
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

  $self->initialize({requiredDbVersion => 4.0,
		     cvsRevision => '$Revision$',
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

  my $parser = XML::LibXML->new();
  my $doc = $parser->parse_file($self->getArg('xmlFile'));

  my ($study) = $doc->findnodes('/mage-tab/idf/study');
  my $studyId = $study->getAttribute('db_id');
  
  $self->addBibRef($study, $studyId);
  $self->addStudyDesigns($doc, $studyId);
  $self->addStudyFactors($doc, $studyId);
  $self->addContacts($doc, $studyId);

  my @protocolSeriesNames;
  $self->addProtocols($doc, \@protocolSeriesNames);

  for (my $i=0; $i<@protocolSeriesNames; $i++) {
    $self->addProtocolSeries($protocolSeriesNames[$i]);
  }
  $self->addProtocolParams($doc);

  my $protAppNodeIds = $self->addProtocolAppNodes($doc, $studyId);
  $protAppNodeIds = $self->addFactorValues($doc, $studyId, $protAppNodeIds);
  $self->addProtocolApps($doc, $protAppNodeIds);
}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------

sub addBibRef {
  my ($self, $study, $studyId) = @_;
  
  my @pubmedIds = $study->findnodes('./pubmed_id');
  for (my $i=0; $i<@pubmedIds; $i++) {
    my $addition = $pubmedIds[$i]->getAttribute('addition');
    if (!defined($addition) || $addition ne 'true') {
      next;
    }
    my $pubmedId = $pubmedIds[$i]->findvalue('.');
    if (defined($pubmedId) && $pubmedId !~ /^\s*$/) {
      my $bibRef = $self->getBibRef($pubmedId);
      my $studyBibRef = GUS::Model::Study::StudyBibRef->new({study_id => $studyId});
      $studyBibRef->setParent($bibRef);
      $bibRef->submit();
      $self->undefPointerCache();
    }
  }
}

# AUTHOR of getPubmedXml: Oleg Khovayko
# This Util is Based on the eutils example from NCBI

sub getPubmedXml {
  my ($self, $pubmedId) = @_;

  my $utils = "http://www.ncbi.nlm.nih.gov/entrez/eutils";

  my $db     = "pubmed";
  my $report = "xml";

  my $esearch = "$utils/esearch.fcgi?db=$db&retmax=1&usehistory=y&term=";
  my $esearchResult = get($esearch . $pubmedId);

  $esearchResult =~ 
    m|<Count>(\d+)</Count>.*<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s;

  my $Count    = $1;
  my $QueryKey = $2;
  my $WebEnv   = $3;

  my $efetch = "$utils/efetch.fcgi?rettype=$report&retmode=text&retmax=1&db=$db&query_key=$QueryKey&WebEnv=$WebEnv";
	
  my $pubmedXml = get($efetch);
  return($pubmedXml);
}

sub getBibRef {
  my ($self, $pubmedId) = @_;

  my $parser = XML::LibXML->new();
  my $pubmedXml = $self->getPubmedXml($pubmedId);
  my $pubmedDoc = $parser->load_xml(string => $pubmedXml);

  my $title = $pubmedDoc->findvalue('/PubmedArticleSet/PubmedArticle/MedlineCitation/Article/ArticleTitle');

  my @authors;
  foreach my $a ($pubmedDoc->findnodes('/PubmedArticleSet/PubmedArticle/MedlineCitation/Article/AuthorList/Author')) {
    push(@authors, $a->findvalue('./LastName') . " " . $a->findvalue('./Initials'));
  }
  my $authorString = join(', ', @authors);

  my $journal = $pubmedDoc->findvalue('/PubmedArticleSet/PubmeArticle/MedlineCitation/Article/Journal/Title');
  $journal = $pubmedDoc->findvalue('/PubmedArticleSet/PubmedArticle/MedlineCitation/MedlineJournalInfo/MedlineTA') unless ($journal);

  my $year = $pubmedDoc->findvalue('/PubmedArticleSet/PubmedArticle/MedlineCitation/Article/Journal/JournalIssue/PubDate/Year');
  my $volume = $pubmedDoc->findvalue('/PubmedArticleSet/PubmedArticle/MedlineCitation/Article/Journal/JournalIssue/Volume');
  my $issue = $pubmedDoc->findvalue('/PubmedArticleSet/PubmedArticle/MedlineCitation/Article/Journal/JournalIssue/Issue');
  my $pages = $pubmedDoc->findvalue('/PubmedArticleSet/PubmedArticle/MedlineCitation/Article/Pagination/MedlinePgn');

  unless($issue || $pages) {
    $pages = '';
    $self->logAlert("Publication with Pumbed id $pubmedId seems to be ahead of print??... No PageNum or Issue");
  }

  my @abstractTexts = $pubmedDoc->findnodes('/PubmedArticleSet/PubmedArticle/MedlineCitation/Article/Abstract/AbstractText');
  my $abstract = $abstractTexts[0]->textContent();
  for (my $i=1; $i<@abstractTexts; $i++) {
    $abstract .= ',' . $abstractTexts[$i]->textContent();
  }
 
  my $extDbRlsId =  $self->getExtDbRlsId('PubMed|unknown');
  if (!$extDbRlsId || !defined($extDbRlsId)) {
    $self->userError("Database is missing an entry for the PubMed, with unknown version");
  }
  my $bibRef = GUS::Model::SRes::BibliographicReference->new({external_database_release_id => $extDbRlsId, source_id => $pubmedId});

  $bibRef->retrieveFromDB();
  $bibRef->setTitle($title);
  $bibRef->setAbstract($abstract);
  $bibRef->setAuthors($authorString);
  $bibRef->setPublication($journal);
  $bibRef->setYear($year);
  $bibRef->setVolume($volume);
  $bibRef->setIssue($issue);
  $bibRef->setPages($pages);

  return($bibRef);
}

sub getOntologyTerm {
  my ($self, $term, $extDbRlsId) = @_;
  
  my $ontologyTerm = GUS::Model::SRes::OntologyTerm->new({name => $term, external_database_release_id => $extDbRlsId});

  if (!$ontologyTerm->retrieveFromDB()) {
    $self->userError("Missing entry for term=$term and ext_db_rls_id=$extDbRlsId in SRes.OntologyTerm");
  }
  elsif ($ontologyTerm->getIsObsolete()==1) {
    $self->userError("Term $term is obsolete in ext_db_rls_id=$extDbRlsId");
  }
  return($ontologyTerm);
}

sub addStudyDesigns {
  my ($self, $doc, $studyId) = @_;
  
  my @studyDesigns = $doc->findnodes('/mage-tab/idf/study_design');
  for (my $i=0; $i<@studyDesigns; $i++) {
    my $addition = $studyDesigns[$i]->getAttribute('addition');
    if (!defined($addition) || $addition ne 'true') {
      next;
    }
    my $type = $studyDesigns[$i]->findvalue('./type');
    my $extDbRls = $studyDesigns[$i]->findvalue('./type_ext_db_rls');
    my $extDbRlsId = $self->getExtDbRlsId($extDbRls);

    if (!$extDbRlsId || !defined($extDbRlsId)) {
      $self->userError("Must provide a valid external database release for Study Design Type $type");
    }
    my $studyDesignType = $self->getOntologyTerm($type, $extDbRlsId);
    
    my $studyDesign = GUS::Model::Study::StudyDesign->new({study_id => $studyId});
    $studyDesign->setParent($studyDesignType);
    $studyDesign->submit();
    $self->undefPointerCache();
  }
}

sub addStudyFactors {
  my ($self, $doc, $studyId) = @_;

  my @studyFactors = $doc->findnodes('/mage-tab/idf/study_factor');
  for (my $i=0; $i<@studyFactors; $i++) {
    my $addition = $studyFactors[$i]->getAttribute('addition');
    if (!defined($addition) || $addition ne 'true') {
      next;
    }
    my $type = $studyFactors[$i]->findvalue('./type');
    my $extDbRls = $studyFactors[$i]->findvalue('./type_ext_db_rls');
    my $extDbRlsId = $self->getExtDbRlsId($extDbRls);;
    if (!$extDbRlsId || !defined($extDbRlsId)) {
      $self->userError("Must provide a valid external database release for Study Factor Type $type");
    }

    my $studyFactorType = $self->getOntologyTerm($type, $extDbRlsId);
    
    my $name = $studyFactors[$i]->findvalue('./name');
    my $description = $studyFactors[$i]->findvalue('./description');
    
    my $studyFactor = GUS::Model::Study::StudyFactor->new({name => $name, study_id=> $studyId});
    if (defined($description) && $description !~ /^\s*$/) {
      $studyFactor->setDescription($description);
    }
    
    $studyFactor->setParent($studyFactorType);
    $studyFactor->submit();
    $self->undefPointerCache();
  }
}

sub setExtDbRlsSourceId {
  my ($self, $extDbRls, $sourceId, $object) = @_;

  my $extDbRlsId =  $self->getExtDbRlsId($extDbRls);
  if (!$extDbRlsId || !defined($extDbRlsId)) {
    $self->userError("$extDbRlsId is not in SRes.ExternalDatabaseRelease");
  }
  $object->setExternalDatabaseReleaseId($extDbRlsId); 
  $object->setSourceId($sourceId);   
}

sub addContacts {
  my ($self, $doc, $studyId) = @_;
  
  my @contacts = $doc->findnodes('/mage-tab/idf/contact');
  for (my $i=0; $i<@contacts; $i++) {
    my $addition = $contacts[$i]->getAttribute('addition');
    if (!defined($addition) || $addition ne 'true') {
      next;
    }  
    my $name = $contacts[$i]->findvalue('./name');
    my $contact = GUS::Model::SRes::Contact->new({name => $name});
    my $affiliation = $contacts[$i]->findvalue('./affiliation');
    if ($name ne $affiliation) {
      my $affiliationObj = GUS::Model::SRes::Contact->new({name => $affiliation});
      $affiliationObj->retrieveFromDB();
      $contact->setParent($affiliationObj);
    }
    $contact->retrieveFromDB();
    
    my $firstName = $contacts[$i]->findvalue('./first_name');
    if (defined($firstName) && $firstName !~ /^\s*$/) {
      $contact->setFirst($firstName);
    }
    
    my $lastName = $contacts[$i]->findvalue('./last_name');
    if (defined($lastName) && $lastName !~ /^\s*$/) {
      $contact->setLast($lastName);
    }
    
    my $address1 = $contacts[$i]->findvalue('./address1');
    if (defined($address1) && $address1 !~ /^\s*$/) {
      $contact->setAddress1($address1);
    }
    
    my $address2 = $contacts[$i]->findvalue('./address2');
    if (defined($address2) && $address2 !~ /^\s*$/) {
      $contact->setAddress2($address2);
    }
    
    my $city = $contacts[$i]->findvalue('./city');
    if (defined($city) && $city !~ /^\s*$/) {
      $contact->setCity($city);
    }
    
    my $state = $contacts[$i]->findvalue('./state');
    if (defined($state) && $state !~ /^\s*$/) {
      $contact->setState($state);
    }
    
    my $country = $contacts[$i]->findvalue('./country');
    if (defined($country) && $country !~ /^\s*$/) {
      $contact->setCountry($country);
    }
    
    my $zip = $contacts[$i]->findvalue('./zip');
    if (defined($zip) && $zip !~ /^\s*$/) {
      $contact->setZip($zip);
    }
    
    my $email = $contacts[$i]->findvalue('./email');
    if (defined($email) && $email !~ /^\s*$/) {
      $contact->setEmail($email);
    }
    
    my $phone = $contacts[$i]->findvalue('./phone');
    if (defined($phone) && $phone !~ /^\s*$/) {
      $contact->setPhone($phone);
    }
    
    my $fax = $contacts[$i]->findvalue('./fax');
    if (defined($fax) && $fax !~ /^\s*$/) {
      $contact->setFax($fax);
    }
    
    my @roles = split(/;/, $contacts[$i]->findvalue('./roles'));
    my @extDbRls = split(/;/, $contacts[$i]->findvalue('./roles_ext_db_rls'));
    for (my $j=0; $j<@roles; $j++) {
      my $extDbRlsId = $self->getExtDbRlsId($extDbRls[$j]);
      if (!$extDbRlsId || !defined($extDbRlsId)) {
	$self->userError("Must provide a valid external database release for Contact Role $roles[$j]");
      }    
      my $contactRole = $self->getOntologyTerm($roles[$j], $extDbRlsId);
    
      my $studyContact = GUS::Model::Study::StudyContact->new({study_id => $studyId});
      $studyContact->setParent($contact);
      $studyContact->setParent($contactRole);
    }
    $contact->submit();
    $self->undefPointerCache();
  }
}

sub addProtocols {
  my ($self, $doc, $protocolSeriesNames) = @_;
 
  my @protocols = $doc->findnodes('/mage-tab/idf/protocol');
  for (my $i=0; $i<@protocols; $i++) {
    my $addition = $protocols[$i]->getAttribute('addition');
    if (!defined($addition) || $addition ne 'true') {
      next;
    }

    my @childProtocols = $protocols[$i]->findnodes('./child_protocol');
    if (scalar(@childProtocols)>1) {
      my @children;
      for (my $j=0; $j<@childProtocols; $j++) {
	my $step = $childProtocols[$j]->getAttribute('step');
	$children[$step-1] = $childProtocols[$j]->findvalue('.');
	if ($children[$step-1] =~ /^\s*$/) {
	  $self->userError("Missing value for child_protocol");
	}
      }
      push(@{$protocolSeriesNames}, join('|||', @children));
      next;
    }   

    my $name = $protocols[$i]->findvalue('./name');
    my $protocol = GUS::Model::Study::Protocol->new({name => $name});
    if ($protocol->retrieveFromDB()) {
      $self->logData("A protocol named $name already exists in the database. This will not be altered.");
      next;
    }
    
    my $description = $protocols[$i]->findvalue('./description');
    if (defined($description) && $description !~ /^\s*$/) {
      $protocol->setDescription($description);
    }
    
    my $type = $protocols[$i]->findvalue('./type');
    if (defined($type) && $type !~ /^\s*$/) {    
      my $typeExtDbRls = $protocols[$i]->findvalue('./type_ext_db_rls');
      my $typeExtDbRlsId = $self->getExtDbRlsId($typeExtDbRls);
      
      if (!$typeExtDbRlsId || !defined($typeExtDbRlsId)) {
	$self->userError("Must provide a valid external database release for Protocol Type $type");
      }
      my $protocolType = $self->getOntologyTerm($type, $typeExtDbRlsId);
      $protocol->setParent($protocolType);
    }
    
    my $otherRead = $protocols[$i]->findvalue('./other_read');
    if (defined($otherRead) && $otherRead !~ /^\s*$/) {
      $protocol->setOtherRead($otherRead);
    }
    
    my $pubmedId = $protocols[$i]->findvalue('./pubmed_id');
    if (defined($pubmedId) && $pubmedId  !~ /^\s*$/) {  
      my $bibRef = $self->getBibRef($pubmedId);
      $protocol->setParent($bibRef);
    }
    
    my $uri = $protocols[$i]->findvalue('./uri');
    if (defined($uri) && $uri  !~ /^\s*$/) {
      $protocol->setUri($uri);
    }
    
    my $extDbRls = $protocols[$i]->findvalue('./external_database_release');
    my $sourceId = $protocols[$i]->findvalue('./source_id');
    if (defined($extDbRls) && $extDbRls !~ /^\s*$/ && defined($sourceId) && $sourceId !~ /^\s*$/) {
      $self->setExtDbRlsSourceId($extDbRls, $sourceId, $protocol);     
    }
    
    my $contactName = $protocols[$i]->findvalue('./contact');
    if (defined($contactName) && $contactName !~ /^\s*$/) {
      my $contact = GUS::Model::SRes::Contact->new({name => $contactName});
      $contact->retrieveFromDB();
      $protocol->setParent($contact);
    }

    my $pubmedId = $protocols[$i]->findvalue('./pubmed_id');
    if (defined($pubmedId) && $pubmedId !~ /^\s*$/) {
      my $bibRef = $self->getBibRef($pubmedId);
      $protocol->setParent($bibRef);
    }
    
    my @protocolParams = $protocols[$i]->findnodes('./param');
    for (my $j=0; $j<@protocolParams; $j++) {
      my $name = $protocolParams[$j]->findvalue('./name');
      if (defined($name) && $name !~ /^\s*$/) {
	my $protocolParam = GUS::Model::Study::ProtocolParam->new({name => $name});
	$protocolParam->setParent($protocol);
	
	my $defaultValue = $protocolParams[$j]->findvalue('./default_value');
	if (defined($defaultValue) && $defaultValue  !~ /^\s*$/) {
	  $protocolParam->setDefaultValue($defaultValue);
	}
	
	my $isUserSpecified = $protocolParams[$j]->findvalue('./is_user_specified');
	if (defined($isUserSpecified) && $isUserSpecified  !~ /^\s*$/) {
	  $protocolParam->setIsUserSpecified($isUserSpecified);
	}
	
	my $dataTypeTerm = $protocolParams[$j]->findvalue('./data_type'); 
	if (defined($dataTypeTerm) && $dataTypeTerm !~ /^\s*$/) { 
	  my $dataTypeExtDbRls = $protocolParams[$j]->findvalue('./data_type_ext_db_rls'); 
	  my $dataTypeExtDbRlsId = $self->getExtDbRlsId($dataTypeExtDbRls);
	  
	  if (!$dataTypeExtDbRlsId || !defined($dataTypeExtDbRlsId)) {
	    $self->userError("Must provide a valid external database release for Data Type $dataTypeTerm");
	  }
	  my $dataType = $self->getOntologyTerm($dataTypeTerm, $dataTypeExtDbRlsId);
	  my $dataTypeId = $dataType->getId();
	  $protocolParam->setDataTypeId($dataTypeId);
	} 
	
	my $unitTypeTerm = $protocolParams[$j]->findvalue('./unit_type'); 
	if (defined($unitTypeTerm) && $unitTypeTerm !~ /^\s*$/) { 
	  my $unitTypeExtDbRls = $protocolParams[$j]->findvalue('./unit_type_ext_db_rls'); 
	  my $unitTypeExtDbRlsId = $self->getExtDbRlsId($unitTypeExtDbRls);
	  
	  if (!$unitTypeExtDbRlsId || !defined($unitTypeExtDbRlsId)) {
	    $self->userError("Must provide a valid external database release for Unit Type $unitTypeTerm");
	  }
	  my $unitType = $self->getOntologyTerm($unitTypeTerm, $unitTypeExtDbRlsId);
	  my $unitTypeId = $unitType->getId();
	  $protocolParam->setUnitTypeId($unitTypeId);
	} 
      }
    }
    $protocol->submit();
  }
}

sub addProtocolSeries {
  my ($self, $protocolSeriesName) = @_;
  
  my $protocolSeries = GUS::Model::Study::Protocol->new({name => $protocolSeriesName});
  $protocolSeries->submit();
  my $protocolSeriesId = $protocolSeries->getId();
  my @children = split(/\|\|\|/, $protocolSeriesName);
  for (my $i=0; $i<@children; $i++) {
    my $orderNum = $i+1;
    my $protocolSeriesLink = GUS::Model::Study::ProtocolSeriesLink->new({order_num => $orderNum});
    my $protocol = GUS::Model::Study::Protocol->new({name => $children[$i]});
    if (!$protocol->retrieveFromDB()) {
      $self->userError("There is no protocol named '$children[$i]' in the database");
    }
    my $protocolId = $protocol->getId();
    $protocolSeriesLink->setProtocolSeriesId($protocolSeriesId);
    $protocolSeriesLink->setProtocolId($protocolId);
    $protocolSeriesLink->submit();
  }
}

sub addProtocolParams {
  my ($self, $doc) = @_;
  
  my @protocols = $doc->findnodes('/mage-tab/idf/protocol');
  for (my $i=0; $i<@protocols; $i++) {
    my $protocolId = $protocols[$i]->getAttribute('db_id');
    if (!defined($protocolId) || $protocolId  =~ /^\s*$/) {
      next;
    }
    my @protocolParams = $protocols[$i]->findnodes('./param');
    for (my $j=0; $j<@protocolParams; $j++) {
      my $addition = $protocolParams[$j]->getAttribute('addition');
      if (!defined($addition) || $addition ne 'true') {
	next;
      }
      my $name = $protocolParams[$j]->findvalue('./name');
      if (defined($name) && $name !~ /^\s*$/) {
	my $protocolParam = GUS::Model::Study::ProtocolParam->new({protocol_id => $protocolId, name => $name});
	
	my $defaultValue = $protocolParams[$j]->findvalue('./default_value');
	if (defined($defaultValue) && $defaultValue  !~ /^\s*$/) {
	  $protocolParam->setDefaultValue($defaultValue);
	}
	
	my $isUserSpecified = $protocolParams[$j]->findvalue('./is_user_specified');
	if (defined($isUserSpecified) && $isUserSpecified  !~ /^\s*$/) {
	  $protocolParam->setIsUserSpecified($isUserSpecified);
	}
	
	my $dataTypeTerm = $protocolParams[$j]->findvalue('./data_type'); 
	if (defined($dataTypeTerm) && $dataTypeTerm !~ /^\s*$/) { 
	  my $dataTypeExtDbRls = $protocolParams[$j]->findvalue('./data_type_ext_db_rls'); 
	  my $dataTypeExtDbRlsId = $self->getExtDbRlsId($dataTypeExtDbRls);
	  
	  if (!$dataTypeExtDbRlsId || !defined($dataTypeExtDbRlsId)) {
	    $self->userError("Must provide a valid external database release for Data Type $dataTypeTerm");
	  }
	  my $dataType = $self->getOntologyTerm($dataTypeTerm, $dataTypeExtDbRlsId);
	  my $dataTypeId = $dataType->getId();
	  $protocolParam->setDataTypeId($dataTypeId);
	} 
	
	my $unitTypeTerm = $protocolParams[$j]->findvalue('./unit_type'); 
	if (defined($unitTypeTerm) && $unitTypeTerm !~ /^\s*$/) { 
	  my $unitTypeExtDbRls = $protocolParams[$j]->findvalue('./unit_type_ext_db_rls'); 
	  my $unitTypeExtDbRlsId = $self->getExtDbRlsId($unitTypeExtDbRls);
	  
	  if (!$unitTypeExtDbRlsId || !defined($unitTypeExtDbRlsId)) {
	    $self->userError("Must provide a valid external database release for Unit Type $unitTypeTerm");
	  }
	  my $unitType = $self->getOntologyTerm($unitTypeTerm, $unitTypeExtDbRlsId);
	  my $unitTypeId = $unitType->getId();
	  $protocolParam->setUnitTypeId($unitTypeId);
	}
	$protocolParam->submit();
	$self->undefPointerCache();
      }
    }
  }
}

sub addProtocolAppNodes {
  my ($self, $doc, $studyId) = @_;
  my $protocolAppNodeIds;
  
  $self->logData("Adding Protocol Application Nodes");
  my @protocolAppNodes = $doc->findnodes('/mage-tab/sdrf/protocol_app_node');
  my $count;
  for (my $i=0; $i<$protocolAppNodes[$i]; $i++) {

    my $id = $protocolAppNodes[$i]->getAttribute('id');
    my $addition = $protocolAppNodes[$i]->getAttribute('addition');
    if (!defined($addition) || $addition ne 'true') {
      my $pan = $protocolAppNodes[$i];
      my $pan_id = $self->handleExistingProtocolAppNode($pan);
      $protocolAppNodeIds->{$id} = $pan_id if defined($pan_id);
      next;
    }
    
    my $name = $protocolAppNodes[$i]->findvalue('./name');
    my $protocolAppNode = GUS::Model::Study::ProtocolAppNode->new({name => $name});
    my $typeNode = $protocolAppNodes[$i]->findvalue('./type');
    if (defined($typeNode) && $typeNode !~ /^\s*$/) {
	my $node = $protocolAppNodes[$i];
      my $extDbRlsId = $self->setExtDbSpec($node);
     
      
      my $type = $self->getOntologyTerm($typeNode, $extDbRlsId);
      my $typeId = $type->getId();
      $protocolAppNode->setTypeId($typeId);
    }
    
    my $description = $protocolAppNodes[$i]->findvalue('./description');
    if (defined($description) && $description !~ /^\s*$/) {
      $protocolAppNode->setDescription($description);
    }
    
    my $extDbRls = $protocolAppNodes[$i]->findvalue('./ext_db_rls');
    my $sourceId = $protocolAppNodes[$i]->findvalue('./source_id');
    if (defined($extDbRls) && $extDbRls !~ /^\s*$/ && defined($sourceId) && $sourceId !~ /^\s*$/) {
      $self->setExtDbRlsSourceId($extDbRls, $sourceId, $protocolAppNode);     
    }
    
    my $uri = $protocolAppNodes[$i]->findvalue('./uri');
    if (defined($uri) && $uri !~ /^\s*$/) {
      $protocolAppNode->setUri($uri);
    }
    
    my $taxon = $protocolAppNodes[$i]->findvalue('./taxon');
    if (defined($taxon) && $taxon !~ /^\s*$/) {   
      my $taxonName = GUS::Model::SRes::TaxonName->new({name => $taxon});
      if ($taxonName->retrieveFromDB()) {
	my $taxonId = $taxonName->getTaxonId();
	$protocolAppNode->setTaxonId($taxonId);
      }
      else {
	$self->userError("The database does not contain an entry for Taxon $taxon");
      }
    }
    my $studyLink = GUS::Model::Study::StudyLink->new({study_id => $studyId});
    $studyLink->setParent($protocolAppNode);
    
    my @factorValues = $protocolAppNodes[$i]->findnodes('./factor_value');
    for (my $j=0; $j<@factorValues; $j++) {
      my $studyFactorValue = GUS::Model::Study::StudyFactorValue->new();
      my $fvName = $factorValues[$j]->findvalue('./name');
      my $studyFactor = GUS::Model::Study::StudyFactor->new({study_id => $studyId, name => $fvName});
      if (!$studyFactor->retrieveFromDB()) {
	$self->userError("There is no study factor named $fvName for study $studyId in the database");
      }
      $studyFactorValue->setParent($studyFactor);
      my $fvValue = $factorValues[$j]->findvalue('./value');
      if (defined($fvValue) && $fvValue !~ /^\s*$/) {    
	$studyFactorValue->setValue($fvValue);
      }
      my $fvTable = $factorValues[$j]->findvalue('./table');
      my $fvRowId = $factorValues[$j]->findvalue('./row_id');
      if (defined($fvTable) && $fvTable !~ /^\s*$/ && defined($fvRowId) && $fvRowId !~ /^\s*$/ ) { 
	my $tableId = $self->getTableId($fvTable);
	$studyFactorValue->setTableId($tableId);
	$studyFactorValue->setRowId($fvRowId);
      }
      $studyFactorValue->setParent($protocolAppNode);
    }
    
    my @characteristics = $protocolAppNodes[$i]->findnodes('./node_characteristic');
    for (my $j=0; $j<@characteristics; $j++) {
      my $characteristic = GUS::Model::Study::Characteristic->new();
      $characteristic->setParent($protocolAppNode);
      my $table = $characteristics[$j]->findvalue('./table');
      if (defined($table) && $table !~ /^\s*$/) {
	my $tableId = $self->getTableId($table);
	$characteristic->setTableId($tableId);
      }
      my $value = $characteristics[$j]->findvalue('./value');
      if (defined($value) && $value !~ /^\s*$/) {
	$characteristic->setValue($value);
      }	
      my $ontologyTermNode = $characteristics[$j]->findvalue('./ontology_term');
      if (defined($ontologyTermNode) && $ontologyTermNode !~ /^\s*$/) {    
	my $extDbRls = $characteristics[$j]->findvalue('./external_database_release');
	my $extDbRlsId = $self->getExtDbRlsId($extDbRls);
	
	if (!$extDbRlsId || !defined($extDbRlsId)) {
	  $self->userError("Must provide a valid external database release for Characteristic $ontologyTermNode");
	}
	my $ontologyTerm = $self->getOntologyTerm($ontologyTermNode, $extDbRlsId);
	$characteristic->setParent($ontologyTerm);
      }
    }
    $protocolAppNode->submit();
    $protocolAppNodeIds->{$id} = $protocolAppNode->getId();
	$count = scalar(keys(%$protocolAppNodeIds))%50;
	$self->undefPointerCache() unless $count;
  }
  return ($protocolAppNodeIds);
}

sub handleExistingProtocolAppNode {
  return undef;
}
sub setExtDbSpec () {
my ($self,$node) = @_;
 my $extDbRlsId =  $self->getExtDbRlsId('OBI|http://purl.obolibrary.org/obo/obi/2012-07-01/obi.owl');
      if (!$extDbRlsId || !defined($extDbRlsId)) {
	$self->userError("Database is missing an entry for http://purl.obolibrary.org/obo/obi/2012-07-01/obi.owl");
	}
	return $extDbRlsId;

}
	sub addFactorValues {
  my ($self, $doc, $studyId, $protAppNodeIds) = @_;
  $self->logData("Adding Factor Values");
  
  my @protocolAppNodes = $doc->findnodes('/mage-tab/sdrf/protocol_app_node');
  for (my $i=0; $i<$protocolAppNodes[$i]; $i++) {
    my $protocolAppNodeId = $protocolAppNodes[$i]->getAttribute('db_id');
    if (!defined($protocolAppNodeId) || $protocolAppNodeId =~ /^\s*$/) {
      next;
    }
    my $id = $protocolAppNodes[$i]->getAttribute('id');
    $protAppNodeIds->{$id} = $protocolAppNodeId;
    my @factorValues = $protocolAppNodes[$i]->findnodes('./factor_value');
    for (my $j=0; $j<@factorValues; $j++) {
      my $addition = $factorValues[$i]->getAttribute('addition');
      if (!defined($addition) || $addition ne 'true') {
	next;
      }
      my $studyFactorValue = GUS::Model::Study::StudyFactorValue->new({protocol_app_node_id => $protocolAppNodeId});
      my $fvName = $factorValues[$j]->findvalue('./name');
      my $studyFactor = GUS::Model::Study::StudyLink->new({study_id => $studyId, name => $fvName});
      if (!$studyFactor->retrieveFromDB()) {
	$self->userError("There is no study factor named $fvName for study $studyId in the database");
      }
      $studyFactorValue->setParent($studyFactor);
      my $fvValue = $factorValues[$j]->findvalue('./value');
      if (defined($fvValue) && $fvValue !~ /^\s*$/) {    
	$studyFactorValue->setValue($fvValue);
      }
      my $fvTable = $factorValues[$j]->findvalue('./table');
      my $fvRowId = $factorValues[$j]->findvalue('./row_id');
      if (defined($fvTable) && $fvTable !~ /^\s*$/ && defined($fvRowId) && $fvRowId !~ /^\s*$/ ) { 
	my $tableId = $self->getTableId($fvTable);
	$studyFactorValue->setTableId($tableId);
	$studyFactorValue->setRowId($fvRowId);
      }
      $studyFactorValue->submit();
      $self->undefPointerCache();
    }
  }
    return ($protAppNodeIds);
}

sub addProtocolApps {
  my ($self, $doc, $protAppNodeIds) = @_;
  
  $self->logData("Adding Protocol Applications");
  my @protocolApps = $doc->findnodes('/mage-tab/sdrf/protocol_app');
  for (my $i=0; $i<@protocolApps; $i++) {
    my $addition = $protocolApps[$i]->getAttribute('addition');
    if (!defined($addition) || $addition ne 'true') {
      next;
    }
    my $protocol = $protocolApps[$i]->findvalue('./protocol');
    my @seriesSteps = split(/\|\|\|/, $protocol);
    my $protocolObj = GUS::Model::Study::Protocol->new({name => $protocol});
    if (!$protocolObj->retrieveFromDB()) {
      $self->userError("There is no protocol in the database named '$protocol'");
    }
    my $protocolApp = GUS::Model::Study::ProtocolApp->new();
    $protocolApp->setParent($protocolObj);
    my $protocolAppDate = $protocolApps[$i]->findvalue('./protocol_app_date');
    if (defined($protocolAppDate) && $protocolAppDate !~ /^\s*$/) {
      $protocolApp->setProtocolAppDate($protocolAppDate);
    }
    
    my @contacts = $protocolApps[$i]->findnodes('./contact');
    for (my $j=0; $j<@contacts; $j++) {
      my $contactName = $contacts[$j]->findvalue('./name');
      if (defined($contactName) && $contactName !~ /^\s*$/) {
	my $contact = GUS::Model::SRes::Contact->new({name => $contactName});
	if (!$contact->retrieveFromDB()) {
	  $self->userError("There is no contact in the databased named $contactName");
	}
	my $protocolAppContact = GUS::Model::Study::ProtocolAppContact->new();
	$protocolAppContact->setParent($contact);
	$protocolAppContact->setParent($protocolApp);
	
	my $step = $contacts[$j]->getAttribute('step');
	if (defined($step) && $step !~ /^\s*$/) {
	  $protocolAppContact->setOrderNum($step);
	}
	my $role = $contacts[$j]->findvalue('./role'); 
	if (defined($role) && $role !~ /^\s*$/) {
	  my $extDbRls = $contacts[$j]->findvalue('./external_database_release');
	  my $extDbRlsId = $self->getExtDbRlsId($extDbRls);
	  if (!$extDbRlsId || !defined($extDbRlsId)) {
	    $self->userError("Must provide a valid external database release for Performer $contactName Role's $role");
	  }    
	  my $contactRole = $self->getOntologyTerm($role, $extDbRlsId);
	  $protocolAppContact->setParent($contactRole);
	}
      }
    }
    
    my @protocolAppParams = $protocolApps[$i]->findnodes('./app_param');
    for (my $j=0; $j<@protocolAppParams; $j++) {
      my $step = $protocolAppParams[$j]->getAttribute('step');
      my $name = $protocolAppParams[$j]->findvalue('./name');
      my $value = $protocolAppParams[$j]->findvalue('./value');
      my $table = $protocolAppParams[$j]->findvalue('./table');
      my $rowId = $protocolAppParams[$j]->findvalue('./row_id');
      my $protocolAppParam = GUS::Model::Study::ProtocolAppParam->new();
      $protocolAppParam->setParent($protocolApp);
      my $stepProtocol = GUS::Model::Study::Protocol->new({name => $seriesSteps[$step-1]});
      if (!$stepProtocol->retrieveFromDB()) {
	$self->userError("There is no protocol named '$seriesSteps[$step-1]' in teh database");
      }
      my $protocolId = $stepProtocol->getId();
      my $protocolParam = GUS::Model::Study::ProtocolParam->new({name => $name, protocol_id => $protocolId});
      $protocolParam->retrieveFromDB();
      $protocolAppParam->setParent($protocolParam);
      if ($value && defined($value)) {
	$protocolAppParam->setValue($value);
      }
      if (defined($table) && $table !~ /^\s*$/ && defined($rowId) && $rowId !~ /^\s*$/ ) { 
	my $tableId = $self->getTableId($table);
	$protocolAppParam->setTableId($tableId);
	$protocolAppParam->setRowId($rowId);
      }
    } 
    
    my @inputs = $protocolApps[$i]->findnodes('./input');
    for (my $j=0; $j<@inputs; $j++) {
      my $input = $inputs[$j]->findvalue('.');
      if (defined($input) && $input !~ /^\s*$/) { 
	my $inputObj = GUS::Model::Study::Input->new();
	$inputObj->setParent($protocolApp);
	$inputObj->setProtocolAppNodeId($protAppNodeIds->{$input});
      }
    }
    
    my @outputs = $protocolApps[$i]->findnodes('./output');
    for (my $j=0; $j<@outputs; $j++) {
      my $output = $outputs[$j]->findvalue('.');
      if (defined($output) && $output !~ /^\s*$/) { 
	my $outputObj = GUS::Model::Study::Output->new();
	$outputObj->setParent($protocolApp);
	$outputObj->setProtocolAppNodeId($protAppNodeIds->{$output});
      }
    }
    
    $protocolApp->submit();
    $self->undefPointerCache();
  }
}

sub getTableId {
  my ($self, $dbTable) = @_;
  my ($db, $table) = split(/\:\:/, $dbTable);
  
  my $dbInfo = GUS::Model::Core::DatabaseInfo->new({name => $db});
  if (!$dbInfo->retrieveFromDB()) {
    $self->userError("There is no database schema named $db");
  }
  my $dbId = $dbInfo->getId();
  
  my $tableInfo = GUS::Model::Core::TableInfo->new({database_id => $dbId, name => $table});
  if (!$tableInfo->retrieveFromDB()) {
    $self->userError("There is no table named $table in database schema $db")
  }
  my$tableId = $tableInfo->getId();
  
  return($tableId);
}

sub undoTables {
  my ($self) = @_;
  # SRes.Contact won't be deleted
  
  return ('Study.StudyContact', 'Study.ProtocolAppContact', 'Study.StudyBibRef', 'Study.StudyDesign', 'Study.StudyFactorValue', 'Study.StudyFactor', 'Study.StudyLink', 'Study.Characteristic', 'Study.Input', 'Study.Output', 'Study.ProtocolAppNode', 'Study.ProtocolAppParam', 'Study.ProtocolApp', 'Study.ProtocolParam', 'Study.ProtocolSeriesLink', 'Study.Protocol', 'SRes.BibliographicReference');
}

1;

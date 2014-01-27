##
## LoadStudyXml Plugin
## $Id: LoadstudyXml.pm manduchi $
##


package GUS::Community::Plugin::LoadStudyXml;
@ISA = qw(GUS::PluginMgr::Plugin);

use strict;
use CBIL::Util::Disp;
use GUS::PluginMgr::Plugin;
use LWP::Simple;
use XML::LibXML;

use GUS::Model::Study::Study;
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
	      descr => 'The full path of the xml file.',
	      constraintFunc=> undef,
	      reqd  => 1,
	      isList => 0,
	      mustExist => 1,
	      format => ''
	     }),
     booleanArg({name => 'private',
		 descr => 'option to indicate that that the study to be loaded should be kept private',
		 reqd => 0,
		 default => 0
            })
    ];
  return $argumentDeclaration;
}

# ----------------------------------------------------------------------
# Documentation
# ----------------------------------------------------------------------

sub getDocumentation {
  my $purposeBrief = 'Loads into the Study schema.';

  my $purpose = 'This plugin reads an xml file, which can be obtained from appropriately parsing a MAGE-TAB file, and populates the Study schema table for the corresponding study.';

  my $tablesAffected = [['Study::Study', 'Loads a row representing this study'], ['Study::StudyDesign', 'Loads all applicable study designs for this study'], ['Study::StudyFactors', 'Loads all applicable study factors for this study'], ['SRes::Contact', 'Enters all missing contacts'], ['Study::StudyContact', 'Loads links between this study and all relevant contacts'], ['SRes::BibliographicReference', 'Enters all missing bibliographic references'], ['Study::StudyBibRef', 'Loads links between this study and all relevant bibliographic references'], ['Study::Protocol', 'Enters all missing protocols'], ['Study::ProtocolParam', 'Enters all missing protocol parameters'], ['Study::ProtocolSeriesLinks', 'Enters all missing protocol series links'], ['Study::ProtocolApp', 'Enters all missing protocol applications'], ['Study::ProtocolAppParam', 'Enters all missing protocol application parameters'], ['Study::ProtocolAppContact', 'Loads links between all relevant protocols and contacts'], ['Study::ProtocolAppNode', 'Enters all missing protocol application nodes'], ['Study::Characteristic', 'Enters all missing protocol app. node characteristics'], ['Study::StudyFactorValues', 'Loads links between study factors and protocol application nodes'], ['Study::StudyLink', 'Loads links between this study and all relevant protocol application nodes'], ['Study::Input', 'Loads links between protocol applications and their inputs'], ['Study::Output', 'Loads links between protocol applications and their outputs']];

  my $tablesDependedOn = [['SRes::OntologyTerm', 'All ontology terms pointed to by this study'], ['SRes::Taxon', 'All taxa pointed to by this study'], ['SRes::ExternalDatabaseRelease', 'All external database releases referred to by this study'], ['Core::DatabaseInfo', 'All database schemas referred to'], ['Core::TableInfo', 'All tables referred to']]; 

  my $howToRestart = '';

  my $failureCases = '';

  my $notes = <<NOTES;

=head2 F<xmlFile>

=head1 AUTHOR

Written by Elisabetta Manduchi.

=head1 COPYRIGHT

Copyright Elisabetta Manduchi, Trustees of University of Pennsylvania 2012. 
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

  my $studyObj = $self->getStudy($doc);

  $self->setStudyDesigns($doc, $studyObj);

  my $studyFactorObjs = $self->getStudyFactors($doc, $studyObj);

  my $contactObjs = $self->getContacts($doc, $studyObj);

  my @protocolSeriesNames;
  my ($protocolIds, $protocolSeriesChildren) = $self->submitProtocols($doc, $contactObjs, \@protocolSeriesNames);

  for (my $i=0; $i<@protocolSeriesNames; $i++) {
    $protocolSeriesChildren = $self->submitProtocolSeries($protocolSeriesNames[$i], $protocolIds, $protocolSeriesChildren);
  }
  $studyObj->submit();
  my $studyId = $studyObj->getId();

  my $protAppNodeIds = $self->submitProtocolAppNodes($doc, $studyId, $studyFactorObjs);
  $self->submitProtocolApps($doc, $contactObjs, $protocolIds, $protAppNodeIds, $protocolSeriesChildren);
}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------

sub getStudy {
  my ($self, $doc) = @_;

  my ($study) = $doc->findnodes('/mage-tab/idf/study');
  my $name = $study->findvalue('./name');
  my $studyObj= GUS::Model::Study::Study->new({name => $name});
  if ($studyObj->retrieveFromDB()) {
    $self->userError("A study named '$name' already exists in the database.");
  }
  
  if ($self->getArg('private')) {
    $studyObj->setOtherRead(0);
  }

  my $description = $study->findvalue('./description');
  $studyObj->setDescription($description);

  my $extDbRls = $study->findvalue('./external_database_release');
  my $sourceId = $study->findvalue('./source_id');
  if (defined($extDbRls) && $extDbRls !~ /^\s*$/ && defined($sourceId) && $sourceId !~ /^\s*$/) {
    $self->setExtDbRlsSourceId($extDbRls, $sourceId, $studyObj);     
  }
  
  my $goal = $study->findvalue('./goal');
  if (defined($goal) && $goal !~ /^\s*$/) {
    $studyObj->setGoal($goal);
  }

  my $approaches = $study->findvalue('./approaches');
  if (defined($approaches) && $approaches !~ /^\s*$/) {
    $studyObj->setApproaches($approaches);
  }

  my $results = $study->findvalue('./results');
  if (defined($results) && $results !~ /^\s*$/) {
    $studyObj->setResults($results);
  }

  my $conclusions = $study->findvalue('./conclusions');
  if (defined($conclusions) && $conclusions !~ /^\s*$/) {
    $studyObj->setConclusions($conclusions);
  }

  my @pubmedIds = $study->findnodes('./pubmed_id');
  for (my $i=0; $i<@pubmedIds; $i++) {
    my $pubmedId = $pubmedIds[$i]->findvalue('.');
    if (defined($pubmedId) && $pubmedId !~ /^\s*$/) {
      my $bibRef = $self->getBibRef($pubmedId);
      my $studyBibRef = GUS::Model::Study::StudyBibRef->new();
      $studyBibRef->setParent($studyObj);
      $studyBibRef->setParent($bibRef);
    }
  }
  
  return($studyObj);
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

  my $journal = $pubmedDoc->findvalue('/PubmedArticleSet/PubmedArticle/MedlineCitation/Article/Journal/Title');
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

sub setStudyDesigns {
  my ($self, $doc, $studyObj) = @_;
  
  my @studyDesigns = $doc->findnodes('/mage-tab/idf/study_design');
  for (my $i=0; $i<@studyDesigns; $i++) {
    my $type = $studyDesigns[$i]->findvalue('./type');
    my $extDbRls = $studyDesigns[$i]->findvalue('./type_ext_db_rls');
    my $extDbRlsId = $self->getExtDbRlsId($extDbRls);

    if (!$extDbRlsId || !defined($extDbRlsId)) {
      $self->userError("Must provide a valid external database release for Study Design Type $type");
    }
    my $studyDesignType = $self->getOntologyTerm($type, $extDbRlsId);
    
    my $studyDesign = GUS::Model::Study::StudyDesign->new();
    $studyDesign->setParent($studyObj);
    $studyDesign->setParent($studyDesignType);
  }
  return;
}

sub getStudyFactors {
  my ($self, $doc, $studyObj) = @_;
  my $studyFactorObjs;

  my @studyFactors = $doc->findnodes('/mage-tab/idf/study_factor');
  for (my $i=0; $i<@studyFactors; $i++) {
    my $type = $studyFactors[$i]->findvalue('./type');
    my $extDbRls = $studyFactors[$i]->findvalue('./type_ext_db_rls');
    my $extDbRlsId = $self->getExtDbRlsId($extDbRls);;
    if (!$extDbRlsId || !defined($extDbRlsId)) {
      $self->userError("Must provide a valid external database release for Study Factor Type $type");
    }

    my $studyFactorType = $self->getOntologyTerm($type, $extDbRlsId);
    
    my $name = $studyFactors[$i]->findvalue('./name');
    my $description = $studyFactors[$i]->findvalue('./description');
    
    my $studyFactor = GUS::Model::Study::StudyFactor->new({name => $name});
    if (defined($description) && $description !~ /^\s*$/) {
      $studyFactor->setDescription($description);
    }
    
    $studyFactor->setParent($studyObj);
    $studyFactor->setParent($studyFactorType);
    $studyFactorObjs->{$name} = $studyFactor;
  }
  return($studyFactorObjs);
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

sub getContacts {
  my ($self, $doc, $studyObj) = @_;
  my $contactObjs;
  
  my @contacts = $doc->findnodes('/mage-tab/idf/contact');
  for (my $i=0; $i<@contacts; $i++) {  
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

    $contact->submit();

    my @roles = split(/;/, $contacts[$i]->findvalue('./roles'));
    my @extDbRls = split(/;/, $contacts[$i]->findvalue('./roles_ext_db_rls'));
    for (my $j=0; $j<@roles; $j++) {
      my $extDbRlsId = $self->getExtDbRlsId($extDbRls[$j]);
      if (!$extDbRlsId || !defined($extDbRlsId)) {
	$self->userError("Must provide a valid external database release for Contact Role $roles[$j]");
      }    
      my $contactRole = $self->getOntologyTerm($roles[$j], $extDbRlsId);
    
      my $studyContact = GUS::Model::Study::StudyContact->new();
      $studyContact->setParent($studyObj);
      $studyContact->setParent($contact);
      $studyContact->setParent($contactRole);
    }
    
    $contactObjs->{$name} = $contact;
  }
  return($contactObjs);
}

sub submitProtocols {
  my ($self, $doc, $contactObjs, $protocolSeriesNames) = @_;
  my ($protocolIds, $protocolSeriesChildren);
  
  my @protocols = $doc->findnodes('/mage-tab/idf/protocol');
  for (my $i=0; $i<@protocols; $i++) {
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
      my $protocolId = $protocol->getId();
      $protocolIds->{$name} = $protocolId;
      push(@{$protocolSeriesChildren->{$name}}, $protocolId);
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
      $protocol->setParent($contactObjs->{$contactName});
    }

    my $pubmedId = $protocols[$i]->findvalue('./pubmed_id');
    if (defined($pubmedId) && $pubmedId !~ /^\s*$/) {
      my $bibRef = $self->getBibRef($pubmedId);
      $protocol->setParent($bibRef);
    }
    
    my @protocolParams = $protocols[$i]->findnodes('./param');
    for (my $j=0; $i<@protocolParams; $j++) {
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
    my $protocolId = $protocol->getId();
    $protocolIds->{$name} = $protocolId;
    push(@{$protocolSeriesChildren->{$name}}, $protocolId);
  }
  return($protocolIds, $protocolSeriesChildren);
}

sub submitProtocolSeries {
  my ($self, $protocolSeriesName, $protocolIds, $protocolSeriesChildren) = @_;
  
  my $protocolSeries = GUS::Model::Study::Protocol->new({name => $protocolSeriesName});
  my $exists = 0;
  if ($protocolSeries->retrieveFromDB()) {
    $self->logData("A protocol series named $protocolSeriesName already exists in the database. This will not be altered.");
    $exists = 1;
  }
  $protocolSeries->submit();
  my $protocolSeriesId = $protocolSeries->getId();
  $protocolIds->{$protocolSeriesName} = $protocolSeriesId;
  my @children = split(/\|\|\|/, $protocolSeriesName);
  for (my $i=0; $i<@children; $i++) {
    my $orderNum = $i+1;
    if (!$exists) {
      my $protocolSeriesLink = GUS::Model::Study::ProtocolSeriesLink->new({order_num => $orderNum});
      $protocolSeriesLink->setProtocolSeriesId($protocolSeriesId);
      $protocolSeriesLink->setProtocolId($protocolIds->{$children[$i]});
      $protocolSeriesLink->submit();
    }
    push(@{$protocolSeriesChildren->{$protocolSeriesName}}, $protocolIds->{$children[$i]});
  }
  return($protocolSeriesChildren);
}

sub submitProtocolAppNodes {
  my ($self, $doc, $studyId, $studyFactorObjs) = @_;
  my $protocolAppNodeIds;

  $self->logData("Submitting the Protocol Application Nodes");
  my @protocolAppNodes = $doc->findnodes('/mage-tab/sdrf/protocol_app_node');
  for (my $i=0; $i<$protocolAppNodes[$i]; $i++) {
    my $id = $protocolAppNodes[$i]->getAttribute('id');
 
    my $name = $protocolAppNodes[$i]->findvalue('./name');
    my $protocolAppNode = GUS::Model::Study::ProtocolAppNode->new({name => $name});
    my $typeNode = $protocolAppNodes[$i]->findvalue('./type');
    if (defined($typeNode) && $typeNode !~ /^\s*$/) {
      my $extDbRlsId =  $self->getExtDbRlsId('OBI|http://purl.obolibrary.org/obo/obi/2012-07-01/obi.owl');
      if (!$extDbRlsId || !defined($extDbRlsId)) {
	$self->userError("Database is missing an entry for http://purl.obolibrary.org/obo/obi/2012-07-01/obi.owl");
      }
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
      $studyFactorValue->setParent($studyFactorObjs->{$fvName});
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

    my @characteristics = $protocolAppNodes[$i]->findnodes('./characteristic');
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
  }
  return ($protocolAppNodeIds);
}

sub submitProtocolApps {
  my ($self, $doc, $contactObjs, $protocolIds, $protAppNodeIds, $protocolSeriesChildren) = @_;

  $self->logData("Submitting the Protocol Applications");
  my @protocolApps = $doc->findnodes('/mage-tab/sdrf/protocol_app');
  for (my $i=0; $i<@protocolApps; $i++) {
    my $protocol = $protocolApps[$i]->findvalue('./protocol');
    my $protocolApp = GUS::Model::Study::ProtocolApp->new({protocol_id => $protocolIds->{$protocol}});
    my $protocolAppDate = $protocolApps[$i]->findvalue('./protocol_app_date');
    if (defined($protocolAppDate) && $protocolAppDate !~ /^\s*$/) {
      $protocolApp->setProtocolAppDate($protocolAppDate);
    }
    
    my @contacts = $protocolApps[$i]->findnodes('./contact');
    for (my $j=0; $j<@contacts; $j++) {
      my $contactName = $contacts[$j]->findvalue('./name');
      if (defined($contactName) && $contactName !~ /^\s*$/) {
	my $protocolAppContact = GUS::Model::Study::ProtocolAppContact->new();
	$protocolAppContact->setParent($contactObjs->{$contactName});
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
      my $protocolParam = GUS::Model::Study::ProtocolParam->new({name => $name, protocol_id => $protocolSeriesChildren->{$protocol}->[$step-1]});
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

  return ('Study.StudyContact', 'Study.ProtocolAppContact', 'Study.StudyBibRef', 'Study.StudyDesign', 'Study.StudyFactorValue', 'Study.StudyFactor', 'Study.StudyLink', 'Study.Characteristic', 'Study.Input', 'Study.Output', 'Study.ProtocolAppNode', 'Study.ProtocolAppParam', 'Study.ProtocolApp', 'Study.ProtocolParam', 'Study.ProtocolSeriesLink', 'Study.Protocol', 'SRes.BibliographicReference', 'Study.Study');
}

1;

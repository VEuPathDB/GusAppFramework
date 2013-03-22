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
use GUS::Model::Study::Funding;
use GUS::Model::Study::StudyFunding;
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
	      format => 'See the NOTES for the format of this file'
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

  my $tablesAffected = [['Study::Study', 'Loads a row representing this study'], ['Study::StudyDesign', 'Loads all applicable study designs for this study'], ['Study::StudyFactors', 'Loads all applicable study factors for this study'], ['SRes::Contact', 'Enters all missing contacts'], ['Study::StudyContact', 'Loads links between this study and all relevant contacts'], ['SRes::BibliographicReference', 'Enters all missing bibliographic references'], ['Study::StudyBibRef', 'Loads links between this study and all relevant bibliographic references'], ['Study::Funding', 'Loads all missing fundings'], ['Study::StudyFunding', 'Loads links between this study and all relevant fundings'], ['Study::Protocol', 'Enters all missing protocols'], ['Study::ProtocolParam', 'Enters all missing protocol parameters'], ['Study::ProtocolSeriesLinks', 'Enters all missing protocol series links'], ['Study::ProtocolApp', 'Enters all missing protocol applications'], ['Study::ProtocolAppParam', 'Enters all missing protocol application parameters'], ['Study::ProtocolAppContact', 'Loads links between all relevant protocols and contacts'], ['Study::ProtocolAppNode', 'Enters all missing protocol application nodes'], ['Study::Characteristic', 'Enters all missing protocol app. node characteristics'], ['Study::StudyFactorValues', 'Loads links between study factors and protocol application nodes'], ['Study::StudyLink', 'Loads links between this study and all relevant protocol application nodes'], ['Study::Input', 'Loads links between protocol applications and their inputs'], ['Study::Output', 'Loads links between protocol applications and their outputs']];

  my $tablesDependedOn = [['SRes::OntologyTerm', 'All ontology terms pointed to by this study'], ['SRes::Taxon', 'All taxa pointed to by this study'], ['SRes::ExternalDatabaseRelease', 'All external database releases referred to by this study'], ['Core::DatabaseInfo', 'All database schemas referred to'], ['Core::TableInfo', 'All tables referred to']]; 

  my $howToRestart = '';

  my $failureCases = '';

  my $notes = <<NOTES;

=head2 F<xmlFile>

=head1 AUTHOR

Written by Elisabetta Manduchi.

=head1 COPYRIGHT

Copyright Elisabetta Manduchi, Trustees of University of Pennsylvania 20012. 
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
		     cvsRevision => '$Revision: 11459 $',
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

  my $study = $self->getStudy($doc);

  $self->setStudyDesigns($doc, $study);

  my $studyFactors = $self->getStudyFactors($doc, $study);

  my $contacts = $self->getContacts($doc, $study);

  my @protocolSeriesNames;
  my $protocolSeriesChildren;
  my $protocolIds = $self->submitProtocols($doc, \@protocolSeriesNames, $protocolSeriesChildren);

  for (my $i=0; $i<@protocolSeriesNames; $i++) {
    $self->submitProtocolSeries($protocolSeriesNames[$i], $protocolIds, $protocolSeriesChildren);
  }
  
  $study->submit();
  my $studyId = $study->getId();
  my $studyFactorIds;
  foreach my $key (keys %{$studyFactors}) {
    $studyFactorIds->{$key} = $studyFactors->{$key}->getId();
  }

  my $protAppNodeIds = $self->submitProtocolAppNodes($doc, $studyId, $studyFactorIds);
  $self->submitProtocolApps($doc, $protocolIds, $protAppNodeIds, $contacts, $protocolSeriesChildren);
}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------

sub getStudy {
  my ($self, $doc) = @_;

  my ($studyNode) = $doc->findnodes('/mage-tab/idf/study');
  my $name = $studyNode->findvalue('./name');
  my $study= GUS::Model::Study::Study->new({name => $name});
  if ($study->retrieveFromDB()) {
    $self->userError("A study named '$name' already exists in the database.");
  }
  
  if ($self->getArg('private')) {
    $study->setOtherRead(0);
  }

  my $description = $studyNode->findvalue('./description');
  $study->setDescription($description);

  my $extDbRls = $studyNode->findvalue('./external_database_release');
  my $sourceId = $studyNode->findvalue('./source_id');
  if (defined($extDbRls) && $extDbRls !~ /^\s*$/ && defined($sourceId) && $sourceId !~ /^\s*$/) {
    $self->setExtDbRlsSourceId($extDbRls, $sourceId, $study);     
  }
  
  my $goal = $studyNode->findvalue('./goal');
  if (defined($goal) && $goal !~ /^\s*$/) {
    $study->setGoal($goal);
  }

  my $approaches = $studyNode->findvalue('./approaches');
  if (defined($approaches) && $approaches !~ /^\s*$/) {
    $study->setApproaches($approaches);
  }

  my $results = $studyNode->findvalue('./results');
  if (defined($results) && $results !~ /^\s*$/) {
    $study->setResults($results);
  }

  my $conclusions = $studyNode->findvalue('./conclusions');
  if (defined($conclusions) && $conclusions !~ /^\s*$/) {
    $study->setConclusions($conclusions);
  }

  my $pubmedIdsString = $studyNode->findvalue('./pubmed_ids');
  if (defined($pubmedIdsString) && $pubmedIdsString !~ /^\s*$/) {
    my @pubmedIds = split(/;/, $pubmedIdsString);
    for (my $i=0; $i<@pubmedIds; $i++) {
      my $bibRef = $self->getBibRef($pubmedIds[$i]);
      my $studyBibRef = GUS::Model::Study::StudyBibRef->new();
      $studyBibRef->setParent($study);
      $studyBibRef->setParent($bibRef);
    }
  }

  return($study);
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
  my ($self, $doc, $study) = @_;
  
  foreach my $studyDesignNode ($doc->findnodes('/mage-tab/idf/study_design')) {
    
    my $type = $studyDesignNode->findvalue('./type');
    my $extDbRls = $studyDesignNode->findvalue('./type_ext_db_rls');
    my $extDbRlsId = $self->getExtDbRlsId($extDbRls);

    if (!$extDbRlsId || !defined($extDbRlsId)) {
      $self->userError("Must provide a valid external database release for Study Design Type $type");
    }
    my $studyDesignType = $self->getOntologyTerm($type, $extDbRlsId);
    
    my $studyDesign = GUS::Model::Study::StudyDesign->new();
    $studyDesign->setParent($study);
    $studyDesign->setParent($studyDesignType);
  }
  return;
}

sub getStudyFactors {
  my ($self, $doc, $study) = @_;
  my $studyFactors;
  
  foreach my $studyFactorNode ($doc->findnodes('/mage-tab/idf/study_factor')) {
    my $type = $studyFactorNode->findvalue('./type');
    my $extDbRls = $studyFactorNode->findvalue('./type_ext_db_rls');
    my $extDbRlsId = $self->getExtDbRlsId($extDbRls);;
    if (!$extDbRlsId || !defined($extDbRlsId)) {
      $self->userError("Must provide a valid external database release for Study Factor Type $type");
    }

    my $studyFactorType = $self->getOntologyTerm($type, $extDbRlsId);
    
    my $name = $studyFactorNode->findvalue('./name');
    my $description = $studyFactorNode->findvalue('./description');
    
    my $studyFactor = GUS::Model::Study::StudyFactor->new({name => $name});
    if (defined($description) && $description !~ /^\s*$/) {
      $studyFactor->setDescription($description);
    }
    
    $studyFactor->setParent($study);
    $studyFactor->setParent($studyFactorType);
    $studyFactors->{$name} = $studyFactor;
  }
  return($studyFactors);
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
  my ($self, $doc, $study) = @_;
  my $contacts;
  
  foreach my $contactNode ($doc->findnodes('/mage-tab/idf/contact')) {  
    my $name = $contactNode->findvalue('./name');
    my $contact = GUS::Model::SRes::Contact->new({name => $name});
    my $affiliationNode = $contactNode->findvalue('./affiliation');
    if ($name ne $affiliationNode) {
      my $affiliation = GUS::Model::SRes::Contact->new({name => $affiliationNode});
      $affiliation->retrieveFromDB();
      $contact->setParent($affiliation);
    }
    $contact->retrieveFromDB();
    
    my $firstName = $contactNode->findvalue('./first_name');
    if (defined($firstName) && $firstName !~ /^\s*$/) {
      $contact->setFirst($firstName);
    }
    
    my $lastName = $contactNode->findvalue('./last_name');
    if (defined($lastName) && $lastName !~ /^\s*$/) {
      $contact->setLast($lastName);
    }
        
    my $address1 = $contactNode->findvalue('./address1');
    if (defined($address1) && $address1 !~ /^\s*$/) {
      $contact->setAddress1($address1);
    }
    
    my $address2 = $contactNode->findvalue('./address2');
    if (defined($address2) && $address2 !~ /^\s*$/) {
      $contact->setAddress2($address2);
    }
    
    my $city = $contactNode->findvalue('./city');
    if (defined($city) && $city !~ /^\s*$/) {
      $contact->setCity($city);
    }
    
    my $state = $contactNode->findvalue('./state');
    if (defined($state) && $state !~ /^\s*$/) {
      $contact->setState($state);
    }
    
    my $country = $contactNode->findvalue('./country');
    if (defined($country) && $country !~ /^\s*$/) {
      $contact->setCountry($country);
    }
    
    my $zip = $contactNode->findvalue('./zip');
    if (defined($zip) && $zip !~ /^\s*$/) {
      $contact->setZip($zip);
    }
    
    my $email = $contactNode->findvalue('./email');
    if (defined($email) && $email !~ /^\s*$/) {
      $contact->setEmail($email);
    }
    
    my $phone = $contactNode->findvalue('./phone');
    if (defined($phone) && $phone !~ /^\s*$/) {
      $contact->setPhone($phone);
    }
    
    my $fax = $contactNode->findvalue('./fax');
    if (defined($fax) && $fax !~ /^\s*$/) {
      $contact->setFax($fax);
    }

    $contact->submit();

    my @roles = split(/;/, $contactNode->findvalue('./roles'));
    my @extDbRls = split(/;/, $contactNode->findvalue('./roles_ext_db_rls'));
    for (my $i=0; $i<@roles; $i++) {
      my $extDbRlsId = $self->getExtDbRlsId($extDbRls[$i]);
      if (!$extDbRlsId || !defined($extDbRlsId)) {
	$self->userError("Must provide a valid external database release for Contact Role $roles[$i]");
      }    
      my $contactRole = $self->getOntologyTerm($roles[$i], $extDbRlsId);
    
      my $studyContact = GUS::Model::Study::StudyContact->new();
      $studyContact->setParent($study);
      $studyContact->setParent($contact);
      $studyContact->setParent($contactRole);
    }
    
    $contacts->{$name} = $contact;
  }
  return($contacts);
}

sub submitProtocols {
  my ($self, $doc) = @_;
  my ($protocolIds, $protocolSeriesNames, $protocolSeriesChildren);
  
  foreach my $protocolNode ($doc->findnodes('/mage-tab/idf/protocol')) {
    my $childProtocols = $protocolNode->findvalue('./child_protocols');
    if (defined($childProtocols) && $childProtocols !~ /^\s*$/) {
      push(@{$protocolSeriesNames}, $childProtocols);
      next;
    }   
    my $name = $protocolNode->findvalue('./name');
    my $protocol = GUS::Model::Study::Protocol->new({name => $name});
    $protocol->retrieveFromDB();
    
    my $description = $protocolNode->findvalue('./description');
    if (defined($description) && $description !~ /^\s*$/) {
      $protocol->setDescription($description);
    }

    my $type = $protocolNode->findvalue('./type');
    if (defined($type) && $type !~ /^\s*$/) {    
      my $typeExtDbRls = $protocolNode->findvalue('./type_ext_db_rls');
      my $typeExtDbRlsId = $self->getExtDbRlsId($typeExtDbRls);
      
      if (!$typeExtDbRlsId || !defined($typeExtDbRlsId)) {
	$self->userError("Must provide a valid external database release for Protocol Type $type");
      }
      my $protocolType = $self->getOntologyTerm($type, $typeExtDbRlsId);
      $protocol->setParent($protocolType);
    }
    
    my $otherRead = $protocolNode->findvalue('./other_read');
    if (defined($otherRead) && $otherRead !~ /^\s*$/) {
      $protocol->setOtherRead($otherRead);
    }
    
    my $pubmedId = $protocolNode->findvalue('./pubmed_id');
    if (defined($pubmedId) && $pubmedId  !~ /^\s*$/) {  
      my $bibRef = $self->getBibRef($pubmedId);
      $protocol->setParent($bibRef);
    }
    
    my $uri = $protocolNode->findvalue('./uri');
    if (defined($uri) && $uri  !~ /^\s*$/) {
      $protocol->setUri($uri);
    }
    
    my $extDbRls = $protocolNode->findvalue('./external_database_release');
    my $sourceId = $protocolNode->findvalue('./source_id');
    if (defined($extDbRls) && $extDbRls !~ /^\s*$/ && defined($sourceId) && $sourceId !~ /^\s*$/) {
      $self->setExtDbRlsSourceId($extDbRls, $sourceId, $protocol);     
    }
    
    my $contactName = $protocolNode->findvalue('./contact');
    if (defined($contactName) && $contactName !~ /^\s*$/) {
      my $contact = GUS::Model::SRes::Contact->new({name => $contactName});
      if (!$contact->retrieveFromDb()) {
	$self->userError("Contact $contactName for protocol $name is missing in the database");
      }
      $protocol->setParent($contact);
    }
    
    my ($protocolParamsNode) = $protocolNode->findnodes('./protocol_parameters');
    if (defined($protocolParamsNode) && $protocolParamsNode !~ /^\s*$/) {
      foreach my $protocolParamNode ($protocolParamsNode->findnodes('./param')) {
	my $name = $protocolParamNode->findvalue('./name');
	if (defined($name) && $name !~ /^\s*$/) {
	  my $protocolParam = GUS::Model::Study::ProtocolParam->new({name => $name});
	  $protocolParam->setParent($protocol);
	  $protocolParam->retrieveFromDB();
	  
	  my $defaultValue = $protocolParamNode->findvalue('./default_value');
	  if (defined($defaultValue) && $defaultValue  !~ /^\s*$/) {
	    $protocolParam->setDefaultValue($defaultValue);
	  }
	  
	  my $isUserSpecified = $protocolParamNode->findvalue('./is_user_specified');
	  if (defined($isUserSpecified) && $isUserSpecified  !~ /^\s*$/) {
	    $protocolParam->setIsUserSpecified($isUserSpecified);
	  }
	  
	  my $dataTypeTerm = $protocolParamNode->findvalue('./data_type'); 
	  if (defined($dataTypeTerm) && $dataTypeTerm !~ /^\s*$/) { 
	    my $dataTypeExtDbRls = $protocolParamNode->findvalue('./data_type_ext_db_rls'); 
	    my $dataTypeExtDbRlsId = $self->getExtDbRlsId($dataTypeExtDbRls);
	    
	    if (!$dataTypeExtDbRlsId || !defined($dataTypeExtDbRlsId)) {
	      $self->userError("Must provide a valid external database release for Data Type $dataTypeTerm");
	    }
	    my $dataType = $self->getOntologyTerm($dataTypeTerm, $dataTypeExtDbRlsId);
	    my $dataTypeId = $dataType->getId();
	    $protocolParam->setDataTypeId($dataTypeId);
	  } 
	  
	  my $unitTypeTerm = $protocolParamNode->findvalue('./unit_type'); 
	  if (defined($unitTypeTerm) && $unitTypeTerm !~ /^\s*$/) { 
	    my $unitTypeExtDbRls = $protocolParamNode->findvalue('./unit_type_ext_db_rls'); 
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
    }

    $protocol->submit();
    my $protocolId = $protocol->getId();
    $protocolIds->{$name} = $protocolId;
    push(@{$protocolSeriesChildren->{$protocolId}}, $protocolId);
  }

  return($protocolIds);
}

sub submitProtocolSeries {
  my ($self, $protocolSeriesName, $protocolIds, $protocolSeriesChildren) = @_;
  
  my $protocolSeries = GUS::Model::Study::Protocol->new({name => $protocolSeriesName});
  $protocolSeries->submit();
  my $protocolSeriesId = $protocolSeries->getId();
  $protocolIds->{$protocolSeriesName} = $protocolSeriesId;
  my @children = split(/;/, $protocolSeriesName);
  for (my $i=0; $i<@children; $i++) {
    my $orderNum = $i+1;
    my $protocolSeriesLink = GUS::Model::Study::ProtocolSeriesLink->new({order_num => $orderNum});
    $protocolSeriesLink->setProtocolSeriesId($protocolSeriesId);
    $protocolSeriesLink->setProtocolId($protocolIds->{$children[$i]});
    $protocolSeriesLink->submit();
    push(@{$protocolSeriesChildren->{$protocolSeriesId}}, $protocolIds->{$children[$i]});
  }
}


sub submitProtocolAppNodes {
  my ($self, $doc, $studyId, $studyFactorIds) = @_;
  my $protocolAppNodeIds;

  $self->logData("Submitting the Protocol Application Nodes");
  foreach my $protocolAppNodeNode ($doc->findnodes('/mage-tab/sdrf/protocol_app_node')) {
    my $id = $protocolAppNodeNode->getAttribute('id');
 
    my $name = $protocolAppNodeNode->findvalue('./name');
    my $protocolAppNode = GUS::Model::Study::ProtocolAppNode->new({name => $name});
    my $typeNode = $protocolAppNodeNode->findvalue('./type');
    if (defined($typeNode) && $typeNode !~ /^\s*$/) {
      my $extDbRlsId =  $self->getExtDbRlsId('OBI|http://purl.obolibrary.org/obo/obi/2012-07-01/obi.owl');
      if (!$extDbRlsId || !defined($extDbRlsId)) {
	$self->userError("Database is missing an entry for http://purl.obolibrary.org/obo/obi/2012-07-01/obi.owl");
      }
      my $type = $self->getOntologyTerm($typeNode, $extDbRlsId);
      my $typeId = $type->getId();
      $protocolAppNode->setTypeId($typeId);
    }

    my $description = $protocolAppNodeNode->findvalue('./description');
    if (defined($description) && $description !~ /^\s*$/) {
      $protocolAppNode->setDescription($description);
    }
    
    my $extDbRls = $protocolAppNodeNode->findvalue('./ext_db_rls');
    my $sourceId = $protocolAppNodeNode->findvalue('./source_id');
    if (defined($extDbRls) && $extDbRls !~ /^\s*$/ && defined($sourceId) && $sourceId !~ /^\s*$/) {
      $self->setExtDbRlsSourceId($extDbRls, $sourceId, $protocolAppNode);     
    }
 
    my $uri = $protocolAppNodeNode->findvalue('./uri');
    if (defined($uri) && $uri !~ /^\s*$/) {
      $protocolAppNode->setUri($uri);
    }
      
    my $taxon = $protocolAppNodeNode->findvalue('./taxon');
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

    my @factorValues = split(/;/, $protocolAppNodeNode->findvalue('./factor_values'));
    for (my $i=0; $i<@factorValues; $i++) {
      my ($fvName, $fvValue, $fvTable, $fvRowId) = split(/\|/, $factorValues[$i]);
      my $studyFactorValue = GUS::Model::Study::StudyFactorValue->new({study_factor_id => $studyFactorIds->{$fvName}});
      $studyFactorValue->setParent($protocolAppNode);
      if (defined($fvValue) && $fvValue !~ /^\s*$/) {    
	$studyFactorValue->setValue($fvValue);
      }
      if (defined($fvTable) && $fvTable !~ /^\s*$/ && defined($fvRowId) && $fvRowId !~ /^\s*$/ ) { 
	my $tableId = $self->getTableId($fvTable);
	$studyFactorValue->setTableId($tableId);
	$studyFactorValue->setRowId($fvRowId);
      }      
    }
    my ($characteristics) = $protocolAppNodeNode->findnodes('./node_characteristics');
    if (defined($characteristics) && $characteristics !~ /^\s*$/) {
      foreach my $charNode ($characteristics->findnodes('./characteristic')) {
	my $characteristic = GUS::Model::Study::Characteristic->new();
	$characteristic->setParent($protocolAppNode);
	my $table = $charNode->findvalue('./table');
	if (defined($table) && $table !~ /^\s*$/) {
	  my $tableId = $self->getTableId($table);
	  $characteristic->setTableId($tableId);
	}
	
	my $ontologyTermNode = $charNode->findvalue('./ontology_term');
	if (defined($ontologyTermNode) && $ontologyTermNode !~ /^\s*$/) {    
	  my $extDbRls = $charNode->findvalue('./external_database_release');
	  my $extDbRlsId = $self->getExtDbRlsId($extDbRls);
	  
	  if (!$extDbRlsId || !defined($extDbRlsId)) {
	    $self->userError("Must provide a valid external database release for Characteristic $ontologyTermNode");
	  }
	  my $ontologyTerm = $self->getOntologyTerm($ontologyTermNode, $extDbRlsId);
	  $characteristic->setParent($ontologyTerm);
	}
      }
    }
    $protocolAppNode->submit();
    $protocolAppNodeIds->{$id} = $protocolAppNode->getId();
  }
  return ($protocolAppNodeIds);
}

sub submitProtocolApps {
  my ($self, $doc, $protocolIds, $protAppNodeIds, $contacts, $protocolSeriesChildren) = @_;
 
  $self->logData("Submitting the Protocol Applications");
  foreach my $protocolAppNode ($doc->findnodes('/mage-tab/sdrf/protocol_app')) {
    my $protocol = $protocolAppNode->findvalue('./protocol');
    my $protocolApp = GUS::Model::Study::ProtocolApp->new({protocol_id => $protocolIds->{$protocol}});
    my $protocolAppDate = $protocolAppNode->findvalue('./protocol_app_date');
    if (defined($protocolAppDate) && $protocolAppDate !~ /^\s*$/) {
      $protocolApp->setProtocolAppDate($protocolAppDate);
    }
    if ($protocolAppNode->findvalue('./contacts') && defined($protocolAppNode->findvalue('./contacts'))) {
      my @contactInfo = split(/;/, $protocolAppNode->findvalue('./contacts'));
      for (my $i=0; $i<@contactInfo; $i++) {
	my ($contactName, $role, $extDbRls) = split(/\:\:/, $contactInfo[$i]);
	my $extDbRlsId = $self->getExtDbRlsId($extDbRls);
	if (!$extDbRlsId || !defined($extDbRlsId)) {
	  $self->userError("Must provide a valid external database release for Performer $contactName Role's $role");
	}    
	my $contactRole = $self->getOntologyTerm($role, $extDbRlsId);
	
	my $protocolAppContact = GUS::Model::Study::ProtocolAppContact->new({contact_id => $contacts->{$contactName}, order_num => $i+1});
	$protocolAppContact->setParent($protocolApp);
	$protocolAppContact->setParent($contactRole);
      }
    }

    if ($protocolAppNode->findvalue('./protocol_app_params') && defined($protocolAppNode->findvalue('./protocol_app_params'))) {
      my @paramsByChildren = split(/!/, $protocolAppNode->findvalue('./protocol_app_params'));
      for (my $i=0; $i<@paramsByChildren; $i++) {
	my @paramsInfo = split(/;/, $paramsByChildren[$i]);	
	for (my $j=0; $j<@paramsInfo; $j++) {
	  my ($name, $value, $table, $rowId) = split(/\|/, $paramsInfo[$j]);
	  my $protocolAppParam = GUS::Model::Study::ProtocolAppParam->new();
	  $protocolAppParam->setParent($protocolApp);
	  my $protocolParam = GUS::Model::Study::ProtocolParam->new({name => $name, protocol_id => $protocolSeriesChildren->{$protocol}->[$i]});
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
      } 
    }
    if ($protocolAppNode->findvalue('./inputs') && defined($protocolAppNode->findvalue('./inputs'))) {
      my @inputNodes = split(/;/, $protocolAppNode->findvalue('./inputs'));    
      for (my $i=0; $i<@inputNodes; $i++) {
	my $input = GUS::Model::Study::Input->new();
	$input->setParent($protocolApp);
	$input->setProtocolAppNodeId($protAppNodeIds->{$inputNodes[$i]});
      }
    }
    if ($protocolAppNode->findvalue('./outputs') && defined($protocolAppNode->findvalue('./outputs'))) {
      my @outputNodes = split(/;/, $protocolAppNode->findvalue('./outputs'));    
      for (my $i=0; $i<@outputNodes; $i++) {
	my $output = GUS::Model::Study::Output->new();
	$output->setParent($protocolApp);
	$output->setProtocolAppNodeId($protAppNodeIds->{$outputNodes[$i]});
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
  if (!$tableInfo->retrieveFromDb()) {
    $self->userError("There is no table named $table in database schema $db")
  }
  my$tableId = $tableInfo->getId();
  
  return($tableId);
}

sub undoTable {
  my ($self) = @_;

  return ('Study.StudyContact', 'Study.ProtocolAppContact', 'SRes.Contact', 'Study.StudyBibRef', 'SRes.BibliographicReference', 'Study.StudyDesign', 'Study.StudyFactorValue', 'Study.StudyFactor', 'Study.StudyLink', 'Study.Characteristic', 'Study.Input', 'Study.Output', 'Study.ProtocolAppNode', 'Study.ProtocolAppParam', 'Study.ProtocolApp', 'Study.ProtocolParam', 'Study.ProtocolSeriesLink', 'Study.Protocol', 'Study.Study');
}

1;

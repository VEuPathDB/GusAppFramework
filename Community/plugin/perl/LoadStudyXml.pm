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

  my $tablesDependedOn = [['SRes::OntologyTerm', 'All ontology terms pointed to by this study'], ['SRes::Taxon', 'All taxa pointed to by this study'], ['SRes::ExternalDatabaseRelease', 'All external database releases referred to by this study']]; 

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
		     cvsRevision => '$Revision: 11447 $',
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

  my @gusFields = ('modification_date', 'user_read', 'user_write', 'group_read', 'group_write', 'other_read', 'other_write', 'row_user_id', 'row_group_id', 'row_project_id', 'row_alg_invocation_id');
  my $resultDescrip = "";

  my $study = $self->getStudy($doc);

  $self->setStudyDesigns($doc, $study);

  my $studyFactors = $self->getStudyFactors($doc, $study);

  my $contacts = $self->getContacts($doc, $study);

  my @protocolSeriesNames;
  my $protocolIds = $self->submitProtocols($doc, \@protocolSeriesNames);

  for (my $i=0; $i<@protocolSeriesNames; $i++) {
    my $protocolSeriesIds = $self->submitProtocolSeries($protocolSeriesNames[$i], $protocolIds);

  }
  
  $study->submit();

  $self->logData("");

  $self->setResultDescr($resultDescrip);
  $self->logData($resultDescrip);
}

# ----------------------------------------------------------------------
# methods called by run
# ----------------------------------------------------------------------

sub getStudy {
  my ($self, $doc) = @_;

  my ($studyNode) = $doc->findnodes('/idf/study');
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
#      my $bibRefString = $bibRef->toString();
#      $self->log($bibRefString);
      my $studyBibRef = GUS::Model::Study::StudyBibRef->new();
      $studyBibRef->setParent($study);
      $studyBibRef->setParent($bibRef);
    }
  }

#  my $studyString = $study->toString();
#  $self->log($studyString);
  return($study);
}

# AUTHOR: Oleg Khovayko
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
    $self->userError('Missing entry for term=$term and ext_db_rls_id=$extDbRlsId in SRes.OntologyTerm');
  }
  elsif ($ontologyTerm->getIsObsolete()==1) {
    $self->userError('Term $term is obsolete in ext_db_rls_id=$extDbRlsId');
  }
  return($ontologyTerm);
}

sub setStudyDesigns {
  my ($self, $doc, $study) = @_;
  
  foreach my $studyDesignNode ($doc->findnodes('/idf/study_design')) {
    
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
  
  foreach my $studyFactorNode ($doc->findnodes('/idf/study_factor')) {
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
    $self->userError("$extDbRlsId is not in SRes.ExteralDatabaseRelease");
  }
  $object->setExternalDatabaseReleaseId($extDbRlsId); 
  $object->setSourceId($sourceId);   
}

sub getContacts {
  my ($self, $doc, $study) = @_;
  my $contacts;
  
  foreach my $contactNode ($doc->findnodes('/idf/contact')) {
    
    my $name = $contactNode->findvalue('./name');
    my $contact = GUS::Model::SRes::Contact->new({name => $name});
    my $affiliation = $contactNode->findvalue('./affiliation');
    if ($name ne $affiliation) {
      my $affiliation = GUS::Model::SRes::Contact->new({name => $affiliation});
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

#    my $contactString = $contact->toString();
#    $self->log($contactString);
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
  my ($protocolIds, $protocolSeriesNames);
  
  foreach my $protocolNode ($doc->findnodes('/idf/protocol')) {
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
	  $protocol->retrieveFromDB();
	  
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

#    my $protocolString = $protocol->toString();
#    $self->log($protocolString);
    $protocol->submit();
    my $protocolId = $protocol->getId();
    $protocolIds->{$name} = $protocolId;
  }
  return($protocolIds);
}

sub submitProtocolSeries {
  my ($self, $protocolSeriesName, $protocolIds) = @_;
  my $protocolSeriesIds;
  
  my $protocolSeries = GUS::Model::Study::Protocol->new({name => $protocolSeriesName});
  $protocolSeries->submit();
  my $protocolSeriesId = $protocolSeries->getId();
  $protocolSeriesIds->{$protocolSeriesName} = $protocolSeriesId;
  my @children = split(/;/, $protocolSeriesName);
  for (my $i=0; $i<@children; $i++) {
    my $protocolSeriesLink = GUS::Model::Study::ProtocolSeriesLink->new();
    $protocolSeriesLink->setProtocolSeriesId($protocolSeriesId);
    $protocolSeriesLink->setProtocolId($protocolIds->{$children[$i]});
    $protocolSeriesLink->submit();
  }

  return($protocolSeriesIds);
}

sub undoTables {
  my ($self) = @_;

  return ('Study.StudyContact', 'Study.ProtocolAppContact', 'SRes.Contact', 'Study.StudyBibRef', 'SRes.BibliographicReference', 'Study.StudyFunding', 'Study.Funding', 'Study.StudyDesign', 'Study.StudyFactorValue', 'Study.StudyFactor', 'Study.StudyLink', 'Study.Characteristic', 'Study.Input', 'Study.Output', 'Study.ProtocolAppNode', 'Study.ProtocolAppParam', 'Study.ProtocolApp', 'Study.ProtocolParam', 'Study.ProtocolSeriesLink', 'Study.Protocol', 'Study.Study');
}

1;

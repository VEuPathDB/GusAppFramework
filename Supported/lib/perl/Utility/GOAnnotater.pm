
#vvvvvvvvvvvvvvvvvvvvvvvvv GUS4_STATUS vvvvvvvvvvvvvvvvvvvvvvvvv
  # GUS4_STATUS | SRes.OntologyTerm              | auto   | absent
  # GUS4_STATUS | SRes.SequenceOntology          | auto   | absent
  # GUS4_STATUS | Study.OntologyEntry            | auto   | absent
  # GUS4_STATUS | SRes.GOTerm                    | auto   | fixed
  # GUS4_STATUS | Dots.RNAFeatureExon            | auto   | absent
  # GUS4_STATUS | RAD.SageTag                    | auto   | absent
  # GUS4_STATUS | RAD.Analysis                   | auto   | absent
  # GUS4_STATUS | ApiDB.Profile                  | auto   | absent
  # GUS4_STATUS | Study.Study                    | auto   | absent
  # GUS4_STATUS | Dots.Isolate                   | auto   | absent
  # GUS4_STATUS | DeprecatedTables               | auto   | absent
  # GUS4_STATUS | Pathway                        | auto   | absent
  # GUS4_STATUS | DoTS.SequenceVariation         | auto   | absent
  # GUS4_STATUS | RNASeq Junctions               | auto   | absent
  # GUS4_STATUS | Simple Rename                  | auto   | absent
  # GUS4_STATUS | ApiDB Tuning Gene              | auto   | absent
  # GUS4_STATUS | Rethink                        | auto   | absent
  # GUS4_STATUS | dots.gene                      | manual | reviewed

#^^^^^^^^^^^^^^^^^^^^^^^^^ End GUS4_STATUS ^^^^^^^^^^^^^^^^^^^^
package GUS::Supported::Utility::GOAnnotater;

use strict;

use GUS::Model::DoTS::GOAssocInstEvidCode;
use GUS::Model::DoTS::GOAssociationInstanceLOE;
use GUS::Model::DoTS::GOAssociationInstance;
use GUS::Model::DoTS::GOAssociation;


sub new {
   my $class = shift;
   my $plugin = shift;
   my $goRelease = shift;   #At least ONE record (or more in array type) of format name^version, 
                            # The name is the name of your GO database in sres.externaldatabase
                            # version is the version in sres.externaldatabaserelease

   my $goEvidenceCodeRelease = shift; # format name^version

   my $self = {};
   bless($self, $class);

   $self->{plugin} = $plugin;
                                                                                                                             
   $self->_initEvidenceCodes($goEvidenceCodeRelease);
   $self->_initGoTermIds($goRelease);
   $self->_initGoTermNames($goRelease);
   
   return $self;
}


sub getGoTermId {
  my ($self, $goId) = @_;

  my $goTermId = $self->{goTermIds}->{$goId};

  $goTermId
    || print("Can't find GoTerm in database for GO Id: $goId");

  return $goTermId;
}

sub getGoTermIdFromName {
  my ($self, $goName) = @_;

  $goName =~ tr/ /_/;
  my $goTermId = $self->{goTermNames}->{$goName};

  $goTermId
    || print("Can't find GoTerm in database for GO Id: $goName");

  return $goTermId;
}


sub getEvidenceCode {
  my ($self, $evidenceCode) = @_;
    
  my $evidenceId = $self->{evidenceIds}->{$evidenceCode};
       $evidenceId || die ("Evidence code '$evidenceCode' not found in db.");

  return $evidenceId;
}


sub getLoeId {
  my ($self, $loeName) = @_;

  if (!$self->{$loeName}) {
    my $gusObj = GUS::Model::DoTS::GOAssociationInstanceLOE->new( {
              'name' => $loeName,
               } );

      unless ($gusObj->retrieveFromDB) { 
                          $gusObj->submit();
                         }

      my $loeId = $gusObj->getId();
 
      $self->{$loeName} = $loeId;
  }

  return $self->{$loeName};
}


sub getOrCreateGOAssociation {
  my ($self, $goAssc) = @_;

     my $gusGOA = GUS::Model::DoTS::GOAssociation->new( {
                   'table_id' => $goAssc->{'tableId'},
                   'row_id' => $goAssc->{'rowId'},
                   'go_term_id' => $goAssc->{'goTermId'},
                   'is_not' => $goAssc->{'isNot'},
                   'is_deprecated' => 0,
                   'defining' => $goAssc->{'isDefining'},
                    } );

    unless ($gusGOA->retrieveFromDB()) {
       $gusGOA->submit(); 
    }

    my $goAssociationId = $gusGOA->getId();

return $goAssociationId;
}


sub deprecateGOInstances {
return 1;
}


sub getOrCreateGOInstance {
 my ($self, $assc) = @_;  

 my $gusObj = GUS::Model::DoTS::GOAssociationInstance->new( {
                      'go_association_id' => $assc->{'goAssociation'},
                      'go_assoc_inst_loe_id' => $assc->{'lineOfEvidence'},
                      'is_primary' => $assc->{'isPrimary'},
                      'is_deprecated' => 0, 
                       } );
 
 unless ($gusObj->retrieveFromDB) { 
                     $gusObj->submit(); 
                     }

 my $instId = $gusObj->getId();

 my $evdObj = GUS::Model::DoTS::GOAssocInstEvidCode->new( {
                     'go_evidence_code_id' => $assc->{'evidenceCode'},
                     'go_association_instance_id' => $instId, 
                      } );

 unless ($evdObj->retrieveFromDB) { $evdObj->submit(); }

return $instId;
}


sub _initEvidenceCodes {
   my $self = shift;
   my $dbRlsId = shift;

   my ($dbName,$dbVersion) = split(/\^/,$dbRlsId);

   my $extDbRlsId = $self->{plugin}->getExtDbRlsId($dbName,
                                                  $dbVersion,)
       or die "Couldn't retrieve external database!\n";


   my $sql = "select ontology_term_id, name from sres.ontologyterm where external_database_release_id = $extDbRlsId";
   
   my $stmt = $self->{plugin}->prepareAndExecute($sql);

   while (my ($id, $name) = $stmt->fetchrow_array()) { 
     $self->{evidenceIds}->{$name} = $id;
   }
}


sub _initGoTermIds {
   my ($self,$goRelease) = @_;

   foreach my $dbRlsId (@$goRelease) {

      my ($dbName,$dbVersion) = split(/\^/,$dbRlsId);

      my $goVersion = $self->{plugin}->getExtDbRlsId($dbName,
                                                   $dbVersion,)
              or die "Couldn't retrieve external database!\n";

      my $sql = "select ontology_term_id
     , source_id
from sres.ontologyterm 
where external_database_release_id = $goVersion
union
select o.ontology_term_id
     , s.source_id
from sres.ontologyterm o
   , sres.ontologysynonym s
where o.ONTOLOGY_TERM_ID = s.ONTOLOGY_TERM_ID
and s.source_id is not null
and o.external_database_release_id = $goVersion";

        my $stmt = $self->{plugin}->prepareAndExecute($sql);

        while (my ($go_term_id, $go_id) = $stmt->fetchrow_array()) {
           $self->{goTermIds}->{$go_id} = $go_term_id;
        }
    }
}

sub _initGoTermNames {
   my ($self,$goRelease) = @_;

   foreach my $dbRlsId (@$goRelease) {

      my ($dbName,$dbVersion) = split(/\^/,$dbRlsId);

      my $goVersion = $self->{plugin}->getExtDbRlsId($dbName,
                                                   $dbVersion,)
              or die "Couldn't retrieve external database!\n";

      my $sql = "select ontology_term_id
     , name
from sres.ontologyterm 
where external_database_release_id = $goVersion
union
select o.ontology_term_id
     , s.ontology_synonym
from sres.ontologyterm o
   , sres.ontologysynonym s
where o.ONTOLOGY_TERM_ID = s.ONTOLOGY_TERM_ID
and s.source_id is not null
and o.external_database_release_id = $goVersion";

        my $stmt = $self->{plugin}->prepareAndExecute($sql);

        while (my ($go_term_id, $name) = $stmt->fetchrow_array()) {
           $name =~ tr/ /_/;
           $self->{goTermNames}->{$name} = $go_term_id;
        }
    }
}

sub undoTables {
  my ($self) = @_;
  return (
		'DoTS.GOAssocInstEvidCode',
		'DoTS.GOAssociationInstance',
		'DoTS.GOAssociation'
     );
}


sub undoPreprocess {
  my ($dbh, $rowAlgInvocations) = @_;

  my $rowAlgInvocationList = join(',', @$rowAlgInvocations);


  my $updateSql = "update dots.goassociation set row_alg_invocation_id = ? where go_association_id = ?";
  my $updateSh = $dbh->prepare($updateSql);

  my $sql = "select ga.go_association_id, rightInstance.row_alg_invocation_id, ga.row_alg_invocation_id as old_row_alg_invocation_id
from dots.GoAssociation ga,
     (select go_association_id, min(row_alg_invocation_id) as row_alg_invocation_id
      from dots.GoAssociationInstance
      where row_alg_invocation_id not in ($rowAlgInvocationList)
      group by go_association_id
     ) rightInstance
where ga.row_alg_invocation_id in ($rowAlgInvocationList)
  and ga.go_association_id = rightInstance.go_association_id
";


  my $sh = $dbh->prepare($sql);
  $sh->execute();

  my $rowCount;

  while(my ($goAssId, $rowAlgId, $oldRowAlgInvocation) = $sh->fetchrow_array()) {
    $updateSh->execute($goAssId, $rowAlgId);
    $rowCount++;
  }

  return "Updated $rowCount Dots.GOAssocations";
}


1;


use strict;

use Bio::SeqIO;
use CBIL::Util::GenomeDir;

sub createPipelineDir {
  my ($mgr) = @_;

  my $propertySet = $mgr->{propertySet};
  my $signal = "createDir";

  return if $mgr->startStep("Creating dir structure", $signal);

  my $pipelineDir = $mgr->{'pipelineDir'};    # buildDir/release/speciesNickname

  $mgr->runCmd("mkdir -p $pipelineDir/seqfiles") unless (-e "$pipelineDir/seqfiles");
  $mgr->runCmd("mkdir -p $pipelineDir/misc") unless (-e "$pipelineDir/misc");
  $mgr->runCmd("mkdir -p $pipelineDir/downloadSite") unless (-e "$pipelineDir/downloadSite");
  $mgr->runCmd("mkdir -p $pipelineDir/blastSite") unless (-e "$pipelineDir/blastSite");

  my $speciesList = $propertySet->getProp('speciesNickname');
  my @speciesArr = split(/\,/,$speciesList);

  foreach my $species (@speciesArr) {
    $mgr->runCmd("mkdir -p $pipelineDir/cluster/${species}initial") unless (-e "$pipelineDir/cluster/${species}initial");
    $mgr->runCmd("mkdir -p $pipelineDir/cluster/${species}intermed") unless (-e "$pipelineDir/cluster/${species}intermed");
    $mgr->runCmd("mkdir -p $pipelineDir/assembly/${species}initial/big") unless (-e "$pipelineDir/assembly/${species}initial/big");
    $mgr->runCmd("mkdir -p $pipelineDir/assembly/${species}initial/small") unless (-e "$pipelineDir/assembly/${species}initial/small");
    $mgr->runCmd("mkdir -p $pipelineDir/assembly/${species}initial/reassemble") unless (-e "$pipelineDir/assembly/${species}initial/reassemble");
    $mgr->runCmd("mkdir -p $pipelineDir/assembly/${species}intermed/big") unless (-e "$pipelineDir/assembly/${species}intermed/big");
    $mgr->runCmd("mkdir -p $pipelineDir/assembly/${species}intermed/small") unless (-e "$pipelineDir/assembly/${species}intermed/small");
    $mgr->runCmd("mkdir -p $pipelineDir/assembly/${species}intermed/reassemble") unless (-e "$pipelineDir/assembly/${species}intermed/reassemble");
  }

  $mgr->runCmd("chmod -R g+w $pipelineDir");

  $mgr->endStep($signal);
}

sub createBlastMatrixDir {
  my ($mgr,$queryFile,$subjectFile) = @_;

  my $propertySet = $mgr->{propertySet};
  my $signal = "create${queryFile}-${subjectFile}MatrixDir";

  return if $mgr->startStep("Creating ${queryFile}-${subjectFile} dir", $signal);

  my $buildName = $mgr->{'buildName'};        # release/speciesNickname
  my $buildDir = $propertySet->getProp('buildDir');
  my $serverPath = $propertySet->getProp('serverPath');
  my $nodePath = $propertySet->getProp('nodePath');
  my $bmTaskSize = $propertySet->getProp('blastmatrix.taskSize');
  my $wuBlastBinPathCluster = $propertySet->getProp('wuBlastBinPathCluster');
  my $pipelineDir = $mgr->{'pipelineDir'};

  my $speciesList = $propertySet->getProp('speciesNickname');
  my @speciesArr = split(/\,/,$speciesList);

  foreach my $species (@speciesArr) {

    &makeMatrixDir(${species}$queryFile,$subjectFile, $buildName, $buildDir,
		 $serverPath, $nodePath, $bmTaskSize, $wuBlastBinPathCluster);

  $mgr->runCmd("chmod -R g+w $pipelineDir");

  $mgr->endStep($signal);
}

sub createSimilarityDir {
  my ($mgr,$queryFile,$subjectFile,$regex,$bsParams,$blastType) = @_;
  my $propertySet = $mgr->{propertySet};
  my $signal = "create" . ucfirst($queryFile) . "-" . ucfirst ($subjectFile) ."SimilarityDir";

  return if $mgr->startStep("Creating ${queryFile}-${subjectFile} similarity dir", $signal);

  my $buildName = $mgr->{'buildName'};        # release/speciesNickname
  my $buildDir = $propertySet->getProp('buildDir');
  my $serverPath = $propertySet->getProp('serverPath');
  my $nodePath = $propertySet->getProp('nodePath');
  my $bsTaskSize = $propertySet->getProp('blastsimilarity.taskSize');
  my $wuBlastBinPathCluster = $propertySet->getProp('wuBlastBinPathCluster');
  my $pipelineDir = $mgr->{'pipelineDir'};

  &makeSimilarityDir($queryFile, $subjectFile, $buildName, $buildDir,
		     $serverPath, $nodePath, $bsTaskSize,
		     $wuBlastBinPathCluster,
		     "${subjectFile}.fsa", "$serverPath/$buildName/seqfiles", '${queryFile}.fsa', $regex, $blastType, $bsParams);

  $mgr->runCmd("chmod -R g+w $pipelineDir");

  $mgr->endStep($signal);
}

sub createRepeatMaskDir {
  my ($mgr,$file) = @_;

  my $propertySet = $mgr->{propertySet};
  my $signal = "make" . ucfirst($file) . "SubDir";

  return if $mgr->startStep("Creating $file repeatmask dir", $signal);

  my $buildName = $mgr->{'buildName'};        # release/speciesNickname
  my $buildDir = $propertySet->getProp('buildDir');
  my $serverPath = $propertySet->getProp('serverPath');
  my $nodePath = $propertySet->getProp('nodePath');
  my $rmTaskSize = $propertySet->getProp('repeatmask.taskSize');
  my $rmPath = $propertySet->getProp('repeatmask.path');
  my $rmOptions = $propertySet->getProp('repeatmask.options');
  my $dangleMax = $propertySet->getProp('repeatmask.dangleMax');
  my $pipelineDir = $mgr->{'pipelineDir'};

  my $speciesList = $propertySet->getProp('speciesNickname');
  my @speciesArr = split(/\,/,$speciesList);

  foreach my $species (@speciesArr) {
    &makeRMDir(${species}$file, $buildName, $buildDir,
	     $serverPath, $nodePath, $rmTaskSize, $rmOptions, $dangleMax, $rmPath);
  }

  $mgr->runCmd("chmod -R g+w $pipelineDir");

  $mgr->endStep($signal);
}

sub createGenomeDir {
  my ($mgr,$query,$genome) = @_;
  my $signal = "create" . ucfirst($query) . "-" . ucfirst($genome) . "GenomeDir";
  return if $mgr->startStep("Creating ${query}-${genome} genome dir", $signal);

  my $propertySet = $mgr->{propertySet};
  my $buildName = $mgr->{buildName}; # release/nickName : release3.0/crypto
  my $buildDir = $propertySet->getProp('buildDir');
  my $serverPath = $propertySet->getProp('serverPath');
  my $nodePath = $propertySet->getProp('nodePath');
  my $gaTaskSize = $propertySet->getProp('genome.taskSize');
  my $gaPath = $propertySet->getProp('genome.path');
  my $gaOptions = $propertySet->getProp('genome.options');
  my $genomeVer = $propertySet->getProp('genome.version');
  my $clusterServer = $propertySet->getProp('clusterServer');
  my $extGDir = $propertySet->getProp('externalDbDir') . '/' . $genomeVer;
  my $srvGDir = $propertySet->getProp('serverExternalDbDir');
  my $genus = $propertySet->getProp('genusNickname'};
  my $speciesList = $propertySet->getProp('speciesNickname');
  my @speciesArr = split(/\,/,$speciesList);

  foreach my $species (@speciesArr) {
    $extGDir .= "$genus/$species";
    $srvGDir .= "$genus/$species";
    &makeGenomeDir(${species}$query, $genome, $buildName, $buildDir, $serverPath,
		$nodePath, $gaTaskSize, $gaOptions, $gaPath, $extGDir, $srvGDir);
  }

  $mgr->runCmd("chmod -R g+w $buildDir/$buildName/");
  $mgr->endStep($signal);
}

sub copyPipelineDirToComputeCluster {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $buildName = $mgr->{'buildName'};        # release/speciesNickname
  my $release = "release".$propertySet->getProp('release');
  my $serverPath = $propertySet->getProp('serverPath');
  my $fromDir =   $propertySet->getProp('buildDir');
  my $signal = "dir2cluster";
  return if $mgr->startStep("Copying $fromDir to $serverPath on clusterServer", $signal);

  $mgr->{cluster}->copyTo($fromDir, $buildName, $serverPath);
                      # buildDIr, release/nickname, serverPath

  $mgr->endStep($signal);
}


sub extractContigs {
  my ($mgr) = @_;

  my $propertySet = $mgr->{propertySet};

  my $signal = "extractContigs";

  return if $mgr->startStep("Extracting contigs from GUS", $signal);

  my $gusConfigFile = $propertySet->getProp('gusConfigFile');

  my $taxonId = $mgr->{taxonId};

  my $extDbName = $propertySet->getProp('contigDbName');
  my $extDbRlsVer = $propertySet->getProp('contigDbRlsVer');
  $mgr->{contigDbRlsId} =  &getDbRlsId($mgr,$extDbName,$extDbRlsVer) unless $mgr->{contigDbRlsId};
  my $contigDbRlsId = $mgr->{contigDbRlsId};

  my $contigFile = "$mgr->{pipelineDir}/seqfiles/contigs.fsa";
  my $logFile = "$mgr->{pipelineDir}/logs/${signal}.log";
 
  my $sql = my $sql = "select x.na_sequence_id, x.description,
            'length='||x.length,x.sequence
             from dots.ExternalNASequence x, dots.sequencetype s
             where x.taxon_id in ($taxonId)
             and x.external_database_release_id in ($contigDbRlsId)
             and x.sequence_type_id = s.sequence_type_id
             and s.name = 'contig'";

  my $cmd = "dumpSequencesFromTable.pl --gusConfigFile $gusConfigFile  --outputFile $contigFile --idSQL \"$sql\" --verbose 2>> $logFile";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);
}

sub extractAnnotatedProteins {
  my ($mgr) = @_;

  my $propertySet = $mgr->{propertySet};

  my $taxonId = $mgr->{taxonId};

  my $extDbName = $propertySet->getProp('contigDbName');
  my $extDbRlsVer = $propertySet->getProp('contigDbRlsVer');
  $mgr->{contigDbRlsId} =  &getDbRlsId($mgr,$extDbName,$extDbRlsVer) unless $mgr->{contigDbRlsId};
  my $contigDbRlsId = $mgr->{contigDbRlsId};

  my $sql = "select t.aa_sequence_id, 'length='||t.length,t.sequence
             from dots.ExternalNASequence x, dots.nafeature f, dots.sequencetype s,dots.aafeature a,dots.translatedaasequence t
             where x.taxon_id in ($taxonId)
             and x.external_database_release_id in ($contigDbRlsId)
             and x.sequence_type_id = s.sequence_type_id
             and s.name = 'contig'
             and x.na_sequence_id = f.na_sequence_id 
             and f.na_feature_id = a.na_feature_id
             and a.aa_sequence_id = t.aa_sequence_id";

  &extractProteinSeqs("annotatedProtein", $sql, $mgr);
}


sub extractNRDB {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $extDbName = $propertySet->getProp('nrdbDbName');
  my $extDbRlsVer = $propertySet->getProp('nrdbDbRlsVer');
  $mgr->{nrdbDbRlsId} =  &getDbRlsId($mgr,$extDbName,$extDbRlsVer) unless $mgr->{nrdbDbRlsId};
  my $nrdbDbRlsId = $mgr->{nrdbDbRlsId};

  my $sql = "select aa_sequence_id,'source_id='||source_id,'secondary_identifier='||secondary_identifier,description,'length='||length,sequence from dots.ExternalAASequence where external_database_release_id = $nrdbReleaseId";

  &extractProteinSeqs("nrdb", $sql, $mgr);
}

sub extractProteinSeqs {
  my ($name, $sql, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "${name}Extract";

  return if $mgr->startStep("Extracting $name protein sequences from GUS", $signal);

  my $gusConfigFile = $propertySet->getProp('gusConfigFile');

  my $seqFile = "$mgr->{pipelineDir}/seqfiles/${name}.fsa";
  my $logFile = "$mgr->{pipelineDir}/logs/${name}Extract.log";

  my $cmd = "dumpSequencesFromTable.pl --gusConfigFile $gusConfigFile  --outputFile $seqFile --idSQL \"$sql\" --verbose 2>> $logFile";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);
}


sub startProteinBlastOnComputeCluster {
  my ($mgr,$name) = @_;
  my $propertySet = $mgr->{propertySet};

  my $serverPath = $propertySet->getProp('serverPath');

  my $signal = "blast$name";
  return if $mgr->startStep("Starting $name blast on cluster", $signal);

  $mgr->endStep($signal);

  my $clusterCmdMsg = "submitPipelineJob run${name}Similarities $serverPath/$mgr->{buildName} NUMBER_OF_NODES";
  my $clusterLogMsg = "monitor $serverPath/$mgr->{buildName}/logs/*.log and xxxxx.xxxx.stdout";

  $mgr->exitToCluster($clusterCmdMsg, $clusterLogMsg, 1);
}

sub loadProteinBlast {
  my ($mgr,$name,$subjectTable) = @_;
  my $propertySet = $mgr->{propertySet};

  my $file = "$mgr->{pipelineDir}/similarity/$name/mainresult/blastSimilarity.out";

  my $restart = $propertySet->getProp("load${name}Restart");

  my $args = "--file $file --restartAlgInvs $restart --queryTable DoTS::ExternalNASequence --subjectTable  $subjectTable --subjectsLimit 50 --hspsLimit 10";

  $mgr->runPlugin("loadSims_$name",
		  "GUS::Common::Plugin::LoadBlastSimFast", $args,
		  "Loading $name similarities");
}


sub makeTranscriptSeqs {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $externalDbDir = $propertySet->getProp('externalDbDir');

  my $file = $propertySet->getProp('fileOfRepeats');

  my $taxonIdList = &getTaxonIdList($mgr);

  my $repeatFile = "$externalDbDir/repeat/$file";

  my $phrapDir = $propertySet->getProp('phrapDir');

  my $args = "--taxon_id_list '$taxonIdList' --repeatFile $repeatFile --phrapDir $phrapDir";

  $mgr->runPlugin("makeAssemSeqs",
		  "DoTS::DotsBuild::Plugin::MakeAssemblySequences", $args,
		  "Making assembly table sequences");
}


sub extractTranscriptSeqs {
  my ($mgr,$name) = @_;
  my $propertySet = $mgr->{propertySet};

  my $taxonIdList = &getTaxonIdList($mgr);

  my $outputFile = "$mgr->{pipelineDir}/seqfiles/${name}.fsa";
  my $args = "--taxon_id_list '$taxonIdList' --outputfile $outputFile --extractonly";

  $mgr->runPlugin("extractUnalignedAssemSeqs",
		  "DoTS::DotsBuild::Plugin::ExtractAndBlockAssemblySequences",
		  $args, "Extracting unaligned assembly sequences");
}

sub extractAssemblies {
  my ($mgr,$name) = @_;
  my $propertySet = $mgr->{propertySet};

  $name = "${name}Assemblies";
  my $signal = "${name}Extract";

  return if $mgr->startStep("Extracting $name assemblies from GUS", $signal);

  my $gusConfigFile = $propertySet->getProp('gusConfigFile');
  my $taxonId = $mgr->{taxonId};
  my $species = $propertySet->getProp('speciesNickname');

  my $seqFile = "$mgr->{pipelineDir}/seqfiles/$name.fsa";
  my $logFile = "$mgr->{pipelineDir}/logs/${name}Extract.log";

  my $sql = "select na_sequence_id,'[$species]',description,'('||number_of_contained_sequences||' sequences)','length='||length,sequence from dots.Assembly where taxon_id = $taxonId";

  my $cmd = "dumpSequencesFromTable.pl --outputFile $seqFile --gusConfigFile $gusConfigFile  --verbose --idSQL \"$sql\" 2>>  $logFile";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);
}

sub startTranscriptAlignToContigs {
  my ($mgr,$name) = @_;
  my $propertySet = $mgr->{propertySet};

  my $serverPath = $propertySet->getProp('serverPath');
  my $clusterServer = $propertySet->getProp('clusterServer');

  my $signal = "${name}AlignToContigs";
  return if $mgr->startStep("Aligning $name to contigs on $clusterServer", $signal);

  $mgr->endStep($signal);
  my $clusterCmdMsg = "submitPipelineJob runContigAlign $serverPath/$mgr->{buildName} NUMBER_OF_NODES";
  my $clusterLogMsg = "monitor $serverPath/$mgr->{buildName}/logs/*.log and xxxxx.xxxx.stdout";

  $mgr->exitToCluster($clusterCmdMsg, $clusterLogMsg, 1);
}

sub loadContigAlignments {
  my ($mgr, $queryName, $targetName) = @_;
  my $propertySet = $mgr->{propertySet};

  my $taxonId = $mgr->{taxonId};

  my $extDbName = $propertySet->getProp('contigDbName');
  my $extDbRlsVer = $propertySet->getProp('contigDbRlsVer');
  $mgr->{contigDbRlsId} =  &getDbRlsId($mgr,$extDbName,$extDbRlsVer) unless $mgr->{contigDbRlsId};
  my $genomeId = $mgr->{contigDbRlsId};

  my $pipelineDir = $mgr->{'pipelineDir'};
  my $pslDir = "$pipelineDir/genome/$queryName-$targetName/mainresult/per-seq";

  my $qFile = "$pipelineDir/repeatmask/$queryName/mainresult/blocked.seq";
  my $tmpFile;
  my $qDir = "/tmp/" . $propertySet->getProp('speciesNickname');

  my $qTabId;
  if ($queryName =~ /finalTranscripts/i) {
    $qTabId = &getTableId($mgr, "Assembly");
    $qFile = "$pipelineDir/seqfiles/finalTranscripts.fsa";
    $tmpFile = $qDir . "/finalTranscripts.fsa";
  }
  else {
    $qTabId = &getTableId($mgr, "AssemblySequence");
    $qFile = "$pipelineDir/repeatmask/$queryName/master/mainresult/blocked.seq";
    $tmpFile = $qDir . "/blocked.seq";
  }

  # copy qFile to /tmp directory to work around a bug in the
  # LoadBLATAlignments plugin's call to FastaIndex

  $mgr->runCmd("mkdir $qDir") if ! -d $qDir;
  $mgr->runCmd("cp $qFile $tmpFile");

  my $tTabId;
  if ($targetName =~ /contigs/i) {
    $tTabId = &getTableId($mgr, "ExternalNASequence");
  }
  else {
    $tTabId = &getTableId($mgr, "VirtualSequence");
  }
  # 56  Assembly
  # 57  AssemblySequence
  # 89  ExternalNASequence
  # 245 VirtualSequence

  my $args = "--blat_dir $pslDir --query_file $tmpFile --keep_best 2 "
    . "--query_table_id $qTabId --query_taxon_id $taxonId "
      . "--target_table_id  $tTabId --target_db_rel_id $genomeId --target_taxon_id $taxonId "
	. "--max_query_gap 5 --min_pct_id 95 max_end_mismatch 10 "
	  . "--end_gap_factor 10 --min_gap_pct 90 "
	    . "--ok_internal_gap 15 --ok_end_gap 50 --min_query_pct 10";

  if ($queryName =~ /newTranscripts/i) {
    my $extDbName = $propertySet->getProp('genbankDbName');
    my $extDbRlsVer = $propertySet->getProp('genbankDbRlsVer');
    $mgr->{genbankDbRlsId} =  &getDbRlsId($mgr,$extDbName,$extDbRlsVer) unless $mgr->{genbankDbRlsId}
    my $gb_db_rel_id = $mgr->{genbankDbRlsId};
    $args .= " --query_db_rel_id $gb_db_rel_id";
  }

  $mgr->runPlugin("LoadBLATAlignments", 
			  "GUS::Common::Plugin::LoadBLATAlignments",
			  $args, "loading genomic alignments of $queryName vs $targetName");
}

sub clusterByContigAlign {
    my ($mgr, $name) = @_;
    my $propertySet = $mgr->{propertySet};

    my $pipelineDir = $mgr->{'pipelineDir'};
    my $taxonId = $mgr->{taxonId};

    my $extDbName = $propertySet->getProp('contigDbName');
    my $extDbRlsVer = $propertySet->getProp('contigDbRlsVer');
    $mgr->{contigDbRlsId} =  &getDbRlsId($mgr,$extDbName,$extDbRlsVer) unless $mgr->{contigDbRlsId};
    my $extDbRelId = $mgr->{contigDbRlsId};

    my $extDbNameGB = $propertySet->getProp('genbankDbName');
    my $extDbRlsVerGB = $propertySet->getProp('genbankDbRlsVer');
    $mgr->{genbankDbRlsId} =  &getDbRlsId($mgr,$extDbNameGB,$extDbRlsVerGB) unless $mgr->{genbankDbRlsId}
    my $gb_db_rel_id = $mgr->{genbankDbRlsId};

    my $outputFile = "$pipelineDir/cluster/$name/cluster.out";
    my $logFile = "$pipelineDir/logs/${name}Cluster.log";

    my $args = "--stage $name --taxon_id $taxonId --query_db_rel_id $gb_db_rel_id "
	. "--target_db_rel_id $extDbRelId --out $outputFile --sort 1";
    # $args .= " --test_chr 5";

    $mgr->runPlugin("ClusterByContig", 
		    "DoTS::DotsBuild::Plugin::ClusterByGenome",
		    $args, "$name clustering by contig alignment");

}
  
sub copyFilesToComputeCluster {
  my ($mgr,$name) = @_;
  my $propertySet = $mgr->{propertySet};

  my $serverPath = $propertySet->getProp('serverPath');
  my $clusterServer = $propertySet->getProp('clusterServer');

  my $signal = "${name}ToCluster";
  return if $mgr->startStep("Copying $name to $serverPath/$mgr->{buildName}/seqfiles on $clusterServer", $signal);

  my $seqfilesDir = "$mgr->{pipelineDir}/seqfiles/";
  my $f = "${name}.fsa";

  $mgr->{cluster}->copyTo($seqfilesDir, $f, "$serverPath/$mgr->{buildName}/seqfiles");
  
  $mgr->endStep($signal);
}

sub clusterByBlastSim {
  my ($mgr, $name, @matrices) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "${name}Cluster";

  return if $mgr->startStep("Clustering $name", $signal);

  my $length = $propertySet->getProp("$signal.length");
  my $percent = $propertySet->getProp("$signal.percent");
  my $logbase = $propertySet->getProp("$signal.logbase");
  my $consistentEnds = $propertySet->getProp("$signal.consistentEnds");
  my $cliqueSzArray = $propertySet->getProp("$signal.cliqueSzArray");
  my $logbaseArray = $propertySet->getProp("$signal.logbaseArray");

  my @matrixFileArray;
  foreach my $matrix (@matrices) {
    push(@matrixFileArray,
	 "$mgr->{pipelineDir}/matrix/$matrix/blastMatrix.out.gz");
  }
  my $matrixFiles = join(",", @matrixFileArray);

  my $ceflag = ($consistentEnds eq "yes")? "--consistentEnds" : "";

  my $outputFile = "$mgr->{pipelineDir}/cluster/$name/cluster.out";
  my $logFile = "$mgr->{pipelineDir}/logs/$signal.log";

  my $cmd = "buildBlastClusters.pl --lengthCutoff $length --percentCutoff $percent --verbose --files '$matrixFiles' --logBase $logbase --iterateCliqueSizeArray $cliqueSzArray $ceflag --iterateLogBaseArray $logbaseArray --sort > $outputFile 2>> $logFile";

  $mgr->runCmd($cmd);

  $mgr->endStep($signal);
}


sub splitCluster {
  my ($name, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "${name}SplitCluster";

  return if $mgr->startStep("SplitCluster $name", $signal);

  my $clusterFile = "$mgr->{pipelineDir}/cluster/$name/cluster.out";
  my $splitCmd = "splitClusterFile $clusterFile";

  $mgr->runCmd($splitCmd);
  $mgr->endStep($signal);
}

sub assembleTranscripts {
  my ($old, $reassemble, $name, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "${name}Assemble";

  return if $mgr->startStep("Assemble $name", $signal);

  my $clusterFile = "$mgr->{pipelineDir}/cluster/$name/cluster.out";

  &runAssemblePlugin($clusterFile, "big", $name, $old, $reassemble, $mgr);
  &runAssemblePlugin($clusterFile, "small", $name, $old, $reassemble, $mgr);
  $mgr->endStep($signal);
  my $msg =
    "EXITING.... PLEASE DO THE FOLLOWING:
 1. check for errors in assemble.errLog and sql failures in updateDOTSAssemblies.log
 2. resume when assembly completes (validly) by re-runnning 'dotsbuild $mgr->{propertiesFile}'
";
  print STDERR $msg;
  print $msg;
  $mgr->goodbye($msg);
}

sub reassembleTranscripts {
  my ($name, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $signal = "${name}Reassemble";

  return if $mgr->startStep("Reassemble $name", $signal);

  my $taxonId = $mgr->{taxonId};

  my $sql = "select na_sequence_id from dots.assembly where taxon_id = $taxonId  and (assembly_consistency < 90 or length < 50 or length is null or description = 'ERROR: Needs to be reassembled')";

  my $clusterFile = "$mgr->{pipelineDir}/cluster/$name/cluster.out";

  my $suffix = "reassemble";

  my $old = "";

  my $reassemble = "yes";

  my $cmd = "makeClusterFile --idSQL \"$sql\" --clusterFile $clusterFile.$suffix";

  $mgr->runCmd($cmd);

  &runAssemblePlugin($clusterFile, $suffix, $name, $old, $reassemble, $mgr);

  $mgr->endStep($signal);
  my $msg =
    "EXITING.... PLEASE DO THE FOLLOWING:
 1. resume when reassembly completes (validly) by re-runnning 'dotsbuild $mgr->{propertiesFile}'
";
  print STDERR $msg;
  print $msg;
  $mgr->goodbye($msg);
}

sub runAssemblePlugin {
  my ($file, $suffix, $name, $assembleOld, $reassemble, $mgr) = @_;
  my $propertySet = $mgr->{propertySet};

  my $taxonId = $mgr->{taxonId};
  my $cap4Dir = $propertySet->getProp('cap4Dir');

  my $reass = $reassemble eq "yes"? "--reassemble" : "";
  my $args = "--clusterfile $file.$suffix $assembleOld $reass --taxon_id $taxonId --cap4Dir $cap4Dir";
  my $pluginCmd = "ga DoTS::DotsBuild::Plugin::UpdateDotsAssembliesWithCap4 --commit $args --comment '$args'";

  my $logfile = "$mgr->{pipelineDir}/logs/${name}Assemble.$suffix.log";

  my $assemDir = "$mgr->{pipelineDir}/assembly/$name/$suffix";
  $mgr->runCmd("mkdir -p $assemDir");
  chdir $assemDir || die "Can't chdir to $assemDir";

  my $cmd = "runUpdateAssembliesPlugin --clusterFile $file.$suffix --pluginCmd \"$pluginCmd\" 2>> $logfile";
  $mgr->runCmdInBackground($cmd);
}

sub deleteAssembliesWithNoTranscripts {
  my ($mgr, $name) = @_;
  my $propertySet = $mgr->{propertySet};

  my $taxonId = $mgr->{taxonId};

  my $args = "--taxon_id $taxonId";

  $mgr->runPlugin("${name}deleteAssembliesWithNoAssSeq", 
		  "DoTS::DotsBuild::Plugin::DeleteAssembliesWithNoAssemblySequences",
		  $args, "Deleting assemblies with no assemblysequences");

}


sub startTranscriptMatrixOnComputeCluster {
  my ($mgr,$name) = @_;
  my $propertySet = $mgr->{propertySet};

  my $serverPath = $propertySet->getProp('serverPath');

  my $signal = "${name}TranscriptMatrix";
  return if $mgr->startStep("Starting ${name}Transcript matrix", $signal);

  $mgr->endStep($signal);

  my $cmd = "run" . ucfirst($signal);

  my $cmdMsg = "submitPipelineJob $cmd $serverPath/$mgr->{buildName} NUMBER_OF_NODES";
  my $logMsg = "monitor $serverPath/$mgr->{buildName}/logs/*.log and xxxxx.xxxx.stdout";

  $mgr->exitToCluster($cmdMsg, $logMsg, 0);
}


sub copyFilesFromComputeCluster {
  my ($mgr,$name,$dir) = @_;
  my $propertySet = $mgr->{propertySet};

  my $serverPath = $propertySet->getProp('serverPath');
  my $clusterServer = $propertySet->getProp('clusterServer');

  my $signal = "copy${name}ResultsFromCluster";
  return if $mgr->startStep("Copying $name results from $clusterServer",
			    $signal);

  $mgr->{cluster}->copyFrom(
		       "$serverPath/$mgr->{buildName}/$dir/$name/master/",
		       "mainresult",
		       "$mgr->{pipelineDir}/$dir/$name");
  $mgr->endStep($signal);
}

sub makeBuildName {
  my ($nickName, $release) = @_;

  return makeBuildNameRls($nickName, $release);
}

sub makeBuildNameRls {
  my ($nickName, $release) = @_;

  return "release${release}/" . $nickName;
}

sub usage {
  my $prog = `basename $0`;
  chomp $prog;
  print STDERR "usage: $prog propertiesfile\n";
  exit 1;
}

sub getTaxonIdFromTaxId {
  my ($mgr) = @_;

  my $propertySet = $mgr->{propertySet};

  my $ncbiTaxId = $propertySet->getProp('ncbiTaxId');

  my $sql = "select taxon_id from sres.taxon where ncbi_tax_id in ($ncbiTaxId)";

  my $cmd = "getValueFromTable --idSQL $sql";
  my $taxonId = $mgr->runCmd($cmd);

  return  $taxonId;
}

sub getTaxonIdList {
  my ($mgr) = @_;
  my $propertySet = $mgr->{propertySet};
  my $returnValue;

  my $taxonId = $mgr->{taxonId};
  if ($propertySet->getProp('includeSubspecies') eq "yes") {
    $returnValue = $mgr->runCmd("getSubTaxa --taxon_id $taxonId");
    chomp $returnValue;
  } else {
    $returnValue = $taxonId;
  }

  return $returnValue;
}

sub getDbRlsId {
  my ($mgr,$extDbName,$extDbRlsVer) = @_;

  my $propertySet = $mgr->{propertySet};

  my $sql = "select external_database_release_id from sres.externaldatabaserelease d, sres.externaldatabase x where x.name in ($extDbName) and x.external_database_id = d.external_database_id and d.version in ($extDbRlsVer)";

  my $cmd = "getValueFromTable --idSQL $sql";
  my $extDbRlsId = $mgr->runCmd($cmd);

  return  $extDbRlsId;
}

sub getTableId {
  my ($mgr,$tableName) = @_;

  my $propertySet = $mgr->{propertySet};

  my $sql = "select table_id from core.tableinfo where name = $tableName";

  my $cmd = "getValueFromTable --idSQL $sql";
  my $tableId = $mgr->runCmd($cmd);

  return  $tableId;
}


=cut

sub getTranlsatedAASeqs{
  my ($mgr,$name,$trunc) = @_;
  
  my $propertySet = $mgr->{propertySet};

  my $gusConfigFile = $propertySet->getProp('gusConfigFile');
  my $logFile = "$fileName.log";
  my $filename = "$name.fsa"
  
  if ($trunc) {
     $qrySQL = select aa_sequence_id,substr(sequence,1,70) from dots.translatedaasequence (where taxon......)
  }
  else {
     $qrySQL = $qrySQL = select aa_sequence_id,sequence from dots.translatedaasequence (where taxon.....);
  }
  
  my $cmd = "dumpSequencesFromTable.pl --gusConfigFile $gusConfigFile  --outputFile $fileName --idSQL \"$qrySQL\" --verbose 2>> $logFile";

  $mgr->runCmd($cmd);
  
  $mgr->endStep($name);
}





sub copyFilesToComputeCluster{
  my ($mgr,$name,$cmd,$dir) = @_;
  #may need simple command above and full path here for specifying where.
  
  Ok, I will need help with this from Debbie.
  }






sub runAAFeaturePredictor{
  my ($mgr,$name,$dir,$cmd) = @_;
  
  my $propertySet = $mgr->{propertySet};
  my $filepath = ????? #how do we track this???????????????????????????????
  my $filename= "$name.fsa";
  
  $cmd = "$dir.$cmd.$filepath.$filename";
  
  $mgr->runCmd($cmd);
  
  $mgr->endStep($signal);
  
}





sub retrieveOutput{
  my ($mgr,$name,$dir) = @_;
  
  Same as putting data in the cluster, I need help getting it back off and in the right place to run the plugin
  
  
}






sub loadData{
  my ($mgr,$name) = @_;
  
  my $gusConfigFile = $propertySet->getProp('gusConfigFile');
  my $args = "--data_file=PATH/$name.??? --algName=$name --algVer=???? --algDesc=??????? --project_name=?????/"

     if ($name eq "TMHmm") {
         my $plugin = "GUS::Common::Plugin::LoadTMDomains";
         my $pluginName = "LoadTMDomains";
     }
     if ($name eq "SignalP") {
         my $plugin = "GUS::Common::Plugin::LoadSignalP";
         my $pluginName = "LoadSignalP";
     }

  $mgr->runPlugin($pluginName, $plugin, $args, "Loading $name output");

  $mgr->endStep($signal);

}

  
=cut


1;

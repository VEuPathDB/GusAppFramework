package GUS::ReportMaker::PlasmodbGeneReportConfig;

our @ISA = qw(Exporter);
our @EXPORT = qw(createReport);

use strict;
use GUS::ReportMaker::DefaultColumn;
use GUS::ReportMaker::Query;
use GUS::ReportMaker::Report;

sub createReport {
  my ($tempTable, $primaryKeyName, $mappedToName, $mappingTables) = @_;

  my @columns;

################################################################################
# plasmoDbGenesQuery

  my $sourceIdCol =
    GUS::ReportMaker::DefaultColumn->new("PlasmoDB_Gene_Name",
					 "The primary PlasmoDB Gene ID (or 'Source ID')",
					 undef, 1);
  push(@columns, $sourceIdCol);

  my $productCol =
    GUS::ReportMaker::DefaultColumn->new("Product",
					 "Description of gene product", undef, 1);
  push(@columns, $productCol);

  my $geneTypeCol =
    GUS::ReportMaker::DefaultColumn->new("Gene_Type",
					 "Gene Type (protein coding, tRNA or rRNA)");
  push(@columns, $geneTypeCol);

  my $isPseudoCol =
    GUS::ReportMaker::DefaultColumn->new("Is_Pseudogene",
					 "Is this a pseudogene (yes/no)?");
  push(@columns, $isPseudoCol);

  my $taxonNameCol =
    GUS::ReportMaker::DefaultColumn->new("Taxon_Name",
					 "Name of species from which gene comes");
  push(@columns, $taxonNameCol);

  my $chromosomeCol =
    GUS::ReportMaker::DefaultColumn->new("Chromosome",
					 "Number of chromosome on which the gene is found");
  push(@columns, $chromosomeCol);

  my $predictionAlgorithmNameCol =
    GUS::ReportMaker::DefaultColumn->new("Prediction_Algorithm",
					 "Name of gene prediction algorithm");
  push(@columns, $predictionAlgorithmNameCol);

  my $externalDatabaseNameCol =
    GUS::ReportMaker::DefaultColumn->new("External_Database",
					 "Name of external source database");
  push(@columns, $externalDatabaseNameCol);

  my $plasmodbGenesSql =
    "select distinct tmp.$primaryKeyName, gf.source_id as Plasmodb_Gene_Name,
            gf.product, gf.gene_type,
            gf.is_pseudo as Is_Pseudogene, gf.taxon_name,  gf.chromosome,
            gf.prediction_algorithm_name as Prediction_Algorithm,
            gf.external_database_name as External_Database
     from $tempTable tmp, plasmodb_42.plasmodb_genes gf
     where gf.na_feature_id = tmp.$primaryKeyName";

# print STDERR "\nplasmodbGenesSql = \n$plasmodbGenesSql\n\n";

  my $plasmodbGenesQuery =
    GUS::ReportMaker::Query->
      new($plasmodbGenesSql,
	  [$sourceIdCol, $productCol, $geneTypeCol, $isPseudoCol,
	   $taxonNameCol, $chromosomeCol,
	   $predictionAlgorithmNameCol,
	   $externalDatabaseNameCol
	   ]);

################################################################################
# notesQuery

  my $notesCol =
    GUS::ReportMaker::DefaultColumn->new("Notes",
					 "Comments by annotators and PlasmoDB users");
  push(@columns, $notesCol);

  my $notesSql =
    "select tmp.$primaryKeyName, n.comment_string as Notes
     from $tempTable tmp, DoTS.NaFeatureComment n
     where n.na_feature_id = tmp.$primaryKeyName
       and (n.comment_string like 'PUB_COMMENT%' or n.comment_string like 'Community PUB_COMMENT%')";

# print STDERR "\nnotesSql = \n$notesSql\n\n";

  my $notesQuery =
    GUS::ReportMaker::Query->new($notesSql,
				 [$notesCol
				 ]);

################################################################################
# ecNumQuery

  my $ecNumCol =
    GUS::ReportMaker::DefaultColumn->new("EC_Number",
					 "Enzyme Commission number");
  push(@columns, $ecNumCol);

  my $ecAssignCol =
    GUS::ReportMaker::DefaultColumn->new("EC_Assign_Method",
					 "Method by which EC assignment was made");
  push(@columns, $ecAssignCol);

  my $ecDescCol =
    GUS::ReportMaker::DefaultColumn->new("EC_Description",
					 "Enzyme Commission description");
  push(@columns, $ecDescCol);

  my $ecSql =
    "select distinct tmp.$primaryKeyName, ec.ec_number,
     ('manual: reviewed=' || aec.review_status_id) as assign_method,
     ec.description as ec_description
     from $tempTable tmp, plasmodb_42.plasmodb_genes gf, plasmodb.AASequenceEnzymeClass aec, sres.EnzymeClass ec
     where gf.na_feature_id = tmp.$primaryKeyName
       and gf.aa_sequence_id = aec.aa_sequence_id
       and aec.enzyme_class_id = ec.enzyme_class_id
     union
     select distinct tmp.$primaryKeyName, ec.ec_number,
     'GO-EC mapping' as ec_assign_method, ec.description as ec_description
    from $tempTable tmp, plasmodb_42.plasmodb_genes gf, dots.GOAssociation ga1, dots.GOAssociation ga2, sres.EnzymeClass ec 
    where gf.na_feature_id = tmp.$primaryKeyName
      and gf.aa_sequence_id = ga1.row_id
      and ga1.table_id = 337
      and ga1.go_term_id = ga2.go_term_id
      and ga2.table_id = 3361
      and ga2.row_id = ec.enzyme_class_id";

# print STDERR "\necSql = \n$ecSql\n\n";

  my $ecQuery =
    GUS::ReportMaker::Query->new($ecSql,
				 [$ecNumCol,
                                  $ecAssignCol,
                                  $ecDescCol,
				 ]);

################################################################################
# goFuncQuery

  my $goFuncNameCol =
    GUS::ReportMaker::DefaultColumn->new("GO_Func_Name",
					 "Gene Ontology (GO) Molecular Function Term");
  push(@columns, $goFuncNameCol);

  my $goFuncIdCol =
    GUS::ReportMaker::DefaultColumn->new("GO_Func_Id",
					 "Gene Ontology (GO) Molecular Function ID");
  push(@columns, $goFuncIdCol);

  my $goFuncSql =
    "select distinct tmp.$primaryKeyName, gt.name Go_Func_Name, gt.go_term_id Go_Func_Id
from $tempTable tmp, plasmodb_42.plasmodb_genes gf, dots.GOAssociation ga,
/* */
      dots.GOAssociationInstance gai,
      dots.GOAssocInstEvidCode gaiec, sres.GOEvidenceCode gec,
/* */ 
     sres.GOTerm gt, sres.GOTerm ancestor
where gf.na_feature_id = tmp.$primaryKeyName
 and  gf.aa_sequence_id = ga.row_id
 and ga.table_id = 337
 and ga.go_term_id = gt.go_term_id
 and gt.ancestor_go_term_id = ancestor.go_term_id
 and ancestor.name = 'molecular_function'
/* */
 and ga.go_association_id = gai.go_association_id
 and gai.go_association_instance_id = gaiec.go_association_instance_id
 and gaiec.go_evidence_code_id = gec.go_evidence_code_id
/*  */
 and gt.name not in ('molecular_function', 'biological_process', 'cellular_component')
";

# print STDERR "\ngoFuncSql = \n$goFuncSql\n\n";

  my $goFuncQuery =
    GUS::ReportMaker::Query->new($goFuncSql,
				 [$goFuncNameCol,
                                  $goFuncIdCol,
				 ]);

################################################################################
# goProcQuery

  my $goProcNameCol =
    GUS::ReportMaker::DefaultColumn->new("GO_Proc_Name",
					 "Gene Ontology (GO) Biological Process Term");
  push(@columns, $goProcNameCol);

  my $goProcIdCol =
    GUS::ReportMaker::DefaultColumn->new("GO_Proc_Id",
					 "Gene Ontology (GO) Biological Process ID");
  push(@columns, $goProcIdCol);

  my $goProcSql = $goFuncSql;
  $goProcSql =~ s/molecular_function/biological_process/;
  $goProcSql =~ s/Go_Func/Go_Proc/g;

# print STDERR "\ngoProcSql =\n$goProcSql\n\n";

  my $goProcQuery =
    GUS::ReportMaker::Query->new($goProcSql,
				 [$goProcNameCol,
                                  $goProcIdCol,
				 ]);

################################################################################
# goComponentQuery

  my $goComponentNameCol =
    GUS::ReportMaker::DefaultColumn->new("GO_Component_Name",
					 "Gene Ontology (GO) Cellular Component Term");
  push(@columns, $goComponentNameCol);

  my $goComponentIdCol =
    GUS::ReportMaker::DefaultColumn->new("GO_Component_Id",
					 "Gene Ontology (GO) Cellular Component ID");
  push(@columns, $goComponentIdCol);

  my $goComponentSql = $goFuncSql;
  $goComponentSql =~ s/molecular_function/cellular_component/;
  $goComponentSql =~ s/Go_Func/Go_Component/g;

#  print STDERR "\ngoComponentSql = (after)\n$goComponentSql\n\n";

  my $goComponentQuery =
    GUS::ReportMaker::Query->new($goComponentSql,
				 [$goComponentNameCol,
                                  $goComponentIdCol,
				 ]);

################################################################################
# splicedNaSeqQuery

  my $splicedNaSeqCol =
    GUS::ReportMaker::DefaultColumn->new("Spliced_NA_Sequence",
					 "Predicted mRNA/RNA/cDNA sequence (i.e. introns spliced out)");
  push(@columns, $splicedNaSeqCol);

  my $splicedSeqLenCol =
    GUS::ReportMaker::DefaultColumn->new("NA_Sequence_Length",
					 "Length of spliced nucleic-acid sequence");
  push(@columns, $splicedSeqLenCol);

  my $splicedNaSeqSql =
    "select tmp.na_feature_id, sns.sequence as Spliced_Na_Sequence,
            length as Na_Sequence_Length
     from $tempTable tmp, plasmodb_42.plasmodb_genes gf, dots.splicednasequence sns
      where tmp.na_feature_id = gf.na_feature_id
       and gf.na_sequence_id = sns.na_sequence_id 
";

# print STDERR "\nsplicedNaSeqSql = \n$splicedNaSeqSql\n\n";

  my $splicedNaSeqQuery =
    GUS::ReportMaker::Query->new($splicedNaSeqSql,
				 [$splicedNaSeqCol,
				  $splicedSeqLenCol,
				 ]);

################################################################################
# predictedProteinSeqQuery

  my $predictedProteinSeqCol =
    GUS::ReportMaker::DefaultColumn->new("Predicted_Protein_Seq",
					 "Amino-acid sequence of predicted gene product");
  push(@columns, $predictedProteinSeqCol);

  my $predictedProteinSeqLenCol =
    GUS::ReportMaker::DefaultColumn->new("Protein_Sequence_Length",
					 "Length of predicted amino-acid sequence");
  push(@columns, $predictedProteinSeqLenCol);

  my $predictedProteinSeqSql =
    "select tmp.na_feature_id, tas.sequence as predicted_protein_seq,
            tas.length as Protein_Sequence_Length
     from $tempTable tmp, plasmodb_42.plasmodb_genes gf, dots.translatedaasequence tas
     where tmp.na_feature_id = gf.na_feature_id
       and gf.aa_sequence_id = tas.aa_sequence_id
";

# print STDERR "\npredictedProteinSeqSql = \n$predictedProteinSeqSql\n\n";

  my $predictedProteinSeqQuery =
    GUS::ReportMaker::Query->new($predictedProteinSeqSql,
				 [$predictedProteinSeqCol,
				  $predictedProteinSeqLenCol,
				 ]);

################################################################################
# exonLocationQuery

  my $exonLocationCol =
    GUS::ReportMaker::DefaultColumn->new("Exon_Locations",
					 "Start and end locations of gene exons");
  push(@columns, $exonLocationCol);

  my $exonLocationSql =
    "select tmp.na_feature_id, ef.order_number,
            to_char(nl.start_min) || '-' || to_char(nl.end_max) Exon_Locations
     from $tempTable tmp,  dots.ExonFeature ef, dots.NaLocation nl
     where tmp.na_feature_id = ef.parent_id
     and nl.na_feature_id = ef.na_feature_id
     order by ef.order_number
";

# print STDERR "\nexonLocationSql = \n$exonLocationSql\n\n";

  my $exonLocationQuery =
    GUS::ReportMaker::Query->new($exonLocationSql,
				 [$exonLocationCol,
				 ]);

################################################################################
# microarraysQuery

  my $microarraysCol =
    GUS::ReportMaker::DefaultColumn->new("Microarrays",
					 "Microarrays containing this gene");
  push(@columns, $microarraysCol);

  my $microarraysSql =
    "select tmp.na_feature_id,
       decode(a.array_id,
              484, 'Scripps/GNF malaria array (scrmalaria)',
                9, 'DeRisi P. falciparum 70-mer oligo array, version 1',
                7, 'DeRisi P. falciparum 70-mer oligo array, version 2',
               10, 'Ben Mamoun P. falciparum cDNA array',
               12, 'MRA-452, 23K (MR4 P. falciparum long oligo)',
               a.name) as microarrays
     from $tempTable tmp ,rad3.CompositeElementGUS ceg,
          rad3.CompositeElementImp sf, rad3.Array a
     where tmp.na_feature_id = ceg.row_id
       and ceg.table_id = 108
       and ceg.composite_element_id = sf.composite_element_id
       and sf.array_id = a.array_id
     order by microarrays
";

# print STDERR "\nmicroarraysSql = \n$microarraysSql\n\n";

  my $microarraysQuery =
    GUS::ReportMaker::Query->new($microarraysSql,
				 [$microarraysCol,
				 ]);

################################################################################
# mr4Query

  my $mr4Col =
    GUS::ReportMaker::DefaultColumn->new("MR4_Reagents",
					 "MR4 Reagents");
  push(@columns, $mr4Col);

  my $mr4Sql =
    "select distinct tmp.na_feature_id,
            dbr.secondary_identifier || ':' || dbr.primary_identifier
     as mr4_reagents
     from $tempTable tmp, dots.dbrefnafeature rnf, sres.dbref dbr 
     where tmp.na_feature_id = rnf.na_feature_id 
     and rnf.db_ref_id = dbr.db_ref_id 
     and dbr.external_database_release_id in
       (select external_database_release_id
        from sres.externalDatabaseRelease
        where external_database_id=448)
";

# print STDERR "\nmr4Sql = \n$mr4Sql\n\n";

  my $mr4Query =
    GUS::ReportMaker::Query->new($mr4Sql,
				 [$mr4Col,
				 ]);

################################################################################
# orthologGroupQuery

  my $orthologGroupCol =
    GUS::ReportMaker::DefaultColumn->new("Ortholog_Group",
					 "Ortholog/Paralog group to which this gene belongs");
  push(@columns, $orthologGroupCol);

  my $orthologGroupSql =
    "select distinct tmp.na_feature_id, asg.aa_sequence_group_id as ortholog_group,
            asg.number_of_members, asg.min_match_identity * 100,
            asg.max_match_identity * 100, asg.min_match_length, asg.max_match_length
     from $tempTable tmp, plasmodb_42.plasmodb_genes gf,
          dots.aasequencesequencegroup assg1, dots.aasequencegroup asg
     where tmp.na_feature_id = gf.na_feature_id
       and gf.aa_sequence_id = assg1.aa_sequence_id
       and assg1.aa_sequence_group_id = asg.aa_sequence_group_id
       and asg.aa_seq_group_experiment_id = 4813
";

# print STDERR "\northologGroupSql = \n$orthologGroupSql\n\n";

  my $orthologGroupQuery =
    GUS::ReportMaker::Query->new($orthologGroupSql,
				 [$orthologGroupCol,
				 ]);

################################################################################
# transmembraneQuery

  my $transmembraneCol =
    GUS::ReportMaker::DefaultColumn->new("Transmembrane_Domains",
					 "Description and location of predicted transmembrane domains");
  push(@columns, $transmembraneCol);

  my $transmembraneSql =
    "select distinct tmp.na_feature_id,
            paf.algorithm_name || ':' || paf.description || '(' || to_char(aal.start_min) ||
            '-' || to_char(aal.end_max) || ')' as transmembrane_domains
     from $tempTable tmp, plasmodb_42.plasmodb_genes gf, dots.PredictedAAFeature paf, dots.AALocation aal
     where tmp.na_feature_id = gf.na_feature_id
       and gf.aa_sequence_id = paf.aa_sequence_id
       and paf.aa_feature_id = aal.aa_feature_id
       and paf.name = 'TMhelix'
     order by transmembrane_domains
";

# print STDERR "\ntransmembraneSql = \n$transmembraneSql\n\n";

  my $transmembraneQuery =
    GUS::ReportMaker::Query->new($transmembraneSql,
				 [$transmembraneCol,
				 ]);

################################################################################
# signalQuery

  my $signalCol =
    GUS::ReportMaker::DefaultColumn->new("Signal_Sequences",
					 "Location and prediction algorithm of predicted signal domains");
  push(@columns, $signalCol);

  my $signalSql =
    "select distinct tmp.na_feature_id,
            spf.algorithm_name || ':' || to_char(aal.start_min) || '-'
            || to_char(aal.end_max) as signal_sequences
     from $tempTable tmp, plasmodb_42.plasmodb_genes gf,
          dots.SignalPeptideFeature spf, dots.AALocation aal
     where tmp.na_feature_id = gf.na_feature_id
       and gf.aa_sequence_id = spf.aa_sequence_id
       and spf.aa_feature_id = aal.aa_feature_id
     order by signal_sequences
";

# print STDERR "\nsignalSql = \n$signalSql\n\n";

  my $signalQuery =
    GUS::ReportMaker::Query->new($signalSql,
				 [$signalCol,
				 ]);

################################################################################
# epitopeQuery

  my $epitopeCol =
    GUS::ReportMaker::DefaultColumn->new("Epitopes",
					 "Epitope type, haplotype and sequence of predicted epitopes");
  push(@columns, $epitopeCol);

  my $epitopeSql =
    "select tmp.na_feature_id, ef.type || ' epitope (haplotype ' || ef.haplotype || '): ' ||
            dbms_lob.substr(aas.sequence, (al.end_max - al.start_min + 1), al.start_min ) as epitopes
     from $tempTable tmp, plasmodb_42.plasmodb_genes gf, dots.epitopeFeature ef,
          dots.aalocation al, dots.aaSequence aas
     where tmp.na_feature_id = gf.na_feature_id
       and gf.aa_sequence_id = ef.aa_sequence_id
       and ef.aa_feature_id = al.aa_feature_id
       and ef.aa_sequence_id = aas.aa_sequence_id
     order by epitopes
";

# print STDERR "\nepitopeSql = \n$epitopeSql\n\n";

  my $epitopeQuery =
    GUS::ReportMaker::Query->new($epitopeSql,
				 [$epitopeCol,
				 ]);

################################################################################
# make report

  return GUS::ReportMaker::Report->new("PlasmoDB Unique Gene ID",
				      [$plasmodbGenesQuery,
				       $notesQuery,
				       $ecQuery,
				       $goFuncQuery,
				       $goProcQuery,
				       $goComponentQuery,
				       $splicedNaSeqQuery,
				       $predictedProteinSeqQuery,
				       $exonLocationQuery,
				       $microarraysQuery,
				       $mr4Query,
				       $orthologGroupQuery,
				       $transmembraneQuery,
				       $signalQuery,
				       $epitopeQuery,
				      ],
				      \@columns);
}


1;

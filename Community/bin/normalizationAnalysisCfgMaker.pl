#!/usr/bin/perl

use strict;

use RAD::MR_T::MageImport::ServiceFactory;

use Error qw(:try);

use XML::Simple;
use Getopt::Long;

=pod

=head1 Purpose

Create a config file for GUS::Community::Plugin::InsertBatchRadAnalysis from a MageTab file.  

This is used for 2 channel processed data where there is a 1:1 relationship between the assay and the processed result.  (ie. NO Averaging of Dye Swaps)

=cut

my ($help, $mageTabFile, $directory, $fileTranslator);

my $RESULT_TABLE = 'RAD::DataTransformationResult';

&GetOptions('help|h' => \$help,
            'mageTab=s' => \$mageTabFile,
            'directory_prefix=s' => \$directory,
            'file_translator=s' => \$fileTranslator,
            );

&usage() if($help);
&usage() unless(-e $mageTabFile && -d $directory);

if($fileTranslator) {
  die "File Translator $fileTranslator doesn't exist" unless(-e $fileTranslator);
}

my $config = {'service' => {
                            'reader' => {
                                         'class' => 'RAD::MR_T::MageImport::Service::Reader::MageTabReader',
                                         'property' => {
                                                        'mageTabFile' => {
                                                                          'value' => $mageTabFile
                                                                         }
                                                       }
                                        },
                            'processor' => {
                                            'decorProperties' => {
                                                                  'modules' => {
                                                                                'value' => 'NamingAcqAndQuan'
                                                                               }
                                                                 },
                                            'baseClass' => 'RAD::MR_T::MageImport::Service::Processor'
                                           },
                            'translator' => {
                                             'class' => 'GUS::Community::RadAnalysis::MageToRadAnalysisTranslator',
                                             'property' => {}
                                            },
                            'validator' => {
                                            'decorProperties' => {
                                                                  'rules' => {
                                                                              'value' => 'AssayHasContact.pm,AssayHasLexAndNoHangingLex.pm,NoHangingBioMaterials.pm,ProtocolHasMgedType.pm,StudyHasContactAndNameAndDescription.pm'
                                                                             }
                                                                 },
                                            'baseClass' => 'RAD::MR_T::MageImport::Service::Validator'
                                           }
                           }
             };


try {
  my $serviceFactory = RAD::MR_T::MageImport::ServiceFactory->new($config);
  my $reader =  $serviceFactory->getServiceByName('reader');

  my $docRoot = $reader->parse();

  if(my $processor = $serviceFactory->getServiceByName('processor')) {
    $processor->process($docRoot);
  }

  my $translator = $serviceFactory->getServiceByName('translator');

  my $quantHash = $translator->mapAll($docRoot);

  &printXml($quantHash);

} catch Error with {
  my $e = shift;

  print STDERR $e->stacktrace();
  exit;
};

#--------------------------------------------------------------------------------

sub printXml {
  my ($quantHash) = @_;

  my $xml = "<plugin>\n";

  foreach my $uri (keys %$quantHash) {
    my $arrayDesign = $quantHash->{$uri}->{array_design};
    my $studyName = $quantHash->{$uri}->{study_name};
    my $protocolName = $quantHash->{$uri}->{protocol_name};
    my $parameterValues = $quantHash->{$uri}->{parameter_values};
    my $quantificationNames = $quantHash->{$uri}->{quantification_names};
    my $assayName = $quantHash->{$uri}->{assay_name};

    my $dataFile = $directory . "/" . $uri;
    unless(-e $dataFile) {
      die "DataFile $dataFile does not exist";
    }

    my $lgName = $assayName ." quantifications";
    my $analysisName = "Pre-processing of $assayName";

    $xml .=  "  <process class=\"GUS::Community::RadAnalysis::Processor::GenericAnalysis\">
    <property name=\"analysisName\" value=\"$analysisName\"/>
    <property name=\"dataFile\" value=\"$dataFile\"/>
    <property name=\"fileTranslatorName\" value=\"$fileTranslator\"/>

    <property name=\"arrayDesignName\" value=\"$arrayDesign\"/>
    <property name=\"studyName\" value=\"$studyName\"/>
    <property name=\"resultView\" value=\"$RESULT_TABLE\"/>
    <property name=\"protocolName\" value=\"$protocolName\"/>     
";


    if(scalar @$parameterValues > 0) {

  $xml .= "    <property name=\"paramValues\">
";

    foreach my $parameterValue (@$parameterValues) {
      my $parameterName = $parameterValue->getParameterName();
      my $value = $parameterValue->getValue();

      $xml .= "      <value>$parameterName|$value</value>\n";
    }
    $xml .= "    </property>
";
}

    $xml .= "    <property name=\"quantificationInputs\">\n";

    foreach my $quantName (@$quantificationNames) {
      $xml .= "      <value>$lgName|$quantName</value>\n";
    }

    $xml .= "    </property>
  </process>\n\n";

  }

  $xml .= "</plugin>\n";

  print STDOUT $xml;
}

#--------------------------------------------------------------------------------

sub usage {
  my ($e) = @_;

  print STDERR "ERROR:  $e\n" if($e);
  print STDERR "usage:  perl normalizationAnalysisCfgMaker.pl --mageTab <FILE> --directory_prefix <DIR> [--file_translator <FILE>]\n";
  exit;
}

1;

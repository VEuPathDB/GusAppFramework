package GUS::ObjRelP::Generator::JavaWrapperGenerator;

@ISA = qw (GUS::ObjRelP::Generator::WrapperGenerator);

use strict;
use GUS::ObjRelP::Generator::WrapperGenerator;

sub new{
    my ($class, $generator, $schemaName, $tableName, $tableGenerator) = @_;
    
    my $self=GUS::ObjRelP::Generator::WrapperGenerator->new($generator, $schemaName, $tableName, $tableGenerator);
    bless $self, $class;
    
    $self->{modelPackagePrefix} = "org.gusdb.model";
    $self->{objreljPackagePrefix} = "org.gusdb.objrelj";
    
    return $self;
}

sub generate {
    my($self, $newOnly) = @_;

    my $dir = $self->{generator}->{targetDir};
    my $file = "$dir/$self->{schemaName}/$self->{tableName}.java";
    return if ($newOnly && -e $file);
    open(F,">$file") || die "Can't open file $file for writing";
    print F $self->_genHeader() . $self->_genConstructor() . "\n} // $self->{tableName}\n";
    close(F);
}

sub _genHeader {
    my ($self) = @_;
    my $modelPackagePrefix = $self->{modelPackagePrefix};
    my $package = $modelPackagePrefix . '.' . $self->{schemaName};
    my $fileDest = "hand_edited/$self->{schemaName}/$self->{tableName}.java.man";

    my $header = <<END_HEADER; 
package ${package};

/** 
 * $self->{tableName}.java
 *
 * WARNING: THIS FILE HAS BEEN AUTOMATICALLY GENERATED AND SHOULD NOT BE EDITED.
 *
 * If you wish to make changes to the class, copy this file to $fileDest
 * (if that file does not already exist).  Make your changes to the .man 
 * file and then regenerate the GUS Java objects.
 *
 * \@author GUS::ObjRelP::Generator
*/

import java.sql.*;
import java.util.*;
import java.math.*;
import java.util.Date;
import org.gusdb.objrelj.*;

END_HEADER
    
    return $header;
}

sub _genConstructor {
    my ($self) = @_;
    my $output = "";
    
    my $name = $self->{tableName};
    $output .= "public class $name extends $name"."_Row {\n\n";
    $output .= "    //Empty Constructor; used in GUSRow.createGUSRow()\n";
    $output .= "    public " . $name . "(){};\n\n";
    $output .= "    // Constructor that creates a new GUSRow that is not in the database but can be submitted there.\n";
    $output .= "    public " . $name . "(ServerI server, String sessionId){\n";
    $output .= "    \tsuper(server, sessionId);\n";
    $output .= "    }\n\n";



#    $output .= "    // Constructor\n";
#    $output .= "    public $name () {}\n\n";
    return $output;
}

1;

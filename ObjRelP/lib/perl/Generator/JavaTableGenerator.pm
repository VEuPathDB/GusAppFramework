package GUS::ObjRelP::Generator::JavaTableGenerator;

@ISA = qw (GUS::ObjRelP::Generator::TableGenerator);

use strict;

sub new{
    my ($class, $generator, $schemaName, $tableName, $tableGenerator) = @_;
    
    my $self=GUS::ObjRelP::Generator::TableGenerator->new($generator, $schemaName, $tableName, $tableGenerator);
    bless $self, $class;
    
    $self->{modelPackagePrefix} = "org.gusdb.model";
    $self->{objreljPackagePrefix} = "org.gusdb.objrelj";
    
    return $self;
}

sub generate {
    my($self, $newOnly) = @_;
    
    my $dir = $self->{generator}->{targetDir};
    
    my $file = "$dir/$self->{schemaName}/$self->{tableName}_Table.java";
    
    return if ($newOnly && -e $file);
    
    open(F,">$file") || die "Can't open table file $file for writing";

    print F $self->_genHeader() . $self->_genConstructor() .  $self->_genDefaultParams() . "\n\n}\n";


    close(F);
}


sub _genHeader{
    my ($self) = @_;
    my $modelPackagePrefix = $self->{modelPackagePrefix};
    my $objreljPackagePrefix = $self->{objreljPackagePrefix};

    my $output = "package $modelPackagePrefix." . $self->{schemaName} . ";\n\n";
    $output .= "import java.util.*;\n";
    $output .= "import  $objreljPackagePrefix.*;\n\n";
    $output .= "public class ". $self->{tableName} . "_Table extends GUSTable {\n\n";
    return $output;
}

sub _genConstructor {
    my($self) = @_; 
    my $schemaName = $self->{schemaName};
    my $tableName = $self->{tableName};
    my $output = "public $tableName" . "_Table () {\n\n";
    
    $output .= "  super(\"$schemaName\", \"$tableName\");\n";
    $output .= "  setDefaultParams();\n";
    $output .= "}\n\n";
    return $output;
}

sub _genDefaultParams {
    my($self) = @_;
    my $tableName = $self->{tableName};
    my $dbiTable = $self->{table};#maybe should be realtable?
    my $realTableName = $self->{generator}->getRealTableName($self->{fullName});
 
    my $output = "public void setDefaultParams () \{\n";
    
    my $keys = $dbiTable->getPrimaryKeyAttributes();
    my $primaryKeyName = $keys->[0]; 
    $output .= $self->_getTableAttributeInfo();
    $output .= $self->_createSetChildRelations();
    $output .= $self->_createSetParentRelations();
    

    $output .= "  setImpTableName(\"$realTableName\");\n\n";
    my $hasSeq = "false"; 
    my $isView = "false";
    if ($dbiTable->hasSequence()){$hasSeq = "true";} 
    if ($dbiTable->isView()){$isView = "true";}
    $output .= "  setIsView($isView);\n\n"; 
    $output .= "  setHasSequence($hasSeq);\n\n";
    $output .=    "\n setPrimaryKeyName(\"$primaryKeyName\");\n \n";
    $output .= '  setTableId('.$dbiTable->getTableId().");\n\n"; 
    $output .= "}\n\n";
    return $output;
    
}
#add all this table's children to the GUSTable's hash of child relations
sub _createSetChildRelations{
    my($self) = @_;
    
    my $output;
    my $tableName = $self->{tableName};
    
    $output .= "   Hashtable childRels = new Hashtable(); \n";
    $output .= "   try{\n";
    my $children = $self->_getChildren();
    foreach my $child (@$children) {
	my ($childSchema, $childTable);
	
	my ($fktab,$selfcol,$fkcol) = @{$child}; 
	($childSchema, $childTable) = $self->_cutFullQualifiedName($fktab);
		
	$output .=  "          childRels.put(\"$childTable\", new GUSTableRelation(\"$tableName\",\"$childTable\", \"$selfcol\", \"$fkcol\"));\n";
    }
    $output .= "          }";
    $output .= "          catch (Exception e){}\n";
    $output .= "          setChildRelations(childRels);";
    return $output;
}

#add all this table's parents to the GUSTable's hash of parent relations
sub _createSetParentRelations{
    my($self) = @_;
    
    my $output;
    my $tableName = $self->{tableName};
    
    $output .= " \n  Hashtable ParentRels = new Hashtable(); \n";
    $output .= "   try{\n";
    my $parents = $self->_getParents();

    foreach my $parent (@$parents) {
	my ($parentSchema, $parentTable);

	my ($pktable, $selfcol, $pkcol) = @{$parent};
	($parentSchema, $parentTable) = $self->_cutFullQualifiedName($pktable);
	
	$output .=  "          ParentRels.put(\"$parentTable\", new GUSTableRelation(\"$parentTable\",\"$tableName\", \"$pkcol\", \"$selfcol\"));\n";
	#print STDERR "fk table is " . $fktab . " selfcol is " . $selfcol . "fkcol is " . $fkcol . "\n";
    }
    $output .= "          }";
    $output .= "          catch (Exception e){}\n";
    $output .= "          setParentRelations(ParentRels);\n\n";  
    return $output;
# SJD: WILL NEED TO ADD CODE TO CREATE SPECIAL RELS FOR JAVA!!!
#  $temp .= $self->createSpecialRels($tn);   

}



#retrieve all oracle info for a particular GUSRow attribute
#write java method to add it to the GUSTable's hash of attribute information 
sub _getTableAttributeInfo {
    my($self) = @_;
    my $output = "";
    my $addTableInfo;
    my $dbiTable = $self->{table};
    my @final_att_list = $self->_getUniqueAttributes();

    my $allAttInfo = $dbiTable->getAttributeInfo();
    my $primaryKeys = $dbiTable->getPrimaryKeyAttributes();
    
    my $attHash = {};
    foreach my $att (@$allAttInfo) {
	my $name = $att->{'col'};
	$attHash->{$name} = $att;
    }

    return undef unless @final_att_list;
    foreach my $att ( @final_att_list ) {
	my $attInfo = $attHash->{$att};
	
	# convert attribute oracle type to Java type
	my $javaType = $self->_oracleTypeConverter( $attInfo, $att );
	
	
	$addTableInfo .= $self->_createJavaTALine($att, $attInfo, $javaType);

    }    
    $output .= $self->_createJavaSetTAInfo($addTableInfo);
    
    return $output;
}


############################################################################
####                    Private utility methods                         ####
############################################################################

#Take oracle type and return Java equivalent
sub _oracleTypeConverter {
    my ($self, $attInfo, $att) = @_;
    my $newType;
    my $oraType = $attInfo->{'type'};
    my $oraPrec = $attInfo->{'prec'};
    my $oraScale = $attInfo->{'scale'};
    my $oraLen = $attInfo->{'length'};
        
    if ($oraType eq "NUMBER") {
	if ($oraScale <= 0) {         #integer
	    if ($oraPrec == 1){
		$newType .= "Boolean";}
	    elsif ($oraPrec > 1 && $oraPrec <= 4){
		$newType .= "Short";}
	    elsif ($oraPrec > 4 && $oraPrec <= 9){
		$newType .= "Integer";}
	    elsif ($oraPrec > 9 && $oraPrec <= 19){
		$newType .= "Long";}
	    else {$newType .= "BigDecimal";}
	}
	else{                        #fraction
	    if ($oraScale > 0 && $oraScale <= 7){    
		$newType .= "Float";}
	    elsif ($oraScale > 7 && $oraScale <= 16){
		$newType .= "Double";}
	    else {$newType .= "BigDecimal";} 
	}
    }
    elsif ($oraType eq "DATE"){
	if ($oraLen == 7){
	    $newType .= "Date";}
	elsif ($oraLen == 6){
	    $newType .= "Time";}
	else { $newType .= "Timestamp";}
    }
    elsif ($oraType eq "FLOAT"){
	$newType .= "BigDecimal"}

    elsif ($oraType eq "VARCHAR2" || $oraType eq "CHAR" || $oraType eq "LONG"){ 
	$newType .= "String";}

    elsif ($oraType eq "CLOB"){
	$newType .= "Clob";}

    elsif ($oraType eq "BLOB"){
	$newType .= "Blob";}    

    elsif ($oraType eq "RAW" || $oraType eq "LONGRAW"){
	$newType .= "byte[]";}

    else {$newType .= "notdefyet";}
# print STDERR "name is $att type is $oraType, precision is $oraPrec, scale is $oraScale,  length  $oraLen, javatype is $newType\n" ;

    return $newType;
}

sub _createJavaTALine {
    my ($self, $att, $attInfo, $javaType) = @_; #more?
    my $line;
    my $oraType = $attInfo->{'type'};
    my $prec = $attInfo->{'prec'};
    my $len = $attInfo->{'length'};
    my $scale = $attInfo->{'scale'};
    my $zeroPrec;
    my $zeroScale;
    
    if ($prec){}
    else {$prec = -1;}
    if ($scale){}
    else {$scale = -1;}
    if ($javaType eq "BigDecimal"){
	$line .= "TableAtts.put(\"$att\", new GUSTableAttribute(\"$att\", \"$oraType\", \"java.math.$javaType\", $prec, $len, $scale, false, false) );\n";}
    else{
	$line .= "TableAtts.put(\"$att\", new GUSTableAttribute(\"$att\", \"$oraType\", \"java.lang.$javaType\", $prec, $len, $scale, false, false) );\n";}
    
    
    return $line;
}

#overhead for setting the GUSTable's hash of attribute information
sub _createJavaSetTAInfo{
    my($self, $allInfo) = @_;
    my $line;
    $line .= "\n\nHashtable TableAtts = new Hashtable(); \n
      try {
     $allInfo
         }
      catch (Exception e) {}\n   ";
    $line .= "setAttInfo(TableAtts);\n\n";
    return $line;
}


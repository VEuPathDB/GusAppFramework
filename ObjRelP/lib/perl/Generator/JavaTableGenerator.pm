package GUS::ObjRelP::Generator::JavaTableGenerator;

@ISA = qw (GUS::ObjRelP::Generator::TableGenerator);

use strict;
use GUS::ObjRelP::Generator::TableGenerator;

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
    print F $self->_genHeader() . $self->_genConstructor() .  $self->_genDefaultParams() . "\n} // $self->{tableName}_Table\n";
    close(F);
}

sub _genHeader{
    my ($self) = @_;
    my $modelPackagePrefix = $self->{modelPackagePrefix};
    my $objreljPackagePrefix = $self->{objreljPackagePrefix};

    my $output = "package $modelPackagePrefix." . $self->{schemaName} . ";\n\n";
    $output .= "import java.util.*;\n";
    $output .= "import $objreljPackagePrefix.*;\n\n";
    $output .= "public class ". $self->{tableName} . "_Table extends GUSTable {\n\n";
    return $output;
}

sub _genConstructor {
    my($self) = @_; 
    my $schemaName = $self->{schemaName};
    my $tableName = $self->{tableName};
    my $output = <<END_CONSTRUCTOR;
    public ${tableName}_Table () 
    {
	super("$schemaName", "$tableName");
        setDefaultParams();
    }

END_CONSTRUCTOR

    return $output;
}

sub _genDefaultParams {
    my($self) = @_;
    my $tableName = $self->{tableName};
    my $dbiTable = $self->{table};#maybe should be realtable?
    my $realTableName = $self->{generator}->getRealTableName($self->{fullName});
 
    my $keys = $dbiTable->getPrimaryKeyAttributes();
    my $primaryKeyName = $keys->[0]; 

    my $hasSeq = ($dbiTable->hasSequence()) ? "true" : "false"; 
    my $isView = ($dbiTable->isView()) ? "true" : "false";
    my $tableId = $dbiTable->getTableId();

    my $output = <<END_DFLT_PARAMS1;
    public void setDefaultParams ()
    {
END_DFLT_PARAMS1

    $output .= $self->_getTableAttributeInfo();
    $output .= $self->_createSetChildRelations();
    $output .= $self->_createSetParentRelations();

    $output .= <<END_DFLT_PARAMS2;

        // Other table properties
	this.ownerName = "$self->{schemaName}";
	this.tableName = "$self->{tableName}";
        this.isView = $isView;
	this.hasSequence = $hasSeq;
	this.primaryKey = "$primaryKeyName";
        this.tableId = $tableId;
    }
END_DFLT_PARAMS2

    return $output;
}

#add all this table's children to the GUSTable's hash of child relations
sub _createSetChildRelations{
    my($self) = @_;
    
    my $output;
    my $schemaName = $self->{schemaName};
    my $tableName = $self->{tableName};
    my $children = $self->_getChildren();
    
    $output .= "        // Child relationships (tables and views that reference this one) \n";
    $output .= "        try {\n";

    foreach my $child (@$children) {
	my ($childSchema, $childTable);
	my ($fktab,$selfcol,$fkcol) = @{$child}; 
	($childSchema, $childTable) = $self->_cutFullQualifiedName($fktab);
	$output .=  "	    ";
	$output .= "addChildRelation(new GUSTableRelation(\"$schemaName\",\"$tableName\",\"$selfcol\",\"$childSchema\",\"$childTable\",\"$fkcol\"), ";
	$output .= "\"$childSchema\", \"$childTable\", \"$fkcol\");\n";
    }
    $output .= "        }\n";
    $output .= "        catch (Exception e) {}\n";
    $output .= "\n";

    return $output;
}

#add all this table's parents to the GUSTable's hash of parent relations
sub _createSetParentRelations{
    my($self) = @_;
    
    my $output;
    my $schema = $self->{schemaName};
    my $tableName = $self->{tableName};
    my $parents = $self->_getParents();
    
    $output .= "        // Parent relationships (tables and views referenced by this one) \n";
    $output .= "        try { \n";

    foreach my $parent (@$parents) {
	my ($parentSchema, $parentTable);
	my ($pktable, $selfcol, $pkcol) = @{$parent};
	($parentSchema, $parentTable) = $self->_cutFullQualifiedName($pktable);
	$output .=  "	    ";
	$output .= "addParentRelation(new GUSTableRelation(\"$parentSchema\",\"$parentTable\",\"$pkcol\",\"$schema\",\"$tableName\",\"$selfcol\"), ";
	$output .= "\"$parentSchema\", \"$parentTable\", \"$selfcol\");\n";

	#print STDERR "fk table is " . $fktab . " selfcol is " . $selfcol . "fkcol is " . $fkcol . "\n";
    }
    $output .= "        }\n";
    $output .= "        catch (Exception e) {}\n";
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
    if ($javaType eq "BigDecimal") {
	$line .= "	    ";
	$line .= "tableAtts.put(\"$att\", new GUSTableAttribute(\"$att\", \"$oraType\", \"java.math.$javaType\", $prec, $len, $scale, false, false) );\n";
    } else {
	$line .= "	    ";
	$line .= "tableAtts.put(\"$att\", new GUSTableAttribute(\"$att\", \"$oraType\", \"java.lang.$javaType\", $prec, $len, $scale, false, false) );\n";
    }
    
    return $line;
}

#overhead for setting the GUSTable's hash of attribute information
sub _createJavaSetTAInfo{
    my($self, $allInfo) = @_;
    my $line = <<END_SET_TA;
	// Attributes (columns) of the table
	Hashtable tableAtts = new Hashtable();
        try {
$allInfo
        } catch (Exception e) {}
        this.attributeInfo = tableAtts;

END_SET_TA

    return $line;
}


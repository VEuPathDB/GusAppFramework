package GUS::ObjRelP::Generator::JavaRowGenerator;

@ISA = qw (GUS::ObjRelP::Generator::RowGenerator);
use GUS::ObjRelP::Generator::RowGenerator;

use strict;

sub new{
    my ($class, $generator, $schemaName, $tableName, $tableGenerator) = @_;
    
    my $self=GUS::ObjRelP::Generator::RowGenerator->new($generator, $schemaName, $tableName, $tableGenerator);
    bless $self, $class;
    
    $self->{modelPackagePrefix} = "org.gusdb.model";
    $self->{objreljPackagePrefix} = "org.gusdb.objrelj";
    
    return $self;
}

sub generate {
    my($self, $newOnly) = @_;
    
    my $dir = $self->{generator}->{targetDir};
    
    my $file = "$dir/$self->{schemaName}/$self->{tableName}_Row.java";
    
    return if ($newOnly && -e $file);
    
    open(F,">$file") || die "Can't open file $file for writing";
    print F $self->_genHeader() . $self->_genAccessors()  .  "} // $self->{tableName}_Row\n";
    close(F);
}

sub _genHeader{
    my ($self) = @_;
    my ($parentSchema, $parentName);
    my $modelPackagePrefix = $self->{modelPackagePrefix};
    my $objreljPackagePrefix = $self->{objreljPackagePrefix};
    
    my $fullParent = $self->_getParentTable();
    if ($fullParent){
	($parentSchema, $parentName) = $self->_cutFullQualifiedName($fullParent);
    }
    
    my $output =  "package $modelPackagePrefix.$self->{schemaName};\n\n";
    
    $output .= "import $modelPackagePrefix.$parentSchema.$parentName;\n" if $fullParent;
    $output .= "import $objreljPackagePrefix.*;\n\n";
    
    $output .= "import java.util.*;\n";
    $output .= "import java.sql.*;\n";   
    $output .= "import java.math.*;\n";
    $output .= "import java.util.Date;\n\n";
    $output .= "import org.gusdb.model.DoTS.*;\n";
    $output .= "import org.gusdb.model.Core.*;\n";
    $output .= "import org.gusdb.model.SRes.*;\n";
#    $output .= "import org.gusdb.model.TESS.*;\n";
    $output .= "import org.gusdb.model.RAD3.*;\n\n";

    $output .= $self->_genClassDeclaration();
    $output .= $self->_genConstructor();

    return $output;
} 

sub _genClassDeclaration{
    my ($self) = @_;
 
    my $output = "";
       
    my $fullParent = $self->_getParentTable();
    if ($fullParent){
	my ($parentSchema, $parentName) = $self->_cutFullQualifiedName($fullParent);
	$output .= "public class $self->{tableName}"."_Row extends $parentName {\n\n";
    } 
    else {
	$output .= "public class $self->{tableName}"."_Row extends GUSRow {\n\n";
    }
    return $output;
}

sub _genConstructor {
    my ($self) = @_;
    
    my $output = "";
    $output .= "    //Empty Constructor; used in GUSRow.createGUSRow()\n";
    $output .= "    public " . $self->{tableName} . "_Row(){};\n\n";
    $output .= "    // Constructor that creates a new GUSRow that is not in the database but can be submitted there.\n";
    $output .= "    public " . $self->{tableName} . "_Row(ServerI server, String sessionId){\n";
    $output .= "    \tsuper(server, sessionId);\n";
    $output .= "    }\n\n";
    return $output;
}
 
# method: _genAccessors
# arg 1: table name
# outputs the set and get methods for the attributes of the table.  If the table is a true table, will just output
# setters and getters for all the attributes.  If it is a view will output methods only for those attributes
# not found in the parent.  Also outputs accessor methods for foreign key parents and children of the table.
# output: string that is created.
sub _genAccessors {
    my ($self) = @_;
    my $output;

    my @parentsAndAttributesList = $self->_getUniqueAttributes();
    
    my $tableObject = $self->{generator}->getTable($self->{fullName}, 1); 
    my $allAttInfo  = $tableObject->getAttributeInfo();

    # Index column/attribute info. by name
    #
    my $attInfoHash = {};
    foreach my $att (@$allAttInfo) {
	my $name = $att->{'col'};
	$attInfoHash->{$name} = $att;
    }
    unless (@parentsAndAttributesList){
	return undef;
    }
   
    my ($finalAttHash, $parentHash) = $self->_splitFksAndAttributes(\@parentsAndAttributesList, $attInfoHash);
    my ($accessorOutput, $setAllAtts) = $self->_createAttributeAccessors($finalAttHash);
    $output .= $accessorOutput; 

    my ($parentAccessorOutput, $setAllParentAtts) = $self->_createParentAccessors($parentHash);
    $output .= $parentAccessorOutput;
    $output .= $self->_createChildAccessors();
    my $parent = $self->_getParentTable( );

    my $pkAccessors;
    my $setAllSuperAtts;
    my $setAllFkSuperAtts;

    if ($parent){
	($pkAccessors, $setAllSuperAtts, $setAllFkSuperAtts) = $self->_addSuperSets();
    } 
    else{
	$pkAccessors .= $self->_genPkAccessors($finalAttHash) if !$parent; 
	#if has parent, parent will have pk att 
    }
    
    # Abstract methods from GUSRow: setAttributesFromResultSet and getTable
    #
    $output .= "    // ----------------------------------------------\n";
    $output .= "    // GUSRow abstract methods\n";
    $output .= "    // ----------------------------------------------\n";
    $output .= "\n";
    $output .= $self->_createJavaSetAttsFromHT($setAllAtts, $setAllSuperAtts, $setAllParentAtts, $setAllFkSuperAtts);
    $output .= $self->_createJavaGetTable();

    $output .= $pkAccessors;

    return $output;
}

sub _genPkAccessors{

    my ($self, $attHash) = @_;

    my $tableObject = $self->{generator}->getTable($self->{fullName}, 1);     
    
    my $primaryKeys = $tableObject->getPrimaryKeyAttributes();
    my $primaryKeyName = $primaryKeys->[0];
    
    my $primaryKeyInfo = $attHash->{$primaryKeyName};
    
    my $primKeyJavaType = $self->_oracleTypeConverter( $primaryKeyInfo, $primaryKeyName);
    my $valueMethod = $self->_getValueMethodFromJavaType($primKeyJavaType);

    my $output = "public long getPrimaryKeyValue(){\n";
    $output .= "\t" . $primKeyJavaType . " pk" . $primaryKeyName . " = get" . $self->_capAttName($primaryKeyName) . "();\n";
    $output .= "\tif (pk" . $primaryKeyName . " == null){ return -1; }\n";
    $output .= "Long pk = new Long(pk" . $primaryKeyName . $valueMethod . ");\n";
    $output .= "return pk.longValue();\n";
    $output .= "}\n\n"; 
    
    $output .= "protected void setPrimaryKeyValue(Long pk)\n";
    $output .= "\tthrows ClassNotFoundException,InstantiationException, IllegalAccessException, SQLException{\n";

    
#    $output .= "\tString pkString = pk.toString();\n";
    $output .= "\tset". $self->_capAttName($primaryKeyName) . "(new " . $primKeyJavaType . "(pk" . $valueMethod .  "));\n";
    $output .= "}\n\n";
    
    return $output;
}


    
############################################################################
####                    Private utility methods                         ####
############################################################################
sub _createAttributeAccessors{

    my ($self, $attHash, $setAllAtts) = @_;
    my $setAllAtts = "";
    my $output = "";
    my $tableObject = $self->{generator}->getTable($self->{fullName}, 1); 
    my $primaryKeys = $tableObject->getPrimaryKeyAttributes();

    foreach my $att ( keys %$attHash){
	my $sub_name = $self->_capAttName( $att );
	
	if ($sub_name eq "Class") {
	    $sub_name = "myClass";
	}
	my $set = "set" . $sub_name;
	my $get = "get" . $sub_name;
	
	my $attInfo = $attHash->{$att};

	# convert attribute oracle type to Java type
	my $javaType = $self->_oracleTypeConverter( $attInfo, $att );

	# add line to setAttributesFromResultSet_aux
	$setAllAtts .= "	    ";                    # JC: these lines are in a 'try' block
	$setAllAtts .= $self->_createJavaHTLine($att, $set, $javaType, $primaryKeys, 0);

	## print the set, setInitial, and get methods
	$output .= "    // $att\n";
	
	# CLOB/BLOB columns
	if (($javaType eq "Clob") || ($javaType eq "Blob")) {
	    
	    # This attribute tracks what part of the CLOB/BLOB has actually been retrieved.
	    # If null then the whole CLOB/BLOB (if present) has been retrieved.
	    #
	    $output .= "    protected CacheRange ${att}_cached = null;\n\n";

	    # The SQL Clob and Blob types are only valid for the duration of the
	    # transaction in which they were created, so we'll only use them for 
	    # the setAttributesFromResultSet_aux method (above); for the standard
	    # get and set methods we'll use char[] and byte[] instead and these will
	    # be the datatypes used internally.

	    my $newJavaType = ($javaType =~ /clob/i) ? "char[]" : "byte[]";

	    # As with a regular attribute, the set method is assumed to set the
	    # *entire* value of the CLOB.
	    #
	    $output .= $self->_createJavaSetClobOrBlob($att, $set, $newJavaType, $primaryKeys);
	    
	    # Regular get() method should throw an exception if the entire CLOB/BLOB
	    # is not available in memory.
	    #
	    $output .= $self->_createJavaGetClobOrBlob($att, $get, $newJavaType);
	    $output .= $self->_createJavaSetClobOrBlobInitial($att, $set, $javaType, $newJavaType, $primaryKeys);
	} 

	# all other column types
	else {
	    $output .= $self->_createJavaSet($att, $set, $javaType, $primaryKeys);
	    $output .= $self->_createJavaGet($att, $get, $javaType);
	   # $output .= $self->_createJavaSetInitial($att, $set, $javaType, $primaryKeys);
	}
    }
    return ($output, $setAllAtts);
}

sub _createChildAccessors{

    my ($self) = @_;
    my $output = "//Child Objects\n";
    
    my $childRelations = $self->_getChildRelations();
    
    my $childHash = $self->_createChildHash($childRelations);
    my $duplicateChildren = $self->_findDuplicateChildren($childHash);
    
    foreach my $childKey (keys %$childHash){
	my ($childFkCol) = $childKey =~ /(\S+)\.\.\S+/;
	my $fullChildTable = $childHash->{$childKey};
	my ($childSchema, $childTable) = $self->_cutFullQualifiedName($fullChildTable);
	next if $childSchema eq "TESS";
	my $instanceName = $self->_createChildInstanceVar($childFkCol, $fullChildTable, $duplicateChildren);
	my $accessorName = $self->_createChildAccessorName($childFkCol, $fullChildTable, $duplicateChildren);

	my $packageChildTable = $self->_formatPackageTableName($childSchema, $childTable);

	$output .= "public void add" . $accessorName . "(" . $packageChildTable . " " .
	    lc($accessorName) ."){\n";
	$output .= "\t" . lc($accessorName) .  ".setParent(this, \"$instanceName\");\n";
 	$output .= "}\n";
	$output .= "public Vector get" . $accessorName . "List(){\n";
	$output .= "\t return getChildren(\"$instanceName\");\n";
	$output .= "}\n";
    }
    return $output;
}


#gets child relations for this table, except if this table is a superclass view, in which
#case it gets the child relations for the real Imp table which it is a view on.
sub _getChildRelations{
    my ($self) = @_;
    my $childRelations;
    my $table = $self->{generator}->getTable($self->{fullName} ,1);
    if ($table->isView()){

	my $fullRealTableName = $table->getRealTableName();
	my ($realTableSchema, $realTableName) = $self->_cutFullQualifiedName($fullRealTableName);

	my ($superClassViewName) = $realTableName =~ /(\S+)Imp$/;

	if ($superClassViewName eq $self->{tableName} && !$self->{generator}->{makeImpTables}){

	    my $realTable = $self->{generator}->getTable($fullRealTableName, 1);
	    $childRelations = $realTable->getChildRelations();
	}
	else {
	    $childRelations = $table->getChildRelations();
	}
    }
    return $childRelations;
}


sub _createChildInstanceVar{

    my ($self, $childFkCol, $fullChildTable, $duplicateChildren)= @_;
    my ($childSchema, $childTable) = $self->_cutFullQualifiedName($fullChildTable);
    my $instanceName = lc($childTable);
    if ($duplicateChildren->{$fullChildTable}){
	$instanceName .= "_IAmA_" . $childFkCol;
    }
    return $instanceName;
}

sub _createChildAccessorName{
    my ($self, $childFkCol, $fullChildTable, $duplicateChildren) = @_;
    my ($childSchema, $childTable) = $self->_cutFullQualifiedName($fullChildTable);
    my $accessorName = $childTable; #should put schema name here too  
    if ($duplicateChildren->{$fullChildTable}){
	$accessorName = $self->_handleDuplicateChild($childFkCol, $childTable);
    }
    return $accessorName;
}

sub _handleDuplicateChild{

    my ($self, $childFkCol, $childTable, $isAccessor) = @_;
       
    my $javaChildAtt = $self->_attributeToJavaName($childFkCol, 1);
    my $accessorName = $childTable . "_IAmA_" . lc($javaChildAtt);
    return $accessorName;
}


#returns a hash whose keys are a concatenation of the name of a child table and 
#the foreign key attributes from the child table to this table (separated by "..."),
#and whose values are the child tablenames (in GUS::Model::Schema::Table format)
sub _createChildHash{
    my ($self, $childRelations) = @_;
    my $childHash;
    foreach my $childRel(@$childRelations){
	
	my ($childSchema, $childTable);
	my ($fullChildTable, $childFkCol, $selfPkCol) = @{$childRel};
	if ($fullChildTable =~ /(\S+)Imp$/ && !$self->{generator}->{makeImpTables}){
	    $fullChildTable = $1;
	}
	#dtb: need unique key for each child while still preserving the child's fk column
	$childHash->{$selfPkCol . ".." . $fullChildTable} = $fullChildTable;

    }
    return $childHash;
}

#returns a hashtable whose keys are any children who have multiple foreign keys to the current table
#(each key is in GUS::Model::schema::table format)
sub _findDuplicateChildren{

    my ($self, $childHash) = @_;
    my $inverseChildHash;
    my $duplicateChildHash;
    foreach my $fkAtt (keys %$childHash){
	my $fullChildTable = $childHash->{$fkAtt};
	$inverseChildHash->{$fullChildTable}++;
	if ($inverseChildHash->{$fullChildTable} > 1){
	    $duplicateChildHash->{$fullChildTable} = 1;
	}
    }
    return $duplicateChildHash;
}


sub _createParentAccessors {
    
    my ($self, $parentHash) = @_;
    my $accessorOutput = "// Parent Objects\n";
    #instance variable declarations
    my $setAllParentAtts = "";
    foreach my $fkAtt( keys %$parentHash){
	my $parentTableName = $parentHash->{$fkAtt};
		my $accessorName = $self->_attributeToJavaName($fkAtt, 1);
	#set method
	$accessorOutput .= "public void set" . $accessorName . "(" . $parentTableName . " " . $fkAtt . "){\n";
	$accessorOutput .= "\tsetParent(" . $fkAtt . ", \"" . $fkAtt . "\");\n";
	$accessorOutput .= "}\n\n";
	my ($parentSchema, $parentTable) = $self->_cutPackageTableName($parentTableName);
	#get method
	
	$accessorOutput .= "public $parentTableName get" . $accessorName . "(boolean retrieveFromDb)\n";
	$accessorOutput .= "\tthrows GUSNoConnectionException, GUSNoSuchRelationException, GUSObjectNotUniqueException{\n";
	$accessorOutput .= "\tGUSTable parentTable = GUSTable.getTableByName(\"$parentSchema\", \"$parentTable\");\n";
	$accessorOutput .= "\treturn ($parentTableName)getParent(\"$fkAtt\", retrieveFromDb);\n";
	$accessorOutput .= "}\n\n";

	$setAllParentAtts .= $self->_createJavaParentHTLine($fkAtt, $parentTableName, 0);
    }
    return ($accessorOutput, $setAllParentAtts);
    
}


#given a list of all attributes for a table split into two hashtables representing the
#instance attributes and foreign key columns.
sub _splitFksAndAttributes {

    my ($self, $allAttributeList, $attInfoHash) = @_;

    my $attributeHash;
    my $fkHash;
    my $table = $self->{generator}->getTable($self->{fullName} ,1);
    my $parentRelations = $table->getParentRelations();
    
    #find all attributes that are foreign keys, including those that should go in a superclass
    foreach my $parentRel(@$parentRelations){
	my ($parentSchema, $parentTable);
	my ($fullParentTable, $selfFkCol, $parentPkCol) = @{$parentRel};
	if ($fullParentTable =~ /(\S+)Imp$/ && !$self->{generator}->{makeImpTables}){
	    $fullParentTable = $1;
	}
	($parentSchema, $parentTable) = $self->_cutFullQualifiedName($fullParentTable);
	my $packageParentTable = $self->_formatPackageTableName($parentSchema, $parentTable);
	$fkHash->{$selfFkCol} = $packageParentTable;
    }
    
    #any attribute that is not a foreign key goes into $attributeHash
    foreach my $attribute(@$allAttributeList){
	if (!$fkHash->{$attribute}){   #attribute is not a foreign key
	    $attributeHash->{$attribute} = $attInfoHash->{$attribute};
	}
    }
    
    #use the original list of attributes to trim foreign keys that should go in a superclass
    my $uniqueFkHash;
    foreach my $attribute (@$allAttributeList){
	if (!$attributeHash->{$attribute}){  #$attribute is a foreign key
	    $uniqueFkHash->{$attribute} = $fkHash->{$attribute};
	}
    }
    return ($attributeHash, $uniqueFkHash);
}

#change an attribute name into one that looks like it belongs in a java accessor
#method.  This entails cutting off the trailing "_id" of the name and converting
#'_' into the normal java case-style.
sub _attributeToJavaName {
    my ($self, $fkAtt) = @_;
    my $finalName = $fkAtt;
    if ($fkAtt =~ /(\S+)_id(\S*)/){

	$finalName = $1 . "_" . $2;
    }
    $finalName = $self->_capAttName($finalName);
    return $finalName;
}



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

#creates one line that will go in the setAttributesFromResultSet method.
#will be called once for every GUSRow attribute

sub _createJavaHTLine {
    my ($self, $RSatt, $RSset, $RSJavaType, $keys, $forSuperClass) = @_;
    
    my $line = "";
    my $super = "";
    if ($forSuperClass){
	$super = "super.";
    }
    if (($RSJavaType eq "Clob") || ($RSJavaType eq "Blob")){
	$line .= "$super" . "$RSset" . "_Retrieved(($RSJavaType)rowHash.get(\"$RSatt\"), specialCases);"
    }
    if ($RSJavaType eq "Boolean" || $RSJavaType eq "Short" || $RSJavaType eq "Long" ||
	$RSJavaType eq "Float" || $RSJavaType eq "Double" || $RSJavaType eq "Integer"){
	$line .= "BigDecimal $RSatt = (BigDecimal)rowHash.get(\"$RSatt\");\n";
	if ($RSJavaType eq "Boolean"){
	    $line .= "$super" . "set_Retrieved(\"$RSatt\", $RSatt != null ? new Boolean(intToBool($RSatt.intValue())) : null);\n";
	}
	else{
	    my $methodName = $self->_getValueMethodFromJavaType($RSJavaType);
	    $line .= "$super" . "set_Retrieved(\"$RSatt\", $RSatt != null ? new $RSJavaType($RSatt" . $methodName . ") : null);\n";
	}
    }
    elsif ($RSJavaType eq "byte{}") 
    {	
	$line .= "$super" . "set_Retrieved(\"$RSatt\", (byte[])rowHash.get(\"$RSatt\"));";
    }
    
    else{
	$line .=  "$super" . "set_Retrieved(\"$RSatt\", ($RSJavaType)rowHash.get(\"$RSatt\"));\n";
    }
    
    $line .= "\n";
    return $line;
}

sub _createJavaParentHTLine{
    #forSuperClass?
    my ($self, $att, $parentTableName, $forSuperClass) = @_;
    my $super = "";
    $super = "super." if $forSuperClass;
    my ($parentSchema, $parentTable) = $self->_cutPackageTableName($parentTableName);
    my $line = "";
    $line .= "BigDecimal $att = (BigDecimal)rowHash.get(\"$att\");\n";
    $line .= "$super" . "set_ParentRetrieved(\"$att\", GUSTable.getTableByName(\"$parentSchema\", \"$parentTable\"),\n";
    $line .= "                    $att.longValue());\n\n"; 
    

    return $line;

}


# create Java used to set the row's primary key value, in the case where that is
# the attribute being modified
sub _createJavaSetPrimKey {
    my ( $self, $Satt, $Sset, $SjavaType, $keys)= @_;
    my $primaryKeyName = $keys->[0];
    
    my $output = "Long pkValue = getPrimaryKeyValue();\n";
    $output .= "if (pkValue != null){\n";
    $output .= "throw new IllegalArgumentException(\"Row\'s GusRowId has already been set.\");\n";
    $output .= "}\n";

    return $output;
}

#gets the method name to return a primitive type from an object
sub _getValueMethodFromJavaType{

    my ($self, $javaType) = @_;
    my $method;
    
    if ($javaType eq "Long"){
	    $method = ".longValue()";
	}
    elsif ($javaType eq "Integer"){
	$method = ".intValue()";
    }
    elsif ($javaType eq "Short"){
	$method = ".shortValue()";
    }
    elsif ($javaType eq "Double"){
	$method = ".doubleValue()";
    }
    elsif ($javaType eq "Float"){
	$method = ".floatValue()";
    }
    
    elsif ($javaType eq "BigDecimal"){
	$method = ".longValue()";
    }

    return $method
}


#creates java method to set a GUSRow attribute
sub _createJavaSet {
    my ( $self, $Satt, $Sset, $SjavaType, $keys)= @_;
    my $primKeySet = $self->_createJavaSetPrimKey($Satt, $Sset, $SjavaType, $keys);

    my $line = <<END_SET1;
    public void $Sset ($SjavaType value)
        throws ClassNotFoundException,InstantiationException, IllegalAccessException, SQLException
    {
        set_Attribute("$Satt", value);
    }
END_SET1

      return $line;
}

#special-purpose version of _createJavaSet for CLOB and BLOB values
sub _createJavaSetClobOrBlob {
    my ( $self, $Satt, $Sset, $SjavaType, $keys)= @_;

    my $line = <<END_SET1;
    public void $Sset ($SjavaType value)
        throws ClassNotFoundException,InstantiationException, IllegalAccessException, SQLException
    {
	// indicates that the entire CLOB/BLOB is now stored locally
	this.${Satt}_cached = null;
        set_Attribute("$Satt", value);
    }
END_SET1

      return $line;
}

#method: createJavaSetInitial
#creates java method to set a GUSRow attribute without type-checking
sub _createJavaSetInitial {
    my ( $self, $ISatt, $ISset, $ISjavaType, $keys) = @_;
    #my $primKeySet = $self->_createJavaSetPrimKey($ISatt, $ISset, $ISjavaType, $keys);
    my $line;
    
    $line = "    public void ${ISset}Retrieved (${ISjavaType} value) { set_Retrieved(\"${ISatt}\", value); }\n\n";


    return $line;
}

#method: createJavaSetClobOrBlobInitial
#special-purpose version of _createJavaSetInitial for CLOB and BLOB values
sub _createJavaSetClobOrBlobInitial {
    my ( $self, $ISatt, $ISset, $ISjavaType, $ISnewJavaType, $keys) = @_;
    my $lob = ($ISnewJavaType =~ /char/i) ? "Clob" : "Blob";

    my $line = <<END_SET_INIT;
    public void ${ISset}_Retrieved ($ISjavaType value, Hashtable specialCases) { 
	${ISatt}_cached = this.set${lob}Initial("$ISatt", value, specialCases);
    }
END_SET_INIT

    return $line;
}

#method:  createJavaGet
#creates java method to retrieve a GUSRow attribute
sub _createJavaGet{
    my ($self, $Gatt, $Gget, $GjavaType)= @_;
    my $line;
    $line .= <<END_GET;
    public $GjavaType $Gget () { return ($GjavaType)get_Attribute("$Gatt"); }
END_GET
    return $line;
}

#special-purpose version of _createJavaGet for CLOB and BLOB values;
#there are actually several variants of this method.
sub _createJavaGetClobOrBlob {
    my ($self, $Gatt, $Gget, $GjavaType)= @_;
    my $baseType = $GjavaType;
    $baseType =~ s/[\s\[\]]//g;
    my $lob = ($GjavaType =~ /char/i) ? "Clob" : "Blob";

    my $line;
    $line .= <<END_GET;
    // Retrieve the specified CLOB/BLOB value, throwing an Exception if only
    // part of the value has been cached locally.
    //
    public $GjavaType $Gget () { 
	if (${Gatt}_cached == null) {
	    return ($GjavaType)get_Attribute("$Gatt"); 
	} else {
	    // Full CLOB/BLOB value not available without accessing db.
	    throw new IllegalArgumentException("CLOB/BLOB column $Gatt not retrieved from db.");
	}
    }

    // Return the full length of the underlying CLOB/BLOB value.
    //
    public Long ${Gget}LobLength () { 
	if (${Gatt}_cached == null) {
            $GjavaType value = ${Gget}();
	    return new Long((value == null) ? 0 : value.length);
	} else {
	    return new Long(${Gatt}_cached.length.longValue());
	}
    }

    // Return the CacheRange describing how much of the CLOB/BLOB is cached, 
    // or null if it is all cached.
    //
    public CacheRange ${Gget}LobCached () {
	if (${Gatt}_cached == null) {
	    return null;
        } else {
	    return new CacheRange(new Long(${Gatt}_cached.start.longValue()), 
	                          new Long(${Gatt}_cached.end.longValue()), 
                                  new Long(${Gatt}_cached.length.longValue()));
        }
    }

    public $GjavaType $Gget (long start, long end) {
	return this.get${lob}Value("$Gatt", ${Gatt}_cached, start, end);
    }

END_GET
    return $line;
}

#creates the header + footer for java method to set all GUSRow attributes from the 
#JDBC result set object
sub _createJavaSetAttsFromHT{
    my ($self, $allAtts, $allSuperAtts, $allParentAtts, $allSuperParentAtts) = @_;
    my $line = <<END_SET_ALL;
    protected void setAttributesFromHashtable_aux(Hashtable rowHash, Hashtable specialCases) 
    {
	
	${allAtts}${allSuperAtts}${allParentAtts}${allSuperParentAtts}
        

    }

END_SET_ALL
  return $line;
}

# Implementation of GUSRow's abstract getTable method
#
sub _createJavaGetTable() {
    my($self) = @_;
    my $line = <<END_GET_TABLE;
    public GUSTable getTable() {
	return GUSTable.getTableByName("$self->{schemaName}", "$self->{tableName}");
    }
    
END_GET_TABLE
    return $line;
}

#In the generated object, adds calls to set attributes that the object's
#parent also has
sub _addSuperSets{
    my($self) = @_;

    my @parentAtts = $self->_parentAndChildAttributes();
    
    my $table = $self->{generator}->getTable($self->{fullName} ,1);
    my $allAttInfo = $table->getAttributeInfo();
    my $output;
    my $primaryKeys = $table->getPrimaryKeyAttributes();
    # Index column/attribute info. by name
    
    my $attHash = {};
    foreach my $att (@$allAttInfo) {
	my $name = $att->{'col'};

	$attHash->{$name} = $att;
    }

    my ($finalParentHash, $fkHash) = $self->_splitFksAndAttributes(\@parentAtts, $attHash);

    foreach my $parentAtt ( keys %$finalParentHash){
	my $sub_name = $self->_capAttName( $parentAtt );
	my $set = "set" . $sub_name;
	my $attInfo = $finalParentHash->{$parentAtt};
	my $javaType = $self->_oracleTypeConverter ($attInfo, $parentAtt);

#	if (!(($javaType eq "Clob") || ($javaType eq "Blob"))) {
	    $output .= "	    ";  # JC: these lines are in a 'try' block
	    $output .= $self->_createJavaHTLine($parentAtt, $set, $javaType, $primaryKeys, 1);
#	}	    
    }
    
    my $superParentSets = "";
    foreach my $fkAtt (keys %$fkHash){
	my $parentTableName = $fkHash->{$fkAtt};
	$superParentSets .= $self->_createJavaParentHTLine($fkAtt, $parentTableName, 1);
    }

    my $pkAccessors = $self->_genPkAccessors($finalParentHash);


    return ($pkAccessors, $output, $superParentSets);
}


sub _formatPackageTableName{

    my ($self, $owner, $table) = @_;
    return $self->{modelPackagePrefix} . "." . $owner . "." . $table;



}


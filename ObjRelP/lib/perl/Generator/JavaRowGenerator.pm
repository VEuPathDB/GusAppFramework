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
    print F $self->_genHeader() . $self->_genAccessors() . "} // $self->{tableName}_Row\n";
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
    $output .= "    // Constructor\n";
    $output .= "    public " . $self->{tableName} . "_Row () {}\n\n";
    return $output;
}
 
# method: _genAccessors
# arg 1: table name
# outputs the set and get methods for the attributes of the table.  If the table is a true table, will just output
# setters and getters for all the attributes.  If it is a view will output methods only for those attributes
# not found in the parent.
# output: string that is created.
sub _genAccessors {
    my ($self) = @_;
    my $output;
    my $setAllAtts;
    my $setAllSuperAtts;

    my @final_att_list = $self->_getUniqueAttributes();
    
    my $tableObject = $self->{generator}->getTable($self->{fullName}, 1);
    my $allAttInfo  = $tableObject->getAttributeInfo();
    
    my $primaryKeys = $tableObject->getPrimaryKeyAttributes();
        

    # Index column/attribute info. by name
    #
    my $attHash = {};
    foreach my $att (@$allAttInfo) {
	my $name = $att->{'col'};
	$attHash->{$name} = $att;
    }
    unless (@final_att_list){
	return undef;
    }
    foreach my $att ( @final_att_list ) {
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
	$setAllAtts .= $self->_createJavaRSLine($att, $set, $javaType, $primaryKeys);

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
	    $output .= $self->_createJavaSetInitial($att, $set, $javaType, $primaryKeys);
	}
    }
    
    my $parent = $self->_getParentTable( );

    if ($parent){
	$setAllSuperAtts .= $self->_addSuperSets();
    } 
    
    # Abstract methods from GUSRow: setAttributesFromResultSet and getTable
    #
    $output .= "    // ----------------------------------------------\n";
    $output .= "    // GUSRow abstract methods\n";
    $output .= "    // ----------------------------------------------\n";
    $output .= "\n";
    $output .= $self->_createJavaSetAttsFromRS($setAllAtts, $setAllSuperAtts);
    $output .= $self->_createJavaGetTable();

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

#creates one line that will go in the setAttributesFromResultSet method.
#will be called once for every GUSRow attribute

sub _createJavaRSLine {
    my ($self, $RSatt, $RSset, $RSJavaType, $keys) = @_;
    my $line =  "$RSset" . "Initial(";
    
    if ($RSJavaType eq "Boolean" || $RSJavaType eq "Short" || $RSJavaType eq "Long" ||
	$RSJavaType eq "Float" || $RSJavaType eq "Double") 
    {
	$line .= "new $RSJavaType(rs.get" . "$RSJavaType(\"$RSatt\")));\n";
    }
    elsif ($RSJavaType eq "Integer") 
    {
	$line .= "new Integer(rs.getInt(\"$RSatt\")));\n";
    }
    # For Clob/Blob columns, must also pass along the "specialCases" Hashtable
    #
    elsif (($RSJavaType eq "Clob") || ($RSJavaType eq "Blob")) 
    {
	$line .= "rs.get" . "$RSJavaType(\"$RSatt\"), specialCases);\n";
    }
    elsif ($RSJavaType eq "BigDecimal" || $RSJavaType eq "Blob" || $RSJavaType eq "Clob" ||
	   $RSJavaType eq "Date" || $RSJavaType eq "Time" || $RSJavaType eq "TimeStamp" ||
	   $RSJavaType eq "String") 
    {
	$line .= "rs.get" . "$RSJavaType(\"$RSatt\"));\n";
    }
    elsif ($RSJavaType eq "byte{}") 
    {	
	$line .= "new byte[](rs.getBytes(\"$RSatt\")));\n";
    }
    else 
    {	
	$line .= "new $RSatt(rs.get" .  $RSatt . "(\"$RSatt\")));\n";
    }
    
#	die "Error in method createJavaRSLine:  Java type \"$RSJavaType\" not found!\n";

    return $line;
}

# create Java used to set the row's primary key value, in the case where that is
# the attribute being modified
sub _createJavaSetPrimKey {
    my ( $self, $Satt, $Sset, $SjavaType, $keys)= @_;
    my $primaryKeyName = $keys->[0];
    my $primKeySet = "";

    if ($Satt eq $primaryKeyName) {
	if ($SjavaType eq "Long"){
	    $primKeySet = "this.setPrimaryKeyValue(value);";
	}
	elsif ($SjavaType eq "Integer"){
	    $primKeySet = "this.setPrimaryKeyValue(new Long(value.intValue()));";
	}
	elsif ($SjavaType eq "Short"){
	    $primKeySet = "this.setPrimaryKeyValue(new Long(value.shortValue()));";
	}
	elsif ($SjavaType eq "BigDecimal"){
	    $primKeySet = "this.setPrimaryKeyValue(new Long(value.longValue()));";
	}
    }
    return $primKeySet;
}

#creates java method to set a GUSRow attribute
sub _createJavaSet {
    my ( $self, $Satt, $Sset, $SjavaType, $keys)= @_;
    my $primKeySet = $self->_createJavaSetPrimKey($Satt, $Sset, $SjavaType, $keys);

    my $line = <<END_SET1;
    public void $Sset ($SjavaType value)
        throws ClassNotFoundException,InstantiationException, IllegalAccessException, SQLException
    {
        attTypeCheck("$Satt", value);   
        set("$Satt", value);
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
        set("$Satt", value);
    }
END_SET1

      return $line;
}

#method: createJavaSetInitial
#creates java method to set a GUSRow attribute without type-checking
sub _createJavaSetInitial {
    my ( $self, $ISatt, $ISset, $ISjavaType, $keys) = @_;
    my $primKeySet = $self->_createJavaSetPrimKey($ISatt, $ISset, $ISjavaType, $keys);
    my $line;

    if ($primKeySet =~ /\S/) {
	$line = <<END_SET_INIT;
    public void ${ISset}Initial ($ISjavaType value) { 
	${primKeySet}
        setInitial("$ISatt", value); 
    }

END_SET_INIT
    } else {
	$line = "    public void ${ISset}Initial (${ISjavaType} value) { setInitial(\"${ISatt}\", value); }\n\n";
    }

    return $line;
}

#method: createJavaSetClobOrBlobInitial
#special-purpose version of _createJavaSetInitial for CLOB and BLOB values
sub _createJavaSetClobOrBlobInitial {
    my ( $self, $ISatt, $ISset, $ISjavaType, $ISnewJavaType, $keys) = @_;
    my $lob = ($ISnewJavaType =~ /char/i) ? "Clob" : "Blob";

    my $line = <<END_SET_INIT;
    public void ${ISset}Initial ($ISjavaType value, Hashtable specialCases) { 
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
    public $GjavaType $Gget () { return ($GjavaType)get("$Gatt"); }
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
	    return ($GjavaType)get("$Gatt"); 
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
sub _createJavaSetAttsFromRS{
    my ($self, $allAtts, $allSuperAtts) = @_;
    my $line = <<END_SET_ALL;
    protected void setAttributesFromResultSet_aux(ResultSet rs, Hashtable specialCases) 
    {
	try { 
${allAtts}${allSuperAtts}
        } catch (Exception e) {}

        this.currentAttVals = (Hashtable)(this.initialAttVals.clone());
	this.isNew = false;
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
#    my $parent = $self->_getParentTable();
#    my ($parentSchema, $parentName) = $self->_cutFullQualifiedName($parent);
    
#    my $parentFullName = $parentSchema . "::" . $parentName;

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

    foreach my $parentAtt ( @parentAtts){
	my $sub_name = $self->_capAttName( $parentAtt );
	my $set = "set" . $sub_name;
	my $attInfo = $attHash->{$parentAtt};
	my $javaType = $self->_oracleTypeConverter ($attInfo, $parentAtt);

#	if (!(($javaType eq "Clob") || ($javaType eq "Blob"))) {
	    $output .= "	    ";  # JC: these lines are in a 'try' block
	    $output .= "super." . $self->_createJavaRSLine($parentAtt, $set, $javaType, $primaryKeys);
#	}	    
    }

    return $output;
}

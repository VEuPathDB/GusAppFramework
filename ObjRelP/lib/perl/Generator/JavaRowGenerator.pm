package GUS::ObjRelP::Generator::JavaRowGenerator;

@ISA = qw (GUS::ObjRelP::Generator::RowGenerator);

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
    print F $self->_genHeader() . $self->_genSetDefaultParams() .
	$self->_genAccessors() . "\n}\n";
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
    $output .= "\n\n";
    return $output;
    
} 

sub _genClassDeclaration{
    my ($self) = @_;
 
    my $output = "";
       
    my $fullParent = $self->_getParentTable();
    if ($fullParent){
	my ($parentSchema, $parentName) = $self->_cutFullQualifiedName($fullParent);
	$output .= "public class $self->{tableName}"."_Row extends $parentName implements java.io.Serializable{\n\n";
    } 
    else {
	$output .= "public class $self->{tableName}"."_Row extends GUSRow implements java.io.Serializable {\n\n";
    }
    return $output;
}

sub _genConstructor{
    my ($self) = @_;
      
    my $output = "public " . $self->{tableName} . "_Row () {\n\n";
    $output .= "  super(\"" . $self->{tableName} . "\", \"" . $self->{schemaName} . "\");\n";
    $output .= "  setDefaultParams();\n";
    $output .= "}\n\n";
    $output .= "public ". $self->{tableName} . "_Row (String owner, String name) { \n\n";
    $output .= "     super(owner, name);\n";
    $output .= "}\n\n";
    
    return $output;
}

sub _genSetDefaultParams{
    my ($self) = @_;
    my $output; my $versionable;
       
    if ( $self->_getVersionable())
       { $versionable = "true";}
    else
    { $versionable = "false";}
  
    $output .= "   public void setDefaultParams \(\) \{\n";
    $output .= "     super.setIsVersionable\($versionable\);\n";
    $output .= "     super.setIsUpdateable\(true\);\n";
    $output .= "   \}\n\n";
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
	if ($sub_name eq "Class"){
	    $sub_name = "myClass";}
	my $set = "set" . $sub_name;
	my $get = "get" . $sub_name;
	
	my $attInfo = $attHash->{$att};
	
	# convert attribute oracle type to Java type
	my $javaType = $self->_oracleTypeConverter( $attInfo, $att );
	
	if (!(($javaType eq "Clob")||($javaType eq "Blob"))){
	    $setAllAtts .= $self->_createJavaRSLine($att, $set, $javaType, $primaryKeys);
	
	    ## print the set and gets 
	    $output .= $self->_createJavaSet($att, $set, $javaType);
	    $output .= $self->_createJavaSetInitial($att, $set, $javaType);
	    $output .= $self->_createJavaGet($att, $get, $javaType);
	}
    }
    
    my $parent = $self->_getParentTable( );
    if ($parent){
	$setAllSuperAtts .= $self->_addSuperSets();
    } 
    
    
    #append table information and attribute value methods
    $output .= $self->_createJavaSetAttsFromRS($setAllAtts, $setAllSuperAtts);
    
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
    
    my $primaryKeyName = $keys->[0];
    my $line =  "$RSset" . "Initial(";
    
    
    if ($RSJavaType eq "Boolean" || $RSJavaType eq "Short" || $RSJavaType eq "Long" ||
	$RSJavaType eq "Float" || $RSJavaType eq "Double"){
	$line .= "new $RSJavaType(rs.get" . "$RSJavaType(\"$RSatt\")));\n";}
    elsif ($RSJavaType eq "Integer") {
	$line .= "new Integer(rs.getInt(\"$RSatt\")));\n";}
    elsif ($RSJavaType eq "BigDecimal" || $RSJavaType eq "Blob" || $RSJavaType eq "Clob" ||
	   $RSJavaType eq "Date" || $RSJavaType eq "Time" || $RSJavaType eq "TimeStamp" ||
	   $RSJavaType eq "String"){
	$line .= "rs.get" . "$RSJavaType(\"$RSatt\"));\n";}
    elsif ($RSJavaType eq "byte{}"){	
	$line .= "new byte[](rs.getBytes(\"$RSatt\")));\n";}
    else {	$line .= "new $RSatt(rs.get" .  $RSatt . "(\"$RSatt\")));\n";}
    
#	die "Error in method createJavaRSLine:  Java type \"$RSJavaType\" not found!\n";


    if ($RSatt eq $primaryKeyName){
	if ($RSJavaType eq "Integer"){
	    $line .= "  //super.setId(new Integer(rs.getInt(\"$primaryKeyName\")));\n";
	}
	elsif ($RSJavaType eq "BigDecimal"){
	    $line .= " // super.setId(rs.getBigDecimal(\"$primaryKeyName\"));\n";
	}
	else{
	    $line .= "// super.setId(new $RSJavaType(rs.get" . "$RSJavaType(\"$primaryKeyName\")));\n";
	}
    }
    return $line;
}

#creates java method to set a GUSRow attribute
sub _createJavaSet{
    my ( $self, $Satt, $Sset, $SjavaType)= @_;
    my $line;
    
    $line .= "   public void $Sset ($SjavaType value)
              throws GUSInvalidObjectException, ClassNotFoundException,
                   InstantiationException, IllegalAccessException, SQLException
 {
       attTypeCheck(\"$Satt\", value);   
       set(\"$Satt\", value);
  }\n\n";
  
      return $line;
}

#method: createJavaSetInitial
#creates java method to set a GUSRow attribute without type-checking
sub _createJavaSetInitial{
    my ( $self, $ISatt, $ISset, $ISjavaType) = @_;
    my $line;
    $line .= "   public void $ISset" . "Initial ($ISjavaType value) {
       setInitial(\"$ISatt\", value);
  }\n\n";
      return $line;
}

#method:  createJavaGet
#creates java method to retrieve a GUSRow attribute
sub _createJavaGet{
    my ($self, $Gatt, $Gget, $GjavaType)= @_;
    my $line;
    $line .= "  public $GjavaType $Gget () {
     return ($GjavaType)get(\"$Gatt\");
    }\n\n";
    return $line;
}

#creates the header + footer for java method to set all GUSRow attributes from the 
#JDBC result set object
sub _createJavaSetAttsFromRS{
    my ($self, $allAtts, $allSuperAtts) = @_;
    my $line;


    $line .=  "    public void setAttributesFromResultSet(ResultSet rs) {
      try { \n
$allAtts  \n 
$allSuperAtts \n
           }
          catch (Exception e) {}
     
     }\n\n\n";
  return $line;
}

#In the generated object, adds calls to set attributes that the object's
#parent also has
sub _addSuperSets{
    my($self ) = @_;
#    my $parent = $self->_getParentTable();
#    my ($parentSchema, $parentName) = $self->_cutFullQualifiedName($parent);
    
#    my $parentFullName = $parentSchema . "::" . $parentName;
    print STDERR "Calling getparentandchildattributes \n";
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
	if (!(($javaType eq "Clob")||($javaType eq "Blob"))){
	    $output .= "super." . $self->_createJavaRSLine($parentAtt, $set, $javaType, $primaryKeys);
	}	    
    }

    return $output;
}

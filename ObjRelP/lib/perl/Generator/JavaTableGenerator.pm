package GUS::ObjRelP::Generator::JavaTableGenerator;

@ISA = qw (GUS::ObjRelP::Generator::TableGenerator);

use strict;
use GUS::ObjRelP::Generator::TableGenerator;
use GUS::ObjRelP::Generator::GeneratorFunctions;

my $tab = "    ";

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

#    my $hasSeq = ($dbiTable->hasSequence()) ? "true" : "false"; 
    my $hasSeq = "true";
    my $isView = ($dbiTable->isView()) ? "true" : "false";

    my $realTableName;
    if ($dbiTable->isView()){
	my $fullRealTableName = $dbiTable->getRealTableName();

	if ($fullRealTableName =~ /\S+::(\S+)/){
	    $realTableName = $1;
	}
    }

    my $tableId = $dbiTable->getTableId();

    my $output =  $tab . "public void setDefaultParams (){";
    
    $output .= $self->_getTableAttributeInfo();
    $output .= $self->_createSetChildRelations();
    $output .= $self->_createSetParentRelations();

    $output .= $tab . "// Other table properties\n";
    $output .= $tab . "this.schemaName = \"" . $self->{schemaName} ."\";\n";
    $output .= $tab . "this.tableName = \"" . $self->{tableName} . "\";\n";
    $output .= $tab . "this.isView = $isView;\n";
    $output .= $tab . "this.hasSequence = $hasSeq;\n";
    $output .= $tab . "this.primaryKey = \"$primaryKeyName\";\n";
    $output .= $tab . "this.tableId = $tableId;\n";
    if ($realTableName){
	$output .= $tab . "this.impTableName = \"$realTableName\";\n";
    }
    $output .= $tab . "}\n";
    

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
    $output .= "        catch (Exception e) {System.err.println(e.getMessage());\ne.printStackTrace();\n}\n";
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
    $output .= "        catch (Exception e) {System.err.println(e.getMessage());\ne.printStackTrace();\n}\n";
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
	my $javaType = oracleTypeConverter( $attInfo, $att );
	$addTableInfo .= $self->_createJavaTALine($att, $attInfo, $javaType);
    }    
    $output .= $self->_createJavaSetTAInfo($addTableInfo);
    
    return $output;
}


############################################################################
####                    Private utility methods                         ####
############################################################################


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
    if ($len){}
    else {$len = -1;}
    
   if ($javaType eq "BigDecimal") {
	$line .= "	    ";
	$line .= "tableAtts.put(\"$att\", new GUSTableAttribute(\"$att\", \"$oraType\", \"java.math.$javaType\", $prec, $len, $scale, false, false) );\n";
    } 
    elsif ($javaType eq "Date"){
	$line .= "tableAtts.put(\"$att\", new GUSTableAttribute(\"$att\", \"$oraType\", \"java.sql.$javaType\", $prec, $len, $scale, false, false) );\n";
	
    }
    else {
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
        } catch (Exception e) {System.err.println(e.getMessage());\ne.printStackTrace();\n}
        this.attributeInfo = tableAtts;

END_SET_TA

    return $line;
}


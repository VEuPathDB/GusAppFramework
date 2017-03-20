package GUS::ObjRelP::Generator::GeneratorFunctions;

@ISA = qw(Exporter);
@EXPORT = qw(oracleTypeConverter);

use strict;


#Take oracle type and return Java equivalent
sub oracleTypeConverter {
    my ($attInfo, $att) = @_;
    my $newType;
    my $oraType = $attInfo->{'type'};
    my $oraPrec = $attInfo->{'prec'};
    my $oraScale = $attInfo->{'scale'};
    my $oraLen = $attInfo->{'length'};
        
    if (uc($oraType) eq "NUMBER" || uc($oraType) eq "NUMERIC" ) {
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
    elsif (uc($oraType) eq "BPCHAR") {  # Postgres Binary Precision Character
	$newType .= "Short";
    }
    elsif (uc($oraType) eq "JSONB") { # Postgres JSONB Type; can be treated as String
      $newType .= "String";
    }
    elsif (uc($oraType) eq "INT4") { # Postgres SERIAL (autoincrement) type translates to Int4 == Integer
      $newType .= "Integer";
    }
    elsif (uc($oraType) eq "BOOL") {# Postrgres BOOL type
      $newType .= "Boolean";
    }
    elsif (uc($oraType) eq "DATE"){
	if ($oraLen == 7){
	    $newType .= "Date";}
	elsif ($oraLen == 6){
	    $newType .= "Time";}
	else { $newType .= "Timestamp";}
    }
    elsif (uc($oraType) eq "TIMESTAMP" ) {
        $newType .= "Timestamp";
    }
    elsif (uc($oraType) eq "FLOAT" || uc($oraType) eq "FLOAT8"){
	$newType .= "BigDecimal"}

    elsif (uc($oraType) eq "VARCHAR2" || uc($oraType) eq "CHAR" || uc($oraType) eq "LONG" || uc($oraType) eq "VARCHAR" ){ 
	$newType .= "String";}

    elsif (uc($oraType) eq "CLOB" || uc($oraType) eq "TEXT" ){
	$newType .= "Clob";}

    elsif (uc($oraType) eq "BLOB"){
	$newType .= "Blob";}    

    elsif (uc($oraType) eq "RAW" || uc($oraType) eq "LONGRAW"){
	$newType .= "byte[]";}

    else {
	print STDERR "Warning: No JavaType found for '".$att."', type: '".$oraType."'\n";
	$newType .= "notdefyet";
    }

    # print STDERR "name is $att type is $oraType, precision is $oraPrec, scale is $oraScale,  length  $oraLen, javatype is $newType\n" ;

    return $newType;
}

1;

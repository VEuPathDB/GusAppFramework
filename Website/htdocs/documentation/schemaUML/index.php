<!DOCTYPE html public "-//w3c//dtd html 4.0 transitional//en">
<HTML>
<HEAD>
   <META http-equiv="Content-Type" content="text/html;
charset=iso-8859-1">
    <meta name="Content-Type" content="text/html; charset=iso-8859-1">
<TITLE> GUS documentation page </TITLE></HEAD>

<BODY>
<h1>GUS Schema UML</h1>
<BR><HR><BR>
<?php
        $currdir = opendir('.');
        while ($f = readdir($currdir)) {
            if (ereg("^\.+",$f)) {
               # do nothing
            } else if (ereg("^index",$f)) {
            } else {
                  print "<a href='$f'><BR>$f<BR>\n";
            }
    }
        closedir($currdir);
?>

</BODY></HTML>




<?php

function process_form ( $values ) {
  $msg = "GUS Registration:

Name: ".$values['fname']." ".$values['lname']." 
Affiliation: ".$values['affiliation']."
Email: ".$values['email']."

GUS Survey:

Current Data Types: ".$values['gustype']."
Current Projects ".$values['gusprof']."
Programming Experience: ".$values['gusprog']."

Workshop Interests: 
  Data Loading ".$values['plug']."
  App Adapters ".$values['visual']."
  WDK ".$values['wdk']."
  RAD ".$values['rad']."
  PROT ".$values['prot']."
  Basics ".$values['start']."

Dietary Restrictions: ".$values['diet'];

    mail('gusworkshop@pcbi.upenn.edu','GUS Workshop Registration',$msg, "Reply-To: ".$values['email']);

  return true;
}

?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
<title>:: GUS Workshop :: </title>
<link href="/workshop/screen.css" media="screen" rel="Stylesheet" type="text/css" />
<meta http-equiv="Content-Language" content="en">
<meta name="ROBOTS" content="ALL">
<meta http-equiv="imagetoolbar" content="no">
</head>

<body>


<div id="Page">

<div class="title">
<h1>The Genomics Unified Schema</h1>
<h2>User's and Developer's Workshop</h2>
<h3>July 6-8, 2005 -- Philadelphia, Pennsylvania</h3>
</div>

<div class="menu">
<span class="menuItem"><a href="index.php">About</a></span>
<span class="menuItem"><a href="agenda.php">Agenda</a></span>
<span class="menuItem"><a href="registration.php">Registration</a></span>
</div>

<div class="body">

<h3>Workshop Registration</h3>

<p>
If you'd like to attend the GUS Workshop, please complete the form below.  Registration and attendance is free.  Breakfast will be provided for those that register before July 2, 2005.
</p>

<p>
The workshop will have an emphasis on getting real work done.  Participants should come prepared to connect to their existing GUS instances (or be ready to install GUS).  Wireless and wired access will be provided.  More details will be sent to participants as the workshop approaches.
</p>


<p>
The second part of this form is a general GUS survey.  This survey will assist in planning the GUS Workshop and 
in planning for GUS development.  Your answers are greatly appreciated.
</p>

<?php

require_once 'HTML/QuickForm.php';

$form = new HTML_QuickForm('registration','post');
$txt_prop = array('size'=>50, 'maxlength'=>50);

$form->addElement('header','reg_header','Registration Information');

$form->addElement('text','fname','First Name:');
$form->addRule('fname','First Name Required','required');

$form->addElement('text','lname','Last Name:');
$form->addRule('lname','Last Name Required','required');

$form->addElement('text','affiliation','Affiliation');
$form->addRule('affiliation','Affiliation Required','required');

$form->addElement('text','email','Email Address');
$form->addRule('email','Email Address Required','required');

$form->addElement('header','gus_header','GUS Survey');

$form->addElement('textarea','gustype','What data types are you currently<br/>using in GUS?');

$form->addElement('textarea','gusprof','What projects are you currently<br/>using GUS with?');

$form->addElement('textarea','gusprog','What is your programming<br/~>experience?');

$form->addElement('header', 'int', 'Areas of Interest for the Workshop');

$form->addElement('checkbox','plug','Data Loading/Plugins');
$form->addElement('checkbox','visual','Application Adapters<br/>(i.e. GBrowse, Apollo)');
$form->addElement('checkbox','wdk','GUS WDK');
$form->addElement('checkbox','rad','Microarrays');
$form->addElement('checkbox','prot','Proteomics');
$form->addElement('checkbox','start','GUS Basics/Getting Started');

$form->addElement('header', 'misc','Misc.');

$form->addElement('textarea','diet', 'Dietary restrictions for<br/> breakfasts & lunches');

$form->addElement('submit','submit','Submit');

if ($form->validate() ) {
   if ( ! $form->process('process_form',false) ) {
      $form->display();
   } else {
      print "<p><b>Thank you.  Your registration has been received, and you will receive an email confirmation shortly.</b></p>";
  }
} else {
   $form->display();
}
?>


</div>

</div>

</body>

</html>
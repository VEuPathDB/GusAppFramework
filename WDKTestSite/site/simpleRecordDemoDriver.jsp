<%@ taglib prefix="sample" tagdir="/WEB-INF/tags/local" %>
<%@ taglib prefix="wdkq" uri="http://www.gusdb.org/taglibs/wdk-query-0.1" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<sample:header banner="Simple Record Demo Driver" />

<p>This page has some links to test out record retrieval 
<hr><p>

<form method="GET" action="/sampleWDK/RecordTester">
<input type="hidden" name="style" value="plain">
<input type="hidden" name="recordSetName" value="RNARecords">
<input type="hidden" name="recordName" value="PSUCDSRecord">

<input type="text" name="primaryKey" size="8">


<p>
<input type="submit">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="reset"> 
</form>


<sample:footer />

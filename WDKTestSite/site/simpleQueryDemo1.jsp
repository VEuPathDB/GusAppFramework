<%@ taglib prefix="sample" tagdir="/WEB-INF/tags/local" %>
<%@ taglib prefix="wdkq" uri="http://www.gusdb.org/taglibs/wdk-query-0.1" %>

<sample:header title="sample title" banner="TestSite Front Page" />

<p>This page has a simple, non-boolean query
<hr><p>


<table>
<wdkq:queryHolder name="form1"
                  initQuery="RNAs"
                  var="q">


  <tr><td><wdkq:displayQuery query="${q}" /></td></tr>
  <c:forEach var="p" 
             items="${q.params}">
	     
       <tr>
	     <td><b>${p.description}</b></td>
	     <td><wdkq:displayParam param="${p}" /></td>
	     <td>${p.help}</td>
       </tr>
  
  </c:forEach>

  <tr>
     <td><wdkq:submit /></td>
     <td><wdkq:reset /></td>
  </tr>


</wdkq:queryHolder>
</table>


<sample:footer />

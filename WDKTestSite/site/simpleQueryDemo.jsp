<%@ taglib  uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@ taglib uri="/WEB-INF/gusweb-format.tld" prefix="f" %>
<%@ taglib uri="/WEB-INF/project-format.tld" prefix="pf" %>

<p>This page has a simple, non-boolean queury


<table>
<wdk:queryHolder name=""
                 queryExportVar="">


  <tr><td><b>Description</b></td></tr>
  <c:forEach var="param" 
             item="Queries.params">
	     
       <tr>
          <gussample:prepareParam name="${param}" exportVar ="p">
	     <td><b>${p.description}</b></td>
	     <td><gussample:displayParam name="${p}" /></td>
	     <td>${p.help}</td>
	   </gussample:prepareParam>
       </tr>
  
  </c:forEach>

  <tr>
     <td><wdk:submit /></td>
     <td><wdk:reset /></td>
  </tr>


</wdk:queryHolder>
</table>
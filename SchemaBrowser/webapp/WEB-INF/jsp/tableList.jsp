<%@ include file="/WEB-INF/jsp/header.jsp" %>

<h1>GUS Schema Browser</h1>

<a href="tableList.htm">Table-Centric View</a> | <a href="categoryList.htm">Category-Centric View</a>

<p/>

<table id="tableDisplay">
	<tr class="tableRow">
		<td class="columnHead"><a href="tableList.htm?sort=schema">Schema</a>::<a href="tableList.htm?sort=name">Table</a></td>
		<td class="columnHead">Superclass</td>
		<td class="columnHead"><a href="tableList.htm?sort=category">Category</a></td>
		<td class="columnHead"></td>
	</tr>

<% String row = "odd"; %>

<c:forEach items="${tables}" var="table">
	<tr class="tableRow <%= row %>">
		<sb:WriteName table="${table}"/>
		<sb:WriteSuperclass table="${table}"/>
    		<sb:WriteCategory table="${table}"/>
		<sb:WriteAction table="${table}"/>
    	</tr>
	<sb:WriteDocumentation table="${table}"/>			
	<% row = row.equals("odd") ? "even" : "odd"; %>
</c:forEach>

</table>

<%@ include file="/WEB-INF/jsp/footer.jsp" %>
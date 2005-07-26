<%@ include file="/WEB-INF/jsp/header.jsp" %>

<h1>GUS Schema Browser</h1>

<a href="tableList.htm">Reset to Normal View</a><p/>

<table id="tableDisplay">
	<tr class="tableRow">
		<td class="columnHead"><a href="tableList.htm?sort=schema">Schema</a>::<a href="tableList.htm?sort=name">Table</a></td>
		<td class="columnHead">Superclass</td>
		<td class="columnHead"><a href="tableList.htm?sort=category">Category</a></td>
		<td class="columnHead"></td>
	</tr>

<% int row = 0; %>

<c:forEach items="${tables}" var="table">
	<sb:WriteRow table="${table}" number="<%= row++ %>"/>
</c:forEach>
</table>

<%@ include file="/WEB-INF/jsp/footer.jsp" %>
<%@ include file="/WEB-INF/jsp/header.jsp" %>

<h1>GUS Schema Browser</h1>

<a href="tableList.htm">Table-Centric View</a> | <a href="categoryList.htm">Category-Centric View</a>

<p/>

<table id="tableDisplay">
	<tr class="tableRow">
		<td class="columnHead"></td>
		<td class="columnHead"></td>
		<td class="columnHead">Superclass</td>
		<td class="columnHead"></td>
	</tr>

<% String row = "odd"; %>

<c:forEach items="${database.superCategories}" var="supercategory">
	<tr><td class="superCatRow" colspan="4">
		<a name="sc:${supercategory.name}"/>
		${supercategory.name}
	</td></tr>
	
	<c:forEach items="${supercategory.categories}" var="category">
		<tr>
			<td class="catRow" colspan="3">
				<a name="c:${category.name}"/>
				${category.name}
			</td>
			<td class="catRow">
				<small><a href="#sc:${supercategory.name}">Return to Super Category</a>
			</td>
		</tr>
		
		<c:forEach items="${category.tables}" var="table">
			<tr class="tableRow <%= row %>">
				<td>&nbsp;</td>
				
				<sb:WriteName table="${table}"/>
				<sb:WriteSuperclass table="${table}"/>
				<sb:WriteAction table="${table}"/>
    			</tr>
			<sb:WriteDocumentation table="${table}"/>			
			<% row = row.equals("odd") ? "even" : "odd"; %>
		</c:forEach>
		
	</c:forEach>
	
</c:forEach>

</table>

<%@ include file="/WEB-INF/jsp/footer.jsp" %>
<%@ include file="/WEB-INF/jsp/header.jsp" %>

<h1>Edit ${documentation.schemaName}<c:if test='${not empty documentation.tableName}'>::${documentation.tableName}<c:if test='${not empty documentation.attributeName}'>::${documentation.attributeName}

</c:if></c:if>
</h1>

<p>Documentation Instructions</p>

<p>
	<spring:hasBindErrors name="documentation">
    		<b>Please fix all errors!</b>
  	</spring:hasBindErrors>
</p>

<form method="post">
	<input type="hidden" name="schema" value="${documentation.schemaName}"/>
	<input type="hidden" name="table" value="${documentation.tableName}"/>
	<input type="hidden" name="attribute" value="${documentation.attributeName}"/>

	<spring:bind path="documentation.documentation">
	<b>Documentation:</b> <font color="red">${status.errorMessage}</font><br/>
		<textarea rows="10" cols="80" name="documentation">${status.value}</textarea>
	</spring:bind></br>
	
  <input type="submit" value="Submit">
</form>

<%@ include file="/WEB-INF/jsp/footer.jsp" %>

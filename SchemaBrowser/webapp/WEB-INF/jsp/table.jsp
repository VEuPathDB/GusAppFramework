<%@ include file="/WEB-INF/jsp/header.jsp" %>

<b><big><a href="tableList.htm">GUS Schema</a> >> ${table.schema.name}::${table.name}</b></big>

<c:if test='${not empty table.superclass}'>
		(subclass of <a href="table.htm?schema=${table.superclass.schema.name}&table=${table.superclass.name}">
			${table.superclass.schema.name}::${table.superclass.name}
		</a>)</TD>
		</c:if>
</FONT>

<c:if test='${not empty table.superclass}'>
	<p>Light grey rows indicate columns provided from the superclass.</p>
</c:if>

<TABLE BORDER="0" CELLPADDING="2" CELLSPACING="0" BGCOLOR="#000000" WIDTH="100%">
<TR><TD>
<TABLE BORDER="1" CELLPADDING="2" CELLSPACING="1" BGCOLOR="#ffffff" WIDTH="100%">
<TR>
	<TH BGCOLOR="#2020ff" ALIGN="left"><FONT COLOR="#ffffff" FACE="helvetica, sans-serif">column</FONT></TH>
	<TH BGCOLOR="#2020ff" ALIGN="left"><FONT COLOR="#ffffff" FACE="helvetica, sans-serif">nulls?</FONT></TH>
	<TH BGCOLOR="#2020ff" ALIGN="left"><FONT COLOR="#ffffff" FACE="helvetica, sans-serif">type</FONT></TH>
	<TH BGCOLOR="#2020ff" ALIGN="left"><FONT COLOR="#ffffff" FACE="helvetica, sans-serif">description</FONT></TH>
</TR>

<c:if test='${not empty table.superclass}'>

<c:set var="table" value="${table}"/>
<jsp:useBean id="table" type="org.gusdb.dbadmin.model.Table"/>
<% pageContext.setAttribute("columns", table.getSuperclass().getColumns(false) ); %>

	<c:forEach items="${columns}" var="column">
			<TR BGCOLOR="#CCCCCC">
				<TD>${column.name}</TD>
				<TD ALIGN="center">&nbsp;
					<c:if test="${column.nullable != 'true'}">
						no
					</c:if>
				</TD>
				<TD><sb:WriteType column="${column}"/></TD>
				<TD>&nbsp;</TD>
			</TR>
	</c:forEach>
</c:if>

<c:forEach items="${table.columns}" var="column">
	<TR BGCOLOR="white">
		<TD>${column.name}</TD>
		<TD ALIGN="center">&nbsp;
					<c:if test="${column.nullable != 'true'}">
						no
					</c:if>
		</TD>
		<TD><sb:WriteType column="${column}"/></TD>
		<TD>&nbsp;</TD>
	</TR>
</c:forEach>

</TABLE>
</TD></TR></TABLE><BR CLEAR="left">
<FONT FACE="helvetica, sans-serif"><B>Child tables:</B></FONT>

<c:forEach items="${table.subclasses}" var="subclass">
	<a href="table.htm?schema=${subclass.schema.name}&table=${subclass.name}">
		${subclass.schema.name}::${subclass.name}
	</a> &nbsp;
</c:forEach>

<%@ include file="/WEB-INF/jsp/footer.jsp" %>

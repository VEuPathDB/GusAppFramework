<%@ taglib prefix="sample" tagdir="/WEB-INF/tags/local" %>
<%@ taglib prefix="wdk" uri="http://www.gusdb.org/taglibs/wdk-query-0.1" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<sample:header banner="CDS View" />

<p>This page shows a CDS in detail
<hr>
<p>
<table width="100%">
<tr><td colspan="2"><b>Systematic&nbsp;id</b></td><td colspan="2">${cds.name}</td></tr>
<tr><td colspan="2"><b>Product</b></td><td colspan="2">${cds.product}</td></tr>
<tr><td colspan="2"><b>Organism</b></td><td colspan="2">${cds.taxon_name}</td></tr>
<tr><td colspan="2"><b>GeneType</b></td><td colspan="2">${cds.gene_type}</td></tr>
<tr><td colspan="2"><b>Pseudogene?</b></td><td colspan="2">${cds.is_pseudo}</td></tr>
<tr><td colspan="2"><b>Partial?</b></td><td colspan="2">${cds.is_partial}</td></tr>
</table>


<sample:footer />

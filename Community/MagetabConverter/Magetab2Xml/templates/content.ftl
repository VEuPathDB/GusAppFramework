<#include "header.ftl"> 

<h1>Biomaterial Graph Derived from Magetab</h1>
<#if studyName??>
  <h3>
    ${studyName}
    <#if studyId??>
     <span class="existing">(Existing study - id = ${studyId})</span>
    </#if>
  </h3>
</#if>
<p class="instruction">
  Click on each node or edge label in the graph below for detailed information (you may
  need to disable your popup blocker).
</p>
<p class="note">
  The node tooltip provides characteristics or file
  information while the edge label tooltip offers parameter settings, if any.  Nodes
  representing material entities are outlined in <span class="material">blue</span> while
  nodes representing data items are outlined in <span class="data">red</span>.  Yellow fills
  for nodes and yellow edges indicated additions to an existing MAGE-TAB.  Some of
  the graphs are rather large.  Horizontal scroll bars above and below the diagram can be
  employed to scan across the image.
</p>
<div class="scroll1">
  <div id="dummy"></div>
</div>
<div class="scroll2">
  <div id="biomaterials">
    <img src="${gifFileName}" usemap="#biomatGraph">
    <#if map??>
      ${map}
    </#if>
    <#list nodes as node>
      <div id="text${node.getId()}" class="popupData">
        <#if node.dbId??>
          <p>DB ID: ${node.getDbId()}</p> 
        </#if>
        <ul>
          <#if node.taxon??>
            <li>${node.getTaxon()}</li>
          </#if>
          <#if node.uri??>
            <li>${node.getUri()}</li>
          </#if>
          <#if node.characteristics??>
            <#list node.characteristics as characteristic>
              <li>${characteristic}</li>
            </#list>
          </#if>
          <#if !node.taxon?? && !node.uri?? && !node.characteristics??>
            NA
          </#if>
        </ul>
      </div>
    </#list>
    <#list edges as edge>
      <div id="text${edge.getFromNode()}${edge.getToNode()}" class="popupData">
        <#assign i = 1>
        <#list edge.applications as application>
          <div class="subheading">${i}. ${application.protocol.name}</div>
          <#if application.protocol.description??>
            <p>${application.protocol.description}</p>
          </#if>
          <#if application.dbId??>
            <p>DB ID: ${application.dbId}</p> 
          </#if>
          <#if application.performer?? && application.performer?has_content>
            <div class="subheading">Performer</div>
            <p>${application.performer}</p>  
          </#if>
          <#if application.parameters?? && application.parameters?has_content>  
            <div class="subheading">Parameter Setting(s)</div>
            <ul>
              <#list application.parameters as parameter>
                <li>
                 ${parameter}
                </li>
              </#list>
            </ul>
          </#if>
          <#assign i=i+1>
          <#if i <= edge.applications?size>
            <hr class="separator" />
          </#if>
        </#list>
      </div>
    </#list>
  </div>      
</div>
<#include "footer.ftl"> 
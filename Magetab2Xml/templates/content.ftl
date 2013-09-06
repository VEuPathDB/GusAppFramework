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
<p class="note">
  Click on each node or edge label in the graph below for detailed information (you may
  need to disable your popup blocker).  The node tooltip provides characteristics or file
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
        <#if node.type == "data item">
          <span class="popupHeading">File Location</span>
        <#else>
          <span class="popupHeading">Characteristics</span>
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
        <#if edge.dbId??>
          <p>DB ID: ${edge.getDbId()}</p> 
        </#if>
        <span class="popupHeading">Parameter Settings</span>
        <ul>
          <#if edge.params??>   
            <#list edge.params?keys as key>
              <li>
                ${key}: &nbsp;
                <#list edge.params[key] as value>
                 ${value} &nbsp;
                </#list>
              </li>
            </#list>
          <#else>
            NA
          </#if>
        </ul>
      </div>
    </#list>
  </div>
</div>
<#include "footer.ftl"> 
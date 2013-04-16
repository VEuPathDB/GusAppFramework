<#include "header.ftl"> 

<h1>Biomaterial Graph Derived from Database for Study ${studyId}</h1>
<p class="note">
  Click on each node in the graph below for detailed information (You may
  need to disable your popup blocker).  Some of the graphs are rather large.
</p>
<div class="scroll1">
  <div id="dummy"></div>
</div>
<div class="scroll2">
  <div id="biomaterials">
    <img src="${gifFileName}" usemap="#biomatGraph">
    <#include "map.ftl">
    <#list nodes as node>
      <div id="text${node.getNodeId()?c}" class="popupData">
        <span class="popupHeading">Characteristics</span>
        <ul>
          <#if node.taxon??>
            <li>Taxon: ${node.getTaxon()}</li>
          </#if>
          <#if node.uri??>
            <li>Uri: ${node.getUri()}</li>
          </#if>
          <#if node.characteristics??>
            <#list node.characteristics as characteristic>
              <li>${characteristic}</li>
            </#list>
          </#if>
        </ul>
      </div>
    </#list>
    <#list edges as edge>
      <div id="text${edge.getFromNode()?c}_${edge.getToNode()?c}" class="popupData">
        <span class="popupHeading">Parameters</span>
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
          </#if>
        </ul>
      </div>
    </#list>
  </div>
</div>
<#include "footer.ftl"> 
<#include "header.ftl"> 

<h1>Biomaterial Graph Derived from Database for Study ${studyId}</h1>
<p class="note">
  Click on each node in the graph below for detailed information (You may
  need to disable your popup blocker).  Some of the graphs are rather large.
</p>
<div class="wait">
  <img src='images/wait.gif' />
</div>
<div class="scroll1">
  <div id="dummy"></div>
</div>
<div class="scroll2">
  <div id="biomaterials">
    <img src="${gifFileName}" usemap="#biomatGraph">
    <#include "map.ftl">
    <#list nodes as node>
      <div id="textNode${node.getNodeId()?c}" class="popupData">
        <#if node.taxon??>
          Taxon: ${node.getTaxon()}
        </#if>
      </div>
    </#list>
  </div>
</div>
<#include "footer.ftl"> 
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:preserve-space elements="*"/>

  <xsl:template match="/mage-tab">
    <xsl:text>&#x0A;</xsl:text>
    <xsl:copy>
      <xsl:apply-templates select="//idf | //sdrf" />
    </xsl:copy>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>

  <xsl:template match="//idf | //sdrf">
    <xsl:text>&#x0A;</xsl:text>
    <xsl:copy>
      <xsl:for-each select="node()">
        <xsl:choose>
          <xsl:when test="@addition">
              <xsl:message>
                Addition Attribute:  <xsl:value-of select="name(.)"></xsl:value-of>
              </xsl:message>
            <xsl:text>&#x0A;</xsl:text>
            <xsl:copy>
              <xsl:apply-templates select="node()|@*" />
            </xsl:copy>
            <xsl:text>&#x0A;</xsl:text>
          </xsl:when>
          <xsl:when test="@db_id">
              <xsl:message>
                DBID Attribute: <xsl:value-of select="name(.)"></xsl:value-of>
              </xsl:message>
            <xsl:call-template name="dbIdAttr" />
          </xsl:when>
          <xsl:otherwise />
        </xsl:choose>
      </xsl:for-each>
    </xsl:copy>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>
  
  <!--
    Additions may well exist within elements having dbId attributes.  Need to search for and
    display them. Paths differ from idf and sdrf descendent elements since contacts is shared
    between them.
   -->
  <xsl:template name="dbIdAttr">
    <xsl:variable name="idfTag" select="//idf[1]" />
    <xsl:variable name="sdrfTag" select="//sdrf[1]" />
    <xsl:text>&#x0A;</xsl:text>
    <xsl:copy>   
      <xsl:copy-of select="@*"/>
      <xsl:if test="ancestor::*[generate-id() = generate-id($idfTag)]">
        <xsl:apply-templates select="protocol_parameters" />
      </xsl:if>
      <xsl:if test="ancestor::*[generate-id() = generate-id($sdrfTag)]">
        <xsl:apply-templates select="factor_values | protocol_app_parameters" />
      </xsl:if>
    </xsl:copy>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>
  
  <!--
    For factor values, protocol app parameters or contracts in the sdrf, print
    every child element that is an addition or the current element along with every
    child element where the grandparent is an addition.
   -->
  <xsl:template match="factor_values | protocol_app_parameters | contacts">
    <xsl:choose>
      <xsl:when test="../@addition">
        <xsl:copy>
          <xsl:call-template name="add_nodes" />
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&#x0A;</xsl:text>
        <xsl:call-template name="add_nodes" />
        <xsl:text>&#x0A;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!--
    Displays all elements that are either additions or have grandparents that are additions.
   -->
  <xsl:template name="add_nodes">
    <xsl:for-each select="node()">
      <xsl:if test="@addition | ../../@addition">
        <xsl:copy>
          <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  
  <!-- 
    For protocol parameters the idf, print every child element that is an addition or
    the current element along with every child element where the grandparent is an addition.
   -->
  <xsl:template match="protocol_parameters">
   <xsl:choose>
      <xsl:when test="../@addition">
        <xsl:copy>
          <xsl:call-template name="add_nodes" />
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&#x0A;</xsl:text>
        <xsl:call-template name="add_nodes" />
        <xsl:text>&#x0A;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!--
    Identity transform 
   -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>

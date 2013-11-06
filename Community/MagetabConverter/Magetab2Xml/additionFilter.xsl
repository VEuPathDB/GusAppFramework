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
    <xsl:text>&#x0A;</xsl:text>
    <xsl:copy>   
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="pubmed_id | param | factor_value | app_param | contact" />
    </xsl:copy>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>
  
  <!--
    For factor values, protocol app parameters or contracts in the sdrf, print
    every element that is an addition or every element where the parent is an addition.
   -->
  <xsl:template match="pubmed_id | param | factor_value | app_param | contact">
     <xsl:choose>
     <xsl:when test=" ../@addition">
        <xsl:copy>
          <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
      </xsl:when>
      <xsl:when test="@addition">
        <xsl:text>&#x0A;</xsl:text>
        <xsl:copy>
          <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
        <xsl:text>&#x0A;</xsl:text> 
      </xsl:when>
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

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

  <!--
    Immediate child nodes of idf or sdrf will either have db_id attribute, addition attribute, both
    attributes or neither.  Only transform those nodes with addition attribute and/or db_id attribute. 
   -->
  <xsl:template match="//idf | //sdrf">
    <xsl:text>&#x0A;</xsl:text>
    <xsl:copy>
      <xsl:for-each select="node()">
        <xsl:choose>
          <xsl:when test="@addition">
            <xsl:text>&#x0A;</xsl:text>
            <xsl:copy>
              <xsl:apply-templates select="node()|@*" />
            </xsl:copy>
            <xsl:text>&#x0A;</xsl:text>
          </xsl:when>
          <xsl:when test="@db_id">
            <xsl:call-template name="dbIdAttr" />
          </xsl:when>
          <xsl:otherwise />
        </xsl:choose>
      </xsl:for-each>
    </xsl:copy>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>
  
  <!--
    Additions may well exist within elements having dbId attributes.  Need to copy the
    db id element and search for incorporated additions.
   -->
  <xsl:template name="dbIdAttr">
    <xsl:text>&#x0A;</xsl:text>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="*[@addition]" />
    </xsl:copy>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>
  
  <!--
    Element has addition attribute.  Apply identity transform 
   -->
  <xsl:template match="*[@addition]">
    <xsl:text>&#x0A;</xsl:text>
    <xsl:copy-of select="."/>
    <xsl:text>&#x0A;</xsl:text>
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

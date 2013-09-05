<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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
  
  <xsl:template name="dbIdAttr">
    <xsl:text>&#x0A;</xsl:text>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="factor_values | protocol_app_parameters | protocol_parameters" />
      <xsl:apply-templates select="protocol_parameters/param[@addition]" />
    </xsl:copy>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>
  
  <xsl:template match="factor_values | protocol_app_parameters | protocol_parameters">
    <xsl:if test="@addition | ../@addition">
      <xsl:text>&#x0A;</xsl:text>
      <xsl:copy>
        <xsl:apply-templates select="node()|@*"/>
      </xsl:copy>
      <xsl:text>&#x0A;</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="protocol_parameters/param[@addition]">
    <xsl:if test="not(../../@addition)">
      <xsl:text>&#x0A;</xsl:text>
      <xsl:copy>
        <xsl:apply-templates select="node()|@*"/>
      </xsl:copy>
      <xsl:text>&#x0A;</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>

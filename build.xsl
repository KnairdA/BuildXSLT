<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xalan="http://xml.apache.org/xalan"
	xmlns:InputXSLT="function.inputxslt.application"
	exclude-result-prefixes="xalan InputXSLT"
>

<xsl:output
	method="xml"
	omit-xml-declaration="yes"
	encoding="UTF-8"
	indent="no"
/>

<xsl:template name="generate">
	<xsl:param name="input"/>
	<xsl:param name="transformation"/>

	<xsl:copy-of select="InputXSLT:generate(
		xalan:nodeset($input),
		InputXSLT:read-file(string($transformation))/self::file/node()
	)/self::generation/node()"/>
</xsl:template>

<xsl:template name="generate_chain">
	<xsl:param name="input"/>
	<xsl:param name="head"/>
	<xsl:param name="tail"/>

	<xsl:choose>
		<xsl:when test="count($tail) &gt; 0">
			<xsl:call-template name="generate">
				<xsl:with-param name="input">
					<xsl:call-template name="generate_chain">
						<xsl:with-param name="input" select="$input"/>
						<xsl:with-param name="head"  select="$tail[1]"/>
						<xsl:with-param name="tail"  select="$tail[position() &gt; 1]"/>
					</xsl:call-template>
				</xsl:with-param>
				<xsl:with-param name="transformation" select="$head/text()"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:call-template name="generate">
				<xsl:with-param name="input"          select="$input"/>
				<xsl:with-param name="transformation" select="$head/text()"/>
			</xsl:call-template>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="task[@type = 'generate']">
	<xsl:variable name="input">
		<xsl:choose>
			<xsl:when test="input/@mode = 'embedded'">
				<xsl:copy-of select="input/node()"/>
			</xsl:when>
			<xsl:when test="input/@mode = 'file'">
				<xsl:copy-of select="InputXSLT:read-file(input/text())/self::file/node()"/>
			</xsl:when>
		</xsl:choose>
	</xsl:variable>

	<xsl:choose>
		<xsl:when test="transformation/@mode = 'chain'">
			<xsl:variable name="chain">
				<xsl:for-each select="transformation/link">
					<xsl:sort select="position()" data-type="number" order="descending"/>

					<xsl:copy-of select="."/>
				</xsl:for-each>
			</xsl:variable>

			<xsl:call-template name="generate_chain">
				<xsl:with-param name="input" select="$input"/>
				<xsl:with-param name="head"  select="xalan:nodeset($chain)/link[1]"/>
				<xsl:with-param name="tail"  select="xalan:nodeset($chain)/link[position() &gt; 1]"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:when test="transformation/@mode = 'file'">
			<xsl:call-template name="generate">
				<xsl:with-param name="input"          select="$input"/>
				<xsl:with-param name="transformation" select="transformation/text()"/>
			</xsl:call-template>
		</xsl:when>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>

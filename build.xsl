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

	<xsl:variable name="result" select="InputXSLT:generate(
		xalan:nodeset($input),
		string($transformation)
	)/self::generation"/>

	<xsl:choose>
		<xsl:when test="$result/@result = 'success'">
			<xsl:copy-of select="$result/node()"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:message terminate="yes">
				<xsl:text>Failed to generate transformation "</xsl:text>
				<xsl:value-of select="string($transformation)"/>
				<xsl:text>"</xsl:text>
			</xsl:message>
		</xsl:otherwise>
	</xsl:choose>
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

<xsl:template name="augment_transformation">
	<xsl:param name="base"/>
	<xsl:param name="transformation"/>

	<transformation mode="{$transformation/@mode}">
		<xsl:choose>
			<xsl:when test="$transformation/@mode = 'file'">
				<xsl:value-of select="$file/@base"/>
				<xsl:text>/</xsl:text>
				<xsl:value-of select="$transformation/text()"/>
			</xsl:when>
			<xsl:when test="$transformation/@mode = 'chain'">
				<xsl:for-each select="$transformation/link">
					<link>
						<xsl:value-of select="$base"/>
						<xsl:text>/</xsl:text>
						<xsl:value-of select="text()"/>
					</link>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$transformation/node()"/>
			</xsl:otherwise>
		</xsl:choose>
	</transformation>
</xsl:template>

<xsl:template name="read_module">
	<xsl:param name="path"/>

	<xsl:variable name="file" select="InputXSLT:read-file($path)/self::file"/>

	<xsl:choose>
		<xsl:when test="$file/@result = 'success'">
			<xsl:choose>
				<xsl:when test="name($file/node()) = 'transformation'">
					<xsl:call-template name="augment_transformation">
						<xsl:with-param name="base"           select="$file/@base"/>
						<xsl:with-param name="transformation" select="$file/node()"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="$file/node()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:when>
		<xsl:otherwise>
			<xsl:message terminate="yes">
				<xsl:text>Failed to resolve module "</xsl:text>
				<xsl:value-of select="$path"/>
				<xsl:text>"</xsl:text>
			</xsl:message>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="resolve_module">
	<xsl:param name="input"/>
	<xsl:param name="definition"/>

	<xsl:choose>
		<xsl:when test="$definition/@mode = 'file'">
			<xsl:variable name="module">
				<xsl:call-template name="read_module">
					<xsl:with-param name="path" select="$definition/text()"/>
				</xsl:call-template>
			</xsl:variable>

			<xsl:call-template name="handle_generate">
				<xsl:with-param name="input"          select="$input"/>
				<xsl:with-param name="transformation" select="xalan:nodeset($module)/node()"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:message terminate="yes">
				<xsl:text>Failed to resolve module definition mode "</xsl:text>
				<xsl:value-of select="$definition/@mode"/>
				<xsl:text>"</xsl:text>
			</xsl:message>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="resolve_transformation">
	<xsl:param name="input"/>
	<xsl:param name="transformation"/>

	<xsl:choose>
		<xsl:when test="$transformation/@mode = 'chain'">
			<xsl:variable name="chain">
				<xsl:for-each select="$transformation/link">
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
		<xsl:when test="$transformation/@mode = 'file'">
			<xsl:call-template name="generate">
				<xsl:with-param name="input"          select="$input"/>
				<xsl:with-param name="transformation" select="$transformation/text()"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:message terminate="yes">
				<xsl:text>Failed to resolve transformation mode "</xsl:text>
				<xsl:value-of select="$transformation/@mode"/>
				<xsl:text>"</xsl:text>
			</xsl:message>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="resolve_input">
	<xsl:param name="input"/>

	<xsl:choose>
		<xsl:when test="$input/@mode = 'embedded'">
			<xsl:copy-of select="$input/node()"/>
		</xsl:when>
		<xsl:when test="$input/@mode = 'file'">
			<xsl:copy-of select="InputXSLT:read-file($input/text())/self::file/node()"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:message terminate="yes">
				<xsl:text>Failed to resolve input mode "</xsl:text>
				<xsl:value-of select="$input/@mode"/>
				<xsl:text>"</xsl:text>
			</xsl:message>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="handle_generate">
	<xsl:param name="input"/>
	<xsl:param name="transformation"/>

	<xsl:call-template name="resolve_transformation">
		<xsl:with-param name="input">
			<xsl:call-template name="resolve_input">
				<xsl:with-param name="input" select="$input"/>
			</xsl:call-template>
		</xsl:with-param>
		<xsl:with-param name="transformation" select="$transformation"/>
	</xsl:call-template>
</xsl:template>

<xsl:template name="handle_module">
	<xsl:param name="input"/>
	<xsl:param name="definition"/>

	<xsl:call-template name="resolve_module">
		<xsl:with-param name="input"      select="$input"/>
		<xsl:with-param name="definition" select="$definition"/>
	</xsl:call-template>
</xsl:template>

<xsl:template match="task[@type = 'generate']">
	<xsl:call-template name="handle_generate">
		<xsl:with-param name="input"          select="input"/>
		<xsl:with-param name="transformation" select="transformation"/>
	</xsl:call-template>
</xsl:template>

<xsl:template match="task[@type = 'module']">
	<xsl:call-template name="handle_module">
		<xsl:with-param name="input"      select="input"/>
		<xsl:with-param name="definition" select="definition"/>
	</xsl:call-template>
</xsl:template>

<xsl:template match="task">
	<xsl:message terminate="yes">
		<xsl:text>Failed to handle task type "</xsl:text>
		<xsl:value-of select="@type"/>
		<xsl:text>"</xsl:text>
	</xsl:message>
</xsl:template>
<xsl:template match="text()|@*"/>

</xsl:stylesheet>

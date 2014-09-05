# BuildXSLT

... is a simple XSLT build system built on [InputXSLT](https://github.com/KnairdA/InputXSLT).

## Current features:

- processing tasks contained within XML _Makefiles_
- generating single transformations
- generating chained transformations
- using files or embedded XML-trees as transformation input

## Example:

BuildXSLT can for example be used to build a [static website](https://github.com/KnairdA/TestXSLT) using the following generation chain called via `ixslt --input make.xml --transformation build.xsl`:

```
<task type="generate">
	<input mode="embedded">
		<datasource>
			<meta>
				<source>source</source>
				<target>target</target>
			</meta>
		</datasource>
	</input>
	<transformation mode="chain">
		<link>detail/list.xsl</link>
		<link>detail/plan.xsl</link>
		<link>detail/process.xsl</link>
		<link>detail/summarize.xsl</link>
	</transformation>
</task>
```

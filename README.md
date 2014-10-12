# BuildXSLT

... is a simple XSLT build system built on [InputXSLT](https://github.com/KnairdA/InputXSLT).

## Current features:

- processing tasks contained within XML _Makefiles_
- generating single transformations
- generating chained transformations
- using files or embedded XML-trees as transformation input
- using external modules such as [StaticXSLT](https://github.com/KnairdA/StaticXSLT)

## Example:

BuildXSLT can for example be used to build a [static website](https://github.com/KnairdA/blog.kummerlaender.eu) using the following XML _Makefile_ called via `ixslt --input make.xml --transformation build.xsl --include ../StaticXSLT`:

```
<task type="module">
	<input mode="embedded">
		<datasource>
			<meta>
				<source>source</source>
				<target>target</target>
			</meta>
		</datasource>
	</input>
	<definition mode="file">[StaticXSLT.xml]</definition>
</task>
```

Where the module definition of `StaticXSLT.xml` looks as follows:

```
<transformation mode="chain">
	<link>src/steps/list.xsl</link>
	<link>src/steps/plan.xsl</link>
	<link>src/steps/process.xsl</link>
	<link>src/steps/summarize.xsl</link>
</transformation>
```

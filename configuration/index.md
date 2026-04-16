# Configuring and Using LiSA

{% include version_disclaimer.html %}

Using and configuring LiSA is straightforward: first, a `Program` (or more
programs, one for each programming language to analyze) must be obtained,
then a `LiSAConfiguration` object must be created and customized, and finally
a `LiSA` instance must be created with the configuration and run on the
program(s). For example:

```java
Program program = ... // use a frontend to parse the code, or build the program programmatically
LiSAConfiguration config = new LiSAConfiguration();
// set configuration options (see below)
LiSA lisa = new LiSA(config);
LiSAReport report = lisa.run(program);
// use the report
```

Each configuration option can be set individually by changing the value of a
field of the `LiSAConfiguration` object passed to the `LiSA` constructor. In the
following sections, when an example usage is provided for a configuration option,
it is assumed that the `LiSAConfiguration` object is stored in a variable named `conf`.

## Available Options

### Setting the Abstract Domain

{% include config_option.html
name="analysis"
type="AbstractDomain&lt;?&gt;"
default="null"
example="conf.analysis = new SimpleAbstractDomain(new PointBasedHeap(), new Interval(), new InferredTypes())"
%}

The [Abstract Domain]({{ site.baseurl }}/documentation/semantic-domains.html#the-abstract-domain-interface)
to execute during the analysis can be selected through the `analysis` option.
The value of this option decides what analyysis is being run, and what shape
will the computed states have. If no value is set for this option, no semantic
analysis will be executed.

Several abstract domains are available in LiSA:

{% include github_alternatives.html class="it.unive.lisa.analysis.AbstractDomain" %}

If you adopt the
[Simple Abstract Domain framework]({{ site.baseurl }}/documentation/simple-abstract-domain.html)
to build your own abstract domain, LiSA also provides alternatives for each component.
The out-of-the-box implementations for the heap domain are:

{% include github_alternatives.html class="it.unive.lisa.analysis.heap.HeapDomain" %}

Instead, the bundled alternatives for the value domain are:

{% include github_alternatives.html class="it.unive.lisa.analysis.value.ValueDomain" %}

Finally, the bundled alternatives for the type domain are:

{% include github_alternatives.html class="it.unive.lisa.analysis.type.TypeDomain" %}

### Interprocedural Analysis and Call Graph

{% include config_option.html
name="interproceduralAnalysis"
type="InterproceduralAnalysis&lt;?, ?&gt;"
default="null"
example="conf.interproceduralAnalysis = new ModularWorstCaseAnalysis&lt;&gt;()"
%}

{% include config_option.html
name="callGraph"
type="CallGraph"
default="null"
example="conf.callGraph = new CHACallGraph()"
%}

{% include config_option.html
name="openCallPolicy"
type="OpenCallPolicy"
default="TopExecutionPolicy.INSTANCE"
example="conf.openCallPolicy = new CustomPolicy()"
%}

The [Interprocedural Analysis]({{ site.baseurl }}/documentation/interprocedural-analysis.html)
and the [Call Graph]({{ site.baseurl }}/documentation/call-graph.html)
regulate how the program-wide analysis is executed, and how calls are resolved
and computed. The value of the `interproceduralAnalysis` option determines the
interprocedural analysis to use, while the value of the `callGraph` option
determines the call graph.
If no value is set for `interproceduralAnalysis`, no
semantic analysis will be executed. Instead, the value of `callGraph` is
effectively ignored if the selected does not require
a call graph, as determined by that analysis' `needsCallGraph` method.
If instead the selected interprocedural analysis requires a call graph and no value is
set for `callGraph`, an error will be raised at startup.

The [Open Call Policy]({{ site.baseurl }}/documentation/interprocedural-analysis.html#handling-calls-with-no-targets)
is used to determine the results of calls that have no targets in the program to
analyze.

Several interprocedural analyses are available in LiSA:
{% include github_alternatives.html class="it.unive.lisa.interprocedural.InterproceduralAnalysis" %}

Orthogonally, call graphs implementations are also bundled with LiSA:
{% include github_alternatives.html class="it.unive.lisa.interprocedural.callgraph.CallGraph" %}

For open call policies, LiSA provides:
{% include github_alternatives.html class="it.unive.lisa.interprocedural.OpenCallPolicy" %}

### Adding Syntactic and Semantic Checks

{% include config_option.html
name="syntacticChecks"
type="Collection&lt;SyntacticCheck&gt;"
default="new HashSet&lt;&gt;()"
example="conf.syntacticChecks.add(new VariableNamesCheck())"
%}

{% include config_option.html
name="semanticChecks"
type="Collection&lt;SemanticCheck&lt;?, ?&gt;&gt;"
default="new HashSet&lt;&gt;()"
example="conf.semanticChecks.add(new NullDereferenceCheck())"
%}

[Syntactic Checks]({{ site.baseurl }}/documentation/checks.html) and
[Semantic Checks]({{ site.baseurl }}/documentation/checks.html) are visitors of
the program under analysis. Syntactic checks only require syntactic information,
and thus can be executed before the analysis, while semantic checks require
semantic information, and thus can only be executed after the analysis.
The collections of syntactic and semantic checks to execute can be customized
through the `syntacticChecks` and `semanticChecks` options, respectively.
The checks in these collections will be executed on the program under analysis, and
the results of the checks will be included in the final report. Note that
the order of execution of the checks is not guaranteed, and should not be relied upon.
The collection of syntactic checks to execute should only be added to, and not
replaced with other (possibly immutable) collections, as LiSA might add new
checks depending on the values of other options. The same applies to the
collection of semantic checks.

As of today, LiSA does not include any syntactic or semantic check
implementations, as they are highly situational.

<!-- Several syntactic checks are available in LiSA: -->
<!-- {% include github_alternatives.html class="it.unive.lisa.checks.syntactic.SyntacticCheck" %} -->
<!---->
<!-- Several semantic checks are available in LiSA: -->
<!-- {% include github_alternatives.html class="it.unive.lisa.checks.semantic.SemanticCheck" %} -->

### Thresholds for Widenings and GLBs

{% include config_option.html
name="wideningThreshold"
type="int"
default="5"
example="conf.wideningThreshold = 10"
%}

{% include config_option.html
name="recursionWideningThreshold"
type="int"
default="5"
example="conf.recursionWideningThreshold = 10"
%}

{% include config_option.html
name="glbThreshold"
type="int"
default="5"
example="conf.glbThreshold = 10"
%}

Fixpoint algorithms that use widenings and greatest lower
bounds (glbs) can be customized by setting the thresholds for the application of
the respective operators. `wideningThreshold` determines after how many iterations
of the fixpoint algorithm on a given node the widening operator should be applied
instead of the least upper bound operator (lub). `recursionWideningThreshold`
determines after how many iterations of the fixpoint algorithm on a recursive call
chain the widening operator should be applied instead of the least upper bound
operator (lub). `glbThreshold` determines how many descending iterations of the
fixpoint algorithm can be performed a given node using the greatest lower bound
operator (glb) before the descending iteration is stopped.

Setting these thresholds to `0` or a negative number causes the respective
operator to be always applied (for widenings) or to never be applied (for glbs).

### Selecting the Fixpoint Algorithms

{% include config_option.html
name="forwardFixpoint"
type="ForwardCFGFixpoint&lt;?, ?&gt;"
default="new ForwardAscendingFixpoint&lt;&gt;()"
example="conf.forwardFixpoint = new CustomForwardFixpoint&lt;&gt;()"
%}

{% include config_option.html
name="forwardDescendingFixpoint"
type="ForwardCFGFixpoint&lt;?, ?&gt;"
default="null"
example="conf.forwardDescendingFixpoint = new CustomForwardDescendingFixpoint&lt;&gt;()"
%}

{% include config_option.html
name="backwardFixpoint"
type="BackwardCFGFixpoint&lt;?, ?&gt;"
default="new BackwardAscendingFixpoint&lt;&gt;()"
example="conf.backwardFixpoint = new CustomBackwardFixpoint&lt;&gt;()"
%}

{% include config_option.html
name="backwardDescendingFixpoint"
type="BackwardCFGFixpoint&lt;?, ?&gt;"
default="null"
example="conf.backwardDescendingFixpoint = new CustomBackwardDescendingFixpoint&lt;&gt;()"
%}

{% include config_option.html
name="fixpointWorkingSet"
type="WorkingSet&lt;Statement&gt;"
default="new OrderBasedWorkingSet()"
example="conf.fixpointWorkingSet = new CustomWorkingSet&lt;&gt;()"
%}

All fixpoint algorithms that LiSA executes over
[control flow graphs]({{ site.baseurl }}/documentation/cfgs.html)
can be customized.
`forwardFixpoint` determines the fixpoint to compute forward fixpoints over
CFGs, while `backwardFixpoint` determines the fixpoint to compute backward
fixpoints over CFGs. The interprocedural analysis selected through the
[`interproceduralAnalysis` option](#interprocedural-analysis-and-call-graph)
determines whether forward and/or backward fixpoints are required, and thus
whether the values of these options are relevant.

Optionally, descending fixpoints can be computed after the ascending ones,
to refine the results. `forwardDescendingFixpoint` determines the fixpoint to
compute descending forward fixpoints over CFGs, while `backwardDescendingFixpoint`
determines the fixpoint to compute descending backward fixpoints over CFGs. If
no value is set for `forwardDescendingFixpoint` or `backwardDescendingFixpoint`,
no descending phase will be executed.

The order in which the nodes of the CFG are visited during fixpoint iterations
is determined by the `WorkingSet` passed to the `fixpointWorkingSet` option.

In all options above, the instances passed to the fields are used as factories
to create new fixpoint instances or new working sets.

LiSA provides standard forward fixpoint algorithms, alongside their optimized variants:
{% include github_alternatives.html class="it.unive.lisa.program.cfg.fixpoints.forward.ForwardCFGFixpoint" %}

These are paired with their backward variants:
{% include github_alternatives.html class="it.unive.lisa.program.cfg.fixpoints.backward.BackwardCFGFixpoint" %}

Each fixpoint implementation can be customized by the following bundled working sets:
{% include github_alternatives.html class="it.unive.lisa.util.collections.workset.WorkingSet" %}

### Optimization-related Options

{% include config_option.html
name="useWideningPoints"
type="boolean"
default="true"
example="conf.useWideningPoints = false"
%}

{% include config_option.html
name="hotspots"
type="Predicate&lt;Statement&gt;"
default="null"
example="conf.hotspots = stmt -&gt; stmt instanceof Assignment"
%}

{% include config_option.html
name="dumpForcesUnwinding"
type="boolean"
default="false"
example="conf.dumpForcesUnwinding = true"
%}

LiSA can be optimized in several ways. A simple optimization is to use
widenings and narrowings only on widening points (i.e., loop conditions),
and to use lubs and glbs on all other nodes regardless of the threshold.
This is typically more efficient, as widening and narrowing are more expensive
than lub and glb, and the results of lubs and glbs are often more precise
than those of widenings and narrowings. This behavior can be enabled by
setting the `useWideningPoints` option to `true`. Note that widening points
correspond to the conditions of loops, as identified by `CFG.getCycleEntries()`.

A second optimization is to use
[optimized fixpoint algorithms]({{ site.baseurl }}/documentation/interprocedural-analysis.html#optimized-fixpoints)
(i.e., algorithms for which invocations of
`AnalysisFixpoint.isOptimized()` on [`forwardFixpoint`](#selecting-the-fixpoint-algorithms),
[`forwardDescendingFixpoint`](#selecting-the-fixpoint-algorithms),
[`backwardFixpoint`](#selecting-the-fixpoint-algorithms), or
[`backwardDescendingFixpoint`](#selecting-the-fixpoint-algorithms)
yields `true` --- these correspond to the ones having `Optimized` in their name).
Such algorithms exploit basic blocks, and store the fixpoint results only for
widening points (i.e., loop conditions), return statements, and calls. This is
doable since results for any other instruction can be recontsructed by executing
a single fixpoint iteration local to the CFG that contains the instruction,
that will stabilize in one iteration since the results of widening points is
already a post-fixpoint. This reconstruction is called _unwinding_ in LiSA.
When such algorithms are used, the `hotspots` predicate can be set to determine
additional statements for which the fixpoint results must be kept to avoid
excessive unwinding. `null` is a special value corresponding to the predicate `t
-> false`. Instead, `dumpForcesUnwinding` can be set to `true` to
force unwinding of all non-hotspot statements when dumping results to output
files, to ensure that results are available for all program instructions.

### Hiding Error and Exceptions

{% include config_option.html
name="shouldSmashError"
type="Predicate&lt;Type&gt;"
default="null"
example="conf.shouldSmashError = type -&gt; type.getName().equals(\"java.lang.NullPointerException\")"
%}

Some error typems might pollute the analysis results, since they might not be
relevant for the properties to prove or they are caused by an excessive
imprecision of the analysis. While it is not possible to completely remove them
(as the modifications they cause to the control flow must be taken into
account), it is possible to _smash_ them, that is, to not have a separate entry
for each of their occurrences in the
[`AnalysisState` errors]({{ site.baseurl }}/documentation/lattices.html#the-analysis-state).
Instead, all occurrences of smashed errors will share a unique `ProgramState`.
The choice over what error types to smash is determined by the `shouldSmashError`
predicate, that returns `true` for the types of errors to smash. `null` is a
special value corresponding to the predicate `t -> false`.

### Event Listeners

{% include config_option.html
name="synchronousListeners"
type="List&lt;EventListener&gt;"
default="new LinkedList&lt;&gt;()"
example="conf.synchronousListeners.add(new LoggingListener())"
%}

{% include config_option.html
name="asynchronousListeners"
type="List&lt;EventListener&gt;"
default="new LinkedList&lt;&gt;()"
example="conf.asynchronousListeners.add(new TracingListener())"
%}

[`EventListener`s]({{ site.baseurl }}/documentation/events.html) can be
registered to process events emitted during the analysis. Listeners can be
either synchronous or asynchronous, and are registered through the
`synchronousListeners` and `asynchronousListeners` options, respectively.
Synchronous listeners will be executed in the same thread as the analysis
itself, and thus will block the analysis until they complete. Asynchronous
listeners will be executed in a separate thread, and thus will not block the
analysis. Synchronous listeners are executed before asynchronous ones, and
the order of execution of the listeners preservers the insertion order into
the respective collection.
The lists of listeners should only be added to, and not
replaced with other (possibly immutable) lists, as LiSA might add new
listeners depending on the values of other options.

LiSA bundles the following event listeners, that can be used both synchronously and asynchronously:
{% include github_alternatives.html class="it.unive.lisa.events.EventListener" %}

When implementinc custom listeners, the following events are issued automatically by the analysis:
{% include github_alternatives.html class="it.unive.lisa.events.Event" %}

### Producing Outputs

{% include config_option.html
name="workdir"
type="String"
default="Paths.get(\".\").toAbsolutePath().normalize().toString()"
example="conf.workdir = \"/tmp/lisa-analysis\""
%}

{% include config_option.html
name="outputs"
type="Collection&lt;LiSAOutput&gt;"
default="new HashSet&lt;&gt;()"
example="conf.outputs.add(new JsonReport())"
%}

All [Outputs]({{ site.baseurl }}/documentation/outputs.html) produced by LiSA
are generated inside the working directory specified by the `workdir` option.
By default, the working directory is the directory where the JVM executing LiSA
was launched, but it can be customized by setting the `workdir` option to a
different path. To generate a new output, it is sufficient to add it to the
collection of outputs specified by the `outputs` option. Note that the order of
generation of the outputs is not guaranteed, and should not be relied upon.
The collection of outputs to produce should only be added to, and not replaced with
other (possibly immutable) collections, as LiSA might add new outputs depending on
on the values of other options.

LiSA includes the following output generators:
{% include github_alternatives.html class="it.unive.lisa.outputs.LiSAOutput" %}

## Logging

Logging is not configured through the `LiSAConfiguration` object. LiSA produces
all logging through [log4j2](https://logging.apache.org/log4j/2.x/index.html),
and will thus follow the framework's own configuration. There are a number of
ways to configure log4j2, but the simplest one is to create a `log4j2.xml` file
in the working directory, with the desired configuration. For example, the
following configuration will log all messages of level `DEBUG` or higher to a file
the console:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="WARN" name="DefaultLoggingConf">
  <Appenders>
    <Console name="console">
      <PatternLayout pattern="%d [%5level] %m %ex%n"/>
    </Console>
  </Appenders>

  <Loggers>
    <Logger name="it.unive.lisa" level="DEBUG" />
    <Logger name="org.reflections" level="WARN" />

    <Root level="DEBUG">
      <AppenderRef ref="console" level="DEBUG"/>
    </Root>
  </Loggers>
</Configuration>
```

Please check [log4j2's documentation](https://logging.apache.org/log4j/2.x/manual/configuration.html)
for more details on how to configure logging.

{% include tip.html
content="If no logging is configured, LiSA will set up a default configuration
that logs to the console only." %}

## Default and Test Configuration

LiSA also offers a class named `DefaultConfiguration`, that provides a default
value for interprocedural analysis and call graph. It also offers utility
methods for building an abstract domain following the
[Simple Abstract Domain framework]({{ site.baseurl }}/documentation/simple-abstract-domain.html).

A common use case when developing static analyzers is to have end-to-end tests
that starts from an input file and the necessary configuration, execute a full
analysis as a black box, and compare the results obtained with some pre-existing
results. LiSA provides a unique infrastructure for this use case to simplify
testing. A `TestConfiguration` is a `LiSAConfiguration` extended with the
following fields:

- `testDir` defines the relative path to the root folder where test files are located;
- `testSubDir` defines an optional path relative to `testDir` to use as workdir
  for the analysis, useful to keep output files separated for similar tests;
- `programFile` holds the name of the source file to analyze, relative to
  `testDir`;
- `forceUpdate` specifies that, should any difference be found between the
  results of the analysis and the pre-existing results, the pre-existing results
  should be updated with the new results instead of raising an error;
- `compareWithOptimization` specifies that, should no difference be found between
  the results of the analysis and the pre-existing results, the analysis should be
  executed again with optimizations enabled, and the results of the optimized analysis
  should be compared with the pre-existing results as well, to check that optimizations
  do not change the results of the analysis;
- `resultComparer` holds a reference to the `ResultComparer` instance to use to
  compare the results of the analysis with the pre-existing results, that can be
  customized to ignore irrelevant differences between the results or additional
  analyzer-specific settings.

A `TestConfiguration` can be used with an instance of `AnalysisTestExecutor`, an
abstract class defined in LiSA to provide the standard workflow for executing
end-to-end tests. The class has a constructor that takes the path to the
expected results folder, where the pre-existing results are located, and a path
to the actual results folder, where test files for produced by the analysis will
be generated. The analysis is started by invoking one of the `perform`
overloads, each accepting a `TestConfiguration` and optionally an already parsed
`Program`. If the program is not provided, the abstract `readProgram` method
will be invoked to parse the file located at `expected-dir/testDir/programFile`.
Then, the execution proceeds as follows (in the following, if `testSubDir` is
`null`, `testDir/testSubDir` should be read as `testDir`):

1. the folder `actual-dir/testDir/testSubDir` is cleared of all files, and it is
   set as workdir for the analysis;
2. an instance of `JSONReportDumper` is added to the outputs to produce;
3. a `LiSA` instance is created with the `TestConfiguration` as configuration, and it is
   run on the parsed program;
4. if no `expected-dir/testDir/testSubDir/report.json` file exists and
   `forceUpdate` is not set, the execution terminates;
5. if no `expected-dir/testDir/testSubDir/report.json` file exists and
   `forceUpdate` is set, the contents of the workdir will be copied to
   `expected-dir/testDir/testSubDir`, and the execution terminates;
6. if `expected-dir/testDir/testSubDir/report.json` exists and `forceUpdate` is
   not set, the `resultComparer` is used to compare it with
   `actual-dir/testDir/testSubDir/report.json`, raising an exception if there are
   any differences;
7. if `expected-dir/testDir/testSubDir/report.json` exists and `forceUpdate` is
   set, the `resultComparer` is used to compare it with
   `actual-dir/testDir/testSubDir/report.json`, and all files where at least one
   difference is found are copied from the workdir to
   `expected-dir/testDir/testSubDir`, replacing the pre-existing files;
8. if `compareWithOptimization` is not set, or if it is set but the fixpoints
   used were already optimized, the execution terminates;
9. if `compareWithOptimization` is set and the fixpoints used were not already
   optimized, the whole process is repeated with the same configuration but with
   optimized fixpoints, and the results of the optimized analysis are compared with
   the pre-existing results as well, raising an exception if there are any
   differences (in this run, `forceUpdate` is ignored).

Alternatively to `forceUpdate`, the `lisa.cron.update` system property can be set
to `true` to achieve the same effect.

## Frontends

Frontends for several languages have been developed over the years. Recall that
frontends are not part of LiSA, but rather they are fully-fledged static
analysers that use LiSA as a library to execute the analysis. They can be used
as-is, can be extended, or can be used as examples to build new frontends for
other languages. For more details on how to build a frontend, please check the
[frontend documentation]({{ site.baseurl }}/documentation/frontends.html).

**GoLiSA**

GoLiSA is a frontend for a subset of the Go programming language. It has been
developed with the objective of performing analyses targeting security
properties of blockchain software and smart contracts, focusing on the
frameworks Hyperledger Fabric, Cosmos SDK, Ethereum Client, and Tendermint Core.
The properties targeted include harmful usage of non-deterministic APIs and
constructs, dangerous cross-contract invocations, and read-write
inconsistencies.

For more information on features and usage, refer to the
[GitHub repository](https://github.com/lisa-analyzer/go-lisa).

**JLiSA**

JLiSA is a frontend for a subset of the Java programming language, developed
primarely for the [SV-COMP](https://sv-comp.sosy-lab.org/) competition.
It is able to identify failing assertions and uncaught runtime exceptions,
and models a subset of the Java APIs.

For more information on features and usage, refer to the
[GitHub repository](https://github.com/lisa-analyzer/jlisa).

**PyLiSA**

PyLiSA is a highly-experimental frontend for a subset of the Python programming language.
Specifically, it does not yet support any dynamic features related to changes to the program
structure (e.g., dynamic code loading, dynamic attribute access, etc.), and it only supports
a subset of the Python APIs.
PyLiSA has been developed for two distinct scenarios: the analysis of Data
Science scripts using Pandas, and the reconstruction of architectural diagrams
for ROS2 robotic networks.

For more information on features and usage, refer to the
[GitHub repository](https://github.com/lisa-analyzer/pylisa).

**EVMLiSA**

EVMLiSA is a frontend for EVM bytecode aimed at soundly reconstructing a full
and sound control flow graph from the bytecode itself, that can be used in later
analyses. The reconstruction can optionally be made aware of the current global
storage to improve the accuracy of the generated control flow graph.

For more information on features and usage, refer to the
[GitHub repository](https://github.com/lisa-analyzer/evm-lisa).

**MichelsonLiSA**

MichelsonLiSA is a frontend for Michelson bytecode obtained by the compilation
of smart contracts for Tezos blockchains.
It is based on an SSA translation of the bytecode, and it is aimed at detecting
cross-contracts invocations.

For more information on features and usage, refer to the
[GitHub repository](https://github.com/lisa-analyzer/michelson-lisa).

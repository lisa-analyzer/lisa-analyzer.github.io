---
layout: docpage
prereq:
  - text: Lattices and Domain Lattices
    link: documentation/lattices.html
  - text: Scoped Objects
    link: documentation/common-interfaces.html#the-scoped-object-interface
  - text: Semantic Domains
    link: documentation/semantic-domains.html
  - text: Symbolic Expressions
    link: documentation/symbolic-expressions.html
---

# Interprocedural Analyses

The Interprocedural Analysis is the component that oversees the whole analysis.
It is the entry point that LiSA uses to start the analysis, and it is
responsible for computing an over-approximation of what the program computes.
This directly translates to the Interprocedural Analysis having two main duties:

- selecting which [CFGs]({{ site.baseurl }}/documentation/cfgs.html) to start the
  analysis from (i.e., the analysis _entry points_) and analyze them;
- computing the results of calls found in one of the starting CFGs or in any of
  of their transitive callees.

These two duties are heavily intertwined. For instance, the second one may lead to the
discovery of new CFGs to analyze, which in turn may lead to the discovery of more calls,
and so on. On the other hand, the first one migth start from CFGs that do not contain
any call, later moving to their callers. In this case, the results of calls must
be computed by accessing results of already analyzed CFGs.

The contents of this page are presented bottom-up, starting from how fixpoints over
CFGs are computed and other prerequisites, and then moving to the
Interprocedural Analysis interface.

{% include diagrams.html %}

## CFG Fixpoints

CFGs contain the code that must be analyzed. In terms of Abstract
Interpretation, this means executing a fixpoint computation over the code it
contains, propagating the entry state from node to node to track its evolution.
Since CFGs are graphs, the classic worklist-based fixpoint algorightm is
suitable for analyzing them. The pseudocode (written in Python for conciseness)
for this algorithm is the following:

```py
def fixpoint(cfg, state):
  results = {}
  worklist = [start(cfg)]
  for node in cfg.nodes:
    results[node] = bottom
  while worklist:
    node = worklist.pop()
    if node in start(cfg):
      pre = state
    else:
      pre = lub([traverse(edge, results[edge.source]) for edge in edges(cfg, node)])
    res = semantics(node, pre)
    if not compare(res, results[node]):
      results[node] = join(results[node], res)
      worklist.extend(succ(cfg, node))
  return results
```

where:

- `start` selects the nodes of the CFG to use as starting points for the
  computation;
- `edges` selects the edges connected to the node to gather its directional
  predecessors;
- `succ` selects the nodes that are reachable from the given node;
- `semantics` computes the semantics of the node to evolve the given state;
- `traverse` modifies the given state according to the semantics of the edge
  (e.g., unconditional traversal or traversal only if a condition is satisfied);
- `compare` checks if the partial order holds between the two given states;
- `join` computes a join that is specific for a previous and a new state.

The definition is generic and can be instantiated in different ways.
LiSA provides the following instantiations, that combine
different directions and traversal stategies. A fixpoint is **forward** if
`start` selects the entry nodes of the CFG, `edges` selects the edges incoming
into the given node, and `succ` selects the successors of the given node.
Instead, a fixpoint is **backward** if `start` selects the exit nodes of the
CFG, `edges` selects the edges outgoing from the given node, and `succ` selects
the predecessors of the given node.
Orthogonally, a fixpoint is **ascending** if `join` moves upwards in the odreded
structure (e.g., with lub), and `compare` uses the partial order of
the domain to compare the most recent result with the older one (i.e.,
`new.leq(old)`). Instead, a
fixpoint is **descending** if `join` moves downwards in the odreded structure
(e.g., with glb), and `compare` uses the partial order of the domain to compare
the older result with the most recent one (i.e., `old.leq(new)`).

LiSA provides the following concrete fixpoint implementations:

- `ForwardAscendingFixpoint`, that is forward and ascending, and whose `join`
  uses `upchain` until a threshold is reached, after which it uses `widening`;
- `ForwardDescendingGLBFixpoint`, that is forward and descending, and whose
  `join` uses `downchain` until a threshold is reached, after which the previous
  value is kept;
- `ForwardDescendingNarrowingFixpoint`, that is forward and descending, and
  whose `join` uses `narrowing`;
- `BackwardAscendingFixpoint`, that is backward and ascending, and whose `join`
  uses `upchain` until a threshold is reached, after which it uses `widening`;
- `BackwardDescendingGLBFixpoint`, that is backward and descending, and whose
  `join` uses `downchain` until a threshold is reached, after which the previous
  value is kept;
- `BackwardDescendingNarrowingFixpoint`, that is backward and descending, and
  whose `join` uses `narrowing`.

LiSA's [configuration]({{ site.baseurl }}/configuration/) allows to select
one forward ascending fixpoint, one forward descending fixpoint, one backward
ascending fixpoint, and one backward descending fixpoint. The interprocedural
analysis will invoke either `CFG.fixpoint` or `CFG.backwardFixpoint` to compute
the fixpoint of a CFG, and the correspoding implementations will be selected
from the configuration. Both methods will run the ascending fixpoint first,
starting from an empty result, and the use the result to kickstart the
descending fixpoint _only if it has been provided_. The descending phase is thus
optional.

Results returned by `CFG.fixpoint` and `CFG.backwardFixpoint` are stored in
`AnalyzedCFG`s and `BackwardAnalyzedCFG`s, respectively:

<center> <img src="{{ site.baseurl }}/documentation/analyzedcfgs.png" alt="Fixpoint results classes"/> </center>

These are parametric to the type `A extends AbstractLattice<A>` that the results
(i.e., `AnalysisState<A>` instances) contain, and are subclasses of `CFG`
that contains methods to query the computed states
before or after a node, and of `BaseLattice<AnalyzedCFG<A>>` and
`BaseLattice<BackwardAnalyzedCFG<A>>`, respectively. Both classes provide
avenues for retrieving the entry or exist state of the whole `CFG` or of
individual nodes (i.e., [Statement]({{ site.baseurl }}/documentation/st-ex-e.html) instances).
Each result is identified by a `ScopeId`, that will be
explained together with the interprocedural analysis interface.

For a list of fixpoint algorithms already implemented in LiSA, see the
[Configuration]({{ site.baseurl }}/configuration/#selecting-the-fixpoint-algorithms) page.

### Optimized fixpoints

Fixpoints can be **optimized**, as in they can be executed over the basic blocks
of each CFG instead of the single nodes. When an optimized fixpoint is passed in
the configuration, LiSA will compute the basic blocks of each CFG at the start
of the analysis (see [the CFG page]({{ site.baseurl }}/documentation/cfgs.html)
for more details). Then, the fixpoints will proceed as if each basic block is a
single node whose semantics is the composition of the semantics of the nodes it
contains. This allows to skip both the traversal of the edges between nodes in
the same basic block and the comparison of the results of each node, thus
significantly reducing the time required to compute the fixpoint. Furthermore,
after the fixpoint completes, **all** results are removed except for (i) the
state after each widening point (e.g., loop guard) and (ii) the state after each call.
This reduces memory consumption, and the results that have been forgotten can
be recomputed with a single local fixpoint iteration. This process is called **unwinding**
in LiSA.

All fixpoint implementations provided by LiSA have an optimized version:
`OptimizedForwardAscendingFixpoint`, `OptimizedForwardDescendingGLBFixpoint`,
`OptimizedForwardDescendingNarrowingFixpoint`, `OptimizedBackwardAscendingFixpoint`,
`OptimizedBackwardDescendingGLBFixpoint`, and `OptimizedBackwardDescendingNarrowingFixpoint`.
These can be passed in the configuration using the same options.

A common situation for static analyzers is to have visitors inspecting the
semantic results to issue warnings. In such a situation, the optimizations
performed by the above fixpoints would be nullified as unwinding is needed at
every program point that needs to be inspected. For this reason, as part of the
[configuration]({{ site.baseurl }}/configuration/), LiSA allows to select additional
instructions for which the results of fixpoints must be kept to avoid excessive
unwinding. The `hotspots` option is a predicate that, whenever it holds for a
node, forces the fixpoint to keep the results of that node even when an
optimized fixpoint is used. This allows to keep the results of nodes that are
relevant for the analysis, while still benefiting from the optimizations for the
rest of the nodes.

Results of optimized fixpoints are stored in `OptimizedAnalyzedCFG`s and
`OptimizedBackwardAnalyzedCFG`s, respectively:

<center> <img src="{{ site.baseurl }}/documentation/optanalyzedcfgs.png" alt="Optimized fixpoint results classes" style="width: 60%"/> </center>

These inherit from `AnalyzedCFG` and `BackwardAnalyzedCFG`, respectively, and
add as type parameter the type `D extends AbstractDomain<A>` that the analysis
executes (necessary for performing unwinding). The main difference w.r.t. their
base classes is that they offer methods to unwind the results (`unwind`) or to
unwind only if necessary (`getUnwindedAnalysisStateAfter`/`Before`).

## Prerequisites

### The Fixpoint Configuration

Analysis options that are related to fixpoint executions are passed around
relevant methods through the `FixpointConfiguration` class, that mainly holds
values that have been passed in the main configuration:

<center> <img src="{{ site.baseurl }}/documentation/fixconf.png" alt="The Fixpoint Configuration class" style="width: 50%"/> </center>

The configuration holds (i) the instance of `WorkingSet` to use in fixpoints,
that can be used to tune the order in which nodes are analyzed, (ii) several
thresholds for widening and glb applications inside fixpoints, (iii) the
instances of fixpoint algorithms selected for the analysis, (iv) whether or not
widening/narrowing should be applied only to widening points (`useWideningPoints`),
and (v) the predicate for selecting hotspots (`hotspots`). The two methods serve
as predicates to check if optimizations are enabled.

### Scope Identifiers

A single CFG can be analyzed multiple times during the analysis, for instance
when its code is invoked at different call sites. If Interprocedural Analyses
want to distinguish between different invocations of the same CFG, they must
identify them by abstracting the concrete call stack. This is modeled in LiSA
with the `ScopeId` class:

<center> <img src="{{ site.baseurl }}/documentation/scopeids.png" alt="Scope Identifiers" style="width: 40%"/> </center>

A `ScopeId` is parametric to the type `A extends AbstractLattice<A>` of the
states that the analysis computes. There is no particular structure required for
its instances: different analyses can abstract different parts of the call stack
(e.g., the call sites, the height of the stack, the states reaching each call
site, etc.). Each implementation must provide three methods:

- `startingId`, that returns the `ScopeId` to use for the initial CFGs selected
  as entry points for the analysis;
- `isStartingId`, that checks if a given `ScopeId` is a starting one;
- `push`, that returns a new `ScopeId` that abstracts the call stack obtained by
  performing the given call `c`, reached with state `state`, on the current
  `ScopeId` (i.e., `this`).

In `push` the type of the parameter `c` is `CFGCall`. The `Call` hierarchy is
discussed in the [Call Graph]({{ site.baseurl }}/documentation/call-graph.html) page,
but it is sufficient to know that it models calls that have been resolved and
whose targets are CFGs under analysis.

If analyses do not distinguish between different invocations of the same CFG,
they can use the `UniqueScope` class as `ScopeId`, that abstracts the whole call
stack as a single element. Results from different calls will thus be merged
together.

### Handling Calls with no Targets

In LiSA, `OpenCall`s are calls that have been resolved, but no viable target
has been found inside the program under analysis (the `Call` hierarchy is
discussed in more depth in the [Call Graph]({{ site.baseurl }}/documentation/call-graph.html) page).
The handling of such calls independent of the Interprocedural Analysis:
regardless of the technique used to compute the results of calls, if no targets
are available than no reasoning can be performed on the call.

To avoid reimplementation of Interprocedural Analyses that just differ in how
they handle `OpenCall`s, LiSA provides the `OpenCallPolicy` interface, that defines
the policy to apply when an `OpenCall` is encountered during the analysis:

<center> <img src="{{ site.baseurl }}/documentation/opencallpolicy.png" alt="Policies for Open Calls" style="width: 80%"/> </center>

An `OpenCallPolicy` is simply a wrapper around the `apply` method, parametric on
the types `A extends AbstractLattice<A>` of states that the analysis computes
and `D extends AbstractDomain<A>` of the domain that the analysis executes,
that computes the effects of the `OpenCall` on a given state. The method has
access to all the semantic information (i.e., the `entryState` and the `params`
of the call), together with the `call` itself, to produce any sound (or
reasonable) result.

LiSA provides three base implementations of `OpenCallPolicy`:

- `WorstCasePolicy`, that is the only fully sound policy, that returns the top
  element of the domain for any call, thus assuming that the open call can do
  anything to the program state _and_ can raise any error;
- `TopExecutionPolicy`, that assumes that the call does not raise any errors,
  but can still tamper with the execution state in any way (in practice, this
  corresponds to setting the state's [normal execution]({{ site.baseurl
  }}/documentation/lattices.html#the-analysis-state) to the top element of the
  domain while leaving the other continuations unchanged);
- `ReturnTopPolicy`, that assumes that the call does not raise any errors,
  cannot tamper with the execution state, but it has an unknown return value
  (in practice, this corresponds to returning the same state with a `PushAny`
  [symbolic expression]({{ site.baseurl }}/documentation/symbolic-expressions.html)
  as normal execution's computed expression).

These are just commonly used policies, but users can implement their own
policies. For a list of policies already implemented in LiSA, see the
[Configuration]({{ site.baseurl }}/configuration/#interprocedural-analysis-and-call-graph) page.

### Storing Fixpoint Results

All Interprocedural Analyses have to store the results of each CFG fixpoints for
later usage, e.g., for producing [outputs]({{ site.baseurl }}/documentation/outputs.html)
or executing [semantic checks]({{ site.baseurl }}/documentation/checks.html).
Storage is centralized in two classes, `FixpointResults` and `CFGResults`:

<center> <img src="{{ site.baseurl }}/documentation/fixres.png" alt="Classes for storing fixpoint results"/> </center>

`CFGResults`, parametric on the type `A extends AbstractLattice<A>` of the states that the
analysis computes, is a function from `ScopeId`s to `AnalyzedCFG`s. It provides
avenues for querying if a result is present for the given `token` through
`contains`, and for retrieving the result through `get`. Instead, `getAll`
returns the flat collection of all values of the mapping, i.e., all the `AnalyzedCFG`s.
To store new results, `putResult` is provided. This method takes as parameters
the `ScopeId` to which the result belongs, and the `AnalyzedCFG` to store.
The method returns a pair of a boolean and an
`AnalyzedCFG` according to the following rules (where `prev` is the previous
result stored for `token`):

- if no `prev` is present, than `token` is mapped to `result` and the method
  returns `(false, result)`;
- if `leq(prev, result)`, than `token` is mapped to `result` and the method
  returns `(true, result)`;
- if `leq(result, prev)`, than the mapping is left unchanged and the method
  returns `(false, prev)`;
- if `prev` and `result` are not comparable, than the mapping is left unchanged
  and the method returns `(true, lub(prev, result))`.

The meaning of the returned pair is to be interpreted in terms of soundness:
since the stored mapping must be an over-approximation for the given scope,
one cannot simply store. Instead, the logic ensures that the result stored after
the call is always the least precise one (i.e., the one that guarantees the
over-approximation), and that is returned as second element of the pair for
later usage by the Interprocedural Analysis. The boolean returned as first
element is a flag that indicates whether the storage operation caused existing
results to be invalidated, requiring the Interprocedural Analysis to reanalyze
some CFGs.

`FixpointResults`, parametric on the type `A extends AbstractLattice<A>` of the states that the
analysis computes, lifts the mapping of `CFGResults` back to `CFG`s, so that
all results for a given `CFG` can be retrieved regardless of the `ScopeId` they belong to.
Note that `FixpointResults`'s `putResult` operates according to the same rules
of `CFGResults`'s `putResult`.

## The Interprocedural Analysis Interface

The `InterproceduralAnalysis` interface defines all operations that an
Interprocedural Analysis must implement to be executed by LiSA:

<center> <img src="{{ site.baseurl }}/documentation/interproc.png" alt="The Interprocedural Analysis Interface" style="width: 70%"/> </center>

The analysis is _initialized_ by LiSA by calling the `init` method, that passes
the analysis-specific configuration:

- the [Application]({{ site.baseurl }}/documentation/units.html#application) to
  analyze;
- the [Call Graph]({{ site.baseurl }}/documentation/call-graph.html) to use for
  call resolution;
- the `OpenCallPolicy` configured by the user;
- the [Event Queue]({{ site.baseurl }}/documentation/events.html) to use for
  emitting events during the analysis;
- the `Analysis` built with the `AbstractDomain` configured by the user.

Note that the call graph is optional: the user might not select one for the
analysis. If the `InterproceduralAnalysis` implementation requires a call graph,
`needsCallGraph` must return `true`, and LiSA will throw an exception if no
call graph is provided. If `needsCallGraph` returns `false`, the call graph
parameter might be `null`. Furthermore, as noted in the
[Event Queue]({{ site.baseurl }}/documentation/events.html) page, the event
queue won't be created if no listeners are registered for the analysis,
so the parameter might be `null`. Usages of the event queue should be
null-checked before emitting events.

The `fixpoint` method is the main entry point for the analysis, and is called
by LiSA to compute a program-wide fixpoint over all the code that has been
passed in the application. The method is passed an initial `AnalysisState` to
start the analysis from, and a `FixpointConfiguration` to use for fixpoint
executions. The method must proceed in starting the analysis by selecting
the CFGs to analyze as entry points, and executing a forward or backward
fixpoint over them. For reproducibility, it is highly advised that the order in
which entry points are analyzed is deterministic, e.g., by sorting them according
to their signature. The method must not return anything: during the analysis,
results of fixpoints must be stored in a `FixpointResults` instance, that is
returned by the `getFixpointResults` method. Invoking this method before
the analysis has been completed will return partial and possibly unsound
results. Results of individual CFGs can be obtained through the
`getAnalysisResultsOf` method, that returns a flattened view of the fixpoint
results for all `ScopeId`s of the given `CFG`.

For a list of interprocedural analyses already implemented in LiSA, see the
[Configuration]({{ site.baseurl }}/configuration/#interprocedural-analysis-and-call-graph) page.

### Handling Calls

The remaining three methods, namely `resolve` and the two `getAbstractResultOf`
overloads, are related to the handling of calls.

If the analysis is _intraprocedural_, as in it does not model calls from one CFG to another,
then `resolve` can return an `OpenCall` (i.e., a call that has been resolved,
but no viable target has been found inside the program under analysis ---
see the `Call` hierarchy in the [Call Graph]({{ site.baseurl }}/documentation/call-graph.html) page)
for any call, that will result in the invocation of the `getAbstractResultOf`
overload accepting the open call. Otherwise, the analysis should rely on the
`CallGraph` instance received in `init` to resolve calls through it's own
`resolve` method, and return the resulting `Call`.

As discussed above, `OpenCall`s are handled according to the `OpenCallPolicy`
configured for the analysis: the `getAbstractResultOf` overload accepting an
`OpenCall` should delegate to the policy's `apply` method to compute the result.
Instead, the `getAbstractResultOf` overload accepting a `CFGCall`
(i.e., a call that has been resolved and whose targets are CFGs under analysis ---
see the `Call` hierarchy in the [Call Graph]({{ site.baseurl }}/documentation/call-graph.html) page)
should:

1. inform the `CallGraph` that the call is being executed by invoking the
   `registerCall` method, so that it can be tracked in the graph's structure;
2. update the current `ScopeId` if necessary by invoking the `push` method;
3. compute the result of the call **for each target independently** by:
   1. using the program's [Scoping Logic]({{ site.baseurl }}/documentation/language-features-and-type-system.html#the-scoping-logic)
      to hide the caller's variables behind the call site
      (see [Scoped Objects]({{ site.baseurl }}/documentation/common-interfaces.html#the-scoped-object-interface) for more details);
   2. using the program's [Assigning Strategy]({{ site.baseurl }}/documentation/language-features-and-type-system.html#the-assigning-strategy)
      to assign the actual parameters of the call to the formal parameters of the callee;
   3. computing the result of invoking the target (e.g., by running a fixpoint
      over the target's CFG or by accessing a previously computed result);
   4. using the program's [Scoping Logic]({{ site.baseurl }}/documentation/language-features-and-type-system.html#the-scoping-logic)
      to remove the callee's variables and restore the caller's ones;
   5. performing cleanup operations through `Analysis.transferThrowers` and
      `Analysis.onCallReturn`;
4. joining the results of each target together.

This general workflow might need slight adaptations depending on the particular
Interprocedural Analysis being implemented.

Note that `return` and `throw` statements will leave on the state's
`computedExpression` a special `Identifier` (either a `CFGReturn` or a `CFGThrow`

---

see the [Identifiers]({{ site.baseurl }}/documentation/symbolic-expressions.html#identifiers) page)
that will contain all [Annotations]({{ site.baseurl }}/documentation/annotations.html)
defined in the target CFG. This allows the propagation of invariants defined
through annotations from the callee to the caller.

### Analyses based on Call Graphs

If an Interprocedural Analysis relies on a call graph, it is highly advised to
inherit from `CallGraphBasedAnalysis`. The class provides default
implementations for `init`, that stores all the parameters in the class' fields,
`resolve`, that delegates to the call graph's `resolve` method, `getAbstractResultOf`
for `OpenCall`s, that delegates to the `OpenCallPolicy`, and `needsCallGraph`,
that returns `true`. Moreover, it already implements the logic for creating
an entry state for the prorgam's entry points by assigning unknown values
to each parameter of the entry points.

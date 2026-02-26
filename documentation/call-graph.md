---
layout: docpage
---

# Call Graphs

The call graph in LiSA has a dual responsibility: it implements the logic for
resolving a call to its targets, and it keeps track of the callees and callers
of each control flow graph. The latter is the cause for the `CallGraph`
inheriting from the `BaseGraph` class, a simple graph implementation provided by
LiSA based on an adjacency list. The latter class won't be detailed here, as it
mostly provides standard constructs for graph manipulation (e.g., adding and
removing nodes and edges, iterating over the graph, etc.).

{% include diagrams.html %}

## Calls

Understanding how calls are represented in LiSA is crucial to reason on the
call graph. The `Call` class is the root of the call hierarchy, and contains the
general structure that is shared among all call types.

<center> <img src="{{ site.baseurl }}/documentation/calls.png" alt="The Call class hierarchy" /> </center>

The superclass of `Call`, the `NaryExpression` class, is detailed in the
[expressions page]({{ site.baseurl }}/documentation/st-ex-e.html): for the
contents of this page, it suffices to know that it is a generalization of
an expression that can have zero or more sub-expressions. The `Call` abstract
class defines the components of a call's signature: the name of the target
program member that is being invoked (`getTargetName`), the qualifier of the
call, if any (`getQualifier` --- an optional string that is used to refer to
the unit in which the target member is declared, e.g., a class name for a Java
static method call, or a module name for a Python function call), and the arguments
passed to the call (`getParameters`).

In addition, each call has a type (`getCallType`), that is defined through an
enumeration that can assume values `STATIC`, `INSTANCE`, or `UNKNOWN`. The call
type is meant as a way to instruct the call graph on how to resolve the call.
A `STATIC` call is a call that does not have
a receiver: during resolution, targets will be searched in the whole program,
optionally restricting the search to types that match the qualifier, if any.
An `INSTANCE` call instead is a call that has a receiver: the type
of the first parameter determines the leaf of the type hierarchy where the call
targets are to be searched, that is traversed upwards as is typical of
object-oriented languages. An `UNKNOWN` call is a call for which it is not
possible to determine whether it has a receiver or not at parse time,
for which both resolutions are attempted.

The most common call instance that is produced by frontends is the
`UnresolvedCall`: a call that has not been resolved yet, and that must be
handled by the call graph to determine its targets. Since the resolution of an
`UnresolvedCall` leads to the creation of a second call, the `Call` class offers
means to record the `UnresolvedCall` that led to its creation: using
`setSource`, one can record that a call originated from a given `UnresolvedCall`,
that can be retrieved using `getSource`. This is useful to access the control
flow graph containing the call: since resolved call do not appear syntactically
in the program, they are not directly part of a control flow graph but must
resort to their source `UnresolvedCall` to access the graph they belong to.

The resolution process yields to the creation of `Call` instances that also implement
the `ResolvedCall` interface, that provides means to access the targets of the
call. `getTargets` returns a collection of `CodeMember`s, an interface that
describes the general structure of a program member that contains code (e.g., a
control flow graph, or a summary of a function from the standard library ---
more information available in the [control flow graphs page]({{ site.baseurl }}/documentation/cfgs.html)).
The interface is implemented by several classes. The three core implementations are:

- `NativeCall`: a call to one or more `NativeCFG`s, that are special CFGs that
  represent the behavior of library or runtime functions without having to analyze
  their code;
- `CFGCall`: a call to one or more `CFG`s under analysis;
- `OpenCall`: a call for which no target could be resolved, and thus needs to be
  over-approximated.

Since a call might resolve to a mix of `NativeCFG`s and regular `CFG`s, the
`MultiCall` class is provided as a wrapper to represent a call that embeds
multiple underlying calls. Finally, the `TruncatedParamsCall` is a special call
generated when calls whose type is `UNKNOWN` are resolved to static targets: the
first parameter passed to the call is actually the qualifier, and is thus
removed in semantic computations.

## Symbol Aliasing

Often, programming languages allow some means of defining aliases for program
members, similar to Python's `import as` or C#'s `using`. These might affect the
resolution of calls, as the name of a function or class might have been locally
renamed by one of these constructs. Such aliases can be stored in an instance of
the `SymbolAliasing` class. This is a subtype of
[`FunctionalLattice`]({{ site.baseurl }}/documentation/lattices.html#powersets-and-functions)
that maps instances of `Symbol` (i.e., a name with an optional qualifier) to
a set of `Symbol`s that represent the possible aliases of the symbol. Instances
of `SymbolAliasing` are automatically extracted from the
[`ProgramState`]({{ site.baseurl }}/documentation/lattices.html#the-program-state)
and passed to the call graph's resolve method.

## The CallGraph class

The `CallGraph` class is the root class of the call graph hierarchy. It inherits
from `BaseGraph` (hidden in the class diagram), and provides standard graph
methods to access, add, and remove nodes and edges.

<center> <img src="{{ site.baseurl }}/documentation/callgraph.png" alt="The CallGraph class hierarchy" style="width:80%"/> </center>

The `CallGraph` class adds several methods, most of which have default
implementations:

- `init` initalizes the call graph by storing the
  [Application]({{ site.baseurl }}/documentation/units.html#application)
  to analyze and the
  [Event Queue]({{ site.baseurl }}/documentation/events.html) to use for emitting
  events (note that this method is called only once by LiSA, at the beginning of
  the analysis);
- `getCallers`, `getCallees`, `getCallersTransitively`, and
  `getCalleesTransitively` return the (transitive) callers and callees of a given
  control flow graph, respectively, by looking at the predecessors and successors
  of the graph in the call graph (both have an overload that receives a collection
  of control flow graphs, and returns the union of their callers and callees);
- `getRecursions` returns the collection of recursions (i.e., loops in the call
  graph), and `getRecursionsContaining` returns the ones that include a certain
  control flow graph.

Three methods require implementation by subtypes of `CallGraph`. The
`getCallSites` method yields all calls that invoke a given `CodeMember`.
This method is used by the overload accepting a collection of `CodeMember`s
to return the union of their call sites.
New edges in the call graph can be added either by resolving a call, or by
manually informing the graph that a call is being executed. In both methods,
`NativeCall`s are never registered in the call graph as they do not point to a
CFG. The `registerCall` method can be used, given a `CFGCall` (i.e., an
already-resolved call that is linked to the `CFG` it might invoke), to add an
edge from a caller to one or more callees. Instead, the `resolve` method
receives an `UnresolvedCall`, the set of `Type`s for each argument, and
`SymbolAliasing` information, produces a resolved `Call` instance.

### The BaseCallGraph class

In most cases, the resolution logic follows the same workflow,
parametric to all language-specific algorithms. Such workflow is implemented in
the `BaseCallGraph` class, that provides implementations for the abstract
methods of `CallGraph`:

- `registerCall` adds the necesseray nodes and edges to the call graph, skipping
  calls that result from the resolution of `UnresolvedCall`s (i.e., ones whose
  `getSource` yields an `UnresolvedCall`) since those get registered during
  resolution;
- `getCallSites` returns the calls that invoke the target member from a cache,
  that is filled whenever a call is registered or resolved;
- `resolve` delegates the resolution to `resolveInstance` and
  `resolveNonInstance`, and then creates a `Call` instance based on the found
  targets; it then proceeds by registering the call (i.e., adding nodes and edges
  to the call graph) before returning it.

All methods involved in the resolution of both instance and non-instance calls
are implemented, but are left open for modifications by subclasses. The
resolution process implemented in `resolve` proceeds as follows:

- first, a cache is checked to see if the call has already been resolved with
  the same type information; if so, the cached result is returned;
- otherwise, the resolution is delegated to `resolveInstance` and
  `resolveNonInstance` depending on the call type, or to both if the call type is
  `UNKNOWN`;
- the results of the resolution are used to create a `Call` instance, that is
  then registered in the call graph and cached; the creation proceeds as follows:
  - if no target is found, an `OpenCall` is created;
  - if only `CFG` targets are found, a `CFGCall` is created;
  - if only `NativeCFG` targets are found, a `NativeCall` is created;
  - if the call type is `UNKNOWN` and only `CFG` targets are found after
    removing the receiver (i.e., the first parameter) from the resolution and
    using it as a qualifier, a `TruncatedParamsCall` wrapping a `CFGCall` is
    created;
  - if the call type is `UNKNOWN` and only `NativeCFG` targets are found after
    removing the receiver (i.e., the first parameter) from the resolution and
    using it as a qualifier, a `TruncatedParamsCall` wrapping a `NativeCall` is
    created;
  - otherwise, the targets will fall in more than one category described above:
    their respective `Call` instances are created, and wrapped in a `MultiCall`.

Both instance and non-instance resolution exploit few auxiliary methods, each
with a default implementation that can be overridden by subclasses to implement
possible language-specific optimizations:

- `getReceiverCompilationUnit` extracts the type definition from a type instance
  that represents the type of the receiver of an instance call; by default,
  inner types are extracted from pointers if necessary;
- `isATarget` checks the signature of a code member to determine whether it is
  suitable for an unresolved call; by default, it first checks aliases to rewrite
  both the target name and the qualifier, and then proceeds by matching the fully
  qualified name through `matchesCodeMemberName` and the suitability of the
  parameters through the program's
  [parameter matching strategy]({{ site.baseurl }}/documentation/language-features-and-type-system.html#parameter-matching-strategy);
- `matchesAlias` checks if an alias exist for the given name and qualifier that
  is suitable for the call; by default, it checks all entries in the
  `SymbolAliasing` for the name and the qualifier, selecting the suitable ones
  through `matchesCodeMemberName`;
- `addTarget` adds a target to the correct collection of targets (i.e., `CFG`
  or `NativeCFG`), depending on the type of the target; by default, it checks the
  type of the target and adds it to the correct collection;
- `matchesCodeMemberName` checks if the name and qualifier of a code member
  match the target name and qualifier of the call; by default, it checks for
  equality of both.

`resolveNonInstance` proceeds by first selecting the types where the targets are
to be searched are determined by looking at the call qualifier (if no qualifier
is present, all types in the program are considered), also considering possible
aliases. Then, each type is searched independently: if the type is not part of a
hierarchy (e.g., it is not part of a language that has classes), the search
filters all code members with `isATarget`. Then, for all selected targets, the
distance from a _perfect target_ is computed (i.e., the number of type
conversions necessary for using the actual parameters of the call as parameters
of the target) using the program's
[parameter matching strategy]({{ site.baseurl }}/documentation/language-features-and-type-system.html#parameter-matching-strategy),
and the ones with the lowest distance are added to the possible
targets. Note that if the call is ambiguous (i.e., there are multiple targets
with the same distance in the same type), an exception is raised.
Instead, if tye type is part of a hierarchy, the hierarchy is traversed upwards
using the program's
[hierarchy traversal strategy]({{ site.baseurl }}/documentation/language-features-and-type-system.html#hierarchy-traversal-strategy).
For each traversed type, the same process described above is applied, but the
search is stopped as soon as at least a target is found, since the traversal
strategy ensures that the first targets found are the most specific ones.

`resolveInstance` proceeds similarly, but the search is restricted to the
type of the receiver (i.e., the first parameter of the call) and its supertypes.
The resolution starts by selecting the possible types of the receiver through
`getPossibleTypesOfReceiver`, the only abstract method of the class, that can
implement several techniques for call graph building (e.g., class hierarchy
analysis, rapid type analysis, etc.). For each such type, the corresponding type
definition is retriieved through `getReceiverCompilationUnit`. The hieararchy
of the definition is then traversed using the program's
[hierarchy traversal strategy]({{ site.baseurl }}/documentation/language-features-and-type-system.html#hierarchy-traversal-strategy),
and for each traversed type the _instance_ code members are filtered using the
same process described above: `isATarget` is used to check the suitability of
the code member, the distance from a perfect target is computed, and the best
targets are selected. The search is stopped as soon as at least a target is found,
since the traversal strategy ensures that the first targets found are the most
specific ones. In case of ambiguity, an exception is raised.

Implementations of `BaseCallGraph` thus only need to provide an implementation of
`getPossibleTypesOfReceiver` to implement a call graph building algorithm, and can
rely on the default implementations of the other methods, that are designed to be
as generic as possible while respecting the possible language-specific features
that might affect the resolution process.

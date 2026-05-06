---
layout: docpage
prereq:
  - text: Units
    link: documentation/units.html
  - text: Control Flow Graphs
    link: documentation/cfgs.html
  - text: Statements, Expressions, and Edges
    link: documentation/st-ex-e.html
  - text: Types
    link: documentation/types.html
  - text: Annotations
    link: documentation/annotations.html
---

# Language Features

A static analysis framework must cope with the diversity of programming languages:
how calls are resolved, how arguments are matched to parameters, how the analysis
state is scoped when entering a function, how errors are propagated, and what
structural invariants a well-formed program must satisfy all vary from one language
to the next. In LiSA, these concerns are encapsulated in a set of pluggable
strategy interfaces that are grouped together by the `LanguageFeatures` abstract
class and attached to a [`Program`]({{ site.baseurl }}/documentation/units.html#the-program-unit) at construction time.

This page describes `LanguageFeatures` and each of the five strategy interfaces
it composes: the parameter matching strategy used to resolve calls, the hierarchy
traversal strategy used to walk type hierarchies, the parameter assigning strategy
that prepares analysis state before entering a callee, the scoping strategy that
manages variable visibility across call boundaries, and the program validation
logic that checks structural correctness before the analysis begins.

{% include diagrams.html %}

## The LanguageFeatures class

`LanguageFeatures` is the abstract class that a frontend must subclass to declare
the language-specific behaviour of the program it is modeling. An instance of
`LanguageFeatures` is passed to [`Program`]({{ site.baseurl }}/documentation/units.html#the-program-unit) and exposed through
`Program.getFeatures()`, making it available throughout the analysis engine.

<center> <img src="{{ site.baseurl }}/schemes/lf-language-features.png" alt="LanguageFeatures abstract class" style="width: 60%"/> </center>

Three methods are abstract and must be implemented by every frontend:

- `getMatchingStrategy()` returns the `ParameterMatchingStrategy` used to decide
  whether a given call site is compatible with a candidate callee;
- `getTraversalStrategy()` returns the `HierarchyTraversalStrategy` used to
  enumerate the units that should be searched for a matching callee when
  resolving a virtual call;
- `getAssigningStrategy()` returns the `ParameterAssigningStrategy` used to bind
  actual arguments to formal parameters in the analysis state before entering a
  callee.

Two further methods have default implementations and may optionally be overridden:

- `getScopingStrategy()` returns a `DefaultScopingStrategy`, which pushes the
  analysis state into the callee's scope and pops it on return;
- `getProgramValidationLogic()` returns a `BaseValidationLogic`, which performs
  structural validation of the [`Program`]({{ site.baseurl }}/documentation/units.html#the-program-unit) before the analysis starts.

## Call Resolution

When LiSA encounters an unresolved call, it must determine which concrete code
member(s) the call may target. This involves two steps: traversing the type
hierarchy to find candidate units (via
[`HierarchyTraversalStrategy`](#hierarchy-traversal)), and then
checking each candidate's signature against the call (via
`ParameterMatchingStrategy`). This section covers the matching step.

<center> <img src="{{ site.baseurl }}/schemes/lf-resolution.png" alt="ParameterMatchingStrategy hierarchy"/> </center>

`ParameterMatchingStrategy` is the interface that decides whether a call's actual
arguments are compatible with a candidate callee's formal parameters. It exposes
two methods:

- `matches(call, formals, actuals, types)` is the core abstract method: given the
  call site, the formal parameter list of the candidate, the actual argument
  expressions, and the runtime type sets of each argument, it returns `true` if
  the call matches this candidate;
- `distanceFromPerfectTarget(call, types, cm, instance)` is a default method that
  computes an integer distance between the call and a candidate code member; a
  distance of `0` means a perfect match; larger values indicate that type
  widening was needed; `-1` signals that the candidate is incompatible; this
  value is used by the call resolution engine to rank candidates when multiple
  matches are found, using `TypeSystem.distanceBetweenTypes` for per-parameter
  distances.

### Fixed-Order Strategies

`FixedOrderMatchingStrategy` is an abstract class that implements
`ParameterMatchingStrategy` for calls where the number of actuals must equal
the number of formals and each argument is matched positionally. Its concrete
`matches` implementation checks that `formals.length == actuals.length` and then
delegates each position to the abstract single-position method
`matches(call, pos, formal, actual, types)`, that checks whether the single actual
argument at position `pos`, with the given runtime type set, is compatible with
the corresponding formal parameter.

Three ready-to-use singleton implementations are provided:

- `RuntimeTypesMatchingStrategy.INSTANCE` accepts a call at position `pos` if
  any runtime type in `types` can be assigned to the formal's static type; this
  is appropriate for virtual (instance) calls where the runtime type is what
  matters;
- `StaticTypesMatchingStrategy.INSTANCE` accepts a call at position `pos` if the
  actual expression's static type can be assigned to the formal's static type.
  This is appropriate for static calls and in languages without subtype
  polymorphism;
- `JavaLikeMatchingStrategy.INSTANCE` combines both: for the receiver argument
  (position `0` of an instance call) it uses runtime types; for all other
  arguments it uses static types; this models the Java virtual dispatch rule.

### Python-Like Matching

`PythonLikeMatchingStrategy` implements `ParameterMatchingStrategy` for languages
that support default parameter values and keyword (named) arguments. It is
constructed with a `FixedOrderMatchingStrategy` delegate that is used once the
positional and keyword slots have been filled in.

Its `matches` implementation performs matching in three phases:

1. positional arguments --- actual arguments are assigned to the corresponding
   formal slots in order, stopping as soon as a `NamedParameterExpression` is
   encountered (i.e., an expression of the form `par_name=some_value`);
2. keyword arguments --- each remaining `NamedParameterExpression` is matched
   to the formal whose name equals the parameter name and assigned to that slot;
3. default values --- any formal slot left unfilled is assigned its declared
   default value expression; if no default exists the call is rejected.

The logic for these three phases is factored into the generic static method
`pythonLogic`, which operates over arbitrary element types `T` and failure
values `F`. This allows the same algorithm to be shared between
`PythonLikeMatchingStrategy` (which fills [`Expression`]({{ site.baseurl }}/documentation/st-ex-e.html#the-expression-class) slots) and
`PythonLikeAssigningStrategy` (which fills [`ExpressionSet`]({{ site.baseurl }}/documentation/symbolic-expressions.html) slots during the
analysis).

## Parameter Assignment

Once a callee has been resolved, LiSA must bind the actual arguments to the
formal parameters in the analysis state before starting the fixpoint on the
callee's CFG. The `ParameterAssigningStrategy` encapsulates this binding.

<center> <img src="{{ site.baseurl }}/schemes/lf-assigning.png" alt="ParameterAssigningStrategy hierarchy" style="width: 80%"/> </center>

`ParameterAssigningStrategy` declares one abstract generic method:

- `prepare(call, callState, interprocedural, expressions, formals, actuals)`
  takes the analysis state at the call site, the resolved formals, and the
  [`ExpressionSet`]({{ site.baseurl }}/documentation/symbolic-expressions.html) arrays produced for each actual argument, and returns a pair
  of the post-assignment analysis state and the [`ExpressionSet`]({{ site.baseurl }}/documentation/symbolic-expressions.html) array with an
  element for each formal parameter.

Two implementations are provided:

`OrderPreservingAssigningStrategy.INSTANCE` assigns each actual expression to
the corresponding formal variable in order. For each formal, it computes the
join over all symbolic expressions in the corresponding [`ExpressionSet`]({{ site.baseurl }}/documentation/symbolic-expressions.html), using
the [abstract domain]({{ site.baseurl }}/documentation/semantic-domains.html#the-abstract-domain-interface)'s `assign` operation to bind each expression to the formal's
symbolic variable. This strategy is appropriate for any language where arguments
are passed positionally with no defaults or keyword arguments.

`PythonLikeAssigningStrategy.INSTANCE` extends the positional strategy to
handle default values and keyword arguments. It first evaluates the default
value expression for each formal that has one (running forward semantics on the
default expression to obtain its [`ExpressionSet`]({{ site.baseurl }}/documentation/symbolic-expressions.html)), then uses the same
`pythonLogic` algorithm from `PythonLikeMatchingStrategy` to fill in the
[`ExpressionSet`]({{ site.baseurl }}/documentation/symbolic-expressions.html) slots for each formal. Only after the slots are filled does it
run the order-preserving assignment loop.

## Hierarchy Traversal

When a yet-to-be-resolved call (i.e., an
[`UnresolvedCall`]({{ site.baseurl }}/documentation/call-graph.html#calls))
needs to be resolved, LiSA must know which units to search for a
matching callee. The `HierarchyTraversalStrategy` determines the order in which
ancestor units are visited.

<center> <img src="{{ site.baseurl }}/schemes/lf-traversal.png" alt="HierarchyTraversalStrategy" style="width: 70%"/> </center>

`HierarchyTraversalStrategy` is an interface that defines a single method,
`traverse(st, start)`, that returns an `Iterable<CompilationUnit>` that enumerates
the units to search, starting from `start` (the static receiver type) and
walking up or across the hierarchy as appropriate for the language.

`SingleInheritanceTraversalStrategy.INSTANCE` implements a breadth-first walk
of the ancestor hierarchy starting from the given unit. At each step it visits
the current unit and its immediate ancestors. This strategy is suitable for
single-inheritance languages (e.g., Java classes), where at most one superclass
exists at each level, though it correctly handles the presence of interfaces by
processing all immediate ancestors.

{% include note.html content="For languages with multiple inheritance, implement
a custom `HierarchyTraversalStrategy` that defines the linearisation order
appropriate for the language (e.g., C3 linearisation for Python). The traversal
strategy only determines the search order; the final selection among matching
candidates is handled by the matching and assigning strategies." %}

## Scoping

When the analysis enters a callee, local variables of the caller must not
interfere with local variables of the callee that share the same name.
`ScopingStrategy` manages this by pushing and popping variable scopes around
each call.

<center> <img src="{{ site.baseurl }}/schemes/lf-scoping.png" alt="ScopingStrategy" style="width: 70%"/> </center>

`ScopingStrategy` is an interface with two abstract methods:

- `scope(call, scope, state, analysis, actuals)` prepares the analysis state for
  entry into a callee identified by the given [`ScopeToken`]({{ site.baseurl }}/documentation/common-interfaces.html#the-scoped-object-interface); it returns a pair of
  the scoped state and the correspondingly scoped [`ExpressionSet`]({{ site.baseurl }}/documentation/symbolic-expressions.html) arrays for
  the actual arguments;
- `unscope(call, scope, state, analysis)` restores the analysis state after
  returning from the callee; if the call returns a value, it assigns the callee's
  return expressions to the call's meta-variable before popping the scope.

`DefaultScopingStrategy` implements both methods. Its `scope` implementation
calls `AnalysisState.pushScope` to push the scope token onto the analysis state
and applies `ExpressionSet.pushScope` to each actual expression so that the
symbolic names of the actuals are correctly translated into the callee's scope.
Its `unscope` implementation checks whether the call returns a value: if not, it
simply pops the scope; otherwise, it assigns each return expression to the call's
meta-variable (joining over all return expressions) and then pops the scope.

## Program Validation

Before starting the analysis, LiSA validates the [`Program`]({{ site.baseurl }}/documentation/units.html#the-program-unit) to catch structural
errors introduced by the frontend. The `ProgramValidationLogic` interface
encapsulates this validation pass.

<center> <img src="{{ site.baseurl }}/schemes/lf-validation.png" alt="ProgramValidationLogic and BaseValidationLogic" style="width: 60%"/> </center>

`ProgramValidationLogic` is an interface with one abstract method:
`validateAndFinalize(program)`. The latter inspects the program's units, code members,
globals, and entry points for structural violations and throws a
`ProgramValidationException` describing the first violation found. It also
finalizes the program (e.g., populating override and annotation chains) so that
the analysis engine can assume a fully resolved program.

`BaseValidationLogic` is the default implementation. It provides a family of
overridable `validateAndFinalize` and `validate` methods organized by the type
of element being checked that perform the minimal checks on each component:

- `validateAndFinalize(Program)` verifies that all entry points are part of the
  program, then delegates to per-unit validation;
- `validateAndFinalize(Unit)` dispatches to the appropriate typed overload based
  on the runtime type of the unit;
- `validateAndFinalize(CodeUnit)` performs no additional checks (procedural units
  have no inheritance constraints);
- `validateAndFinalize(CompilationUnit)` is the central method: it recursively
  validates ancestors, resolves override chains (populating `overrides` and
  `overriddenBy` on each code member's descriptor), propagates inherited
  annotations from ancestors to subunits and overriding members, and registers
  the unit as an instance of itself;
- `validateAndFinalize(ClassUnit)` checks that a concrete class has no unresolved
  abstract members;
- `validateAndFinalize(AbstractClassUnit)` checks that an abstract class is not
  sealed;
- `validateAndFinalize(InterfaceUnit)` checks that an interface declares no
  instance globals;
- `validate(Global, isInstance)` checks that the global's instance flag is
  consistent with how it is registered in its unit and that constant globals are
  not declared as instance globals;
- `validate(CodeMember, instance)` checks that the member is registered exactly
  once in its unit under the correct instance/static category, and calls
  `CodeMember.validate()` to run any member-level checks.

`CodeMember.validate()` results in calls to `CFG.validate()`, that (i) ensures
that all control flow structures are well-formed (e.g., all nodes are actually
part of the CFG), (ii) ensures no execution-stopping nodes (i.e., ones where
`stopsExecution()` returns `true`) have successors, (iii) ensures that nodes
that do not stop execution have at least one successor, and (iv) checks that
all entrypoints of the CFG are actual nodes of the CFG. Then, it launches
validation of the inner [`NodeList`]({{ site.baseurl }}/documentation/cfgs.html#graphs-containing-code), which checks that all edges' endpoints are
part of the [`NodeList`]({{ site.baseurl }}/documentation/cfgs.html#graphs-containing-code).

Frontends that model a language with additional
structural constraints (e.g., a no-cyclic-inheritance rule or restrictions on
interface method visibility) should subclass `BaseValidationLogic` and override
the relevant `validateAndFinalize` overload. The `processedUnits` set ensures
that each unit is only visited once even when the overriding method calls
`super`.

{% include important.html content="`validateAndFinalize` is called exactly once
per analysis, just before the fixpoint computation starts. At the moment it is
called, the program graph is fully constructed: all units, code members, globals,
and entry points are already in place. After `validateAndFinalize` returns, the
override and annotation chains are considered final and must not be modified." %}

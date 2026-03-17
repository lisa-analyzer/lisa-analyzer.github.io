---
layout: docpage
prereq:
  - text: Program Points
    link: documentation/common-interfaces.html#minimal-program-components
  - text: Lattices and Domain Lattices
    link: documentation/lattices.html
  - text: Semantic Domains
    link: documentation/semantic-domains.html
  - text: Symbolic Expressions
    link: documentation/symbolic-expressions.html
---

# The Simple Abstract Domain

In LiSA, an abstract domain is responsible for tracking the whole program state,
including the values and types of variables and expressions, and the structure
of the memory.
To simplify this task, LiSA offers the `SimpleAbstractState` and the
`SimpleAbstractDomain` classes, that implement the framework proposed in:

> <ins>Pietro Ferrara</ins>, 2016.
> **A generic framework for heap and value analyses of object-oriented programming languages**.
> Theoretical Computer Science, Volume 631, 2016, Pages 43-72.<br/>
> <small>[<i class="fas fa-link"></i> DOI](https://doi.org/10.1016/j.tcs.2016.04.001)</small>

In this framework, the state of the analysis is composed of a
heap abstraction and a value abstrction,
where the semantics of each instruction is first evaluated on the heap abstraction, that
rewrites the instruction by removing all of the parts performing heap operations with
symbolic identifiers. The rewrtitten expression is then processed by the value abstraction.
Additionally, since processing assignments and allocations might summarize or
materialize heap locations, the heap abstraction also provides a substitution
(i.e., a series of assignments and variable removals) that must be applied to the
value abstraction before processing the rewritten expression.

LiSA extends this framework by adding a type abstraction to the state,
that is responsible for tracking the types of program variables and expressions.
The type abstraction operates after the heap abstraction (i.e., after the
rewriting happened), but before the value abstraction, so that the value
abstraction can leverage type information to improve its precision if necessary.
An intutive scheme of how the framework operates can be seen below:

<center> <img src="{{ site.baseurl }}/documentation/sad-overview.png" alt="Simple Abstract Domain Overview" style="width: 60%"/> </center>

Intuitively, whenever an expression (assignment or not) must be evaluated, the
`SimpleAbstractDomain` first feeds it to the `HeapDomain`, the domain that
tracks the dynamic memory of the program. The `HeapDomain` processes the
expression, making the necessary updates to its internal state, and returns a
new state and a substutution, i.e., a list of operations of the form
`{ x1, x2, ..., xn } -> { y1, y2, ..., ym }`.
Each such operation should be interpreted as assigning to each `yi` _all of the
values_ (i.e., their least upper bound) of `x1, x2, ..., xn`, and then
removing every `xj` that is not in `y1, y2, ..., ym` from the state. This allows
for easy summarization (i.e., `{ x, y } -> { x }`, with `x` becoming the
summary of both `x` and `y` that are then removed from the state) and
materialization (i.e., `{ x } -> { x, y }`, with `y` becoming a new
identifier that is added to the state with the same value of `x`).
The substitution is then applied to the `TypeDomain`, that updates its internal
state accordingly, and then to the `ValueDomain`, that also updates its internal
state accordingly. Finally, the `HeapDomain` rewrites the input expression by
removing all heap operations (e.g., if the `HeapDomain` knows that `x.f` is a
reference to some location `l`, then the expression `y = x.f + 3` is rewritten to
`y = l + 3`: the memory access is removed, and the other domains can now focus
on variables only). This might generate more than one expression: both the
`TypeDomain` and the `ValueDomain` are fed one of them at a time, and their
resulting states are merged together through the least upper bound operation
to obtain the final states.

{% include tip.html content="If you are not familiar with memory abstractions,
concepts like summarization, materialization, and rewriting might be a
challenge. Adopting this framework has the benefit of simplifying this: you
can focus on implementing the value abstraction of your choice, and use one of
the already-provided heap abstractions that LiSA provides!" %}

As highlighted in the diagram above, the `HeapDomain`, `TypeDomain`, and
`ValueDomain` are all _configurable_, meaning that the `SimpleAbstractDomain`
can be instantiated with different implementations of each of these domains.

{% include diagrams.html %}

## Substitutions

In LiSA, a substitution is a list of `HeapReplacement` objects, each
representing an operation of the form `{ x1, x2, ..., xn } -> { y1, y2, ..., ym }`
described above:

<center> <img src="{{ site.baseurl }}/documentation/repl.png" alt="The Heap Replacement class" style="width: 40%"/> </center>

A `HeapReplacement` is composed of two sets of `Identifier`s, the
_source_ set (i.e., `{ x1, x2, ..., xn }` in the example above) and the _target_ set
(i.e., `{ y1, y2, ..., ym }` in the example above). The class provides
methods to retrieve these sets (`getSources` and `getTargets`), and to automatically
compute their difference, that represents the `Identifier`s that must be removed from
the state after the assignment (`getIdsToForget`). It also provides ways to add new
sources and targets to the replacement (`addSource` and `addTarget`, together with
`withSource` and `withTarget` that additionally return the current replacement
for chaining calls).

## Lattice structure

The lattices managed by the `SimpleAbstractDomain` and its components are all
[Domain Lattices]({{ site.baseurl }}/documentation/lattices.html#domain-lattices)
since they must provide the basic operations over variables and the scoping
logic other than lattice operations.

<center> <img src="{{ site.baseurl }}/documentation/sad-lattices.png" alt="Simple Abstract Domain Lattices" /> </center>

Specifically, the `HeapLattice` interface, parametric on the concrete type `L`
of the lattice, that must extend `HeapLattice<L>`, extends
`DomainLattice<L, Pair<L, List<HeapReplacement>>>`, meaning that lattice
operators accept and produce instances of `L`, but variable operations (like
`forgetIdentifier`) and scoping operations (like `popScope`) return both a
new and modified instance of `L` and a substitution, in the form of a list of
`HeapReplacement` objects. Other than the default
`DomainLattice` operations, `HeapLattice` defines a new method, called `expand`,
that is tasked with expanding a single deletion `HeapReplacement` (i.e., one of
the form `{ x } -> { }`) with all the replacements implied by it (i.e., if `y`
is only reachable through `x`, then `y` must also be deleted). This is used to
ensure that no dangling references are left in the heap abstraction, performing
a sort of garbage collection.

Instead, `LatticeWithReplacement` defines the a lattice instance that can be the
target of a substitution. It is parametric on the concrete type `L` of the
lattice, that must extend `LatticeWithReplacement<L>`, and extends
`DomainLattice<L, L>`, meaning that both lattice operations and variable/scoping
operations return instances of `L`. The interface defines the
implementation-independent logic for applying an individual `HeapReplacement` in method
`applyReplacement`. The latter relies on the `store` method to perform an
assignment. `ValueLattice`, parametric on the concrete type
`L` of the lattice that must extend `ValueLattice<L>`, and `TypeLattice`,
parametric on the concrete type `L` of the lattice that must extend
`TypeLattice<L>`, both extend `LatticeWithReplacement<L>`.

The `DomainLattice` instance that models the states generated by the framework
is `SimpleAbstractState`, parametric on the types `H extends HeapLattice<H>`,
`T extends TypeLattice<T>`, and `V extends ValueLattice<V>` of the
inner components to use. This class is effectively a _cartesian product_ of the
three lattices, and implements the lattice operations by invoking the
corresponding operation on each component. Variable and scoping operations also
invoke the corresponding operation on each component, collecting all of the
substitutions produced by the heap component and applying them to the type and
value components. Note that no reduction is applied between the three components:
if one of them becomes bottom, the other two are allowed to remain non-bottom.
`SimpleAbstractState` implements both `BaseLattice<SimpleAbstractState<H, V, T>>`
and `AbstractLattice<SimpleAbstractState<H, V, T>>`, with the latter implying
that it can be used a lattice instance in conjunction with
[Semantic Domains]({{ site.baseurl }}/documentation/semantic-domains.html).

{% include tip.html content="LiSA provides subtypes of `CartesianCombination`
to quickly implement `ValueLattice`s, `TypeLattice`s, and `HeapLattice`s as products." %}

## Domain and Components

`HeapDomain`s, `TypeDomain`s, and `ValueDomain`s cannot directly implement the
[Abstract Domain]({{ site.baseurl }}/documentation/semantic-domains.html#the-abstract-domain-interface)
interface, since (i) abstract domains must be able to handle all symbolic
expressions, but `ValueDomain`s and `TypeDomain`s cannot, and (ii) since each
domain runs in isolation, they need avenues to query information from each other. To
this end, LiSA introduces the `SemanticComponent` interface, that matches
`SemanticDomain` except for having an additional parameter, the
`SemanticOracle`, in all transformers:

<center> <img src="{{ site.baseurl }}/documentation/sad-comps.png" alt="Simple Abstract Domain Components" /> </center>

The `SemanticOracle` parameter can effectively be used for cross-component communication,
exploiting the methods it exposes to query information from other components.
`SemanticComponent` has the same type parameters as `SemanticDomain`:

- `L extends DomainLattice<L, T>` defines the type of abstract states the
  transformers accept as parameters (see the
  [Lattices]({{ site.baseurl }}/documentation/lattices.html#domain-lattices) page;
- `T` defines the return type of the transformers (as, in some cases, a domain
  implementation might want to return a pair of a state and some auxiliary
  information);
- `E extends SymbolicExpression` defines the type of
  [SymbolicExpressions]({{ site.baseurl }}/documentation/symbolic-expressions.html)
  the transformers can operate on;
- `I extends Identifier` defines the type of
  [Identifiers]({{ site.baseurl }}/documentation/symbolic-expressions.html#identifiers)
  the transformers can assign values to.

`HeapDomain`, that has a type parameter `L` that must extend `HeapLattice<L>`,
inherits directly from `SemanticComponent<L, Pair<L, List<HeapReplacement>>, SymbolicExpression, Identifier>`,
meaning that its transformers accept instances of `L` as input, can process any
`SymbolicExpression` and can assign values to any `Identifier`, but return a
pair of a new state `L` and a substitution `List<HeapReplacement>`. The common
logic for domains that must react to substitutions is implemented in the
interface `DomainWithReplacement`, parametric on the concrete type `L` of the
`DomainLattice<L, L>` that the domain manages and on the type `E` of
`SymbolicExpression`s it can process. This interface inherits from
`SemanticComponent<L, L, E, Identifier>`, meaning that its transformers accept
and produce instances of `L`, can process `E` expressions, and can assign values
to any `Identifier`. `DomainWithReplacement` provides an
implementation-independent logic for applying a list of `HeapReplacement`s
through method `applyReplacements`. Finally,`ValueDomain`, having a type
parameter `L` that must extend `ValueLattice<L>`, and `TypeDomain`, having a type
parameter `L` that must extend `TypeLattice<L>`, both inherit from
`LatticeWithReplacement<L, ValueExpression>`.

{% include warn.html content="The `DomainWithReplacement` interface currently
duplicates code from the `LatticeWithReplacement` interface. The former is
marked for removal in release 1.0." %}

The methods of a `SemanticOracle` are replicated and split among the three
components, each with an extra parameter for the `state` instance to use for the
computation and a reference to the `SemanticOracle` itself for further queries.
This allows domain-specific answers to each query to be computed modularly.

The `SimpleAbstractDomain` class can be defined in terms of these components:

<center> <img src="{{ site.baseurl }}/documentation/sad-dom.png" alt="Simple Abstract Domain" style="width: 50%"/> </center>

`SimpleAbstractDomain`, parametric on the types `H extends HeapLattice<H>`,
`T extends TypeLattice<T>`, and `V extends ValueLattice<V>` of the
states of its inner components to use, implements
`AbstractDomain<SimpleAbstractState<H, V, T>>` and stores the three components
to use in its fields. Each transfromer is implemented
following the framework of rewritings and substitutions: first, the target
expression is processed using the corresponding `heapDomain` transformer over
the `heapState` of the current state, that returns a new instance of `H`
and a substitution. The substitution is then applied to the `typeState` and
`valueState` of the current state, updating them accordingly. Then, the
`heapDomain` rewrites the expression, and the resulting expression(s) are
processed one at a time using the corresponding `typeDomain` and `valueDomain`
transformers over the updated `typeState` and `valueState`. The resulting
states are merged together using the least upper bound operation to obtain the
final states.

The `SemanticOracle` created by `SimpleAbstractDomain` is the `MutableOracle`,
that holds the three states `heap`, `type`, and `value` to use for queries.
The oracle can be _mutated_ (that is, each state can be updated) to avoid
excessive allocations during the execution of each transformer. In
`MutableOracle`, each query is implemented by delegating the computation to the
corresponding component, passing the held state and the oracle itself as parameter.
Thus, components always recieve an oracle that has an overview of the whole program
state, and can query information from each other as needed.

For a list of heap, value, and type domains already implemented in LiSA, see the
[Configuration]({{ site.baseurl }}/configuration/#setting-the-abstract-domain) page.

## Non-Relational Analyses

One of the key objectives of LiSA is the ease of implementing new analyses by
reusing existing components. Non-relational analyses
(or more formally, Cartesian abstractions) compute independent values
for different program variables, and are able to evaluate an expression to an
abstract values by knowing the abstract values of program variables.
Both their formalization and their implementation typically relies
on (i) a mapping from program variables to abstract values (i.e., lattice
instances), and (ii) the ability to recursively evaluate expressions by combining
the abstract values of their sub-expressions.

### Environments

The mapping from program variables to abstract values is modeled in LiSA through
the `Environment` class hierarchy:

<center> <img src="{{ site.baseurl }}/documentation/environments.png" alt="The Environment class hierarchy"/> </center>

An `Environment` is a `FunctionalLattice` that has `Identifier`s as keys and
lattice instances as values. The class is parametric on the type `L`, that must
extend `Lattice<L>`, of the values of the map, and on the concrete type `E` of
the environment itself, that must extend `Environment<L, E>`. `Environment`
extends `FunctionalLattice<E, Identifier, L>`, meaning that all lattice
operators accept and return values of type `E`, and implements `DomainLattice<E,
E>`, meaning that variable and scoping operations also accept and return values
of type `E`. `ValueEnvironment`, `TypeEnvironment`, and `HeapEnvironment` all
subclass `Environment` and all possess one type parameter `L` for the values
they contain (i.e., they all inherit from `Environment<L, X<L>>`, where `X` is
`ValueEnvironment`, `TypeEnvironment`, or `HeapEnvironment` respectively).
However, while `ValueEnvironment` specifies that `L` can be any lattice instance
(i.e., `L extends Lattice<L>`), `TypeEnvironment` and `HeapEnvironment` restrict
`L` to be a `TypeValue<L>` and a `HeapValue<L>` respectively. These define
additional operations for their specific types:

- since instances of `TypeValue` ultimately abstract sets of types, the
  interfaces provides method `getRuntimeTypes` to retrieve such abstraction;
- `HeapValue`'s `reachableOnlyFrom` instead should perform a cut of the memory
  of the program starting from the given `Identifier`s, returning all those
  `Identifier`s that are only reachable from them.

### Non Relational Domains

Non-relational domains can be implemented in LiSA by subclassing the
`NonRelationalDomain` interface:

<center> <img src="{{ site.baseurl }}/documentation/nonrel.png" alt="Non-Relational Domains" style="width: 80%"/> </center>

A `NonRelationalDomain` is parametric on the type `L` of lattice instances it
uses as values (that must extend `Lattice<L>`), on the type `T` of the values it
returns from its transformers, on the type `M` of the mapping it is designed to
work with (that must extend `FunctionalLattice<M, Identifier, L>` and `DomainLattice<M, T>`),
and on the type `E` of `SymbolicExpression`s it can process. Note that the binding
allow the type of values used inside the mapping `M` to differ from the
return type of each tansformer: this is essential for enabling both heap and
value analyses. `NonRelationalDomain` extends two interfaces:

- `SemanticEvaluator`, that defines a `canProcess` method to check whether the
  domain can process a given expression, relying on its type and its runtie
  types;
- `SemanticComponent<M, T, E, Identifier`, meaning that the domain can be used
  for all three components (heap, type, and value) by instantiating `M` with the
  corresponding environment type (i.e., `HeapEnvironment`, `TypeEnvironment`, or
  `ValueEnvironment`).

Three methods are defined by the interface:

- `eval`, that given an expression and an environment (i.e., the values of each
  variable possibly appearing in the expression), evaluates the former to a
  lattice instance that can be stored in the environment;
- `fixedVariable`, that optionally returns a lattice instance that can
  over-approximate the given variable in all program executions; if this method
  returns a non-bottom value, all assignments to that variable are ignored, and the
  variable is always assumed to have that value (this is useful for instance in
  security analyses, when one wants to assume that certain variables are always
  under the control of the attacker);
- `unknownValue`, that returns a lattice instance to be used when the mapping
  `M` is queried for a value that is not present in it.

Three sub-interfaces of `NonRelationalDomain` are provided to specialize it
for each of the three components:

- `NonRelationalHeapDomain`, parametric in the type `L extends HeapValue<L>`
  of the values to use in `HeapEnvironment`s,
  that specializes `NonRelationalDomain` by binding `L` to `L`, `T` to
  `Pair<HeapEnvironment<L>, List<HeapReplacement>>`, `M` to `HeapEnvironment<L>`
  and `E` to `SymbolicExpression`, and that also extends `HeapDomain<HeapEnvironment<L>>`;
  `NonRelationalHeapDomain` is thus a `HeapDomain` that maps `Identifier`s to
  `HeapValue`s through a `HeapEnvironment`, whose transformers return both a new
  environment and a substitution, and that can process any symbolic expression;
- `NonRelationalTypeDomain`, parametric in the type `L extends TypeValue<L>`
  of the values to use in `TypeEnvironment`s,
  that specializes `NonRelationalDomain` by binding `L` to `L`, both `T` and `M`
  to `TypeEnvironment<L>`
  and `E` to `ValueExpression`, and that also extends `TypeDomain<TypeEnvironment<L>>`;
  `NonRelationalTypeDomain` is thus a `TypeDomain` that maps `Identifier`s to
  `TypeValue`s through a `TypeEnvironment`, whose transformers return a new
  environment, and that can process any value expression;
- `NonRelationalValueDomain`, parametric in the type `L extends Lattice<L>`
  of the values to use in `ValueEnvironment`s,
  that specializes `NonRelationalDomain` by binding `L` to `L`, both `T` and `M`
  to `ValueEnvironment<L>`
  and `E` to `ValueExpression`, and that also extends `ValueDomain<ValueEnvironment<L>>`;
  `NonRelationalValueDomain` is thus a `ValueDomain` that maps `Identifier`s to
  lattice instances through a `ValueEnvironment`, whose transformers return a new
  environment, and that can process any value expression.

#### Base Implementations

While `Environment`s and `NonRelationalDomain`s provide the necessary infrastructure
for avoiding reimplementation of variable mappings, the recursive expression
evaluation (i.e., the `eval` method) and the logic for assignments must still be coded from scratch
despite being a process that does not depend on the final implementation.
Recursive evaluation of a symbolic expression can be straightforwardly implemented
using the expressions' visitor pattern through the `ExpressionVisitor` interface.
Still, even after the infrastructure has been taken care of, parts of the
implementations can be factored out. In LiSA, this is achieved with the
`BaseNonRelationalDomain` interface and its children.

<center> <img src="{{ site.baseurl }}/documentation/base-nonrel.png" alt="Base Non-Relational Domains"/> </center>

`BaseNonRelationalDomain` is parametric to the type `L`, that must extend `Lattice<L>`,
of the values to use in the mapping, and to the type `M` of the mapping itself, that must
extend `FunctionalLattice<M, Identifier, L>` and `DomainLattice<M, M>`.
The interface extends `NonRelationalDomain<L, M, M, ValueExpression>`,
meaning that it can process value expressions only, and that its transformers
accept and return instances of `M`, which in turn maps `Identifier`s to instances of `L`.
Additionally, `BaseNonRelationalDomain` also implements `ExpressionVisitor<L>`,
meaning that all its `visit` overloads return instances of `L`. The interface
provides default implementations for `SemanticComponent`'s and
`NonRelationalDomain`'s transformers:

- `assign` evaluates the right-hand side expression through `eval`, which produces an
  instance of `L`; then, the assignment is performed by both considering the
  result of `fixedVariable` and the possible weakness of the left-hand side
  identifier;
- `smallStepSemantics` is a no-op, since variable mappings do not change without
  assignments;
- `satisfies` evaluates any sub-expression to an instance of `L` through `eval`, and
  then invokes the corresponding `satisfiesX` method, where `X` is the class of the
  target expression, after automatically handling logical the operators `and`, `or`, and `not`;
- `assume` invokes the corresponding `assumeX` method, where `X` is the class of the
  target expression, after automatically handling logical the operators `and`, `or`, and `not`;
- `eval` calls `accept` on the target expression using the domain itself as
  visitor, and passing the environment, the program point, and the oracle as
  additional parameters;
- `fixedVariable` returns the bottom element of `L`;
- `unknownValue` returns the top element of `L`;
- `canProcess` allows the evaluation of all expressions that can assume a
  `ValueType` (see [the Types page for more information]({{ site.baseurl }}/documentation/types.html)) at
  runtime.

All `visit` overloads are implemented by either (i) throwing an exception if the
target of the visit is a `HeapExpression`, since such base implementations
cannot handle them, (ii) returning the bottom element if one of the sub-expressions
recursive evaluations returned bottom, or (iii) invoking the corresponding `evalX` method,
where `X` is the class of the expression being visited. All `evalX` methods
have default implementations that return the top element of `L`, symbolizing
that those expressions are not handled and thus over-approximated, and reducing
the number of methods one is required to implement when implementing the
interface to only the strictly required ones.
The same holds for all `satisfiesX` methods, that by default return `Satisfiability.UNKNOWN`,
and for all `assumeX` methods, that by default return the input environment.
Following the non-relational
approach, evaluations of `Identifier`s through `evalIdentifier` simply return
the contents of the environment for that id.
`BaseNonRelationalDomain` adds only two new methods that must be implemented by
concrete subclasses: `top` and `bottom`, that serve as proxies to retrieve the top
and bottom elements of `L`, respectively.

`BaseNonRelationalDomain` is specialized for value and type analyses through
`BaseNonRelationalValueDomain` and `BaseNonRelationalTypeDomain`, both
parametric on the type `L` that must extend `Lattice<L>` of the values to use in the
mapping. `BaseNonRelationalValueDomain` extends `BaseNonRelationalDomain<L, ValueEnvironment<L>>`
and `NonRelationalValueDomain<L>`, while `BaseNonRelationalTypeDomain` extends
`BaseNonRelationalDomain<L, TypeEnvironment<L>>` and `NonRelationalTypeDomain<L>`.
Both interfaces do not add any new method, but simply bind the type parameters
of `BaseNonRelationalDomain` to the corresponding environment types.

{% include note.html content="The `BaseNonRelationalHeapDomain` interface is
missing from LiSA as we did not yet find a use case for it. It is however
entirely possible to implement it following the same pattern as the other two
base implementations." %}

### Dataflow Analyses

Following the same idea of non-relational analyses, dataflow analyses also
use a shared structure that is independent from the concrete analysis being
implemented:

- the domains track sets of elements (that are analysis-specific);
- if the analysis is _possible_, `lessOrEqual` is implemented through subset
  inclusion, `lub` is implemented as set union, and `glb` is implemented as set
  intersection; otherwise, if the analysis is _definite_, `lessOrEqual` is implemented
  through superset inclusion, `lub` is implemented as set intersection, and `glb` is
  implemented as set union;
- the tracked sets are updated using the dataflow formula `F(I) = I \ kill(e, I) U gen(e, I)`,
  where `I` is the input set of elements, `e` is the expression being processed,
  and `kill` and `gen` are analysis-specific functions.

This structure is captured by the Dataflow Analysis infrastructure:

<center> <img src="{{ site.baseurl }}/documentation/dataflow.png" alt="Dataflow Analyses"/> </center>

The `DataflowDomain` interface defines the concrete operations that a dataflow
analysis must support to be used within LiSA. It is parametric to the type `L`
of `DataflowDomainLattice<L, E>` to be used (either `PossibleSet` or
`DefiniteSet`), and to the type `E` of `DataflowElement<E>` that the sets
computed by the domain contain. `DataflowDomain` is both a `ValueDomain<L>` and
a `SemanticEvaluator`, meaning that it can be used in the Simple Abstract Domain
framework as value component producing instances of `L`, and that it offers a
`canProcess` test to filter out unsupported expressions. Transformers from
`ValueDomain` are implemented using the dataflow formula, that in turns use the
implementation-specific `gen` and `kill` functions (each with two overloads, one
for assignments and one for non-assigning expressions). Similarly to
`BaseNonRelationalDomain`, `canProcess` allows all expressions that have a
`ValueType`.

A `DataflowElement` is a an object that can be tracked inside the sets produced
by a `DataflowDomain`. It is parametric to the concrete type `E` of the element itself,
that must extend `DataflowElement<E>`, and extends both `StructuredObject` and
`ScopedObject<E>`, meaning that it can be converted to a
`StructuredRepresentation` for dumping and that it supports scoping operations.
`DataflowElement`s typically track symbolic information that refer to
`Identifier`s: these can be retrieved using the `getInvolvedIdentifier` method.
Instead, `replaceIdentifier` produces an element that is identical to the
current one, but where occurrences of `source` are replaced with `target`.

Finally, the sets produced by `DataflowDomain`s are modeled through the
`DataflowDomainLattice` interface, parametric to the concrete type `L` of the
lattice itself, that must extend `DataflowDomainLattice<L, E>`, and to the type `E` of
`DataflowElement<E>` contained in the sets. These are `ValueLattice<L>`s where
lattice operations are implemented through set operations (union or intersection,
depending on whether the analysis is possible or definite). The elements
contained in the set can be retrieved through the `getDataflowElements` method,
and can be updated using the `update` method. Two concrete instances of this
interface exist:

- `PossibleSet`, parametric on the type `E extends DataflowElement<E>` that it
  contains, that implements a possible dataflow analysis by extending
  `SetLattice<PossibleSet<E>, E>`;
- `DefiniteSet`, parametric on the type `E extends DataflowElement<E>` that it
  contains, that implements a possible dataflow analysis by extending
  `InverseSetLattice<DefiniteSet<E>, E>`.

With this infrastructure, one has to simply create a `DataflowElement` instance
that tracks the information of interest, and then implement a `DataflowDomain`
that defines the `gen` and `kill` functions to specify how such information is
updated when processing each expression. The possible or definite nature of the
analysis follows by the type of `DataflowDomainLattice` used.

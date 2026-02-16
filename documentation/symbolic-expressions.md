---
layout: docpage
prereq:
  - text: Scoped Objects
    link: documentation/common-interfaces.html#the-scoped-object-interface
  - text: Program Points
    link: documentation/common-interfaces.html#minimal-program-components
---

# Symbolic Expressions

Symbolic expressions are LiSA's internal language for defining atomic operations
that a program performs during its execution. These are the subjects of the
evaluations performed by [Semantic Domains]({{ site.baseurl }}/documentation/semantic-domains.html)
to infer program properties, and allow domain definitions that are independent
of the source programming language. The rationale behind this design choice is to
allow LiSA to support multiple programming languages and paradigms by not
attributing any specific meaning to syntactic constructs.
For instance, an assignment in Python can automatically wrap or unwrap tuple
values, while in Java it can perform boxing or unboxing of primitive types,
neither of which happens in C. Thus, LiSA allows
[Statements]({{ site.baseurl }}/documentation/st-ex-e.html) (i.e., syntactic
constructs appearing in the source program) to implement their own semantics by
decomposing themselves into a series of symbolic expressions that capture the
intended operations in a language-agnostic way. This allows abstract domains
to focus on the semantics of small and well-defined operations, rather than
having to deal with the peculiarities of each programming language.
The decomposition is _semantic_:
the state of the analysis can be queried for any information (e.g., types of
variables, values of constants, aliasing of memory locations) that may be needed to
narrow down the possible behaviors of the expression. The same statement can
thus produce a different decomposition each time it is analyzed, depending on
the current state of the analysis. Symbolic expressions are also extensible, meaning that
new ones can be added to support new language constructs or paradigms.

In this page, we present the main interfaces and classes that define symbolic
expressions in LiSA, focusing on ones that have an important role in the overall
design of the framework.

{% include diagrams.html %}

## The Symbolic Expression Class

The `SymbolicExpression` class is the root of the symbolic expression hierarchy. It
extends the `ScopedObject<SymbolicExpression>` interface, meaning that all symbolic expressions
can be scoped when entering or exiting a new context during an analysis.
This is particularly useful for expressions that contain
[Identifiers](#identifiers), as it allows to isolate variable references
when analyzing function calls. In the class diagrams in the remainder of this
page, methods have been removed from concrete expression instances for the sake
of clarity, and they will be described in the relevant sections.

<center> <img src="{{ site.baseurl }}/documentation/symbexps.png" alt="The SymbolicExpression class hierarchy" /> </center>

Each symbolic expression is identified by a static [Type]({{ site.baseurl }}/documentation/types.html),
that is, a supertype of all possible runtime types the expression can take, and
a [Code Location]({{ site.baseurl }}/documentation/common-interfaces.html#minimal-program-components),
corresponding to the syntactic construct that generated the expression. `SymbolicExpression`
defines three abstract methods that must be implemented by all subclasses:

- `mightNeedRewriting`, that returns `true` if the expression may need to be
  rewritten by an analysis before being evaluated by `ValueDomain`s when using
  [the Simple Abstract Domain framework]({{ site.baseurl }}/documentation/simple-abstract-domain.html);
- `removeTypingExpressions`, that returns a copy of the expression where all
  type conversions and casts have been removed, simplifying the expression for
  inspection by components that do not need type information;
- `replace`, that returns a copy of the expression where all occurrences of a
  given sub-expression have been replaced by another expression; this is useful
  for analyses that need to substitute parts of an expression.

Other than the above methods, `SymbolicExpression` instances must define `accept`,
which plays a central role in LiSA as it allows recursive traversal of symbolic
expressions through the visitor pattern. When a recursive taversal is needed,
one can simply call `accept` on the root expression, passing an
`ExpressionVisitor` to it together with any additional parameters needed. The
`ExpressionVisitor` interface is parametric on the type `T` of the value
returned by each visit operation. The interface defines a `visit` method for
each concrete subclass of `SymbolicExpression`, allowing to define custom
behaviors for each expression type. It also defines visits for arbitrary
`HeapExpression`s and `ValueExpression`s, that can be used to cover user-defined
expressions not bundled within LiSA. The recursive traversal happens
automatically: each `visit` method receives as parameter the expression being
visited, the result of recursive visits on its sub-expressions, and any
additional parameters passed to the initial `accept` call. `SymbolicExpression`
define `accept` by simply calling the appropriate `visit` method on the
visitor, passing itself and the results of recursive `accept` calls on its
sub-expressions.

The `SymbolicExpression` class hiearrchy is split among `HeapExpression`s, that
represent operations that manipulate the dynamic memory (e.g., object creation,
field access), and `ValueExpression`s, that represent operations that produce
values (e.g., arithmetic operations, constants). This distinction is important
as it allows analyses to focus on either heap manipulations or value computations,
depending on their purpose. Both kinds of expressions can be combined to form
complex expressions that manipulate both values and memory locations.

### Heap Expressions

Heap expressions are symbolic expressions that represent operations
that manipulate the dynamic memory of the program. These include:

- `MemoryAllocation`, that allocates a new region of memory for a new object,
  array, or other data structure; the allocation can happen on the heap or on the stack,
  and can be provided with a set of [Annotations]({{ site.baseurl }}/documentation/annotations.html)
  that give additional information about the allocation itself;
- `HeapReference`, that creates a reference to a memory location identified by
  an inner `SymbolicExpression`;
- `HeapDereference`, that accesses the memory location pointed to by an inner
  `SymbolicExpression`;
- `AccessChild`, that accesses a child location (e.g., a field of an object,
  an element of an array) of a memory location, where both the `child` and the
  `container` are represented by inner `SymbolicExpression`s;
- `NullConstant`, that represents the `null` (or `None`, `nil`, etc.) value in
  the program.

When adopting [the Simple Abstract Domain framework]({{ site.baseurl }}/documentation/simple-abstract-domain.html),
heap expressions are **always** rewritten by the `HeapDomain` before being
evaluated by `ValueDomain` and `TypeDomain`.

### Value Expressions

Value expressions are symbolic expressions that represent operations
that produce values during program execution. `ValueExpression`s offer an
additional method: `removeNegations`, that simplifies boolean expressions by
removing negations and inverting comparison operators, where possible.
Value expressions include:

- `Constant`, that represents a constant value of any type in the program;
- `Skip`, that represents a no-operation expression that produces no value;
- `PushInv`, short for _push invalid value_, that represents an expression
  that pushes an invalid value onto the evaluation stack, that should be
  interpreted as a bottom value by analyses;
- `PushAny`, short for _push any value_, that represents an expression
  that pushes an unknown value onto the evaluation stack, that should be
  interpreted as a top value by analyses;
- `PushAnyWithConstaints`, a version of `PushAny` enriched with arbitrary binary
  constraints (i.e., `BinaryExpression`s with comparison operators) that the
  unknown value must satisfy;
- `UnaryExpression`, `BinaryExpression`, and `TernaryExpression`, that represent
  unary, binary, and ternary operations on inner `SymbolicExpression`s,
  respectively; these classes are parametric on the operator type, which is
  represented by a user-defined object;
- `Identifier`, that represents a named location (either a real program variable
  or a synthetic one used by the analysis to track some special value) in the program.

When adopting [the Simple Abstract Domain framework]({{ site.baseurl }}/documentation/simple-abstract-domain.html),
value expressions **might** be rewritten by the `HeapDomain` before being
evaluated by `ValueDomain` and `TypeDomain`. This is because sub-expressions of
a value expression may be heap expressions that need to be rewritten first.

### Identifiers

`Identifier`s play a key role in LiSA: other than modeling program variables,
they alre also used by a number of analysis components to represent specal
values (e.g., the return value of a function, the exception being thrown).

<center> <img src="{{ site.baseurl }}/documentation/ids.png" alt="The Identifier class hierarchy" /> </center>

An `Identifier` is a `ValueExpression` that is uniquely identified by its name.
An identifier can be _weak_ (as returned by the `isWeak` method), meaning that it
can represent multiple program locations at once (e.g., when modeling aliasing
or arrays) or _strong_, meaning that it represents a single program variable.
As discussed in
[the Semantic Domain page]({{ site.baseurl }}/documentation/semantic-domains.html#the-semantic-domain-interface),
special care must be taken when updating weak identifiers to avoid unsound
behaviors.
`Identifier`s can also be **scoped**, meaning that they can be hidden behind some
program construct (e.g., function calls) to avoid clashing with local
definitions. For instance, when an `Identifier` named `x` is scoped by the
instruction `scope`, it undergoes a sort of renaming, becoming `[scope]x`. This allows
to distinguish between different instances of `x` defined in different scopes.
Method `canBeScoped` returns `true` if the identifier can be scoped, while
`isScopedByCall` returns `true` if the identifier has been scoped by a call.
An identifier can be combined with another one through `lub`, that raises an
exception whenever the two identifiers are not compatible (i.e., they have different
names). If they have the same name, the resulting identifier is weak if at least one of
the two is weak.
Two more predicates are provided by the `Identifier` class: `canBeAssigned`,
returning wether assignments having that identifier as left-hand side are allowed
(useful for preventing assignments to special memory locations), and
`isInstrumentedReceiver`, returning `true` if the identifier represents an
entity (e.g., object or array) that is being initialized by the current
expression.

`Identifier` has five direct subclasses:

- `Variable`s represent program or synthetic variables and are always strong;
- `HeapLocation`s represent memory locations allocated during program execution
  and can be either weak or strong but cannot be scoped;
- `GlobalVariables` represent global program variables (or class static
  variables), are always strong, and cannot be scoped;
- `MemoryPointer`s represent references to `HeapLocation`s, are always strong,
  and cannot be scoped;
- `OutOfScopeIdentifer`s are identifiers that have been created by scoping
  another one (including another `OutOfScopeIdentifier`), that maintain the
  weakness property of the original identifier and can be scoped again.

Thus, any identifier that can be scoped becomes an `OutOfScopeIdentifier` named
`scope:name`, where `scope` is the `ScopeToken` (see the definition of the
[Scoped Object Interface]({{ site.baseurl }}/documentation/common-interfaces.html#the-scoped-object-interface))
used to scope it, and `name` is the original identifier's name.

Finally, the `Variable` class has three subclasses representing special
synthetic variables that LiSA uses to model specific program constructs:

- `InstrumentedReceiver` models the entity (e.g., object or array) being initialized
  by the current instruction;
- `CFGReturn` stores the value returned by `return` statements in control flow graphs;
- `CFGThrow` stores the exception being thrown by `throw` statements in control flow graphs.

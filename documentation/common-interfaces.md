---
layout: docpage
---

# Common Interfaces for the Analysis Structure

This page contains information about common interfaces used throughout the
analysis infrastructure of LiSA, that are applied to several components to
model shared properties, requirements and behaviors.

{% include diagrams.html %}

## The Structured Representation Interface

A `StructuredRepresentation` is a way to represent the contents of a complex
object in a structured way, such that it is (i) independent of its source,
(ii) comparable with other representations (potentially originating from
a different source), and (iii) serialisable. `StricturedRepresentation`s
are mainly used to produce human-readable representations of `Lattice`
elements, and to serialize them in ouput files into a unique format so that
several visualization tools can be built on top of the same output.

<center> <img src="{{ site.baseurl }}/documentation/structured.png" alt="The StructuredRepresentation class hierarchy" /> </center>

`StructuredRepresentation` is ab abstract class, that has five concrete
subtypes:

- `StringRepresentation`: a representation of any object as a string;
- `SetRepresentation`: a representation of any object as a sorted set of
  `StructuredRepresentation` elements;
- `ListRepresentation`: a representation of any object as an ordered list of
  `StructuredRepresentation` elements;
- `MapRepresentation`: a representation of any object as a map from
  `StructuredRepresentation` keys to `StructuredRepresentation` elements;
- `ObjectRepresentation`: a representation of any object as a named collection
  of fields, each field being a `StructuredRepresentation` element.

Instances of these classes just have to be created by passing the appropriate
values, and they will automatically provide the required functionalities
(like comparability and serializability).

A `StrucutredObject` is any object that can produce a `StructuredRepresentation`
of itself. The `Lattice` interface extends the `StructuredObject` interface,
meaning that all lattices can produce a structured representation of
themselves through the `representation` method.

## The Scoped Object Interface

The `ScopedObject` interface defines the common operations objects can be _scoped_.
Scoping is a mechanism provided bu LiSA to
isolate parts of an object when entering a new context (e.g., a function
call) and to restore them when exiting the context. Scoping is essential to
implement [Interprocedural Analyses]({{ site.baseurl }}/documentation/interprocedural-analysis.html),
as it allows to track caller's variables without polluting the callee state.

<center> <img src="{{ site.baseurl }}/documentation/scoped.png" alt="Scoped Objects" /> </center>

`ScopedObject` is parametric on the
type `T` that is returned by its methods. The interface defines two
methods: `pushScope`, that returns a new instance of the object where
all information contained in it becomes _hidden_ by the given scope token,
and `popScope`, that restores information in the receiver by removing
the scope specified by the `token` parameter.
Implementations of these methods usually manipulate program variables
(called `Identifier`s in
[Symbolic Expressions]({{ site.baseurl }}/documentation/symbolic-expressions.html)
terms) by applying a sort of renaming: since `SymbolicExpression`s are
instances of `ScopedObject`, `pushScope` and `popScope` implementations
should recursively invoke these methods on all symbolic expression references
they contain. This will cause an identifier `x` to be renamed to `[scope]x`,
such that it won't conflict with later definitions of `x` in inner scopes.

Scopes are indentified by `ScopeToken` instances, that are wrappers around a
`CodeElement` (i.e., any program construct that has a position in the source
program). This allows to easily identify scopes with program constructs
like function calls. Both `CodeElement` and `ProgramPoint` are defined in the
next section.

## Minimal Program Components

To reduce dependencies between the analysis structure and the program structure,
methods of analysis components that need to refer to program constructs
use (when possible) minimal interfaces that expose only the necessary information.

<center> <img src="{{ site.baseurl }}/documentation/minimal-prog.png" alt="Minimal Program Interfaces" /> </center>

Three such interfaces are used throughout the analysis structure:

- `CodeLocation`: instances of this interface represent a position in the
  source program; it exposes a single method, `getCodeLocation`, that returns a
  textual representation of that location; note that since the program might be
  composed by either source files or binary files, no structure is imposed to
  `CodeLocation`s as they might point to lines in a source file or offsets in a
  binary file;
- `CodeElement`: instances of this interface represent program constructs
  that have a position in the source program; since the program might be
  composed by either source files or binary files, the structure of a `CodeElement`
  is minimal, exposing only the `getLocation` method that returns the
  `CodeLocation` where the element is defined;
- `ProgramPoint`: instances of this interface represent specific points
  inside a control flow graph (`CFG`), that is part of a `Unit` of the
  `Program`; the main objective of this interface is to provide a way for
  analysis components to retrieve the `Program` where an instruction lies,
  so that it can be queried for language-specific properties.

Read more about [CFGs]({{ site.baseurl }}/documentation/cfgs.html),
[Units and Programs]({{ site.baseurl }}/documentation/units.html) in their dedicated pages.

---
layout: docpage
prereq:
  - text: Minimal Program Components
    link: documentation/common-interfaces.html#minimal-program-components
  - text: Statements, Expressions, and Edges
    link: documentation/st-ex-e.html
  - text: Annotations
    link: documentation/annotations.html
  - text: Control Flow Graphs
    link: documentation/cfgs.html
---

# Units

A `Unit` is a named container that groups together the globals and code members
of a logical program entity. Units represent the structural backbone of a program
in LiSA: they correspond to concepts such as files, modules, classes, and
interfaces, depending on the language being analyzed. Every
[`CFG`]({{ site.baseurl }}/documentation/cfgs.html) and every `Global` belongs to
exactly one unit. Units are gathered into a `Program`, and one or more programs
form an `Application` that LiSA analyzes as a whole.

This page describes the unit hierarchy, from the abstract `Unit` base class
and its associated globals, through the flat grouping units, up to the
`CompilationUnit` family that models object-oriented type hierarchies.

{% include diagrams.html %}

## The Unit class

The `Unit` abstract class is the common base for all units in LiSA. It groups
together a set of globals (variables or constants scoped to the unit) and a
set of code members (functions, methods, or procedures contained in it).
Within a single unit, each global is uniquely identified by its name, and each
code member is uniquely identified by its full signature.

<center> <img src="{{ site.baseurl }}/schemes/units-unit.png" alt="Unit class and globals"/> </center>

`Unit` provides a uniform API for accessing and searching its contents:

- `getGlobals()` and `getCodeMembers()` return the globals and code members
  defined directly in the unit, respectively;
- `getGlobal(String)` and `getCodeMember(String)` look up a specific element by
  name or signature, returning `null` if not found;
- `getCodeMembersByName(String)` returns all code members with the given name,
  regardless of their parameter signature;
- `getGlobalsRecursively()` and `getCodeMembersRecursively()` return all globals
  and code members accessible from the unit, including those defined in
  superunits; subclasses override these methods to add inherited members;
- `addGlobal(Global)` and `addCodeMember(CodeMember)` register a new element in
  the unit, returning `true` if the element was added or `false` if one with the
  same name or signature already existed;
- `getMatchingCodeMember(CodeMemberDescriptor)` searches for code members whose
  signature is compatible with the given descriptor according to
  `CodeMemberDescriptor.matchesSignature`, and is used during call resolution.

Two abstract methods complete the interface: `canBeInstantiated()` returns `true`
if instances of the unit can be created at runtime (i.e., it is a concrete
class), and `getProgram()` returns the `Program` this unit belongs to.

### Globals

A `Global` is a variable or field scoped to a unit. It records the variable's
name, static type (`getStaticType()`), source location
(`getLocation()`), annotations (`getAnnotations()`), and the unit that
contains it (`getContainer()`). The `isInstance()` flag distinguishes instance
fields (belonging to each object of the unit) from static globals (belonging to
the unit itself). Given a `CodeLocation`, the `toSymbolicVariable()` method
produces the `GlobalVariable` symbolic expression used to represent accesses to
the global during the analysis.

A `ConstantGlobal` is a `Global` that is bound to a fixed, statically known
value. It extends `Global` with a `getConstant()` method that returns the
`Constant` expression holding that value. Constant globals are never instance
globals: they are always scoped at the unit level. Their static type is
automatically inferred from the type of the constant.

## The Program unit

A `Program` is a `Unit` that collects all the units composing a single
programming-language program. The main purpose is to act as a registry of all
`Unit` instances parsed from the program's source, enriched with the
type system and the language-specific algorithms (e.g., call resolution --- more information on the
[Language Features and Type System]({{ site.baseurl }}/documentation/language-features-and-type-system.html) page)
and the entry points of the analysis. In a `Program` instance,
globals and code members are typically used to provide always-available built-ins and constants
(e.g., Python's `print` function).

<center> <img src="{{ site.baseurl }}/schemes/units-program.png" alt="Program unit" style="width: 60%"/> </center>

`Program` provides the following:

- `addUnit(Unit)` and `getUnits()` manage the collection of units in the program;
  `getUnit(String)` looks up a unit by name.
- `addEntryPoint(CFG)` and `getEntryPoints()` manage the set of CFGs from which
  the analysis should start. Entry points are typically the `main` functions or
  other top-level procedures of the program.
- `getAllCFGs()` traverses all units recursively and collects every `CFG` defined
  in the program, providing a global view of the code to analyze.
- `getFeatures()` returns the `LanguageFeatures` object that carries
  language-specific behaviors (such as call resolution strategies, parameter
  assignment strategies, and validation logic), which are configured by the
  frontend for the language being analyzed.
- `getTypes()` returns the `TypeSystem` that knows all the types appearing in the
  program and provides the type inference logic used during analysis.

{% include note.html content="`Program` cannot be added as a unit to another
`Program`: calling `addUnit` with a `Program` instance raises an exception.
Programs are meant to be composed at the `Application` level." %}

## The Application unit

An `Application` collects one or more `Program`s that must be analyzed together.
It is the top-level entry point passed to LiSA's analysis engine, and it supports
multi-language analysis by allowing programs written in different languages to
coexist.

<center> <img src="{{ site.baseurl }}/schemes/units-application.png" alt="Application" style="width: 60%"/> </center>

`Application` provides aggregated views over all its programs:

- `getPrograms()` returns the array of programs composing the application.
- `getAllCFGs()` returns all CFGs defined across all programs (lazily computed
  and cached on first access).
- `getEntryPoints()` returns the union of the entry points of all programs.
- `getAllCodeCodeMembers()` returns all code members defined across all programs,
  providing a global view of the callable constructs in the application.

Results are lazily computed and cached on first access, so repeated calls to
these methods are cheap.

## Units for grouping code

Not every unit in a program corresponds to an object-oriented type. Languages
such as Python, JavaScript, or C use files and modules as the primary unit of
organization, grouping functions and global variables without the notion of
instantiable types. LiSA represents these with two classes that sit below
`Unit` in the hierarchy but above the compilation-unit family.

<center> <img src="{{ site.baseurl }}/schemes/units-code-units.png" alt="ProgramUnit and CodeUnit" style="width: 60%"/> </center>

`ProgramUnit` is the abstract base for all units that can be part of a `Program`
and have a source location. It extends `Unit` and also implements `CodeElement`,
the minimal interface for program constructs with a location (see
[Minimal Program Components]({{ site.baseurl }}/documentation/common-interfaces.html#minimal-program-components)).

`CodeUnit` is a concrete, non-instantiable (i.e., whose `canBeInstantiated` returns `false`)
`ProgramUnit` that models a file or
module: a flat container of globals and code members without any inheritance
structure. Frontends
for procedural or scripted languages typically create one `CodeUnit` per source
file, populating it with the functions and top-level variables defined in it.

## Compilation Units

Compilation units model the object-oriented type constructs of a language —
classes, abstract classes, and interfaces — that organize code members and
globals into an inheritance hierarchy.

<center> <img src="{{ site.baseurl }}/schemes/units-compilation-units.png" alt="Compilation unit hierarchy"/> </center>

`CompilationUnit` is the abstract base for all units that participate in an
inheritance hierarchy. It extends `ProgramUnit` and adds the following
capabilities beyond those of `Unit`:

- Instance members: beyond the static code members and globals tracked by
  `Unit`, a `CompilationUnit` also tracks instance code members and globals
  (those defined on each object rather than on the type itself). All methods of
  `Unit` targeting globals and code members are also defined here for instance
  code members, with an additional boolean parameter to decide wheteher the
  search should be local to the unit or if the type hierarchy should be
  traversed.
- Annotations: unit-level annotations are stored and accessible via
  `getAnnotations()`. These are propagated during validation to subunits,
  following the rules described in the
  [Annotations]({{ site.baseurl }}/documentation/annotations.html#annotation-propagation)
  page.
- Hierarchy: `getImmediateAncestors()` returns the direct superunits of this
  unit (superclasses and/or superinterfaces), and `isInstanceOf(CompilationUnit)`
  checks whether this unit is a subtype of the given one, traversing the
  hierarchy transitively. `getInstances()` returns all units that directly or
  indirectly inherit from this one. The `isSealed()` flag prevents a unit from
  being used as a superunit.

Three concrete subclasses implement the different kinds of object-oriented types:

- `ClassUnit` represents a concrete class that can be instantiated
  (`canBeInstantiated()` returns `true`). It tracks its superclasses (via
  `getSuperclasses()` and `addSuperclass(ClassUnit)`) and the interfaces it
  implements (via `getInterfaces()` and `addInterface(InterfaceUnit)`). A class
  may inherit from multiple superclasses and implement multiple interfaces,
  depending on the language features declared through `LanguageFeatures`.
- `AbstractClassUnit` is a `ClassUnit` that cannot be instantiated
  (`canBeInstantiated()` returns `false`). It is used to represent abstract
  classes, that is, classes which define some abstract code members that must
  be implemented by concrete subclasses.
- `InterfaceUnit` represents an interface — a purely abstract type that defines
  a contract without providing implementations. It cannot be instantiated, and
  it can only inherit from other interfaces (tracked via
  `addSuperinterface(InterfaceUnit)`).

{% include tip.html content="When implementing a frontend, choose the unit type
that best matches the source language construct: `CodeUnit` for files and modules,
`ClassUnit` for concrete classes, `AbstractClassUnit` for abstract classes, and
`InterfaceUnit` for interfaces or traits. Use `Program` to gather all units of
a single-language program. `Application` should never be used directly: when
more than one program will be passed to LiSA for the analysis, an `Application`
object is automatically built." %}

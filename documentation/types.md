---
layout: docpage
prereq:
  - text: Minimal Program Components
    link: documentation/common-interfaces.html#minimal-program-components
  - text: Statements, Expressions, and Edges
    link: documentation/st-ex-e.html
  - text: Units
    link: documentation/units.html
---

# Types

Every value produced during a program analysis carries a type. In LiSA, the
type of a value determines which operations are applicable to it, how
assignments are checked, how type casts behave, and whether two values can be
mixed in, e.g., an arithmetic or logical expression. This page describes the type
hierarchy in LiSA: the core `Type` interface and its subtypes, the `TypeSystem`
that registers and reasons about types, and the concrete type families that
frontends use to model language-specific kinds of values.

All types in LiSA implement the `Type` interface, which acts as the single root
of the type hierarchy. Concrete type families extend it through a set of
sub-interfaces, each capturing a distinct kind of value: primitive scalars
(`BooleanType`, `CharacterType`, `StringType`, `NumericType`), in-memory
objects (`InMemoryType`, `UnitType`, `ErrorType`, `ArrayType`), pointer
references (`PointerType`, `ReferenceType`), and special sentinel types
(`Untyped`, `VoidType`, `NullType`). A separate `TypeTokenType` represents
type references appearing as first-class values in code.

{% include diagrams.html %}

## The Type Interface

The `Type` interface is the root contract that every type in LiSA must satisfy.
It provides a uniform API for type introspection, assignment compatibility, and
supertype resolution. For convenience, the following class diagram has a two column layout.

<center> <img src="{{ site.baseurl }}/schemes/types-type.png" alt="Type interface"/> </center>

Three methods form the core abstract contract that every concrete type must
implement:

- `canBeAssignedTo(other: Type)` returns `true` if a value of this type can be
  used where `other` is expected (i.e., this type is a subtype of `other`);
- `commonSupertype(other: Type)` returns the most specific type that is a
  supertype of both this type and `other`; when no meaningful supertype exists
  the method should return `Untyped.INSTANCE`;
- `allInstances(types: TypeSystem)` returns all concrete instances of this type
  that are registered in the given type system; for singleton types this is a
  set containing only the singleton; for parametric types like `ReferenceType`
  it may expand to a family of instantiated types; for types that support
  inheritance this may include all subtypes as well.

The `Type` interface also provides default implementations of a large family of
type-test and type-cast helpers. For every sub-interface `X` in the
hierarchy, `Type` declares:

- `isXType()` --- returns `true` if this type is an instance of `XType`;
- `asXType()` --- casts this type to `XType` and returns it, or `null` if the
  cast is not applicable.

Both methods have concrete default implementations, so sub-interfaces need not
override them.

`isValueType()` is a convenience default that returns `true` when the type is
neither an `InMemoryType` nor a `PointerType`, identifying types that can be
used for local variables in most languages. Specifically, this method can be
used as a shortcut for `ValueDomain`s to understand if they should track a
value or not. More information about `ValueDomain`s can be found in the
[Simple Abstract Domain]({{ site.baseurl }}/documentation/simple-abstract-domain.html) page.

Two additional methods provide means to create values for a given type:

- `defaultValue(cfg, location)` returns an `Expression` representing the
  default value of this type at the given program point (e.g., `0` for an
  integer); the base implementation returns `null`, meaning no default exists;
- `unknownValue(cfg, location)` returns an `Expression` representing an
  unknown value of this type, implemented as a `DefaultParamInitialization`
  node.

`castIsConversion()` returns `true` if a cast between types of this kind
actually converts the value (as opposed to merely reinterpreting the reference),
similarly to what happens in most languages when casting from a floating-point to an integer.
The base implementation returns `false`; `BooleanType` and `NumericType`
override it to return `true`.

The static helper `commonSupertype(types, fallback)` iterates over a collection
of types and computes their pairwise common supertype, returning `fallback` if
the collection is `null` or empty.

{% include important.html content="Every type should be implemented as a singleton
(accessed through a static `INSTANCE` field) or as a value-equal object whose
`equals` and `hashCode` methods are consistent. Type identity is tested
frequently during analysis, so inconsistent equality semantics will produce
incorrect results." %}

## The TypeSystem

The `TypeSystem` abstract class acts as the registry for all types appearing in
a `Program`. It is responsible for storing and looking up types by name, and
for providing the language-specific type operations used during analysis.

<center> <img src="{{ site.baseurl }}/schemes/types-type-system.png" alt="TypeSystem" style="width: 60%"/> </center>

The registry methods are concrete:

- `getTypes()` returns all types currently registered;
- `getType(name)` looks up a type by its string representation, returning
  `null` if not found;
- `registerType(type)` adds a type to the registry using `type.toString()` as
  the key, returning `true` if the type was newly registered or `false` if an
  entry with the same name already existed.

{% include important.html content="Since LiSA works on any programming
language, it has no built-in notion of available types. Registering types is
essential for LiSA to have a complete type hierarchy and to be able to answer
questions about type relationships during analysis. Every frontend is
responsible for registering **all** types that can appear in the analyzed
program. At startup, LiSA performs a few registrations automatically: all
primitive types are registered (see below), and a `ReferenceType` is registered
for each already-registered type that can be referenced." %}

Three methods operate on sets of types, as needed during expression analysis:

- `cast(types, tokens)` and `cast(types, tokens, mightFail)` filter a set of
  actual types against a set of `TypeTokenType` values; for each token and each
  actual type, if the actual type can be assigned to the token's type the actual
  type is kept in the result; the optional `mightFail` flag is set to `true` if
  any actual type was rejected, signalling that the cast might throw at runtime;
- `convert(types, tokens)` is like `cast` but returns the target types
  (from the tokens) rather than the source types, modelling a conversion that
  changes the runtime type of the value;
- `getReference(type)` wraps `type` in a `ReferenceType` after verifying via
  `canBeReferenced` that the language allows references to that type; it throws
  `IllegalArgumentException` if the check fails.

{% include tip.html content="Note that frontends that redefine the default
`ReferenceType` should override `getReference(type)` to return the appropriate,
language-specific type instance." %}

The abstract methods define the language-specific behaviour that every
TypeSystem implementation must provide:

- `getBooleanType()`, `getStringType()`, `getIntegerType()`, and
  `getCharacterType()` return the canonical instances for the four basic scalar
  type families;
- `canBeReferenced(type)` returns `true` if a `ReferenceType` wrapping `type`
  is valid in the language;
- `distanceBetweenTypes(first, second)` returns a non-negative integer
  measuring how "far apart" two types are in terms of conversions steps needed
  to convert the first type into the second; this distance
  is used during call resolution to rank candidate overloads: smaller values
  indicate a closer match.

## Primitive Types

Primitive types are the building blocks for scalar values in a language. LiSA
defines four primitive-type interfaces: `BooleanType`, `CharacterType`,
`StringType`, and `NumericType`. All four extend `Type` directly.

<center> <img src="{{ site.baseurl }}/schemes/types-primitive-types.png" alt="Primitive type interfaces"/> </center>

`BooleanType` is a marker interface for types representing boolean (`true`/`false`)
values. It overrides `castIsConversion()` to return `true`, reflecting that a
cast to or from a boolean type always converts the value.

`CharacterType` and `StringType` are pure marker interfaces --- they declare no
methods beyond what they inherit from `Type`. A frontend creates a concrete class
implementing one of these interfaces to introduce its character or string type.

Note that type interfaces in LiSA can be combined: for instance, a Java string
is both a `StringType` and an `InMemoryType`. Thus, primitive types are not
"primitive" in the sense of being always distinct from object types; rather,
they are primitive in the sense of representing common value types that have
special semantics in most languages.

### Numeric Types

`NumericType` is a richer interface for types that represent numbers.
It introduces three abstract methods that every numeric type must specify:

- `getNBits()` returns the number of bits used to represent the value (typically
  8, 16, 32, or 64);
- `isUnsigned()` returns `true` if the type represents an unsigned value;
- `isIntegral()` returns `true` if the type is an integer (as opposed to a
  floating-point) type.

The following default methods derive additional properties from those three:

- `is8Bits()`, `is16Bits()`, `is32Bits()`, `is64Bits()` check whether `getNBits()`
  equals the respective power-of-two size;
- `isSigned()` returns `!isUnsigned()`;
- `sameNumericTypes(other)` returns `true` if `other` has the same bit width,
  integrality, and signedness as this type;
- `supertype(other)` returns whichever of `this` or `other` is the wider type,
  preferring floating-point over integer and signed over unsigned when the bit
  width is the same;
- `castIsConversion()` returns `true`, consistent with `BooleanType`.

The static method `commonNumericalType(left, right)` computes the set of common
numeric supertypes across two sets of types. It filters both sets to numeric (or
untyped) values and, for each pair, uses `commonSupertype` to find the result.
Untyped values pair with any numeric type and contribute that numeric type to the
result. The method returns an empty set if both filtered sets consist entirely of
untyped values.

{% include tip.html content="When implementing a numeric type, override only
`getNBits()`, `isUnsigned()`, and `isIntegral()`. All other methods are derived
from these three. The canonical `supertype` ordering (wider > narrower,
floating-point > integer, signed > unsigned) is already implemented and should
not be changed unless the language has non-standard promotion rules." %}

## Special Types

LiSA provides three singleton types that serve as sentinels for special
situations: `Untyped` for values whose type is unknown or irrelevant, `VoidType`
for the absence of a value, and `NullType` for the null reference.

<center> <img src="{{ site.baseurl }}/schemes/types-special-types.png" alt="Special singleton types"/> </center>

Each is implemented as a concrete class with a public static `INSTANCE` field
and a protected constructor, following the singleton pattern. All three override
`canBeAssignedTo`, `commonSupertype`, and `allInstances` with type-specific
semantics.

`Untyped` (`Untyped.INSTANCE`) represents any possible type.
It can be used in languages with dynamic typing to represent the static type of
an expression, denoting that it can be of any type.
Its assignment rules reflect this: `canBeAssignedTo`
returns `true` only when `other` is also `Untyped`, and `commonSupertype`
always returns `Untyped.INSTANCE` regardless of the other operand. When asked
for `allInstances`, `Untyped` returns all types registered in the type system,
because an untyped value could be of any known type.

`VoidType` (`VoidType.INSTANCE`) represents the return type of procedures
that produce no value. A void value is never assignable to any other type
(`canBeAssignedTo` always returns `false`), and its only common supertype with
itself is `VoidType`; with any other type it falls back to `Untyped.INSTANCE`.

`NullType` (`NullType.INSTANCE`) is the type of the `null` literal. It
implements `InMemoryType` rather than `Type` directly, because null can only
appear as a reference to an in-memory location. Accordingly, `canBeAssignedTo`
returns `true` for any `InMemoryType` or `Untyped`, and `commonSupertype` with
any `InMemoryType` returns that in-memory type (`null` is assignable to any
reference), while any other combination produces `Untyped.INSTANCE`.

## In-Memory Types

In-memory types model structured values that are not atomic: for instance,
objects and structs that are composed of several fields, or pointers to other
memory regions. The marker interface `InMemoryType` extends `Type` and acts as
the root of this sub-hierarchy.

<center> <img src="{{ site.baseurl }}/schemes/types-in-memory-types.png" alt="In-memory type hierarchy" style="width: 70%"/> </center>

`InMemoryType` is a pure marker interface --- its presence on a type signals that
values of that type are structured and need special handling.
`isValueType()` (inherited from `Type`) returns `false` for all `InMemoryType`
instances.

### Array Types

`ArrayType` extends `InMemoryType` and represents multi-dimensional arrays. It
declares three abstract methods:

- `getInnerType()` returns the element type of the innermost dimension of the
  array (i.e., the type obtained by removing one dimension);
- `getBaseType()` returns the element type of a fully dereferenced array --- the
  type obtained by stripping all dimensions;
- `getDimensions()` returns the number of dimensions.

Frontends can implement `ArrayType` by providing a concrete class that pairs a base
element type with a dimension count.

### Unit Types and Error Types

`UnitType` extends `InMemoryType` and represents the runtime type of an instance
of a `CompilationUnit` --- in other words, the type of an object or struct. It declares one
abstract method, `getUnit()`, that returns the `CompilationUnit` that introduced this type.

Every frontend creates one `UnitType` implementation per class,
struct, or data type that can be instantiated, associating each type with its
defining unit.

`ErrorType` extends `UnitType` with no additional methods. It is a marker
interface for types whose instances can be thrown as errors or exceptions. When
a frontend models a throwable class, its associated type should implement
`ErrorType` so that LiSA's exception handling logic can identify it.

## Pointer Types

Pointer types represent values that refer to memory locations rather than
carrying data directly. `PointerType` is the root interface; `ReferenceType`
is the sole built-in implementation.

<center> <img src="{{ site.baseurl }}/schemes/types-pointer-types.png" alt="Pointer type hierarchy" style="width: 40%"/> </center>

`PointerType` extends `Type` and declares one abstract method:

- `getInnerType()` returns the type of the value that the pointer points to.

`isValueType()` returns `false` for all `PointerType` instances, consistent with
how pointer types behave in most languages.

`ReferenceType` is a concrete, value-equal class (not a singleton) that
implements `PointerType`. It is constructed with the inner type it points to:

- `ReferenceType(t)` creates a reference to type `t`;
- `getInnerType()` returns the inner type passed at construction.

Its assignment and supertype rules are structural: `canBeAssignedTo` returns
`true` for another `ReferenceType` whose inner type is a supertype of this
inner type, or for `Untyped`. `commonSupertype` with another `ReferenceType`
constructs a new `ReferenceType` whose inner type is the common supertype of both
inner types; with any other type it falls back to `Untyped.INSTANCE`.
`allInstances` expands to a set of `ReferenceType`s, one for each instance of
the inner type.

`ReferenceType` instances are created through `TypeSystem.getReference(type)`,
which first verifies that the language allows references to `type` via
`canBeReferenced`.

{% include note.html content="Do not construct `ReferenceType` objects directly
in frontend code. Always go through `TypeSystem.getReference(type)` so that the
language-specific `canBeReferenced` check is enforced." %}

## Type Tokens

`TypeTokenType` represents the type of a type token: a first-class reference
to a type that appears as a value in the analyzed program. Type tokens arise, for
example, from class-literal expressions (`Foo.class` in Java) or arguments of cast expressions.

<center> <img src="{{ site.baseurl }}/schemes/types-token-type.png" alt="TypeTokenType" style="width: 20%"/> </center>

A `TypeTokenType` wraps a set of `Type` objects --- the types that the token may
refer to at runtime; `getTypes()` returns that set.

`canBeAssignedTo` returns `true` for another `TypeTokenType` or for `Untyped`.
`commonSupertype` with itself returns `this`; with any other type it falls back
to `Untyped.INSTANCE`. `allInstances` returns a singleton set containing this
token type.

Type tokens are produced and consumed by `TypeSystem.cast` and
`TypeSystem.convert`, which use the wrapped type set to determine which actual
types are reachable through a cast or conversion operation.

{% include tip.html content="When a frontend encounters a class-literal
expression or a type instantiation, create a `TypeTokenType` wrapping the set
of statically known target types and use it as the static type of the
expression. This allows `TypeSystem.cast` and `TypeSystem.convert` to resolve
the operation correctly during the analysis." %}

# The IMP Language

IMP is a high-level, imperative, and dynamically-typed programming language
inspired by Java. IMP is used as the main testing language in LiSA.

{% include note.html content="This page is not meant as a formal
specification of the IMP language, but rather as a quick reference
guide built through examples." %}

## Comments

Single-line comments start with two forward slashes (`//`).

```java
// this is a single line comment
```

Multi-line comments are enclosed between `/*` and `*/`.

```java
/* this is a
   multi line
   comment */
```

## Typing

IMP is dynamically typed: the type of a variable is determined at run-time and
does not have to be specified in the source code.
IMP also allows binding the same variable through assignment statements
to values of different types. The keyword
`def` always precedes the declaration of a variable.

```java
def x = true;
x = -5.2;
x = "Static Analysis is Amazing!";
```

Note that each instruction must end with a semicolon.

### Basic Types

IMP supports the following basic data types:

- **boolean**, with values `true` or `false`;
- signed 32-bit **integer**, with values between Java's `Integer.MIN_VALUE` and
  `Integer.MAX_VALUE`, e.g., `-5`, `0`, `+10`;
- signed single-precision 32-bit **float**, with values between
  `-Float.MAX_VALUE` and Java's `Float.MAX_VALUE`, e.g., `-0.5`, `3.0`, `+5.4`;
- atomic **string**, that is, text surrounded by double quotes, e.g., `"Hello!"`
  (contrary to Java, string is not an object but a basic data type).

### Reference Types

IMP supports the following reference data types:

- **objects**, instances of one of the classes defined in the program;
- **arrays** of the types defined above.

## Classes

An IMP program contains zero or more classes.

```java
class Vehicle {}
```

The `class` keyword is used to declare the IMP class `Vehicle`, whose body is
enclosed within the curly `{}` braces.

### Inheritance

An IMP class can inherit attributes and methods from another class.

```java
class Motorbike extends Vehicle {}
```

The `extends` keyword expresses that the class `Motorbike` inherits the
`Vehicle` class' attributes and methods, which is a superclass. Conversely,
the class `Motorbike` is a subclass of the class `Vehicle`.

### Interfaces

Besides classes, an IMP program can also declare interfaces.

```java
interface Drivable {
  turnOn();
}
```

The `interface` keyword declares the IMP interface `Drivable`. Interface
members are method signatures, that is, method declarations without a body,
terminated by a semicolon. An interface can also declare methods with a
body, that behave as Java's default methods: they are inherited as-is by
whoever implements the interface, unless explicitly overridden.

```java
interface Drivable {
  turnOn(); // method signature, without a body

  honk() { // default method, with a body
    return true;
  }
}
```

An interface can extend one or more other interfaces, separated by a comma,
inheriting all of their members.

```java
interface FourWheelDrivable extends Drivable, OffRoadCapable {}
```

A class declares that it provides an implementation for one or more
interfaces through the `implements` keyword, also followed by a
comma-separated list. A class implementing an interface must provide a
method for each of the interface's signatures that is not backed by a
default implementation.

```java
class Motorbike extends Vehicle implements Drivable {
  turnOn() {
    return true;
  }
}
```

### Abstract Classes

A class can be declared `abstract`; as in Java, an abstract class cannot be
instantiated directly, and is meant to be extended by other classes. Like
interfaces, abstract classes can declare method signatures without a body,
that subclasses are expected to implement, alongside regular methods.

```java
abstract class Vehicle {
  turnOn(); // method signature, without a body

  honk() { // regular method, with a body
    return true;
  }
}
```

### Class Members

Each class has zero or more members, that can be fields, constants,
constructors, or methods.
As opposed to Java, IMP has no concept of static members of a class.
IMP also does not have access modifiers, i.e., the scope of a field,
method, constructor, or class is always public.

#### Methods

A method is a block of code that is executed only when it is called.
Methods are declared specifying their name and parameters.

```java
myMethod() {}
```

A `void` method can also have explicit return statements.

```java
foo() {
  return;
}

bar(i, w) {
  return i + w;
}
```

As in Java, methods have an implicit parameter named `this`, that refers to the
object on which the method is invoked.

A subclass can override a method from a superclass by simply redefining it.
The overridden method can still be invoked through the `super` keyword, e.g.,
`super.foo()`. Note that subclasses cannot override a method preceded by the
keyword `final`.

#### Constructors

A constructor is a particular method used to initialize objects, and it
cannot be overridden. A tilde `~` precedes constructors. Note that to invoke a
constructor, the tilde is omitted.

```java
class Motorbike extends Vehicle {
  ~Motorbike(){} // this is a constructor

  create() {
    return new Motorbike(); // invoking the constructor
  }
}
```

#### Fields

Fields are declared by only specifying their name and do not support
in-place initialization. A field cannot be declared final.

```java
class Vehicle {
  brand = "Audi"; // this raises an error
}

// the correct form is:
class Vehicle {
  brand;
  ~Vehicle() {
    this.brand = "Audi";
  }
}
```

Fields can be accessed anywhere inside and outside the class.

#### Constants

A constant is a field whose value is fixed at compile time. Constants are
declared using the `const` keyword, followed by their name, an equal sign,
and a literal value; contrary to fields, constants support in-place
initialization, but their value cannot be `null`.

```java
class Vehicle {
  const wheels = 4;
}
```

## Expressions

An expression can be:

1. a literal: any constant value that can be assigned to a variable, e.g., `5`,
   `"s"`, `true`, `null`, or `-5.2`;
2. the keywords `this` and `super`, that respectively refer to the receiver of
   the method being executed, and to that same receiver seen as an instance of
   its superclass (e.g., to invoke an overridden method as `super.foo()`);
3. an identifier: an alphanumeric string representing a valid variable name
   (used also for field names);
4. a logical operation: binary _and_ (`&&`), binary _or_ (`||`), or unary _not_
   (`!`);
5. an arithmetic operation: binary _addition_ (`+`), binary _subtraction_ (`-`),
   binary _multiplication_ (`*`), binary _division_ (`/`), or binary _modulus_ (`%`);
6. a comparison: binary _equal to_ (`==`), binary _not equal_ (`!=`), binary
   _greater than_ (`>`), binary _less than_ (`<`), binary _greater than or equal
   to_ (`>=`), or binary _less than or equal to_ (`<=`) (note that `==` and `!=`
   are the only comparisons that can be applied to non-numeric operands);
7. a type check: `x is Motorbike` evaluates to `true` if the runtime type of
   `x` is `Motorbike`, or a subtype of it;
8. a type cast: `x as Motorbike` casts `x` to the type `Motorbike`;
9. an array creation: `new int[5]` that creates a one-dimensional `int` array of
   length 5 (multi-dimensional arrays are also supported);
10. an access to an array element: `intArray[2]`, where the receiver _must_ be
    stored in a local variable (indexing is 0-based);
11. an object creation: `new Motorbike()` that allocates the object and invokes
    the corresponding constructor;
12. a field access: `this.brand`, where the receiver (`this`, `super`, or a
    local variable, _not_ an arbitrary expression) _must_ be explicit;
13. a method call: `this.foo(x)`, where the receiver (`this`, `super` or a local
    variable, _not_ an arbitrary expression) _must_ be explicit; possible parameters are:
    1. literals;
    2. variables;
    3. `this`;
    4. a field access;
    5. an array access;
    6. another method call;
14. an assignment: `x = 15`, where the left-hand side can be a local variable, a
    field access or an array access, and the right-hand side is an expression;
15. a string concatenation: `str + "foo"`, where the operands are expressions;
16. a string manipulating operator, written as a receiver-less call whose
    arguments are expressions:
    1. `strlen(a)` returns the integer length of the string represented by `a`;
    2. `strcat(a, b)` returns the concatenations of the strings represented by `a`
       and `b`;
    3. `strindex(a, b)` returns the integer index of the first occurrence of the
       string represented by `b` inside the string represented by `a`;
    4. `streq(a, b)` returns `true` if the contents of the strings represented by `a`
       and `b` are equal;
    5. `strcon(a, b)` returns `true` if the string represented by `b` is contained
       in the string represented by `a`;
    6. `strstarts(a, b)` returns `true` if the string represented by `a` starts with
       the string represented by `b`;
    7. `strends(a, b)` returns `true` if the string represented by `a` ends with the
       string represented by `b`;
    8. `strrep(a, b, c)` returns a new string that is equal to the one represented by
       `a` where each occurrence of the string represented by `b` is replaced with the
       string represented by `c`;
    9. `strsub(a, i, j)` returns the substring of the string represented by `a`,
       starting from the position represented by `i` (inclusive) and ending at the
       position represented by `j` (exclusive);
17. an array manipulating operator, `arraylen(a)`, that returns the integer
    length of the array represented by `a`.

Note that expressions can also be grouped using parentheses.

### Static Allocation

Array and object creation expressions have a statically-allocated
counterpart, introduced by the `bump` keyword instead of `new`: `bump int[5]`
and `bump Motorbike()` follow the same syntax as their `new` counterparts,
but allocate the array or object directly instead of allocating it on the
heap and yielding a reference to it. This distinction only affects the
memory model used by LiSA's analyses.

### Variable Scoping

When created, variables are preceded by the keyword `def`.

```java
def x;
```

The scope of variables in IMP is similar to the one in Java. Local
variables are declared inside a method and cannot be accessed outside of it.
They are only visible inside the inner-most block of code, delimited by curly
brackets, that contains their definition, and inside all blocks of code
nested inside it.

```java
class Vehicle {
  brand; // this is a field

  countKm() {
    def y = true; // this is a local variable visible until the end of the method
    if (y) {
      def x = 5; // this is a local variable visible until the end of the if block
    }
  }
}
```

## Annotations

Classes, interfaces, fields, constants, constructors, methods, method
parameters, and local variable declarations can be decorated with one or
more annotations, enclosed in square brackets `[]` and placed right before
the element they annotate.

```java
[tainted]
class Vehicle {
  [notNull]
  brand;
}
```

An annotation can optionally carry members, written as a comma-separated
list of `name = value` pairs enclosed in parentheses. A member's value can
be a literal, an array of literals enclosed in square brackets, or the name
of a unit (a class or an interface).

```java
[source(kind = "user-input", trusted = false, ids = [1, 2, 3])]
def x = readInput();
```

Multiple annotations can be attached to the same element by separating them
with a comma.

```java
[notNull, tainted]
foo3([notNull] i, [tainted] j) {
  return i + j;
}
```

## Control Flow

In the following, if only one instruction is present inside a control flow block,
then the curly braces can be omitted.

### IF Statement

The `if` statement is used to specify a block of code to be executed if a
condition is `true`. The condition is an expression enclosed in parentheses
`()`.

```java
def x = 4;
def y = 3;
if (x != 5) {
  return y;
}
```

### ELSE Statement

The `else` statement is used to specify a block of code to be executed if
a condition is `false`. Note that the `else` statement is optional.

```java
def x = 5;
def y = 3;
if (x != 5) {
  return y;
} else {
  y = y + 1;
}
```

### WHILE Loop

A `while` loop keeps executing a block of code while a condition is true.
The condition is an expression enclosed in parentheses `()`.

```java
def i = 5;
while (i < 100) {
  i = i * 2;
}
```

### FOR Loop

A `for` loop is composed of three instructions: an initialization, a
condition, and a post-operation. The initialization is executed only once at the
beginning of the loop. Then, the loop body is repeated while the condition holds.
At each iteration of the loop, after executing the whole loop body, the
post-operation is executed. The initialization is a local variable declaration
or an expression, while the condition and the post-operation are expressions.
All three are optional, but the semicolons are not.

```java
for (def i = 0; i < 20; i = i + 1) {
  y = y + 5;
}
```

### Labeled Loops, BREAK and CONTINUE

The `break` statement immediately exits the innermost `while` or `for` loop,
while the `continue` statement immediately jumps to the next iteration of
the innermost loop.

```java
def i = 5;
while (i < 100) {
  if (i == 10) {
    break;
  }
  i = i * 2;
}
```

Both `while` and `for` loops can be preceded by a label, that is, an
identifier followed by a colon `:`. When followed by a label, `break` and
`continue` respectively exit and continue the labeled loop instead of the
innermost one, which is useful to escape or advance an outer loop from
within a loop nested inside it.

```java
loop: for (def i = 0; i < 10; i = i + 1) {
  while (i < 5) {
    if (i == 3) {
      break loop;
    }
    i = i + 1;
  }
}
```

## Returning Values and Throwing Errors

A method can return a value using the `return` keyword followed by an
expression. If the method does not return any value, the `return` keyword can
be used alone to exit the method. Note that all return statements must be
of the same kind: either all returning a value or all not returning any value.
In case a method does not return any value, the return statement can be omitted
at the end of the method body.

```java
return foo();
return;
```

It is possible to throw any object to raise errors using the `throw`
keyword.

```java
throw foo();
def r = foo();
throw r;
```

## Exception Handling

Errors raised with `throw` can be handled using a `try` statement, mirroring
Java's semantics.

```java
try {
  risky();
} catch (IOException e) {
  handle(e);
}
```

A `try` block can be followed by one or more `catch` blocks. Each `catch`
can list one or more exception types separated by a comma, and can
optionally bind the caught exception to a variable, whose name is written
last.

```java
try {
  risky();
} catch (NetworkError, IOException e) {
  // e refers to the object that was thrown, whatever its actual type is
  handle(e);
} catch (OutOfMemoryError) {
  // the exception object is not bound to any variable here
  abort();
}
```

An optional `else` block, executed only if the `try` block completes without
raising any error, can follow the last `catch` block. An optional `finally`
block, always executed regardless of whether an error was raised and caught,
can close the whole statement.

```java
try {
  risky();
} catch (IOException e) {
  handle(e);
} else {
  // executed only if risky() does not throw
  onSuccess();
} finally {
  // always executed
  cleanup();
}
```

## Assertions

Assertions are allowed, using the `assert` keyword followed by a Boolean
expression. Assertions have the classical meaning of halting the program
with an error if the expression evaluates to `false`.

```java
assert x == 10;
```

## Example Programs

Several IMP programs that can be used as examples can be found in the
[testcases folder](https://github.com/lisa-analyzer/lisa/tree/master/lisa/lisa-analyses/imp-testcases)
inside the LiSA repository.

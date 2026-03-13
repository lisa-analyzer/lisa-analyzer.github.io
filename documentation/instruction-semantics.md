---
layout: docpage
prereq:
  - text: Abstract State
    link: documentation/lattices.html#the-analysis-state
  - text: Analysis
    link: documentation/semantic-domains.html#the-analysis-class
  - text: Interprocedural Analysis
    link: documentation/interprocedural-analysis.html#the-interprocedural-analysis-interface
  - text: Symbolic Expressions
    link: documentation/symbolic-expressions.html
---

# Specifying the Semantics of Instructions

As LiSA aims at running any kind of analysis on any programming language, what
happens when an instruction is executed needs to specified in a way that is
independent from both. This happens through
[Symbolic Expressions]({{ site.baseurl }}/documentation/symbolic-expressions.html),
a language-independent representation of the operations performed by instructions.
These symbolically represent atomic operations on values and addresses, and can
thus be employed independently from the analysis being run. E.g., an instruction
can specify that an addition between two values is performed, without specifying
how the result of the addition is computed. The information that an addition
is being executed is given to abstract domains by feeding them the corresponding
symbolic expression, to be processed on a specific abstract state. With this
workflow, (i) the instructions can spefcify what operations are performed
without computing their result, that entirely depends on the abstract domain,
and (ii) the abstract domains can compute the result of the operations without
knowing the syntactic construct that generated them, thus being completely
decoupled from the source programming language.

Specifying the semantics of instructions is akin to specifying their small step
semantics. This happens in the `forwardSemantics` and `backwardSemantics`
methods of the [`Statement`]({{ site.baseurl }}/documentation/st-ex-e.html) class,
that is the root class for instructions that can appear in the program.

{% include warn.html content="Backward analysis is experimental, and has been
added mainly for teaching purposes. There is no full support for backward
analyses yet in LiSA. Thus, the reset of this page will focus on fordward
analyses, and will discuss the `forwardSemantics` method only." %}

The `forwardSemantics` is parametric to the type `A extends
<AbstractLattice<A>>` of the abstract state, and to the type `D extends
AbstractDomain<D>>` of the abstract domain. This means that the semantics
definition does not have access to any implementation-specific detail of the
analysis being run. The method receives three parameters:

- `entryState`: and `AnalysisState<A>` instance representing the the state of
  the analysis when the instruction is executed;
- `interprocedural`: the `InterproceduralAnalysis<A, D>` instance for the
  analysis, that can be used to compute the result of calls;
- `expressions`: a `StatementStore<A>` (a
  [functional lattice]({{ site.baseurl }}/documentation/lattices.html#powersets-and-functions)
  from `Statement`s to `AnalysisState<A>`s) where the result of intermediate
  expressions is to be stored.

Implementations of the `forwardSemantics` method are expected to return an
`AnalysisState<A>` instance representing the state of the analysis after the
instruction is executed. Results of the semantics of inner expressions
(e.g., the right and left hand-side of an assignment) are expected to be stored
in the `expressions` lattice, so that they can be retrieved by LiSA as needed.

The rest of this page will discuss different implementations of the
`forwardSemantics` method by examples.

## Semantics of No-op Instructions

The most basic implementation of the `forwardSemantics` method is the one of
a no-op instruction, whose execution does not change the state of the analysis:

```java
public final <A extends AbstractLattice<A>, D extends AbstractDomain<D>> AnalysisState<A> forwardSemantics(
        AnalysisState<A> entryState,
        InterproceduralAnalysis<A, D> interprocedural,
        StatementStore<A> expressions)
        throws SemanticException {
    return entryState;
}
```

As no computation is performed, the method simply returns the input state as it
is. Note that the entry state also carries a set of symbolic expressions that
have been computed and represent the contents of the operand stack. The code
above returns the state as-is, meaning that the contents of the operand stack
are not modified. This might not be ideal, as the instruction might reset the
stack contents. If one wants to prevent this, a simple modification is needed:

```java
public final <A extends AbstractLattice<A>, D extends AbstractDomain<D>> AnalysisState<A> forwardSemantics(
        AnalysisState<A> entryState,
        InterproceduralAnalysis<A, D> interprocedural,
        StatementStore<A> expressions)
        throws SemanticException {
    return entryState.withExecutionExpression(new Skip(getLocation()));
}
```

The invocation of the `withExecutionExpression` changes the operand stack by
setting it to a set containing only a `Skip` symbolic expression, that represents
an instruction that does not have a value. This distinguishes invalid states
(i.e., ones where no instruction has been executed) from valid states that have
no value on the stack.

## Semantics of instructions that produce a value

Instructions that produce a value are subtypes of the [`Expression`]({{ site.baseurl }}/documentation/st-ex-e.html)
class. Expressions differ from statements in that they have a type associated
with them (i.e., the static type of the values they can produce) and that they
store a collection of _meta variables_, that are synthetic variables that
represent temporary values that remain on the stack until after the instruction
is executed. For example, an allocation of a data structure in memory will
produce a reference to the allocated memory that is lost if it is not stored in
a variable. Such reference should be added to the meta variables of the
insrtuction so that outer expressions (e.g., assignemnts) can utilize it. When
the root insrtuction has completed execution, the state is cleared from all meta
variables, simulating their removal from the stack.

Aside from these two differences, the semantics of expressions is defined in the
same way as the one of statements. The only difference is that the result of the
expression is left on the stack as a symbolic expression. For instance, an
expression that models a literal value will implement its semantics as (assuming
that the literal value is stored in the `literal` field):

```java
public final <A extends AbstractLattice<A>, D extends AbstractDomain<D>> AnalysisState<A> forwardSemantics(
        AnalysisState<A> entryState,
        InterproceduralAnalysis<A, D> interprocedural,
        StatementStore<A> expressions)
        throws SemanticException {
    Analysis<A, D> analysis = interprocedural.getAnalysis();
    return analysis.smallStepSemantics(entryState, new Constant(getStaticType(), this.literal, getLocation()), this);
}
```

Similarly, an expression that reads the value of a variable will implement its
semantics as (assuming that the variable is stored in the `variable` field):

```java
public final <A extends AbstractLattice<A>, D extends AbstractDomain<D>> AnalysisState<A> forwardSemantics(
        AnalysisState<A> entryState,
        InterproceduralAnalysis<A, D> interprocedural,
        StatementStore<A> expressions)
        throws SemanticException {
    Analysis<A, D> analysis = interprocedural.getAnalysis();
    return analysis.smallStepSemantics(entryState, new Variable(getStaticType(), this.variable, getLocation()), this);
}
```

In both cases, the `Analysis` instance that contains a reference to the abstract
domain to be executed is retrieved from the `InterproceduralAnalysis` instance.
Then, the `smallStepSemantics` method is used to process a non-assigning
expression: the creation of a constant value in the first case, and the access
to a variable by its name in the second case. The result of the small step semantics
is a new `AnalysisState` instance, that can be returned to the caller as the
state after the execution of the instruction. In both cases, the returned
state's `computedExpressions` field will contain a singleton collection
containing the symbolic expression that has been passed to the
`smallStepSemantics` method.

## Semantics of compound instructions

A compound instruction is an instruction that contains other sub-instructions.
For example, an assignment, a call, or even a simple addition. Let's start with
the latter, supposing that the left and right operands are stored into the
`left` and `right` fields, respectively:

```java
public final <A extends AbstractLattice<A>, D extends AbstractDomain<D>> AnalysisState<A> forwardSemantics(
        AnalysisState<A> entryState,
        InterproceduralAnalysis<A, D> interprocedural,
        StatementStore<A> expressions)
        throws SemanticException {
    AnalysisState<A> leftState = this.left.forwardSemantics(entryState, interprocedural, expressions);
    AnalysisState<A> rightState = this.right.forwardSemantics(leftState, interprocedural, expressions);

    expressions.put(this.left, leftState);
    expressions.put(this.right, rightState);

    Analysis<A, D> analysis = interprocedural.getAnalysis();
    AnalysisState<A> result = entryState.bottom();
    for (SymbolicExpression l : leftState.getComputedExpressions())
        for (SymbolicExpression r : rightState.getComputedExpressions())
            result = result.lub(analysis.smallStepSemantics(
                 rightState,
                 new BinaryExpression(getStaticType(), new NumericAddition(), l, r, getLocation()),
                 this));

    getMetaVariables().addAll(this.left.getMetaVariables());
    getMetaVariables().addAll(this.right.getMetaVariables());
    this.left.getMetaVariables().clear();
    this.right.getMetaVariables().clear();

    return result;
}
```

As can be seen, there are several operations that are performed in the code
above:

1. the semantics of the two sub-instructions are recursively computed by
   invoking their `forwardSemantics` method, the first operating on the entry
   state, and the second operating on the state resulting from the semantics
   computation of the first sub-instruction;
2. the result of both computations is stored in the `expressions` map;
3. the result of the expression is initialized to the bottom value;
4. for every possible combination of the symbolic expressions resulting
   from the two sub-instructions, a `BinaryExpression` symbolic expression
   with an operator corresponding to the addition (determined by the
   `NumericAddition` operator) between the two is created and fed to the
   analysis by invoking the `smallStepSemantics` method;
5. the result on each combination is lubbed to the result of the expression,
   thus computing an over-approximation of all possible cases;
6. the meta variables of the two sub-instructions are added to the meta
   variables of the current instruction and cleared from the original one
   to propagate them towards the root instruction;
7. the final result is returned.

Note that the above workflow is common to all compound instructions, with the
only difference being in step 4. For this reason, LiSA provides a dedicated
class hierarchy for compound instructions, rooted in `NaryStatement` and
`NaryExpression`, that implement steps 1, 2, 3, 5, 6, and 7, and leave step 4 to
the concrete subtypes. Both classes implement `forwardSemantics` providing the
above steps, leaving the implementation of step 4 to the `forwardSemanticsAux`
method. The above semantics can thus be implemented in a subtype of
`NaryExpression` by implementing the `forwardSemanticsAux` method as:

```java
public <A extends AbstractLattice<A>, D extends AbstractDomain<A>> AnalysisState<A> forwardSemanticsAux(
        InterproceduralAnalysis<A, D> interprocedural,
        AnalysisState<A> state,
        ExpressionSet[] params,
        StatementStore<A> expressions)
        throws SemanticException {
    Analysis<A, D> analysis = interprocedural.getAnalysis();
    AnalysisState<A> result = state.bottom();
    for (SymbolicExpression l : params[0])
        for (SymbolicExpression r : params[1])
            result = result.lub(analysis.smallStepSemantics(
                 rightState,
                 new BinaryExpression(getStaticType(), new NumericAddition(), l, r, getLocation()),
                 this));
    return result;
}
```

`forwardSemanticsAux` still receives the `InterproceduralAnalysis` instance and
the `StatementStore` instance, together with the `state` resulting from the
evaluation of all sub-instructions, and an array of `ExpressionSet`s that
represent the symbolic expressions resulting from the evaluation of each sub-instruction.
Again, the implementation of this method follows the same pattern of iterating
over all possible combinations of symbolic expressions and feeding them to the
analysis. This can be simplified if the number of sub-instructions is known (and
thus the number of nested loops can be determined). LiSA provides several
classes that fix the number of sub-instructions:

- `UnaryStatement` and `UnaryExpression` for instructions with one sub-instruction,
  that implement `forwardSemanticsAux` with a single loop over `params[0]` and
  invoke the `fwdUnarySemantics` method on each symbolic expression,
  that is left to be implemented by the concrete subtypes;
- `BinaryStatement` and `BinaryExpression` for instructions with two sub-instructions,
  that implement `forwardSemanticsAux` with two nested loops over `params[0]`
  and `params[1]` and invoke the `fwdBinarySemantics` method on each pair of
  symbolic expressions, that is left to be implemented by the concrete subtypes;
- `TernaryStatement` and `TernaryExpression` for instructions with three sub-instructions,
  that implement `forwardSemanticsAux` with three nested loops over `params[0]`,
  `params[1]`, and `params[2]` and invoke the `fwdTernarySemantics` method on
  each triple of symbolic expressions, that is left to be implemented by the
  concrete subtypes.

All the methods introduced by these classes have the same parameters as `forwardSemanticsAux`,
except for the `params` array that is replaced by as many parameters as the
number of sub-instructions, each of type `SymbolicExpression`.
Whit this workflow, the semantics of the addition above can be implemented in a
subtype of `BinaryExpression` by implementing the `fwdBinarySemantics` method
as:

```java
public <A extends AbstractLattice<A>, D extends AbstractDomain<A>> AnalysisState<A> fwdBinarySemantics(
        InterproceduralAnalysis<A, D> interprocedural,
        AnalysisState<A> state,
        SymbolicExpression left,
        SymbolicExpression right,
        StatementStore<A> expressions)
        throws SemanticException {
    Analysis<A, D> analysis = interprocedural.getAnalysis();
    return analysis.smallStepSemantics(
        state,
        new BinaryExpression(getStaticType(), new NumericAddition(), left, right, getLocation()),
        this);
}
```

Other than `smallStepSemantics`, all semantics computations can freely use any
method provided by both the `Analysis` and `AnalysisState` classes, as well as
methods from `InterproceduralAnalysis`. For instance, the semantics of a
pre-increment insrtuction `++x` ca be implemented in a `UnaryExpression` as:

```java
public <A extends AbstractLattice<A>, D extends AbstractDomain<A>> AnalysisState<A> fwdUnarySemantics(
        InterproceduralAnalysis<A, D> interprocedural,
        AnalysisState<A> state,
        SymbolicExpression operand,
        StatementStore<A> expressions)
        throws SemanticException {
    Analysis<A, D> analysis = interprocedural.getAnalysis();
    AnalysisState<A> result = analysis.assign(
        state,
        operand,
        new BinaryExpression(
            getStaticType(),
            new NumericAddition(),
            operand,
            new Constant(new IntegerType(), 1, getLocation()),
            getLocation()),
        this);
    return result.withExecutionExpression(operand);
}
```

The computation performs an assignment between the operand (i.e., the variable
being incremented) and the result of the addition between the operand itself and
the constant value `1`. The result of the assignment is returned as the result of
the semantics, and the operand is left on the stack as the result of the expression.

### Semantics of calls

A call instruction is simply an `NaryExpression`, and its semantics is computed
according to the workflow described above. As part of the workflow,
`interprocedural.resolve()` and `interprocedural.getAbstractResultOf` can be
used to compute the result of the call (for more details on the call types and
how they are handled by LiSA, see the
[call graph]({{ site.baseurl }}/documentation/call-graph.html) page and the
[interprocedural analysis]({{ site.baseurl }}/documentation/interprocedural-analysis.html)
pages). The novelty in terms of semantics computation lies in how the result of
such calls is modeled in the state: since there is no symbolic expression to
model a call (this is by design, as symbolic expressions are handled by abstract
domains, and LiSA aims at abstracting away calls before they reach domains),
the result of a call (i.e., the return value of the called functions, if any)
is modeled by a meta variable. Such variable will also contain any annotation
defined by the called function(s), enabling propagation of annotation-based
invariants. The meta variable is then left on the stack as the result of the
call expression, and can be used by outer expressions (e.g., assignments)
uniformly with any other symbolic expression.

### Semantics of memory operations

Memory operations can be very complex, with each programming language performing
several slightly-different operations on memory. LiSA instead adopts a
simplified memory model, in which memory can be allocated, referenced,
dereferenced, and traversed (e.g., by accessing the fields of a data structure).
The semantics of complex memory operations thus has to be defined in terms of
these basic operations. For instance, the (simplified) semantics of a Java object allocation
corresponding to the `new` operator can be defined in an `NaryExpression` as:

```java
public <A extends AbstractLattice<A>, D extends AbstractDomain<A>> AnalysisState<A> forwardSemanticsAux(
        InterproceduralAnalysis<A, D> interprocedural,
        AnalysisState<A> state,
        ExpressionSet[] params,
        StatementStore<A> expressions)
        throws SemanticException {
    Analysis<A, D> analysis = interprocedural.getAnalysis();
    Type staticType = getStaticType();
    Type type = staticType.isReferenceType()
        ? staticType.asReferenceType().getInnerType()
        : staticType;
    ReferenceType reftype = staticType.isReferenceType()
        ? staticType.asReferenceType()
        : new ReferenceType(staticType);

    MemoryAllocation creation = new MemoryAllocation(type, getLocation(), staticallyAllocated);
    HeapReference ref = new HeapReference(reftype, creation, getLocation());

    // we start by allocating the memory region
    AnalysisState<A> allocated = analysis.smallStepSemantics(state, creation, this);

    // we need to add the receiver to the parameters of the constructor call
    InstrumentedReceiverRef paramThis = new InstrumentedReceiverRef(getCFG(), getLocation(), false, reftype);
    Expression[] fullExpressions = ArrayUtils.insert(0, getSubExpressions(), paramThis);

    // we also have to add the receiver inside the state
    AnalysisState<A> callstate = paramThis.forwardSemantics(allocated, interprocedural, expressions);
    ExpressionSet[] fullParams = ArrayUtils.insert(0, params, callstate.getExecutionExpressions());

    // we store a reference to the newly created region in the receiver
    AnalysisState<A> tmp = state.bottomExecution();
    for (SymbolicExpression rec : callstate.getExecutionExpressions())
        tmp = tmp.lub(analysis.assign(callstate, rec, ref, paramThis));
    // we store the approximation of the receiver in the sub-expressions
    expressions.put(paramThis, tmp);

    // constructor call
    UnresolvedCall call = new UnresolvedCall(
        getCFG(),
        getLocation(),
        CallType.INSTANCE,
        type.toString(),
        type.toString(),
        fullExpressions);
    AnalysisState<A> sem = call.forwardSemanticsAux(interprocedural, tmp, fullParams, expressions);

    // now remove the instrumented receiver
    expressions.forget(paramThis);
    for (SymbolicExpression v : callstate.getExecutionExpressions())
        if (v instanceof Identifier)
            // we leave the instrumented receiver in the program variables
            // until it is popped from the stack to keep a reference to the
            // newly created object and its fields
            getMetaVariables().add((Identifier) v);

    // finally, we leave a reference to the newly created object on the
    // stack; this correponds to the state after the constructor call
    // but with the receiver left on the stack
    return sem.withExecutionExpressions(callstate.getExecutionExpressions());
}
```

The object creation is split into several steps:

1. first, a memory region is allocated by feeding a `MemoryAllocation` symbolic
   expression to the analysis;
2. then, the implicit receiver of the constructor call is created
   (`InstrumentedReceiverRef` is an `Expression` modeling the `this` parameter)
   corresponding to the newly allocated object; it is evaluated by invoking its
   `forwardSemantics` method, and the resullt of the evaluation (that is an
   instrumented variable) is assigned to a reference to the newly allocated memory region;
3. the constructor call is executed by constructing a yet-to-be-resolved call
   targeting the constructor of the allocated type and computing its semantics
   by invoking the `forwardSemanticsAux` method;
4. the instrumented variable corresponding to the receiver of the constructor
   call is added to the meta variables, ensuring that it will be removed from
   the state when it is popped from the operand stack;
5. finally, the result of the constructor call is returned as the overall result
   of the semantics, with the receiver left on the stack.

Similarly, other complex memory operations can be defined in terms of the basic
ones. For instance, the semantics of a field access can be defined as a
dereference followed by a traversal, while the semantics of a field assignment
can be defined as a dereference followed by an assignment.

## Modeling errors and exceptions

To get accurate results, it is also important to model the possible errors that
the execution of an instruction might raise. For instance, in an object oriented
language where the receivers of field accesses can be `null`, a null dereference
error is raised whenever a field of a `null` pointer is accessed. Supposing that
the field access is modeled with a `UnaryExpression` containing a reference to
the receiver as a nested instruction and the name of the field to access as
field of the class, the skeleton for its semantics method can look like the
following:

```java
public <A extends AbstractLattice<A>, D extends AbstractDomain<A>> AnalysisState<A> fwdUnarySemantics(
        InterproceduralAnalysis<A, D> interprocedural,
        AnalysisState<A> state,
        SymbolicExpression expr,
        StatementStore<A> expressions)
        throws SemanticException {
    CodeLocation loc = getLocation();
    AnalysisState<A> result = state.bottomExecution();
    Analysis<A, D> analysis = interprocedural.getAnalysis();

    Satisfiability sat = analysis.satisfies(
        state,
        new BinaryExpression(
            new BooleanType(),
            new ComparisonEq(),
            expr,
            new Constant(new NullType(), null, loc),
            loc),
        this);

    if (sat.mightBeTrue()) {
        // construct a state where an error representing a possible
        // null dereference has happened, with the error on the stack
        AnalysisState<A> errorState = ...;

        // assign exception to variable thrower
        CFGThrow throwVar = new CFGThrow(getCFG(), new ErrorType(), getLocation());
        Error error = new Error(npeType.getReference(), this);
        for (SymbolicExpression th : errorState.getExecutionExpressions()) {
            AnalysisState<A> tmp = analysis.assign(errorState, throwVar, th, this);
            AnalysisState<A> err = analysis.moveExecutionToError(tmp.withExecutionExpression(throwVar), error, this));
            result = result.lub(err);
        }
    }

    if (sat == Satisfiability.SATISFIED)
        // the receiver of the access is always null, we can terminate
        // the execution of the semantics here
        return result;

    // rest of the semantics
    AnalysisState<A> access = ...;
    return result.lub(access);
}
```

Before modeling the field access, the analysis is queried for information using
the `satisfies` method, that yields the `Satisfiability` of a Boolean
expression. The expression passed to `satisfies` compares the receiver of the
access with the `null` constant, asking the analysis if they might be equal. If
the answer is possibly `true` (i.e., either `SATISFIED` or `UNKNOWN`), then an
error state has to be taken into account.

The creation of such state is language-specific, and is thus omitted from the
example code. The only assumption is that the error value or a reference to it
are left on the stack (i.e., the computed expressions) of the resulting state.
For instance, in Java it entails creating an `Exception` object with a process
similar to the object creation presented above.

After the error state is created, the expressions left on the stack in the
error state are assigned to a `CFGThrow`, that is, to an `Identifier` that
explicitly stores the error. Then, `moveExecutionToError` is used to introduce
a new error continuation in the analysis state. The continuation is identified
by the `Error` object passed as a parameter, that is a pair consisting of the
error type and the instruction where the error is raised. The `moveExecutionToError`
method introduces the new continuation (this is an optional operation: if the
[`shouldSmashError`]({{ site.baseurl }}/configuration/#hiding-error-and-exceptions)
is set to smash the error type, the continuation is added to the smashed errors)
and sets the state for the normal execution to bottom.

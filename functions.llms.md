# 11  Functions

R has three function types: closures (`CLOSXP`, functions written in R), builtins (`BUILTINSXP`), and specials (`SPECIALSXP`, both implemented in C). They differ in how arguments are evaluated: builtins evaluate their arguments before the call, specials don’t.

## 11.1 Closures

Create closures with `R_mkClosure()` — the old idiom of allocating a `CLOSXP` with `Rf_allocSExp()` and filling it with `SET_FORMALS`/`SET_BODY`/`SET_CLOENV` is no longer part of the API.

### 11.1.1 `R_mkClosure()`

needs protect throws

**Header:** `Rinternals.h`\
**Since:** 4.5.0\
**R equivalent:** `as.function()`

Create a closure from formals, body, and environment.

``` c
SEXP R_mkClosure(SEXP formals, SEXP body, SEXP env);
```

**Returns:** A new `CLOSXP` closure.

The API replacement for the non-API idiom `Rf_allocSExp(CLOSXP)` + `SET_FORMALS`/`SET_BODY`/`SET_CLOENV`. Checks that `formals` is a well-formed pairlist of formal arguments.

**See also:** [`R_ClosureFormals()`](#R_ClosureFormals)

### 11.1.2 `R_ClosureFormals()`, `R_ClosureBody()`, `R_ClosureEnv()`

**Header:** `Rinternals.h`\
**Since:** 4.5.0\
**R equivalent:** `formals()`

Access the formals, body, or environment of a closure.

``` c
SEXP R_ClosureFormals(SEXP x);
SEXP R_ClosureBody(SEXP x);
SEXP R_ClosureEnv(SEXP x);
```

**Returns:** The formals, body, or environment of closure `x`, respectively.

The API replacements for `FORMALS()`, `BODY()`, and `CLOENV()`.

**See also:** [`R_mkClosure()`](#R_mkClosure)

### 11.1.3 `R_ClosureExpr()`, `BODY_EXPR()`

**Header:** `Rinternals.h`

Get the body expression of a closure.

``` c
SEXP R_ClosureExpr(SEXP);
#define BODY_EXPR(e) R_ClosureExpr(e)
```

**Returns:** The unevaluated body expression of the closure.

Returns the unevaluated body, like `body()` at the R level.

**See also:** [`R_ClosureFormals()`](#R_ClosureFormals), [`R_mkClosure()`](#R_mkClosure)

### 11.1.4 `R_BytecodeExpr()`

**Header:** `Rinternals.h`

Get the byte-compiled form of a closure’s body.

``` c
SEXP R_BytecodeExpr(SEXP e);
```

**Returns:** The byte-compiled body as a `BCODESXP`, or `R_NilValue` if the closure is not byte-compiled.

Returns a `BCODESXP` if the closure has been byte-compiled, and `R_NilValue` otherwise.

**See also:** [`R_ClosureExpr()`](#R_ClosureExpr)

## 11.2 Testing functions

### 11.2.1 `Rf_isFunction()`, `Rf_isPrimitive()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.function()`

Test whether an object is a function or a primitive function.

``` c
Rboolean Rf_isFunction(SEXP);
Rboolean Rf_isPrimitive(SEXP);
```

**Returns:** `TRUE` if the object is a function (respectively a primitive function), otherwise `FALSE`.

`FUNSXP` is an abstract union type.

## 11.3 Promises (`PROMSXP`)

A promise bundles an unevaluated expression with the environment it should be evaluated in; it’s how R implements lazy evaluation of function arguments.

### 11.3.1 `R_UnboundValue()`

**Header:** `Rinternals.h`

Access the unbound-value marker constant.

``` c
LibExtern SEXP  R_UnboundValue;     /* Unbound marker */
```

`R_UnboundValue` marks an unbound symbol or an unread promise value.

**See also:** [`R_MissingArg()`](#R_MissingArg)

## 11.4 Srcrefs

### 11.4.1 `R_Srcref()`

**Header:** `Rinternals.h`

Access the current srcref, for debuggers.

``` c
LibExtern SEXP  R_Srcref;           /* Current srcref, for debuggers */
```

### 11.4.2 `R_GetCurrentSrcref()`, `R_GetSrcFilename()`

needs protect

**Header:** `Rinternals.h`

Get the current srcref or the source filename of a srcref.

``` c
SEXP R_GetCurrentSrcref(int);
SEXP R_GetSrcFilename(SEXP);
```

**Returns:** `R_GetCurrentSrcref()` returns the current srcref, or `R_NilValue` if none; `R_GetSrcFilename()` returns the filename stored in a srcref.

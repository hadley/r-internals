# 8  Environments

An environment (`ENVSXP`) is a set of bindings from symbols to values, plus a pointer to a parent (enclosing) environment. Lookup walks the parent chain until it finds a binding or reaches the empty environment. Small environments store bindings as a pairlist (the frame); larger ones use a hash table. In R’s own source, environments are conventionally named `rho`.

## 8.1 Predefined environments

### 8.1.1 `R_GlobalEnv()`

Access the global environment.

``` c
SEXP R_GlobalEnv;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

The “global” environment.

### 8.1.2 `R_EmptyEnv()`

Access the empty environment.

``` c
SEXP R_EmptyEnv;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

An empty environment at the root of the environment tree.

### 8.1.3 `R_BaseEnv()`

Access the base environment.

``` c
SEXP R_BaseEnv;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

The base environment; formerly `R_NilValue`.

### 8.1.4 `R_BaseNamespace()`

Access the base namespace.

``` c
SEXP R_BaseNamespace;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

The (fake) namespace for base.

## 8.2 Creation

### 8.2.1 `R_NewEnv()`

Create a new environment.

``` c
SEXP R_NewEnv(SEXP enclos, int hash, int size);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

## 8.3 Get and set objects in environment

In these functions, `symbol` should be a `SYMSXP` and `environment` an `ENVSXP`.

### 8.3.1 Get values

Retrieving a variable from an environment can allocate, because the binding might be an active binding or a promise that needs forcing.

### 8.3.2 `Rf_findFun()`

Find the function bound to a symbol in an environment and its enclosing environments.

``` c
SEXP Rf_findFun(SEXP symbol, SEXP environment);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

Like `Rf_findVar()`, but ignores non-functions.

**See also:** [`Rf_findVar()`](#Rf_findVar)

### 8.3.3 `R_getVar()` (`R_getVarEx()`)

Get the value of a variable from an environment.

``` c
SEXP R_getVar(SEXP sym, SEXP env, Rboolean inherits);
SEXP R_getVarEx(SEXP sym, SEXP env, Rboolean inherits, SEXP ifnotfound);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** can throw · **Since:** 4.5.0 · **R equivalent:** `get()`

- `inherits`: search enclosing frames, as `inherits = TRUE` in `get()`.
- `ifnotfound`: `R_getVarEx` only: value returned when the variable is not found, as in `get0()`.

The API replacement for the non-API `Rf_findVar()`/ `Rf_findVarInFrame()`. `R_getVar()` errors when the variable is not found. Active bindings are triggered and delayed bindings are forced.

**See also:** [`R_GetBindingType()`](#R_GetBindingType)

### 8.3.4 `R_ParentEnv()`

Get the enclosing environment of an environment.

``` c
SEXP R_ParentEnv(SEXP env);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** can throw · **Since:** 4.5.0 · **R equivalent:** `parent.env()`

The API replacement for `ENCLOS()`; errors on the empty environment.

### 8.3.5 Set values

To remove a binding, set its value to `R_UnboundValue`.

### 8.3.6 `Rf_defineVar()`

Bind a symbol to a value in an environment.

``` c
void Rf_defineVar(SEXP symbol, SEXP value, SEXP env);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

To remove a binding, set its value to `R_UnboundSymbol`.

### 8.3.7 `Rf_setVar()` (`Rf_gsetVar()`)

Assign a value to a symbol in an environment.

``` c
void Rf_setVar(SEXP, SEXP, SEXP);
void Rf_gsetVar(SEXP, SEXP, SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** `assign()`

### 8.3.8 Check for presence

### 8.3.9 `R_lsInternal3()`

List the names bound in an environment.

``` c
SEXP R_lsInternal3(SEXP env, Rboolean all_names, Rboolean sorted);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

Returns a character vector. The older `R_lsInternal(env, all)` was removed from the headers in R 4.6.0.

## 8.4 Miscellaneous

### 8.4.1 `Rf_isEnvironment()`

Test whether an object is an environment.

``` c
Rboolean Rf_isEnvironment(SEXP x);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

Equivalent to `TYPEOF(x) == ENVSXP`.

### 8.4.2 `R_IsPackageEnv()` (`R_PackageEnvName()`, `R_FindPackageEnv()`)

Test whether an environment is a package environment, get its name, or find a package’s environment.

``` c
Rboolean R_IsPackageEnv(SEXP rho);
SEXP R_PackageEnvName(SEXP rho);
SEXP R_FindPackageEnv(SEXP info);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

**See also:** [`R_IsNamespaceEnv()`](#R_IsNamespaceEnv)

### 8.4.3 `R_IsNamespaceEnv()` (`R_NamespaceEnvSpec()`, `R_FindNamespace()`)

Test whether an environment is a namespace environment, get its spec, or find a namespace.

``` c
Rboolean R_IsNamespaceEnv(SEXP rho);
SEXP R_NamespaceEnvSpec(SEXP rho);
SEXP R_FindNamespace(SEXP info);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

**See also:** [`R_IsPackageEnv()`](#R_IsPackageEnv)

### 8.4.4 `R_LockEnvironment()` (`R_EnvironmentIsLocked()`)

Lock an environment, or test whether it is locked.

``` c
void R_LockEnvironment(SEXP env, Rboolean bindings);
Rboolean R_EnvironmentIsLocked(SEXP env);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

**See also:** [`R_LockBinding()`](#R_LockBinding)

### 8.4.5 `R_LockBinding()` (`R_unLockBinding()`)

Lock or unlock a binding in an environment.

``` c
void R_LockBinding(SEXP sym, SEXP env);
void R_unLockBinding(SEXP sym, SEXP env);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

**See also:** [`R_LockEnvironment()`](#R_LockEnvironment)

### 8.4.6 `R_MakeActiveBinding()`

Make an active binding for a symbol in an environment.

``` c
void R_MakeActiveBinding(SEXP sym, SEXP fun, SEXP env);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

**See also:** [`R_BindingIsLocked()`](#R_BindingIsLocked)

### 8.4.7 `R_BindingIsLocked()` (`R_BindingIsActive()`)

Test whether a binding is locked or active.

``` c
Rboolean R_BindingIsLocked(SEXP sym, SEXP env);
Rboolean R_BindingIsActive(SEXP sym, SEXP env);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

**See also:** [`R_MakeActiveBinding()`](#R_MakeActiveBinding)

### 8.4.8 `R_HasFancyBindings()`

Test whether an environment has fancy bindings.

``` c
Rboolean R_HasFancyBindings(SEXP rho);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

### 8.4.9 `Rf_topenv()`

Find the top-level environment in an environment chain.

``` c
SEXP Rf_topenv(SEXP, SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `topenv()`

- `x`: the environment to start from.
- `target`: stop when this environment is reached, usually `R_NilValue`.

**See also:** [`R_ParentEnv()`](#R_ParentEnv)

### 8.4.10 `R_GetCurrentEnv()`

Retrieve the environment of the currently executing closure.

``` c
SEXP R_GetCurrentEnv(void);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** `environment()`

Only meaningful while R is evaluating a call. Usually better to pass the environment explicitly as an argument to your C function.

## 8.5 Inspecting bindings

R 4.6.0 added an **experimental** API for examining bindings in detail — whether a binding is delayed (a promise), forced, missing, or active — and for working with `...` without evaluating it. Both interface and semantics may change in future R releases. Note that the `R_Dots*` and `R_Dot*` accessors look up `...` only in the frame you pass; call `R_findDotsEnv()` first if you want R’s usual inherited lookup.

### 8.5.1 `R_GetBindingType()`

Query the type of a symbol’s binding in an environment.

``` c
R_BindingType_t R_GetBindingType(SEXP sym, SEXP env);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** 4.6.0 · **R equivalent:** —

Returns one of `R_BindingTypeUnbound`, `R_BindingTypeValue`, `R_BindingTypeMissing`, `R_BindingTypeDelayed`, `R_BindingTypeForced`, or `R_BindingTypeActive`. Part of the experimental binding API added in R 4.6.0; the interface may change.

**See also:** [`R_getVar()`](#R_getVar)

### 8.5.2 `R_DelayedBindingExpression()` (`R_DelayedBindingEnvironment()`, `R_ForcedBindingExpression()`)

Inspect the expression or environment behind a delayed or forced binding.

``` c
SEXP R_DelayedBindingExpression(SEXP sym, SEXP env);
SEXP R_DelayedBindingEnvironment(SEXP sym, SEXP env);
SEXP R_ForcedBindingExpression(SEXP sym, SEXP env);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** 4.6.0 · **R equivalent:** —

Use `R_GetBindingType()` first to check the binding type.

**See also:** [`R_GetBindingType()`](#R_GetBindingType), [`R_MakeDelayedBinding()`](#R_MakeDelayedBinding)

### 8.5.3 `R_MakeDelayedBinding()` (`R_MakeForcedBinding()`, `R_MakeMissingBinding()`)

Create a delayed, forced, or missing binding in an environment.

``` c
void R_MakeDelayedBinding(SEXP sym, SEXP expr, SEXP evalEnv, SEXP env);
void R_MakeForcedBinding(SEXP sym, SEXP expr, SEXP value, SEXP env);
void R_MakeMissingBinding(SEXP sym, SEXP env);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** 4.6.0 · **R equivalent:** —

- `expr`: the expression associated with the binding.
- `evalEnv`: environment in which a delayed binding’s expression is evaluated.

A delayed binding is a promise; a forced binding pairs an expression with its already-computed value; a missing binding is one whose argument was not supplied.

**See also:** [`R_GetBindingType()`](#R_GetBindingType)

### 8.5.4 `R_envSymbols()`

List the symbols bound in an environment.

``` c
SEXP R_envSymbols(SEXP env);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** 4.6.0 · **R equivalent:** `ls()`

### 8.5.5 `R_findDotsEnv()` (`R_DotsExist()`)

Find the nearest enclosing frame containing a `...` binding.

``` c
SEXP R_findDotsEnv(SEXP env);
Rboolean R_DotsExist(SEXP env);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** 4.6.0 · **R equivalent:** —

`R_findDotsEnv()` walks parent environments and returns the first containing a proper `...` binding, or `R_EmptyEnv`. The `R_Dots*`/`R_Dot*` accessors look up `...` only in the given frame, so call this first if you need R’s inherited lookup.

**See also:** [`R_DotsLength()`](#R_DotsLength), [`R_DotsElt()`](#R_DotsElt)

### 8.5.6 `R_DotsLength()` (`R_DotsNames()`)

Get the length or names of the `...` binding in a frame.

``` c
int R_DotsLength(SEXP env);
SEXP R_DotsNames(SEXP env);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** never · **Since:** 4.6.0 · **R equivalent:** `...length()`

**See also:** [`R_findDotsEnv()`](#R_findDotsEnv)

### 8.5.7 `R_GetDotType()`

Query the type of an individual `...` element.

``` c
R_DotType_t R_GetDotType(int i, SEXP env);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** 4.6.0 · **R equivalent:** —

Returns one of `R_DotTypeValue`, `R_DotTypeMissing`, `R_DotTypeDelayed`, or `R_DotTypeForced`.

**See also:** [`R_DotsElt()`](#R_DotsElt)

### 8.5.8 `R_DotsElt()` (`R_DotForcedExpression()`, `R_DotDelayedExpression()`, `R_DotDelayedEnvironment()`)

Access an individual `...` element or its underlying expression.

``` c
SEXP R_DotsElt(int i, SEXP env);
SEXP R_DotForcedExpression(int i, SEXP env);
SEXP R_DotDelayedExpression(int i, SEXP env);
SEXP R_DotDelayedEnvironment(int i, SEXP env);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** 4.6.0 · **R equivalent:** `...elt()`

- `i`: zero-based index into the `...` binding.

`R_DotsElt()` forces the element, like `...elt()`; the `R_Dot*` variants inspect a delayed or forced element without forcing — check with `R_GetDotType()` first.

**See also:** [`R_findDotsEnv()`](#R_findDotsEnv), [`R_GetDotType()`](#R_GetDotType)

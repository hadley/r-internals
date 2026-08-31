# 8  Environments

An environment (`ENVSXP`) is a set of bindings from symbols to values, plus a pointer to a parent (enclosing) environment. Lookup walks the parent chain until it finds a binding or reaches the empty environment. Small environments store bindings as a pairlist (the frame); larger ones use a hash table. In R’s own source, environments are conventionally named `rho`.

## 8.1 Predefined environments

### 8.1.1 `R_GlobalEnv()`

**Header:** `Rinternals.h`

Access the global environment.

``` c
SEXP R_GlobalEnv;
```

The “global” environment.

### 8.1.2 `R_EmptyEnv()`

**Header:** `Rinternals.h`

Access the empty environment.

``` c
SEXP R_EmptyEnv;
```

An empty environment at the root of the environment tree.

### 8.1.3 `R_BaseEnv()`

**Header:** `Rinternals.h`

Access the base environment.

``` c
SEXP R_BaseEnv;
```

The base environment; formerly `R_NilValue`.

### 8.1.4 `R_BaseNamespace()`

**Header:** `Rinternals.h`

Access the base namespace.

``` c
SEXP R_BaseNamespace;
```

The (fake) namespace for base.

## 8.2 Creation

### 8.2.1 `R_NewEnv()`

needs protect throws

**Header:** `Rinternals.h`

Create a new environment.

``` c
SEXP R_NewEnv(SEXP enclos, int hash, int size);
```

**Returns:** The newly allocated environment, with enclosure `enclos`.

## 8.3 Get and set objects in environment

In these functions, `symbol` should be a `SYMSXP` and `environment` an `ENVSXP`.

### 8.3.1 Get values

Retrieving a variable from an environment can allocate, because the binding might be an active binding or a promise that needs forcing.

### 8.3.2 `Rf_findFun()`

needs protect throws

**Header:** `Rinternals.h`

Find the function bound to a symbol in an environment and its enclosing environments.

``` c
SEXP Rf_findFun(SEXP symbol, SEXP environment);
```

**Returns:** The function bound to `symbol` in `environment` or an enclosing frame.

Like `Rf_findVar()`, but ignores non-functions.

**See also:** [`Rf_findVar()`](#Rf_findVar)

### 8.3.3 `R_getVar()`, `R_getVarEx()`

throws

**Header:** `Rinternals.h`\
**Since:** 4.5.0\
**R equivalent:** `get()`

Get the value of a variable from an environment.

``` c
SEXP R_getVar(SEXP sym, SEXP env, Rboolean inherits);
SEXP R_getVarEx(SEXP sym, SEXP env, Rboolean inherits, SEXP ifnotfound);
```

- `inherits`: search enclosing frames, as `inherits = TRUE` in `get()`.
- `ifnotfound`: `R_getVarEx` only: value returned when the variable is not found, as in `get0()`.

**Returns:** The value of `sym` in `env`, searching enclosing frames if `inherits` is `TRUE` (not freshly allocated); `R_getVarEx()` returns `ifnotfound` when not found, while `R_getVar()` errors.

The API replacement for the non-API `Rf_findVar()`/ `Rf_findVarInFrame()`. `R_getVar()` errors when the variable is not found. Active bindings are triggered and delayed bindings are forced.

**See also:** [`R_GetBindingType()`](#R_GetBindingType)

### 8.3.4 `R_ParentEnv()`

throws

**Header:** `Rinternals.h`\
**Since:** 4.5.0\
**R equivalent:** `parent.env()`

Get the enclosing environment of an environment.

``` c
SEXP R_ParentEnv(SEXP env);
```

**Returns:** The enclosing (parent) environment of `env`; errors on the empty environment.

The API replacement for `ENCLOS()`; errors on the empty environment.

### 8.3.5 Set values

To remove a binding, set its value to `R_UnboundValue`.

### 8.3.6 `Rf_defineVar()`

throws

**Header:** `Rinternals.h`

Bind a symbol to a value in an environment.

``` c
void Rf_defineVar(SEXP symbol, SEXP value, SEXP env);
```

To remove a binding, set its value to `R_UnboundSymbol`.

### 8.3.7 `Rf_setVar()`, `Rf_gsetVar()`

throws

**Header:** `Rinternals.h`\
**R equivalent:** `assign()`

Assign a value to a symbol in an environment.

``` c
void Rf_setVar(SEXP, SEXP, SEXP);
void Rf_gsetVar(SEXP, SEXP, SEXP);
```

### 8.3.8 Check for presence

### 8.3.9 `R_lsInternal3()`

experimental needs protect throws

**Header:** `Rinternals.h`

List the names bound in an environment.

``` c
SEXP R_lsInternal3(SEXP env, Rboolean all_names, Rboolean sorted);
```

**Returns:** A freshly allocated character vector of the names bound in `env`.

Returns a character vector. The older `R_lsInternal(env, all)` was removed from the headers in R 4.6.0.

## 8.4 Miscellaneous

### 8.4.1 `Rf_isEnvironment()`

**Header:** `Rinternals.h`

Test whether an object is an environment.

``` c
Rboolean Rf_isEnvironment(SEXP x);
```

**Returns:** `TRUE` if `x` is an environment (`ENVSXP`), otherwise `FALSE`.

Equivalent to `TYPEOF(x) == ENVSXP`.

### 8.4.2 `R_IsPackageEnv()`, `R_PackageEnvName()`, `R_FindPackageEnv()`

experimental needs protect throws

**Header:** `Rinternals.h`

Test whether an environment is a package environment, get its name, or find a package’s environment.

``` c
Rboolean R_IsPackageEnv(SEXP rho);
SEXP R_PackageEnvName(SEXP rho);
SEXP R_FindPackageEnv(SEXP info);
```

**Returns:** `R_IsPackageEnv()` returns `TRUE` if `rho` is a package environment, otherwise `FALSE`; `R_PackageEnvName()` returns its name as a string, or `R_NilValue` if not a package environment; `R_FindPackageEnv()` returns the environment of the named package.

**See also:** [`R_IsNamespaceEnv()`](#R_IsNamespaceEnv)

### 8.4.3 `R_IsNamespaceEnv()`, `R_NamespaceEnvSpec()`, `R_FindNamespace()`

experimental needs protect throws

**Header:** `Rinternals.h`

Test whether an environment is a namespace environment, get its spec, or find a namespace.

``` c
Rboolean R_IsNamespaceEnv(SEXP rho);
SEXP R_NamespaceEnvSpec(SEXP rho);
SEXP R_FindNamespace(SEXP info);
```

**Returns:** `R_IsNamespaceEnv()` returns `TRUE` if `rho` is a namespace, otherwise `FALSE`; `R_NamespaceEnvSpec()` returns its spec string, or `R_NilValue` if not a namespace; `R_FindNamespace()` returns the named namespace environment.

**See also:** [`R_IsPackageEnv()`](#R_IsPackageEnv)

### 8.4.4 `R_LockEnvironment()`, `R_EnvironmentIsLocked()`

experimental throws

**Header:** `Rinternals.h`

Lock an environment, or test whether it is locked.

``` c
void R_LockEnvironment(SEXP env, Rboolean bindings);
Rboolean R_EnvironmentIsLocked(SEXP env);
```

**Returns:** `R_EnvironmentIsLocked()` returns `TRUE` if `env` is locked, otherwise `FALSE`.

**See also:** [`R_LockBinding()`](#R_LockBinding)

### 8.4.5 `R_LockBinding()`, `R_unLockBinding()`

experimental throws

**Header:** `Rinternals.h`

Lock or unlock a binding in an environment.

``` c
void R_LockBinding(SEXP sym, SEXP env);
void R_unLockBinding(SEXP sym, SEXP env);
```

**See also:** [`R_LockEnvironment()`](#R_LockEnvironment)

### 8.4.6 `R_MakeActiveBinding()`

experimental throws

**Header:** `Rinternals.h`

Make an active binding for a symbol in an environment.

``` c
void R_MakeActiveBinding(SEXP sym, SEXP fun, SEXP env);
```

**See also:** [`R_BindingIsLocked()`](#R_BindingIsLocked)

### 8.4.7 `R_BindingIsLocked()`, `R_BindingIsActive()`

experimental throws

**Header:** `Rinternals.h`

Test whether a binding is locked or active.

``` c
Rboolean R_BindingIsLocked(SEXP sym, SEXP env);
Rboolean R_BindingIsActive(SEXP sym, SEXP env);
```

**Returns:** `TRUE` if the binding of `sym` in `env` is locked (`R_BindingIsLocked()`) or active (`R_BindingIsActive()`), otherwise `FALSE`.

**See also:** [`R_MakeActiveBinding()`](#R_MakeActiveBinding)

### 8.4.8 `R_HasFancyBindings()`

**Header:** `Rinternals.h`

Test whether an environment has fancy bindings.

``` c
Rboolean R_HasFancyBindings(SEXP rho);
```

**Returns:** `TRUE` if `rho` has any active or delayed bindings, otherwise `FALSE`.

### 8.4.9 `Rf_topenv()`

**Header:** `Rinternals.h`\
**R equivalent:** `topenv()`

Find the top-level environment in an environment chain.

``` c
SEXP Rf_topenv(SEXP, SEXP);
```

- `x`: the environment to start from.
- `target`: stop when this environment is reached, usually `R_NilValue`.

**Returns:** The top-level environment in the chain containing `x`, stopping at `target`.

**See also:** [`R_ParentEnv()`](#R_ParentEnv)

### 8.4.10 `R_GetCurrentEnv()`

experimental

**Header:** `Rinternals.h`\
**R equivalent:** `environment()`

Retrieve the environment of the currently executing closure.

``` c
SEXP R_GetCurrentEnv(void);
```

**Returns:** The environment of the closure currently being evaluated; only meaningful while R is evaluating a call.

Only meaningful while R is evaluating a call. Usually better to pass the environment explicitly as an argument to your C function.

## 8.5 Inspecting bindings

R 4.6.0 added an **experimental** API for examining bindings in detail — whether a binding is delayed (a promise), forced, missing, or active — and for working with `...` without evaluating it. Both interface and semantics may change in future R releases. Note that the `R_Dots*` and `R_Dot*` accessors look up `...` only in the frame you pass; call `R_findDotsEnv()` first if you want R’s usual inherited lookup.

### 8.5.1 `R_GetBindingType()`

experimental

**Header:** `Rinternals.h`\
**Since:** 4.6.0

Query the type of a symbol’s binding in an environment.

``` c
R_BindingType_t R_GetBindingType(SEXP sym, SEXP env);
```

**Returns:** The binding type of `sym` in `env`: one of `R_BindingTypeUnbound`, `R_BindingTypeValue`, `R_BindingTypeMissing`, `R_BindingTypeDelayed`, `R_BindingTypeForced`, or `R_BindingTypeActive`.

Returns one of `R_BindingTypeUnbound`, `R_BindingTypeValue`, `R_BindingTypeMissing`, `R_BindingTypeDelayed`, `R_BindingTypeForced`, or `R_BindingTypeActive`. Part of the experimental binding API added in R 4.6.0; the interface may change.

**See also:** [`R_getVar()`](#R_getVar)

### 8.5.2 `R_DelayedBindingExpression()`, `R_DelayedBindingEnvironment()`, `R_ForcedBindingExpression()`

experimental

**Header:** `Rinternals.h`\
**Since:** 4.6.0

Inspect the expression or environment behind a delayed or forced binding.

``` c
SEXP R_DelayedBindingExpression(SEXP sym, SEXP env);
SEXP R_DelayedBindingEnvironment(SEXP sym, SEXP env);
SEXP R_ForcedBindingExpression(SEXP sym, SEXP env);
```

**Returns:** `R_DelayedBindingExpression()` returns the delayed expression, `R_DelayedBindingEnvironment()` the environment it will be evaluated in, and `R_ForcedBindingExpression()` the expression behind a forced binding.

Use `R_GetBindingType()` first to check the binding type.

**See also:** [`R_GetBindingType()`](#R_GetBindingType), [`R_MakeDelayedBinding()`](#R_MakeDelayedBinding)

### 8.5.3 `R_MakeDelayedBinding()`, `R_MakeForcedBinding()`, `R_MakeMissingBinding()`

experimental throws

**Header:** `Rinternals.h`\
**Since:** 4.6.0

Create a delayed, forced, or missing binding in an environment.

``` c
void R_MakeDelayedBinding(SEXP sym, SEXP expr, SEXP evalEnv, SEXP env);
void R_MakeForcedBinding(SEXP sym, SEXP expr, SEXP value, SEXP env);
void R_MakeMissingBinding(SEXP sym, SEXP env);
```

- `expr`: the expression associated with the binding.
- `evalEnv`: environment in which a delayed binding’s expression is evaluated.

A delayed binding is a promise; a forced binding pairs an expression with its already-computed value; a missing binding is one whose argument was not supplied.

**See also:** [`R_GetBindingType()`](#R_GetBindingType)

### 8.5.4 `R_envSymbols()`

experimental needs protect throws

**Header:** `Rinternals.h`\
**Since:** 4.6.0\
**R equivalent:** `ls()`

List the symbols bound in an environment.

``` c
SEXP R_envSymbols(SEXP env);
```

**Returns:** A freshly allocated list of the symbols bound in `env`.

### 8.5.5 `R_findDotsEnv()`, `R_DotsExist()`

experimental

**Header:** `Rinternals.h`\
**Since:** 4.6.0

Find the nearest enclosing frame containing a `...` binding.

``` c
SEXP R_findDotsEnv(SEXP env);
Rboolean R_DotsExist(SEXP env);
```

**Returns:** `R_findDotsEnv()` returns the nearest enclosing frame containing a `...` binding, or `R_EmptyEnv` if none; `R_DotsExist()` returns `TRUE` if `env` contains a `...` binding, otherwise `FALSE`.

`R_findDotsEnv()` walks parent environments and returns the first containing a proper `...` binding, or `R_EmptyEnv`. The `R_Dots*`/`R_Dot*` accessors look up `...` only in the given frame, so call this first if you need R’s inherited lookup.

**See also:** [`R_DotsLength()`](#R_DotsLength), [`R_DotsElt()`](#R_DotsElt)

### 8.5.6 `R_DotsLength()`, `R_DotsNames()`

experimental needs protect

**Header:** `Rinternals.h`\
**Since:** 4.6.0\
**R equivalent:** `...length()`

Get the length or names of the `...` binding in a frame.

``` c
int R_DotsLength(SEXP env);
SEXP R_DotsNames(SEXP env);
```

**Returns:** `R_DotsLength()` returns the number of elements in the `...` binding of `env`; `R_DotsNames()` returns their names as a character vector.

**See also:** [`R_findDotsEnv()`](#R_findDotsEnv)

### 8.5.7 `R_GetDotType()`

experimental

**Header:** `Rinternals.h`\
**Since:** 4.6.0

Query the type of an individual `...` element.

``` c
R_DotType_t R_GetDotType(int i, SEXP env);
```

**Returns:** The type of `...` element `i`: one of `R_DotTypeValue`, `R_DotTypeMissing`, `R_DotTypeDelayed`, or `R_DotTypeForced`.

Returns one of `R_DotTypeValue`, `R_DotTypeMissing`, `R_DotTypeDelayed`, or `R_DotTypeForced`.

**See also:** [`R_DotsElt()`](#R_DotsElt)

### 8.5.8 `R_DotsElt()`, `R_DotForcedExpression()`, `R_DotDelayedExpression()`, `R_DotDelayedEnvironment()`

experimental needs protect throws

**Header:** `Rinternals.h`\
**Since:** 4.6.0\
**R equivalent:** `...elt()`

Access an individual `...` element or its underlying expression.

``` c
SEXP R_DotsElt(int i, SEXP env);
SEXP R_DotForcedExpression(int i, SEXP env);
SEXP R_DotDelayedExpression(int i, SEXP env);
SEXP R_DotDelayedEnvironment(int i, SEXP env);
```

- `i`: zero-based index into the `...` binding.

**Returns:** `R_DotsElt()` returns the (forced) value of `...` element `i`; the `R_Dot*` variants return the underlying expression or evaluation environment without forcing it.

`R_DotsElt()` forces the element, like `...elt()`; the `R_Dot*` variants inspect a delayed or forced element without forcing — check with `R_GetDotType()` first.

**See also:** [`R_findDotsEnv()`](#R_findDotsEnv), [`R_GetDotType()`](#R_GetDotType)

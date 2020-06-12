# Environments (`ENVSXP`)

```cpp
Rboolean Rf_isEnvironment(SEXP x); // (TYPEOF(x) == ENVSXP)
```

* `R_GlobalEnv`: The "global" environment
* `R_EmptyEnv`: An empty environment at the root of the environment tree
* `R_BaseEnv`: The base environment; formerly R_NilValue
* `R_BaseNamespace`: The (fake) namespace for base
* `R_NamespaceRegistry`: Registry for registered namespaces
* `R_GetCurrentEnv`: Retrieve the current environment `R (>= 3.6.0)`

Environments are commonly called `rho` in the sources.

## Get and set objects in environment

`symbol` should be a `SYMSXP`; `environment` should be an `ENVSXP`.

### Get values

Note that retrieving an variable from an environment may cause an allocation because it might be an active binding.

```cpp
// Look up symbol in environment, following up enclosing envs
SEXP Rf_findVar(SEXP symbol, SEXP environment);

// Look up symbol in environment, ignoring non-functions
SEXP Rf_findFun(SEXP symbol, SEXP environment);

// Look in single environment
// Returns R_UnboundValue if not found
// doGet: if TRUE, returns value; if FALSE just checks for presence
SEXP Rf_findVarInFrame3(SEXP env, SEXP symbol, Rboolean doGet);

// Shortcut from findVarInFrame3(rho, symbol, TRUE)
SEXP Rf_findVarInFrame(SEXP env, SEXP symbol);
```

### Set values

```cpp
// Define value
void Rf_defineVar(SEXP symbol, SEXP value, SEXP env);

// Copy variables from (VECSXP) unless already present in to
void Rf_addMissingVarsToNewEnv(SEXP to, SEXP from);
```

To remove a binding, set its value to `R_UnboundSymbol`.

### Check for presence

```cpp
// Returns character vector
SEXP R_lsInternal3(SEXP env, Rboolean all_names, Rboolean sorted);

// Shorthand for R_lsInternal3(env, all, TRUE)
SEXP R_lsInternal(SEXP, Rboolean);
```

## Miscellaneous

```cpp
Rboolean R_IsPackageEnv(SEXP rho);
SEXP R_PackageEnvName(SEXP rho);
SEXP R_FindPackageEnv(SEXP info);
Rboolean R_IsNamespaceEnv(SEXP rho);
SEXP R_NamespaceEnvSpec(SEXP rho);
SEXP R_FindNamespace(SEXP info);
void R_LockEnvironment(SEXP env, Rboolean bindings);
Rboolean R_EnvironmentIsLocked(SEXP env);
void R_LockBinding(SEXP sym, SEXP env);
void R_unLockBinding(SEXP sym, SEXP env);
void R_MakeActiveBinding(SEXP sym, SEXP fun, SEXP env);
Rboolean R_BindingIsLocked(SEXP sym, SEXP env);
Rboolean R_BindingIsActive(SEXP sym, SEXP env);
Rboolean R_HasFancyBindings(SEXP rho);
Rboolean R_envHasNoSpecialSymbols(SEXP);
```

## Internals

```cpp
SEXP FRAME(SEXP x);
void SET_FRAME(SEXP x, SEXP v);

SEXP ENCLOS(SEXP x);
void SET_ENCLOS(SEXP x, SEXP v);

int  ENVFLAGS(SEXP x);
void SET_ENVFLAGS(SEXP x, int v);
```

### Truelength

> This is almost unused. The only current use is for hash tables of 
> environments (VECSXPs), where length is the size of the table and 
> truelength is the number of primary slots in use, and for the reference 
> hash tables in serialization (VECSXPs), where truelength is the number of 
> slots in use.
> --- R-internals

```cpp
int  (TRUELENGTH)(SEXP x);
R_xlen_t  (XTRUELENGTH)(SEXP x);
void (SET_TRUELENGTH)(SEXP x, int v);
```

### Hash

```cpp
SEXP HASHTAB(SEXP x);
void SET_HASHTAB(SEXP x, SEXP v);

int  HASHASH(SEXP x);
void SET_HASHASH(SEXP x, int v);

int  HASHVALUE(SEXP x);
void SET_HASHVALUE(SEXP x, int v);
```

// [R-Internals]: Hashing is principally designed for fast searching of
// environments, which  are from time to time added to but rarely deleted from,
// so items are not actually deleted but have their value set to R_UnboundValue.


Code from lobstr should help me understand how they work:

```cpp
int FrameSize(SEXP frame) {
  int count = 0;

  for(SEXP cur = frame; cur != R_NilValue; cur = CDR(cur)) {
    SEXP obj = CAR(cur)
    if (obj != R_UnboundValue)
      count++;
  }
  return count;
}

int HashTableSize(SEXP table) {
  int count = 0;
  int n = Rf_length(table);
  for (int i = 0; i < n; ++i)
    count += FrameSize(VECTOR_ELT(table, i));
  return count;
}

int envlength(SEXP x) {
  bool isHashed = HASHTAB(x) != R_NilValue;
  return isHashed ? HashTableSize(HASHTAB(x)) : FrameSize(FRAME(x));
}
```

# 1  Calling C from R

R packages call C code through `.Call()`. On the R side you pass R objects; on the C side you receive and return `SEXP`s. This chapter covers the mechanics: writing the C function, registering it, and the contract you sign up to.

## 1.1 .Call

A `.Call`-able C function takes some number of `SEXP` arguments and returns a `SEXP`:

``` c
#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

SEXP add_one(SEXP x) {
  if (TYPEOF(x) != REALSXP) {
    Rf_error("x must be a numeric vector");
  }
  R_xlen_t n = Rf_xlength(x);
  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  for (R_xlen_t i = 0; i < n; i++) {
    REAL(out)[i] = REAL(x)[i] + 1;
  }
  UNPROTECT(1);
  return out;
}
```

Call it from R with `.Call()`, passing the registered native symbol (see below) followed by the arguments:

``` r
add_one <- function(x) .Call(C_add_one, x)
```

`.External` is a variant in which the C function receives a single `SEXP` holding an unevaluated argument list (a pairlist) that it walks itself. It exists to support variable-argument and call-level tricks; new code almost never needs it.

## 1.2 Routine registration

Every native routine a package calls should be registered. Registration gives you speed (R skips symbol lookup), safety (R checks the argument count), and lets you hide all other symbols from the dynamic library. Create `src/init.c`:

``` c
#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

SEXP add_one(SEXP x);

static const R_CallMethodDef callMethods[] = {
  {"add_one", (DL_FUNC) &add_one, 1},
  {NULL, NULL, 0}
};

void R_init_mypkg(DllInfo *dll) {
  R_registerRoutines(dll, NULL, callMethods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
```

`R_useDynamicSymbols(dll, FALSE)` means only registered routines are visible, so `.Call("add_one", ...)` by string fails and you must use the symbol object. Generate the R-side registration with `tools::package_native_routine_registration_skeleton("src")`, then put `useDynLib(mypkg, .registration = TRUE)` in `NAMESPACE`, which makes the symbol object `C_add_one` available to your R code.

### 1.2.1 `R_registerRoutines()`, `R_useDynamicSymbols()`

**Header:** `R_ext/Rdynload.h`

Register a package’s native routines and restrict dynamic symbol lookup.

``` c
int R_registerRoutines(DllInfo *info, const R_CMethodDef * const croutines,
                       const R_CallMethodDef * const callRoutines,
                       const R_FortranMethodDef * const fortranRoutines,
                       const R_ExternalMethodDef * const externalRoutines);
Rboolean R_useDynamicSymbols(DllInfo *info, Rboolean value);
```

- `info`: passed to your `R_init_<pkgname>()` initializer.
- `callRoutines`: NULL-terminated array of `R_CallMethodDef` entries: name, function pointer cast to `DL_FUNC`, argument count.
- `value`: `FALSE` hides unregistered symbols, so routines can only be reached via registration.

**Returns:** `R_registerRoutines()` returns the number of routines registered; `R_useDynamicSymbols()` returns the previous setting.

Call from `R_init_<pkgname>()`. Generate the registration boilerplate with `tools::package_native_routine_registration_skeleton("src")`.

### 1.2.2 `R_RegisterCCallable()`, `R_GetCCallable()`

throws

**Header:** `R_ext/Rdynload.h`

Export or retrieve a C entry point for use by another package.

``` c
void R_RegisterCCallable(const char *package, const char *name, DL_FUNC fptr);
DL_FUNC R_GetCCallable(const char *package, const char *name);
```

**Returns:** `R_GetCCallable()` returns the registered function pointer, raising an error if not found.

Register in `R_init_<package>()`; clients retrieve the pointer at their own load time and call it directly, with no R-level dispatch. The function pointer must remain valid while the providing package is loaded.

**See also:** [`R_registerRoutines()`](#R_registerRoutines)

### 1.2.3 `R_FindSymbol()`

**Header:** `R_ext/Rdynload.h`

Look up a symbol in a loaded DLL by name.

``` c
DL_FUNC R_FindSymbol(char const *name, char const *pkg, DllInfo *info);
```

**Returns:** The entry point for `name`, or `NULL` if not found.

Searches the DLLs loaded for package `pkg` (`info` is filled in if not `NULL`). Rarely needed now that `R_GetCCallable()` exists.

**See also:** [`R_GetCCallable()`](#R_GetCCallable)

### 1.2.4 `R_forceSymbols()`

**Header:** `R_ext/Rdynload.h`

Restrict a DLL to registered (symbol) entry points.

``` c
Rboolean R_forceSymbols(DllInfo *info, Rboolean value);
```

**Returns:** The previous setting.

With `value = TRUE`, entry points of the DLL can only be called via registered `R_CallMethodDef` symbols, not by name. Set in `R_init_<package>()` alongside `R_useDynamicSymbols(dll, FALSE)`.

**See also:** [`R_registerRoutines()`](#R_registerRoutines)

## 1.3 The contract

A C function called from R signs up to four rules:

1.  **Main thread only.** R’s API is not thread-safe. Call it only from the thread R called you on; do your own threading only on memory R doesn’t know about.
2.  **Errors longjmp.** `Rf_error()`, failed allocations, and user interrupts unwind the C stack with `longjmp` — destructors don’t run and `free()` doesn’t happen. Use `R_UnwindProtect()` or transient allocation ([Memory allocation](memory.llms.md)) when you hold resources.
3.  **Arguments are borrowed.** The `SEXP`s you receive are owned by R. You must not modify them (they may be shared — see [SEXPs](sexps.llms.md)), and you must not store pointers to their contents beyond the call.
4.  **Protect what you allocate.** Any `SEXP` you create can be collected by the garbage collector at the next allocation unless you `PROTECT` it — see [Protection](protection.llms.md).

## 1.4 A minimal package

The smallest working package has six files:

    mypkg/
      DESCRIPTION          # Package: mypkg ...
      NAMESPACE            # useDynLib(mypkg, .registration = TRUE); export(add_one)
      R/add_one.R          # the .Call wrapper
      src/add_one.c        # the C code
      src/init.c           # registration
      src/Makevars         # PKG_CPPFLAGS = -DR_NO_REMAP

`usethis::create_package()` + `usethis::use_c()` sets this up for you.

## 1.5 Iterating quickly

For fast iteration, `pkgload::load_all()` recompiles and reloads the package’s DLL in place. For one-off experiments without a package, the `callme` package compiles a string of C code and calls it directly — the modern replacement for the old `inline` package. If you want C++ with automatic wrappers, look at cpp11 or Rcpp; the underlying rules in this book still apply.

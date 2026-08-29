# 3  Protection and the garbage collector

R’s garbage collector reclaims `SEXP`s that are no longer reachable. That creates a hazard unique to writing C against R: a `SEXP` you just allocated can be freed out from under you at the *next allocation*, unless you tell R you’re still using it. Telling R is called **protection**, and getting it right is the single most important discipline in R C programming.

## 3.1 When the garbage collector runs

GC can only run when R allocates — `Rf_allocVector()`, `Rf_cons()`, `Rf_install()`, `Rf_mkString()`, and anything else that creates an object. Pure accessors (`REAL()`, `TYPEOF()`, `CAR()`) never trigger it. The corollary: an unprotected `SEXP` is safe only until the next allocation, which makes protection bugs easy to miss — they surface only when GC happens to run at the wrong moment.

### 3.1.1 `R_gc()` (`R_gc_running()`)

Trigger garbage collection, or check whether it is running.

``` c
void R_gc(void);
int R_gc_running();
```

**Status:** API · **Header:** `R_ext/Memory.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `gc`

## 3.2 What needs protecting

Protect every `SEXP` you allocate, unless it is immediately stored inside an already-protected object. You do **not** need to protect:

- **Function arguments** — R is holding them for the duration of the call.
- **Symbols** — interned symbols are permanently reachable.
- **Values reachable from a protected object** — e.g. once you’ve `SET_VECTOR_ELT(protected_list, i, x)`, `x` is safe.
- **`R_NilValue`** and other R-owned constants.

When in doubt, protect: an extra `PROTECT` is cheap, a missing one is a crash.

## 3.3 PROTECT and UNPROTECT

`PROTECT()` pushes the object onto a protection stack (an internal array of `SEXP`s); `UNPROTECT(n)` pops the `n` most recent entries. Protects and unprotects must balance exactly — R warns about a “stack imbalance” when they don’t. Because the stack is only reset when your `.Call` entry point returns, protecting inside a loop without unprotecting can overflow it; use `PROTECT_WITH_INDEX()`/`REPROTECT()` to reuse one stack slot across iterations.

### 3.3.1 `Rf_protect()` (`Rf_unprotect()`)

Protect and unprotect objects from garbage collection.

``` c
SEXP Rf_protect(SEXP);
void Rf_unprotect(int);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

These are the underlying functions for the `PROTECT()` and `UNPROTECT()` macros; use the macros instead in package code.

**See also:** [`PROTECT()`](#PROTECT)

### 3.3.2 `R_ProtectWithIndex()` (`R_Reprotect()`)

Protect an object at a fixed stack location so its value can be replaced later.

``` c
void R_ProtectWithIndex(SEXP, PROTECT_INDEX *);
void R_Reprotect(SEXP, PROTECT_INDEX);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

These are the underlying functions for the `PROTECT_WITH_INDEX()` and `REPROTECT()` macros. Useful when you need to coerce a protected value and replace it in place, such as inside a loop.

**See also:** [`PROTECT()`](#PROTECT)

### 3.3.3 `PROTECT()` (`UNPROTECT()`, `PROTECT_WITH_INDEX()`, `REPROTECT()`)

Protect SEXPs from garbage collection.

``` c
SEXP PROTECT(SEXP s);
void UNPROTECT(int n);
PROTECT_INDEX PROTECT_WITH_INDEX(SEXP s, PROTECT_INDEX *idx);
void REPROTECT(SEXP s, PROTECT_INDEX idx);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

`PROTECT()` pushes `s` onto the protection stack; `UNPROTECT(n)` pops the `n` most recent entries. Unbalanced use inside a loop can overflow the protection stack, since it is only reset automatically when your `.Call` entry point returns. Use `PROTECT_WITH_INDEX()`/`REPROTECT()` to re-protect a different value at the same stack depth, e.g. inside a loop.

``` c
SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
// ... fill out ...
UNPROTECT(1);
return out;
```

**See also:** [`R_PreserveObject()`](#R_PreserveObject)

### 3.3.4 `UNPROTECT_PTR()` (`Rf_unprotect_ptr()`)

Unprotect a specific object by pointer.

``` c
#define UNPROTECT_PTR(s) Rf_unprotect_ptr(s)
void Rf_unprotect_ptr(SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

Searches the protection stack for a matching entry and removes it, rather than unprotecting the most recent entries. Convenient but error-prone: prefer a strict `PROTECT`/`UNPROTECT` stack discipline, or `PROTECT_WITH_INDEX` when the number of protected objects varies.

**See also:** [`PROTECT()`](#PROTECT), [`R_ProtectWithIndex()`](#R_ProtectWithIndex)

## 3.4 Preserving objects across calls

`PROTECT` only lasts until your `.Call` returns. To keep an object alive across multiple calls from R (typically stashed in a static variable or an external pointer), add it to R’s precious list. The precious list is a pairlist walked by the GC; because `R_ReleaseObject()` searches it linearly, preserving and releasing many objects in the same order can degrade to quadratic time — see [this dplyr issue](https://github.com/tidyverse/dplyr/issues/1396) for a real-world manifestation.

### 3.4.1 `R_PreserveObject()` (`R_ReleaseObject()`)

Preserve an object across C calls by adding it to R’s precious list.

``` c
void R_PreserveObject(SEXP);
void R_ReleaseObject(SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

Objects are added to `R_PreciousList`, a pairlist walked by the garbage collector. `R_PreserveObject()` allocates (it conses the object onto `R_PreciousList`), so it can throw on out-of-memory; `R_ReleaseObject()` performs a linear search of this list to remove the entry and does not allocate, but repeatedly preserving and releasing many objects in the same order can cause quadratic slowdowns.

**See also:** [`PROTECT()`](#PROTECT)

### 3.4.2 `R_NewPreciousMSet()` (`R_PreserveInMSet()`, `R_ReleaseFromMSet()`)

Protect a changing set of objects across R calls.

``` c
SEXP R_NewPreciousMSet(int n);
void R_PreserveInMSet(SEXP x, SEXP mset);
void R_ReleaseFromMSet(SEXP x, SEXP mset);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

- `n`: initial capacity hint.
- `mset`: a multi-set created by `R_NewPreciousMSet()`.

A “precious multi-set” protects many objects more cheaply than one `R_PreserveObject()` per object. The set itself must be protected (e.g. with `R_PreserveObject()`); members can be added and removed freely.

**See also:** [`R_PreserveObject()`](#R_PreserveObject)

## 3.5 Modifying inputs and reference counting

You must not modify a function argument in place: it may be shared with the caller (see [SEXPs](sexps.llms.md)). Duplicate first — for lists, `Rf_shallow_duplicate()` copies only the top level, while `Rf_duplicate()` copies every element. `MAYBE_SHARED()` and friends let you check the reference-count flags before modifying an object you *did* create, which is the optimisation R’s own internals use.

### 3.5.1 `MAYBE_SHARED()` (`NO_REFERENCES()`, `MAYBE_REFERENCED()`, `NOT_SHARED()`, `MARK_NOT_MUTABLE()`)

Test or set an object’s reference-count flags before modifying it in place.

``` c
int MAYBE_SHARED(SEXP x);
int NO_REFERENCES(SEXP x);
void MARK_NOT_MUTABLE(SEXP x);
#define MAYBE_REFERENCED(x) (! NO_REFERENCES(x))
#define NOT_SHARED(x) (! MAYBE_SHARED(x))
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

Package code sees these as plain functions, not macros (that expansion is only visible inside R’s own build, where `USE_RINTERNALS` is defined). By default they test the `REFCNT` reference count, since R defines `SWITCH_TO_REFCNT` unless a package opts out with `SWITCH_TO_NAMED`; the legacy `NAMED` counter is what they test in that (rare) opt-out case.

**See also:** [`Rf_duplicate()`](#Rf_duplicate)

### 3.5.2 `Rf_duplicate()` (`Rf_shallow_duplicate()`, `Rf_lazy_duplicate()`)

Duplicate an object, either deeply or shallowly.

``` c
SEXP Rf_duplicate(SEXP);
SEXP Rf_shallow_duplicate(SEXP);
SEXP Rf_lazy_duplicate(SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

Use `Rf_shallow_duplicate()` for lists when only the top-level structure needs copying; `Rf_duplicate()` also copies every element.

**See also:** [`MAYBE_SHARED()`](#MAYBE_SHARED)

## 3.6 Finding protection bugs

Protection bugs typically manifest as intermittent segfaults or corrupted objects. Two tools make them reproducible:

- `gctorture(TRUE)` (or `gctorture2()` for finer control) forces a GC at every allocation, so a missing `PROTECT` fails immediately instead of randomly. Combine with `gctorture(TRUE); <your test>` under `R CMD check`.
- [rchk](https://github.com/kalibera/rchk) statically analyses your compiled package for protect/unprotect imbalances and unprotected uses. It has false positives, but every report is worth reading.

## 3.7 Header flags

The macros below read and write the flags in an object’s header. You rarely need them directly — prefer the higher-level accessors noted in the entry.

### 3.7.1 `TYPEOF()` (`NAMED()`, `REFCNT()`, `SET_NAMED()`)

Read an object’s type tag and header flags.

``` c
int  (TYPEOF)(SEXP x);
int  (NAMED)(SEXP x);
int  (REFCNT)(SEXP x);
void (SET_NAMED)(SEXP x, int v);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

`TYPEOF()` is the canonical way to test an object’s type. The flag accessors are mostly needed only for the reference-count checks described above. There are no API setters for the type or object flags — use constructors (e.g. `Rf_allocLang()`) and `Rf_setAttrib()` instead.

**See also:** [`MAYBE_SHARED()`](#MAYBE_SHARED), [`Rf_isObject()`](#Rf_isObject)

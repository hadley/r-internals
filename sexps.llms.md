# 2  SEXPs

Every R object you see in C is a `SEXP` — a pointer to a headered structure whose first field is a `SEXPTYPE` tag saying what kind of object it is. This uniform object model means one C type represents everything from a number to an environment; you distinguish cases with `TYPEOF()`.

``` c
SEXP x;
if (TYPEOF(x) == REALSXP) { ... }
```

Prefer `TYPEOF(x) == INTSXP`-style tests over the old `Rf_isInteger()` family: the `Rf_is*()` functions sometimes answer “can this be coerced to” rather than “is this”, and there is no `Rf_is*()` for many types. Test the type you actually require, and `Rf_error()` otherwise.

## 2.1 SEXPTYPEs

The complete set of `SEXPTYPE`s, with the chapter that covers each:

| SEXPTYPE | R object | Chapter |
|----|----|----|
| `NILSXP` | `NULL` | — |
| `SYMSXP` | symbol (name) | [Symbols](symbols.llms.md) |
| `LISTSXP` | pairlist | [Pairlists](pairlists.llms.md) |
| `CLOSXP` | closure (R function) | [Functions](functions.llms.md) |
| `ENVSXP` | environment | [Environments](environments.llms.md) |
| `PROMSXP` | promise | [Functions](functions.llms.md) |
| `LANGSXP` | call | [Pairlists](pairlists.llms.md) |
| `SPECIALSXP`, `BUILTINSXP` | primitive function | [Functions](functions.llms.md) |
| `CHARSXP` | single string (internal) | [Strings](strings.llms.md) |
| `LGLSXP`, `INTSXP`, `REALSXP`, `CPLXSXP`, `STRSXP`, `RAWSXP`, `VECSXP`, `EXPRSXP` | vectors | [Vectors](vectors.llms.md) |
| `DOTSXP` | `...` | [Pairlists](pairlists.llms.md) |
| `ANYSXP` | wildcard for matching; no object has this type | — |
| `BCODESXP` | byte code | internals; not covered |
| `EXTPTRSXP` | external pointer | [External pointers](external-pointers.llms.md) |
| `WEAKREFSXP` | weak reference | [External pointers](external-pointers.llms.md) |
| `S4SXP` | S4 object | [OO](oo.llms.md) |
| `NEWSXP`, `FREESXP` | node-class bookkeeping | internals; never seen in package code |
| `FUNSXP` | pseudo-type matching any function type | — |

## 2.2 Layout

Conceptually, a `SEXP` points to a fixed-size header (the type tag, GC and reference-count flags, attribute pointer, and links) followed by type-specific payload. For vectors the payload is a contiguous C array you access with `REAL()`, `INTEGER()`, and friends ([Vectors](vectors.llms.md)); for cons-based types it is `CAR`/`CDR` slots ([Pairlists](pairlists.llms.md)). Treat the header as opaque: read it through accessor macros, never by poking struct fields directly.

Almost every object can carry **attributes** — a pairlist of named metadata such as `names`, `dim`, and `class`. Attributes are what turn a bare vector into a matrix, factor, or data frame; see [Attributes](attributes.llms.md).

## 2.3 Copy-on-modify

R semantics are copy-on-modify: two variables can point at the same object, and R copies only when one of them modifies it. At the C level there is no automatic copying, so the rule becomes: **never modify an object you didn’t create**. Function arguments in particular may be shared with the caller. If you need to modify an input, duplicate it first:

``` c
SEXP out = PROTECT(Rf_duplicate(x));  // deep copy
// or Rf_shallow_duplicate(x) to copy only the top level of a list
```

`MAYBE_SHARED(x)` tells you whether an object *might* be shared, but it is conservative — treat “maybe” as “yes”. The reference-count flags behind it (`NAMED`/`REFCNT`) are an optimisation used by R’s internals, not a licence to mutate; see [Protection](protection.llms.md) for the details.

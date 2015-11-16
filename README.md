# R internals

This repo aims to provide some useful additional information about R's internal C API (for the rare circumstance where you need to use it instead of [Rcpp](http://www.rcpp.org)). This site draws heavily from Section 5 ("System and foreign language interfaces") of [Writing R extensions](http://cran.r-project.org/doc/manuals/R-exts.html), [R internals](https://cran.r-project.org/doc/manuals/r-release/R-ints.html), and inspection of R's source code to see how functions are used.

Here we focus on best practices and modern tools. To wit, we recommend that you use `R_NO_REMAP` so all API functions have the prefix `R_` or `Rf_`:

```c
#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
```

(Including `<Rinternals.h>` seems like bad form. However, it doesn't actually give you access to the "internal" internal API unless you set some additional flags. Instead it lets you access the "public" internal API, which is both necessary and safe. Yes, this is confusing.)

## SEXPs

At the C-level, all R objects are stored in a common datatype, the `SEXP`, or S-expression. A `SEXP` is a variant type, with subtypes or `SEXPTYPE`s for all R's data structures. This site roughly breaks R's API in chapters based on the `SEXPTYPE` the functions work with:

* [Vectors](vectors.md) cover the most important data structures: vectors.
  This includes `LGLSXP`, `INTSXP`, `REALSXP`, `CPLXSXP`, `STRSXP`, `VECSXP`,
  `RAWSXP`, and `EXPRSXP`.

* [Strings](strings.md): Character vectors are a more complex object made of 
  vector `CHARSXP`s.

* [Environments](environments.md), or `ENVSXP`s.

* [Functions](functions,md), including `CLOSXP`s and the rarer `BUILTINSXP`s,
  `SPECIALSXP`s and `FUNSXPs`.

* [Symbols](symbols.md), `SYMSXP`s.

* [Pairlists](pairlists.md), including `LISTSXP`s and the related
  `NILSXP`, `LANGSXP`, and `DOTSXP`. This chapter also includes a discussion
  of attributes, which are powered by pair lists.

* [External pointers](external-pointers.md), or `XPTRSXP`s.

Other categories are:

* [Evaluating code and handling errors](error-eval.md).
* [Garbage collection and reference counting](gc-rc.md).
* [Object oriented code](oo.md) (including `S4SXP`s).
* [Other miscellaneous functions](misc.md).
* [Serialisation](save-load.md).

# R internals

Reading R's source code is an extremely powerful technique for improving your programming skills. However, many base R functions, and many functions in older packages, are written in C. It's useful to be able to figure out how those functions work, so this chapter will introduce you to R's C API. You'll need some basic C knowledge, which you can get from a standard C text (e.g., [_The C Programming Language_](http://amzn.com/0131101633?tag=devtools-20) by Kernigan and Ritchie), or from [Rcpp](#rcpp). You'll need a little patience, but it is possible to read R's C source code, and you will learn a lot doing it. \index{C}

The contents of this chapter draw heavily from Section 5 ("System and foreign language interfaces") of [Writing R extensions](http://cran.r-project.org/doc/manuals/R-exts.html), but focus on best practices and modern tools. This means it does not cover the old `.C` interface, the old API defined in `Rdefines.h`, or rarely used language features. To see R's complete C API, look at the header file `Rinternals.h`. It's easiest to find and display this file from within R:

```{r, eval = FALSE}
rinternals <- file.path(R.home("include"), "Rinternals.h")
file.show(rinternals)
```

All functions are defined with either the prefix `Rf_` or `R_` but are exported without it (unless `#define R_NO_REMAP` has been used).

I do not recommend using C for writing new high-performance code. Instead write C++ with Rcpp. The Rcpp API protects you from many of the historical idiosyncracies of the R API, takes care of memory management for you, and provides many useful helper methods.

## Getting started

To call a C function from R, you first need a C function! In an R package, C code lives in `.c` files in `src/`. You'll need to include two header files:

```c
#include <R.h>
#include <Rinternals.h>
```

(Yes, including `<Rinternals.h>` seems like bad form. On top of that, doing so doesn't actually give you access to the "internal" internal API unless you set some additional flags. The default just gives you access to the "public" internal API, which is both necessary and done for safety's sake. Yes, this is confusing.)

## SEXPs

At the C-level, all R objects are stored in a common datatype, the `SEXP`, or S-expression. All R objects are S-expressions so every C function that you create must return a `SEXP` as output and take `SEXP`s as inputs. (Technically, this is a pointer to a structure with typedef `SEXPREC`.) A `SEXP` is a variant type, with subtypes for all R's data structures. The most important types are: \indexc{SEXP}

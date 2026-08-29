# 14  Evaluation

Evaluating R code from C is how you call back into R: apply a function, access a method, or run user-supplied expressions. There is no public “apply this closure to these arguments” entry point (`Rf_applyClosure()` is internal); instead you build a call — a `LANGSXP` pairlist, see [Pairlists, calls, and `...`](pairlists.llms.md) — and evaluate it with `Rf_eval()`.

Evaluation can do anything R code can do: allocate, signal errors, and longjmp. Treat every `Rf_eval()` as a potential non-local return and protect accordingly.

## 14.1 Evaluation

Follows [WRE §5.11, Evaluating R expressions from C](https://cran.r-project.org/doc/manuals/R-exts.html#Evaluating-R-expressions-from-C) closely.

A typical use looks up a function and calls it with C-constructed arguments:

``` c
SEXP call = PROTECT(Rf_lang2(Rf_install("sqrt"), x));
SEXP result = PROTECT(Rf_eval(call, R_GlobalEnv));
/* ... */
UNPROTECT(2);
```

For more than a couple of arguments, build the call with `Rf_allocList()` + `SET_TYPEOF(..., LANGSXP)` or `Rf_cons()` rather than deeply nesting `Rf_lang*()` calls. Evaluate in the environment that gives the call the right scope: `R_GlobalEnv` for user-visible semantics, a namespace environment for calling a package’s internals, or `R_BaseEnv`/`R_BaseNamespace` for base functions.

### 14.1.1 `Rf_eval()`

Evaluate an expression in an environment.

``` c
SEXP Rf_eval(SEXP expression, SEXP environment);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `eval()`

Expression can be anything - non-language objects are returned as is.

### 14.1.2 `R_forceAndCall()`

Force promises in an expression and then call it.

``` c
SEXP R_forceAndCall(SEXP expression, int n, SEXP environment);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

- `n`: The number of arguments to force.

`n` is the number of leading arguments in the call to force before evaluating.

**See also:** [`Rf_eval()`](#Rf_eval)

### 14.1.3 `Rf_substitute()`

Substitute values for variables in an expression.

``` c
SEXP Rf_substitute(SEXP,SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `substitute()`

## 14.2 Protected evaluation

`Rf_eval()` longjmps on error, abandoning your C function mid-flight. If you need to keep control after a failure — to report the error yourself, retry, or clean up and continue — evaluate in a context that catches the error instead. These functions ignore all existing condition handlers, so R-level `tryCatch()` and `suppressWarnings()` have no effect on the protected evaluation.

For richer control — running cleanup code on unwind, or installing condition handlers — see [Errors and conditions](errors.llms.md).

### 14.2.1 `R_tryEval()` (`R_tryEvalSilent()`)

Evaluate an R expression in a stand-alone context so errors don’t longjmp.

``` c
SEXP R_tryEval(SEXP expression, SEXP environment, int* pOutError);
SEXP R_tryEvalSilent(SEXP expression, SEXP environment, int* pOutError);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** never · **Since:** — · **R equivalent:** `try()`

- `pOutError`: On error, the function returns NULL and sets the contents of `pOutError` to 1.

`R_tryEvalSilent()` behaves like `R_tryEval()` but suppresses printing of error messages. Both ignore existing condition handlers, so R-level `tryCatch()` and `suppressWarnings()` have no effect on the evaluation.

**See also:** [`R_ToplevelExec()`](#R_ToplevelExec)

### 14.2.2 `R_ToplevelExec()`

Execute a C function in a top-level context, catching any errors.

``` c
Rboolean R_ToplevelExec(void (*fun)(void *), void *data);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

- `fun`: C function to call after context setup. Passed `*data`.

Both `R_tryEval()` and `R_tryEvalSilent()` call `R_ToplevelExec` under the hood.

**See also:** [`R_tryEval()`](#R_tryEval)

### 14.2.3 `R_curErrorBuf()`

Access the text of the current error.

``` c
const char *R_curErrorBuf();
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `geterrmessage()`

## 14.3 Parsing

Parsing turns text into an expression vector (`EXPRSXP`) without evaluating it; evaluate the result element by element with `Rf_eval()`. Always check the returned `ParseStatus` before evaluating.

### 14.3.1 `R_ParseVector()` (`R_ParseString()`, `R_ParseEvalString()`)

Parse R code from a character vector or C string.

``` c
SEXP R_ParseVector(SEXP text, int n, ParseStatus *status, SEXP srcfile);
SEXP R_ParseString(const char *str);
SEXP R_ParseEvalString(const char *str, SEXP env);
```

**Status:** API · **Header:** `R_ext/Parse.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

- `text`: a character vector of lines of R code.
- `n`: number of elements to parse, or -1 for all.
- `status`: set to `PARSE_OK`, `PARSE_INCOMPLETE`, `PARSE_ERROR`, or `PARSE_EOF`; may be `NULL`.
- `srcfile`: a source reference environment, usually `R_NilValue`.

Returns an `EXPRSXP` of parsed expressions. `R_ParseString()` (R 4.4.0) parses a single C string; `R_ParseEvalString()` parses and evaluates in one step. Check `status` before evaluating the result.

**See also:** [`Rf_eval()`](#Rf_eval)

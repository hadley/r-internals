# 15  Errors and conditions

R reports errors with a `longjmp`: `Rf_error()` never returns, abandoning your C function on the spot. That has two consequences you must design around. First, any cleanup your function owes — freeing `R_Calloc()` memory, closing files, restoring global state — will not run unless you arrange it in advance with `R_UnwindProtect()` or an external pointer finalizer. Second, in C++ the longjmp skips destructors, so RAII objects must live below an `R_UnwindProtect()` boundary that converts the longjmp into a C++ exception (see `R_MakeUnwindCont()`).

For catching errors from R code you call, rather than signalling your own, see the protected evaluation entry points in [Evaluation](evaluation.llms.md).

## 15.1 Signalling

Follows [WRE §6.2, Error signaling](https://cran.r-project.org/doc/manuals/R-exts.html#Error-signaling-1) closely.

`Rf_error()` and `Rf_warning()` take `printf`-style format strings. If your message is a plain string that might contain `%`, pass it as `Rf_error("%s", msg)` so it isn’t interpreted as a format.

To signal an error with a custom class — so R code can catch it selectively with `tryCatch(my_class = function(c) ...)` — there is no dedicated entry point. Build a condition object (a named list with `message` and `call` fields, classed `c("my_class", "error", "condition")`) and signal it by evaluating a call to `stop()`:

``` c
SEXP cls = PROTECT(Rf_allocVector(STRSXP, 3));
SET_STRING_ELT(cls, 0, Rf_mkChar("negative_value"));
SET_STRING_ELT(cls, 1, Rf_mkChar("error"));
SET_STRING_ELT(cls, 2, Rf_mkChar("condition"));

SEXP cond = PROTECT(Rf_mkNamed(VECSXP, (const char *[]){"message", "call", ""}));
SET_VECTOR_ELT(cond, 0, Rf_mkString("x must be non-negative"));
SET_VECTOR_ELT(cond, 1, R_NilValue);
Rf_classgets(cond, cls);

/* Never returns, so the UNPROTECT is never reached */
Rf_eval(Rf_lang2(Rf_install("stop"), cond), R_GlobalEnv);
```

The same pattern with `warning()` signals a classed warning.

### 15.1.1 `Rf_error()` (`Rf_errorcall()`)

Signal an error, optionally including the call in the message.

``` c
void Rf_error(const char* format, ...);
void Rf_errorcall(SEXP call, const char* format, ...);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** `stop()`

Use `Rf_errorcall(R_NilValue, ...)` to suppress display of the call.

### 15.1.2 `Rf_warning()` (`Rf_warningcall()`, `Rf_warningcall_immediate()`)

Signal a warning, optionally including the call or displaying it immediately.

``` c
void Rf_warning(const char* format, ...);
void Rf_warningcall(SEXP call, const char*, ...);
void Rf_warningcall_immediate(SEXP call, const char*, ...);
```

**Status:** API · **Header:** `R_ext/Error.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** `warning()`

### 15.1.3 `error_return()` (`errorcall_return()`)

Eliminate compiler warnings about non-void functions that don’t return.

``` c
#define error_return(msg) { \
  Rf_error(msg); \
  return R_NilValue; \
}
#define errorcall_return(cl,msg) { \
  Rf_errorcall(cl, msg); \
  return R_NilValue; \
}
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

`Rf_error` will `longjmp` and so any code following will not be executed; however, most compilers do not detect this when providing warnings.

**See also:** [`Rf_error()`](#Rf_error)

### 15.1.4 `UNIMPLEMENTED()`

Signal an error for an unimplemented operation.

``` c
[[noreturn]] void UNIMPLEMENTED(const char *s);
```

**Status:** API · **Header:** `R_ext/Error.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

Signals “feature ‘s’ is not implemented”; never returns. Use `UNIMPLEMENTED_TYPE()` for a type-specific variant.

**See also:** [`Rf_error()`](#Rf_error)

## 15.2 Condition handling and cleanup

Follows [WRE §6.13, Condition handling and cleanup code](https://cran.r-project.org/doc/manuals/R-exts.html#Condition-handling-and-cleanup-code-1) closely.

These functions let C code do what `tryCatch()` and `on.exit()` do at the R level: run a body function with a condition handler or cleanup action installed. Reach for `R_UnwindProtect()` when you need guaranteed cleanup, and the `R_tryCatch*()` family when you need to inspect or recover from a condition object.

### 15.2.1 `R_UnwindProtect()`

Run a C function, guaranteeing a cleanup action runs on normal return and on longjmp.

``` c
SEXP R_UnwindProtect(SEXP (*fun)(void *data), void *data,
                     void (*clean)(void *cdata, Rboolean jump), void *cdata,
                     SEXP cont);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

- `fun`: function to run; its return value is passed through.
- `clean`: cleanup function, called with `jump = FALSE` after a normal return and `jump = TRUE` before a non-local transfer of control resumes.
- `cont`: continuation token from `R_MakeUnwindCont()`, or `R_NilValue` for plain C use.

This is the primary tool for making C (and C++) code longjmp-safe: free `R_Calloc()` memory, close files, and restore state in `clean`. With a continuation token, `clean` can throw a C++ exception to unwind the C++ stack and then call `R_ContinueUnwind()` to resume R’s longjmp.

**See also:** [`R_MakeUnwindCont()`](#R_MakeUnwindCont), [`R_ExecWithCleanup()`](#R_ExecWithCleanup)

### 15.2.2 `R_MakeUnwindCont()` (`R_ContinueUnwind()`)

Allocate a continuation token for C++ stack unwinding, and resume the unwind.

``` c
SEXP R_MakeUnwindCont(void);
NORET void R_ContinueUnwind(SEXP cont);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

`PROTECT` the token before passing it to `R_UnwindProtect()`. Only needed when C++ code sits between R and the cleanup handler; plain C code should pass `R_NilValue` as `cont` instead.

**See also:** [`R_UnwindProtect()`](#R_UnwindProtect)

### 15.2.3 `R_ExecWithCleanup()`

Execute a C function in a protected context, with cleanup before teardown.

``` c
SEXP R_ExecWithCleanup(SEXP (*fun)(void *), void *data,
                       void (*cleanfun)(void *),
                       void *cleandata);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

- `fun`: C function to call after context setup. Passed `*data`.
- `cleanfun`: C function to call before context teardown. Passed `*data`.

Older, simpler variant of `R_UnwindProtect()`; the cleanup function is not told whether the exit was a normal return or a longjmp.

**See also:** [`R_UnwindProtect()`](#R_UnwindProtect)

### 15.2.4 `R_tryCatchError()` (`R_withCallingErrorHandler()`)

Call a C function with a handler installed for R error conditions.

``` c
SEXP R_tryCatchError(SEXP (*fun)(void *data), void *data,
                     SEXP (*hndlr)(SEXP cond, void *hdata), void *hdata);
SEXP R_withCallingErrorHandler(SEXP (*fun)(void *data), void *data,
                               SEXP (*hndlr)(SEXP cond, void *hdata), void *hdata);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `tryCatch()`

- `hndlr`: handler called with the condition object; its return value becomes the result.

`R_tryCatchError()` installs an exiting handler (like `tryCatch(error = ...)`); `R_withCallingErrorHandler()` installs a calling handler (like `withCallingHandlers(error = ...)`) and avoids calling back into R, so it is more efficient. `R_tryCatchError()` is implemented via R-level `tryCatch()` and has some overhead.

**See also:** [`R_tryCatch()`](#R_tryCatch), [`R_tryEval()`](#R_tryEval)

### 15.2.5 `R_tryCatch()`

Call a C function with handlers for arbitrary condition classes and a cleanup action.

``` c
SEXP R_tryCatch(SEXP (*fun)(void *data), void *data,
                SEXP conds,
                SEXP (*hndlr)(SEXP cond, void *hdata), void *hdata,
                void (*clean)(void *cdata), void *cdata);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `tryCatch()`

- `conds`: condition classes to handle, as a character vector (`STRSXP`).

`NULL` may be passed for `fun` or `clean` if condition handling or cleanup is not needed. Implemented via R-level `tryCatch()`, so it has some overhead.

**See also:** [`R_tryCatchError()`](#R_tryCatchError), [`R_UnwindProtect()`](#R_UnwindProtect)

## 15.3 Interrupts

Follows [WRE §6.14, Allowing interrupts](https://cran.r-project.org/doc/manuals/R-exts.html#Allowing-interrupts-1) closely.

### 15.3.1 `R_CheckUserInterrupt()`

Check for a pending user interrupt, signalling an error if one occurred.

``` c
void R_CheckUserInterrupt(void);
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

Call periodically from long-running loops; R cannot interrupt compiled code that never checks. On interrupt it longjmps, so the same cleanup obligations as for `Rf_error()` apply.

### 15.3.2 `Rf_onintr()`

R’s default response to a user interrupt.

``` c
void Rf_onintr(void);
```

**Status:** API · **Header:** `Rinterface.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

Jumps back to the top level, discarding the current computation. Intended for front-ends and graphics devices; package code should almost always use `R_CheckUserInterrupt()` instead.

**See also:** [`R_CheckUserInterrupt()`](#R_CheckUserInterrupt)

## 15.4 C stack checking

Follows [WRE §6.15, C stack checking](https://cran.r-project.org/doc/manuals/R-exts.html#C-stack-checking-1) closely.

### 15.4.1 `R_CheckStack()` (`R_CheckStack2()`)

Signal an error if the C stack is (nearly) exhausted.

``` c
void R_CheckStack(void);
void R_CheckStack2(R_SIZE_T extra);
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

- `extra`: `R_CheckStack2()` errors when fewer than `extra` bytes remain.

Call before deep C recursion; better still, avoid deep recursion or write it tail-recursively so the compiler can optimize it away. Stack checking is not available on all platforms.

# Errors and Evaluation

Use `Rf_errorcall(R_NilValue, ...)` to suppress display of call.

```cpp
void Rf_error(const char* format, ...);
void Rf_errorcall(SEXP call, const char* format, ...);

void Rf_warning(const char* format, ...);
void Rf_warningcall(SEXP call, const char*, ...);
void Rf_warningcall_immediate(SEXP call, const char*, ...);

// One of these things is not like the others...
void  R_ShowMessage(const char *s);

// Print to stdout or stderr
void Rprintf(const char *, ...);
void REprintf(const char *, ...);

void R_FlushConsole(void);
```

Two macros eliminate compiler warnings about non-void functions that don't return.
(`Rf_error` will `longjmp` and so any code following will not be executed; however,
most compilers do not detect this when providing warnings)

```cpp
#define error_return(msg) { \\
  Rf_error(msg); \\
  return R_NilValue; \\
}
#define errorcall_return(cl,msg) { \\
  Rf_errorcall(cl, msg); \\
  return R_NilValue; \\
}
```

## Evaluation

```cpp
// Expression can be anything - non-language objects are returned as is.
// [[SEXP creator]]
SEXP Rf_eval(SEXP expression, SEXP environment);

// Force promises in an expression and then call.
// n, I think, is the number of arguments to force.
// Not sure what advantages are over Rf_eval.
// [[SEXP creator]]
SEXP R_forceAndCall(SEXP expression, int n, SEXP environment);

/* Protected evaluation
 *
 * Use these to evaluate R expressions in a stand-alone context,
 * free of existing handlers, and to ensure that any errors produced
 * during evaluation don't cause a longjmp to a separate context.
 *
 * R_tryEval and R_tryEvalSilent both call R_ToplevelExec under the hood.
 */
// [[SEXP creator]]
// On error, returns NULL and sets contents of pOutError to 1
SEXP R_tryEval(SEXP expression, SEXP environment, int* pOutError);

// [[SEXP creator]]
// same as R_tryEval, but doesn't print error messages
SEXP R_tryEvalSilent(SEXP expression, SEXP environment, int* pOutError);

// [[SEXP creator]]
// @param fun C function to call after context setup. Passed *data
Rboolean R_ToplevelExec(void (*fun)(void *), void *data);


// You can access text of error with
const char *R_curErrorBuf();


// [[SEXP creator]]
// Note: Not used anywhere in R souce
// @param fun C function to call after context setup. Passed *data
// @param cleanfun C function to call before context teardown. Passed *data
SEXP R_ExecWithCleanup(SEXP (*fun)(void *), void *data,
                       void (*cleanfun)(void *), 
                       void *cleandata);
```

# Errors and evaluatoin

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

Two macros eliminate compiler warnings about non-void function with void returns:

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

/* Protected evaluation */
// [[SEXP creator]]
// Returns NULL on failure
SEXP R_tryEval(SEXP expression, SEXP environment, int* pOutError);
// [[SEXP creator]]
// Returns NULL on failure
SEXP R_tryEvalSilent(SEXP expression, SEXP environment, int* pOutError);

// You can access text of error with
const char *R_curErrorBuf();


// [[SEXP creator]]
// @param fun C function to call after context setup. Passed *data
Rboolean R_ToplevelExec(void (*fun)(void *), void *data);

// [[SEXP creator]]
// Note: Not used anywhere in R souce
// @param fun C function to call after context setup. Passed *data
// @param cleanfun C function to call before context teardown. Passed *data
SEXP R_ExecWithCleanup(SEXP (*fun)(void *), void *data,
                       void (*cleanfun)(void *), 
                       void *cleandata);
```

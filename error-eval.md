# Errors and evaluatoin

```cpp
void  Rf_error(const char *, ...);
void	Rf_warning(const char *, ...);
void 	R_ShowMessage(const char *s);

void Rf_errorcall(SEXP, const char *, ...);
void Rf_warningcall(SEXP, const char *, ...);
void Rf_warningcall_immediate(SEXP, const char *, ...);

#define error_return(msg)	{ Rf_error(msg);	   return R_NilValue; }
#define errorcall_return(cl,msg){ Rf_errorcall(cl, msg);   return R_NilValue; }

void NORET R_signal_protect_error(void);
void NORET R_signal_unprotect_error(void);
void NORET R_signal_reprotect_error(PROTECT_INDEX i);
```

## Printing 

```cpp
void Rprintf(const char *, ...);
void REprintf(const char *, ...);

void R_FlushConsole(void);
```

## Evaluation

```cpp
SEXP Rf_eval(SEXP, SEXP);

/* Calling a function with arguments evaluated */
SEXP R_forceAndCall(SEXP e, int n, SEXP rho);

/* Protected evaluation */
Rboolean R_ToplevelExec(void (*fun)(void *), void *data);
SEXP R_ExecWithCleanup(SEXP (*fun)(void *), void *data,
  void (*cleanfun)(void *), void *cleandata);

SEXP R_tryEval(SEXP, SEXP, int *);
SEXP R_tryEvalSilent(SEXP, SEXP, int *);
const char *R_curErrorBuf();
```

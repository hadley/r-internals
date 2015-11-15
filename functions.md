# Functions (`CLOSXP`, `BUILTINSXP`, `SPECIALSXP`, `FUNSXP`)

```cpp
Rboolean Rf_isFunction(SEXP);
Rboolean Rf_isPrimitive(SEXP);
```

`FUNSXP` is an abstract union type.

## Internals

```cpp
SEXP (FORMALS)(SEXP x);
SEXP (BODY)(SEXP x);
SEXP (CLOENV)(SEXP x);
int  (RDEBUG)(SEXP x);
int  (RSTEP)(SEXP x);
int  (RTRACE)(SEXP x);
void (SET_RDEBUG)(SEXP x, int v);
void (SET_RSTEP)(SEXP x, int v);
void (SET_RTRACE)(SEXP x, int v);
void SET_FORMALS(SEXP x, SEXP v);
void SET_BODY(SEXP x, SEXP v);
void SET_CLOENV(SEXP x, SEXP v);
```

## Promises (`PROMSXP`)

```cpp
LibExtern SEXP	R_UnboundValue;	    /* Unbound marker */
LibExtern SEXP	R_MissingArg;	    /* Missing argument marker */
```

```cpp
SEXP (PRCODE)(SEXP x);
SEXP (PRENV)(SEXP x);
SEXP (PRVALUE)(SEXP x);
int  (PRSEEN)(SEXP x);
void (SET_PRSEEN)(SEXP x, int v);
void SET_PRENV(SEXP x, SEXP v);
void SET_PRVALUE(SEXP x, SEXP v);
void SET_PRCODE(SEXP x, SEXP v);
void SET_PRSEEN(SEXP x, int v);
```

## Srcrefs

```cpp
LibExtern SEXP	R_Srcref;           /* Current srcref, for debuggers */
SEXP R_GetCurrentSrcref(int);
SEXP R_GetSrcFilename(SEXP);
```

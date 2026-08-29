# 23  Migrating to API compliance

([WRE §6.23](https://cran.r-project.org/doc/manuals/R-exts.html#Moving-into-C-API-compliance-1))

R is progressively clarifying and tightening its C API: entry points intended for internal use are being removed from the installed headers or hidden, and replaced by more robust API entry points. This appendix collects what you need to bring a package that uses non-API entry points into compliance: how to find problems, the API replacements, recipes for common idioms, and backports for packages that must compile against older R versions.

## 23.1 Checking a package

`R CMD check` reports calls to non-API entry points in the *checking compiled code* step, and `R CMD check --as-cran` treats them more strictly. You can also inspect a package’s compiled objects directly:

``` r
tools::checkFF("mypackage", package = "mypackage")
```

The `tools` package carries R’s own list of non-API entry points (`tools:::nonAPI`), which is what the check compares against.

## 23.2 Replacements

The table below is generated from this book’s records: every non-API entry point that has a direct API replacement. For entry points with no drop-in replacement, see the [recipes](#recipes) below.

| Non-API | API replacement |
|----|----|
| `ATTRIB()`, `SET_ATTRIB()` | [`Rf_getAttrib()`](attributes.llms.md#Rf_getAttrib) |
| `Rf_isFrame()` | [`Rf_isDataFrame()`](attributes.llms.md#Rf_isDataFrame) |
| `R_NamespaceRegistry()` | `R_getRegisteredNamespace()` |
| `Rf_findVar()` | [`R_getVar()`](environments.llms.md#R_getVar) |
| `Rf_findVarInFrame3()`, `Rf_findVarInFrame()` | [`R_getVar()`](environments.llms.md#R_getVar) |
| `ENCLOS()`, `SET_ENCLOS()` | [`R_ParentEnv()`](environments.llms.md#R_ParentEnv) |
| `ENVFLAGS()`, `SET_ENVFLAGS()` | [`R_EnvironmentIsLocked()`](environments.llms.md#R_LockEnvironment) |
| `EXTPTR_PTR()`, `EXTPTR_PROT()`, `EXTPTR_TAG()` | [`R_ExternalPtrAddr()`](external-pointers.llms.md#R_ExternalPtrAddr) |
| `FORMALS()`, `BODY()`, `CLOENV()` | [`R_ClosureFormals()`](functions.llms.md#R_ClosureFormals) |
| `SET_FORMALS()`, `SET_BODY()`, `SET_CLOENV()` | [`R_mkClosure()`](functions.llms.md#R_mkClosure) |
| `IS_S4_OBJECT()`, `SET_S4_OBJECT()`, `UNSET_S4_OBJECT()` | [`Rf_isS4()`](oo.llms.md#Rf_isS4) |
| `CONS_NR()` | [`Rf_cons()`](pairlists.llms.md#Rf_cons) |
| `SETLENGTH()` | [`Rf_lengthgets()`](vectors.llms.md#Rf_lengthgets) |
| `STRING_PTR()` | [`STRING_PTR_RO()`](vectors.llms.md#STRING_PTR_RO) |
| `VECTOR_PTR()` | [`VECTOR_ELT()`](vectors.llms.md#VECTOR_ELT) |
| `Rf_GetOption()` | [`Rf_GetOption1()`](utilities.llms.md#Rf_GetOption1) |

## 23.3 Recipes

Common non-API idioms and how to rewrite them.

### 23.3.1 Creating environments, calls, and closures

([WRE §6.23.3–6.23.5](https://cran.r-project.org/doc/manuals/R-exts.html#Creating-environments-1))

A widespread idiom allocates a raw object with `Rf_allocSExp()` (or allocates a pairlist and retypes it with `SET_TYPEOF()`) and then mutates its fields:

``` c
SEXP env = Rf_allocSExp(ENVSXP);
SET_ENCLOS(env, parent);

SEXP expr = Rf_allocList(3);
SET_TYPEOF(expr, LANGSXP);

SEXP fun = Rf_allocSExp(CLOSXP);
SET_FORMALS(fun, formals);
SET_BODY(fun, body);
SET_CLOENV(fun, env);
```

`Rf_allocSExp()`, `SET_TYPEOF()`, and the mutation macros (`SET_ENCLOS()`, `SET_FORMALS()`, …) are not part of the API because they expose internal structure. Use the constructors instead:

``` c
SEXP env  = R_NewEnv(parent, FALSE, 0);
SEXP expr = Rf_allocLang(3);            // R 4.4.1
SEXP fun  = R_mkClosure(formals, body, env);  // R 4.5.0
```

See [`R_NewEnv()`](environments.llms.md#R_NewEnv), [`Rf_allocLang()`](pairlists.llms.md#Rf_allocLang), and [`R_mkClosure()`](functions.llms.md#R_mkClosure). On any R version, a call expression can also be built with `LCONS(R_NilValue, Rf_allocList(n - 1))`.

### 23.3.2 Working with variable bindings

([WRE §6.23.8](https://cran.r-project.org/doc/manuals/R-exts.html#Working-with-variable-bindings-1))

`Rf_findVar()` and `Rf_findVarInFrame()` are too low level for the API; use [`R_getVar()` / `R_getVarEx()`](environments.llms.md#R_getVar) (R 4.5.0), analogous to `get()`/`get0()`, and `R_existsVarInFrame()` to test for existence. To inspect or create delayed, forced, missing, or active bindings — previously done by poking at `PROMSXP` fields — use the experimental binding-access API added in R 4.6.0, documented in [Inspecting bindings](environments.llms.md#inspecting-bindings).

## 23.4 Backports

([WRE §6.23.9](https://cran.r-project.org/doc/manuals/R-exts.html#Some-backports-1))

Packages that must also compile under older R versions can define the newer entry points conditionally. The block below covers every recent addition referenced above:

``` c
#if R_VERSION < R_Version(4, 4, 1)
SEXP Rf_allocLang(int n) {
  if (n > 0)
    return LCONS(R_NilValue, Rf_allocList(n - 1));
  else
    return R_NilValue;
}
#endif

#if R_VERSION < R_Version(4, 5, 0)
# define Rf_isDataFrame(x)   Rf_isFrame(x)
# define R_ClosureFormals(x) FORMALS(x)
# define R_ClosureBody(x)    BODY(x)
# define R_ClosureEnv(x)     CLOENV(x)
# define R_ParentEnv(x)      ENCLOS(x)

SEXP R_mkClosure(SEXP formals, SEXP body, SEXP env) {
  SEXP fun = Rf_allocSExp(CLOSXP);
  SET_FORMALS(fun, formals);
  SET_BODY(fun, body);
  SET_CLOENV(fun, env);
  return fun;
}

void CLEAR_ATTRIB(SEXP x) {
  SET_ATTRIB(x, R_NilValue);
  SET_OBJECT(x, 0);
  UNSET_S4_OBJECT(x);
}
#endif

#if R_VERSION < R_Version(4, 6, 0)
# define DATAPTR_RW(x)        DATAPTR(x)
# define R_class(x)           R_data_class(x, FALSE)
# define R_resizeVector(x, n) SETLENGTH(x, n)

SEXP R_allocResizableVector(SEXPTYPE type, R_xlen_t maxlen) {
  SEXP ret = Rf_allocVector(type, maxlen);
  SET_TRUELENGTH(ret, maxlen);
  SET_GROWABLE_BIT(ret);
  return ret;
}

SEXP R_duplicateAsResizable(SEXP x) {
  SEXP ret = Rf_duplicate(x);
  SET_TRUELENGTH(ret, Rf_xlength(x));
  SET_GROWABLE_BIT(ret);
  return ret;
}
#endif
```

Note the irony: a backport for an old R version necessarily uses the non-API idioms it emulates. Guard each backport with the version check so it only compiles where the real API is missing, and drop it once your minimum supported R version catches up.

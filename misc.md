# Misc

## Other sexptypes

### Byte code (`BCODESXP`)

```cpp
#define BCODE_CODE(x)	CAR(x)
#define BCODE_CONSTS(x) CDR(x)
#define BCODE_EXPR(x)	TAG(x)
#define isByteCode(x)	(TYPEOF(x)==BCODESXP)

void R_initialize_bcode(void);
SEXP R_bcEncode(SEXP);
SEXP R_bcDecode(SEXP);

SEXP R_PromiseExpr(SEXP);
SEXP R_ClosureExpr(SEXP);
#define PREXPR(e) R_PromiseExpr(e)
#define BODY_EXPR(e) R_ClosureExpr(e)
```

### Weak references (`WEAKREFSXP`)

```cpp
SEXP R_MakeWeakRef(SEXP key, SEXP val, SEXP fin, Rboolean onexit);
SEXP R_MakeWeakRefC(SEXP key, SEXP val, R_CFinalizer_t fin, Rboolean onexit);
SEXP R_WeakRefKey(SEXP w);
SEXP R_WeakRefValue(SEXP w);
void R_RunWeakRefFinalizer(SEXP w);
```


## Sorting

```cpp
/* dummy renamed to II to avoid problems with g++ on Solaris */
void R_qsort    (double *v,         size_t i, size_t j);
void R_qsort_I  (double *v, int *II, int i, int j);
void R_qsort_int  (int *iv,         size_t i, size_t j);
void R_qsort_int_I(int *iv, int *II, int i, int j);

#define revsort       Rf_revsort
#define iPsort        Rf_iPsort
#define rPsort        Rf_rPsort
#define cPsort        Rf_cPsort


/* ../../main/sort.c : */
void	R_isort(int*, int);
void	R_rsort(double*, int);
void	R_csort(Rcomplex*, int);
void    rsort_with_index(double *, int *, int);
void	revsort(double*, int*, int);/* reverse; sort i[] alongside */
void	iPsort(int*,    int, int);
void	rPsort(double*, int, int);
void	cPsort(Rcomplex*, int, int);

/* C version of R's  indx <- order(..., na.last, decreasing) :
e.g.  arglist = Rf_lang2(x,y)  or  Rf_lang3(x,y,z) */
void R_orderVector (int *indx, int n, SEXP arglist, Rboolean nalast, Rboolean decreasing);
// C version of R's  indx <- order(x, na.last, decreasing) :
void R_orderVector1(int *indx, int n, SEXP x,       Rboolean nalast, Rboolean decreasing);


```

## Misc

```cpp
SEXP Rf_allocSExp(SEXPTYPE);
R_xlen_t Rf_any_duplicated(SEXP x, Rboolean from_last);
R_xlen_t Rf_any_duplicated3(SEXP x, SEXP incomp, Rboolean from_last);
SEXP Rf_applyClosure(SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP Rf_cons(SEXP, SEXP);
int Rf_countContexts(int, int);
SEXP Rf_CreateTag(SEXP);
SEXP Rf_GetOption(SEXP, SEXP); /* pre-2.13.0 compatibility */
SEXP Rf_GetOption1(SEXP);
int Rf_GetOptionDigits(void);
int Rf_GetOptionWidth(void);
void Rf_gsetVar(SEXP, SEXP, SEXP);
bSEXP Rf_installS3Signature(const char *, const char *);
Rboolean Rf_isFree(SEXP);
Rboolean Rf_isUnsorted(SEXP, Rboolean);
SEXP Rf_namesgets(SEXP, SEXP);
Rboolean Rf_pmatch(SEXP, SEXP, Rboolean);
Rboolean Rf_psmatch(const char *, const char *, Rboolean);
void Rf_readS3VarsFromFrame(SEXP, SEXP*, SEXP*, SEXP*, SEXP*, SEXP*, SEXP*);
void Rf_setSVector(SEXP*, int, SEXP);
void Rf_setVar(SEXP, SEXP, SEXP);
SEXP Rf_substitute(SEXP,SEXP);

// match vectors
SEXP Rf_match(SEXP itable, SEXP ix, int no_match);
SEXP Rf_matchE(SEXP itable, SEXP ix, int no_match, SEXP env);

// env is used to look up as.character when translating POSIXlt
// seems unlikely you'd ever need to use this variant

/* Shutdown actions */
void R_dot_Last(void);		/* in main.c */
void R_RunExitFinalizers(void);	/* in memory.c */

/* Replacements for popen and system */
#ifdef HAVE_POPEN
FILE *R_popen(const char *, const char *);
#endif
int R_system(const char *);

/* R_compute_identical:  C version of identical() function
The third arg to R_compute_identical() consists of bitmapped flags for non-default options:
currently the first 4 default to TRUE, so the flag is set for FALSE values:
1 = !NUM_EQ
2 = !SINGLE_NA
4 = !ATTR_AS_SET
8 = !IGNORE_BYTECODE
16 = !IGNORE_ENV
Default from R's default: 15
*/
Rboolean R_compute_identical(SEXP, SEXP, int);

Rboolean Rf_conformable(SEXP, SEXP);
SEXP	 Rf_elt(SEXP, int);
Rboolean Rf_isTs(SEXP);
Rboolean Rf_isUserBinop(SEXP);
SEXP	 Rf_lastElt(SEXP);
SEXP	 Rf_lcons(SEXP, SEXP);
int	 Rf_stringPositionTr(SEXP, const char *);
SEXP R_FixupRHS(SEXP x, SEXP y);

#define IndexWidth    Rf_IndexWidth

#define setIVector    Rf_setIVector
void	setIVector(int*, int, int);
#define setRVector    Rf_setRVector
void	setRVector(double*, int, double);

/* These two are guaranteed to use '.' as the decimal point,
and to accept "NA".
*/
double R_atof(const char *str);
double R_strtod(const char *c, char **end);

char *R_tmpnam(const char *prefix, const char *tempdir);
char *R_tmpnam2(const char *prefix, const char *tempdir, const char *fileext);

void R_CheckUserInterrupt(void);
void R_CheckStack(void);
void R_CheckStack2(size_t);

/* ../../appl/interv.c: also in Applic.h */
int findInterval(double *xt, int n, double x,
  Rboolean rightmost_closed,  Rboolean all_inside, int ilo,
  int *mflag);

void find_interv_vec(double *xt, int *n,	double *x,   int *nx,
  int *rightmost_closed, int *all_inside, int *indx);

/* ../../appl/maxcol.c: also in Applic.h */
void R_max_col(double *matrix, int *nr, int *nc, int *maxes, int *ties_meth);
```

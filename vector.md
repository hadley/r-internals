# Vectors

* Logical (`LGLSXP`)
* Integer (`INTSXP`)
* Double  (`REALSXP`)
* Complex (`CPLXSXP`)
* String  (`STRINGSXP`)
* Lists   (`VECSXP`)
* Raw     (`RAWSXP`)
* Expression (`EXPRSXP`)

```cpp
typedef unsigned char Rbyte;

typedef enum { 
  FALSE = 0, 
  TRUE 
} Rboolean;

typedef struct {
  double r;
  double i;
} Rcomplex;
```

## Test

```cpp
Rboolean Rf_isVector(SEXP);
Rboolean Rf_isVectorAtomic(SEXP);
Rboolean Rf_isVectorList(SEXP);
Rboolean Rf_isVectorizable(SEXP);
Rboolean Rf_isNumber(SEXP);
Rboolean Rf_isNumeric(SEXP);

Rboolean (Rf_isLogical)(SEXP s);
Rboolean (Rf_isReal)(SEXP s);
Rboolean (Rf_isComplex)(SEXP s);
Rboolean (Rf_isExpression)(SEXP s);
Rboolean (Rf_isString)(SEXP s);
Rboolean Rf_isNewList(SEXP);
Rboolean Rf_isInteger(SEXP);

#define IS_SCALAR(x, type) (TYPEOF(x) == (type) && XLENGTH(x) == 1)
#define IS_SIMPLE_SCALAR(x, type) \
(IS_SCALAR(x, type) && ATTRIB(x) == R_NilValue)

```

## Get/set

```cpp
SEXP (STRING_ELT)(SEXP x, R_xlen_t i);
void SET_STRING_ELT(SEXP x, R_xlen_t i, SEXP v);

int  *(LOGICAL)(SEXP x);
int  *(INTEGER)(SEXP x);
Rbyte *(RAW)(SEXP x);
double *(REAL)(SEXP x);
Rcomplex *(COMPLEX)(SEXP x);
SEXP (VECTOR_ELT)(SEXP x, R_xlen_t i);
SEXP SET_VECTOR_ELT(SEXP x, R_xlen_t i, SEXP v);
SEXP *(STRING_PTR)(SEXP x);
SEXP * NORET (VECTOR_PTR)(SEXP x);


```

## Missing/special values vlaues

```cpp
double R_NaN;		  /* IEEE NaN */
double R_PosInf;	/* IEEE Inf */
double R_NegInf;	/* IEEE -Inf */
double R_NaReal;	/* NA_REAL: IEEE */
int	 R_NaInt;	    /* NA_INTEGER:= INT_MIN currently */

#define NA_LOGICAL	R_NaInt
#define NA_INTEGER	R_NaInt
#define NA_REAL		R_NaReal

int R_IsNA(double);		  /* True for R's NA only */
int R_IsNaN(double);		/* True for special NaN, *not* for NA */
int R_finite(double);		/* True if none of NA, NaN, +/-Inf */
```


## Create

```cpp
SEXP	 Rf_mkNamed(SEXPTYPE, const char **);
SEXP Rf_allocVector(SEXPTYPE, R_xlen_t);
SEXP Rf_allocVector3(SEXPTYPE, R_xlen_t, R_allocator_t*);

SEXP	 Rf_ScalarComplex(Rcomplex);
SEXP	 Rf_ScalarInteger(int);
SEXP	 Rf_ScalarLogical(int);
SEXP	 Rf_ScalarRaw(Rbyte);
SEXP	 Rf_ScalarReal(double);
```

## Coerce

```cpp
int Rf_asLogical(SEXP x);
int Rf_asInteger(SEXP x);
double Rf_asReal(SEXP x);
Rcomplex Rf_asComplex(SEXP x);

SEXP Rf_coerceVector(SEXP, SEXPTYPE);
void Rf_copyVector(SEXP, SEXP);
```

## Internals

```cpp
/* type for length of (standard, not long) vectors etc */
typedef int R_len_t;
#define R_LEN_T_MAX INT_MAX

R_len_t  Rf_length(SEXP);
SEXP Rf_lengthgets(SEXP, R_len_t);
SEXP Rf_xlengthgets(SEXP, R_xlen_t);
R_xlen_t  Rf_xlength(SEXP);
```

```cpp
int  (LENGTH)(SEXP x);
int  (TRUELENGTH)(SEXP x);
void (SETLENGTH)(SEXP x, int v);
void (SET_TRUELENGTH)(SEXP x, int v);
R_xlen_t  (XLENGTH)(SEXP x);
R_xlen_t  (XTRUELENGTH)(SEXP x);
int  (IS_LONG_VEC)(SEXP x);
```

## Helpers

```cpp
// returns LGLSXP same length as x
SEXP Rf_duplicated(SEXP x, Rboolean from_last);
```

# Variants

## Arrays

```cpp
Rboolean Rf_isArray(SEXP);

SEXP Rf_alloc3DArray(SEXPTYPE, int, int, int);
SEXP Rf_allocArray(SEXPTYPE, SEXP);

SEXP Rf_dimgets(SEXP, SEXP);
SEXP Rf_dimnamesgets(SEXP, SEXP);
SEXP Rf_DropDims(SEXP);

SEXP Rf_GetArrayDimnames(SEXP);
void Rf_GetMatrixDimnames(SEXP, SEXP*, SEXP*, const char**, const char**);

SEXP Rf_arraySubscript(int, SEXP, SEXP, SEXP (*)(SEXP,SEXP),SEXP (*)(S EXP, int), SEXP);
```

### Matrices

```cpp
SEXP Rf_allocMatrix(SEXPTYPE, int, int);
SEXP Rf_GetColNames(SEXP);
SEXP Rf_GetRowNames(SEXP);
int Rf_ncols(SEXP);
int Rf_nrows(SEXP);
Rboolean Rf_isMatrix(SEXP);
void Rf_copyMatrix(SEXP, SEXP, Rboolean);
void Rf_copyListMatrix(SEXP, SEXP, Rboolean);
```

### Factors

```cpp
Rboolean Rf_isFactor(SEXP);
int	 Rf_nlevels(SEXP);
Rboolean Rf_isOrdered(SEXP);
Rboolean Rf_isUnordered(SEXP);

// Coerce into character vector
SEXP Rf_asCharacterFactor(SEXP x);
```

### Data frame

```cpp
Rboolean Rf_isFrame(SEXP);
```


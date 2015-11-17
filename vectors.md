# Vectors

There are seven vector types in R:

* Logical (`LGLSXP`), contains `Rboolean`.

* Integer (`INTSXP`), contains `int`.

* Double  (`REALSXP`), contains `double`.

* Complex (`CPLXSXP`), contains `Rcomplex`.

* String  (`STRINGSXP`), contains `CHARSXP`.

* Lists   (`VECSXP`), contains any other sexp. __Beware:__ Lists are `VECSXP`s
  not `LISTSXP`s. This is because early implementations of lists were Lisp-like 
  linked lists, which are now called as "[pairlists](pairlists.md)".

* Raw     (`RAWSXP`), contains `Rbyte`.

* Expression (`EXPRSXP`), contains `LANGSXP`, `SYMSXP` or a vector 
  (except for a list).

Three of those vectors are built on top of simple types defined by R:

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

## Length

After the SEXPTYPE, the most important property of a vector is it's length. Historically, R vectors were limited to length $2 ^ 31 -  1$. Still most vectors are shorter than this, so you can use an `int` based interface:

```cpp
typedef int R_len_t;
// Get the length of a vector
R_len_t Rf_length(SEXP x);
// Set the length of a vector by creating a new vector of extended length
// [[SEXP creator]]
SEXP Rf_lengthgets(SEXP x, R_len_t n);
```

As of R 3.0.0, R vectors can have length up to $2 ^ 64 - 1$. If you want your code to be as general as possible, you should instead use the `R_xlen_t`based interface:

```cpp
// ptrdiff_t is the type of the result of subtracting two pointers, and
// is usually 8 bytes (like a double)
typedef ptrdiff_t R_xlen_t;
R_xlen_t Rf_xlength(SEXP x);
SEXP Rf_xlengthgets(SEXP x, R_xlen_t n);
```

These functions also have uppercase variants - in base R code these are implemented as macros for efficiency.

```cpp
int  LENGTH(SEXP x);
void SETLENGTH(SEXP x, int v);
R_xlen_t XLENGTH(SEXP x);
int IS_LONG_VEC(SEXP x);
```

## Create

The most common way to create a new vector is with `Rf_allocVector()`:

```cpp
// [[SEXP creator]]
SEXP Rf_allocVector(SEXPTYPE type, R_xlen_t n);
```
If you want to create a vector of length 1 from the corresponding C type, use:

```cpp
// [[SEXP creator]]
SEXP Rf_ScalarLogical(int x);

// [[SEXP creator]]
SEXP Rf_ScalarInteger(int x);

// [[SEXP creator]]
SEXP Rf_ScalarReal(double x);

// [[SEXP creator]]
SEXP Rf_ScalarComplex(Rcomplex x);

// [[SEXP creator]]
SEXP Rf_ScalarRaw(Rbyte x);

// Makes STRSXP from CHARSXP
// [[SEXP creator]]
SEXP Rf_ScalarString(SEXP);
// Makes STRSXP from C string
// [[SEXP creator]]
SEXP Rf_mkString(const char*);
```

(Note, as with all SEXP creation functions you must `Rf_protect()` the result of any of these calls unless you're immediately assigning it into an already protected object)

Alternatively you can coerce from an existing vector:

```cpp
// [[SEXP creator]]
// Error: if can't coerce between TYPEOF(x) and newtype.
SEXP Rf_coerceVector(SEXP x, SEXPTYPE newtype);
```

There are two rarer variants:

```cpp
// Given a null-terminated array of const char*'s, create an element
// of that length, and initialise a character vector of names
// [[SEXP creator]]
SEXP Rf_mkNamed(SEXPTYPE type, const char ** names);

// Create a vector with a custom memory allocator
typedef void *(*custom_alloc_t)(R_allocator_t *allocator, size_t);
typedef void  (*custom_free_t)(R_allocator_t *allocator, void *);
typedef struct R_allocator {
    custom_alloc_t mem_alloc; /* malloc equivalent */
    custom_free_t  mem_free;  /* free equivalent */
    void *res;                /* reserved (maybe for copy) - must be NULL */
    void *data;               /* custom data for the allocator implementation */
} R_allocator_t;
// [[SEXP creator]]
SEXP Rf_allocVector3(SEXPTYPE type, R_xlen_t type, R_allocator_t* allocator);
```

## Get and set values

The simple types are wrappers around an array of C values, so you get and set by using a helper that returns a pointer:

```cpp
int*      LOGICAL(SEXP x);
int*      INTEGER(SEXP x);
double*   REAL(SEXP x);
Rcomplex* COMPLEX(SEXP x);
Rbyte*    RAW(SEXP x);
```

__NB__: these functions are all upper case and don't start with `Rf_`.

When working with longer vectors, there's typically a performance advantage to saving the index and reusing. For example, instead of:

```cpp
for (int i = 0; i < n; ++i) {
  INTEGER(x)[i] = INTEGER(x)[i] * 2;
}
```

Do:

```cpp
int* px = INTEGER(x);
for (int i = 0; i < n; ++i) {
  px[i] = px[i] * 2;
}
```

Strings and lists don't map to simple C structs, so instead have a pair of functions to get and set values.

```cpp
// Returns a CHARSXP
SEXP STRING_ELT(SEXP x, R_xlen_t i);
void SET_STRING_ELT(SEXP x, R_xlen_t i, SEXP v);

// Returns potentially any SEXPTYPE
SEXP VECTOR_ELT(SEXP x, R_xlen_t i);
SEXP SET_VECTOR_ELT(SEXP x, R_xlen_t i, SEXP v);
```

(There is `STRING_PTR()` which is used in a hanful of places in the R source; `VECTOR_PTR()` is a deprecated interface that now throws an error.)

### Scalars

There are a few helpers that extract the first value, coercing the vector as necessary:

```cpp
int Rf_asLogical(SEXP x);
int Rf_asInteger(SEXP x);
double Rf_asReal(SEXP x);
Rcomplex Rf_asComplex(SEXP x);
```

### Special values

Integer, logical, and character vectors have special sentinels for missing values: 

```cpp
#define NA_LOGICAL	R_NaInt
#define NA_INTEGER	R_NaInt
int	 R_NaInt;	    /* NA_INTEGER:= INT_MIN currently */
```

Missing values are somewhat more complicated for `REALSXP` because there is an existing protocol for missing values defined by the floating point standard ([IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point)). In doubles, an `NA` is `NaN` with a special bit pattern (the lowest word is 1954, the year Ross Ihaka was born), and there are other special values for positive and negative infinity. Use `ISNA()`, `ISNAN()`, and `!R_FINITE()` macros to check for missing, NaN, or non-finite values. Use the constants `NA_REAL`, `R_NaN`, `R_PosInf`, and `R_NegInf` to set those values.

```cpp
// Provided for cross-platform safety
double R_NaN;
double R_PosInf;
double R_NegInf;

double R_NaReal; // NaN used to represent NA in R
#define NA_REAL		R_NaReal

int R_IsNA(double);
int R_IsNaN(double);
int R_finite(double);	 // not NA, NaN, Inf, or -Inf
```

## Test

A number of helpers let you test if an SEXP is of the given type:

```cpp
Rboolean Rf_isLogical(SEXP s);
Rboolean Rf_isInteger(SEXP);
Rboolean Rf_isReal(SEXP s);
Rboolean Rf_isComplex(SEXP s);
Rboolean Rf_isString(SEXP s);
Rboolean Rf_isExpression)(SEXP s);
```

__NB__: there's no function to test for `RAWSXP` or `VECSXP`; you use must use `TYPEOF(x) == RAWSXP`, or `TYPEOF(x) == VECSXP`. `isList()` tests if the object is a pairlist.

A handful of functions test for frequently used combinations of variable types:

```
Rboolean Rf_isNewList(SEXP); // NILSXP, VECSXP
Rboolean Rf_isVectorAtomic(SEXP); // LGLSXP, INTSXP, REALSXP, CPLXSXP, STRSXP, RAWSXP
Rboolean Rf_isVectorList(SEXP); // LISTSXP, EXPRSXP
Rboolean Rf_isVector(SEXP); // isVectorAtomic(x) || isVectorList()
Rboolean Rf_isNumber(SEXP); // INTSXP (but not factor), LGLSXP, REALSXP, CPLXSXP
Rboolean Rf_isNumeric(SEXP); // INTSXP (but not factor), REALSXP, CPLXSXP
```

__NB__: these are not always consistent with their R equivalents. For example, `Rf_isVectorAtomic(R_NilValue)` is false, but `is.atomic(NULL)` is true; `Rf_isNewList(R_NilValue)` is true; but `is.list(NULL)` is false. Because of this confusion, I recommend writing your own wrapper around `TYPEOF(x)`.

__NB__: Be careful when checking whether whether an R object is an integer vector. Internally, `factor`s are also `INTSXP`s so `TYPEOF(x) == INTSXP` would accept both vanilla integer vectors and factors. (Prefer using `Rf_isInteger()` and `Rf_isFactor()` for these cases.)

__NB__: It is somewhat strange that `Rf_isNewList()` returns `TRUE` for `R_NilValue`, given that `R_NilValue` is just an empty pairlist (ie, `NULL` and `pairlist()` are identical).

# Variants

The R API provides some support for the various data structures built on top of vectors.

## Arrays

Arrays are vectors with a dim attribute:

```cpp
Rboolean Rf_isArray(SEXP x);

SEXP Rf_alloc3DArray(SEXPTYPE type, int, int, int);
SEXP Rf_allocArray(SEXPTYPE type, SEXP);

SEXP Rf_GetArrayDimnames(SEXP);
// [[SEXP creator]]
SEXP Rf_dimgets(SEXP, SEXP);
// [[SEXP creator]]
SEXP Rf_dimnamesgets(SEXP, SEXP);

SEXP Rf_DropDims(SEXP);


SEXP Rf_arraySubscript(int, SEXP, SEXP, SEXP (*)(SEXP,SEXP),SEXP (*)(S EXP, int), SEXP);
```

### Matrices

Matrices are a special case of arrays; those with 2 dimensions:

```cpp
SEXP Rf_allocMatrix(SEXPTYPE type, int nrow, int nrow);
Rboolean Rf_isMatrix(SEXP);
SEXP Rf_GetColNames(SEXP x);
SEXP Rf_GetRowNames(SEXP x);

// rl, cl are output parameters: row and col names as sexps
// rownames and colnames are output parameters 
void Rf_GetMatrixDimnames(SEXP x, SEXP* rl, SEXP* cl, 
  const char** rownames, const char** colnames);

int Rf_ncols(SEXP x);
int Rf_nrows(SEXP x);

void Rf_copyMatrix(SEXP source, SEXP target, Rboolean byrow);
void Rf_copyListMatrix(SEXP source, SEXP target, Rboolean byrow);
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

## Miscellaneous helpers

```cpp
// Copies from source to target, recylcing as necessary.
void Rf_copyVector(SEXP source, SEXP target);
// use Rf_duplicate if you simply want to duplicate a vector

// Extract tail of a STRSXP
// [[SEXP creator]]
SEXP Rf_stringSuffix(SEXP string, int fromIndex);
```

A couple of macros aid in testing if an object is a "scalar" (a vector of length 1):

```cpp
#define IS_SCALAR(x, type) (TYPEOF(x) == (type) && XLENGTH(x) == 1)
#define IS_SIMPLE_SCALAR(x, type) (IS_SCALAR(x, type) && ATTRIB(x) == R_NilValue)

// Checks to see if a list can be converted into a vector, i.e. each element
// of a list or pairlist is a vector of length 0 or 1
Rboolean Rf_isVectorizable(SEXP);

// returns LGLSXP same length as x
// [[SEXP creator]]
SEXP Rf_duplicated(SEXP x, Rboolean from_last);
```

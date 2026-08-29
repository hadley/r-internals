# 5  Vectors

R has six atomic vector types, plus two vector types whose elements are themselves SEXPs:

- Logical (`LGLSXP`): `int`, using `0`/`1` for false/true and `NA_LOGICAL` for missing.
- Integer (`INTSXP`): `int`, with `NA_INTEGER` for missing.
- Double (`REALSXP`): `double`.
- Complex (`CPLXSXP`): `Rcomplex`.
- Raw (`RAWSXP`): `Rbyte`.
- String (`STRSXP`): elements are `CHARSXP`s; see [Strings](strings.llms.md).
- List (`VECSXP`): elements are arbitrary SEXPs. Beware: lists are `VECSXP`s, not `LISTSXP`s — early R lists were Lisp-like linked lists, which survive as [pairlists](pairlists.llms.md).
- Expression (`EXPRSXP`): like a list, but intended to hold language objects.

Two supporting C types:

``` c
typedef unsigned char Rbyte;

typedef struct {
  double r;
  double i;
} Rcomplex;
```

## 5.1 Length

After the SEXPTYPE, the most important property of a vector is its length. There are two length types:

``` c
typedef int R_len_t;          // limited to 2^31 - 1
typedef ptrdiff_t R_xlen_t;   // 64-bit on all supported platforms
```

New code should always use `R_xlen_t` for vector lengths and indices. It costs nothing on 64-bit platforms, and the alternative fails badly: an `int` length silently overflows if a user passes a vector longer than \\2^{31}-1\\. Reserve `int` for things that are inherently small, like the number of arguments to a call. You’ll still need occasional casts where older parts of the API take or return `int`.

Vectors also carry a hidden “truelength” field used for over-allocation: since R 3.4.0, assigning past the end of a vector grows the allocation by ~5% and records the capacity in truelength, so repeated appends can extend the vector in place. The experimental resizable-vector API (`R_allocResizableVector()`/`R_resizeVector()`) builds on the same mechanism.

### 5.1.1 `Rf_xlength()` (`Rf_length()`)

Get the length of a vector.

``` c
R_xlen_t Rf_xlength(SEXP x);
R_len_t Rf_length(SEXP x);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `length()`

- `x`: any vector.

`Rf_xlength()` uses `R_xlen_t` and supports long vectors (length up to 2^64 - 1); `Rf_length()` is limited to `int` (2^31 - 1). Also works on pairlists, where it is O(n).

**See also:** [`Rf_lengthgets()`](#Rf_lengthgets), [`LENGTH()`](#LENGTH)

### 5.1.2 `Rf_lengthgets()` (`Rf_xlengthgets()`)

Set the length of a vector by creating a new vector of extended length.

``` c
SEXP Rf_lengthgets(SEXP x, R_len_t n);
SEXP Rf_xlengthgets(SEXP x, R_xlen_t n);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `length<-`

- `x`: a vector.
- `n`: the new length.

`Rf_xlengthgets()` is the `R_xlen_t`-based variant for long vectors.

**See also:** [`Rf_xlength()`](#Rf_xlength), [`SETLENGTH()`](#SETLENGTH)

### 5.1.3 `LENGTH()` (`XLENGTH()`)

Get the length of a vector.

``` c
int LENGTH(SEXP x);
R_xlen_t XLENGTH(SEXP x);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `length()`

- `x`: any vector.

Uppercase variants of `Rf_length()`/`Rf_xlength()`, implemented as macros in base R for efficiency.

**See also:** [`Rf_xlength()`](#Rf_xlength), [`SETLENGTH()`](#SETLENGTH)

### 5.1.4 `IS_LONG_VEC()`

Test whether a vector is a long vector.

``` c
int IS_LONG_VEC(SEXP x);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

- `x`: any vector.

True when a vector’s length exceeds the `int`-based limit of 2^31 - 1.

**See also:** [`Rf_xlength()`](#Rf_xlength)

## 5.2 Create

The most common way to create a new vector is `Rf_allocVector()`. As with all SEXP creation functions, you must `PROTECT()` the result unless you immediately assign it into an already-protected object. Alternatively, you can coerce an existing vector with `Rf_coerceVector()`.

To create a vector of length 1 from a C value, use the scalar helpers — they’re shorter and clearer than allocating and assigning separately:

``` c
SEXP x = PROTECT(Rf_ScalarReal(3.14));
// equivalent to:
// SEXP x = PROTECT(Rf_allocVector(REALSXP, 1));
// REAL(x)[0] = 3.14;
UNPROTECT(1);
```

`Rf_mkNamed()` creates a named vector in one call. This template creates a list holding two objects `x` and `y` named `xname` and `yname`:

``` c
// array of names; note the terminating empty string
const char *names[] = {"xname", "yname", ""};
SEXP list = PROTECT(Rf_mkNamed(VECSXP, names));  // creates a list of length 2
SET_VECTOR_ELT(list, 0, x); // x and y are arbitrary SEXPs
SET_VECTOR_ELT(list, 1, y);
UNPROTECT(1);
```

Finally, `Rf_allocVector3()` lets you supply a custom allocator:

``` c
typedef void *(*custom_alloc_t)(R_allocator_t *allocator, size_t);
typedef void  (*custom_free_t)(R_allocator_t *allocator, void *);
typedef struct R_allocator {
    custom_alloc_t mem_alloc; /* malloc equivalent */
    custom_free_t  mem_free;  /* free equivalent */
    void *res;                /* reserved (maybe for copy) - must be NULL */
    void *data;               /* custom data for the allocator implementation */
} R_allocator_t;
```

### 5.2.1 `Rf_allocVector()`

Create a new vector of the given type and length.

``` c
SEXP Rf_allocVector(SEXPTYPE type, R_xlen_t n);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `vector()`

- `type`: any vector `SEXPTYPE` (`LGLSXP`, `INTSXP`, `REALSXP`, `CPLXSXP`, `STRSXP`, `VECSXP`, `RAWSXP`, `EXPRSXP`).
- `n`: number of elements; `R_xlen_t` supports long vectors on 64-bit platforms.

Atomic vector contents are uninitialised; `VECSXP`/`EXPRSXP` elements are `R_NilValue` and `STRSXP` elements are `""`. Attributes are unset.

``` c
SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
```

**See also:** [`Rf_allocVector3()`](#Rf_allocVector3), [`Rf_coerceVector()`](#Rf_coerceVector)

### 5.2.2 `Rf_ScalarLogical()` (`Rf_ScalarInteger()`, `Rf_ScalarReal()`, `Rf_ScalarComplex()`, `Rf_ScalarRaw()`)

Create a vector of length 1 from the corresponding C type.

``` c
SEXP Rf_ScalarLogical(int x);
SEXP Rf_ScalarInteger(int x);
SEXP Rf_ScalarReal(double x);
SEXP Rf_ScalarComplex(Rcomplex x);
SEXP Rf_ScalarRaw(Rbyte x);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

- `x`: the C value to wrap.

For strings, use [`Rf_ScalarString()`](#Rf_ScalarString) or [`Rf_mkString()`](#Rf_mkString) instead. `Rf_ScalarLogical()` returns cached singletons and never allocates; the other `Rf_Scalar*()` variants always allocate.

**See also:** [`Rf_allocVector()`](#Rf_allocVector), [`Rf_ScalarString()`](#Rf_ScalarString), [`Rf_mkString()`](#Rf_mkString)

### 5.2.3 `Rf_coerceVector()`

Coerce an existing vector to a different type.

``` c
SEXP Rf_coerceVector(SEXP x, SEXPTYPE newtype);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `as.vector()`

- `x`: a vector.
- `newtype`: the `SEXPTYPE` to coerce to.

Errors if it can’t coerce between `TYPEOF(x)` and `newtype`.

**See also:** [`Rf_allocVector()`](#Rf_allocVector), [`Rf_asLogical()`](#Rf_asLogical)

### 5.2.4 `Rf_mkNamed()`

Create a named vector of the given type.

``` c
SEXP Rf_mkNamed(SEXPTYPE type, const char **names);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `setNames()`

- `type`: any vector `SEXPTYPE`.
- `names`: a null-terminated array of `const char*` names.

The vector’s length matches the number of names supplied, and its names attribute is set from them.

``` c
// array of names; note the null string
const char *names[] = {"xname", "yname", ""};
SEXP list = PROTECT(Rf_mkNamed(VECSXP, names));  // creates a list of length 2
SET_VECTOR_ELT(list, 0, x); // x and y are arbitrary SEXPs
SET_VECTOR_ELT(list, 1, y);
UNPROTECT(1);
```

**See also:** [`Rf_allocVector()`](#Rf_allocVector)

### 5.2.5 `Rf_allocVector3()`

Create a new vector using a custom allocator.

``` c
SEXP Rf_allocVector3(SEXPTYPE type, R_xlen_t n, R_allocator_t *allocator);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

Like `Rf_allocVector()`, but memory for the data payload comes from `allocator`; pass `NULL` for plain `Rf_allocVector()` behaviour. Rarely needed in package code.

**See also:** [`Rf_allocVector()`](#Rf_allocVector)

## 5.3 Resizable vectors

R 4.6.0 added an **experimental** API for vectors that can grow in place: allocate with a maximum length, then resize without copying. This replaces the non-API `SETLENGTH()`/`SET_TRUELENGTH()` idiom; the interface may change in future R releases.

### 5.3.1 `R_allocResizableVector()` (`R_duplicateAsResizable()`, `R_resizeVector()`, `R_isResizable()`, `R_maxLength()`)

Create and resize vectors that can grow in place.

``` c
SEXP R_allocResizableVector(SEXPTYPE type, R_xlen_t maxlen);
SEXP R_duplicateAsResizable(SEXP x);
void R_resizeVector(SEXP x, R_xlen_t newlen);
bool R_isResizable(SEXP x);
R_xlen_t R_maxLength(SEXP x);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** 4.6.0 · **R equivalent:** —

- `maxlen`: maximum length the vector can grow to.
- `newlen`: new length, at most `maxlen`.

A resizable vector allocates `maxlen` up front and can be resized in place with `R_resizeVector()` — the API replacement for the non-API `SETLENGTH()`/`SET_TRUELENGTH()` idiom. Experimental: the interface may change in future R releases.

**See also:** [`Rf_allocVector()`](#Rf_allocVector)

## 5.4 Get and set values

The atomic types wrap a C array, so you get and set values through a helper that returns a pointer to the underlying data. These helpers are all uppercase and don’t start with `Rf_`.

When working with longer vectors, cache the pointer instead of calling the accessor on every iteration. Instead of:

``` c
for (R_xlen_t i = 0; i < n; ++i) {
  INTEGER(x)[i] = INTEGER(x)[i] * 2;
}
```

do:

``` c
int* px = INTEGER(x);
for (R_xlen_t i = 0; i < n; ++i) {
  px[i] = px[i] * 2;
}
```

Strings and lists don’t map to simple C arrays, so they have paired get/set functions (`STRING_ELT()`/`SET_STRING_ELT()`, `VECTOR_ELT()`/`SET_VECTOR_ELT()`). (`STRING_PTR()` exists but is used only in a handful of places in R itself; `VECTOR_PTR()` is a deprecated interface that now throws an error.)

### 5.4.1 `LOGICAL()` (`INTEGER()`, `REAL()`, `COMPLEX()`, `RAW()`)

Get a pointer to the underlying C array of an atomic vector.

``` c
int*      LOGICAL(SEXP x);
int*      INTEGER(SEXP x);
double*   REAL(SEXP x);
Rcomplex* COMPLEX(SEXP x);
Rbyte*    RAW(SEXP x);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

- `x`: a vector of the corresponding type.

For long vectors, cache the returned pointer and reuse it rather than calling the accessor on every iteration.

``` c
int* px = INTEGER(x);
for (int i = 0; i < n; ++i) {
  px[i] = px[i] * 2;
}
```

**See also:** [`STRING_ELT()`](#STRING_ELT), [`VECTOR_ELT()`](#VECTOR_ELT)

### 5.4.2 `STRING_ELT()` (`SET_STRING_ELT()`)

Get or set a single element of a character vector.

``` c
SEXP STRING_ELT(SEXP x, R_xlen_t i);
void SET_STRING_ELT(SEXP x, R_xlen_t i, SEXP v);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** can throw · **Since:** — · **R equivalent:** —

- `x`: a `STRSXP`.
- `i`: zero-based element index.
- `v`: the `CHARSXP` to set.

`STRING_ELT()` returns a `CHARSXP`, not an ordinary `SEXP` value; strings use a pair of accessor functions rather than a plain C array.

**See also:** [`VECTOR_ELT()`](#VECTOR_ELT), [`STRING_PTR()`](#STRING_PTR)

### 5.4.3 `VECTOR_ELT()` (`SET_VECTOR_ELT()`)

Get or set a single element of a list.

``` c
SEXP VECTOR_ELT(SEXP x, R_xlen_t i);
SEXP SET_VECTOR_ELT(SEXP x, R_xlen_t i, SEXP v);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** can throw · **Since:** — · **R equivalent:** —

- `x`: a `VECSXP`.
- `i`: zero-based element index.
- `v`: the value to set.

`VECTOR_ELT()` may return any `SEXPTYPE`; lists use a pair of accessor functions rather than a plain C array.

**See also:** [`STRING_ELT()`](#STRING_ELT), [`VECTOR_PTR()`](#VECTOR_PTR)

### 5.4.4 `STRING_PTR_RO()` (`VECTOR_PTR_RO()`)

Get read-only access to the elements of a character or list vector.

``` c
const SEXP *STRING_PTR_RO(SEXP x);
const SEXP *VECTOR_PTR_RO(SEXP x);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** 4.5.0 · **R equivalent:** —

The read-only analogues of `STRING_PTR()`/`VECTOR_PTR()`; use them when you only read elements so ALTREP and future representations aren’t forced to materialize a writable array.

**See also:** [`STRING_ELT()`](#STRING_ELT)

### 5.4.5 `DATAPTR_RO()` (`DATAPTR()`)

Get an untyped pointer to a vector’s data.

``` c
const void *(DATAPTR_RO)(SEXP x);
void *(DATAPTR)(SEXP x);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

- `x`: any vector.

Prefer the typed accessors (`REAL()`, `INTEGER_RO()`, …), which check the vector type. `DATAPTR()` gives write access; `DATAPTR_RO()` is read-only.

**See also:** [`LOGICAL()`](#LOGICAL), [`INTEGER_RO()`](#INTEGER_RO)

### 5.4.6 `INTEGER_RO()` (`LOGICAL_RO()`, `REAL_RO()`, `COMPLEX_RO()`, `RAW_RO()`)

Get a read-only pointer to the underlying C array.

``` c
const int*      (INTEGER_RO)(SEXP x);
const int*      (LOGICAL_RO)(SEXP x);
const double*   (REAL_RO)(SEXP x);
const Rcomplex* (COMPLEX_RO)(SEXP x);
const Rbyte*    (RAW_RO)(SEXP x);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

- `x`: a vector of the corresponding type.

Read-only variants of `INTEGER()` etc. Use them when you only read: the `const` pointer catches accidental writes, and ALTREP vectors can avoid materialising a writable copy.

**See also:** [`LOGICAL()`](#LOGICAL), [`DATAPTR_RO()`](#DATAPTR_RO)

### 5.4.7 `INTEGER_ELT()` (`LOGICAL_ELT()`, `REAL_ELT()`, `COMPLEX_ELT()`, `RAW_ELT()`, `SET_INTEGER_ELT()`, `SET_LOGICAL_ELT()`, `SET_REAL_ELT()`, `SET_COMPLEX_ELT()`, `SET_RAW_ELT()`)

Get or set a single element of an atomic vector.

``` c
int      (INTEGER_ELT)(SEXP x, R_xlen_t i);
int      (LOGICAL_ELT)(SEXP x, R_xlen_t i);
double   (REAL_ELT)(SEXP x, R_xlen_t i);
Rcomplex (COMPLEX_ELT)(SEXP x, R_xlen_t i);
Rbyte    (RAW_ELT)(SEXP x, R_xlen_t i);
void SET_INTEGER_ELT(SEXP x, R_xlen_t i, int v);
void SET_LOGICAL_ELT(SEXP x, R_xlen_t i, int v);
void SET_REAL_ELT(SEXP x, R_xlen_t i, double v);
void SET_COMPLEX_ELT(SEXP x, R_xlen_t i, Rcomplex v);
void SET_RAW_ELT(SEXP x, R_xlen_t i, Rbyte v);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

- `x`: a vector of the corresponding type.
- `i`: zero-based element index.
- `v`: the new value.

Element-wise access is much slower than sweeping a cached pointer; use it when the type is not known in advance or only a few elements are touched.

**See also:** [`LOGICAL()`](#LOGICAL), [`STRING_ELT()`](#STRING_ELT)

### 5.4.8 Scalars

A few helpers extract the first value of a vector, coercing as necessary:

### 5.4.9 `Rf_asLogical()` (`Rf_asInteger()`, `Rf_asReal()`, `Rf_asComplex()`)

Extract the first value of a vector as a C type, coercing as necessary.

``` c
int Rf_asLogical(SEXP x);
int Rf_asInteger(SEXP x);
double Rf_asReal(SEXP x);
Rcomplex Rf_asComplex(SEXP x);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** `as.logical()`

- `x`: a vector.

**See also:** [`Rf_coerceVector()`](#Rf_coerceVector)

### 5.4.10 `Rf_asBool()` (`Rf_asRboolean()`)

Extract a checked single logical value as a C bool.

``` c
bool Rf_asBool(SEXP x);
Rboolean Rf_asRboolean(SEXP x);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** 4.5.0 · **R equivalent:** —

- `x`: a vector coercible to a single logical.

Like `Rf_asLogical()`, but errors if the coerced value is `NA` (or the input is not a single value), so the result is always usable as a C boolean.

**See also:** [`Rf_asLogical()`](#Rf_asLogical)

### 5.4.11 Special values

Integer, logical, and character vectors use sentinel values for missing data (`NA_INTEGER`, `NA_LOGICAL`, `NA_STRING`). `NA_INTEGER` is `INT_MIN`, the smallest representable `int` — which means R integer vectors cannot store that value, and negating or taking the absolute value of `NA_INTEGER` overflows.

Missing values are more complicated for `REALSXP` because doubles already have a missing-value protocol defined by the floating-point standard ([IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point)). An `NA` is a `NaN` with a special bit pattern (the lowest word is 1954, the year Ross Ihaka was born), and there are distinct values for positive and negative infinity. Test with the `ISNA()`, `ISNAN()`, and `!R_FINITE()` macros; set with the constants `NA_REAL`, `R_NaN`, `R_PosInf`, and `R_NegInf`.

### 5.4.12 `NA_LOGICAL()` (`NA_INTEGER()`)

Represent missing logical and integer values.

``` c
#define NA_LOGICAL R_NaInt
#define NA_INTEGER R_NaInt
```

**Status:** API · **Header:** `R_ext/Arith.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `NA`

`NA_LOGICAL` and `NA_INTEGER` are both `R_NaInt` (currently `INT_MIN`); `NA_STRING` is `R_NaString`.

**See also:** [`NA_REAL()`](#NA_REAL)

### 5.4.13 `NA_REAL()` (`R_NaReal()`)

Represent a missing double value.

``` c
double R_NaReal;
#define NA_REAL R_NaReal
```

**Status:** API · **Header:** `R_ext/Arith.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `NA_real_`

Represented as an `NaN` with a specific bit pattern, per the IEEE 754 floating-point standard.

**See also:** [`R_NaN()`](#R_NaN), [`ISNA()`](#ISNA), [`NA_LOGICAL()`](#NA_LOGICAL)

### 5.4.14 `R_NaN()` (`R_PosInf()`, `R_NegInf()`)

Represent NaN and positive or negative infinity as doubles.

``` c
double R_NaN;
double R_PosInf;
double R_NegInf;
```

**Status:** API · **Header:** `R_ext/Arith.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `NaN`

Use these constants, together with `NA_REAL`, for cross-platform-safe NaN, infinite, and missing values.

**See also:** [`NA_REAL()`](#NA_REAL), [`ISNA()`](#ISNA)

### 5.4.15 `ISNA()` (`ISNAN()`, `R_FINITE()`)

Check a double for missing, NaN, or non-finite values.

``` c
int ISNA(double x);
int ISNAN(double x);
int R_FINITE(double x);
```

**Status:** API · **Header:** `R_ext/Arith.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `is.na()`

- `x`: the double to check.

These are macros; `R_IsNA()`, `R_IsNaN()`, and `R_finite()` are the equivalent functions. Check `!R_FINITE()` for non-finite values.

**See also:** [`R_IsNA()`](#R_IsNA), [`NA_REAL()`](#NA_REAL)

### 5.4.16 `R_IsNA()` (`R_IsNaN()`, `R_finite()`)

Check a double for missing, NaN, or non-finite values.

``` c
int R_IsNA(double);
int R_IsNaN(double);
int R_finite(double);
```

**Status:** API · **Header:** `R_ext/Arith.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `is.finite()`

Function equivalents of the `ISNA()`, `ISNAN()`, and `R_FINITE()` macros. `R_finite()` is false for `NA`, `NaN`, `Inf`, and `-Inf`.

**See also:** [`ISNA()`](#ISNA)

### 5.4.17 `R_isnancpp()`

Test for NaN in a way that is safe from C++ compiler optimisations.

``` c
int R_isnancpp(double);
```

**Status:** API · **Header:** `R_ext/Arith.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

Only needed from C++; it backs the `ISNAN()` macro there. In C, use `ISNAN()` directly.

**See also:** [`ISNA()`](#ISNA), [`R_IsNA()`](#R_IsNA)

## 5.5 Test

A number of helpers test whether a SEXP has a given type. There’s no `Rf_isRaw()` or `Rf_isList()` for `RAWSXP`/`VECSXP`; use `TYPEOF(x) == RAWSXP` or `TYPEOF(x) == VECSXP`. (`Rf_isList()` tests for a pairlist.)

These tests are not always consistent with their R equivalents. For example, `Rf_isVectorAtomic(R_NilValue)` is false but `is.atomic(NULL)` is true; `Rf_isNewList(R_NilValue)` is true but `is.list(NULL)` is false. Because of this confusion, prefer writing your own wrappers around `TYPEOF(x)`.

### 5.5.1 `Rf_isLogical()` (`Rf_isInteger()`, `Rf_isReal()`, `Rf_isComplex()`, `Rf_isString()`, `Rf_isExpression()`)

Test if an SEXP is a vector of the given type.

``` c
Rboolean Rf_isLogical(SEXP s);
Rboolean Rf_isInteger(SEXP s);
Rboolean Rf_isReal(SEXP s);
Rboolean Rf_isComplex(SEXP s);
Rboolean Rf_isString(SEXP s);
Rboolean Rf_isExpression(SEXP s);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `is.logical()`

- `s`: any SEXP.

No function tests for `RAWSXP` or `VECSXP`; use `TYPEOF(x) == RAWSXP` or `TYPEOF(x) == VECSXP` instead. Factors are also `INTSXP`s, so `TYPEOF(x) == INTSXP` accepts both plain integer vectors and factors; combine `Rf_isInteger()` with `Rf_isFactor()` to distinguish them.

**See also:** [`Rf_isNewList()`](#Rf_isNewList), [`Rf_isFactor()`](#Rf_isFactor)

### 5.5.2 `Rf_isNewList()` (`Rf_isVectorAtomic()`, `Rf_isVectorList()`, `Rf_isVector()`, `Rf_isNumber()`, `Rf_isNumeric()`)

Test for frequently used combinations of vector types.

``` c
Rboolean Rf_isNewList(SEXP s);
Rboolean Rf_isVectorAtomic(SEXP s);
Rboolean Rf_isVectorList(SEXP s);
Rboolean Rf_isVector(SEXP s);
Rboolean Rf_isNumber(SEXP s);
Rboolean Rf_isNumeric(SEXP s);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

- `s`: any SEXP.

`Rf_isNewList()` matches `NILSXP`/`VECSXP`; `Rf_isVectorAtomic()` matches `LGLSXP`/`INTSXP`/`REALSXP`/`CPLXSXP`/`STRSXP`/`RAWSXP`; `Rf_isVectorList()` matches `LISTSXP`/`EXPRSXP`; `Rf_isVector()` is their union; `Rf_isNumber()` and `Rf_isNumeric()` match `LGLSXP`/`REALSXP`/ `CPLXSXP` and non-factor `INTSXP`. Results can diverge from their R equivalents: `Rf_isVectorAtomic(R_NilValue)` is false (`is.atomic(NULL)` is true) while `Rf_isNewList(R_NilValue)` is true (`is.list(NULL)` is false); consider writing your own wrapper around `TYPEOF(x)` instead.

**See also:** [`Rf_isLogical()`](#Rf_isLogical)

### 5.5.3 `Rf_isNull()`

Test whether an object is NULL.

``` c
Rboolean (Rf_isNull)(SEXP s);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `is.null()`

## 5.6 Sorting and ordering

Follows [WRE §6.10, Utility functions](https://cran.r-project.org/doc/manuals/R-exts.html#Utility-functions-1) closely.

Two families: the `R_*sort` functions sort C arrays in place (the `R_qsort*` variants use 1-based `i:j` ranges and don’t handle `NA`; `R_isort`/`R_rsort`/`R_csort` sort `NA`s last), while `R_orderVector()` computes an ordering permutation of R vectors, like `order()` — note it returns 0-based indices. None of the in-place sorts are stable.

### 5.6.1 `R_qsort()` (`R_qsort_I()`, `R_qsort_int()`, `R_qsort_int_I()`)

Sort a numeric array in place using quicksort.

``` c
void R_qsort    (double *v,         size_t i, size_t j);
void R_qsort_I  (double *v, int *II, int i, int j);
void R_qsort_int  (int *iv,         size_t i, size_t j);
void R_qsort_int_I(int *iv, int *II, int i, int j);
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `sort()`

The dummy index argument is renamed to `II` to avoid problems with g++ on Solaris.

**See also:** [`R_isort()`](#R_isort), [`R_orderVector()`](#R_orderVector)

### 5.6.2 `R_isort()` (`R_rsort()`, `R_csort()`)

Sort an int, double, or complex array in place.

``` c
void R_isort(int*, int);
void R_rsort(double*, int);
void R_csort(Rcomplex*, int);
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `sort()`

**See also:** [`R_qsort()`](#R_qsort)

### 5.6.3 `rsort_with_index()`

Sort a double array in place, reordering an index array alongside.

``` c
void rsort_with_index(double *, int *, int);
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

**See also:** [`Rf_revsort()`](#Rf_revsort)

### 5.6.4 `Rf_revsort()`

Sort a double array in reverse order, reordering an index array alongside.

``` c
void Rf_revsort(double*, int*, int);
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

**See also:** [`rsort_with_index()`](#rsort_with_index)

### 5.6.5 `Rf_iPsort()` (`Rf_rPsort()`, `Rf_cPsort()`)

Partially sort an int, double, or complex array around the k-th element.

``` c
void Rf_iPsort(int*,    int, int);
void Rf_rPsort(double*, int, int);
void Rf_cPsort(Rcomplex*, int, int);
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

**See also:** [`R_qsort()`](#R_qsort)

### 5.6.6 `R_orderVector()` (`R_orderVector1()`)

Compute an ordering permutation into an index array.

``` c
void R_orderVector (int *indx, int n, SEXP arglist, Rboolean nalast, Rboolean decreasing);
void R_orderVector1(int *indx, int n, SEXP x,       Rboolean nalast, Rboolean decreasing);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** `order()`

C equivalent of `order(..., na.last, decreasing)`; build `arglist` with `Rf_lang2()` or `Rf_lang3()`. `R_orderVector1()` is the single-vector version, equivalent to `order(x, na.last, decreasing)`.

**See also:** [`R_qsort()`](#R_qsort)

### 5.6.7 `Rf_isUnsorted()`

Test whether a vector may be unsorted.

``` c
Rboolean Rf_isUnsorted(SEXP, Rboolean);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** `is.unsorted()`

## 5.7 Matching and duplication

Vector-level equivalents of `match()`, `duplicated()`, and `anyDuplicated()`.

### 5.7.1 `Rf_any_duplicated()` (`Rf_any_duplicated3()`)

Find the position of the first duplicated element of a vector.

``` c
R_xlen_t Rf_any_duplicated(SEXP x, Rboolean from_last);
R_xlen_t Rf_any_duplicated3(SEXP x, SEXP incomp, Rboolean from_last);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** `anyDuplicated()`

### 5.7.2 `Rf_match()` (`Rf_matchE()`)

Find the positions of first matches between two vectors.

``` c
SEXP Rf_match(SEXP itable, SEXP ix, int no_match);
SEXP Rf_matchE(SEXP itable, SEXP ix, int no_match, SEXP env);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `match()`

In `Rf_matchE()`, `env` is used to look up `as.character` when translating `POSIXlt`; rarely needed directly.

**See also:** [`Rf_pmatch()`](#Rf_pmatch)

### 5.7.3 `Rf_duplicated()`

Identify duplicated elements of a vector.

``` c
SEXP Rf_duplicated(SEXP x, Rboolean from_last);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `duplicated()`

- `x`: a vector.
- `from_last`: if `TRUE`, search from the last element.

Returns an `LGLSXP` the same length as `x`.

## 5.8 Miscellaneous helpers

A couple of macros test whether an object is a “scalar” (a vector of length 1):

### 5.8.1 `Rf_copyVector()`

Copy from one vector to another, recycling as necessary.

``` c
void Rf_copyVector(SEXP source, SEXP target);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

- `source`: the vector to copy from.
- `target`: the vector to copy to.

Use `Rf_duplicate()` instead if you just want to duplicate a vector without recycling.

**See also:** [`Rf_copyMatrix()`](#Rf_copyMatrix)

### 5.8.2 `Rf_stringSuffix()`

Extract the tail of a STRSXP.

``` c
SEXP Rf_stringSuffix(SEXP string, int fromIndex);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `substring()`

- `string`: a `STRSXP`.
- `fromIndex`: the index to start the suffix from.

### 5.8.3 `IS_SCALAR()` (`IS_SIMPLE_SCALAR()`)

Test if an object is a scalar (a vector of length 1) of the given type.

``` c
#define IS_SCALAR(x, type) (TYPEOF(x) == (type) && XLENGTH(x) == 1)
#define IS_SIMPLE_SCALAR(x, type) (IS_SCALAR(x, type) && ATTRIB(x) == R_NilValue)
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

- `x`: any SEXP.
- `type`: a `SEXPTYPE`.

`IS_SIMPLE_SCALAR()` additionally requires that the object has no attributes.

### 5.8.4 `Rf_isVectorizable()`

Test if a list can be converted into a vector.

``` c
Rboolean Rf_isVectorizable(SEXP x);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

- `x`: a list or pairlist.

True when every element of the list or pairlist is a vector of length 0 or 1.

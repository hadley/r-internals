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

### 5.1.1 `Rf_xlength()`, `Rf_length()`

**Header:** `Rinternals.h`\
**R equivalent:** `length()`

Get the length of a vector.

``` c
R_xlen_t Rf_xlength(SEXP x);
R_len_t Rf_length(SEXP x);
```

- `x`: any vector.

**Returns:** The length of `x`: `Rf_xlength()` returns an `R_xlen_t`, `Rf_length()` an `R_len_t`.

`Rf_xlength()` uses `R_xlen_t` and supports long vectors (length up to 2^64 - 1); `Rf_length()` is limited to `int` (2^31 - 1). Also works on pairlists, where it is O(n).

**See also:** [`Rf_lengthgets()`](#Rf_lengthgets), [`LENGTH()`](#LENGTH)

### 5.1.2 `Rf_lengthgets()`, `Rf_xlengthgets()`

needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `length<-`

Set the length of a vector by creating a new vector of extended length.

``` c
SEXP Rf_lengthgets(SEXP x, R_len_t n);
SEXP Rf_xlengthgets(SEXP x, R_xlen_t n);
```

- `x`: a vector.
- `n`: the new length.

**Returns:** A newly allocated copy of `x` with length `n`, padded or truncated as needed.

`Rf_xlengthgets()` is the `R_xlen_t`-based variant for long vectors.

**See also:** [`Rf_xlength()`](#Rf_xlength), [`SETLENGTH()`](#SETLENGTH)

### 5.1.3 `LENGTH()`, `XLENGTH()`

**Header:** `Rinternals.h`\
**R equivalent:** `length()`

Get the length of a vector.

``` c
int LENGTH(SEXP x);
R_xlen_t XLENGTH(SEXP x);
```

- `x`: any vector.

**Returns:** The length of `x`: `LENGTH()` returns an `int`, `XLENGTH()` an `R_xlen_t`.

Uppercase variants of `Rf_length()`/`Rf_xlength()`, implemented as macros in base R for efficiency.

**See also:** [`Rf_xlength()`](#Rf_xlength), [`SETLENGTH()`](#SETLENGTH)

### 5.1.4 `IS_LONG_VEC()`

experimental

**Header:** `Rinternals.h`

Test whether a vector is a long vector.

``` c
int IS_LONG_VEC(SEXP x);
```

- `x`: any vector.

**Returns:** Non-zero if `x` is a long vector (length over 2^31 - 1), zero otherwise.

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

needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `vector()`

Create a new vector of the given type and length.

``` c
SEXP Rf_allocVector(SEXPTYPE type, R_xlen_t n);
```

- `type`: any vector `SEXPTYPE` (`LGLSXP`, `INTSXP`, `REALSXP`, `CPLXSXP`, `STRSXP`, `VECSXP`, `RAWSXP`, `EXPRSXP`).
- `n`: number of elements; `R_xlen_t` supports long vectors on 64-bit platforms.

**Returns:** A freshly allocated vector of `type` and length `n`; atomic contents are uninitialized.

Atomic vector contents are uninitialised; `VECSXP`/`EXPRSXP` elements are `R_NilValue` and `STRSXP` elements are `""`. Attributes are unset.

``` c
SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
```

**See also:** [`Rf_allocVector3()`](#Rf_allocVector3), [`Rf_coerceVector()`](#Rf_coerceVector)

### 5.2.2 `Rf_ScalarLogical()`, `Rf_ScalarInteger()`, `Rf_ScalarReal()`, `Rf_ScalarComplex()`, `Rf_ScalarRaw()`

needs protect throws

**Header:** `Rinternals.h`

Create a vector of length 1 from the corresponding C type.

``` c
SEXP Rf_ScalarLogical(int x);
SEXP Rf_ScalarInteger(int x);
SEXP Rf_ScalarReal(double x);
SEXP Rf_ScalarComplex(Rcomplex x);
SEXP Rf_ScalarRaw(Rbyte x);
```

- `x`: the C value to wrap.

**Returns:** A length-1 vector of the corresponding type holding `x`; `Rf_ScalarLogical()` returns a cached singleton.

For strings, use [`Rf_ScalarString()`](#Rf_ScalarString) or [`Rf_mkString()`](#Rf_mkString) instead. `Rf_ScalarLogical()` returns cached singletons and never allocates; the other `Rf_Scalar*()` variants always allocate.

**See also:** [`Rf_allocVector()`](#Rf_allocVector), [`Rf_ScalarString()`](#Rf_ScalarString), [`Rf_mkString()`](#Rf_mkString)

### 5.2.3 `Rf_coerceVector()`

needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `as.vector()`

Coerce an existing vector to a different type.

``` c
SEXP Rf_coerceVector(SEXP x, SEXPTYPE newtype);
```

- `x`: a vector.
- `newtype`: the `SEXPTYPE` to coerce to.

**Returns:** A freshly allocated copy of `x` coerced to `newtype`.

Errors if it can’t coerce between `TYPEOF(x)` and `newtype`.

**See also:** [`Rf_allocVector()`](#Rf_allocVector), [`Rf_asLogical()`](#Rf_asLogical)

### 5.2.4 `Rf_mkNamed()`

needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `setNames()`

Create a named vector of the given type.

``` c
SEXP Rf_mkNamed(SEXPTYPE type, const char **names);
```

- `type`: any vector `SEXPTYPE`.
- `names`: a null-terminated array of `const char*` names.

**Returns:** A freshly allocated vector of `type` with one element per name and the names attribute set.

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

needs protect throws

**Header:** `Rinternals.h`

Create a new vector using a custom allocator.

``` c
SEXP Rf_allocVector3(SEXPTYPE type, R_xlen_t n, R_allocator_t *allocator);
```

**Returns:** A freshly allocated vector of `type` and length `n`, with payload memory from `allocator`.

Like `Rf_allocVector()`, but memory for the data payload comes from `allocator`; pass `NULL` for plain `Rf_allocVector()` behaviour. Rarely needed in package code.

**See also:** [`Rf_allocVector()`](#Rf_allocVector)

## 5.3 Resizable vectors

R 4.6.0 added an **experimental** API for vectors that can grow in place: allocate with a maximum length, then resize without copying. This replaces the non-API `SETLENGTH()`/`SET_TRUELENGTH()` idiom; the interface may change in future R releases.

### 5.3.1 `R_allocResizableVector()`

experimental needs protect throws

**Header:** `Rinternals.h`\
**Since:** 4.6.0

Create a vector that can grow in place up to a maximum length.

``` c
SEXP R_allocResizableVector(SEXPTYPE type, R_xlen_t maxlen);
```

- `type`: any vector `SEXPTYPE`.
- `maxlen`: maximum length the vector can grow to.

**Returns:** A freshly allocated resizable vector of `type`, initially length 0, able to grow to `maxlen`.

Allocates `maxlen` elements up front; the vector starts at length 0 and can be resized in place with `R_resizeVector()`. Experimental: the interface may change in future R releases.

**See also:** [`Rf_allocVector()`](#Rf_allocVector), [`R_resizeVector()`](#R_resizeVector)

### 5.3.2 `R_duplicateAsResizable()`

experimental needs protect throws

**Header:** `Rinternals.h`\
**Since:** 4.6.0

Duplicate a vector as a resizable vector.

``` c
SEXP R_duplicateAsResizable(SEXP x);
```

- `x`: a vector.

**Returns:** A freshly allocated resizable copy of `x` that can grow up to its current length.

The copy keeps its current length and can grow up to that length with `R_resizeVector()`. Experimental: the interface may change in future R releases.

**See also:** [`R_allocResizableVector()`](#R_allocResizableVector), [`R_resizeVector()`](#R_resizeVector)

### 5.3.3 `R_resizeVector()`

experimental throws

**Header:** `Rinternals.h`\
**Since:** 4.6.0

Resize a resizable vector in place.

``` c
void R_resizeVector(SEXP x, R_xlen_t newlen);
```

- `x`: a resizable vector.
- `newlen`: new length, at most the vector’s maximum length.

The API replacement for the non-API `SETLENGTH()`/`SET_TRUELENGTH()` idiom. Experimental: the interface may change in future R releases.

**See also:** [`R_allocResizableVector()`](#R_allocResizableVector), [`R_maxLength()`](#R_maxLength)

### 5.3.4 `R_isResizable()`

experimental

**Header:** `Rinternals.h`\
**Since:** 4.6.0

Test if a vector is resizable.

``` c
bool R_isResizable(SEXP x);
```

- `x`: any SEXP.

**Returns:** `true` if `x` is a resizable vector, otherwise `false`.

**See also:** [`R_allocResizableVector()`](#R_allocResizableVector)

### 5.3.5 `R_maxLength()`

experimental

**Header:** `Rinternals.h`\
**Since:** 4.6.0

Get the maximum length a resizable vector can grow to.

``` c
R_xlen_t R_maxLength(SEXP x);
```

- `x`: a resizable vector.

**Returns:** The maximum length `x` can grow to.

**See also:** [`R_resizeVector()`](#R_resizeVector)

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

### 5.4.1 `LOGICAL()`, `INTEGER()`, `REAL()`, `COMPLEX()`, `RAW()`

**Header:** `Rinternals.h`

Get a pointer to the underlying C array of an atomic vector.

``` c
int*      LOGICAL(SEXP x);
int*      INTEGER(SEXP x);
double*   REAL(SEXP x);
Rcomplex* COMPLEX(SEXP x);
Rbyte*    RAW(SEXP x);
```

- `x`: a vector of the corresponding type.

**Returns:** A writable pointer to the underlying C array of `x`.

For long vectors, cache the returned pointer and reuse it rather than calling the accessor on every iteration.

``` c
int* px = INTEGER(x);
for (int i = 0; i < n; ++i) {
  px[i] = px[i] * 2;
}
```

**See also:** [`STRING_ELT()`](#STRING_ELT), [`VECTOR_ELT()`](#VECTOR_ELT)

### 5.4.2 `STRING_ELT()`, `SET_STRING_ELT()`

throws

**Header:** `Rinternals.h`

Get or set a single element of a character vector.

``` c
SEXP STRING_ELT(SEXP x, R_xlen_t i);
void SET_STRING_ELT(SEXP x, R_xlen_t i, SEXP v);
```

- `x`: a `STRSXP`.
- `i`: zero-based element index.
- `v`: the `CHARSXP` to set.

**Returns:** `STRING_ELT()` returns the `CHARSXP` element at index `i` (not a copy); `SET_STRING_ELT()` returns nothing.

`STRING_ELT()` returns a `CHARSXP`, not an ordinary `SEXP` value; strings use a pair of accessor functions rather than a plain C array.

**See also:** [`VECTOR_ELT()`](#VECTOR_ELT), [`STRING_PTR()`](#STRING_PTR)

### 5.4.3 `VECTOR_ELT()`, `SET_VECTOR_ELT()`

throws

**Header:** `Rinternals.h`

Get or set a single element of a list.

``` c
SEXP VECTOR_ELT(SEXP x, R_xlen_t i);
SEXP SET_VECTOR_ELT(SEXP x, R_xlen_t i, SEXP v);
```

- `x`: a `VECSXP`.
- `i`: zero-based element index.
- `v`: the value to set.

**Returns:** `VECTOR_ELT()` returns the element at index `i` (not a copy); `SET_VECTOR_ELT()` returns `v`.

`VECTOR_ELT()` may return any `SEXPTYPE`; lists use a pair of accessor functions rather than a plain C array.

**See also:** [`STRING_ELT()`](#STRING_ELT), [`VECTOR_PTR()`](#VECTOR_PTR)

### 5.4.4 `STRING_PTR_RO()`, `VECTOR_PTR_RO()`

**Header:** `Rinternals.h`\
**Since:** 4.5.0

Get read-only access to the elements of a character or list vector.

``` c
const SEXP *STRING_PTR_RO(SEXP x);
const SEXP *VECTOR_PTR_RO(SEXP x);
```

**Returns:** A read-only pointer to the `SEXP` element array of `x`.

The read-only analogues of `STRING_PTR()`/`VECTOR_PTR()`; use them when you only read elements so ALTREP and future representations aren’t forced to materialize a writable array.

**See also:** [`STRING_ELT()`](#STRING_ELT)

### 5.4.5 `DATAPTR_RO()`, `DATAPTR()`

**Header:** `Rinternals.h`

Get an untyped pointer to a vector’s data.

``` c
const void *(DATAPTR_RO)(SEXP x);
void *(DATAPTR)(SEXP x);
```

- `x`: any vector.

**Returns:** An untyped pointer to the data payload of `x`; `DATAPTR()` is writable, `DATAPTR_RO()` read-only.

Prefer the typed accessors (`REAL()`, `INTEGER_RO()`, …), which check the vector type. `DATAPTR()` gives write access; `DATAPTR_RO()` is read-only.

**See also:** [`LOGICAL()`](#LOGICAL), [`INTEGER_RO()`](#INTEGER_RO)

### 5.4.6 `INTEGER_RO()`, `LOGICAL_RO()`, `REAL_RO()`, `COMPLEX_RO()`, `RAW_RO()`

**Header:** `Rinternals.h`

Get a read-only pointer to the underlying C array.

``` c
const int*      (INTEGER_RO)(SEXP x);
const int*      (LOGICAL_RO)(SEXP x);
const double*   (REAL_RO)(SEXP x);
const Rcomplex* (COMPLEX_RO)(SEXP x);
const Rbyte*    (RAW_RO)(SEXP x);
```

- `x`: a vector of the corresponding type.

**Returns:** A read-only pointer to the underlying C array of `x`.

Read-only variants of `INTEGER()` etc. Use them when you only read: the `const` pointer catches accidental writes, and ALTREP vectors can avoid materialising a writable copy.

**See also:** [`LOGICAL()`](#LOGICAL), [`DATAPTR_RO()`](#DATAPTR_RO)

### 5.4.7 `INTEGER_ELT()`, `LOGICAL_ELT()`, `REAL_ELT()`, `COMPLEX_ELT()`, `RAW_ELT()`, `SET_INTEGER_ELT()`, `SET_LOGICAL_ELT()`, `SET_REAL_ELT()`, `SET_COMPLEX_ELT()`, `SET_RAW_ELT()`

**Header:** `Rinternals.h`

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

- `x`: a vector of the corresponding type.
- `i`: zero-based element index.
- `v`: the new value.

**Returns:** The `*_ELT()` getters return the element at index `i` as the corresponding C type; the `SET_*_ELT()` setters return nothing.

Element-wise access is much slower than sweeping a cached pointer; use it when the type is not known in advance or only a few elements are touched.

**See also:** [`LOGICAL()`](#LOGICAL), [`STRING_ELT()`](#STRING_ELT)

### 5.4.8 Scalars

A few helpers extract the first value of a vector, coercing as necessary:

### 5.4.9 `Rf_asLogical()`, `Rf_asInteger()`, `Rf_asReal()`, `Rf_asComplex()`

throws

**Header:** `Rinternals.h`\
**R equivalent:** `as.logical()`

Extract the first value of a vector as a C type, coercing as necessary.

``` c
int Rf_asLogical(SEXP x);
int Rf_asInteger(SEXP x);
double Rf_asReal(SEXP x);
Rcomplex Rf_asComplex(SEXP x);
```

- `x`: a vector.

**Returns:** The first element of `x` coerced to the corresponding C type; may be an `NA` sentinel such as `NA_INTEGER` or `NA_REAL`.

**See also:** [`Rf_coerceVector()`](#Rf_coerceVector)

### 5.4.10 `Rf_asBool()`, `Rf_asRboolean()`

throws

**Header:** `Rinternals.h`\
**Since:** 4.5.0

Extract a checked single logical value as a C bool.

``` c
bool Rf_asBool(SEXP x);
Rboolean Rf_asRboolean(SEXP x);
```

- `x`: a vector coercible to a single logical.

**Returns:** The single logical value of `x` as a C boolean; never `NA` because `NA` inputs raise an error.

Like `Rf_asLogical()`, but errors if the coerced value is `NA` (or the input is not a single value), so the result is always usable as a C boolean.

**See also:** [`Rf_asLogical()`](#Rf_asLogical)

### 5.4.11 Special values

Integer, logical, and character vectors use sentinel values for missing data (`NA_INTEGER`, `NA_LOGICAL`, `NA_STRING`). `NA_INTEGER` is `INT_MIN`, the smallest representable `int` — which means R integer vectors cannot store that value, and negating or taking the absolute value of `NA_INTEGER` overflows.

Missing values are more complicated for `REALSXP` because doubles already have a missing-value protocol defined by the floating-point standard ([IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point)). An `NA` is a `NaN` with a special bit pattern (the lowest word is 1954, the year Ross Ihaka was born), and there are distinct values for positive and negative infinity. Test with the `ISNA()`, `ISNAN()`, and `!R_FINITE()` macros; set with the constants `NA_REAL`, `R_NaN`, `R_PosInf`, and `R_NegInf`.

### 5.4.12 `NA_LOGICAL()`, `NA_INTEGER()`

**Header:** `R_ext/Arith.h`\
**R equivalent:** `NA`

Represent missing logical and integer values.

``` c
#define NA_LOGICAL R_NaInt
#define NA_INTEGER R_NaInt
```

`NA_LOGICAL` and `NA_INTEGER` are both `R_NaInt` (currently `INT_MIN`); `NA_STRING` is `R_NaString`.

**See also:** [`NA_REAL()`](#NA_REAL)

### 5.4.13 `NA_REAL()`, `R_NaReal()`

**Header:** `R_ext/Arith.h`\
**R equivalent:** `NA_real_`

Represent a missing double value.

``` c
double R_NaReal;
#define NA_REAL R_NaReal
```

Represented as an `NaN` with a specific bit pattern, per the IEEE 754 floating-point standard.

**See also:** [`R_NaN()`](#R_NaN), [`ISNA()`](#ISNA), [`NA_LOGICAL()`](#NA_LOGICAL)

### 5.4.14 `R_NaN()`, `R_PosInf()`, `R_NegInf()`

**Header:** `R_ext/Arith.h`\
**R equivalent:** `NaN`

Represent NaN and positive or negative infinity as doubles.

``` c
double R_NaN;
double R_PosInf;
double R_NegInf;
```

Use these constants, together with `NA_REAL`, for cross-platform-safe NaN, infinite, and missing values.

**See also:** [`NA_REAL()`](#NA_REAL), [`ISNA()`](#ISNA)

### 5.4.15 `ISNA()`, `ISNAN()`, `R_FINITE()`

**Header:** `R_ext/Arith.h`\
**R equivalent:** `is.na()`

Check a double for missing, NaN, or non-finite values.

``` c
int ISNA(double x);
int ISNAN(double x);
int R_FINITE(double x);
```

- `x`: the double to check.

**Returns:** Non-zero if `x` is `NA` (`ISNA()`), `NaN` or `NA` (`ISNAN()`), or finite (`R_FINITE()`); zero otherwise.

These are macros; `R_IsNA()`, `R_IsNaN()`, and `R_finite()` are the equivalent functions. Check `!R_FINITE()` for non-finite values.

**See also:** [`R_IsNA()`](#R_IsNA), [`NA_REAL()`](#NA_REAL)

### 5.4.16 `R_IsNA()`, `R_IsNaN()`, `R_finite()`

**Header:** `R_ext/Arith.h`\
**R equivalent:** `is.finite()`

Check a double for missing, NaN, or non-finite values.

``` c
int R_IsNA(double);
int R_IsNaN(double);
int R_finite(double);
```

**Returns:** Non-zero if the argument is `NA` (`R_IsNA()`), `NaN` or `NA` (`R_IsNaN()`), or finite (`R_finite()`); zero otherwise.

Function equivalents of the `ISNA()`, `ISNAN()`, and `R_FINITE()` macros. `R_finite()` is false for `NA`, `NaN`, `Inf`, and `-Inf`.

**See also:** [`ISNA()`](#ISNA)

### 5.4.17 `R_isnancpp()`

**Header:** `R_ext/Arith.h`

Test for NaN in a way that is safe from C++ compiler optimisations.

``` c
int R_isnancpp(double);
```

**Returns:** Non-zero if the argument is `NaN`, zero otherwise.

Only needed from C++; it backs the `ISNAN()` macro there. In C, use `ISNAN()` directly.

**See also:** [`ISNA()`](#ISNA), [`R_IsNA()`](#R_IsNA)

## 5.5 Test

A number of helpers test whether a SEXP has a given type. There’s no `Rf_isRaw()` or `Rf_isList()` for `RAWSXP`/`VECSXP`; use `TYPEOF(x) == RAWSXP` or `TYPEOF(x) == VECSXP`. (`Rf_isList()` tests for a pairlist.)

These tests are not always consistent with their R equivalents. For example, `Rf_isVectorAtomic(R_NilValue)` is false but `is.atomic(NULL)` is true; `Rf_isNewList(R_NilValue)` is true but `is.list(NULL)` is false. Because of this confusion, prefer writing your own wrappers around `TYPEOF(x)`.

### 5.5.1 `Rf_isLogical()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.logical()`

Test if an SEXP is a logical vector.

``` c
Rboolean Rf_isLogical(SEXP s);
```

- `s`: any SEXP.

**Returns:** `TRUE` if `s` is an `LGLSXP`, otherwise `FALSE`.

No function tests for `RAWSXP` or `VECSXP`; use `TYPEOF(x) == RAWSXP` or `TYPEOF(x) == VECSXP` instead.

**See also:** [`Rf_isNewList()`](#Rf_isNewList), [`Rf_isFactor()`](#Rf_isFactor)

### 5.5.2 `Rf_isInteger()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.integer()`

Test if an SEXP is an integer vector.

``` c
Rboolean Rf_isInteger(SEXP s);
```

- `s`: any SEXP.

**Returns:** `TRUE` if `s` is an `INTSXP` (including factors), otherwise `FALSE`.

Factors are also `INTSXP`s, so `Rf_isInteger()` accepts both plain integer vectors and factors; combine with `Rf_isFactor()` to distinguish them.

**See also:** [`Rf_isFactor()`](#Rf_isFactor)

### 5.5.3 `Rf_isReal()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.double()`

Test if an SEXP is a double vector.

``` c
Rboolean Rf_isReal(SEXP s);
```

- `s`: any SEXP.

**Returns:** `TRUE` if `s` is a `REALSXP`, otherwise `FALSE`.

### 5.5.4 `Rf_isComplex()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.complex()`

Test if an SEXP is a complex vector.

``` c
Rboolean Rf_isComplex(SEXP s);
```

- `s`: any SEXP.

**Returns:** `TRUE` if `s` is a `CPLXSXP`, otherwise `FALSE`.

### 5.5.5 `Rf_isString()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.character()`

Test if an SEXP is a character vector.

``` c
Rboolean Rf_isString(SEXP s);
```

- `s`: any SEXP.

**Returns:** `TRUE` if `s` is a `STRSXP`, otherwise `FALSE`.

### 5.5.6 `Rf_isExpression()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.expression()`

Test if an SEXP is an expression vector.

``` c
Rboolean Rf_isExpression(SEXP s);
```

- `s`: any SEXP.

**Returns:** `TRUE` if `s` is an `EXPRSXP`, otherwise `FALSE`.

### 5.5.7 `Rf_isNewList()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.list()`

Test if an SEXP is a list (`VECSXP`) or `NULL`.

``` c
Rboolean Rf_isNewList(SEXP s);
```

- `s`: any SEXP.

**Returns:** `TRUE` if `s` is a `VECSXP` or `NILSXP`, otherwise `FALSE`.

Matches `NILSXP`/`VECSXP`, so the result diverges from `is.list()` on `NULL`: `Rf_isNewList(R_NilValue)` is true while `is.list(NULL)` is false. Consider writing your own wrapper around `TYPEOF(x)` instead.

**See also:** [`Rf_isLogical()`](#Rf_isLogical)

### 5.5.8 `Rf_isVectorAtomic()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.atomic()`

Test if an SEXP is an atomic vector.

``` c
Rboolean Rf_isVectorAtomic(SEXP s);
```

- `s`: any SEXP.

**Returns:** `TRUE` if `s` is an atomic vector (`LGLSXP`, `INTSXP`, `REALSXP`, `CPLXSXP`, `STRSXP`, or `RAWSXP`), otherwise `FALSE`.

Matches `LGLSXP`/`INTSXP`/`REALSXP`/`CPLXSXP`/`STRSXP`/`RAWSXP`, so the result diverges from `is.atomic()` on `NULL`: `Rf_isVectorAtomic(R_NilValue)` is false while `is.atomic(NULL)` is true. Consider writing your own wrapper around `TYPEOF(x)` instead.

### 5.5.9 `Rf_isVectorList()`

**Header:** `Rinternals.h`

Test if an SEXP is a pairlist or expression vector.

``` c
Rboolean Rf_isVectorList(SEXP s);
```

- `s`: any SEXP.

**Returns:** `TRUE` if `s` is a `LISTSXP` or `EXPRSXP`, otherwise `FALSE`.

Matches `LISTSXP`/`EXPRSXP`.

### 5.5.10 `Rf_isVector()`

**Header:** `Rinternals.h`

Test if an SEXP is any kind of vector.

``` c
Rboolean Rf_isVector(SEXP s);
```

- `s`: any SEXP.

**Returns:** `TRUE` if `s` is any kind of vector, otherwise `FALSE`.

The union of `Rf_isVectorAtomic()` and `Rf_isVectorList()`.

**See also:** [`Rf_isVectorAtomic()`](#Rf_isVectorAtomic), [`Rf_isVectorList()`](#Rf_isVectorList)

### 5.5.11 `Rf_isNumber()`

**Header:** `Rinternals.h`

Test if an SEXP is a numeric-like vector.

``` c
Rboolean Rf_isNumber(SEXP s);
```

- `s`: any SEXP.

**Returns:** `TRUE` if `s` is `LGLSXP`, `REALSXP`, `CPLXSXP`, or a non-factor `INTSXP`, otherwise `FALSE`.

Matches `LGLSXP`/`REALSXP`/`CPLXSXP` and non-factor `INTSXP`.

**See also:** [`Rf_isNumeric()`](#Rf_isNumeric)

### 5.5.12 `Rf_isNumeric()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.numeric()`

Test if an SEXP is a numeric-like vector.

``` c
Rboolean Rf_isNumeric(SEXP s);
```

- `s`: any SEXP.

**Returns:** `TRUE` if `s` is `LGLSXP`, `REALSXP`, `CPLXSXP`, or a non-factor `INTSXP`, otherwise `FALSE`.

Matches `LGLSXP`/`REALSXP`/`CPLXSXP` and non-factor `INTSXP`.

**See also:** [`Rf_isNumber()`](#Rf_isNumber)

### 5.5.13 `Rf_isNull()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.null()`

Test whether an object is NULL.

``` c
Rboolean (Rf_isNull)(SEXP s);
```

**Returns:** `TRUE` if `s` is `NULL` (`NILSXP`), otherwise `FALSE`.

## 5.6 Sorting and ordering

Follows [WRE §6.10, Utility functions](https://cran.r-project.org/doc/manuals/R-exts.html#Utility-functions-1) closely.

Two families: the `R_*sort` functions sort C arrays in place (the `R_qsort*` variants use 1-based `i:j` ranges and don’t handle `NA`; `R_isort`/`R_rsort`/`R_csort` sort `NA`s last), while `R_orderVector()` computes an ordering permutation of R vectors, like `order()` — note it returns 0-based indices. None of the in-place sorts are stable.

### 5.6.1 `R_qsort()`, `R_qsort_I()`, `R_qsort_int()`, `R_qsort_int_I()`

**Header:** `R_ext/Utils.h`\
**R equivalent:** `sort()`

Sort a numeric array in place using quicksort.

``` c
void R_qsort    (double *v,         size_t i, size_t j);
void R_qsort_I  (double *v, int *II, int i, int j);
void R_qsort_int  (int *iv,         size_t i, size_t j);
void R_qsort_int_I(int *iv, int *II, int i, int j);
```

The dummy index argument is renamed to `II` to avoid problems with g++ on Solaris.

**See also:** [`R_isort()`](#R_isort), [`R_orderVector()`](#R_orderVector)

### 5.6.2 `R_isort()`, `R_rsort()`, `R_csort()`

**Header:** `R_ext/Utils.h`\
**R equivalent:** `sort()`

Sort an int, double, or complex array in place.

``` c
void R_isort(int*, int);
void R_rsort(double*, int);
void R_csort(Rcomplex*, int);
```

**See also:** [`R_qsort()`](#R_qsort)

### 5.6.3 `rsort_with_index()`

**Header:** `R_ext/Utils.h`

Sort a double array in place, reordering an index array alongside.

``` c
void rsort_with_index(double *, int *, int);
```

**See also:** [`Rf_revsort()`](#Rf_revsort)

### 5.6.4 `Rf_revsort()`

**Header:** `R_ext/Utils.h`

Sort a double array in reverse order, reordering an index array alongside.

``` c
void Rf_revsort(double*, int*, int);
```

**See also:** [`rsort_with_index()`](#rsort_with_index)

### 5.6.5 `Rf_iPsort()`, `Rf_rPsort()`, `Rf_cPsort()`

**Header:** `R_ext/Utils.h`

Partially sort an int, double, or complex array around the k-th element.

``` c
void Rf_iPsort(int*,    int, int);
void Rf_rPsort(double*, int, int);
void Rf_cPsort(Rcomplex*, int, int);
```

**See also:** [`R_qsort()`](#R_qsort)

### 5.6.6 `R_orderVector()`, `R_orderVector1()`

throws

**Header:** `Rinternals.h`\
**R equivalent:** `order()`

Compute an ordering permutation into an index array.

``` c
void R_orderVector (int *indx, int n, SEXP arglist, Rboolean nalast, Rboolean decreasing);
void R_orderVector1(int *indx, int n, SEXP x,       Rboolean nalast, Rboolean decreasing);
```

C equivalent of `order(..., na.last, decreasing)`; build `arglist` with `Rf_lang2()` or `Rf_lang3()`. `R_orderVector1()` is the single-vector version, equivalent to `order(x, na.last, decreasing)`.

**See also:** [`R_qsort()`](#R_qsort)

### 5.6.7 `Rf_isUnsorted()`

experimental throws

**Header:** `Rinternals.h`\
**R equivalent:** `is.unsorted()`

Test whether a vector may be unsorted.

``` c
Rboolean Rf_isUnsorted(SEXP, Rboolean);
```

**Returns:** `TRUE` if `x` may be unsorted, otherwise `FALSE`.

## 5.7 Matching and duplication

Vector-level equivalents of `match()`, `duplicated()`, and `anyDuplicated()`.

### 5.7.1 `Rf_any_duplicated()`, `Rf_any_duplicated3()`

experimental throws

**Header:** `Rinternals.h`\
**R equivalent:** `anyDuplicated()`

Find the position of the first duplicated element of a vector.

``` c
R_xlen_t Rf_any_duplicated(SEXP x, Rboolean from_last);
R_xlen_t Rf_any_duplicated3(SEXP x, SEXP incomp, Rboolean from_last);
```

**Returns:** The one-based index of the first duplicated element, or 0 if there are no duplicates.

### 5.7.2 `Rf_match()`, `Rf_matchE()`

experimental needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `match()`

Find the positions of first matches between two vectors.

``` c
SEXP Rf_match(SEXP itable, SEXP ix, int no_match);
SEXP Rf_matchE(SEXP itable, SEXP ix, int no_match, SEXP env);
```

**Returns:** A freshly allocated `INTSXP` the length of `ix` giving one-based match positions in `itable`, or `no_match` where unmatched.

In `Rf_matchE()`, `env` is used to look up `as.character` when translating `POSIXlt`; rarely needed directly.

**See also:** [`Rf_pmatch()`](#Rf_pmatch)

### 5.7.3 `Rf_duplicated()`

experimental needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `duplicated()`

Identify duplicated elements of a vector.

``` c
SEXP Rf_duplicated(SEXP x, Rboolean from_last);
```

- `x`: a vector.
- `from_last`: if `TRUE`, search from the last element.

**Returns:** A freshly allocated `LGLSXP` the same length as `x`, `TRUE` at duplicated positions.

Returns an `LGLSXP` the same length as `x`.

## 5.8 Miscellaneous helpers

A couple of macros test whether an object is a “scalar” (a vector of length 1):

### 5.8.1 `Rf_copyVector()`

throws

**Header:** `Rinternals.h`

Copy from one vector to another, recycling as necessary.

``` c
void Rf_copyVector(SEXP source, SEXP target);
```

- `source`: the vector to copy from.
- `target`: the vector to copy to.

Use `Rf_duplicate()` instead if you just want to duplicate a vector without recycling.

**See also:** [`Rf_copyMatrix()`](#Rf_copyMatrix)

### 5.8.2 `Rf_stringSuffix()`

needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `substring()`

Extract the tail of a STRSXP.

``` c
SEXP Rf_stringSuffix(SEXP string, int fromIndex);
```

- `string`: a `STRSXP`.
- `fromIndex`: the index to start the suffix from.

**Returns:** A freshly allocated `STRSXP` with each element replaced by its suffix starting at `fromIndex`.

### 5.8.3 `IS_SCALAR()`, `IS_SIMPLE_SCALAR()`

experimental

**Header:** `Rinternals.h`

Test if an object is a scalar (a vector of length 1) of the given type.

``` c
#define IS_SCALAR(x, type) (TYPEOF(x) == (type) && XLENGTH(x) == 1)
#define IS_SIMPLE_SCALAR(x, type) (IS_SCALAR(x, type) && ATTRIB(x) == R_NilValue)
```

- `x`: any SEXP.
- `type`: a `SEXPTYPE`.

`IS_SIMPLE_SCALAR()` additionally requires that the object has no attributes.

### 5.8.4 `Rf_isVectorizable()`

experimental

**Header:** `Rinternals.h`

Test if a list can be converted into a vector.

``` c
Rboolean Rf_isVectorizable(SEXP x);
```

- `x`: a list or pairlist.

**Returns:** `TRUE` if every element of `x` is a vector of length 0 or 1, otherwise `FALSE`.

True when every element of the list or pairlist is a vector of length 0 or 1.

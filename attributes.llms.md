# 7  Attributes

Almost every SEXP can carry attributes: named metadata stored as a [pairlist](pairlists.llms.md) hanging off the object (though you should treat them as an opaque map and use the accessors below). Attributes are what turn bare vectors into R’s richer data structures — a matrix is a vector with a `dim` attribute, a factor is an integer vector with `levels` and `class`, and a data frame is a list with `names`, `row.names`, and `class`.

## 7.1 Get and set

Attributes are stored as a tagged pairlist, but you should treat them as an opaque map from symbol to value and use the accessors below.

### 7.1.1 `Rf_getAttrib()`, `Rf_setAttrib()`

throws

**Header:** `Rinternals.h`

Get or set the attribute associated with a symbol.

``` c
SEXP Rf_getAttrib(SEXP x, SEXP symbol);
SEXP Rf_setAttrib(SEXP x, SEXP symbol, SEXP value);
```

**Returns:** `Rf_getAttrib()` returns the value of the attribute, or `R_NilValue` if `x` has no such attribute; `Rf_setAttrib()` returns `value`.

`Rf_getAttrib()` normally returns a borrowed reference, but there is one exception: retrieving `row.names` from a data frame expands the compact `c(NA_integer_, -n)` form into a newly allocated vector, which must be protected.

**See also:** [`Rf_copyMostAttrib()`](#Rf_copyMostAttrib), [`ATTRIB()`](#ATTRIB)

### 7.1.2 `Rf_copyMostAttrib()`

throws

**Header:** `Rinternals.h`

Copy attributes, except names, dim, and dimnames, from one object to another.

``` c
void Rf_copyMostAttrib(SEXP source, SEXP target);
```

**See also:** [`Rf_getAttrib()`](#Rf_getAttrib), [`DUPLICATE_ATTRIB()`](#DUPLICATE_ATTRIB)

### 7.1.3 `DUPLICATE_ATTRIB()`, `SHALLOW_DUPLICATE_ATTRIB()`

throws

**Header:** `Rinternals.h`

Copy attributes from one object to another when duplicating an object.

``` c
void DUPLICATE_ATTRIB(SEXP to, SEXP from);
void SHALLOW_DUPLICATE_ATTRIB(SEXP to, SEXP from);
```

**See also:** [`Rf_copyMostAttrib()`](#Rf_copyMostAttrib)

### 7.1.4 `Rf_namesgets()`

throws

**Header:** `Rinternals.h`\
**R equivalent:** `names<-()`

Set the names of a vector.

``` c
SEXP Rf_namesgets(SEXP, SEXP);
```

**Returns:** The input vector with its names set.

### 7.1.5 `R_getAttributes()`, `R_getAttribCount()`, `R_getAttribNames()`, `R_hasAttrib()`

experimental needs protect throws

**Header:** `Rinternals.h`\
**Since:** 4.6.0\
**R equivalent:** `attributes()`

Query the attributes of an object as a whole.

``` c
SEXP R_getAttributes(SEXP x);
R_xlen_t R_getAttribCount(SEXP x);
SEXP R_getAttribNames(SEXP x);
bool R_hasAttrib(SEXP x, SEXP name);
```

**Returns:** `R_getAttributes()` returns the attributes of `x` as a named list (`R_NilValue` if none); `R_getAttribCount()` returns the number of attributes; `R_getAttribNames()` returns their names as a character vector; `R_hasAttrib()` returns `true` if `x` has an attribute called `name`.

`R_getAttributes()` returns the attributes as a named list, like `attributes()`; `R_hasAttrib()` tests for one attribute by name without retrieving it.

**See also:** [`Rf_getAttrib()`](#Rf_getAttrib), [`R_mapAttrib()`](#R_mapAttrib)

### 7.1.6 `R_nrow()`, `R_ncol()`

experimental throws

**Header:** `Rinternals.h`\
**Since:** 4.6.0\
**R equivalent:** `nrow()`

Get the number of rows or columns of a matrix or data frame.

``` c
R_xlen_t R_nrow(SEXP x);
R_xlen_t R_ncol(SEXP x);
```

**Returns:** The number of rows (`R_nrow()`) or columns (`R_ncol()`) of `x`.

May dispatch to the `dim` method for non-standard objects, so they can allocate and error.

**See also:** [`Rf_getAttrib()`](#Rf_getAttrib)

### 7.1.7 `R_class()`

throws

**Header:** `Rinternals.h`\
**Since:** 4.6.0\
**R equivalent:** `class()`

Get the class vector of an object.

``` c
SEXP R_class(SEXP x);
```

**Returns:** The class vector of `x`, or the implicit class if `x` has no class attribute.

Returns the implicit class for classless objects, like `class()` does; use `Rf_getAttrib(x, R_ClassSymbol)` if you want only the explicit class attribute.

**See also:** [`Rf_getAttrib()`](#Rf_getAttrib)

### 7.1.8 `R_mapAttrib()`

experimental needs protect throws

**Header:** `Rinternals.h`\
**Since:** 4.6.0

Iterate over the attributes of an object with a callback.

``` c
SEXP R_mapAttrib(SEXP x, SEXP (*FUN)(SEXP, SEXP, void *), void *data);
```

- `FUN`: called with each attribute’s name and value; return `NULL` to continue, or any other value to stop and return it.

**Returns:** The first non-`NULL` value returned by `FUN`, or `NULL` if `FUN` returned `NULL` for every attribute.

Highly experimental: both interface and semantics may change at short notice. Use only when `Rf_getAttrib()`/`R_getAttributes()` can’t do the job.

**See also:** [`R_getAttributes()`](#R_getAttributes)

### 7.1.9 `ANY_ATTRIB()`, `CLEAR_ATTRIB()`

**Header:** `Rinternals.h`\
**Since:** 4.5.0

Test for, or remove, all attributes.

``` c
int  (ANY_ATTRIB)(SEXP x);
void CLEAR_ATTRIB(SEXP x);
```

**Returns:** `ANY_ATTRIB()` returns non-zero if `x` has any attributes, otherwise zero.

`CLEAR_ATTRIB()` removes all attributes and clears the object and S4 bits. Prefer `Rf_getAttrib()`/`Rf_setAttrib()` when you only touch one attribute.

**See also:** [`Rf_getAttrib()`](#Rf_getAttrib), [`R_getAttributes()`](#R_getAttributes)

## 7.2 Arrays

An array is an atomic vector with a `dim` attribute: an integer vector giving the size of each dimension. Elements are stored in column-major order (the first dimension varies fastest), so the flat data pointer from `REAL()` etc. needs no rearrangement.

### 7.2.1 `Rf_isArray()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.array()`

Test if an object is an array.

``` c
Rboolean Rf_isArray(SEXP x);
```

- `x`: any SEXP.

**Returns:** `TRUE` if `x` is an array (a vector with a `dim` attribute), otherwise `FALSE`.

Arrays are vectors with a dim attribute.

**See also:** [`Rf_allocArray()`](#Rf_allocArray), [`Rf_isMatrix()`](#Rf_isMatrix)

### 7.2.2 `Rf_allocArray()`, `Rf_alloc3DArray()`

needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `array()`

Create an array of the given type and dimensions.

``` c
SEXP Rf_allocArray(SEXPTYPE type, SEXP dims);
SEXP Rf_alloc3DArray(SEXPTYPE type, int, int, int);
```

- `type`: any vector `SEXPTYPE`.
- `dims`: an integer vector of dimensions.

**Returns:** A newly allocated array of the given type and dimensions.

**See also:** [`Rf_allocMatrix()`](#Rf_allocMatrix), [`Rf_dimgets()`](#Rf_dimgets)

### 7.2.3 `Rf_GetArrayDimnames()`

**Header:** `Rinternals.h`\
**R equivalent:** `dimnames()`

Get the dimnames of an array.

``` c
SEXP Rf_GetArrayDimnames(SEXP x);
```

- `x`: an array.

**Returns:** The dimnames of `x` as a list, or `R_NilValue` if it has none.

**See also:** [`Rf_dimgets()`](#Rf_dimgets)

### 7.2.4 `Rf_dimgets()`, `Rf_dimnamesgets()`

throws

**Header:** `Rinternals.h`\
**R equivalent:** `dim<-`

Set the dim or dimnames attribute of an array.

``` c
SEXP Rf_dimgets(SEXP x, SEXP v);
SEXP Rf_dimnamesgets(SEXP x, SEXP v);
```

- `x`: an array.
- `v`: the new dim (an integer vector) or dimnames (a list).

**Returns:** The modified object `x`.

**See also:** [`Rf_GetArrayDimnames()`](#Rf_GetArrayDimnames), [`Rf_DropDims()`](#Rf_DropDims)

### 7.2.5 `Rf_DropDims()`

throws

**Header:** `Rinternals.h`\
**R equivalent:** `drop()`

Drop the dim attribute of an array.

``` c
SEXP Rf_DropDims(SEXP x);
```

- `x`: an array.

**Returns:** `x` with its `dim` attribute removed.

**See also:** [`Rf_dimgets()`](#Rf_dimgets)

### 7.2.6 `Rf_arraySubscript()`

needs protect throws

**Header:** `Rinternals.h`

Compute the vector offset corresponding to an array subscript.

``` c
SEXP Rf_arraySubscript(int, SEXP, SEXP, SEXP (*)(SEXP,SEXP), SEXP (*)(SEXP, int), SEXP);
```

**Returns:** A newly allocated vector of offsets into the array’s underlying storage.

## 7.3 Matrices

A matrix is an array with exactly two dimensions. R provides a few matrix-specific conveniences:

### 7.3.1 `Rf_allocMatrix()`

needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `matrix()`

Create a matrix of the given type and dimensions.

``` c
SEXP Rf_allocMatrix(SEXPTYPE type, int nrow, int ncol);
```

- `type`: any vector `SEXPTYPE`.
- `nrow`: number of rows.
- `ncol`: number of columns.

**Returns:** A newly allocated matrix of the given type and dimensions.

Matrices are arrays with exactly 2 dimensions.

**See also:** [`Rf_allocArray()`](#Rf_allocArray), [`Rf_ncols()`](#Rf_ncols)

### 7.3.2 `Rf_isMatrix()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.matrix()`

Test if an object is a matrix.

``` c
Rboolean Rf_isMatrix(SEXP x);
```

- `x`: any SEXP.

**Returns:** `TRUE` if `x` is a matrix (an array with exactly two dimensions), otherwise `FALSE`.

**See also:** [`Rf_isArray()`](#Rf_isArray)

### 7.3.3 `Rf_GetColNames()`, `Rf_GetRowNames()`

**Header:** `Rinternals.h`\
**R equivalent:** `colnames()`

Get the column or row names from a dimnames object.

``` c
SEXP Rf_GetColNames(SEXP dimnames);
SEXP Rf_GetRowNames(SEXP dimnames);
```

- `dimnames`: a dimnames object.

**Returns:** `Rf_GetColNames()` returns the column names (second element of `dimnames`) and `Rf_GetRowNames()` the row names (first element); either may be `R_NilValue`.

**See also:** [`Rf_GetMatrixDimnames()`](#Rf_GetMatrixDimnames)

### 7.3.4 `Rf_GetMatrixDimnames()`

**Header:** `Rinternals.h`\
**R equivalent:** `dimnames()`

Get the row and column names of a matrix through output parameters.

``` c
void Rf_GetMatrixDimnames(SEXP x, SEXP* rl, SEXP* cl,
  const char** rownames, const char** colnames);
```

- `x`: a matrix.
- `rl`: output parameter for the row names as a SEXP.
- `cl`: output parameter for the column names as a SEXP.
- `rownames`: output parameter for the row names as C strings.
- `colnames`: output parameter for the column names as C strings.

**See also:** [`Rf_GetColNames()`](#Rf_GetColNames)

### 7.3.5 `Rf_ncols()`, `Rf_nrows()`

**Header:** `Rinternals.h`\
**R equivalent:** `ncol()`

Get the number of columns or rows of a matrix.

``` c
int Rf_ncols(SEXP x);
int Rf_nrows(SEXP x);
```

- `x`: a matrix.

**Returns:** The number of columns (`Rf_ncols()`) or rows (`Rf_nrows()`) of `x`.

**See also:** [`Rf_allocMatrix()`](#Rf_allocMatrix)

### 7.3.6 `Rf_copyMatrix()`, `Rf_copyListMatrix()`

throws

**Header:** `Rinternals.h`

Copy the contents of one matrix into another.

``` c
void Rf_copyMatrix(SEXP source, SEXP target, Rboolean byrow);
void Rf_copyListMatrix(SEXP source, SEXP target, Rboolean byrow);
```

- `source`: the matrix to copy from.
- `target`: the matrix to copy to.
- `byrow`: if `TRUE`, copy by rows.

**See also:** [`Rf_copyVector()`](#Rf_copyVector)

### 7.3.7 `Rf_conformable()`

throws

**Header:** `Rinternals.h`

Test whether two objects have conformable dimensions.

``` c
Rboolean Rf_conformable(SEXP, SEXP);
```

**Returns:** `TRUE` if the two objects have conformable dimensions, otherwise `FALSE`.

## 7.4 Factors

A factor is an integer vector of 1-based codes with a `levels` character vector and class `"factor"`. `NA_INTEGER` codes represent missing values. Because factors are `INTSXP` internally, `TYPEOF(x) == INTSXP` alone can’t distinguish them from plain integer vectors.

### 7.4.1 `Rf_isFactor()`, `Rf_isOrdered()`, `Rf_isUnordered()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.factor()`

Test if an object is a factor, or an ordered or unordered factor.

``` c
Rboolean Rf_isFactor(SEXP x);
Rboolean Rf_isOrdered(SEXP x);
Rboolean Rf_isUnordered(SEXP x);
```

- `x`: any SEXP.

**Returns:** `TRUE` if `x` is a factor (`Rf_isFactor()`), an ordered factor (`Rf_isOrdered()`), or an unordered factor (`Rf_isUnordered()`), otherwise `FALSE`.

**See also:** [`Rf_nlevels()`](#Rf_nlevels), [`Rf_asCharacterFactor()`](#Rf_asCharacterFactor)

### 7.4.2 `Rf_nlevels()`

experimental

**Header:** `Rinternals.h`\
**R equivalent:** `nlevels()`

Get the number of levels of a factor.

``` c
int Rf_nlevels(SEXP x);
```

- `x`: a factor.

**Returns:** The number of levels of the factor `x`.

**See also:** [`Rf_isFactor()`](#Rf_isFactor)

### 7.4.3 `Rf_asCharacterFactor()`

needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `as.character()`

Coerce a factor into a character vector.

``` c
SEXP Rf_asCharacterFactor(SEXP x);
```

- `x`: a factor.

**Returns:** A newly allocated character vector of the factor’s level labels.

**See also:** [`Rf_isFactor()`](#Rf_isFactor)

## 7.5 Data frames

A data frame is a `VECSXP` of equal-length columns with `names`, `row.names`, and class `"data.frame"`. The C API offers almost no support — you build and manipulate them as plain lists with attributes.

The `row.names` attribute is special. It must be a character or integer vector with one entry per row, but the default sequence `1:n` is stored in a compact form: the length-2 integer vector `c(NA_integer_, -n)`. `Rf_getAttrib(df, R_RowNamesSymbol)` expands this for you, returning a freshly allocated length-`n` vector (an ALTREP compact sequence in recent R). This makes it a rare case where `Rf_getAttrib()` allocates, so you must `PROTECT` the result. When constructing a data frame in C you can set the compact form yourself:

``` c
SEXP rn = PROTECT(Rf_allocVector(INTSXP, 2));
INTEGER(rn)[0] = NA_INTEGER;
INTEGER(rn)[1] = -n;  // n rows
Rf_setAttrib(df, R_RowNamesSymbol, rn);
UNPROTECT(1);
```

### 7.5.1 `Rf_isDataFrame()`

**Header:** `Rinternals.h`\
**Since:** 4.5.0\
**R equivalent:** `is.data.frame()`

Test whether an object is a data frame.

``` c
Rboolean Rf_isDataFrame(SEXP x);
```

**Returns:** `TRUE` if `x` is a data frame, otherwise `FALSE`.

## 7.6 Time series

A `ts` object is a numeric vector or matrix with a `tsp` attribute holding `c(start, end, frequency)`. This is mostly of historical interest — most modern time series packages use their own classes — but base R’s `is.ts()` is available:

### 7.6.1 `Rf_isTs()`

throws

**Header:** `Rinternals.h`\
**R equivalent:** `is.ts()`

Test whether an object is a time series.

``` c
Rboolean Rf_isTs(SEXP);
```

**Returns:** `TRUE` if the object is of class `ts`, otherwise `FALSE`.

Tests for the `"ts"` class. Mostly of historical interest: the `ts` class (a numeric vector or matrix with a `tsp` attribute) is base R’s original time series representation, but most modern time series packages use their own classes.

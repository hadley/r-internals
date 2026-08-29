# 21  Utilities

Assorted entry points that don’t fit elsewhere: options, parsing, and file paths. Most are declared in `R_ext/Utils.h` (included by `<R.h>`). For sorting, ordering, matching, and duplication, see [Vectors](vectors.llms.md); for string searching, see [Strings](strings.llms.md).

## 21.1 Testing

### 21.1.1 `R_compute_identical()`

Test whether two objects are identical.

``` c
Rboolean R_compute_identical(SEXP, SEXP, int);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** `identical()`

The third argument is a bitmask of flags for non-default options (set a bit to get the FALSE behaviour): 1 = !NUM_EQ, 2 = !SINGLE_NA, 4 = !ATTR_AS_SET, 8 = !IGNORE_BYTECODE, 16 = !IGNORE_ENV, 32 = !IGNORE_SRCREF. R’s `identical()` default corresponds to 16.

## 21.2 Options

### 21.2.1 `Rf_GetOption1()`

Retrieve the value of an R option.

``` c
SEXP Rf_GetOption1(SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** `getOption()`

The older two-argument `Rf_GetOption()` was removed from the headers in R 4.6.0.

**See also:** [`Rf_GetOptionDigits()`](#Rf_GetOptionDigits)

### 21.2.2 `Rf_GetOptionDigits()` (`Rf_GetOptionWidth()`)

Retrieve the digits or width option.

``` c
int Rf_GetOptionDigits(void);
int Rf_GetOptionWidth(void);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `getOption()`

**See also:** [`Rf_GetOption1()`](#Rf_GetOption1)

## 21.3 Numeric parsing

`R_atof()`/`R_strtod()` exist because the C library equivalents are locale-dependent: R’s versions always use `.` as the decimal point and recognise `"NA"`.

### 21.3.1 `R_atof()` (`R_strtod()`)

Convert a string to a double.

``` c
double R_atof(const char *str);
double R_strtod(const char *c, char **end);
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `as.numeric()`

These two are guaranteed to use ‘.’ as the decimal point, and to accept “NA”.

### 21.3.2 `acopy_string()`

Copy a string into R_alloc-allocated memory.

``` c
const char *acopy_string(const char *in);
```

**Status:** experimental · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

The copy uses transient `R_alloc()` memory, so it is freed automatically when your `.Call` entry point returns.

**See also:** [`R_alloc()`](#R_alloc)

## 21.4 Files and system

### 21.4.1 `R_tmpnam()` (`R_tmpnam2()`, `R_free_tmpnam()`)

Create a name for a temporary file.

``` c
char *R_tmpnam(const char *prefix, const char *tempdir);
char *R_tmpnam2(const char *prefix, const char *tempdir, const char *fileext);
void R_free_tmpnam(char *name);
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** `tempfile()`

The returned string is dynamically allocated; free it with `R_free_tmpnam()` (not `free()`). A `NULL` prefix or extension is replaced by `""`.

### 21.4.2 `R_ExpandFileName()`

Expand a path containing ~ to a full path.

``` c
const char *R_ExpandFileName(const char *);
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `path.expand()`

Needed because most C APIs don’t understand `~`.

## 21.5 Platform information

Follows [WRE §6.17, Platform and version information](https://cran.r-project.org/doc/manuals/R-exts.html#Platform-and-version-information-1) closely.

A few macros help write platform-aware code: `USING_R` confirms the code is being compiled for R, and `Rconfig.h` (included by `<R.h>`) defines platform macros such as `WORDS_BIGENDIAN` — but note these describe the compiler that built R, not necessarily yours. For compile-time R version checks (`R_VERSION`, `R_Version()`), see [R version](r-version.llms.md). If you use `alloca`, define it portably via `Rconfig.h`’s `HAVE_ALLOCA_H` as shown in WRE §6.17.

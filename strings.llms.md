# 6  Strings

A character vector (`STRSXP`) is an array of pointers to `CHARSXP`s, and every `CHARSXP` lives in a global string pool. This means each distinct string is stored only once, however many character vectors reference it — and it means you should never modify the contents of a `CHARSXP`.

## 6.1 Encodings

Each `CHARSXP` carries an encoding flag. R assumes strings are in the native encoding unless marked otherwise; UTF-8 is the safe default for new code. See also [Querying CHARSXP encoding](https://cran.r-project.org/doc/manuals/R-exts.html#Querying-CHARSXP-encoding-1) in Writing R Extensions.

### 6.1.1 `cetype_t()` (`CE_NATIVE()`, `CE_UTF8()`, `CE_LATIN1()`, `CE_BYTES()`, `CE_SYMBOL()`, `CE_ANY()`)

Enumerate the encodings a CHARSXP can carry.

``` c
typedef enum {
  CE_NATIVE = 0,
  CE_UTF8   = 1,
  CE_LATIN1 = 2,
  CE_BYTES  = 3,
  CE_SYMBOL = 5,
  CE_ANY    = 99
} cetype_t;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

One of `CE_NATIVE`, `CE_UTF8`, `CE_LATIN1`, `CE_BYTES`, `CE_SYMBOL`, or `CE_ANY`.

**See also:** [`Rf_getCharCE()`](#Rf_getCharCE)

### 6.1.2 `Rf_getCharCE()`

Get the encoding of a CHARSXP.

``` c
cetype_t Rf_getCharCE(SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

**See also:** [`cetype_t()`](#cetype_t)

### 6.1.3 `Riconv()` (`Riconv_open()`, `Riconv_close()`)

Convert a string between encodings.

``` c
void *Riconv_open(const char *tocode, const char *fromcode);
size_t Riconv(void *cd, const char **inbuf, size_t *inbytesleft,
              char **outbuf, size_t *outbytesleft);
int Riconv_close(void *cd);
```

**Status:** API · **Header:** `R_ext/Riconv.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

A wrapper over the system `iconv()`, with the same calling convention. `""` as an encoding name means the current native encoding; `"UTF-8"` is always supported. Returns `(size_t) -1` on error, with `errno` set (`E2BIG` when the output buffer is full).

**See also:** [`Rf_reEnc()`](#Rf_reEnc)

## 6.2 Creating from C strings

These calls create `CHARSXP`s (or length-1 `STRSXP`s) from C strings. Typically they don’t need protection because the result is immediately assigned into a `STRSXP`.

They will crash R if passed `NULL`; check for it yourself and substitute `""` or `NA_STRING` as appropriate.

Most modern C libraries produce UTF-8, so you should typically use `Rf_mkCharCE()` or `Rf_mkCharLenCE()` with `CE_UTF8`, and avoid the native-encoding creation functions, including `Rf_mkString()`.

To re-encode strings from another encoding, use R’s wrapper around iconv in `R_ext/Riconv.h`, which provides cross-platform `Riconv_open()` and `Riconv()`. It’s usually best to convert to UTF-8. See [Re-encoding](https://cran.r-project.org/doc/manuals/R-exts.html#Re_002dencoding-1) in Writing R Extensions.

### 6.2.1 `Rf_mkChar()` (`Rf_mkCharLen()`)

Create a CHARSXP from a C string in the current encoding.

``` c
SEXP Rf_mkChar(const char* x);
SEXP Rf_mkCharLen(const char* x, int n);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

`Rf_mkChar()` takes a null-terminated string; `Rf_mkCharLen()` takes an explicit length. Protection is rarely needed since the result is usually assigned immediately into a `STRSXP`. Both crash R on `NULL` input, so check for it yourself and substitute `""` or `NA_STRING`.

**See also:** [`Rf_mkCharCE()`](#Rf_mkCharCE), [`Rf_ScalarString()`](#Rf_ScalarString)

### 6.2.2 `Rf_mkCharCE()` (`Rf_mkCharLenCE()`)

Create a CHARSXP from a C string in a specified encoding.

``` c
SEXP Rf_mkCharCE(const char* x, cetype_t encoding);
SEXP Rf_mkCharLenCE(const char* x, int n, cetype_t encoding);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

Prefer these over `Rf_mkChar()` and `Rf_mkString()` when the input is UTF-8, which is typical for modern C code.

**See also:** [`cetype_t()`](#cetype_t), [`Rf_mkChar()`](#Rf_mkChar)

### 6.2.3 `Rf_ScalarString()` (`Rf_mkString()`)

Create a length-1 STRSXP from a CHARSXP or C string.

``` c
SEXP Rf_ScalarString(SEXP);
SEXP Rf_mkString(const char*);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

`Rf_ScalarString()` builds a `STRSXP` from a `CHARSXP`; `Rf_mkString()` builds one from a C string. Both crash R on `NULL` input.

**See also:** [`Rf_mkChar()`](#Rf_mkChar)

## 6.3 Convert to C string

To access the C string stored in a `CHARSXP`, use `CHAR()`. (To match the other vector accessors like `INTEGER()`, this is typically called via the `Rf_`-less name.)

The `Rf_translateChar*` functions return a `const char*` in the specified encoding; most modern C APIs use UTF-8, so you almost always want `Rf_translateCharUTF8()`.

If re-encoding is necessary, the returned `char*` is allocated with `R_alloc()` and freed automatically at the end of the `.Call`; if you need it across calls, make a copy. If you make many translating calls in a loop, free the transient memory explicitly with `vmaxget()`/`vmaxset()`:

``` c
const void *vmax = vmaxget();
... // one or more calls to Rf_translateCharUTF8(), etc.
vmaxset(vmax);
```

### 6.3.1 `CHAR()` (`R_CHAR()`)

Access the underlying C string stored in a CHARSXP.

``` c
const char* R_CHAR(SEXP x);
#define CHAR(x) R_CHAR(x)
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

Named `CHAR()` for consistency with the other vector accessors (`LOGICAL()`, `INTEGER()`, …).

**See also:** [`Rf_translateCharUTF8()`](#Rf_translateCharUTF8)

### 6.3.2 `Rf_translateCharUTF8()` (`Rf_translateChar()`, `Rf_translateChar0()`)

Translate a CHARSXP to a C string in a specified encoding.

``` c
const char* Rf_translateChar(SEXP x);
const char* Rf_translateChar0(SEXP x);
const char* Rf_translateCharUTF8(SEXP x);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

`Rf_translateChar()` translates to the native encoding; `Rf_translateChar0()` leaves bytes-encoded strings alone and otherwise translates to native; `Rf_translateCharUTF8()` translates to UTF-8, which is what most modern C APIs want. A re-encoded `char*` is allocated with `R_alloc()` and freed automatically after the `.C`/`.Call`/`.External` returns; copy it if you need to keep it longer.

**See also:** [`CHAR()`](#CHAR)

## 6.4 Special values

### 6.4.1 `NA_STRING()` (`R_NaString()`)

Use the singleton CHARSXP representing NA.

``` c
SEXP R_NaString; // Singleton CHARSXP
#define NA_STRING R_NaString
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `NA_character_`

`R_NaString` is a singleton `CHARSXP`; `NA_STRING` is the macro alias.

**See also:** [`R_BlankString()`](#R_BlankString)

### 6.4.2 `R_BlankString()` (`R_BlankScalarString()`)

Use the global blank string objects.

``` c
SEXP R_BlankString; // CHARSXP
SEXP R_BlankScalarString; // STRSXP
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `""`

`R_BlankString` is a `CHARSXP`; `R_BlankScalarString` is a `STRSXP`.

**See also:** [`NA_STRING()`](#NA_STRING)

### 6.4.3 `Rf_StringBlank()` (`Rf_isBlankString()`)

Check whether a string is blank.

``` c
Rboolean Rf_StringBlank(SEXP);
Rboolean Rf_isBlankString(const char *);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

`Rf_StringBlank()` takes a `SEXP`; `Rf_isBlankString()` takes a `const char*`.

**See also:** [`R_BlankString()`](#R_BlankString)

### 6.4.4 `Rf_isValidString()` (`Rf_isValidStringF()`)

Check whether a STRSXP holds at least one valid string.

``` c
Rboolean Rf_isValidString(SEXP);
Rboolean Rf_isValidStringF(SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

`Rf_isValidString(x)` is `TYPEOF(x) == STRSXP && LENGTH(x) > 0 && TYPEOF(STRING_ELT(x, 0)) != NILSXP`; `Rf_isValidStringF(x)` is `isValidString(x) && CHAR(STRING_ELT(x, 0))[0]`.

## 6.5 Searching and matching

### 6.5.1 `Rf_pmatch()` (`Rf_psmatch()`)

Perform partial matching of strings.

``` c
Rboolean Rf_pmatch(SEXP, SEXP, Rboolean);
Rboolean Rf_psmatch(const char *, const char *, Rboolean);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** `pmatch()`

`Rf_psmatch()` is the variant for C strings.

**See also:** [`Rf_match()`](#Rf_match)

### 6.5.2 `Rf_stringPositionTr()`

Find the position of a string within a character vector.

``` c
int Rf_stringPositionTr(SEXP, const char *);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

## 6.6 Helper functions

### 6.6.1 `Rf_acopy_string()`

Copy a C string into memory allocated by R_alloc().

``` c
char* Rf_acopy_string(const char *);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

The copy is freed automatically at the next garbage collection.

### 6.6.2 `Rf_asChar()`

Render an R object to a CHARSXP.

``` c
SEXP Rf_asChar(SEXP x);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `as.character()`

### 6.6.3 `Rf_NonNullStringMatch()`

Check that two strings are equal and neither NA nor empty.

``` c
Rboolean Rf_NonNullStringMatch(SEXP s, SEXP t);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

Translates both strings to UTF-8 before comparing.

### 6.6.4 `Rf_reEnc()`

Re-encode a C string from one encoding to another.

``` c
const char *Rf_reEnc(const char *x, cetype_t ce_in, cetype_t ce_out, int subst);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

**See also:** [`cetype_t()`](#cetype_t)

### 6.6.5 `Rf_StringFalse()` (`Rf_StringTrue()`)

Test whether a C string represents false or true.

``` c
Rboolean Rf_StringFalse(const char *);
Rboolean Rf_StringTrue(const char *);
```

**Status:** experimental · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

Recognises the strings `as.logical()` accepts (`"T"`, `"TRUE"`, `"false"`, …); anything else returns `FALSE` from both.

### 6.6.6 Types

You can convert `SEXPTYPE`s to and from C strings:

### 6.6.7 `Rf_str2type()`

Convert a C string to a SEXPTYPE.

``` c
SEXPTYPE Rf_str2type(const char *);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

**See also:** [`Rf_type2str()`](#Rf_type2str)

### 6.6.8 `Rf_type2str()` (`Rf_type2char()`, `Rf_type2rstr()`, `Rf_type2str_nowarn()`)

Convert a SEXPTYPE to a string.

``` c
const char * Rf_type2char(SEXPTYPE);
SEXP Rf_type2rstr(SEXPTYPE);
SEXP Rf_type2str(SEXPTYPE);
SEXP Rf_type2str_nowarn(SEXPTYPE);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** never · **Since:** — · **R equivalent:** `typeof()`

`Rf_type2char()` returns a C string; `Rf_type2rstr()` returns a `STRSXP`; `Rf_type2str()` returns a `CHARSXP`. Only the `SEXP`-returning members need protection.

**See also:** [`Rf_str2type()`](#Rf_str2type)

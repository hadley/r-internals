# Strings (`CHARSXP`)

```cpp
typedef enum {
  CE_NATIVE = 0,
  CE_UTF8   = 1,
  CE_LATIN1 = 2,
  CE_BYTES  = 3,
  CE_SYMBOL = 5,
  CE_ANY    =99
} cetype_t;

cetype_t Rf_getCharCE(SEXP);
```


## Creating from C strings

```cpp
SEXP Rf_mkCharCE(const char*, cetype_t);
SEXP Rf_mkCharLenCE(const char*, int, cetype_t);
SEXP Rf_mkChar(const char*);
SEXP Rf_mkCharLen(const char*, int);

// Makes character vector from CHRSXP
SEXP Rf_ScalarString(SEXP);
// Makes character vector from C string
SEXP Rf_mkString(const char*);
```

```cpp
const char *Rf_reEnc(const char *x, cetype_t ce_in, cetype_t ce_out, int subst);
```

## Convert to C strings

```cpp
#define CHAR(x)		R_CHAR(x)
const char* R_CHAR(SEXP x);
const char* Rf_translateChar(SEXP);
const char* Rf_translateChar0(SEXP);
const char* Rf_translateCharUTF8(SEXP);
```

## Special values

```cpp
#define NA_STRING	R_NaString
LibExtern SEXP	R_NaString;	    /* NA_STRING as a CHARSXP */

Rboolean Rf_StringBlank(SEXP);
LibExtern SEXP	R_BlankString;	    /* "" as a CHARSXP */
LibExtern SEXP	R_BlankScalarString;	    /* "" as a STRSXP */
Rboolean isBlankString(const char *);
#define isBlankString Rf_isBlankString

#define StringFalse   Rf_StringFalse
Rboolean StringFalse(const char *);

#define StringTrue    Rf_StringTrue
Rboolean StringTrue(const char *);

// TYPEOF(x) == STRSXP && LENGTH(x) > 0 && TYPEOF(STRING_ELT(x, 0)) != NILSXP;
Rboolean Rf_isValidString(SEXP);
// isValidString(x) && CHAR(STRING_ELT(x, 0))[0];
Rboolean Rf_isValidStringF(SEXP);
```

## Helper functions

```cpp
typedef enum {Bytes, Chars, Width} nchar_type;
int R_nchar(SEXP string, nchar_type type_,
  Rboolean allowNA, Rboolean keepNA, const char* msg_name);
  
SEXP Rf_stringSuffix(SEXP, int);

// Return a copy of a string using memory from R_alloc.
// Caller responisble for freeing
char* Rf_acopy_string(const char *);

// Render any R object as a string (utils.c)
// Returns a CHARSXP
SEXP Rf_asChar(SEXP x); 

// Checks that s and t are equal (and not NA or "") (match.c)
// Translates both to UTF-8 for comparison
Rboolean Rf_NonNullStringMatch(SEXP s, SEXP t);
```

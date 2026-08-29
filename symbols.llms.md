# 9  Symbols

A symbol (`SYMSXP`) is a name, like `x` or `+`. Symbols are interned: there is exactly one `SYMSXP` per name, stored in a global table, so two symbols are equal iff they are the same pointer. Because they’re never garbage collected, symbols don’t need protection, and if you use one repeatedly it’s worth caching the result of `Rf_install()`.

## 9.1 Test

### 9.1.1 `Rf_isSymbol()`

Test whether an object is a symbol.

``` c
Rboolean Rf_isSymbol(SEXP s);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `is.symbol()`

## 9.2 Create

`Rf_install()` returns the existing symbol for a name, or creates it if it doesn’t exist yet.

### 9.2.1 `Rf_install()` (`Rf_installChar()`, `Rf_installTrChar()`)

Create the symbol for a name, returning the existing symbol if already present.

``` c
SEXP Rf_install(const char *);
SEXP Rf_installChar(SEXP);
SEXP Rf_installTrChar(SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** can throw · **Since:** — · **R equivalent:** `as.name()`

Symbols are never garbage collected, so `SYMSXP`s don’t need to be protected. Cache frequently used symbols to avoid repeated lookups. `Rf_installChar()` takes a CHARSXP; `Rf_installTrChar()` is the same but first translates the string to the native encoding.

## 9.3 Accessors

### 9.3.1 `PRINTNAME()`

Get the print name of a symbol.

``` c
SEXP (PRINTNAME)(SEXP x);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

Returns the name as a CHARSXP; use `CHAR(PRINTNAME(x))` for a `const char*`. There is no API setter — symbols are interned, so create the symbol you want with `Rf_install()` instead.

**See also:** [`Rf_install()`](#Rf_install)

## 9.4 Missing symbol

`R_MissingArg` represents the missing/empty symbol, i.e. the second argument in the call `f(x, )`.

### 9.4.1 `R_MissingArg()`

Access the missing/empty symbol.

``` c
SEXP R_MissingArg;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

Used as the second argument in a call like `f(x, )`.

## 9.5 Predefined symbols

A number of symbols are so commonly used that they’re predefined and exported as global constants — use these instead of calling `Rf_install()` yourself.

### 9.5.1 `R_dot_defined()`

Access the predefined symbol for “.defined”.

``` c
SEXP R_dot_defined;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.2 `R_dot_Method()`

Access the predefined symbol for “.Method”.

``` c
SEXP R_dot_Method;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.3 `R_dot_packageName()`

Access the predefined symbol for “.packageName”.

``` c
SEXP R_dot_packageName;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.4 `R_dot_target()`

Access the predefined symbol for “.target”.

``` c
SEXP R_dot_target;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.5 `R_BaseSymbol()`

Access the predefined symbol for “base”.

``` c
SEXP R_BaseSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.6 `R_BraceSymbol()`

Access the predefined symbol for “{”.

``` c
SEXP R_BraceSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.7 `R_Bracket2Symbol()`

Access the predefined symbol for “\[\[”.

``` c
SEXP R_Bracket2Symbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.8 `R_BracketSymbol()`

Access the predefined symbol for “\[”.

``` c
SEXP R_BracketSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.9 `R_ClassSymbol()`

Access the predefined symbol for “class”.

``` c
SEXP R_ClassSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.10 `R_DeviceSymbol()`

Access the predefined symbol for “.Device”.

``` c
SEXP R_DeviceSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.11 `R_DimNamesSymbol()`

Access the predefined symbol for “dimnames”.

``` c
SEXP R_DimNamesSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.12 `R_DimSymbol()`

Access the predefined symbol for “dim”.

``` c
SEXP R_DimSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.13 `R_DollarSymbol()`

Access the predefined symbol for “\$”.

``` c
SEXP R_DollarSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.14 `R_DotsSymbol()`

Access the predefined symbol for “…”.

``` c
SEXP R_DotsSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.15 `R_DoubleColonSymbol()`

Access the predefined symbol for “::”.

``` c
SEXP R_DoubleColonSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.16 `R_DropSymbol()`

Access the predefined symbol for “drop”.

``` c
SEXP R_DropSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.17 `R_LastvalueSymbol()`

Access the predefined symbol for “.Last.value”.

``` c
SEXP R_LastvalueSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.18 `R_LevelsSymbol()`

Access the predefined symbol for “levels”.

``` c
SEXP R_LevelsSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.19 `R_ModeSymbol()`

Access the predefined symbol for “mode”.

``` c
SEXP R_ModeSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.20 `R_NaRmSymbol()`

Access the predefined symbol for “na.rm”.

``` c
SEXP R_NaRmSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.21 `R_NameSymbol()`

Access the predefined symbol for “name”.

``` c
SEXP R_NameSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.22 `R_NamesSymbol()`

Access the predefined symbol for “names”.

``` c
SEXP R_NamesSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.23 `R_NamespaceEnvSymbol()`

Access the predefined symbol for “.\_\_NAMESPACE\_\_.”.

``` c
SEXP R_NamespaceEnvSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.24 `R_PackageSymbol()`

Access the predefined symbol for “package”.

``` c
SEXP R_PackageSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.25 `R_PreviousSymbol()`

Access the predefined symbol for “previous”.

``` c
SEXP R_PreviousSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.26 `R_QuoteSymbol()`

Access the predefined symbol for “quote”.

``` c
SEXP R_QuoteSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.27 `R_RowNamesSymbol()`

Access the predefined symbol for “row.names”.

``` c
SEXP R_RowNamesSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.28 `R_SeedsSymbol()`

Access the predefined symbol for “.Random.seed”.

``` c
SEXP R_SeedsSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.29 `R_SortListSymbol()`

Access the predefined symbol for “sort.list”.

``` c
SEXP R_SortListSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.30 `R_SourceSymbol()`

Access the predefined symbol for “source”.

``` c
SEXP R_SourceSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.31 `R_SpecSymbol()`

Access the predefined symbol for “spec”.

``` c
SEXP R_SpecSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.32 `R_TripleColonSymbol()`

Access the predefined symbol for `":::"`.

``` c
SEXP R_TripleColonSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

### 9.5.33 `R_TspSymbol()`

Access the predefined symbol for “tsp”.

``` c
SEXP R_TspSymbol;
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** —

# 9  Symbols

A symbol (`SYMSXP`) is a name, like `x` or `+`. Symbols are interned: there is exactly one `SYMSXP` per name, stored in a global table, so two symbols are equal iff they are the same pointer. Because they’re never garbage collected, symbols don’t need protection, and if you use one repeatedly it’s worth caching the result of `Rf_install()`.

## 9.1 Test

### 9.1.1 `Rf_isSymbol()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.symbol()`

Test whether an object is a symbol.

``` c
Rboolean Rf_isSymbol(SEXP s);
```

**Returns:** `TRUE` if `s` is a symbol (`SYMSXP`), otherwise `FALSE`.

## 9.2 Create

`Rf_install()` returns the existing symbol for a name, or creates it if it doesn’t exist yet.

### 9.2.1 `Rf_install()`, `Rf_installChar()`, `Rf_installTrChar()`

throws

**Header:** `Rinternals.h`\
**R equivalent:** `as.name()`

Create the symbol for a name, returning the existing symbol if already present.

``` c
SEXP Rf_install(const char *);
SEXP Rf_installChar(SEXP);
SEXP Rf_installTrChar(SEXP);
```

**Returns:** The symbol (`SYMSXP`) with the given name, creating it if necessary.

Symbols are never garbage collected, so `SYMSXP`s don’t need to be protected. Cache frequently used symbols to avoid repeated lookups. `Rf_installChar()` takes a CHARSXP; `Rf_installTrChar()` is the same but first translates the string to the native encoding.

## 9.3 Accessors

### 9.3.1 `PRINTNAME()`

**Header:** `Rinternals.h`

Get the print name of a symbol.

``` c
SEXP (PRINTNAME)(SEXP x);
```

**Returns:** The print name of the symbol `x` as a `CHARSXP`.

Returns the name as a CHARSXP; use `CHAR(PRINTNAME(x))` for a `const char*`. There is no API setter — symbols are interned, so create the symbol you want with `Rf_install()` instead.

**See also:** [`Rf_install()`](#Rf_install)

## 9.4 Missing symbol

`R_MissingArg` represents the missing/empty symbol, i.e. the second argument in the call `f(x, )`.

### 9.4.1 `R_MissingArg()`

**Header:** `Rinternals.h`

Access the missing/empty symbol.

``` c
SEXP R_MissingArg;
```

Used as the second argument in a call like `f(x, )`.

## 9.5 Predefined symbols

A number of symbols are so commonly used that they’re predefined and exported as global constants — use these instead of calling `Rf_install()` yourself.

### 9.5.1 `R_dot_defined()`

**Header:** `Rinternals.h`

Access the predefined symbol for “.defined”.

``` c
SEXP R_dot_defined;
```

### 9.5.2 `R_dot_Method()`

**Header:** `Rinternals.h`

Access the predefined symbol for “.Method”.

``` c
SEXP R_dot_Method;
```

### 9.5.3 `R_dot_packageName()`

**Header:** `Rinternals.h`

Access the predefined symbol for “.packageName”.

``` c
SEXP R_dot_packageName;
```

### 9.5.4 `R_dot_target()`

**Header:** `Rinternals.h`

Access the predefined symbol for “.target”.

``` c
SEXP R_dot_target;
```

### 9.5.5 `R_BaseSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “base”.

``` c
SEXP R_BaseSymbol;
```

### 9.5.6 `R_BraceSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “{”.

``` c
SEXP R_BraceSymbol;
```

### 9.5.7 `R_Bracket2Symbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “\[\[”.

``` c
SEXP R_Bracket2Symbol;
```

### 9.5.8 `R_BracketSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “\[”.

``` c
SEXP R_BracketSymbol;
```

### 9.5.9 `R_ClassSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “class”.

``` c
SEXP R_ClassSymbol;
```

### 9.5.10 `R_DeviceSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “.Device”.

``` c
SEXP R_DeviceSymbol;
```

### 9.5.11 `R_DimNamesSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “dimnames”.

``` c
SEXP R_DimNamesSymbol;
```

### 9.5.12 `R_DimSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “dim”.

``` c
SEXP R_DimSymbol;
```

### 9.5.13 `R_DollarSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “\$”.

``` c
SEXP R_DollarSymbol;
```

### 9.5.14 `R_DotsSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “…”.

``` c
SEXP R_DotsSymbol;
```

### 9.5.15 `R_DoubleColonSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “::”.

``` c
SEXP R_DoubleColonSymbol;
```

### 9.5.16 `R_DropSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “drop”.

``` c
SEXP R_DropSymbol;
```

### 9.5.17 `R_LastvalueSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “.Last.value”.

``` c
SEXP R_LastvalueSymbol;
```

### 9.5.18 `R_LevelsSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “levels”.

``` c
SEXP R_LevelsSymbol;
```

### 9.5.19 `R_ModeSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “mode”.

``` c
SEXP R_ModeSymbol;
```

### 9.5.20 `R_NaRmSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “na.rm”.

``` c
SEXP R_NaRmSymbol;
```

### 9.5.21 `R_NameSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “name”.

``` c
SEXP R_NameSymbol;
```

### 9.5.22 `R_NamesSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “names”.

``` c
SEXP R_NamesSymbol;
```

### 9.5.23 `R_NamespaceEnvSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “.\_\_NAMESPACE\_\_.”.

``` c
SEXP R_NamespaceEnvSymbol;
```

### 9.5.24 `R_PackageSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “package”.

``` c
SEXP R_PackageSymbol;
```

### 9.5.25 `R_PreviousSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “previous”.

``` c
SEXP R_PreviousSymbol;
```

### 9.5.26 `R_QuoteSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “quote”.

``` c
SEXP R_QuoteSymbol;
```

### 9.5.27 `R_RowNamesSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “row.names”.

``` c
SEXP R_RowNamesSymbol;
```

### 9.5.28 `R_SeedsSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “.Random.seed”.

``` c
SEXP R_SeedsSymbol;
```

### 9.5.29 `R_SortListSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “sort.list”.

``` c
SEXP R_SortListSymbol;
```

### 9.5.30 `R_SourceSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “source”.

``` c
SEXP R_SourceSymbol;
```

### 9.5.31 `R_SpecSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “spec”.

``` c
SEXP R_SpecSymbol;
```

### 9.5.32 `R_TripleColonSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for `":::"`.

``` c
SEXP R_TripleColonSymbol;
```

### 9.5.33 `R_TspSymbol()`

**Header:** `Rinternals.h`

Access the predefined symbol for “tsp”.

``` c
SEXP R_TspSymbol;
```

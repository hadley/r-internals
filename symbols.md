# Symbols (`SYMSXP`)

```cpp
Rboolean Rf_isSymbol(SEXP s);
```

## Create

If symbol exists, return it; otherwise create it. `SYMSXP`s don't need to be protected because symbols are not currently reclaimed by the garbage collector. If you are using a symbol many times, it may be worth caching it to avoid repeated lookups.

```cpp
SEXP Rf_install(const char *);
SEXP Rf_installChar(SEXP);
```

## Predefined symbols

A number of symbols are so commonly used, they're predefined and exported:

* `R_dot_defined`: ".defined"
* `R_dot_Method`: ".Method"
* `R_dot_packageName`:  ".packageName"
* `R_dot_target`: ".target"
* `R_BaseSymbol`: "base"
* `R_BraceSymbol`: "{"
* `R_Bracket2Symbol`: "[["
* `R_BracketSymbol`: "["
* `R_ClassSymbol`: "class"
* `R_DeviceSymbol`: ".Device"
* `R_DimNamesSymbol`: "dimnames"
* `R_DimSymbol`: "dim"
* `R_DollarSymbol`: "$"
* `R_DotsSymbol`: "..."
* `R_DoubleColonSymbol`:  "::"
* `R_DropSymbol`: "drop"
* `R_LastvalueSymbol`: ".Last.value"
* `R_LevelsSymbol`: "levels"
* `R_ModeSymbol`: "mode"
* `R_NaRmSymbol`: "na.rm"
* `R_NameSymbol`: "name"
* `R_NamesSymbol`: "names"
* `R_NamespaceEnvSymbol`:  ".\_\_NAMESPACE\_\_."
* `R_PackageSymbol`: "package"
* `R_PreviousSymbol`: "previous"
* `R_QuoteSymbol`: "quote"
* `R_RowNamesSymbol`: "row.names"
* `R_SeedsSymbol`: ".Random.seed"
* `R_SortListSymbol`: "sort.list"
* `R_SourceSymbol`: "source"
* `R_SpecSymbol`: "spec"
* `R_TripleColonSymbol`:  ":::"
* `R_TspSymbol`: "tsp"

## Internals

```cpp
SEXP (PRINTNAME)(SEXP x);
void SET_PRINTNAME(SEXP x, SEXP v);

SEXP (SYMVALUE)(SEXP x);
void SET_SYMVALUE(SEXP x, SEXP v);

SEXP (INTERNAL)(SEXP x);
void SET_INTERNAL(SEXP x, SEXP v);

int  (DDVAL)(SEXP x);
void (SET_DDVAL)(SEXP x, int v);
SEXP Rf_installDDVAL(int i);
```

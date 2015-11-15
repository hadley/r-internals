# Symbols (`SYMSXP`)

## Create and test

```cpp
Rboolean (Rf_isSymbol)(SEXP s);

SEXP Rf_install(const char *);
SEXP Rf_installChar(SEXP);
```

## Predefined symbols

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
SEXP (SYMVALUE)(SEXP x);
SEXP (INTERNAL)(SEXP x);
int  (DDVAL)(SEXP x);
void (SET_DDVAL)(SEXP x, int v);
void SET_PRINTNAME(SEXP x, SEXP v);
void SET_SYMVALUE(SEXP x, SEXP v);
void SET_INTERNAL(SEXP x, SEXP v);
```



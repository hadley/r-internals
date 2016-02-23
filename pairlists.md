# Pairlists (`LISTSXP`, `DOTSXP` & `LANGSXP`)

Pairlists are linked lists used for calls, unevaluated arguments, attributes, and in `...`. 
```cpp
Rboolean Rf_isPairList(SEXP); // LISTSXP
Rboolean Rf_isLanguage(SEXP); // LANGSXP
Rboolean Rf_isList(SEXP);     // LISTSXP, NILSXP
```

Pairlists are always terminated with `R_NilValue`. To loop over all elements of a pairlist, use this template:

```cpp
int length(SEXP s) {
  SEXP el;
  int i = 0;
  
  for(SEXP nxt = x; nxt != R_NilValue; el = CAR(nxt), nxt = CDR(nxt)) {
    i++;
  }
  
  return i;
}
```
## Creation

```cpp
#define CONS(a, b) cons((a), (b))  /* data lists */
#define LCONS(a, b) lcons((a), (b))  /* language lists */
```

Must end with `R_NilValue`. 

There are helpers for 5-6 arguments:

```cpp
SEXP Rf_list1(SEXP x1);
SEXP Rf_list2(SEXP x1, SEXP x2);
SEXP Rf_list3(SEXP x1, SEXP x2, SEXP x3);
SEXP Rf_list4(SEXP x1, SEXP x2, SEXP x3, SEXP x4);
SEXP Rf_list5(SEXP x1, SEXP x2, SEXP x3, SEXP x4, SEXP x5);

SEXP Rf_lang1(SEXP x1);
SEXP Rf_lang2(SEXP x1, SEXP x2);
SEXP Rf_lang3(SEXP x1, SEXP x2, SEXP x3);
SEXP Rf_lang4(SEXP x1, SEXP x2, SEXP x3, SEXP x4);
SEXP Rf_lang5(SEXP x1, SEXP x2, SEXP x3, SEXP x4, SEXP x5);
SEXP Rf_lang6(SEXP x1, SEXP x2, SEXP x3, SEXP x4, SEXP x5, SEXP x6);

SEXP Rf_allocFormalsList2(SEXP x1, SEXP x2);
SEXP Rf_allocFormalsList3(SEXP x1, SEXP x2, SEXP x3);
SEXP Rf_allocFormalsList4(SEXP x1, SEXP x2, SEXP x3, SEXP x4);
SEXP Rf_allocFormalsList5(SEXP x1, SEXP x2, SEXP x3, SEXP x4, SEXP x5);
SEXP Rf_allocFormalsList6(SEXP x1, SEXP x2, SEXP x3, SEXP x4, SEXP x5, SEXP x6);
```

```cpp
SEXP Rf_PairToVectorList(SEXP x);
SEXP Rf_VectorToPairList(SEXP x);
SEXP Rf_listAppend(SEXP, SEXP);
```

You can also create an empty pairlist of set size:

```cpp
SEXP Rf_allocList(int n); 
```

## Accessors

Unlike lists (`VECSXP`s), pairlists (`LISTSXP`s) have no way to index into an arbitrary location. Instead, R provides a set of helper functions that navigate along a linked list. The basic helpers are `CAR()`, which extracts the first element of the list, and `CDR()`, which extracts the rest of the list. These can be composed to get `CAAR()`, `CDAR()`, `CADDR()`, `CADDDR()`, and so on. Corresponding to the getters, R provides setters `SETCAR()`, `SETCDR()`, etc.

```cpp
SEXP CAR(SEXP e);
SEXP CDR(SEXP e);
SEXP CAAR(SEXP e);
SEXP CDAR(SEXP e);
SEXP CADR(SEXP e);
SEXP CDDR(SEXP e);
SEXP CDDDR(SEXP e);
SEXP CADDR(SEXP e);
SEXP CADDDR(SEXP e);
SEXP CAD4R(SEXP e);
SEXP SETCAR(SEXP x, SEXP y);
SEXP SETCDR(SEXP x, SEXP y);
SEXP SETCADR(SEXP x, SEXP y);
SEXP SETCADDR(SEXP x, SEXP y);
SEXP SETCADDDR(SEXP x, SEXP y);
SEXP SETCAD4R(SEXP e, SEXP y);

SEXP Rf_nthcdr(SEXP, int);

void SET_TAG(SEXP x, SEXP y);
SEXP (TAG)(SEXP e);

// CONS with no-refcounting ?
SEXP CONS_NR(SEXP a, SEXP b);


// Used for missing values in function calls?
int  (MISSING)(SEXP x);
void (SET_MISSING)(SEXP x, int v);
```

## Dots (`DOTSXP`)

Represents the `...` structure in R. Easiest to get to with `findVar(R_DotsSymbol, env)` or similar. Is usually a pair list, but will have value `R_MissingArg` if there are no arguments.

## Null (`NILSXP`)

There is a single value with type `NILSXP`: `R_NilValue`.  This corresponds to `NULL` in R, and is often used as generic zero length vector.

## Attributes

```cpp
SEXP Rf_getAttrib(SEXP x, SEXP symbol);
SEXP Rf_setAttrib(SEXP x, SEXP symbol, SEXP value);

// Copies attributes except names, dim, and dimnames
void Rf_copyMostAttrib(SEXP source, SEXP target);
```

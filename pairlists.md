# Pairlists (`NILSXP`, `LISTSXP`, `DOTSXP` & `LANGSXP`)

In R code, there are only a few instances when you need to care about the difference between a pairlist and a list (as described in [Pairlists](#pairlists)). In C, pairlists play much more important role because they are used for calls, unevaluated arguments, attributes, and in `...`. In C, lists and pairlists differ primarily in how you access and name elements. \index{pairlists}

Unlike lists (`VECSXP`s), pairlists (`LISTSXP`s) have no way to index into an arbitrary location. Instead, R provides a set of helper functions that navigate along a linked list. The basic helpers are `CAR()`, which extracts the first element of the list, and `CDR()`, which extracts the rest of the list. These can be composed to get `CAAR()`, `CDAR()`, `CADDR()`, `CADDDR()`, and so on. Corresponding to the getters, R provides setters `SETCAR()`, `SETCDR()`, etc.


```cpp
SEXP Rf_allocList(int);
Rboolean Rf_isPairList(SEXP);
Rboolean Rf_isLanguage(SEXP);
Rboolean Rf_isList(SEXP);
```

## Accessors

```cpp
SEXP (TAG)(SEXP e);
SEXP (CAR)(SEXP e);
SEXP (CDR)(SEXP e);
SEXP (CAAR)(SEXP e);
SEXP (CDAR)(SEXP e);
SEXP (CADR)(SEXP e);
SEXP (CDDR)(SEXP e);
SEXP (CDDDR)(SEXP e);
SEXP (CADDR)(SEXP e);
SEXP (CADDDR)(SEXP e);
SEXP (CAD4R)(SEXP e);
int  (MISSING)(SEXP x);
void (SET_MISSING)(SEXP x, int v);
void SET_TAG(SEXP x, SEXP y);
SEXP SETCAR(SEXP x, SEXP y);
SEXP SETCDR(SEXP x, SEXP y);
SEXP SETCADR(SEXP x, SEXP y);
SEXP SETCADDR(SEXP x, SEXP y);
SEXP SETCADDDR(SEXP x, SEXP y);
SEXP SETCAD4R(SEXP e, SEXP y);

SEXP Rf_nthcdr(SEXP, int);


// CONS with no-refcounting ?
SEXP CONS_NR(SEXP a, SEXP b);
```

## Null (`NILSXP`)

```cpp
#define NILSXP	     0	  /* nil = NULL */
Rboolean (Rf_isNull)(SEXP s);
LibExtern SEXP	R_NilValue;	    /* The nil object */
```

## Dots (`DOTSXP`)



## Creation

```cpp
#define CONS(a, b)	cons((a), (b))		/* data lists */
#define LCONS(a, b)	lcons((a), (b))		/* language lists */

SEXP	 Rf_list1(SEXP);
SEXP	 Rf_list2(SEXP, SEXP);
SEXP	 Rf_list3(SEXP, SEXP, SEXP);
SEXP	 Rf_list4(SEXP, SEXP, SEXP, SEXP);
SEXP	 Rf_list5(SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP	 Rf_listAppend(SEXP, SEXP);

SEXP	 Rf_lang1(SEXP);
SEXP	 Rf_lang2(SEXP, SEXP);
SEXP	 Rf_lang3(SEXP, SEXP, SEXP);
SEXP	 Rf_lang4(SEXP, SEXP, SEXP, SEXP);
SEXP	 Rf_lang5(SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP	 Rf_lang6(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
```

## Coercion

```cpp
SEXP Rf_PairToVectorList(SEXP x);
SEXP Rf_VectorToPairList(SEXP x);
```

## Attributes

```cpp
void Rf_copyMostAttrib(SEXP, SEXP);
SEXP Rf_getAttrib(SEXP, SEXP);
SEXP Rf_setAttrib(SEXP, SEXP, SEXP);
```

There are some (confusingly named) shortcuts for common setting operations: `classgets()`, `namesgets()`, `dimgets()`, and `dimnamesgets()` are the internal versions of the default methods of `class<-`, `names<-`, `dim<-`, and `dimnames<-`.


## Language

```cpp
SEXP Rf_allocFormalsList2(SEXP sym1, SEXP sym2);
SEXP Rf_allocFormalsList3(SEXP sym1, SEXP sym2, SEXP sym3);
SEXP Rf_allocFormalsList4(SEXP sym1, SEXP sym2, SEXP sym3, SEXP sym4);
SEXP Rf_allocFormalsList5(SEXP sym1, SEXP sym2, SEXP sym3, SEXP sym4, SEXP sym5);
SEXP Rf_allocFormalsList6(SEXP sym1, SEXP sym2, SEXP sym3, SEXP sym4, SEXP sym5, SEXP sym6);
```

# Garbage collection and reference counting

## GC

You might wonder what all the `PROTECT()` calls do. They tell R that the object is in use and shouldn't be deleted if the garbage collector is activated. (We don't need to protect objects that R already knows we're using, like function arguments.)

You also need to make sure that every protected object is unprotected. `UNPROTECT()` takes a single integer argument, `n`, and unprotects the last n objects that were protected. The number of protects and unprotects must match. If not, R will warn about a "stack imbalance in .Call".  Other specialised forms of protection are needed in some circumstances: 

* `UNPROTECT_PTR()` unprotects the object pointed to by the `SEXP`,

* `PROTECT_WITH_INDEX()` saves an index of the protection location that can 
  be used to replace the protected value using `REPROTECT()`. 
  
Consult the R externals section on [garbage collection](http://cran.r-project.org/doc/manuals/R-exts.html#Garbage-Collection) for more details.

## How PROTECT works

Objects protected by `PROTECT()` are placed on a protection stack (internally called `R_PPStack`), which itself is just an array of `SEXP`s. A protection index, called `R_PPStackTop`, denotes the top of the protection stack. When `UNPROTECT()`ing a (number) of objects, the stack top is decremented, and so all `SEXP`s 'overflowing' the `R_PPStack` are considered unprotected and hence eligible for garbage collection.

Note that this implies that `PROTECT_WITH_INDEX()` and `REPROTECT()` are merely APIs for modifying elements within the protection stack. `UNPROTECT_PTR()` performs a search (from the top of the stack) to find the element to unprotect.

## Using PROTECT

Properly protecting the R objects you allocate is extremely important! Improper protection leads to difficulty diagnosing errors, typically segfaults, but other corruption is possible as well. In general, if you allocate a new R object, you must `PROTECT` it.

### R_PreserveObject, R_ReleaseObject

The primary structure that R uses for protecting objects is the so-called `R_PreciousList`, which is just a pairlist of `SEXP`s. The aforementioned `R_PPStack` is part of this `R_PreciousList` (and hence is the mechanism by which those `SEXP`s become protected). `R_PreserveObject()` and `R_ReleaseObject()` are mechanisms for inserting and removing `SEXP`s from this precious list.

These functions need to be used with care: because `R_ReleaseObject()` will perform a recursive search for the object to protect, if many `SEXP`s are inserted and later removed in the same order, this can cause performance regressions. See [this dplyr issue](https://github.com/hadley/dplyr/issues/1396) for an interesting manifestation of this problem.

```cpp
#define NEWSXP      30    /* fresh node created in new page */
#define FREESXP     31    /* node released by GC */

void R_PreserveObject(SEXP);
void R_ReleaseObject(SEXP);

void R_ProtectWithIndex(SEXP, PROTECT_INDEX *);
void R_Reprotect(SEXP, PROTECT_INDEX);
SEXP Rf_protect(SEXP);
void Rf_unprotect_ptr(SEXP);
void Rf_unprotect(int);

/* Pointer Protection and Unprotection */
#define PROTECT(s)	Rf_protect(s)
#define UNPROTECT(n)	Rf_unprotect(n)
#define UNPROTECT_PTR(s)	Rf_unprotect_ptr(s)

/* We sometimes need to coerce a protected value and place the new
coerced value under protection.  For these cases PROTECT_WITH_INDEX
saves an index of the protection location that can be used to
replace the protected value using REPROTECT. */
typedef int PROTECT_INDEX;
#define PROTECT_WITH_INDEX(x,i) R_ProtectWithIndex(x,i)
#define REPROTECT(x,i) R_Reprotect(x,i)

void	R_gc(void);
int	  R_gc_running();

Rboolean R_cycle_detected(SEXP s, SEXP child);

```

## Memory size

```cpp
void*	vmaxget(void);
void	vmaxset(const void *);
```

## Manual memory management

```cpp
char*	R_alloc(size_t, int);
long double *R_allocLD(size_t nelem);
char*	S_alloc(long, int);
char*	S_realloc(char *, long, long, int);
```

## Reference counting

You must be very careful when modifying function inputs. If you're working with lists, use `shallow_duplicate()` to make a shallow copy; `duplicate()` will also copy every element in the list.


```cpp
#define MAYBE_SHARED(x) (NAMED(x) > 1)
#define NO_REFERENCES(x) (NAMED(x) == 0)
#define MARK_NOT_MUTABLE(x) SET_NAMED(x, NAMEDMAX)
#define MAYBE_REFERENCED(x) (! NO_REFERENCES(x))
#define NOT_SHARED(x) (! MAYBE_SHARED(x))

/* Complex assignment support */
/* temporary definition that will need to be refined to distinguish
getter from setter calls */
#define IS_GETTER_CALL(call) (CADR(call) == R_TmpvalSymbol)
```

### Efficient copying

```cpp
SEXP Rf_duplicate(SEXP);
SEXP Rf_shallow_duplicate(SEXP);
SEXP Rf_lazy_duplicate(SEXP);
```

### Internals

```cpp
/* General Cons Cell Attributes */
int  (OBJECT)(SEXP x);
int  (MARK)(SEXP x);
int  (TYPEOF)(SEXP x);
int  (NAMED)(SEXP x);
int  (REFCNT)(SEXP x);
void (SET_OBJECT)(SEXP x, int v);
void (SET_TYPEOF)(SEXP x, int v);
void (SET_NAMED)(SEXP x, int v);

int  (LEVELS)(SEXP x);
int  (SETLEVELS)(SEXP x, int v);

#define TYPE_BITS 5
#define MAX_NUM_SEXPTYPE (1<<TYPE_BITS)

```

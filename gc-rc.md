# Garbage collection and reference counting

## GC

You might wonder what all the `PROTECT()` calls do. They tell R that the object is in use and shouldn't be deleted if the garbage collector is activated. (We don't need to protect objects that R already knows we're using, like function arguments.)

You also need to make sure that every protected object is unprotected. `UNPROTECT()` takes a single integer argument, `n`, and unprotects the last n objects that were protected. The number of protects and unprotects must match. If not, R will warn about a "stack imbalance in .Call".  Other specialised forms of protection are needed in some circumstances: 

* `UNPROTECT_PTR()` unprotects the object pointed to by the `SEXP`s. 

* `PROTECT_WITH_INDEX()` saves an index of the protection location that can 
  be used to replace the protected value using `REPROTECT()`. 
  
Consult the R externals section on [garbage collection](http://cran.r-project.org/doc/manuals/R-exts.html#Garbage-Collection) for more details.

Properly protecting the R objects you allocate is extremely important! Improper protection leads to difficulty diagnosing errors, typically segfaults, but other corruption is possible as well. In general, if you allocate a new R object, you must `PROTECT` it.

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
SEXP (ATTRIB)(SEXP x);
int  (OBJECT)(SEXP x);
int  (MARK)(SEXP x);
int  (TYPEOF)(SEXP x);
int  (NAMED)(SEXP x);
int  (REFCNT)(SEXP x);
void (SET_OBJECT)(SEXP x, int v);
void (SET_TYPEOF)(SEXP x, int v);
void (SET_NAMED)(SEXP x, int v);
void SET_ATTRIB(SEXP x, SEXP v);
void DUPLICATE_ATTRIB(SEXP to, SEXP from);
void SHALLOW_DUPLICATE_ATTRIB(SEXP to, SEXP from);

int  (LEVELS)(SEXP x);
int  (SETLEVELS)(SEXP x, int v);

#define TYPE_BITS 5
#define MAX_NUM_SEXPTYPE (1<<TYPE_BITS)

```

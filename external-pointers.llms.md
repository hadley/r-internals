# 12  External pointers

An external pointer (`EXTPTRSXP`) wraps a C `void*` so it can be passed through R code. R treats the pointer as opaque; you use it to manage C-side resources (handles, connections, data structures) that outlive a single `.Call`. Because R can’t see what the pointer owns, you register a finalizer to release the resource when the SEXP is garbage collected.

## 12.1 Create and access

### 12.1.1 `R_MakeExternalPtr()`

needs protect throws

**Header:** `Rinternals.h`

Create an external pointer wrapping a C pointer.

``` c
SEXP R_MakeExternalPtr(void *p, SEXP tag, SEXP prot);
```

**Returns:** A new external pointer (`EXTPTRSXP`) wrapping `p`.

`tag` and `prot` are arbitrary SEXPs stored alongside the C pointer; `prot` stays protected from garbage collection while the external pointer is reachable.

### 12.1.2 `R_ClearExternalPtr()`

**Header:** `Rinternals.h`

Clear the address stored in an external pointer.

``` c
void R_ClearExternalPtr(SEXP s);
```

### 12.1.3 `R_ExternalPtrAddr()`, `R_ExternalPtrTag()`, `R_ExternalPtrProtected()`, `R_SetExternalPtrAddr()`, `R_SetExternalPtrTag()`, `R_SetExternalPtrProtected()`

**Header:** `Rinternals.h`

Get and set the address, tag, and protected fields of an external pointer.

``` c
void *R_ExternalPtrAddr(SEXP s);
SEXP R_ExternalPtrTag(SEXP s);
SEXP R_ExternalPtrProtected(SEXP s);
void R_SetExternalPtrAddr(SEXP s, void *p);
void R_SetExternalPtrTag(SEXP s, SEXP tag);
void R_SetExternalPtrProtected(SEXP s, SEXP p);
```

**Returns:** `R_ExternalPtrAddr()` returns the stored C pointer; `R_ExternalPtrTag()` and `R_ExternalPtrProtected()` return the tag and protected fields.

### 12.1.4 `R_MakeExternalPtrFn()`, `R_ExternalPtrAddrFn()`

needs protect throws

**Header:** `Rinternals.h`

Wrap a C function pointer in an external pointer.

``` c
SEXP R_MakeExternalPtrFn(DL_FUNC p, SEXP tag, SEXP prot);
DL_FUNC R_ExternalPtrAddrFn(SEXP s);
```

- `p`: the function pointer to wrap.
- `tag`: an identifying tag, often `R_NilValue`.
- `prot`: an object to protect from GC while the pointer lives.

**Returns:** `R_MakeExternalPtrFn()` returns a new external pointer wrapping `p`; `R_ExternalPtrAddrFn()` returns the stored function pointer.

The function-pointer analogue of `R_MakeExternalPtr()`; storing a `DL_FUNC` directly avoids casting between object and function pointers, which is undefined behaviour in C.

**See also:** [`R_MakeExternalPtr()`](#R_MakeExternalPtr), [`R_ExternalPtrAddr()`](#R_ExternalPtrAddr)

## 12.2 Finalization

A finalizer has the signature:

``` c
typedef void (*R_CFinalizer_t)(SEXP);
```

### 12.2.1 `R_RegisterCFinalizer()`, `R_RegisterFinalizer()`, `R_RegisterFinalizerEx()`, `R_RegisterCFinalizerEx()`

throws

**Header:** `Rinternals.h`

Register a finalizer to run when an external pointer is garbage collected.

``` c
void R_RegisterFinalizer(SEXP s, SEXP fun);
void R_RegisterCFinalizer(SEXP s, R_CFinalizer_t fun);
void R_RegisterFinalizerEx(SEXP s, SEXP fun, Rboolean onexit);
void R_RegisterCFinalizerEx(SEXP s, R_CFinalizer_t fun, Rboolean onexit);
```

`R_RegisterFinalizer()` takes an R function and `R_RegisterCFinalizer()` a C function of type `R_CFinalizer_t`. The `Ex` variants add an `onexit` argument controlling whether the finalizer also runs when R shuts down.

## 12.3 Weak references

Weak references (`WEAKREFXP`) reference an object without keeping it alive; they’re used with finalizers to run code when an object is collected.

### 12.3.1 `R_MakeWeakRef()`, `R_MakeWeakRefC()`

needs protect throws

**Header:** `Rinternals.h`

Create a weak reference.

``` c
SEXP R_MakeWeakRef(SEXP key, SEXP val, SEXP fin, Rboolean onexit);
SEXP R_MakeWeakRefC(SEXP key, SEXP val, R_CFinalizer_t fin, Rboolean onexit);
```

**Returns:** A newly created weak reference object.

`R_MakeWeakRef()` takes an R function finalizer; `R_MakeWeakRefC()` takes a C finalizer of type `R_CFinalizer_t`.

### 12.3.2 `R_WeakRefKey()`, `R_WeakRefValue()`

**Header:** `Rinternals.h`

Get the key or value of a weak reference.

``` c
SEXP R_WeakRefKey(SEXP w);
SEXP R_WeakRefValue(SEXP w);
```

**Returns:** `R_WeakRefKey()` returns the key and `R_WeakRefValue()` the value stored in `w`.

### 12.3.3 `R_RunWeakRefFinalizer()`

throws

**Header:** `Rinternals.h`

Run the finalizer attached to a weak reference.

``` c
void R_RunWeakRefFinalizer(SEXP w);
```

# 4  Memory allocation

Sometimes you need scratch memory that isn’t an R object — a work array, a lookup table. R offers two kinds of allocation, differing in who cleans up: **transient** memory that R reclaims automatically, and **user-controlled** memory that you must free yourself, including on error paths. These functions are declared in `R_ext/Memory.h` and `R_ext/RS.h` (both included by `<R.h>`), and are not thread-safe.

## 4.1 Transient allocation

Follows [WRE §6.1.1, Transient storage allocation](https://cran.r-project.org/doc/manuals/R-exts.html#Transient-storage-allocation-1) closely.

`R_alloc()` memory comes from R’s heap arena and is released automatically when your `.Call` entry point returns — including when an error or interrupt unwinds the stack. That makes it the default choice: it is impossible to leak. If you call `R_alloc()` in a loop, bound the growth by resetting the arena’s high-water mark each iteration:

``` c
void *vmax = vmaxget();
for (...) {
  double *work = (double *) R_alloc(n, sizeof(double));
  ...
  vmaxset(vmax);
}
```

The returned memory is only guaranteed to be aligned for `double`; use `R_allocLD()` if you need `long double` alignment.

### 4.1.1 `R_alloc()`, `R_allocLD()`

throws

**Header:** `R_ext/Memory.h`

Allocate temporary memory that R reclaims automatically.

``` c
char* R_alloc(size_t, int);
long double *R_allocLD(size_t nelem);
```

**Returns:** A pointer to the allocated memory, freed automatically when the `.Call` entry point returns.

Memory is freed automatically when the `.Call` entry point returns (including on error or interrupt). `R_allocLD()` additionally guarantees the 16-byte alignment some platforms need for `long double`.

**See also:** [`vmaxget()`](#vmaxget)

### 4.1.2 `S_alloc()`, `S_realloc()`

throws

**Header:** `R_ext/Memory.h`

Allocate and reallocate temporary memory using the legacy S interface.

``` c
char* S_alloc(long, int);
char* S_realloc(char *, long, long, int);
```

**Returns:** A pointer to the allocated (or reallocated) temporary memory.

Best avoided: `long` is limited to 2^31 - 1 bytes on 64-bit Windows, so these cannot handle large allocations there. Prefer `R_alloc()`.

**See also:** [`R_alloc()`](#R_alloc)

### 4.1.3 `vmaxget()`, `vmaxset()`

**Header:** `R_ext/Memory.h`

Get and set the high-water mark of R’s temporary allocation arena.

``` c
void* vmaxget(void);
void vmaxset(const void *);
```

**Returns:** `vmaxget()` returns the current allocation high-water mark, for passing back to `vmaxset()`.

`vmaxset()` releases everything allocated by `R_alloc()` since the matching `vmaxget()`. Useful to bound memory growth when calling `R_alloc()` in a loop, but easy to get wrong — for experts only.

**See also:** [`R_alloc()`](#R_alloc)

## 4.2 User-controlled memory

Follows [WRE §6.1.2, User-controlled memory](https://cran.r-project.org/doc/manuals/R-exts.html#User_002dcontrolled-memory) closely.

`R_Calloc()`/`R_Realloc()`/`R_Free()` are for memory that must outlive the call or whose lifetime doesn’t fit the arena model. The catch is the longjmp contract ([Calling C from R](calling-c.llms.md)): if R errors between allocation and free, your `R_Free()` never runs and the memory leaks. Options, in rough order of preference:

- Keep the allocation inside one function and wrap the body in `R_UnwindProtect()` with a cleanup handler that frees it.
- Free from an `on.exit()` action in the calling R function (base R’s `pwilcox` does this).
- Attach the memory to an external pointer with a finalizer ([External pointers](external-pointers.llms.md)) when it must persist across calls.

Also provided: `CallocCharBuf(n)` (a `char` buffer of `n + 1` for the NUL terminator), and `Memcpy()`/`Memzero()` for copying and zeroing arrays.

### 4.2.1 `R_Calloc()`, `R_Realloc()`, `R_Free()`

throws

**Header:** `R_ext/RS.h`

Allocate, reallocate, and free user-controlled memory with R error handling.

``` c
type* R_Calloc(size_t n, type);
type* R_Realloc(any *p, size_t n, type);
void R_Free(any *p);
```

**Returns:** `R_Calloc()` and `R_Realloc()` return a pointer to the allocated memory; never `NULL`, since failure raises an R error.

Analogues of `calloc()`/`realloc()`/`free()`; on allocation failure R throws an error, so a returned pointer is always valid. You must `R_Free()` on every path, including error paths (see `R_UnwindProtect()`). Never mix with `malloc()`/`free()`, and never call the underlying `R_chk_calloc()` etc. directly. The legacy `Calloc`/`Realloc`/`Free` spellings were removed in R 4.5.0.

**See also:** [`R_alloc()`](#R_alloc)

### 4.2.2 `R_malloc_gc()`, `R_calloc_gc()`, `R_realloc_gc()`

**Header:** `R_ext/Memory.h`

Allocate memory, retrying after a garbage collection on failure.

``` c
void *R_malloc_gc(size_t);
void *R_calloc_gc(size_t, size_t);
void *R_realloc_gc(void *, size_t);
```

**Returns:** A pointer to the allocated memory, or `NULL` if allocation fails even after a garbage collection.

Like `malloc()`/`calloc()`/`realloc()`, but if the allocation fails a garbage collection is run and the allocation retried. Memory must be released with `free()`.

**See also:** [`R_Calloc()`](#R_Calloc)

## 4.3 When to use a RAWSXP instead

If the memory should be managed by R’s garbage collector, visible to R, or returned to R, don’t use either of the above — allocate a `RAWSXP` ([Vectors](vectors.llms.md)) and work in `RAW(x)`. You get GC-managed lifetime, `PROTECT` semantics, and alignment suitable for any type, at the cost of an R object header.

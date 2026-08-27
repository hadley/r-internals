## 6 The R API: entry points for C code <a href="#The-R-API_003a-entry-points-for-C-code"
class="copiable-link">¶</a>

There are a large number of entry points in the R executable/DLL that
can be called from C code (and a few that can be called from Fortran
code). Only those documented here are stable enough that they will only
be changed with considerable notice.

As explained elsewhere in this manual, these functions should only be
called from the main thread of the R process. (Doing otherwise can
result in memory corruption and very hard-to-debug segfaults.)

The recommended procedure to use these is to include the header file
`R.h` in your C code by

<div class="example">

``` example-preformatted
#include <R.h>
```

</div>

This will include several other header files from the directory
`R_INCLUDE_DIR``/R_ext`, and there are other header files there that can
be included too, but many of the features they contain should be
regarded as undocumented and unstable.

Most of these header files, including all those included by `R.h`, can
be used from C++ code. (However, they cannot safely be included in a
`extern "C" { }` block as they may include C++ headers when included
from C++ code—and whether this succeeds is system-specific).

> **Note:** Because R re-maps many of its external names to avoid
> clashes with system or user code, it is *essential* to include the
> appropriate header files when using these entry points.

This remapping can cause
problems<a href="#FOOT164" id="DOCF164" class="footnote"><sup>164</sup></a>,
and can be eliminated by defining `R_NO_REMAP` (before including any R
headers) and prepending ‘`Rf_`’ to *all* the function names used from
`Rinternals.h` and `R_ext/Error.h`. These problems can usually be
avoided by including other headers (such as system headers and those for
external software used by the package) before any R headers. (Headers
from other packages may include R headers directly or *via* inclusion
from further packages, and may define `R_NO_REMAP` with or without
including `Rinternals.h`.) <span id="index-R_005fext_002fError_002eh"
class="index-entry-id"></span>

As from R 4.5.0, `R_NO_REMAP` is always defined when the R headers are
included from C++ code.

If you decide to define `R_NO_REMAP` in your code, do use something like

<div class="example">

``` example-preformatted
#ifndef R_NO_REMAP
# define R_NO_REMAP
#endif
```

</div>

to avoid distracting compiler warnings.

Some of these entry points are declared in header `Rmath.h`, most of
which are remapped there. That remapping can be eliminated by defining
`R_NO_REMAP_RMATH` (before including any R headers) and prepending
‘`Rf_`’ to the function names used from that header except

<div class="example">

``` example-preformatted
exp_rand norm_rand unif_rand signrank_free wilcox_free
```

</div>

We can classify the entry points as

*API*  
Entry points which are documented in this manual and declared in an
installed header file. These can be used in distributed packages and
ideally will only be changed after deprecation. See
<a href="#API-index" class="xref">API index</a>.

*public*  
Entry points declared in an installed header file that are exported on
all R platforms but are not documented and subject to change without
notice. Do not use these in distributed code. Their declarations will
eventually be moved out of installed header files.

*private*  
Entry points that are used when building R and exported on all R
platforms but are not declared in the installed header files. Do not use
these in distributed code.

*hidden*  
Entry points that are where possible (Windows and some modern Unix-alike
compilers/loaders when using R as a shared library) not exported.

*experimental*  
Entry points declared in an installed header file that are part of an
experimental API, such as `R_ext/Altrep.h`. These are subject to change,
so package authors wishing to use these should be prepared to adapt. See
<a href="#Experimental-API-index" class="xref">Experimental API
index</a>.

*embedding*  
Entry points intended primarily for embedding and creating new
front-ends. It is not clear that this needs to be a separate category
but it may be useful to keep it separate for now. See
<a href="#Embedding-API-index" class="xref">Embedding API index</a>.

<span id="index-R_005fext_002fAltrep_002eh-1"
class="index-entry-id"></span>

If you would like to use an entry point or variable that is not
identified as part of the API in this document, or is currently hidden,
you can make a request for it to be made available. Entry points or
variables not identified as in the API may be changed or removed with no
notice as part of efforts to improve aspects of R.

**Work in progress:** Currently Entry points in the API are identified
in the source for this document with `@apifun`, `@eapifun`, and
`@embfun` entries. Similarly, `@apivar`, `@eapivar`, and `@embvar`
identify variables, and `@apihdr`, `@eapihdr`, and `@embhdr` identify
headers in the API. `@forfun` identifies entry points to be called as
Fortran subroutines. This could be used for programmatic extraction, but
the specific format is work in progress and even the way this document
is produced is subject to change.

- [Memory allocation](#Memory-allocation)
- [Error signaling](#Error-signaling)
- [Random number generation](#Random-numbers)
- [Missing and IEEE special values](#Missing-and-IEEE-values)
- [Printing](#Printing)
- [Calling C from Fortran and vice
  versa](#Calling-C-from-Fortran-and-vice-versa)
- [Numerical analysis subroutines](#Numerical-analysis-subroutines)
- [Optimization](#Optimization)
- [Integration](#Integration)
- [Utility functions](#Utility-functions)
- [Linear algebra](#Linear-algebra)
- [Re-encoding](#Re_002dencoding)
- [Condition handling and cleanup
  code](#Condition-handling-and-cleanup-code)
- [Allowing interrupts](#Allowing-interrupts)
- [C stack checking](#C-stack-checking)
- [Custom serialization input and
  output](#Custom-serialization-input-and-output)
- [Platform and version information](#Platform-and-version-information)
- [Inlining C functions](#Inlining-C-functions)
- [Controlling visibility](#Controlling-visibility)
- [Using these functions in your own C code](#Standalone-Mathlib)
- [Organization of header files](#Organization-of-header-files)
- [Hash tables](#Hash-tables)
- [Moving into C API compliance](#Moving-into-C-API-compliance)

------------------------------------------------------------------------

<div id="Memory-allocation" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Error-signaling" rel="next">Error signaling</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.1 Memory allocation <a href="#Memory-allocation-1" class="copiable-link">¶</a>

<span id="index-Memory-allocation-from-C" class="index-entry-id"></span>

There are two types of memory allocation available to the C programmer,
one in which R manages the clean-up and the other in which users have
full control (and responsibility).

These functions are declared in header `R_ext/RS.h` which is included by
`R.h`.

- [Transient storage allocation](#Transient-storage-allocation)
- [User-controlled memory](#User_002dcontrolled-memory)

------------------------------------------------------------------------

<div id="Transient-storage-allocation" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#User_002dcontrolled-memory" rel="next">User-controlled
memory</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Memory-allocation" rel="up">Memory allocation</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.1.1 Transient storage allocation <a href="#Transient-storage-allocation-1" class="copiable-link">¶</a>

<span id="index-R_005falloc-1" class="index-entry-id"></span>
<span id="index-R_005falloc-3" class="index-entry-id"></span>
<span id="index-R_005fallocLD" class="index-entry-id"></span>
<span id="index-R_005fallocLD-1" class="index-entry-id"></span>
<span id="index-S_005falloc" class="index-entry-id"></span>
<span id="index-S_005falloc-1" class="index-entry-id"></span>
<span id="index-S_005frealloc" class="index-entry-id"></span>
<span id="index-S_005frealloc-1" class="index-entry-id"></span>
<span id="index-vmaxget" class="index-entry-id"></span>
<span id="index-vmaxget-1" class="index-entry-id"></span>
<span id="index-vmaxset" class="index-entry-id"></span>
<span id="index-vmaxset-1" class="index-entry-id"></span>
<span id="index-Rf_005fnrows" class="index-entry-id"></span>
<span id="index-Rf_005fnrows-1" class="index-entry-id"></span>
<span id="index-Rf_005fncols" class="index-entry-id"></span>
<span id="index-Rf_005fncols-1" class="index-entry-id"></span>

Here R will reclaim the memory at the end of the call to `.C`, `.Call`
or `.External`. Use

<div class="example">

``` example-preformatted
char *R_alloc(size_t n, int size)
```

</div>

which allocates `n` units of `size` bytes each. A typical usage (from
package **stats**) is

<div class="example">

``` example-preformatted
x = (int *) R_alloc(nrows(merge)+2, sizeof(int));
```

</div>

(`size_t` is defined in `stddef.h` which the header defining `R_alloc`
includes.)

There is a similar call, `S_alloc` (named for compatibility with older
versions of S) which zeroes the memory allocated,

<div class="example">

``` example-preformatted
char *S_alloc(long n, int size)
```

</div>

and

<div class="example">

``` example-preformatted
char *S_realloc(char *p, long new, long old, int size)
```

</div>

which (for `new`` > ``old`) changes the allocation size from `old` to
`new` units, and zeroes the additional units. NB: these calls are best
avoided as `long` is insufficient for large memory allocations on 64-bit
Windows (where it is limited to 2^31-1 bytes).

This memory is taken from the heap, and released at the end of the `.C`,
`.Call` or `.External` call. Users can also manage it, by noting the
current position with a call to `vmaxget` and subsequently clearing
memory allocated by a call to `vmaxset`. An example might be

<div class="example">

``` example-preformatted
void *vmax = vmaxget()
// a loop involving the use of R_alloc at each iteration
vmaxset(vmax)
```

</div>

This is only recommended for experts.

Note that this memory will be freed on error or user interrupt (if
allowed: see
<a href="#Allowing-interrupts" class="pxref">Allowing interrupts</a>).

The memory returned is only guaranteed to be aligned as required for
`double` pointers: take precautions if casting to a pointer which needs
more. There is also

<div class="example">

``` example-preformatted
long double *R_allocLD(size_t n)
```

</div>

which is guaranteed to have the 16-byte alignment needed for
`long double` pointers on some platforms.

These functions should only be used in code called by `.C` etc, never
from front-ends. They are not thread-safe.

------------------------------------------------------------------------

</div>

<div id="User_002dcontrolled-memory" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Transient-storage-allocation" rel="prev">Transient storage
allocation</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Memory-allocation" rel="up">Memory allocation</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.1.2 User-controlled memory <a href="#User_002dcontrolled-memory-1" class="copiable-link">¶</a>

The other form of memory allocation is an interface to `malloc`, the
interface providing R error signaling. This memory lasts until freed by
the user and is additional to the memory allocated for the R workspace.

The interface macros are

<div class="example">

<div class="group">

``` example-preformatted
type* R_Calloc(size_t n, type)
type* R_Realloc(any *p, size_t n, type)
void R_Free(any *p)
```

</div>

</div>

<span id="index-R_005fCalloc" class="index-entry-id"></span>
<span id="index-R_005fCalloc-1" class="index-entry-id"></span>
<span id="index-R_005fRealloc" class="index-entry-id"></span>
<span id="index-R_005fRealloc-1" class="index-entry-id"></span>
<span id="index-R_005fFree" class="index-entry-id"></span>
<span id="index-R_005fFree-1" class="index-entry-id"></span>

providing analogues of `calloc`, `realloc` and `free`. If there is an
error during allocation it is handled by R, so if these return the
memory has been successfully allocated or freed. `R_Free` will set the
pointer `p` to `NULL`.

Users should arrange to `R_Free` this memory when no longer needed,
including on error or user interrupt. This can often be done most
conveniently from an `on.exit` action in the calling R function – see
`pwilcox` for an example.

Do not assume that memory allocated by `R_Calloc`/`R_Realloc` comes from
the same pool as used by
`malloc`:<a href="#FOOT165" id="DOCF165" class="footnote"><sup>165</sup></a>
in particular do not use `free` or `strdup` with it.

Memory obtained by these macros should be aligned in the same way as
`malloc`, that is ‘suitably aligned for any kind of variable’.

Historically the macros `Calloc`, `Free` and `Realloc` were used but
have been removed in \R 4.5.0.

`R_Calloc`, `R_Realloc`, and `R_Free` are currently implemented as
macros expanding to calls to `R_chk_calloc`, `R_chk_realloc`, and
`R_chk_free`, respectively. These should not be called directly as they
may be removed in the future. <span id="index-R_005fchk_005fcalloc"
class="index-entry-id"></span> <span id="index-R_005fchk_005fcalloc-1"
class="index-entry-id"></span> <span id="index-R_005fchk_005frealloc"
class="index-entry-id"></span> <span id="index-R_005fchk_005frealloc-1"
class="index-entry-id"></span> <span id="index-R_005fchk_005ffree"
class="index-entry-id"></span> <span id="index-R_005fchk_005ffree-1"
class="index-entry-id"></span>

<span id="index-CallocCharBuf" class="index-entry-id"></span>
<span id="index-Memcpy" class="index-entry-id"></span>
<span id="index-Memzero" class="index-entry-id"></span>

<div class="example">

<div class="group">

``` example-preformatted
char * CallocCharBuf(size_t n)
void * Memcpy(q, p, n)
void * Memzero(p, n)
```

</div>

</div>

`CallocCharBuf(n)` is shorthand for `R_Calloc(n+1, char)` to allow for
the `nul` terminator. `Memcpy` and `Memzero` take `n` items from array
`p` and copy them to array `q` or zero them respectively.
<span id="index-R_005fchk_005fmemcpy" class="index-entry-id"></span>
<span id="index-R_005fchk_005fmemcpy-1" class="index-entry-id"></span>
<span id="index-R_005fchk_005fmemset" class="index-entry-id"></span>
<span id="index-R_005fchk_005fmemset-1" class="index-entry-id"></span>

------------------------------------------------------------------------

</div>

</div>

<div id="Error-signaling" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Random-numbers" rel="next">Random number generation</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Memory-allocation" rel="prev">Memory allocation</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.2 Error signaling <a href="#Error-signaling-1" class="copiable-link">¶</a>

<span id="index-Error-signaling-from-C" class="index-entry-id"></span>

The basic error signaling routines are the equivalents of `stop` and
`warning` in R code, and use the same interface.

<div class="example">

<div class="group">

``` example-preformatted
void Rf_error(const char * format, ...);
void Rf_warning(const char * format, ...);
void Rf_errorcall(SEXP call, const char * format, ...);
void Rf_warningcall(SEXP call, const char * format, ...);
void Rf_warningcall_immediate(SEXP call, const char * format, ...);
```

</div>

</div>

<span id="index-Rf_005ferror" class="index-entry-id"></span>
<span id="index-Rf_005ferror-1" class="index-entry-id"></span>
<span id="index-Rf_005fwarning" class="index-entry-id"></span>
<span id="index-Rf_005fwarning-1" class="index-entry-id"></span>
<span id="index-Rf_005ferrorcall" class="index-entry-id"></span>
<span id="index-Rf_005ferrorcall-1" class="index-entry-id"></span>
<span id="index-Rf_005fwarningcall" class="index-entry-id"></span>
<span id="index-Rf_005fwarningcall-1" class="index-entry-id"></span>
<span id="index-Rf_005fwarningcall_005fimmediate"
class="index-entry-id"></span>
<span id="index-Rf_005fwarningcall_005fimmediate-1"
class="index-entry-id"></span>

These have the same call sequences as calls to `printf`, but in the
simplest case can be called with a single character string argument
giving the error message. (Don’t do this if the string contains ‘`%`’ or
might otherwise be interpreted as a format.)

These are defined in header `R_ext/Error.h` included by `R.h`. **NB**:
when `R_NO_REMAP` is defined (as is done for C++ code), `Rf_error` etc
must be used.

Header `R_ext/Error.h` defines a macro `NORET` intended to be used only
from C code (C++ code can use the `[[noreturn]]` attribute). This covers
various ways to signal to the compiler that the function never returns.
Because the usages of those ways differ by C standard, it should always
be used at the beginning of a function declaration, including before
`static` and attributes such as `attribute_hidden`.

- [Error signaling from Fortran](#Error-signaling-from-Fortran)

------------------------------------------------------------------------

<div id="Error-signaling-from-Fortran" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Error-signaling" rel="up">Error signaling</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.2.1 Error signaling from Fortran <a href="#Error-signaling-from-Fortran-1" class="copiable-link">¶</a>

<span id="index-Error-signaling-from-Fortran"
class="index-entry-id"></span>

There are two interface function provided to call `Rf_error` and
`Rf_warning` from Fortran code, in each case with a simple character
string argument. They are defined as

<div class="example">

<div class="group">

``` example-preformatted
subroutine rexit(message)
subroutine rwarn(message)
```

</div>

</div>

<span id="index-rexit-1" class="index-entry-id"></span>
<span id="index-rexit" class="index-entry-id"></span>
<span id="index-rwarn-1" class="index-entry-id"></span>
<span id="index-rwarn" class="index-entry-id"></span>

Messages of more than 255 characters are truncated, with a warning.

The subroutine `xerbla` is also available for compatibility with BLAS
and LAPACK, but is not intended for use in packages.
<span id="index-xerbla-1" class="index-entry-id"></span>
<span id="index-xerbla" class="index-entry-id"></span>

------------------------------------------------------------------------

</div>

</div>

<div id="Random-numbers" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Missing-and-IEEE-values" rel="next">Missing and IEEE special
values</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Error-signaling" rel="prev">Error signaling</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.3 Random number generation <a href="#Random-number-generation" class="copiable-link">¶</a>

<span id="index-Random-numbers-in-C" class="index-entry-id"></span>
<span id="index-unif_005frand" class="index-entry-id"></span>
<span id="index-unif_005frand-1" class="index-entry-id"></span>
<span id="index-norm_005frand" class="index-entry-id"></span>
<span id="index-norm_005frand-1" class="index-entry-id"></span>
<span id="index-exp_005frand" class="index-entry-id"></span>
<span id="index-exp_005frand-1" class="index-entry-id"></span>
<span id="index-R_005funif_005findex" class="index-entry-id"></span>
<span id="index-R_005funif_005findex-1" class="index-entry-id"></span>
<span id="index-GetRNGstate" class="index-entry-id"></span>
<span id="index-GetRNGstate-1" class="index-entry-id"></span>
<span id="index-PutRNGstate" class="index-entry-id"></span>
<span id="index-PutRNGstate-1" class="index-entry-id"></span>
<span id="index-_002eRandom_002eseed" class="index-entry-id"></span>

The interface to R’s internal random number generation routines is

<div class="example">

<div class="group">

``` example-preformatted
double unif_rand();
double norm_rand();
double exp_rand();
double R_unif_index(double);
```

</div>

</div>

giving one uniform, normal or exponential pseudo-random variate.
However, before these are used, the user must call

<div class="example">

``` example-preformatted
GetRNGstate();
```

</div>

and after all the required variates have been generated, call

<div class="example">

``` example-preformatted
PutRNGstate();
```

</div>

These essentially read in (or create) `.Random.seed` and write it out
after use.

These are defined in header `R_ext/Random.h`. These functions are never
remapped.

The random number generator is private to R; there is no way to select
the kind of RNG nor set the seed except by evaluating calls to the R
functions which do so.

The C code behind R’s `r``xxx` functions can be accessed by including
the header file `Rmath.h`; See
<a href="#Distribution-functions" class="xref">Distribution
functions</a>. Those calls should also be preceded and followed by calls
to `GetRNGstate` and `PutRNGstate`.

- [Random-number generation from
  Fortran](#Random_002dnumber-generation-from-Fortran)

------------------------------------------------------------------------

<div id="Random_002dnumber-generation-from-Fortran"
class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Random-numbers" rel="up">Random number generation</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.3.1 Random-number generation from Fortran <a href="#Random_002dnumber-generation-from-Fortran-1"
class="copiable-link">¶</a>

It was explained earlier that Fortran random-number generators should
not be used in R packages, not least as packages cannot safely
initialize them. Rather a package should call R’s built-in generators:
one way to do so is to use C wrappers like

<div class="example">

``` example-preformatted
#include <R_ext/RS.h>
#include <R_ext/Random.h>

void F77_SUB(getRNGseed)(void) {
    GetRNGstate();
}
void F77_SUB(putRNGseed)(void) {
    PutRNGstate();
}
double F77_SUB(unifRand)(void) {
    return(unif_rand());
}
```

</div>

called from Fortran code like

<div class="example">

``` example-preformatted
      ...
      double precision X
      call getRNGseed()
      X = unifRand()
      ...
      call putRNGseed()
```

</div>

Alternatively one could use Fortran 2003’s `iso_c_binding` module by
something like (fixed-form Fortran 90 code):

<div class="example">

``` example-preformatted
      module rngfuncs
        use iso_c_binding
        interface
          double precision
     *      function unifRand() bind(C, name = "unif_rand")
          end function unifRand

          subroutine getRNGseed() bind(C, name = "GetRNGstate")
          end subroutine getRNGseed

          subroutine putRNGseed() bind(C, name = "PutRNGstate")
          end subroutine putRNGseed
        end interface
      end module rngfuncs

      subroutine testit
      use rngfuncs
      double precision X
      call getRNGseed()
      X = unifRand()
      print *, X
      call putRNGSeed()
      end subroutine testit
```

</div>

------------------------------------------------------------------------

</div>

</div>

<div id="Missing-and-IEEE-values" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Printing" rel="next">Printing</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Random-numbers" rel="prev">Random number generation</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.4 Missing and IEEE special values <a href="#Missing-and-IEEE-special-values" class="copiable-link">¶</a>

<span id="index-Missing-values-1" class="index-entry-id"></span>
<span id="index-IEEE-special-values-1" class="index-entry-id"></span>
<span id="index-ISNA-1" class="index-entry-id"></span>
<span id="index-ISNA-3" class="index-entry-id"></span>
<span id="index-ISNAN-1" class="index-entry-id"></span>
<span id="index-ISNAN-3" class="index-entry-id"></span>
<span id="index-R_005fFINITE" class="index-entry-id"></span>
<span id="index-R_005fFINITE-1" class="index-entry-id"></span>
<span id="index-R_005fIsNaN" class="index-entry-id"></span>
<span id="index-R_005fIsNaN-1" class="index-entry-id"></span>
<span id="index-R_005fPosInf" class="index-entry-id"></span>
<span id="index-R_005fPosInf-1" class="index-entry-id"></span>
<span id="index-R_005fNegInf" class="index-entry-id"></span>
<span id="index-R_005fNegInf-1" class="index-entry-id"></span>
<span id="index-NA_005fREAL-1" class="index-entry-id"></span>
<span id="index-NA_005fREAL-3" class="index-entry-id"></span>

A set of functions is provided to test for `NA`, `Inf`, `-Inf` and
`NaN`. These functions are accessed *via* macros:

<div class="example">

<div class="group">

``` example-preformatted
ISNA(x)        True for R’s NA only
ISNAN(x)       True for R’s NA and IEEE NaN
R_FINITE(x)    False for Inf, -Inf, NA, NaN
```

</div>

</div>

and *via* function `R_IsNaN` which is true for `NaN` but not `NA`.

Do use `R_FINITE` rather than `isfinite` or `finite`; the latter is
often mendacious and `isfinite` is only available on a some platforms,
on which `R_FINITE` is a macro expanding to `isfinite`.

Currently in C code `ISNAN` is a macro calling `isnan`. (Since this
gives problems on some C++ systems, if the R headers are called from C++
code a function call is used.)

You can check for `Inf` or `-Inf` by testing equality to `R_PosInf` or
`R_NegInf`, and set (but not test) an `NA` as `NA_REAL`.

All of the above apply to *double* variables only. For integer variables
there is a variable accessed by the macro `NA_INTEGER` which can used to
set or test for missingness.

These are defined in header `R_ext/Arith.h` included by `R.h`.

------------------------------------------------------------------------

</div>

<div id="Printing" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Calling-C-from-Fortran-and-vice-versa" rel="next">Calling C
from Fortran and vice versa</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Missing-and-IEEE-values" rel="prev">Missing and IEEE special
values</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.5 Printing <a href="#Printing-1" class="copiable-link">¶</a>

<span id="index-Printing-from-C" class="index-entry-id"></span>
<span id="index-Rprintf" class="index-entry-id"></span>
<span id="index-Rprintf-1" class="index-entry-id"></span>
<span id="index-REprintf" class="index-entry-id"></span>
<span id="index-REprintf-1" class="index-entry-id"></span>
<span id="index-Rvprintf" class="index-entry-id"></span>
<span id="index-Rvprintf-1" class="index-entry-id"></span>
<span id="index-REvprintf" class="index-entry-id"></span>
<span id="index-REvprintf-1" class="index-entry-id"></span>

The most useful function for printing from a C routine compiled into R
is `Rprintf`. This is used in exactly the same way as `printf`, but is
guaranteed to write to R’s output (which might be a GUI console rather
than a file, and can be re-directed by `sink`). It is wise to write
complete lines (including the `"\n"`) before returning to R. It is
defined in `R_ext/Print.h`.

The function `REprintf` is similar but writes on the error stream
(`stderr`) which may or may not be different from the standard output
stream.

Functions `Rvprintf` and `REvprintf` are analogues using the `vprintf`
interface. Because that is a
C99<a href="#FOOT166" id="DOCF166" class="footnote"><sup>166</sup></a>
interface, they are only defined by `R_ext/Print.h` in C++ code if the
macro `R_USE_C99_IN_CXX` is defined before it is included or (as from R
4.0.0) a C++11 compiler is used.

Another circumstance when it may be important to use these functions is
when using parallel computation on a cluster of computational nodes, as
their output will be re-directed/logged appropriately.

- [Printing from Fortran](#Printing-from-Fortran)

------------------------------------------------------------------------

<div id="Printing-from-Fortran" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Printing" rel="up">Printing</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.5.1 Printing from Fortran <a href="#Printing-from-Fortran-1" class="copiable-link">¶</a>

<span id="index-Printing-from-Fortran" class="index-entry-id"></span>

On many systems Fortran `write` and `print` statements can be used, but
the output may not interleave well with that of C, and may be invisible
on GUI interfaces. They are not portable and best avoided.

Some subroutines are provided to ease the output of information from
Fortran code.

<span id="index-dblepr-1" class="index-entry-id"></span>
<span id="index-dblepr" class="index-entry-id"></span>
<span id="index-realpr-1" class="index-entry-id"></span>
<span id="index-realpr" class="index-entry-id"></span>
<span id="index-intpr-1" class="index-entry-id"></span>
<span id="index-intpr" class="index-entry-id"></span>

<div class="example">

<div class="group">

``` example-preformatted
subroutine dblepr(label, nchar, data, ndata)
subroutine realpr(label, nchar, data, ndata)
subroutine intpr (label, nchar, data, ndata)
```

</div>

</div>

and from R 4.0.0, <span id="index-labelpr-1"
class="index-entry-id"></span> <span id="index-labelpr"
class="index-entry-id"></span> <span id="index-dblepr1-1"
class="index-entry-id"></span> <span id="index-dblepr1"
class="index-entry-id"></span> <span id="index-realpr1-1"
class="index-entry-id"></span> <span id="index-realpr1"
class="index-entry-id"></span> <span id="index-intpr1-1"
class="index-entry-id"></span> <span id="index-intpr1"
class="index-entry-id"></span>

<div class="example">

<div class="group">

``` example-preformatted
subroutine labelpr(label, nchar)
subroutine dblepr1(label, nchar, var)
subroutine realpr1(label, nchar, var)
subroutine intpr1 (label, nchar, var)
```

</div>

</div>

Here `label` is a character label of up to 255 characters, `nchar` is
its length (which can be `-1` if the whole label is to be used), `data`
is an array of length at least `ndata` of the appropriate type
(`double precision`, `real` and `integer` respectively) and `var` is a
(scalar) variable. These routines print the label on one line and then
print `data` or `var` as if it were an R vector on subsequent line(s).
Note that some compilers will give an error or warning unless `data` is
an array: others will accept a scalar when `ndata` has value one or
zero. **NB:** There is no check on the type of `data` or `var`, so using
`real` (including a real constant) instead of `double precision` will
give incorrect answers.

`intpr` works with zero `ndata` so can be used to print a label in
earlier versions of R.

------------------------------------------------------------------------

</div>

</div>

<div id="Calling-C-from-Fortran-and-vice-versa"
class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Numerical-analysis-subroutines" rel="next">Numerical analysis
subroutines</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Printing" rel="prev">Printing</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.6 Calling C from Fortran and vice versa <a href="#Calling-C-from-Fortran-and-vice-versa-1"
class="copiable-link">¶</a>

<span id="index-Calling-C-from-Fortran-and-vice-versa"
class="index-entry-id"></span>

Naming conventions for symbols generated by Fortran differ by platform:
it is not safe to assume that Fortran names appear to C with a trailing
underscore. To help cover up the platform-specific differences there is
a set of
macros<a href="#FOOT167" id="DOCF167" class="footnote"><sup>167</sup></a>
that should be used.

`F77_SUB(``name``)`  
to define a function in C to be called from Fortran

`F77_NAME(``name``)`  
to declare a Fortran routine in C before use

`F77_CALL(``name``)`  
to call a Fortran routine from C

On current platforms these are the same, but it is unwise to rely on
this. Note that names containing underscores were not legal in Fortran
77, and are not portably handled by the above macros. (Also, all Fortran
names for use by R are lower case, but this is not enforced by the
macros.)

For example, suppose we want to call R’s normal random numbers from
Fortran. We need a C wrapper along the lines of

<span id="index-Random-numbers-in-Fortran"
class="index-entry-id"></span>

<div class="example">

<div class="group">

``` example-preformatted
#include <R.h>

void F77_SUB(rndstart)(void) { GetRNGstate(); }
void F77_SUB(rndend)(void) { PutRNGstate(); }
double F77_SUB(normrnd)(void) { return norm_rand(); }
```

</div>

</div>

to be called from Fortran as in

<div class="example">

<div class="group">

``` example-preformatted
      subroutine testit()
      double precision normrnd, x
      call rndstart()
      x = normrnd()
      call dblepr("X was", 5, x, 1)
      call rndend()
      end
```

</div>

</div>

Note that this is not guaranteed to be portable, for the return
conventions might not be compatible between the C and Fortran compilers
used. (Passing values *via* arguments is safer.)

The standard packages, for example **stats**, are a rich source of
further examples.

Where supported, *link time optimization* provides a reliable way to
check the consistency of calls to C from Fortran or *vice versa*. See
<a href="#Using-Link_002dtime-Optimization" class="xref">Using Link-time
Optimization</a>. One place where this occurs is the registration of
`.Fortran` calls in C code (see
<a href="#Registering-native-routines" class="pxref">Registering native
routines</a>). For example

<div class="example">

``` example-preformatted
init.c:10:13: warning: type of 'vsom_' does not match original
 declaration [-Wlto-type-mismatch]
  extern void F77_NAME(vsom)(void *, void *, void *, void *,
    void *, void *, void *, void *, void *);
vsom.f90:20:33: note: type mismatch in parameter 9
   subroutine vsom(neurons,dt,dtrows,dtcols,xdim,ydim,alpha,train)
vsom.f90:20:33: note: 'vsom' was previously declared here
```

</div>

shows that a subroutine has been registered with 9 arguments (as that is
what the `.Fortran` call used) but only has 8.

- [Fortran character strings](#Fortran-character-strings)
- [Fortran LOGICAL](#Fortran-LOGICAL)
- [Passing functions](#Passing-functions)

------------------------------------------------------------------------

<div id="Fortran-character-strings" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Fortran-LOGICAL" rel="next">Fortran LOGICAL</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Calling-C-from-Fortran-and-vice-versa" rel="up">Calling C from
Fortran and vice versa</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.6.1 Fortran character strings <a href="#Fortran-character-strings-1" class="copiable-link">¶</a>

Passing character strings from C to Fortran or *vice versa* is not
portable, but can be done with care. The internal representations are
different: a character array in C (or C++) is NUL-terminated so its
length can be computed by `strlen`. Fortran character arrays are
typically stored as an array of bytes and a length. This matters when
passing strings from C to Fortran or *vice versa*: in many cases one has
been able to get away with passing the string but not the length.
However, in 2019 this changed for `gfortran`, starting with version 9
but backported to versions 7 and 8. Several months later, `gfortran` 9.2
introduced an option

<div class="example">

``` example-preformatted
-ftail-call-workaround
```

</div>

and made it the current default but said it might be withdrawn in
future.

Suppose we want a function to report a message from Fortran to R’s
console (one could use `labelpr`, or `intpr` with dummy data, but this
might be the basis of a custom reporting function). Suppose the
equivalent in Fortran would be

<div class="example">

``` example-preformatted
      subroutine rmsg(msg)
      character*(*) msg
      print *.msg
      end
```

</div>

in file `rmsg.f`. Using `gfortran` 9.2 and later we can extract the C
view by

<div class="example">

``` example-preformatted
gfortran -c -fc-prototypes-external rmsg.f
```

</div>

which gives

<div class="example">

``` example-preformatted
void rmsg_ (char *msg, size_t msg_len);
```

</div>

(where `size_t` applies to version 8 and later). We could re-write that
portably in C as

<div class="example">

``` example-preformatted
#ifndef USE_FC_LEN_T
# define USE_FC_LEN_T
#endif
#include <Rconfig.h> // included by R.h, so define USE_FC_LEN_T early

void F77_NAME(rmsg)(char *msg, FC_LEN_T msg_len)
{
    char cmsg[msg_len+1];
    strncpy(cmsg, msg, msg_len);
    cmsg[msg_len] = '\0'; // nul-terminate the string, to be sure
    // do something with 'cmsg'
}
```

</div>

in code depending on `R(>= 3.6.2)`. For earlier versions of R we could
just assume that `msg` is NUL-terminated (not guaranteed, but people
have been getting away with it for many years), so the complete C side
might be

<div class="example">

``` example-preformatted
#ifndef USE_FC_LEN_T
# define USE_FC_LEN_T
#endif
#include <Rconfig.h>

#ifdef FC_LEN_T
void F77_NAME(rmsg)(char *msg, FC_LEN_T msg_len)
{
    char cmsg[msg_len+1];
    strncpy(cmsg, msg, msg_len);
    cmsg[msg_len] = '\0';
    // do something with 'cmsg'
}
#else
void F77_NAME(rmsg)(char *msg)
{
    // do something with 'msg'
}
#endif
```

</div>

(`USE_FC_LEN_T` is the default as from R 4.3.0.)

An alternative is to use Fortran 2003 features to set up the Fortran
routine to pass a C-compatible character string. We could use something
like

<div class="example">

``` example-preformatted
      module cfuncs
        use iso_c_binding, only: c_char, c_null_char
        interface
          subroutine cmsg(msg) bind(C, name = 'cmsg')
            use iso_c_binding, only: c_char
            character(kind = c_char):: msg(*)
          end subroutine cmsg
        end interface
      end module

      subroutine rmsg(msg)
        use cfuncs
        character(*) msg
        call cmsg(msg//c_null_char) ! need to concatenate a nul terminator
      end subroutine rmsg
```

</div>

where the C side is simply

<div class="example">

``` example-preformatted
void cmsg(const char *msg)
{
    // do something with nul-terminated string 'msg'
}
```

</div>

If you use `bind` to a C function as here, the only way to check that
the bound definition is correct is to compile the package with LTO
(which requires compatible C and Fortran compilers, usually `gcc` and
`gfortran`).

Passing a variable-length string from C to Fortran is trickier, but <a
href="https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2023-0/bind-c.html"
class="uref">https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2023-0/bind-c.html</a>
provides a recipe. However, all the uses in BLAS and LAPACK are of a
single character, and for these we can write a wrapper in Fortran along
the lines of

<div class="example">

``` example-preformatted
      subroutine c_dgemm(transa, transb, m, n, k, alpha,
     +     a, lda, b, ldb, beta, c, ldc)
     +     bind(C, name = 'Cdgemm')
        use iso_c_binding, only : c_char, c_int, c_double
        character(c_char), intent(in) :: transa, transb
        integer(c_int), intent(in) :: m, n, k, lda, ldb, ldc
        real(c_double), intent(in) :: alpha, beta, a(lda, *), b(ldb, *)
        real(c_double), intent(out) ::  c(ldc, *)
        call dgemm(transa, transb, m, n, k, alpha,
     +             a, lda, b, ldb, beta, c, ldc)
      end subroutine c_dgemm
```

</div>

which is then called from C with declaration

<div class="example">

``` example-preformatted
void
Cdgemm(const char *transa, const char *transb, const int *m,
       const int *n, const int *k, const double *alpha,
       const double *a, const int *lda, const double *b, const int *ldb,
       const double *beta, double *c, const int *ldc);
```

</div>

Alternatively, do as R does and pass the character length(s) from C to
Fortran. A portable way to do this is

<div class="example">

``` example-preformatted
// before any R headers, or define in PKG_CPPFLAGS
#ifndef  USE_FC_LEN_T
# define USE_FC_LEN_T
#endif
#include <Rconfig.h>
#include <R_ext/BLAS.h>
#ifndef FCONE
# define FCONE
#endif
...
        F77_CALL(dgemm)("N", "T", &nrx, &ncy, &ncx, &one, x,
                        &nrx, y, &nry, &zero, z, &nrx FCONE FCONE);
```

</div>

(Note there is no comma before or between the `FCONE` invocations.)
Packages which call from C/C++ BLAS/LAPACK routines with character
arguments must adopt this approach: packages not using it will now fail
to install.

------------------------------------------------------------------------

</div>

<div id="Fortran-LOGICAL" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Passing-functions" rel="next">Passing functions</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Fortran-character-strings" rel="prev">Fortran character
strings</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Calling-C-from-Fortran-and-vice-versa" rel="up">Calling C from
Fortran and vice versa</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.6.2 Fortran LOGICAL <a href="#Fortran-LOGICAL-1" class="copiable-link">¶</a>

Passing Fortran LOGICAL variables to/from C/C++ is potentially
compiler-dependent. Fortran compilers have long used a 32-bit integer
type so it is pretty portable to use `int *` on the C/C++ side. However,
recent versions of `gfortran` *via* the option `-fc-prototypes-external`
say the C equivalent is `int_least32_t *`: ‘Link-Time Optimization’ will
report `int *` as a mismatch. It is possible to use `iso_c_binding` in
Fortran 2003 to map LOGICAL variables to the C99 type `_Bool`, but it is
usually simpler to pass integers.

------------------------------------------------------------------------

</div>

<div id="Passing-functions" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Fortran-LOGICAL" rel="prev">Fortran LOGICAL</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Calling-C-from-Fortran-and-vice-versa" rel="up">Calling C from
Fortran and vice versa</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.6.3 Passing functions <a href="#Passing-functions-1" class="copiable-link">¶</a>

A number of packages call C functions passed as arguments to Fortran
code along the lines of

<div class="example">

``` example-preformatted
c         subroutine fcn(m,n,x,fvec,iflag)
c         integer m,n,iflag
c         double precision x(n),fvec(m)
...
      subroutine lmdif(fcn, ...
```

</div>

where the C declaration and call are

<div class="example">

``` example-preformatted
void fcn_lmdif(int *m, int *n, double *par, double *fvec, int *iflag);

void F77_NAME(lmdif)(void (*fcn_lmdif)(int *m, int *n, double *par,
                                       double *fvec, int *iflag), ...

F77_CALL(lmdif)(&fcn_lmdif, ...
```

</div>

This works on most platforms but depends on the C and Fortran compilers
agreeing on calling conventions: this have been seen to fail. The most
portable solution seems to be to convert the Fortran code to C, perhaps
using `f2c`.

------------------------------------------------------------------------

</div>

</div>

<div id="Numerical-analysis-subroutines" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Optimization" rel="next">Optimization</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Calling-C-from-Fortran-and-vice-versa" rel="prev">Calling C
from Fortran and vice versa</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.7 Numerical analysis subroutines <a href="#Numerical-analysis-subroutines-1" class="copiable-link">¶</a>

<span id="index-Numerical-analysis-subroutines-from-C"
class="index-entry-id"></span>

R contains a large number of mathematical functions for its own use, for
example numerical linear algebra computations and special functions.

<span id="index-R_005fext_002fBLAS_002eh" class="index-entry-id"></span>
<span id="index-R_005fext_002fLapack_002eh"
class="index-entry-id"></span>
<span id="index-R_005fext_002fLinpack_002eh"
class="index-entry-id"></span>

The header files `R_ext/BLAS.h`, `R_ext/Lapack.h` and `R_ext/Linpack.h`
contain declarations of the BLAS, LAPACK and LINPACK linear algebra
functions included in R. These are expressed as calls to Fortran
subroutines, and they will also be usable from users’ Fortran code.
Although not part of the official API, this set of subroutines is
unlikely to change (but routines have been added in the past, most
recently in R 4.5.0).

The header file `Rmath.h` lists many other functions that are available
and documented in the following subsections. Many of these are C
interfaces to the code behind R functions, so the R function
documentation may give further details. <span id="index-Rmath_002eh"
class="index-entry-id"></span>

If `R_NO_REMAP_RMATH` most of these will need to be prefixed by `Rf_`:
see the header file for which ones.

- [Distribution functions](#Distribution-functions)
- [Mathematical functions](#Mathematical-functions)
- [Numerical Utilities](#Numerical-Utilities)
- [Mathematical constants](#Mathematical-constants)

------------------------------------------------------------------------

<div id="Distribution-functions" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Mathematical-functions" rel="next">Mathematical functions</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Numerical-analysis-subroutines" rel="up">Numerical analysis
subroutines</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.7.1 Distribution functions <a href="#Distribution-functions-1" class="copiable-link">¶</a>

<span id="index-Distribution-functions-from-C"
class="index-entry-id"></span>

The routines used to calculate densities, cumulative distribution
functions and quantile functions for the standard statistical
distributions are available as entry points.

The arguments for the entry points follow the pattern of those for the
normal distribution:

<div class="example">

<div class="group">

``` example-preformatted
double dnorm(double x, double mu, double sigma, int give_log);
double pnorm(double x, double mu, double sigma, int lower_tail,
             int give_log);
double qnorm(double p, double mu, double sigma, int lower_tail,
             int log_p);
double rnorm(double mu, double sigma);
```

</div>

</div>

That is, the first argument gives the position for the density and CDF
and probability for the quantile function, followed by the
distribution’s parameters. Argument `lower_tail` should be `TRUE` (or
`1`) for normal use, but can be `FALSE` (or `0`) if the probability of
the upper tail is desired or specified.

Finally, `give_log` should be non-zero if the result is required on log
scale, and `log_p` should be non-zero if `p` has been specified on log
scale.

Note that you directly get the cumulative (or “integrated”) *hazard*
function, H(t) = - log(1 - F(t)), by using

<div class="example">

``` example-preformatted
- pdist(t, ..., /*lower_tail = */ FALSE, /* give_log = */ TRUE)
```

</div>

or shorter (and more cryptic) `- p``dist``(t, ..., 0, 1)`.
<span id="index-cumulative-hazard" class="index-entry-id"></span>

The random-variate generation routine `rnorm` returns one normal
variate. See
<a href="#Random-numbers" class="xref">Random number generation</a>, for
the protocol in using the random-variate routines.
<span id="index-Random-numbers-in-C-1" class="index-entry-id"></span>

Note that these argument sequences are (apart from the names and that
`rnorm` has no `n`) mainly the same as the corresponding R functions of
the same name, so the documentation of the R functions can be used. Note
that the exponential and gamma distributions are parametrized by `scale`
rather than `rate`.

For reference, the following table gives the basic name (to be prefixed
by ‘`d`’, ‘`p`’, ‘`q`’ or ‘`r`’ apart from the exceptions noted) and
distribution-specific arguments for the complete set of distributions.

> |                         |              |                              |
> |-------------------------|--------------|------------------------------|
> | beta                    | `beta`       | `a`, `b`                     |
> | non-central beta        | `nbeta`      | `a`, `b`, `ncp`              |
> | binomial                | `binom`      | `n`, `p`                     |
> | Cauchy                  | `cauchy`     | `location`, `scale`          |
> | chi-squared             | `chisq`      | `df`                         |
> | non-central chi-squared | `nchisq`     | `df`, `ncp`                  |
> | exponential             | `exp`        | `scale` (and **not** `rate`) |
> | F                       | `f`          | `n1`, `n2`                   |
> | non-central F           | `nf`         | `n1`, `n2`, `ncp`            |
> | gamma                   | `gamma`      | `shape`, `scale`             |
> | geometric               | `geom`       | `p`                          |
> | hypergeometric          | `hyper`      | `NR`, `NB`, `n`              |
> | logistic                | `logis`      | `location`, `scale`          |
> | lognormal               | `lnorm`      | `logmean`, `logsd`           |
> | negative binomial       | `nbinom`     | `size`, `prob`               |
> | normal                  | `norm`       | `mu`, `sigma`                |
> | Poisson                 | `pois`       | `lambda`                     |
> | Student’s t             | `t`          | `n`                          |
> | non-central t           | `nt`         | `df`, `delta`                |
> | Studentized range       | `tukey` (\*) | `rr`, `cc`, `df`             |
> | uniform                 | `unif`       | `a`, `b`                     |
> | Weibull                 | `weibull`    | `shape`, `scale`             |
> | Wilcoxon rank sum       | `wilcox`     | `m`, `n`                     |
> | Wilcoxon signed rank    | `signrank`   | `n`                          |

Entries marked with an asterisk only have ‘`p`’ and ‘`q`’ functions
available, and none of the non-central distributions have ‘`r`’
functions.

(If remapping is suppressed, the Normal distribution names are
`Rf_dnorm4`, `Rf_pnorm5` and `Rf_qnorm5`.)

Additionally, a *multivariate* RNG for the multinomial distribution is

<div class="example">

``` example-preformatted
void Rf_rmultinom(int n, double* prob, int K, int* rN)
```

</div>

where `K = length(prob)`, sum(prob\[.\]) == 1 and `rN` must point to a
length-`K` integer vector n1 n2 .. nK where each entry nj=`rN[j]` is
“filled” by a random binomial from Bin(n; prob\[j\]), constrained to
sum(rN\[.\]) == n. <span id="index-rmultinom"
class="index-entry-id"></span> <span id="index-rmultinom-1"
class="index-entry-id"></span>

After calls to `dwilcox`, `pwilcox` or `qwilcox` the function
`wilcox_free()` should be called, and similarly `signrank_free()` for
the signed rank functions. <span id="index-wilcox_005ffree"
class="index-entry-id"></span> <span id="index-wilcox_005ffree-1"
class="index-entry-id"></span> <span id="index-signrank_005ffree"
class="index-entry-id"></span> <span id="index-signrank_005ffree-1"
class="index-entry-id"></span> Since `wilcox_free()` and
`signrank_free()` were only added to `Rmath.h` in R  4.2.0, their use
requires something like

<div class="example">

``` example-preformatted
#include "Rmath.h"
#include "Rversion.h"

#if R_VERSION < R_Version(4, 2, 0)
extern void wilcox_free(void);
extern void signrank_free(void);
#endif
```

</div>

For the negative binomial distribution (‘`nbinom`’), in addition to the
`(size, prob)` parametrization, the alternative `(size, mu)`
parametrization is provided as well by functions ‘`[dpqr]nbinom_mu()`’,
see <span class="kbd kbd">?NegBinomial</span> in R.

Functions `dpois_raw(x, *)` and `dbinom_raw(x, *)` are versions of the
Poisson and binomial probability mass functions which work continuously
in `x`, whereas `dbinom(x,*)` and `dpois(x,*)` only return non zero
values for integer `x`.

<div class="example">

<div class="group">

``` example-preformatted
double dbinom_raw(double x, double n, double p, double q, int give_log)
double dpois_raw (double x, double lambda, int give_log)
```

</div>

</div>

Note that `dbinom_raw()` returns both p and q = 1-p which may be
advantageous when one of them is close to 1.

------------------------------------------------------------------------

</div>

<div id="Mathematical-functions" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Numerical-Utilities" rel="next">Numerical Utilities</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Distribution-functions" rel="prev">Distribution functions</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Numerical-analysis-subroutines" rel="up">Numerical analysis
subroutines</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.7.2 Mathematical functions <a href="#Mathematical-functions-1" class="copiable-link">¶</a>

<span id="index-Gamma-function" class="index-entry-id"></span>
<span id="index-Polygamma-functions" class="index-entry-id"></span>
<span id="index-gammafn" class="index-entry-id"></span>
<span id="index-gammafn-1" class="index-entry-id"></span>
<span id="index-lgammafn" class="index-entry-id"></span>
<span id="index-lgammafn-1" class="index-entry-id"></span>
<span id="index-digamma" class="index-entry-id"></span>
<span id="index-digamma-1" class="index-entry-id"></span>
<span id="index-trigamma" class="index-entry-id"></span>
<span id="index-trigamma-1" class="index-entry-id"></span>
<span id="index-tetragamma" class="index-entry-id"></span>
<span id="index-tetragamma-1" class="index-entry-id"></span>
<span id="index-pentagamma" class="index-entry-id"></span>
<span id="index-pentagamma-1" class="index-entry-id"></span>
<span id="index-psigamma" class="index-entry-id"></span>
<span id="index-psigamma-1" class="index-entry-id"></span>
<span id="index-dpsifn" class="index-entry-id"></span>
<span id="index-dpsifn-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **gammafn** `(double ``x``)` <a href="#index-gammafn-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **lgammafn** `(double ``x``)` <a href="#index-lgammafn-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **digamma** `(double ``x``)` <a href="#index-digamma-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **trigamma** `(double ``x``)` <a href="#index-trigamma-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **tetragamma** `(double ``x``)` <a href="#index-tetragamma-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **pentagamma** `(double ``x``)` <a href="#index-pentagamma-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **psigamma** `(double ``x``, double ``deriv``)` <a href="#index-psigamma-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`void` **dpsifn** `(double ``x``, int ``n``, int ``kode``, int ``m``, double* ``ans``, int* ``nz``, int* ``ierr``)` <a href="#index-dpsifn-2" class="copiable-link">¶</a>  
The Gamma function, the natural logarithm of its absolute value and
first four derivatives and the n-th derivative of Psi, the digamma
function, which is the derivative of `lgammafn`. In other words,
`digamma(x)` is the same as `psigamma(x,0)`,
`trigamma(x) == psigamma(x,1)`, etc. The underlying workhorse,
`dpsifn()`, is useful, e.g., when several derivatives of log
Gamma=`lgammafn` are desired. It computes and returns in `ans[]` the
length-`m` sequence (-1)^(k+1) / gamma(k+1) \* psi(k;x) for k = n ...
n+m-1, where psi(k;x) is the k-th derivative of Psi(x), i.e.,
`psigamma(x,k)`. For more details, see the comments in
`src/nmath/polygamma.c`.

<span id="index-Beta-function" class="index-entry-id"></span>
<span id="index-beta" class="index-entry-id"></span>
<span id="index-beta-1" class="index-entry-id"></span>
<span id="index-lbeta" class="index-entry-id"></span>
<span id="index-lbeta-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **beta** `(double ``a``, double ``b``)` <a href="#index-beta-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **lbeta** `(double ``a``, double ``b``)` <a href="#index-lbeta-2" class="copiable-link">¶</a>  
The (complete) Beta function and its natural logarithm.

<span id="index-choose" class="index-entry-id"></span>
<span id="index-choose-1" class="index-entry-id"></span>
<span id="index-lchoose" class="index-entry-id"></span>
<span id="index-lchoose-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **choose** `(double ``n``, double ``k``)` <a href="#index-choose-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **lchoose** `(double ``n``, double ``k``)` <a href="#index-lchoose-2" class="copiable-link">¶</a>  
The number of combinations of `k` items chosen from `n` and the natural
logarithm of its absolute value, generalized to arbitrary real `n`. `k`
is rounded to the nearest integer (with a warning if needed).

<span id="index-Bessel-functions" class="index-entry-id"></span>
<span id="index-bessel_005fi" class="index-entry-id"></span>
<span id="index-bessel_005fi-1" class="index-entry-id"></span>
<span id="index-bessel_005fj" class="index-entry-id"></span>
<span id="index-bessel_005fj-1" class="index-entry-id"></span>
<span id="index-bessel_005fk" class="index-entry-id"></span>
<span id="index-bessel_005fk-1" class="index-entry-id"></span>
<span id="index-bessel_005fy" class="index-entry-id"></span>
<span id="index-bessel_005fy-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **bessel_i** `(double ``x``, double ``nu``, double ``expo``)` <a href="#index-bessel_005fi-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **bessel_j** `(double ``x``, double ``nu``)` <a href="#index-bessel_005fj-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **bessel_k** `(double ``x``, double ``nu``, double ``expo``)` <a href="#index-bessel_005fk-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **bessel_y** `(double ``x``, double ``nu``)` <a href="#index-bessel_005fy-2" class="copiable-link">¶</a>  
Bessel functions of types I, J, K and Y with index `nu`. For `bessel_i`
and `bessel_k` there is the option to return exp(-`x`) I(`x`; `nu`) or
exp(`x`) K(`x`; `nu`) if `expo` is 2. (Use `expo`` == 1` for unscaled
values.)

------------------------------------------------------------------------

</div>

<div id="Numerical-Utilities" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Mathematical-constants" rel="next">Mathematical constants</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Mathematical-functions" rel="prev">Mathematical functions</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Numerical-analysis-subroutines" rel="up">Numerical analysis
subroutines</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.7.3 Numerical Utilities <a href="#Numerical-Utilities-1" class="copiable-link">¶</a>

There are a few other numerical utility functions available as entry
points.

<span id="index-R_005fpow" class="index-entry-id"></span>
<span id="index-R_005fpow-1" class="index-entry-id"></span>
<span id="index-R_005fpow_005fdi" class="index-entry-id"></span>
<span id="index-R_005fpow_005fdi-1" class="index-entry-id"></span>
<span id="index-pow1p" class="index-entry-id"></span>
<span id="index-pow1p-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **R_pow** `(double ``x``, double ``y``)` <a href="#index-R_005fpow-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **R_pow_di** `(double ``x``, int ``i``)` <a href="#index-R_005fpow_005fdi-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **pow1p** `(double ``x``, double ``y``)` <a href="#index-pow1p-2" class="copiable-link">¶</a>  
`R_pow(``x``, ``y``)` and `R_pow_di(``x``, ``i``)` compute `x``^``y` and
`x``^``i`, respectively using `R_FINITE` checks and returning the proper
result (the same as R) for the cases where `x`, `y` or `i` are 0 or
missing or infinite or `NaN`.

`pow1p(``x``, ``y``)` computes `(1 + ``x``)^``y`, accurately even for
small `x`, i.e., \|x\| \<\< 1.

<span id="index-log1p" class="index-entry-id"></span>
<span id="index-log1p-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **log1p** `(double ``x``)` <a href="#index-log1p-2" class="copiable-link">¶</a>  
Computes `log(1 + ``x``)` (*log 1 **p**lus x*), accurately even for
small `x`, i.e., \|x\| \<\< 1.

This should be provided by your platform, in which case it is not
included in `Rmath.h`, but is (probably) in `math.h` which `Rmath.h`
includes (except under C++, so it may not be declared for C++98).

<span id="index-log1pmx" class="index-entry-id"></span>
<span id="index-log1pmx-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **log1pmx** `(double ``x``)` <a href="#index-log1pmx-2" class="copiable-link">¶</a>  
Computes `log(1 + ``x``) - ``x` (*log 1 **p**lus x **m**inus **x***),
accurately even for small `x`, i.e., \|x\| \<\< 1.

<span id="index-log1pexp" class="index-entry-id"></span>
<span id="index-log1pexp-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **log1pexp** `(double ``x``)` <a href="#index-log1pexp-2" class="copiable-link">¶</a>  
Computes `log(1 + exp(``x``))` (*log 1 **p**lus **exp***), accurately,
notably for large `x`, e.g., x \> 720.

<span id="index-log1mexp" class="index-entry-id"></span>
<span id="index-log1mexp-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **log1mexp** `(double ``x``)` <a href="#index-log1mexp-2" class="copiable-link">¶</a>  
Computes `log(1 - exp(``-x``))` (*log 1 **m**inus **exp***), accurately,
carefully for two regions of `x`, optimally cutting off at log 2 (=
0.693147..), using
`((-x) > -M_LN2 ? log(-expm1(-x)) : log1p(-exp(-x)))`.

<span id="index-expm1" class="index-entry-id"></span>
<span id="index-expm1-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **expm1** `(double ``x``)` <a href="#index-expm1-2" class="copiable-link">¶</a>  
Computes `exp(``x``) - 1` (*exp x **m**inus 1*), accurately even for
small `x`, i.e., \|x\| \<\< 1.

This should be provided by your platform, in which case it is not
included in `Rmath.h`, but is (probably) in `math.h` which `Rmath.h`
includes (except under C++, so it may not be declared for C++98).

<span id="index-lgamma1p" class="index-entry-id"></span>
<span id="index-lgamma1p-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **lgamma1p** `(double ``x``)` <a href="#index-lgamma1p-2" class="copiable-link">¶</a>  
Computes `log(gamma(``x`` + 1))` (*log(gamma(1 **p**lus x))*),
accurately even for small `x`, i.e., 0 \< x \< 0.5.

<span id="index-cospi" class="index-entry-id"></span>
<span id="index-cospi-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **cospi** `(double ``x``)` <a href="#index-cospi-2" class="copiable-link">¶</a>  
Computes `cos(pi * x)` (where `pi` is 3.14159...), accurately, notably
for half integer `x`.

This might be provided by your
platform<a href="#FOOT168" id="DOCF168" class="footnote"><sup>168</sup></a>,
in which case it is not included in `Rmath.h`, but is in `math.h` which
`Rmath.h` includes. (Ensure that neither `math.h` nor `cmath` is
included before `Rmath.h` or define

<div class="example">

``` example-preformatted
#define __STDC_WANT_IEC_60559_FUNCS_EXT__ 1
```

</div>

before the first inclusion.)

<span id="index-sinpi" class="index-entry-id"></span>
<span id="index-sinpi-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **sinpi** `(double ``x``)` <a href="#index-sinpi-2" class="copiable-link">¶</a>  
Computes `sin(pi * x)` accurately, notably for (half) integer `x`.

This might be provided by your platform, in which case it is not
included in `Rmath.h`, but is in `math.h` which `Rmath.h` includes (but
see the comments for `cospi`).

<span id="index-Rtanpi" class="index-entry-id"></span>
<span id="index-Rtanpi-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **Rtanpi** `(double ``x``)` <a href="#index-Rtanpi-2" class="copiable-link">¶</a>  
Computes `tan(pi * x)` accurately, notably for integer `x`, giving `NaN`
for half integer `x` and exactly +1 or -1 for (non half) quarter
integers.

<span id="index-tanpi" class="index-entry-id"></span>
<span id="index-tanpi-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **tanpi** `(double ``x``)` <a href="#index-tanpi-2" class="copiable-link">¶</a>  
Computes `tan(pi * x)` accurately for integer `x` with possibly platform
dependent behavior for half (and quarter) integers. This might be
provided by your platform, in which case it is not included in
`Rmath.h`, but is in `math.h` which `Rmath.h` includes (but see the
comments for `cospi`).

<span id="index-logspace_005fadd" class="index-entry-id"></span>
<span id="index-logspace_005fadd-1" class="index-entry-id"></span>
<span id="index-logspace_005fsub" class="index-entry-id"></span>
<span id="index-logspace_005fsub-1" class="index-entry-id"></span>
<span id="index-logspace_005fsum" class="index-entry-id"></span>
<span id="index-logspace_005fsum-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **logspace_add** `(double ``logx``, double ``logy``)` <a href="#index-logspace_005fadd-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **logspace_sub** `(double ``logx``, double ``logy``)` <a href="#index-logspace_005fsub-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **logspace_sum** `(const double* ``logx``, int ``n``)` <a href="#index-logspace_005fsum-2" class="copiable-link">¶</a>  
Compute the log of a sum or difference from logs of terms, i.e., “x + y”
as `log (exp(``logx``) + exp(``logy``))` and “x - y” as
`log (exp(``logx``) - exp(``logy``))`, and “sum_i x\[i\]” as
`log (sum[i = 1:``n`` exp(``logx``[i])] )` without causing unnecessary
overflows or throwing away too much accuracy.

<span id="index-imax2" class="index-entry-id"></span>
<span id="index-imax2-1" class="index-entry-id"></span>
<span id="index-imin2" class="index-entry-id"></span>
<span id="index-imin2-1" class="index-entry-id"></span>
<span id="index-fmax2" class="index-entry-id"></span>
<span id="index-fmax2-1" class="index-entry-id"></span>
<span id="index-fmin2" class="index-entry-id"></span>
<span id="index-fmin2-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`int` **imax2** `(int ``x``, int ``y``)` <a href="#index-imax2-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`int` **imin2** `(int ``x``, int ``y``)` <a href="#index-imin2-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **fmax2** `(double ``x``, double ``y``)` <a href="#index-fmax2-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **fmin2** `(double ``x``, double ``y``)` <a href="#index-fmin2-2" class="copiable-link">¶</a>  
Return the larger (`max`) or smaller (`min`) of two integer or double
numbers, respectively. Note that `fmax2` and `fmin2` differ from
C99/C++11’s `fmax` and `fmin` when one of the arguments is a `NaN`:
these versions return `NaN`.

<!-- -->

<span class="category-def">Function: </span>`double` **sign** `(double ``x``)` <a href="#index-sign-1" class="copiable-link">¶</a>  
<span id="index-sign" class="index-entry-id"></span>
<span id="index-sign-2" class="index-entry-id"></span>

Compute the *signum* function, where sign(`x`) is 1, 0, or *-1*, when
`x` is positive, 0, or negative, respectively, and `NaN` if `x` is a
`NaN`.

<span id="index-fsign" class="index-entry-id"></span>
<span id="index-fsign-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **fsign** `(double ``x``, double ``y``)` <a href="#index-fsign-2" class="copiable-link">¶</a>  
Performs “transfer of sign” and is defined as \|x\| \* sign(y).

<span id="index-fprec" class="index-entry-id"></span>
<span id="index-fprec-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **fprec** `(double ``x``, double ``digits``)` <a href="#index-fprec-2" class="copiable-link">¶</a>  
Returns the value of `x` rounded to `digits` *significant* decimal
digits.

This is the function used by R’s `signif()`.

<span id="index-fround" class="index-entry-id"></span>
<span id="index-fround-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **fround** `(double ``x``, double ``digits``)` <a href="#index-fround-2" class="copiable-link">¶</a>  
Returns the value of `x` rounded to `digits` decimal digits (after the
decimal point).

This is the function used by R’s `round()`. (Note that C99/C++11 provide
a `round` function but C++98 need not.)

<span id="index-ftrunc" class="index-entry-id"></span>
<span id="index-ftrunc-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **ftrunc** `(double ``x``)` <a href="#index-ftrunc-2" class="copiable-link">¶</a>  
Returns the value of `x` truncated (to an integer value) towards zero.

------------------------------------------------------------------------

</div>

<div id="Mathematical-constants" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Numerical-Utilities" rel="prev">Numerical Utilities</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Numerical-analysis-subroutines" rel="up">Numerical analysis
subroutines</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.7.4 Mathematical constants <a href="#Mathematical-constants-1" class="copiable-link">¶</a>

<span id="index-M_005fE" class="index-entry-id"></span>
<span id="index-M_005fE-1" class="index-entry-id"></span>
<span id="index-M_005fPI" class="index-entry-id"></span>
<span id="index-M_005fPI-1" class="index-entry-id"></span>

R has a set of commonly used mathematical constants encompassing
constants defined by POSIX and usually found in headers `math.h` and
`cmath`, as well as further ones that are used in statistical
computations. These are defined to (at least) 30 digits accuracy in
`Rmath.h`. The following definitions use `ln(x)` for the natural
logarithm (`log(x)` in R).

> | Name             | Definition (`ln = log`) | round(*value*, 7) |
> |------------------|-------------------------|-------------------|
> | `M_E`            | *e*                     | 2.7182818         |
> | `M_LOG2E`        | log2(*e*)               | 1.4426950         |
> | `M_LOG10E`       | log10(*e*)              | 0.4342945         |
> | `M_LN2`          | ln(2)                   | 0.6931472         |
> | `M_LN10`         | ln(10)                  | 2.3025851         |
> | `M_PI`           | pi                      | 3.1415927         |
> | `M_PI_2`         | pi/2                    | 1.5707963         |
> | `M_PI_4`         | pi/4                    | 0.7853982         |
> | `M_1_PI`         | 1/pi                    | 0.3183099         |
> | `M_2_PI`         | 2/pi                    | 0.6366198         |
> | `M_2_SQRTPI`     | 2/sqrt(pi)              | 1.1283792         |
> | `M_SQRT2`        | sqrt(2)                 | 1.4142136         |
> | `M_SQRT1_2`      | 1/sqrt(2)               | 0.7071068         |
> | `M_SQRT_3`       | sqrt(3)                 | 1.7320508         |
> | `M_SQRT_32`      | sqrt(32)                | 5.6568542         |
> | `M_LOG10_2`      | log10(2)                | 0.3010300         |
> | `M_2PI`          | 2\*pi                   | 6.2831853         |
> | `M_SQRT_PI`      | sqrt(pi)                | 1.7724539         |
> | `M_1_SQRT_2PI`   | 1/sqrt(2\*pi)           | 0.3989423         |
> | `M_SQRT_2dPI`    | sqrt(2/pi)              | 0.7978846         |
> | `M_LN_SQRT_PI`   | ln(sqrt(pi))            | 0.5723649         |
> | `M_LN_SQRT_2PI`  | ln(sqrt(2\*pi))         | 0.9189385         |
> | `M_LN_SQRT_PId2` | ln(sqrt(pi/2))          | 0.2257914         |

<span id="index-R_005fext_002fConstants_002eh"
class="index-entry-id"></span>

For compatibility with S this file used to define the constant `PI` this
is defunct and should be replaced by `M_PI`. Header `Constants.h`
includes either C header `float.h` or C++ header `cfloat`, which provide
constants such as `DBL_MAX`.

<span id="index-TRUE" class="index-entry-id"></span>
<span id="index-TRUE-1" class="index-entry-id"></span>
<span id="index-FALSE" class="index-entry-id"></span>
<span id="index-FALSE-1" class="index-entry-id"></span>
<span id="index-R_005fext_002fBoolean_002eh"
class="index-entry-id"></span>

The included header `R_ext/Boolean.h` has enumeration constants `TRUE`
and `FALSE` of type `Rboolean` in order to provide a way of using
“logical” variables in C consistently. This can conflict with other
software: for example it conflicts with the headers in IJG’s `jpeg-9`
(but not earlier versions). `Rboolean` cannot represent
`NA`<a href="#FOOT169" id="DOCF169" class="footnote"><sup>169</sup></a>
and hence cannot be used for elements of R logical vectors.

Type `Rboolean` is being phased out: as from R 4.5.0 the header also
makes available the type `bool` and values `true` and `false`. These are
reserved words in C23 and C++11 and available *via* header `stdbool.h`
as from C99. (Type `bool` is not a drop-in replacement for `Rboolean` as
it is usually stored in a byte and `Rboolean` in an `int`, hence 4
bytes.)

Some package maintainers may want to exclude the provision of `TRUE`,
`FALSE`, `true`, `false` and `bool` to avoid clashes with other headers
such as the IJG ones mentioned above. This cannot be done entirely (the
last three are keywords in C23 and C++11) but as from R 4.5.0 defining
`R_INCLUDE_BOOLEAN_H` to `0` before including any header which includes
this one (such as `R.h` and `Rinternals.h`) skips its body.

------------------------------------------------------------------------

</div>

</div>

<div id="Optimization" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Integration" rel="next">Integration</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Numerical-analysis-subroutines" rel="prev">Numerical analysis
subroutines</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.8 Optimization <a href="#Optimization-1" class="copiable-link">¶</a>

<span id="index-optimization" class="index-entry-id"></span>

The C code underlying `optim` can be accessed directly. The user needs
to supply a function to compute the function to be minimized, of the
type

<div class="example">

``` example-preformatted
typedef double optimfn(int n, double *par, void *ex);
```

</div>

where the first argument is the number of parameters in the second
argument. The third argument is a pointer passed down from the calling
routine, normally used to carry auxiliary information.

Some of the methods also require a gradient function

<div class="example">

``` example-preformatted
typedef void optimgr(int n, double *par, double *gr, void *ex);
```

</div>

which passes back the gradient in the `gr` argument. No function is
provided for finite-differencing, nor for approximating the Hessian at
the result.

The interfaces (defined in header `R_ext/Applic.h`) are

- Nelder Mead: <span id="index-nmmin" class="index-entry-id"></span>
  <span id="index-nmmin-1" class="index-entry-id"></span>
  <div class="example">

  ``` example-preformatted
  void nmmin(int n, double *xin, double *x, double *Fmin, optimfn fn,
             int *fail, double abstol, double intol, void *ex,
             double alpha, double beta, double gamma, int trace,
             int *fncount, int maxit);
  ```

  </div>
- BFGS: <span id="index-vmmin" class="index-entry-id"></span>
  <span id="index-vmmin-1" class="index-entry-id"></span>
  <div class="example">

  ``` example-preformatted
  void vmmin(int n, double *x, double *Fmin,
             optimfn fn, optimgr gr, int maxit, int trace,
             int *mask, double abstol, double reltol, int nREPORT,
             void *ex, int *fncount, int *grcount, int *fail);
  ```

  </div>
- Conjugate gradients: <span id="index-cgmin"
  class="index-entry-id"></span> <span id="index-cgmin-1"
  class="index-entry-id"></span>
  <div class="example">

  ``` example-preformatted
  void cgmin(int n, double *xin, double *x, double *Fmin,
             optimfn fn, optimgr gr, int *fail, double abstol,
             double intol, void *ex, int type, int trace,
             int *fncount, int *grcount, int maxit);
  ```

  </div>
- Limited-memory BFGS with bounds: <span id="index-lbfgsb"
  class="index-entry-id"></span> <span id="index-lbfgsb-1"
  class="index-entry-id"></span>
  <div class="example">

  ``` example-preformatted
  void lbfgsb(int n, int lmm, double *x, double *lower,
              double *upper, int *nbd, double *Fmin, optimfn fn,
              optimgr gr, int *fail, void *ex, double factr,
              double pgtol, int *fncount, int *grcount,
              int maxit, char *msg, int trace, int nREPORT);
  ```

  </div>
- Simulated annealing: <span id="index-samin"
  class="index-entry-id"></span> <span id="index-samin-1"
  class="index-entry-id"></span>
  <div class="example">

  ``` example-preformatted
  void samin(int n, double *x, double *Fmin, optimfn fn, int maxit,
             int tmax, double temp, int trace, void *ex);
  ```

  </div>

Many of the arguments are common to the various methods. `n` is the
number of parameters, `x` or `xin` is the starting parameters on entry
and `x` the final parameters on exit, with final value returned in
`Fmin`. Most of the other parameters can be found from the help page for
`optim`: see the source code `src/appl/lbfgsb.c` for the values of
`nbd`, which specifies which bounds are to be used.

The function `optif9` is included in the experimental API for use by the
**nlme** package. It is subject to change and not intended for use by
other packages. <span id="index-optif9" class="index-entry-id"></span>
<span id="index-optif9-1" class="index-entry-id"></span>

------------------------------------------------------------------------

</div>

<div id="Integration" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Utility-functions" rel="next">Utility functions</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Optimization" rel="prev">Optimization</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.9 Integration <a href="#Integration-1" class="copiable-link">¶</a>

<span id="index-integration" class="index-entry-id"></span>

The C code underlying `integrate` can be accessed directly. The user
needs to supply a *vectorizing* C function to compute the function to be
integrated, of the type

<div class="example">

``` example-preformatted
typedef void integr_fn(double *x, int n, void *ex);
```

</div>

where `x[]` is both input and output and has length `n`, i.e., a C
function, say `fn`, of type `integr_fn` must basically do
`for(i in 1:n) x[i] := f(x[i], ex)`. The vectorization requirement can
be used to speed up the integrand instead of calling it `n` times. Note
that in the current implementation built on QUADPACK, `n` will be either
15 or 21. The `ex` argument is a pointer passed down from the calling
routine, normally used to carry auxiliary information.

There are interfaces (defined in header `R_ext/Applic.h`) for integrals
over finite and infinite intervals (or “ranges” or “integration
boundaries”).

- Finite: <span id="index-Rdqags" class="index-entry-id"></span>
  <span id="index-Rdqags-1" class="index-entry-id"></span>
  <div class="example">

  ``` example-preformatted
  void Rdqags(integr_fn f, void *ex, double *a, double *b,
              double *epsabs, double *epsrel,
              double *result, double *abserr, int *neval, int *ier,
              int *limit, int *lenw, int *last,
              int *iwork, double *work);
  ```

  </div>
- Infinite: <span id="index-Rdqagi" class="index-entry-id"></span>
  <span id="index-Rdqagi-1" class="index-entry-id"></span>
  <div class="example">

  ``` example-preformatted
  void Rdqagi(integr_fn f, void *ex, double *bound, int *inf,
              double *epsabs, double *epsrel,
              double *result, double *abserr, int *neval, int *ier,
              int *limit, int *lenw, int *last,
              int *iwork, double *work);
  ```

  </div>

Only the 3rd and 4th argument differ for the two integrators; for the
finite range integral using `Rdqags`, `a` and `b` are the integration
interval bounds, whereas for an infinite range integral using `Rdqagi`,
`bound` is the finite bound of the integration (if the integral is not
doubly-infinite) and `inf` is a code indicating the kind of integration
range,

`inf = 1`  
corresponds to (bound, +Inf),

`inf = -1`  
corresponds to (-Inf, bound),

`inf = 2`  
corresponds to (-Inf, +Inf),

`f` and `ex` define the integrand function, see above; `epsabs` and
`epsrel` specify the absolute and relative accuracy requested, `result`,
`abserr` and `last` are the output components `value`, `abs.err` and
`subdivisions` of the R function integrate, where `neval` gives the
number of integrand function evaluations, and the error code `ier` is
translated to R’s `integrate() $ message`, look at that function
definition. `limit` corresponds to `integrate(..., subdivisions = *)`.
It seems you should always define the two work arrays and the length of
the second one as

<div class="example">

``` example-preformatted
    lenw = 4 * limit;
    iwork =   (int *) R_alloc(limit, sizeof(int));
    work = (double *) R_alloc(lenw,  sizeof(double));
```

</div>

The comments in the source code in `src/appl/integrate.c` give more
details, particularly about reasons for failure (`ier >= 1`).

------------------------------------------------------------------------

</div>

<div id="Utility-functions" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Linear-algebra" rel="next">Linear algebra</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Integration" rel="prev">Integration</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.10 Utility functions <a href="#Utility-functions-1" class="copiable-link">¶</a>

<span id="index-Sort-functions-from-C" class="index-entry-id"></span>

R has a fairly comprehensive set of sort routines which are made
available to users’ C code. The following is declared in header file
`Rinternals.h`.

<span id="index-R_005forderVector" class="index-entry-id"></span>
<span id="index-R_005forderVector-1" class="index-entry-id"></span>
<span id="index-R_005forderVector1" class="index-entry-id"></span>
<span id="index-R_005forderVector1-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`void` **R_orderVector** `(int* ``indx``, int ``n``, SEXP ``arglist``, Rboolean ``nalast``, Rboolean ``decreasing``)` <a href="#index-R_005forderVector-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`void` **R_orderVector1** `(int* ``indx``, int ``n``, SEXP ``x``, Rboolean ``nalast``, Rboolean ``decreasing``)` <a href="#index-R_005forderVector1-2" class="copiable-link">¶</a>  
`R_orderVector()` corresponds to R’s `order(..., na.last, decreasing)`.
More specifically, `indx <- order(x, y, na.last, decreasing)`
corresponds to
`R_orderVector(indx, n, Rf_lang2(x, y), nalast, decreasing)` and for
three vectors, `Rf_lang3(x,y,z)` is used as `arglist`.

Both `R_orderVector` and `R_orderVector1` assume the vector `indx` to be
allocated to length \>= n. On return, `indx[]` contains a permutation of
`0:(n-1)`, i.e., 0-based C indices (and not 1-based R indices, as R’s
`order()`).

When ordering only one vector, `R_orderVector1` is faster and
corresponds (but is 0-based) to R’s
`indx <- order(x, na.last, decreasing)`. It was added in R 3.3.0.

All other sort routines are declared in header file `R_ext/Utils.h`
(included by `R.h`) and include the following.

<span id="index-R_005fisort" class="index-entry-id"></span>
<span id="index-R_005fisort-1" class="index-entry-id"></span>
<span id="index-R_005frsort" class="index-entry-id"></span>
<span id="index-R_005frsort-1" class="index-entry-id"></span>
<span id="index-R_005fcsort" class="index-entry-id"></span>
<span id="index-R_005fcsort-1" class="index-entry-id"></span>
<span id="index-rsort_005fwith_005findex" class="index-entry-id"></span>
<span id="index-rsort_005fwith_005findex-1"
class="index-entry-id"></span>

<span class="category-def">Function: </span>`void` **R_isort** `(int* ``x``, int ``n``)` <a href="#index-R_005fisort-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`void` **R_rsort** `(double* ``x``, int ``n``)` <a href="#index-R_005frsort-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`void` **R_csort** `(Rcomplex* ``x``, int ``n``)` <a href="#index-R_005fcsort-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`void` **rsort_with_index** `(double* ``x``, int* ``index``, int ``n``)` <a href="#index-rsort_005fwith_005findex-2" class="copiable-link">¶</a>  
The first three sort integer, real (double) and complex data
respectively. (Complex numbers are sorted by the real part first then
the imaginary part.) `NA`s are sorted last.

`rsort_with_index` sorts on `x`, and applies the same permutation to
`index`. `NA`s are sorted last.

<span id="index-Rf_005frevsort" class="index-entry-id"></span>
<span id="index-Rf_005frevsort-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`void` **Rf_revsort** `(double* ``x``, int* ``index``, int ``n``)` <a href="#index-Rf_005frevsort-2" class="copiable-link">¶</a>  
Is similar to `rsort_with_index` but sorts into decreasing order, and
`NA`s are not handled.

<span id="index-Rf_005fiPsort" class="index-entry-id"></span>
<span id="index-Rf_005fiPsort-1" class="index-entry-id"></span>
<span id="index-Rf_005frPsort" class="index-entry-id"></span>
<span id="index-Rf_005frPsort-1" class="index-entry-id"></span>
<span id="index-Rf_005fcPsort" class="index-entry-id"></span>
<span id="index-Rf_005fcPsort-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`void` **Rf_iPsort** `(int* ``x``, int ``n``, int ``k``)` <a href="#index-Rf_005fiPsort-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`void` **Rf_rPsort** `(double* ``x``, int ``n``, int ``k``)` <a href="#index-Rf_005frPsort-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`void` **Rf_cPsort** `(Rcomplex* ``x``, int ``n``, int ``k``)` <a href="#index-Rf_005fcPsort-2" class="copiable-link">¶</a>  
These all provide (very) partial sorting: they permute `x` so that
`x``[``k``]` is in the correct place with smaller values to the left,
larger ones to the right.

<span id="index-R_005fqsort" class="index-entry-id"></span>
<span id="index-R_005fqsort-1" class="index-entry-id"></span>
<span id="index-R_005fqsort_005fI" class="index-entry-id"></span>
<span id="index-R_005fqsort_005fI-1" class="index-entry-id"></span>
<span id="index-R_005fqsort_005fint" class="index-entry-id"></span>
<span id="index-R_005fqsort_005fint-1" class="index-entry-id"></span>
<span id="index-R_005fqsort_005fint_005fI"
class="index-entry-id"></span>
<span id="index-R_005fqsort_005fint_005fI-1"
class="index-entry-id"></span>

<span class="category-def">Function: </span>`void` **R_qsort** `(double *``v``, size_t ``i``, size_t ``j``)` <a href="#index-R_005fqsort-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`void` **R_qsort_I** `(double *``v``, int *``I``, int ``i``, int ``j``)` <a href="#index-R_005fqsort_005fI-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`void` **R_qsort_int** `(int *``iv``, size_t ``i``, size_t ``j``)` <a href="#index-R_005fqsort_005fint-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`void` **R_qsort_int_I** `(int *``iv``, int *``I``, int ``i``, int ``j``)` <a href="#index-R_005fqsort_005fint_005fI-2" class="copiable-link">¶</a>  
These routines sort `v``[``i``:``j``]` or `iv``[``i``:``j``]` (using
1-indexing, i.e., `v``[1]` is the first element) calling the quicksort
algorithm as used by R’s `sort(v, method = "quick")` and documented on
the help page for the R function `sort`. The `..._I()` versions also
return the `sort.index()` vector in `I`. Note that the ordering is *not*
stable, so tied values may be permuted.

Note that `NA`s are not handled (explicitly) and you should use
different sorting functions if `NA`s can be present.

<span id="index-qsort4-2" class="index-entry-id"></span>
<span id="index-qsort4" class="index-entry-id"></span>
<span id="index-qsort3-2" class="index-entry-id"></span>
<span id="index-qsort3" class="index-entry-id"></span>

<span class="category-def">Function: </span>`subroutine` **qsort4** `(double precision ``v``, integer ``indx``, integer ``ii``, integer ``jj``)` <a href="#index-qsort4-1" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`subroutine` **qsort3** `(double precision ``v``, integer ``ii``, integer ``jj``)` <a href="#index-qsort3-1" class="copiable-link">¶</a>  
The Fortran interface routines for sorting double precision vectors are
`qsort3` and `qsort4`, equivalent to `R_qsort` and `R_qsort_I`,
respectively.

<span id="index-R_005fmax_005fcol" class="index-entry-id"></span>
<span id="index-R_005fmax_005fcol-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`void` **R_max_col** `(double* ``matrix``, int* ``nr``, int* ``nc``, int* ``maxes``, int* ``ties_meth``)` <a href="#index-R_005fmax_005fcol-2" class="copiable-link">¶</a>  
Given the `nr` by `nc` matrix `matrix` in column-major (“Fortran”)
order, `R_max_col()` returns in `maxes``[``i``-1]` the column number of
the maximal element in the `i`-th row (the same as R’s `max.col()`
function). In the case of ties (multiple maxima), `*ties_meth` is an
integer code in `1:3` determining the method: 1 = “random”, 2 = “first”
and 3 = “last”. See R’s help page `?max.col`.

<span id="index-findInterval" class="index-entry-id"></span>
<span id="index-findInterval-1" class="index-entry-id"></span>
<span id="index-findInterval2" class="index-entry-id"></span>
<span id="index-findInterval2-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`int` **findInterval** `(double* ``xt``, int ``n``, double ``x``, Rboolean ``rightmost_closed``, Rboolean ``all_inside``, int ``ilo``, int* ``mflag``)` <a href="#index-findInterval-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`int` **findInterval2** `(double* ``xt``, int ``n``, double ``x``, Rboolean ``rightmost_closed``, Rboolean ``all_inside``, Rboolean ``left_open``, int ``ilo``, int* ``mflag``)` <a href="#index-findInterval2-2" class="copiable-link">¶</a>  
Given the ordered vector `xt` of length `n`, return the interval or
index of `x` in `xt``[]`, typically max(*i*; 1 \<= i \<= `n` &
*`xt`\[i\]* \<= `x`) where we use 1-indexing as in R and Fortran (but
not C). If `rightmost_closed` is true, also returns *`n`-1* if `x`
equals *`xt`\[`n`\]*. If `all_inside` is not 0, the result is coerced to
lie in `1:(``n``-1)` even when `x` is outside the `xt`\[\] range. On
return, `*``mflag` equals *-1* if `x` \< `xt`\[1\], *+1* if `x` \>=
`xt`\[`n`\], and 0 otherwise.

The algorithm is particularly fast when `ilo` is set to the last result
of `findInterval()` and `x` is a value of a sequence which is increasing
or decreasing for subsequent calls.

`findInterval2()` is a generalization of `findInterval()`, with an extra
`Rboolean` argument `left_open`. Setting `left_open = TRUE` basically
replaces all left-closed right-open intervals t) by left-open ones t\],
see the help page of R function `findInterval` for details.

There is also an `F77_CALL(interv)()` version of `findInterval()` with
the same arguments, but all pointers.

<span id="index-interv" class="index-entry-id"></span>
<span id="index-interv-1" class="index-entry-id"></span>

A system-independent interface to produce the name of a temporary file
is provided as

<span id="index-R_005ftmpnam" class="index-entry-id"></span>
<span id="index-R_005ftmpnam-1" class="index-entry-id"></span>
<span id="index-R_005ftmpnam2" class="index-entry-id"></span>
<span id="index-R_005ftmpnam2-1" class="index-entry-id"></span>
<span id="index-R_005ffree_005ftmpnam" class="index-entry-id"></span>
<span id="index-R_005ffree_005ftmpnam-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`char *` **R_tmpnam** `(const char *``prefix``, const char *``tmpdir``)` <a href="#index-R_005ftmpnam-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`char *` **R_tmpnam2** `(const char *``prefix``, const char *``tmpdir``, const char *``fileext``)` <a href="#index-R_005ftmpnam2-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`void` **R_free_tmpnam** `(char *``name``)` <a href="#index-R_005ffree_005ftmpnam-2" class="copiable-link">¶</a>  
Return a pathname for a temporary file with name beginning with `prefix`
and ending with `fileext` in directory `tmpdir`. A `NULL` prefix or
extension is replaced by `""`. Note that the return value is dynamically
allocated and should be freed using `R_free_tmpnam` when no longer
needed (unlike the system call `tmpnam`). Freeing the result using
`free` is no longer recommended.

<span id="index-R_005fatof" class="index-entry-id"></span>
<span id="index-R_005fatof-1" class="index-entry-id"></span>
<span id="index-R_005fstrtod" class="index-entry-id"></span>
<span id="index-R_005fstrtod-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`double` **R_atof** `(const char* ``str``)` <a href="#index-R_005fatof-2" class="copiable-link">¶</a>  
<span class="category-def">Function: </span>`double` **R_strtod** `(const char* ``str``, char ** ``end``)` <a href="#index-R_005fstrtod-2" class="copiable-link">¶</a>  
Implementations of the C99/POSIX functions `atof` and `strtod` which
guarantee platform- and locale-independent behaviour, including always
using the period as the decimal point *aka* ‘radix character’ and
returning R’s `NA_REAL_` for all unconverted strings, including `"NA"`.

There is also the internal function used to expand file names in several
R functions, and called directly by `path.expand`.

<span id="index-R_005fExpandFileName" class="index-entry-id"></span>
<span id="index-R_005fExpandFileName-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`const char *` **R_ExpandFileName** `(const char *``fn``)` <a href="#index-R_005fExpandFileName-2" class="copiable-link">¶</a>  
Expand a path name `fn` by replacing a leading tilde by the user’s home
directory (if defined). The precise meaning is platform-specific; it
will usually be taken from the environment variable `HOME` if this is
defined.

<span id="index-acopy_005fstring" class="index-entry-id"></span>
<span id="index-acopy_005fstring-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`const char *` **acopy_string** `(const char *``in``)` <a href="#index-acopy_005fstring-2" class="copiable-link">¶</a>  
Return a copy of a string using memory from `R_alloc`.

For historical reasons there are Fortran interfaces to functions
`D1MACH` and `I1MACH`. These can be called from C code as e.g.
`F77_CALL(d1mach)(4)`. Note that these are emulations of the original
functions by Fox, Hall and Schryer on Netlib at
<a href="https://netlib.org/slatec/src/"
class="uref">https://netlib.org/slatec/src/</a> for IEC 60559 arithmetic
(required by R). <span id="index-d1mach" class="index-entry-id"></span>
<span id="index-d1mach-1" class="index-entry-id"></span>
<span id="index-i1mach" class="index-entry-id"></span>
<span id="index-i1mach-1" class="index-entry-id"></span>

------------------------------------------------------------------------

</div>

<div id="Linear-algebra" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Re_002dencoding" rel="next">Re-encoding</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Utility-functions" rel="prev">Utility functions</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.11 Linear algebra <a href="#Linear-algebra-1" class="copiable-link">¶</a>

The preferred way to do numerical linear algebra from C/Fortran code is
to use
BLAS/LAPACK<a href="#FOOT170" id="DOCF170" class="footnote"><sup>170</sup></a>
Declarations callable from C/C++ are provided in headers `R_ext/BLAS.h`
and `R_ext/LAPACK.h`.

However, a number of Fortran routines are included in R and underlie
`lm.fit()`, `lm.wfit()` and `qr(LAPACK = FALSE)` and its helper
functions. These remain available to packages which wish to emulate what
R does, and are declared as a C/C++ interface in header
`R_ext/Applic.h`. But they are also often called *via* `.Fortran()` and
from Fortran code.

<span id="index-dqrqty" class="index-entry-id"></span>
<span id="index-dqrqty-1" class="index-entry-id"></span>
<span id="index-dqrqy" class="index-entry-id"></span>
<span id="index-dqrqy-1" class="index-entry-id"></span>
<span id="index-dqrcf" class="index-entry-id"></span>
<span id="index-dqrcf-1" class="index-entry-id"></span>
<span id="index-dqrrsd" class="index-entry-id"></span>
<span id="index-dqrrsd-1" class="index-entry-id"></span>
<span id="index-dqrxb" class="index-entry-id"></span>
<span id="index-dqrxb-1" class="index-entry-id"></span>
<span id="index-dqrls" class="index-entry-id"></span>
<span id="index-dqrls-1" class="index-entry-id"></span>
<span id="index-dqrdc2" class="index-entry-id"></span>
<span id="index-dqrdc2-1" class="index-entry-id"></span>

<div class="example">

``` example-preformatted
void F77_NAME(dqrqty)(double *x, int *n, int *k, double *qraux,
                      double *y, int *ny, double *qty);
void F77_NAME(dqrqy)(double *x, int *n, int *k, double *qraux,
                     double *y, int *ny, double *qy);
void F77_NAME(dqrcf)(double *x, int *n, int *k, double *qraux,
                     double *y, int *ny, double *b, int *info);
void F77_NAME(dqrrsd)(double *x, int *n, int *k, double *qraux,
                     double *y, int *ny, double *rsd);
void F77_NAME(dqrxb)(double *x, int *n, int *k, double *qraux,
                     double *y, int *ny, double *xb);
void F77_NAME(dqrls)(double *x, int *n, int *p, double *y, int *ny,
                     double *tol, double *b, double *rsd,
                     double *qty, int *k,
                     int *jpvt, double *qraux, double *work);
void F77_NAME(dqrdc2)(double *x, int *ldx, int *n, int *p,
                      double *tol, int *rank,
                      double *qraux, int *pivot, double *work);
```

</div>

For further details see their source files in directory `src/Appl` in
the R sources or <a href="https://netlib.org/linpack/"
class="uref">https://netlib.org/linpack/</a>. `dqrdc2` is an extensive R
modification to LINPACK’s `dqrdc` which uses column pivoting and
computes the (numerical) rank.

These are for the time being regarded as part of the API but may in
future be supplemented or replaced by interfaces using Fortran 2003’s
`bind(C)`.

------------------------------------------------------------------------

</div>

<div id="Re_002dencoding" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Condition-handling-and-cleanup-code" rel="next">Condition
handling and cleanup code</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Linear-algebra" rel="prev">Linear algebra</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.12 Re-encoding <a href="#Re_002dencoding-1" class="copiable-link">¶</a>

R has its own C-level interface to the encoding conversion capabilities
provided by `iconv` because there are incompatibilities between the
declarations in different implementations of `iconv`.

These are declared in header file `R_ext/Riconv.h`.
<span id="index-R_005fext_002fRiconv_002eh"
class="index-entry-id"></span>

<span id="index-Riconv_005fopen" class="index-entry-id"></span>
<span id="index-Riconv_005fopen-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`void *` **Riconv_open** `(const char *``to``, const char *``from``)` <a href="#index-Riconv_005fopen-2" class="copiable-link">¶</a>  
Set up a pointer to an encoding object to be used to convert between two
encodings: `""` indicates the current locale.

<span id="index-Riconv" class="index-entry-id"></span>
<span id="index-Riconv-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`size_t` **Riconv** `(void *``cd``, const char **``inbuf``, size_t *``inbytesleft``, char **``outbuf``, size_t *``outbytesleft``)` <a href="#index-Riconv-2" class="copiable-link">¶</a>  
Convert as much as possible of `inbuf` to `outbuf`. Initially the
`size_t` variables indicate the number of bytes available in the
buffers, and they are updated (and the `char` pointers are updated to
point to the next free byte in the buffer). The return value is the
number of characters converted, or `(size_t)-1` (beware: `size_t` is
usually an unsigned type). It should be safe to assume that an error
condition sets `errno` to one of `E2BIG` (the output buffer is full),
`EILSEQ` (the input cannot be converted, and might be invalid in the
encoding specified) or `EINVAL` (the input does not end with a complete
multi-byte character).

<span id="index-Riconv_005fclose" class="index-entry-id"></span>
<span id="index-Riconv_005fclose-1" class="index-entry-id"></span>

<span class="category-def">Function: </span>`int` **Riconv_close** `(void * ``cd``)` <a href="#index-Riconv_005fclose-2" class="copiable-link">¶</a>  
Free the resources of an encoding object.

------------------------------------------------------------------------

</div>

<div id="Condition-handling-and-cleanup-code"
class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Allowing-interrupts" rel="next">Allowing interrupts</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Re_002dencoding" rel="prev">Re-encoding</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.13 Condition handling and cleanup code <a href="#Condition-handling-and-cleanup-code-1"
class="copiable-link">¶</a>

<span id="index-Condition-handling" class="index-entry-id"></span>
<span id="index-Cleanup-code" class="index-entry-id"></span>
<span id="index-Error-handling" class="index-entry-id"></span>

Three functions are available for establishing condition handlers from
within C code:

<div class="example">

``` example-preformatted
#include <Rinternals.h>

SEXP R_tryCatchError(SEXP (*fun)(void *data), void *data,
                     SEXP (*hndlr)(SEXP cond, void *hdata), void *hdata);

SEXP R_tryCatch(SEXP (*fun)(void *data), void *data,
                SEXP,
                SEXP (*hndlr)(SEXP cond, void *hdata), void *hdata,
                void (*clean)(void *cdata), void *cdata);
SEXP R_withCallingErrorHandler(SEXP (*fun)(void *data), void *data,
                               SEXP (*hndlr)(SEXP cond, void *hdata), void *hdata)
```

</div>

<span id="index-R_005ftryCatchError" class="index-entry-id"></span>
<span id="index-R_005ftryCatchError-1" class="index-entry-id"></span>
<span id="index-R_005ftryCatch" class="index-entry-id"></span>
<span id="index-R_005ftryCatch-1" class="index-entry-id"></span>
<span id="index-R_005fwithCallingErrorHandler"
class="index-entry-id"></span>
<span id="index-R_005fwithCallingErrorHandler-1"
class="index-entry-id"></span>

`R_tryCatchError` establishes an exiting handler for conditions
inheriting form class `error`.

`R_tryCatch` can be used to establish a handler for other conditions and
to register a cleanup action. The conditions to be handled are specified
as a character vector (`STRSXP`). A `NULL` pointer can be passed as
`fun` or `clean` if condition handling or cleanup are not needed.

These are currently implemented using the R-level `tryCatch` mechanism
so are subject to some overhead.

`R_withCallingErrorHandler` establishes a calling handler for conditions
inheriting from class `error`. It establishes the handler without
calling back into R and will therefore be more efficient.

The function `R_UnwindProtect` can be used to ensure that a cleanup
action takes place on ordinary return as well as on a non-local transfer
of control, which R implements as a `longjmp`.

<div class="example">

``` example-preformatted
SEXP R_UnwindProtect(SEXP (*fun)(void *data), void *data,
                     void (*clean)(void *data, Rboolean jump), void *cdata,
                     SEXP cont);
```

</div>

<span id="index-R_005fUnwindProtect" class="index-entry-id"></span>
<span id="index-R_005fUnwindProtect-1" class="index-entry-id"></span>

`R_UnwindProtect` can be used in two ways. The simper usage, suitable
for use in C code, passes `NULL` for the `cont` argument.
`R_UnwindProtect` will call `fun(data)`. If `fun` returns a value, then
`R_UnwindProtect` calls `clean(cleandata, FALSE)` before returning the
value returned by `fun`. If `fun` executes a non-local transfer of
control, then `clean(cleandata, TRUE)` is called, and the non-local
transfer of control is resumed.

The second use pattern, suitable to support C++ stack unwinding, uses
two additional functions:

<div class="example">

``` example-preformatted
SEXP R_MakeUnwindCont();
NORET void R_ContinueUnwind(SEXP cont);
```

</div>

<span id="index-R_005fMakeUnwindCont" class="index-entry-id"></span>
<span id="index-R_005fMakeUnwindCont-1" class="index-entry-id"></span>
<span id="index-R_005fContinueUnwind" class="index-entry-id"></span>
<span id="index-R_005fContinueUnwind-1" class="index-entry-id"></span>

`R_MakeUnwindCont` allocates a *continuation token* `cont` to pass to
`R_UnwindProtect`. This token should be protected with `PROTECT` before
calling `R_UnwindProtect`. When the `clean` function is called with
`jump == TRUE`, indicating that R is executing a non-local transfer of
control, it can throw a C++ exception to a C++ `catch` outside the C++
code to be unwound, and then use the continuation token in the a call
`R_ContinueUnwind(cont)` to resume the non-local transfer of control
within R.

An older interface for the simpler `R_MakeUnwindCont` usage remains
available:

<div class="example">

``` example-preformatted
SEXP R_ExecWithCleanup(SEXP (*fun)(void *), void *data,
                       void (*cleanfun)(void *), void *cleandata);
```

</div>

<span id="index-R_005fExecWithCleanup" class="index-entry-id"></span>
<span id="index-R_005fExecWithCleanup-1" class="index-entry-id"></span>

`cleanfun` is called on both regular returns and non-local transfers of
control, but without an indication of which form of exit is occurring.

The function `R_ToplevelExec` can be used to execute code without
allowing any non-local transfers of control, including by user
interrupts or invoking `abort` restarts.

<div class="example">

``` example-preformatted
Rboolean R_ToplevelExec(void (*fun)(void *), void *data);
```

</div>

<span id="index-R_005fToplevelExec" class="index-entry-id"></span>
<span id="index-R_005fToplevelExec-1" class="index-entry-id"></span>

The return value is `TRUE` if `fun` returns normally and `FALSE` if
`fun` exits with a jump to top level. `fun` is called with a new
top-level context. Condition handlers and other features of the current
top level context when `R_ToplevelExec` is called will not be seen by
the code in `fun`. Two convenience functions built on `R_ToplevelExec`
are `R_tryEval` and `R_tryEvalSilent`.

<div class="example">

``` example-preformatted
SEXP R_tryEval(SEXP e, SEXP env, int *ErrorOccurred);
SEXP R_tryEvalSilent(SEXP e, SEXP env, int *ErrorOccurred);
```

</div>

<span id="index-R_005ftryEvalSilent" class="index-entry-id"></span>
<span id="index-R_005ftryEvalSilent-1" class="index-entry-id"></span>
<span id="index-R_005ftryEval" class="index-entry-id"></span>
<span id="index-R_005ftryEval-1" class="index-entry-id"></span>

These return a `NULL` pointer if evaluating the expression results in a
jump to top level.

Using `R_ToplevelExec` is usually only appropriate in situations where
one might want to run code in a separate thread if that was an option.
For example, finalizers are run in a separate top level context. The
other functions mentioned in this section will usually be more
appropriate choices.

Currently, if these evaluations produce an error that is handled by the
default handler, then the error message will be stored in a buffer that
can be accessed with `R_curErrorBuf`.

<div class="example">

``` example-preformatted
const char *R_curErrorBuf(void);
```

</div>

<span id="index-R_005fcurErrorBuf" class="index-entry-id"></span>
<span id="index-R_005fcurErrorBuf-1" class="index-entry-id"></span>

This design could change in the future.

------------------------------------------------------------------------

</div>

<div id="Allowing-interrupts" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#C-stack-checking" rel="next">C stack checking</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Condition-handling-and-cleanup-code" rel="prev">Condition
handling and cleanup code</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.14 Allowing interrupts <a href="#Allowing-interrupts-1" class="copiable-link">¶</a>

<span id="index-Interrupts" class="index-entry-id"></span>

No part of R can be interrupted whilst running long computations in
compiled code, so programmers should make provision for the code to be
interrupted at suitable points by calling from C

<div class="example">

``` example-preformatted
#include <R_ext/Utils.h>

void R_CheckUserInterrupt(void);
```

</div>

<span id="index-R_005fCheckUserInterrupt" class="index-entry-id"></span>
<span id="index-R_005fCheckUserInterrupt-1"
class="index-entry-id"></span>

and from Fortran

<div class="example">

``` example-preformatted
subroutine rchkusr()
```

</div>

<span id="index-rchkusr-1" class="index-entry-id"></span>
<span id="index-rchkusr" class="index-entry-id"></span>

These check if the user has requested an interrupt, and if so branch to
R’s error signaling functions.

Note that it is possible that the code behind one of the entry points
defined here if called from your C or Fortran code could be
interruptible or generate an error and so not return to your code.

------------------------------------------------------------------------

</div>

<div id="C-stack-checking" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Custom-serialization-input-and-output" rel="next">Custom
serialization input and output</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Allowing-interrupts" rel="prev">Allowing interrupts</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.15 C stack checking <a href="#C-stack-checking-1" class="copiable-link">¶</a>

<span id="index-C-stack-checking" class="index-entry-id"></span>

R provides a framework for detecting when the amount of C stack is too
low. Two functions are available:

<div class="example">

``` example-preformatted
void R_CheckStack(void)
void R_CheckStack2(size_t extra)
```

</div>

<span id="index-R_005fCheckStack" class="index-entry-id"></span>
<span id="index-R_005fCheckStack-1" class="index-entry-id"></span>
<span id="index-R_005fCheckStack2" class="index-entry-id"></span>
<span id="index-R_005fCheckStack2-1" class="index-entry-id"></span>

These functions signal an error when a low stack condition is detected.
`R_CheckStack2` does so when `extra` bytes are more than is available on
the stack.

This mechanism is not always available (See
<a href="#Threading-issues" class="xref">Threading issues</a>) and it is
best to avoid deep recursions in C and to track recursion depth when
using recursion is unavoidable. C compilers will often optimize tail
recursions to avoid consuming C stack, so it is best to write code in a
tail-recursive form when possible.

------------------------------------------------------------------------

</div>

<div id="Custom-serialization-input-and-output"
class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Platform-and-version-information" rel="next">Platform and
version information</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#C-stack-checking" rel="prev">C stack checking</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.16 Custom serialization input and output <a href="#Custom-serialization-input-and-output-1"
class="copiable-link">¶</a>

<span id="index-Serialization" class="index-entry-id"></span>

The internal serialization code uses a framework for serializing from
and to different output media. This framework has been in use internally
for some time, but its use in packages is highly experimental and may
need to be changed or dropped once some experience is gained. Package
authors considering using this framework should keep this in mind.

Client code will define a persistent stream structure with declarations
like

<div class="example">

``` example-preformatted
struct R_outpstream_st out;
struct R_inpstream_st in;
```

</div>

These are filled in by calling these functions with appropriate
arguments:

<div class="example">

``` example-preformatted
void R_InitInPStream(R_inpstream_t stream, R_pstream_data_t data,
                     R_pstream_format_t type,
                     int (*inchar)(R_inpstream_t),
                     void (*inbytes)(R_inpstream_t, void *, int),
                     SEXP (*phook)(SEXP, SEXP), SEXP pdata);
void R_InitOutPStream(R_outpstream_t stream, R_pstream_data_t data,
                      R_pstream_format_t type, int version,
                      void (*outchar)(R_outpstream_t, int),
                      void (*outbytes)(R_outpstream_t, void *, int),
                      SEXP (*phook)(SEXP, SEXP), SEXP pdata);
```

</div>

Code should not depend on the fields of the stream structures. Simpler
initializers are available for serializing to or from a file pointer:

<div class="example">

``` example-preformatted
void R_InitFileOutPStream(R_outpstream_t stream, FILE *fp,
                          R_pstream_format_t type, int version,
                          SEXP (*phook)(SEXP, SEXP), SEXP pdata);
void R_InitFileInPStream(R_inpstream_t stream, FILE *fp,
                         R_pstream_format_t type,
                         SEXP (*phook)(SEXP, SEXP), SEXP pdata);
```

</div>

Once the stream structures are set up they can be used by calling

<div class="example">

``` example-preformatted
void R_Serialize(SEXP s, R_outpstream_t stream)
SEXP R_Unserialize(R_inpstream_t stream)
```

</div>

Examples can be found in the R sources in `src/main/serialize.c`.
<span id="index-R_005fInitFileOutPStream" class="index-entry-id"></span>
<span id="index-R_005fInitFileOutPStream-1"
class="index-entry-id"></span> <span id="index-R_005fInitFileInPStream"
class="index-entry-id"></span>
<span id="index-R_005fInitFileInPStream-1"
class="index-entry-id"></span> <span id="index-R_005fInitInPStream"
class="index-entry-id"></span> <span id="index-R_005fInitInPStream-1"
class="index-entry-id"></span> <span id="index-R_005fUnserialize"
class="index-entry-id"></span> <span id="index-R_005fUnserialize-1"
class="index-entry-id"></span> <span id="index-R_005fInitOutPStream"
class="index-entry-id"></span> <span id="index-R_005fInitOutPStream-1"
class="index-entry-id"></span> <span id="index-R_005fSerialize"
class="index-entry-id"></span> <span id="index-R_005fSerialize-1"
class="index-entry-id"></span>

------------------------------------------------------------------------

</div>

<div id="Platform-and-version-information" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Inlining-C-functions" rel="next">Inlining C functions</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Custom-serialization-input-and-output" rel="prev">Custom
serialization input and output</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.17 Platform and version information <a href="#Platform-and-version-information-1"
class="copiable-link">¶</a>

<span id="index-Version-information-from-C"
class="index-entry-id"></span> <span id="index-OpenMP-1"
class="index-entry-id"></span> <span id="index-R_005fVersion"
class="index-entry-id"></span> <span id="index-R_005fVersion-1"
class="index-entry-id"></span>

The header files define `USING_R`, which can be used to test if the code
is indeed being used with R.

Header file `Rconfig.h` (included by `R.h`) is used to define
platform-specific macros that are mainly for use in other header files.
The macro `WORDS_BIGENDIAN` is defined on
big-endian<a href="#FOOT171" id="DOCF171" class="footnote"><sup>171</sup></a>
systems (e.g. most OSes on Sparc and PowerPC hardware) and not on
little-endian systems (nowadays all the commoner R platforms). It can be
useful when manipulating binary files. NB: these macros apply only to
the C compiler used to build R, not necessarily to another C or C++
compiler.

Header file `Rversion.h` (**not** included by `R.h`) defines a macro
`R_VERSION` giving the version number encoded as an integer, plus a
macro `R_Version` to do the encoding. This can be used to test if the
version of R is late enough, or to include back-compatibility features,
such as

<div class="example">

<div class="group">

``` example-preformatted
#if R_VERSION >= R_Version(3, 1, 0)
  ...
#endif
```

</div>

</div>

More detailed information is available in the macros `R_MAJOR`,
`R_MINOR`, `R_YEAR`, `R_MONTH` and `R_DAY`: see the header file
`Rversion.h` for their format. Note that the minor version includes the
patch level (as in ‘`2.2`’).

Packages which use `alloca` need to ensure it is defined: as it is part
of neither C nor POSIX there is no standard way to do so. One can use

<div class="example">

``` example-preformatted
#include <Rconfig.h> // for HAVE_ALLOCA_H
#ifdef __GNUC__
// this covers gcc, clang, icc
# undef alloca
# define alloca(x) __builtin_alloca((x))
#elif defined(HAVE_ALLOCA_H)
// needed for native compilers on Solaris and AIX
# include <alloca.h>
#endif
```

</div>

(and this should be included before standard C headers such as
`stdlib.h`, since on some platforms these include `malloc.h` which may
have a conflicting definition), which suffices for known R platforms.

------------------------------------------------------------------------

</div>

<div id="Inlining-C-functions" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Controlling-visibility" rel="next">Controlling visibility</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Platform-and-version-information" rel="prev">Platform and
version information</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.18 Inlining C functions <a href="#Inlining-C-functions-1" class="copiable-link">¶</a>

<span id="index-R_005fINLINE" class="index-entry-id"></span>
<span id="index-R_005fINLINE-1" class="index-entry-id"></span>

The C99 keyword `inline` should be recognized by all compilers nowadays
used to build R. Portable code which might be used with earlier versions
of R can be written using the macro `R_INLINE` (defined in file
`Rconfig.h` included by `R.h`), as for example from package
<a href="https://CRAN.R-project.org/package=cluster"
class="url"><strong>cluster</strong></a>

<div class="example">

``` example-preformatted
#include <R.h>

static R_INLINE int ind_2(int l, int j)
{
...
}
```

</div>

Be aware that using inlining with functions in more than one compilation
unit is almost impossible to do portably, see
<a href="https://www.greenend.org.uk/rjk/tech/inline.html"
class="uref">https://www.greenend.org.uk/rjk/tech/inline.html</a>, so
this usage is for `static` functions as in the example. All the R
configure code has checked is that `R_INLINE` can be used in a single C
file with the compiler used to build R. We recommend that packages
making extensive use of inlining include their own configure code.

------------------------------------------------------------------------

</div>

<div id="Controlling-visibility" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Standalone-Mathlib" rel="next">Using these functions in your
own C code</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Inlining-C-functions" rel="prev">Inlining C functions</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.19 Controlling visibility <a href="#Controlling-visibility-1" class="copiable-link">¶</a>

<span id="index-Visibility" class="index-entry-id"></span>

Header `R_ext/Visibility.h` has some definitions for controlling the
visibility of entry points. These are only effective when
‘`HAVE_VISIBILITY_ATTRIBUTE`’ is defined – this is checked when R is
configured and recorded in header `Rconfig.h` (included by
`R_ext/Visibility.h`). It is often defined on modern Unix-alikes with a
recent
compiler<a href="#FOOT172" id="DOCF172" class="footnote"><sup>172</sup></a>
but not supported on Windows. Minimizing the visibility of symbols in a
shared library will both speed up its loading (unlikely to be
significant) and reduce the possibility of linking to other entry points
of the same name.

C/C++ entry points prefixed by `attribute_hidden` will not be visible in
the shared object. There is no comparable mechanism for Fortran entry
points, but there is a more comprehensive scheme used by, for example
package **stats**. Most compilers which allow control of visibility will
allow control of visibility for all symbols *via* a flag, and where
known the flag is encapsulated in the macros ‘`C_VISIBILITY`’,
‘`CXX_VISIBILITY`’<a href="#FOOT173" id="DOCF173" class="footnote"><sup>173</sup></a>
and ‘`F_VISIBILITY`’ for C, C++ and Fortran
compilers.<a href="#FOOT174" id="DOCF174" class="footnote"><sup>174</sup></a>
These are defined in `etc/Makeconf` and so available for normal
compilation of package code. For example, `src/Makevars` could include
some of

<div class="example">

``` example-preformatted
PKG_CFLAGS=$(C_VISIBILITY)
PKG_CXXFLAGS=$(CXX_VISIBILITY)
PKG_FFLAGS=$(F_VISIBILITY)
```

</div>

This would end up with **no** visible entry points, which would be
pointless. However, the effect of the flags can be overridden by using
the `attribute_visible` prefix. A shared object which registers its
entry points needs only for have one visible entry point, its
initializer, so for example package **stats** has

<div class="example">

``` example-preformatted
void attribute_visible R_init_stats(DllInfo *dll)
{
    R_registerRoutines(dll, CEntries, CallEntries, FortEntries, NULL);
    R_useDynamicSymbols(dll, FALSE);
...
}
```

</div>

Because the ‘`C_VISIBILITY`’ mechanism is only useful in conjunction
with `attribute_visible`, it is not enabled unless
‘`HAVE_VISIBILITY_ATTRIBUTE`’ is defined. The usual visibility flag is
`-fvisibility=hidden`: some compilers also support
`-fvisibility-inlines-hidden` which can be used by overriding
‘`C_VISIBILITY`’ and ‘`CXX_VISIBILITY`’ in `config.site` when building
R, or editing `etc/Makeconf` in the R installation.

Note that `configure` only checks that visibility attributes and flags
are accepted, not that they actually hide symbols.

The visibility mechanism is not available on Windows, but there is an
equally effective way to control which entry points are visible, by
supplying a definitions file `pkgname``/src/``pkgname``-win.def`: only
entry points listed in that file will be visible. Again using **stats**
as an example, it has

<div class="example">

``` example-preformatted
LIBRARY stats.dll
EXPORTS
 R_init_stats
```

</div>

------------------------------------------------------------------------

</div>

<div id="Standalone-Mathlib" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Organization-of-header-files" rel="next">Organization of
header files</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Controlling-visibility" rel="prev">Controlling visibility</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.20 Using these functions in your own C code <a href="#Using-these-functions-in-your-own-C-code"
class="copiable-link">¶</a>

It is possible to build `Mathlib`, the R set of mathematical functions
documented in `Rmath.h`, as a standalone library `libRmath` under both
Unix-alikes and Windows. (This includes the functions documented in
<a href="#Numerical-analysis-subroutines" class="ref">Numerical analysis
subroutines</a> as from that header file.)

The library is not built automatically when R is installed. For further
details see <a href="R-admin.html#The-standalone-Rmath-library"
data-manual="R-admin">The standalone Rmath library</a> in R Installation
and Administration.

------------------------------------------------------------------------

</div>

<div id="Organization-of-header-files" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Hash-tables" rel="next">Hash tables</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Standalone-Mathlib" rel="prev">Using these functions in your
own C code</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.21 Organization of header files <a href="#Organization-of-header-files-1" class="copiable-link">¶</a>

The header files which R installs are in directory `R_INCLUDE_DIR`
(default `R_HOME``/include`). This currently includes

> |                       |                                                                                              |
> |-----------------------|----------------------------------------------------------------------------------------------|
> | `R.h`                 | includes many other files                                                                    |
> | `Rinternals.h`        | definitions for using R’s internal structures                                                |
> | `Rdefines.h`          | macros for an S-like interface to the above (no longer maintained)                           |
> | `Rmath.h`             | standalone math library                                                                      |
> | `Rversion.h`          | R version information                                                                        |
> | `Rinterface.h`        | for add-on front-ends (Unix-alikes only)                                                     |
> | `Rembedded.h`         | for add-on front-ends                                                                        |
> | `R_ext/Applic.h`      | optimization, integration and some LAPACK ones)                                              |
> | `R_ext/BLAS.h`        | C definitions for BLAS routines                                                              |
> | `R_ext/Callbacks.h`   | C (and R function) top-level task handlers                                                   |
> | `R_ext/GetX11Image.h` | X11Image interface used by package **trkplot**                                               |
> | `R_ext/Lapack.h`      | C definitions for some LAPACK routines                                                       |
> | `R_ext/Linpack.h`     | C definitions for some LINPACK routines, not all of which are included in R                  |
> | `R_ext/Parse.h`       | a small part of R’s parse interface: not part of the stable API.                             |
> | `R_ext/RStartup.h`    | for add-on front-ends                                                                        |
> | `R_ext/Rdynload.h`    | needed to register compiled code in packages                                                 |
> | `R_ext/Riconv.h`      | interface to `iconv`                                                                         |
> | `R_ext/Visibility.h`  | definitions controlling visibility                                                           |
> | `R_ext/eventloop.h`   | for add-on front-ends and for packages that need to share in the R event loops (not Windows) |

<span id="index-R_005fGetX11Image" class="index-entry-id"></span>
<span id="index-R_005fGetX11Image-1" class="index-entry-id"></span>

The following headers are included by `R.h`:

> |                     |                                                                             |
> |---------------------|-----------------------------------------------------------------------------|
> | `Rconfig.h`         | configuration info that is made available                                   |
> | `R_ext/Arith.h`     | handling for `NA`s, `NaN`s, `Inf`/`-Inf`                                    |
> | `R_ext/Boolean.h`   | `TRUE`/`FALSE` type                                                         |
> | `R_ext/Complex.h`   | C typedefs for R’s `complex`                                                |
> | `R_ext/Constants.h` | constants                                                                   |
> | `R_ext/Error.h`     | error signaling                                                             |
> | `R_ext/Memory.h`    | memory allocation                                                           |
> | `R_ext/Print.h`     | `Rprintf` and variations.                                                   |
> | `R_ext/RS.h`        | definitions common to `R.h` and the former `S.h`, including `F77_CALL` etc. |
> | `R_ext/Random.h`    | random number generation                                                    |
> | `R_ext/Utils.h`     | sorting and other utilities                                                 |
> | `R_ext/libextern.h` | definitions for exports from `R.dll` on Windows.                            |

<span id="index-R_005fext_002fMemory_002eh"
class="index-entry-id"></span>
<span id="index-R_005fext_002fRandom_002eh"
class="index-entry-id"></span>

The graphics systems are exposed in headers `R_ext/GraphicsEngine.h`,
`R_ext/GraphicsDevice.h` (which it includes) and `R_ext/QuartzDevice.h`.
Facilities for defining custom connection implementations are provided
in `R_ext/Connections.h`, but make sure you consult the file before use.
<span id="index-R_005fext_002fQuartzDevice_002eh"
class="index-entry-id"></span>
<span id="index-R_005fext_002fGraphicsEngine_002eh"
class="index-entry-id"></span>
<span id="index-R_005fext_002fGraphicsDevice_002eh"
class="index-entry-id"></span>
<span id="index-R_005fext_002fConnections_002eh"
class="index-entry-id"></span>
<span id="index-R_005fnew_005fcustom_005fconnection"
class="index-entry-id"></span>
<span id="index-R_005fnew_005fcustom_005fconnection-1"
class="index-entry-id"></span> <span id="index-R_005fReadConnection"
class="index-entry-id"></span> <span id="index-R_005fReadConnection-1"
class="index-entry-id"></span> <span id="index-R_005fWriteConnection"
class="index-entry-id"></span> <span id="index-R_005fWriteConnection-1"
class="index-entry-id"></span> <span id="index-R_005fGetConnection"
class="index-entry-id"></span> <span id="index-R_005fGetConnection-1"
class="index-entry-id"></span>

Let us re-iterate the advice to include in C++ code system headers
before the R header files, especially `Rinternals.h` (included by
`Rdefines.h`) and `Rmath.h`, which redefine names which may be used in
system headers, or (preferably and the default since R 4.5.0) to define
`R_NO_REMAP`.

------------------------------------------------------------------------

</div>

<div id="Hash-tables" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Moving-into-C-API-compliance" rel="next">Moving into C API
compliance</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Organization-of-header-files" rel="prev">Organization of
header files</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.22 Hash tables <a href="#Hash-tables-1" class="copiable-link">¶</a>

An implementation of hash tables is available that is accessible from
the R and C level. The C interface is experimental and may change. It is
currently declared in `Rinternals.h`. <span id="index-R_005fasHashtable"
class="index-entry-id"></span> <span id="index-R_005fasHashtable-1"
class="index-entry-id"></span> <span id="index-R_005fHashtabSEXP"
class="index-entry-id"></span> <span id="index-R_005fHashtabSEXP-1"
class="index-entry-id"></span> <span id="index-R_005fisHashtable"
class="index-entry-id"></span> <span id="index-R_005fisHashtable-1"
class="index-entry-id"></span> <span id="index-R_005fmkhashtab"
class="index-entry-id"></span> <span id="index-R_005fmkhashtab-1"
class="index-entry-id"></span> <span id="index-R_005fgethash"
class="index-entry-id"></span> <span id="index-R_005fgethash-1"
class="index-entry-id"></span> <span id="index-R_005fsethash"
class="index-entry-id"></span> <span id="index-R_005fsethash-1"
class="index-entry-id"></span> <span id="index-R_005fremhash"
class="index-entry-id"></span> <span id="index-R_005fremhash-1"
class="index-entry-id"></span> <span id="index-R_005fnumhash"
class="index-entry-id"></span> <span id="index-R_005fnumhash-1"
class="index-entry-id"></span> <span id="index-R_005ftyphash"
class="index-entry-id"></span> <span id="index-R_005ftyphash-1"
class="index-entry-id"></span> <span id="index-R_005fmaphash"
class="index-entry-id"></span> <span id="index-R_005fmaphash-1"
class="index-entry-id"></span> <span id="index-R_005fmaphashC"
class="index-entry-id"></span> <span id="index-R_005fmaphashC-1"
class="index-entry-id"></span> <span id="index-R_005fclrhash"
class="index-entry-id"></span> <span id="index-R_005fclrhash-1"
class="index-entry-id"></span>

------------------------------------------------------------------------

</div>

<div id="Moving-into-C-API-compliance" class="section-level-extent">

<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Hash-tables" rel="prev">Hash tables</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#The-R-API" rel="up">The R API: entry points for C code</a></span></span><span class="nav-button">
 
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

### 6.23 Moving into C API compliance <a href="#Moving-into-C-API-compliance-1" class="copiable-link">¶</a>

Work is in progress to clarify and tighten the C API for extending R
code. This will help make package C code more robust, and will
facilitate maintaining and improving the R source code without impacting
package space. In the process a number of entry points intended for
internal use will be removed from installed header files or hidden, and
others will be replaced by more robust versions better suited for use in
package C code. This section describes how packages can move from using
non-API entry points to using ones available and supported in the API.

**Work in progress:** This section is a work in progress and will be
adjusted as changes are made to the API.

- [Some API replacements for non-API entry
  points](#Some-API-replacements-for-non_002dAPI-entry-points)
- [Some API replacements for non-API
  variables](#Some-API-replacements-for-non_002dAPI-variables)
- [Creating environments](#Creating-environments)
- [Creating call expressions](#Creating-call-expressions)
- [Creating closures](#Creating-closures)
- [Querying `CHARSXP` encoding](#Querying-CHARSXP-encoding)
- [Working with attributes](#Working-with-attributes)
- [Working with variable bindings](#Working-with-variable-bindings)
- [Some backports](#Some-backports)

------------------------------------------------------------------------

<div id="Some-API-replacements-for-non_002dAPI-entry-points"
class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Some-API-replacements-for-non_002dAPI-variables"
rel="next">Some API replacements for non-API variables</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Moving-into-C-API-compliance" rel="up">Moving into C API
compliance</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.23.1 Some API replacements for non-API entry points <a href="#Some-API-replacements-for-non_002dAPI-entry-points-1"
class="copiable-link">¶</a>

Some non-API entry points intended for internal use have long had entry
points in the API that can be used instead. In other cases new entry
point have been added that are more appropriate for use in packages;
typically these include more extensive error checking on arguments.

This table lists some non-API functions used in packages and the API
functions that should be used instead:

`EXTPTR_PROT`  
`EXTPTR_TAG`  
`EXTPTR_PTR`  
Use `R_ExternalPtrProtected`, `R_ExternalPtrTag`, and
`R_ExternalPtrAddr`.

`OBJECT`  
`IS_S4_OBJECT`  
Use `Rf_isObject` and `Rf_isS4`.

`GetOption`  
Use `Rf_GetOption1`.

`R_lsInternal`  
Use `R_lsInternal3`.

`REAL0`  
`COMPLEX0`  
Use `REAL` and `COMPLEX`.

`STRING_PTR`  
`DATAPTR`  
`STDVEC_DATAPTR`  
Use `STRING_PTR_RO` and `DATAPTR_RO`. Obtaining writable pointers to
these data can violate the memory manager’s integrity assumptions and is
not supported. One exception is that a writable pointer may need to be
returned by an `ALTREP` `Dataptr` method. The function `DATAPTR_RW` can
use for this purpose.

`isFrame`  
Use `Rf_isDataFrame`, added in R 4.5.0.

`BODY`  
`FORMALS`  
`CLOENV`  
Use `R_ClosureBody`, `R_ClosureFormals`, and `R_ClosureEnv`; these were
added in R 4.5.0.

`ENCLOS`  
Use `R_ParentEnv`, added in R 4.5.0.

`IS_ASCII`  
Use `Rf_charIsASCII`, added in R 4.5.0.

`IS_UTF8`  
Use `charIsUTF8`, added in R 4.5.0, or avoid completely.

`Rf_allocSExp`  
Use an appropriate constructor.

`Rf_findVarInFrame3`  
Use `R_existsVarInFrame` to test for existence.

`Rf_findVar`  
`Rf_findVarInFrame`  
Use `R_getVar` or `R_getVarEx`, added in R 4.5.0. In some cases using
`eval` may suffice.

`ATTRIB`  
Use `Rf_getAttrib` for individual attributes. To test whether there are
any attributes use `ANY_ATTRIB`, added in R 4.5.0. `R_mapAttrib` was
added in R 4.6.0 for iterating over an object’s attributes.

`SET_ATTRIB`  
`SET_OBJECT`  
Use `Rf_setAttrib` for individual attributes, `DUPLICATE_ATTRIB` or
`SHALLOW_DUPLICATE_ATTRIB` for copying attributes from one object to
another. Use `CLEAR_ATTRIB` for removing all attributes, added in R
4.5.0.

`ENVFLAGS`  
`SET_ENVFLAGS`  
Use `R_EnvironmentIsLocked` and `R_LockEnvironment` instead.

`R_GetCurrentEnv`  
Use `environment()` at the R level and pass the result as an argument to
your C function.

`SETLENGTH`  
See <a href="#Resizing-vectors" class="ref">Resizing vectors</a>.

`R_data_class`  
Use `R_class` added in R 4.6.0

`PRVALUE SET_PRVALUE`  
`PRCODE SET_PRCODE R_PromiseExpr`  
`PRENV SET_PRENV`  
Use the binding access API added in R 4.6.0. See
<a href="#Working-with-variable-bindings" class="xref">Working with
variable bindings</a>.

For recently added entry points packages that need to be compiled under
older versions that do not yet contain these entry points can use
back-ported versions defined conditionally. See
<a href="#Some-backports" class="xref">Some backports</a>.

------------------------------------------------------------------------

</div>

<div id="Some-API-replacements-for-non_002dAPI-variables"
class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Creating-environments" rel="next">Creating environments</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Some-API-replacements-for-non_002dAPI-entry-points"
rel="prev">Some API replacements for non-API entry points</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Moving-into-C-API-compliance" rel="up">Moving into C API
compliance</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.23.2 Some API replacements for non-API variables <a href="#Some-API-replacements-for-non_002dAPI-variables-1"
class="copiable-link">¶</a>

Non-API variables should not be used in packages as they may depend on
internal structure that may change, or changing them might damage R’s
internal state. Some non-API variables can be accessed through a
function interface.

`SaveVar`  
Use `R_GetSaveAction` and `R_SetSaveAction`.

`R_NamespaceRegistry`  
Use `R_getRegisteredNamespace` to find a registered namespace.

------------------------------------------------------------------------

</div>

<div id="Creating-environments" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Creating-call-expressions" rel="next">Creating call
expressions</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Some-API-replacements-for-non_002dAPI-variables"
rel="prev">Some API replacements for non-API variables</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Moving-into-C-API-compliance" rel="up">Moving into C API
compliance</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.23.3 Creating environments <a href="#Creating-environments-1" class="copiable-link">¶</a>

An idiom appearing in a number of packages is to create an environment
as

<div class="example">

``` example-preformatted
SEXP env = Rf_allocSExp(ENVSXP);
SET_ENCLOS(env, parent);
```

</div>

The function `Rf_allocSExp` and mutation functions like `SET_ENCLOS`,
`SET_FRAME`, and `SET_HASHTAB` are not part of the API as they expose
internal structure that might need to change in the future. A proper
constructor function should be used instead. The constructor function
for environments is `R_NewEnv`, so the new environment should be created
as

<div class="example">

``` example-preformatted
SEXP env = R_NewEnv(parent, FALSE, 0);
```

</div>

------------------------------------------------------------------------

</div>

<div id="Creating-call-expressions" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Creating-closures" rel="next">Creating closures</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Creating-environments" rel="prev">Creating environments</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Moving-into-C-API-compliance" rel="up">Moving into C API
compliance</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.23.4 Creating call expressions <a href="#Creating-call-expressions-1" class="copiable-link">¶</a>

Another idiom used in some packages is to create a call expression with
space for two arguments as

<div class="example">

``` example-preformatted
SEXP expr = Rf_allocList(3);
SET_TYPEOF(expr, "LANGSXP");
```

</div>

and then fill in the function and argument expressions. `SET_TYPEOF`
will also not be available to packages in the future. An alternative way
to construct the expression that will work in any R version is

<div class="example">

``` example-preformatted
SEXP expr = LCONS(R_NilValue, allocList(2));
```

</div>

R 4.4.1 added the constructor `Rf_allocLang`, so the expression can be
created as

<div class="example">

``` example-preformatted
SEXP env = Rf_allocLang(3);
```

</div>

------------------------------------------------------------------------

</div>

<div id="Creating-closures" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Querying-CHARSXP-encoding" rel="next">Querying <code
class="code">CHARSXP</code> encoding</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Creating-call-expressions" rel="prev">Creating call
expressions</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Moving-into-C-API-compliance" rel="up">Moving into C API
compliance</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.23.5 Creating closures <a href="#Creating-closures-1" class="copiable-link">¶</a>

Yet another common idiom is to create a new closure as

<div class="example">

``` example-preformatted
SEXP fun = Rf_allocSExp(CLOSXP);
SET_FORMALS(fun, formals);
SET_BODY(fun, body);
SET_CLOENV(fun, env);
```

</div>

R 4.5.0 adds the constructor `R_mkClosure`; this can be used as

<div class="example">

``` example-preformatted
SEXP fun = R_mkClosure(formals, body, env);
```

</div>

------------------------------------------------------------------------

</div>

<div id="Querying-CHARSXP-encoding" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Working-with-attributes" rel="next">Working with
attributes</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Creating-closures" rel="prev">Creating closures</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Moving-into-C-API-compliance" rel="up">Moving into C API
compliance</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.23.6 Querying `CHARSXP` encoding <a href="#Querying-CHARSXP-encoding-1" class="copiable-link">¶</a>

A number of packages query encoding bits set on `CHARSXP` objects via
macros `IS_ASCII` and `IS_UTF8`, some packages also via `IS_BYTES` and
`IS_LATIN1`. These macros are not part of the API and packages have been
copying their definition and directly accessing the bits in memory. The
structure of the object header is, however, internal to R and may have
to change in the future.

`IS_ASCII` can be replaced by `Rf_charIsASCII`, added in R 4.5.0. It can
also be replaced by code that checks individual characters (bytes).

Information provided by the other macros is available via function
`Rf_getCharCE`, which has been part of the API since R 2.7.0. Before
switching to `Rf_getCharCE`, packages are, however, advised to check
whether the encoding information is really needed and whether it is used
correctly.

Most code should be able to work with complete `CHARSXP`s and never look
at the individual bytes. When access to characters and bytes (of strings
other than `CE_BYTES`) is needed, one would use `Rf_translateChar` or
`Rf_translateCharUTF8`. These functions internally already check the
encoding and whether the string is ASCII and only translate when needed,
which should be rarely since R \>= 4.2.0 (UTF-8 is used as native
encoding on most systems running R).

Several packages use the encoding information to find out whether an
internal string representation visible via `CHAR` is UTF-8 or latin1. R
4.5.0 provides functions `Rf_charIsUTF8` and `Rf_charIsLatin1` for this
purpose, which are safer against future changes and handle also native
strings when running in the corresponding locale. Note that both will be
true for ASCII strings.

A pattern used in several packages is

<div class="example">

``` example-preformatted
char *asutf8(SEXP c)
{
  if (!IS_UTF8(s) && !IS_ASCII(s))  // not compliant
    return Rf_translateCharUTF8(s);
   else
    return CHAR(s);
}
```

</div>

to make this code compliant, simply call

<div class="example">

``` example-preformatted
char *asutf8(SEXP c)
{
  return Rf_translateCharUTF8(s); // compliant
}
```

</div>

as the encoding flags are already checked in `Rf_translateCharUTF8`.
Also note the non-compliant check does not handle native encoding.

------------------------------------------------------------------------

</div>

<div id="Working-with-attributes" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Working-with-variable-bindings" rel="next">Working with
variable bindings</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Querying-CHARSXP-encoding" rel="prev">Querying <code
class="code">CHARSXP</code> encoding</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Moving-into-C-API-compliance" rel="up">Moving into C API
compliance</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.23.7 Working with attributes <a href="#Working-with-attributes-1" class="copiable-link">¶</a>

The current implementation (R 4.5.0) represents attributes internally as
a linked list. It may be useful to change this at some point, so
external code should not rely on this representation. The low-level
functions `ATTRIB` and `SET_ATTRIB` reveal this representation and are
therefore not part of the API. Individual attributes can be accessed and
set with `Rf_getAttrib` and `Rf_setAttrib`. Attributes can be copied
from one object to another with `DUPLICATE_ATTRIB` and
`SHALLOW_DUPLICATE_ATTRIB`. The `CLEAR_ATTRIB` function added in R 4.5.0
can be used to remove all attributes. These functions ensure can that
certain consistency requirements are maintained, such as setting the
object bit according to whether a class attribute is present.

The function `R_getAttributes` returns the same result as the R function
`attributes`. <span id="index-R_005fgetAttributes"
class="index-entry-id"></span> <span id="index-R_005fgetAttributes-1"
class="index-entry-id"></span> `R_getAttribCount` returns the number of
attributes and `R_getAttribNames` returns the names of an object’s
attributes. `R_hasAttrib` can be used to query whether an attribute is
present. <span id="index-R_005fgetAttribCount"
class="index-entry-id"></span> <span id="index-R_005fgetAttribCount-1"
class="index-entry-id"></span> <span id="index-R_005fgetAttribNames"
class="index-entry-id"></span> <span id="index-R_005fgetAttribNames-1"
class="index-entry-id"></span> <span id="index-R_005fhasAttrib"
class="index-entry-id"></span> <span id="index-R_005fhasAttrib-1"
class="index-entry-id"></span> The functions `R_nrow` and `R_ncol`
return the number of rows or columns in a standard matrix or data frame.
They may be extended to handle non-standard cases by dispatching to
`dim`. <span id="index-R_005fnrow" class="index-entry-id"></span>
<span id="index-R_005fnrow-1" class="index-entry-id"></span>
<span id="index-R_005fncol" class="index-entry-id"></span>
<span id="index-R_005fncol-1" class="index-entry-id"></span>

The function `R_mapAttrib` can be used to iterate over the attributes of
an object:

<div class="example">

``` example-preformatted
SEXP R_mapAttrib(SEXP x, SEXP (*FUN)(SEXP, SEXP, void *), void *data);
```

</div>

<span id="index-R_005fmapAttrib" class="index-entry-id"></span>
<span id="index-R_005fmapAttrib-1" class="index-entry-id"></span>

The function `FUN` should return a C `NULL` if it wants the iteration to
continue. If `FUN` returns a non-`NULL` value, then the iteration stops
and that value is returned as the result of the `R_mapAttrib` call.
`R_mapAttrib` is highly experimental. It should only be used if
absolutely necessary as both the interface and the semantics may change
at short notice.

Some additional functions may be added for working with attributes.

------------------------------------------------------------------------

</div>

<div id="Working-with-variable-bindings"
class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Next:
</span><span class="nav-link"><a href="#Some-backports" rel="next">Some backports</a></span></span>,
<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Working-with-attributes" rel="prev">Working with
attributes</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Moving-into-C-API-compliance" rel="up">Moving into C API
compliance</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.23.8 Working with variable bindings <a href="#Working-with-variable-bindings-1" class="copiable-link">¶</a>

The internal functions `Rf_findVar` and `Rf_findVarInFrame` have been
used in a number of packages but are too low level to be part of the
API. For most uses the functions `R_getVar` and `R_getVarEx` added in R
4.5.0 will be sufficient. These are analogous to the R functions `get`
and `get0`.

In rare cases package R or C code may want to obtain more detailed
information on a binding, such as whether the binding is delayed or not.
An experimental C API has been added in R 4.6.0. An R level API may be
added as well.

The type of a binding for a symbol in an environment can be obtained
with

<div class="example">

<div class="group">

``` example-preformatted
R_BindingType_t R_GetBindingType(SEXP sym, SEXP env);
```

</div>

</div>

<span id="index-R_005fGetBindingType" class="index-entry-id"></span>
<span id="index-R_005fGetBindingType-1" class="index-entry-id"></span>

The returned value type is an `enum` with possible values
`R_BindingTypeUnbound`, `R_BindingTypeValue`, `R_BindingTypeMissing`,
`R_BindingTypeDelayed`, `R_BindingTypeForced`, and
`R_BindingTypeActive`. <span id="index-R_005fBindingTypeUnbound"
class="index-entry-id"></span>
<span id="index-R_005fBindingTypeUnbound-1"
class="index-entry-id"></span> <span id="index-R_005fBindingTypeValue"
class="index-entry-id"></span> <span id="index-R_005fBindingTypeValue-1"
class="index-entry-id"></span> <span id="index-R_005fBindingTypeMissing"
class="index-entry-id"></span>
<span id="index-R_005fBindingTypeMissing-1"
class="index-entry-id"></span> <span id="index-R_005fBindingTypeDelayed"
class="index-entry-id"></span>
<span id="index-R_005fBindingTypeDelayed-1"
class="index-entry-id"></span> <span id="index-R_005fBindingTypeForced"
class="index-entry-id"></span>
<span id="index-R_005fBindingTypeForced-1"
class="index-entry-id"></span> <span id="index-R_005fBindingTypeActive"
class="index-entry-id"></span>
<span id="index-R_005fBindingTypeActive-1"
class="index-entry-id"></span>

Features of forced or delayed bindings can be examined with

<div class="example">

<div class="group">

``` example-preformatted
SEXP R_ForcedBindingExpression(SEXP sym, SEXP env);
SEXP R_DelayedBindingExpression(SEXP sym, SEXP env);
SEXP R_DelayedBindingEnvironment(SEXP sym, SEXP env);
```

</div>

</div>

<span id="index-R_005fForcedBindingExpression"
class="index-entry-id"></span>
<span id="index-R_005fForcedBindingExpression-1"
class="index-entry-id"></span>
<span id="index-R_005fDelayedBindingExpression"
class="index-entry-id"></span>
<span id="index-R_005fDelayedBindingExpression-1"
class="index-entry-id"></span>
<span id="index-R_005fDelayedBindingEnvironment"
class="index-entry-id"></span>
<span id="index-R_005fDelayedBindingEnvironment-1"
class="index-entry-id"></span>

New forced, delayed, and missing bindings can be created with

<div class="example">

<div class="group">

``` example-preformatted
void R_MakeForcedBinding(SEXP sym, SEXP expr, SEXP value, SEXP env);
void R_MakeDelayedBinding(SEXP sym, SEXP expr, SEXP evalEnv, SEXP env);
void R_MakeMissingBinding(SEXP sym, SEXP env);
```

</div>

</div>

<span id="index-R_005fMakeForcedBinding" class="index-entry-id"></span>
<span id="index-R_005fMakeForcedBinding-1"
class="index-entry-id"></span> <span id="index-R_005fMakeDelayedBinding"
class="index-entry-id"></span>
<span id="index-R_005fMakeDelayedBinding-1"
class="index-entry-id"></span> <span id="index-R_005fMakeMissingBinding"
class="index-entry-id"></span>
<span id="index-R_005fMakeMissingBinding-1"
class="index-entry-id"></span>

A vector of the symbols for which an environment has bindings is
returned by

<div class="example">

<div class="group">

``` example-preformatted
SEXP R_envSymbols(SEXP env);
```

</div>

</div>

<span id="index-R_005fenvSymbols" class="index-entry-id"></span>
<span id="index-R_005fenvSymbols-1" class="index-entry-id"></span>

The environment containing a `...` binding can be found by walking
parent environments with

<div class="example">

<div class="group">

``` example-preformatted
SEXP R_findDotsEnv(SEXP env);
```

</div>

</div>

<span id="index-R_005ffindDotsEnv" class="index-entry-id"></span>
<span id="index-R_005ffindDotsEnv-1" class="index-entry-id"></span>

This returns the first environment in the chain starting from `env` that
contains a proper `...` binding, or `R_EmptyEnv` if none is found.

Whether a proper `...` binding exists in a given frame can be determined
with

<div class="example">

<div class="group">

``` example-preformatted
Rboolean R_DotsExist(SEXP env);
```

</div>

</div>

<span id="index-R_005fDotsExist" class="index-entry-id"></span>
<span id="index-R_005fDotsExist-1" class="index-entry-id"></span>

Length and names of a `...` binding are returned by

<div class="example">

<div class="group">

``` example-preformatted
int R_DotsLength(SEXP env);
SEXP R_DotsNames(SEXP env);
```

</div>

</div>

<span id="index-R_005fDotsLength" class="index-entry-id"></span>
<span id="index-R_005fDotsLength-1" class="index-entry-id"></span>
<span id="index-R_005fDotsNames" class="index-entry-id"></span>
<span id="index-R_005fDotsNames-1" class="index-entry-id"></span>

These correspond to the R functions `...length` and `...names`.

The type of an individual `...` element can be obtained with

<div class="example">

<div class="group">

``` example-preformatted
R_DotType_t R_GetDotType(int i, SEXP env);
```

</div>

</div>

<span id="index-R_005fGetDotType" class="index-entry-id"></span>
<span id="index-R_005fGetDotType-1" class="index-entry-id"></span>

The returned value is an `enum` with possible values `R_DotTypeValue`,
`R_DotTypeMissing`, `R_DotTypeDelayed`, and `R_DotTypeForced`.
<span id="index-R_005fDotTypeValue" class="index-entry-id"></span>
<span id="index-R_005fDotTypeValue-1" class="index-entry-id"></span>
<span id="index-R_005fDotTypeMissing" class="index-entry-id"></span>
<span id="index-R_005fDotTypeMissing-1" class="index-entry-id"></span>
<span id="index-R_005fDotTypeDelayed" class="index-entry-id"></span>
<span id="index-R_005fDotTypeDelayed-1" class="index-entry-id"></span>
<span id="index-R_005fDotTypeForced" class="index-entry-id"></span>
<span id="index-R_005fDotTypeForced-1" class="index-entry-id"></span>

Individual `...` elements can be examined using

<div class="example">

<div class="group">

``` example-preformatted
SEXP R_DotsElt(int i, SEXP env);
SEXP R_DotForcedExpression(int i, SEXP env);
SEXP R_DotDelayedExpression(int i, SEXP env);
SEXP R_DotDelayedEnvironment(int i, SEXP env);
```

</div>

</div>

<span id="index-R_005fDotsElt" class="index-entry-id"></span>
<span id="index-R_005fDotsElt-1" class="index-entry-id"></span>
<span id="index-R_005fDotDelayedExpression"
class="index-entry-id"></span>
<span id="index-R_005fDotDelayedExpression-1"
class="index-entry-id"></span>
<span id="index-R_005fDotDelayedEnvironment"
class="index-entry-id"></span>
<span id="index-R_005fDotDelayedEnvironment-1"
class="index-entry-id"></span>
<span id="index-R_005fDotForcedExpression"
class="index-entry-id"></span>
<span id="index-R_005fDotForcedExpression-1"
class="index-entry-id"></span>

`R_DotsElt` corresponds to the R function `...elt`.

Note that all these functions look up `...` only in the specified `env`
frame and do not search parent environments. The R functions
`...length`, `...names`, and `...elt` do walk parent environments (using
`R_findDotsEnv` internally). If you need inherited lookup from C code,
call `R_findDotsEnv` first and pass the result to the accessor
functions.

Some internal lookup functions return `R_UnboundValue` to indicate *not
found*. This should not be the case for any functions in the external
API. <span id="index-R_005fUnboundValue" class="index-entry-id"></span>
<span id="index-R_005fUnboundValue-1" class="index-entry-id"></span>

------------------------------------------------------------------------

</div>

<div id="Some-backports" class="subsection-level-extent">

<span class="nav-button"><span class="nav-label">Previous:
</span><span class="nav-link"><a href="#Working-with-variable-bindings" rel="prev">Working with
variable bindings</a></span></span>,
<span class="nav-button"><span class="nav-label">Up:
</span><span class="nav-link"><a href="#Moving-into-C-API-compliance" rel="up">Moving into C API
compliance</a></span></span><span class="nav-button">  
</span><span class="nav-button">\[<a href="#SEC_Contents" rel="contents"
title="Table of contents">Contents</a>\]</span><span class="nav-button">\[<a href="#Concept-index" rel="index" title="Index">Index</a>\]</span>

#### 6.23.9 Some backports <a href="#Some-backports-1" class="copiable-link">¶</a>

This section lists backports of recently added definitions that can be
used in packages that need to be compiled under older versions of R that
do not yet contain these entry points.

<div class="example">

``` example-preformatted
#if R_VERSION < R_Version(4, 4, 1)
#define allocLang Rf_allocLang

SEXP Rf_allocLang(int n)
{
    if (n > 0)
          return LCONS(R_NilValue, Rf_allocList(n - 1));
    else
          return R_NilValue;
}
#endif

#if R_VERSION < R_Version(4, 5, 0)
# define Rf_isDataFrame(x) Rf_isFrame(x)
# define R_ClosureFormals(x) FORMALS(x)
# define R_ClosureEnv(x) CLOENV(x)
# define R_ParentEnv(x) ENCLOS(x)

SEXP R_mkClosure(SEXP formals, SEXP body, SEXP env)
{
    SEXP fun = Rf_allocSExp(CLOSXP);
    SET_FORMALS(fun, formals);
    SET_BODY(fun, body);
    SET_CLOENV(fun, env);
    return fun;
}

void CLEAR_ATTRIB(SEXP x)
{
    SET_ATTRIB(x, R_NilValue);
    SET_OBJECT(x, 0);
    UNSET_S4_OBJECT(x);
}
#endif

#if R_VERSION < R_Version(4, 6, 0)
# define DATAPTR_RW(x) DATAPTR(x)
# define R_class(x) R_data_class(x, FALSE)
# define R_resizeVector(x, newlen) SETLENGTH(x, newlen)

SEXP R_allocResizableVector(SEXPTYPE type, R_xlen_t maxlen)
{
    SEXP ret = Rf_allocVector(type, maxlen);
    SET_TRUELENGTH(ret, maxlen);
    SET_GROWABLE_BIT(ret);
    return ret;
}

SEXP R_duplicateAsResizable(SEXP x)
{
    SEXP ret = Rf_duplicate(x);
    SET_TRUELENGTH(ret, Rf_xlength(x));
    SET_GROWABLE_BIT(ret);
    return ret;
}

SEXP R_mapAttrib(SEXP x, SEXP (*FUN)(SEXP, SEXP, void *), void *data)
{
    PROTECT_INDEX api;
    SEXP a = ATTRIB(x);
    SEXP val = NULL;

    PROTECT_WITH_INDEX(a, &api);
    while (a != R_NilValue) {
    SEXP tag = PROTECT(TAG(a));
    SEXP attr = PROTECT(CAR(a));
    val = FUN(tag, attr, data);
    UNPROTECT(2); /* tag, attr */
    if (val != NULL)
        break;
    REPROTECT(a = CDR(a), api);
    }
    UNPROTECT(1); /* a */
    return val;
}
#endif
```

</div>

------------------------------------------------------------------------

</div>

</div>

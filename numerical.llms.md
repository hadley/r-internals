# 20  Numerical methods

R exposes the C and Fortran code behind `optim()`, `integrate()`, and its linear algebra routines, so package code can run the same algorithms without going back through R. For pure scalar mathematics (distributions, special functions), see [Mathematical functions](math.llms.md).

## 20.1 Optimization

Follows [WRE §6.8, Optimization](https://cran.r-project.org/doc/manuals/R-exts.html#Optimization-1) closely.

All five minimizers take the objective as a C callback, and some take a gradient callback:

``` c
typedef double optimfn(int n, double *par, void *ex);
typedef void optimgr(int n, double *par, double *gr, void *ex);
```

`ex` is an opaque pointer passed straight through to your callback — use it to carry auxiliary data (including a `SEXP`, if you protect it elsewhere). If you don’t have an analytic gradient, you must finite-difference yourself; no helper is provided.

### 20.1.1 `nmmin()` (`vmmin()`, `cgmin()`, `lbfgsb()`, `samin()`)

Minimize a function using the code underlying optim().

``` c
void nmmin(int n, double *xin, double *x, double *Fmin, optimfn fn,
           int *fail, double abstol, double intol, void *ex,
           double alpha, double beta, double gamma, int trace,
           int *fncount, int maxit);
void vmmin(int n, double *x, double *Fmin,
           optimfn fn, optimgr gr, int maxit, int trace,
           int *mask, double abstol, double reltol, int nREPORT,
           void *ex, int *fncount, int *grcount, int *fail);
void cgmin(int n, double *xin, double *x, double *Fmin,
           optimfn fn, optimgr gr, int *fail, double abstol,
           double intol, void *ex, int type, int trace,
           int *fncount, int *grcount, int maxit);
void lbfgsb(int n, int lmm, double *x, double *lower,
            double *upper, int *nbd, double *Fmin, optimfn fn,
            optimgr gr, int *fail, void *ex, double factr,
            double pgtol, int *fncount, int *grcount,
            int maxit, char *msg, int trace, int nREPORT);
void samin(int n, double *x, double *Fmin, optimfn fn, int maxit,
           int tmax, double temp, int trace, void *ex);
```

**Status:** API · **Header:** `R_ext/Applic.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `optim()`

Respectively Nelder–Mead, BFGS, conjugate gradients, limited-memory BFGS with box constraints, and simulated annealing. Common arguments: `n` is the number of parameters, `x`/`xin` hold the starting parameters on entry and `x` the result on exit, `Fmin` receives the final value, `fail` is a nonzero-on-failure flag, and `fncount`/ `grcount` report evaluation counts. See `?optim` for the remaining arguments and `src/appl/lbfgsb.c` for the `nbd` bounds codes. No finite-differencing or Hessian approximation is provided. (`optif9`, also declared here, is experimental and intended only for the nlme package.)

**See also:** [`Rdqags()`](#Rdqags)

## 20.2 Integration

Follows [WRE §6.9, Integration](https://cran.r-project.org/doc/manuals/R-exts.html#Integration-1) closely.

The integrand is a *vectorized* callback — it receives `n` points in `x` and must overwrite them with the function values:

``` c
typedef void integr_fn(double *x, int n, void *ex);
```

In the current QUADPACK-based implementation `n` is always 15 or 21.

### 20.2.1 `Rdqags()` (`Rdqagi()`)

Numerically integrate a function over a finite or infinite interval.

``` c
void Rdqags(integr_fn f, void *ex, double *a, double *b,
            double *epsabs, double *epsrel,
            double *result, double *abserr, int *neval, int *ier,
            int *limit, int *lenw, int *last,
            int *iwork, double *work);
void Rdqagi(integr_fn f, void *ex, double *bound, int *inf,
            double *epsabs, double *epsrel,
            double *result, double *abserr, int *neval, int *ier,
            int *limit, int *lenw, int *last,
            int *iwork, double *work);
```

**Status:** API · **Header:** `R_ext/Applic.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `integrate()`

- `a`: `Rdqags`: lower and upper integration bounds (`a`, `b`).
- `bound`: `Rdqagi`: the finite bound, with `inf` selecting the range: 1 for `(bound, Inf)`, −1 for `(-Inf, bound)`, 2 for `(-Inf, Inf)`.
- `result`: outputs: value, absolute error estimate, evaluation count, error code, and number of subdivisions (`result`, `abserr`, `neval`, `ier`, `last`).
- `limit`: maximum number of subintervals, as `subdivisions` in `integrate()`.

Always allocate the work arrays as `iwork = R_alloc(limit, sizeof(int))` and `work = R_alloc(lenw, sizeof(double))` with `lenw = 4 * limit`. The comments in `src/appl/integrate.c` explain the `ier` failure codes.

**See also:** [`nmmin()`](#nmmin)

## 20.3 Linear algebra

Follows [WRE §6.11, Linear algebra](https://cran.r-project.org/doc/manuals/R-exts.html#Linear-algebra-1) closely.

For numerical linear algebra, call the BLAS/LAPACK routines that R itself is built on: declarations are in `R_ext/BLAS.h` and `R_ext/LAPACK.h` (the older `R_ext/Linpack.h` also exists). These are Fortran calling conventions — all arguments are pointers, and character arguments need a hidden length argument, which the `FCONE` macro (defined by these headers) appends portably. This set of routines is not formally API but changes rarely.

### 20.3.1 `dqrdc2()` (`dqrls()`, `dqrqty()`, `dqrqy()`, `dqrcf()`, `dqrrsd()`, `dqrxb()`)

LINPACK-derived QR decomposition and least-squares routines.

``` c
void F77_NAME(dqrdc2)(double *x, int *ldx, int *n, int *p,
                      double *tol, int *rank,
                      double *qraux, int *pivot, double *work);
void F77_NAME(dqrls)(double *x, int *n, int *p, double *y, int *ny,
                     double *tol, double *b, double *rsd,
                     double *qty, int *k,
                     int *jpvt, double *qraux, double *work);
```

**Status:** API · **Header:** `R_ext/Applic.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

These Fortran routines underlie `lm.fit()`, `lm.wfit()`, and `qr(LAPACK = FALSE)`; `dqrdc2` is R’s modification of LINPACK’s `dqrdc` with column pivoting and rank computation. Prefer BLAS/LAPACK for new code; see the sources in `src/appl/` for argument details. Regarded as API for now, but may be replaced by `bind(C)` interfaces in future.

## 20.4 Miscellaneous

### 20.4.1 `findInterval()` (`findInterval2()`, `interv()`)

Locate the interval containing a value within a sorted vector.

``` c
int findInterval(double *xt, int n, double x,
  Rboolean rightmost_closed,  Rboolean all_inside, int ilo,
  int *mflag);
int findInterval2(double *xt, int n, double x,
  Rboolean rightmost_closed,  Rboolean all_inside, Rboolean left_open,
  int ilo, int *mflag);
int F77_SUB(interv)(double *xt, int *n, double *x,
  int *rightmost_closed, int *all_inside, int *ilo, int *mflag);
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `findInterval()`

Also declared in `R_ext/Applic.h`. `findInterval2()` adds a `left_open` argument for left-open intervals. `interv` is the Fortran-callable predecessor, declared only under `R_RS_H`. The algorithm is fastest when `ilo` carries the previous result and successive `x` values are monotone.

### 20.4.2 `R_max_col()`

Find the column position of the maximum in each row of a matrix.

``` c
void R_max_col(double *matrix, int *nr, int *nc, int *maxes, int *ties_meth);
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `max.col()`

Also declared in `R_ext/Applic.h`.

### 20.4.3 `d1mach()` (`i1mach()`)

Report machine floating-point or integer constants.

``` c
double F77_SUB(d1mach)(int *i);
int F77_SUB(i1mach)(int *i);
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

Fortran-era routines kept for old numerical code. New code should use the C99 constants from `<float.h>`/`<limits.h>` or `R_ext/Arith.h` instead.

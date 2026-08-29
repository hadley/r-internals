# 19  Mathematical functions (Rmath)

`Rmath.h` gives C code access to the routines behind R’s mathematical and statistical functions: distribution functions, special functions, and numerical utilities, all with R’s edge-case semantics (missing values, `NaN`, infinities). The header has its own remapping scheme: define `R_NO_REMAP_RMATH` and most names need an `Rf_` prefix — see the header for which. We show the canonical (remapped) names below.

## 19.1 Distribution functions

Follows [WRE §6.7.1, Distribution functions](https://cran.r-project.org/doc/manuals/R-exts.html#Distribution-functions-1) closely.

Every distribution provides up to four entry points: `d` (density/mass), `p` (CDF), `q` (quantile), and `r` (random generation). The table gives the base name — prefix with `d`/`p`/`q`/`r` — and the distribution-specific arguments, which come between the `x`/`p` argument and the trailing `lower_tail`/`log_p` flags.

| Distribution            | Base name  | Parameters                  |
|-------------------------|------------|-----------------------------|
| beta                    | `beta`     | `a`, `b`                    |
| non-central beta        | `nbeta`    | `a`, `b`, `ncp`             |
| binomial                | `binom`    | `n`, `p`                    |
| Cauchy                  | `cauchy`   | `location`, `scale`         |
| chi-squared             | `chisq`    | `df`                        |
| non-central chi-squared | `nchisq`   | `df`, `ncp`                 |
| exponential             | `exp`      | `scale` (not `rate`!)       |
| F                       | `f`        | `n1`, `n2`                  |
| non-central F           | `nf`       | `n1`, `n2`, `ncp`           |
| gamma                   | `gamma`    | `shape`, `scale`            |
| geometric               | `geom`     | `p`                         |
| hypergeometric          | `hyper`    | `NR`, `NB`, `n`             |
| logistic                | `logis`    | `location`, `scale`         |
| lognormal               | `lnorm`    | `logmean`, `logsd`          |
| negative binomial       | `nbinom`   | `size`, `prob`              |
| normal                  | `norm`     | `mu`, `sigma`               |
| Poisson                 | `pois`     | `lambda`                    |
| Student’s t             | `t`        | `n`                         |
| non-central t           | `nt`       | `df`, `delta`               |
| Studentized range       | `tukey`    | `rr`, `cc`, `df` (p/q only) |
| uniform                 | `unif`     | `a`, `b`                    |
| Weibull                 | `weibull`  | `shape`, `scale`            |
| Wilcoxon rank sum       | `wilcox`   | `m`, `n`                    |
| Wilcoxon signed rank    | `signrank` | `n`                         |

The non-central distributions have no `r` functions, and `tukey` has only `p` and `q`. Note that the exponential and gamma distributions are parametrized by `scale`, not `rate`.

### 19.1.1 `dnorm()` (`pnorm()`, `qnorm()`, `rnorm()`)

Density, CDF, quantile, and random generation for a distribution.

``` c
double dnorm(double x, double mu, double sigma, int give_log);
double pnorm(double x, double mu, double sigma, int lower_tail, int give_log);
double qnorm(double p, double mu, double sigma, int lower_tail, int log_p);
double rnorm(double mu, double sigma);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `dnorm()`

- `give_log`: return the result on the log scale.
- `lower_tail`: use the lower (left) tail; set to 0 for the upper tail.
- `log_p`: `p` is supplied on the log scale.

Shown for the normal distribution; every distribution in the table above follows the same argument pattern with its own parameters. The cumulative hazard is `-pdist(t, ..., 0, 1)`. The `r*` functions draw from R’s RNG stream and must be bracketed by `GetRNGstate()`/`PutRNGstate()` (see [Random number generation](rng.llms.md)). With `R_NO_REMAP_RMATH` defined, the normal names become `Rf_dnorm4`, `Rf_pnorm5`, `Rf_qnorm5`.

**See also:** [`Rf_rmultinom()`](#Rf_rmultinom)

### 19.1.2 `dnbinom_mu()` (`pnbinom_mu()`, `qnbinom_mu()`, `rnbinom_mu()`)

Negative binomial distribution in the alternative (size, mu) parametrization.

``` c
double dnbinom_mu(double x, double size, double mu, int give_log);
double pnbinom_mu(double x, double size, double mu, int lower_tail, int give_log);
double qnbinom_mu(double p, double size, double mu, int lower_tail, int log_p);
double rnbinom_mu(double size, double mu);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `dnbinom()`

**See also:** [`dnorm()`](#dnorm)

### 19.1.3 `dbinom_raw()` (`dpois_raw()`)

Binomial and Poisson mass functions that vary continuously in x.

``` c
double dbinom_raw(double x, double n, double p, double q, int give_log);
double dpois_raw(double x, double lambda, int give_log);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

Unlike `dbinom()`/`dpois()`, these return nonzero values for non-integer `x`. `dbinom_raw()` takes both `p` and `q = 1 - p`, which is more accurate when one is close to 1.

**See also:** [`dnorm()`](#dnorm)

### 19.1.4 `Rf_rmultinom()` (`rmultinom()`)

Generate one multinomial random vector.

``` c
void Rf_rmultinom(int n, double* prob, int K, int* rN);
#define rmultinom Rf_rmultinom
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `rmultinom()`

- `n`: number of trials; the counts in `rN` sum to `n`.
- `prob`: length-`K` vector of probabilities, summing to 1.
- `rN`: output: length-`K` integer array filled with the counts.

Must be bracketed by `GetRNGstate()`/`PutRNGstate()`.

**See also:** [`dnorm()`](#dnorm), [`GetRNGstate()`](#GetRNGstate)

### 19.1.5 `wilcox_free()` (`signrank_free()`)

Free memory cached by the Wilcoxon distribution functions.

``` c
void wilcox_free(void);
void signrank_free(void);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** 4.2.0 · **R equivalent:** —

Call after any use of `dwilcox`/`pwilcox`/`qwilcox` (or the `signrank` equivalents). Declared in `Rmath.h` only from R 4.2.0; for earlier versions declare `extern void wilcox_free(void);` yourself. These names are never remapped.

**See also:** [`dnorm()`](#dnorm)

## 19.2 Mathematical functions

Follows [WRE §6.7.2, Mathematical functions](https://cran.r-project.org/doc/manuals/R-exts.html#Mathematical-functions-1) closely.

### 19.2.1 `gammafn()` (`lgammafn()`, `digamma()`, `trigamma()`, `tetragamma()`, `pentagamma()`, `psigamma()`)

Gamma function, its log, and derivatives of the digamma function.

``` c
double gammafn(double x);
double lgammafn(double x);
double digamma(double x);
double trigamma(double x);
double tetragamma(double x);
double pentagamma(double x);
double psigamma(double x, double deriv);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `gamma()`

`digamma(x)` is `psigamma(x, 0)`, `trigamma(x)` is `psigamma(x, 1)`, and so on. When you need several derivatives at once, the underlying workhorse `dpsifn()` computes a whole sequence in one call; see `src/nmath/polygamma.c` in the R sources.

**See also:** [`beta()`](#beta)

### 19.2.2 `beta()` (`lbeta()`)

Beta function and its natural logarithm.

``` c
double beta(double a, double b);
double lbeta(double a, double b);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `beta()`

**See also:** [`gammafn()`](#gammafn)

### 19.2.3 `choose()` (`lchoose()`)

Binomial coefficient and its log, generalized to real n.

``` c
double choose(double n, double k);
double lchoose(double n, double k);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `choose()`

`k` is rounded to the nearest integer (with a warning if needed).

**See also:** [`gammafn()`](#gammafn)

### 19.2.4 `bessel_i()` (`bessel_j()`, `bessel_k()`, `bessel_y()`)

Bessel functions I, J, K, and Y of fractional order.

``` c
double bessel_i(double x, double nu, double expo);
double bessel_j(double x, double nu);
double bessel_k(double x, double nu, double expo);
double bessel_y(double x, double nu);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `besselI()`

- `nu`: order of the Bessel function.
- `expo`: for `bessel_i`/`bessel_k` only: 1 for unscaled, 2 to return `exp(-x) * I(x, nu)` or `exp(x) * K(x, nu)` (avoids overflow).

### 19.2.5 `expm1()` (`log1p()`)

Compute exp(x) - 1 and log(1 + x) accurately for small x.

``` c
double expm1(double x);
double log1p(double x);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

C99 functions that R requires; `Rmath.h` remaps `log1p()` to R’s own implementation on platforms where the system version is inaccurate.

**See also:** [`log1pmx()`](#log1pmx)

### 19.2.6 `dpsifn()`

Compute derivatives of the log-gamma (psi) function.

``` c
void dpsifn(double x, int n, int kode, int m, double *ans, int *nz, int *ierr);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

- `n`: the derivative order (0 = digamma, 1 = trigamma, …).
- `kode`: 1 for psi^(n)(x), 2 for exp(-x) \* psi^(n)(x).
- `m`: number of sequence values to compute.
- `ans`: output array of length at least m.
- `nz`: output; number of underflowed entries.
- `ierr`: output; error flag, 0 on success.

Low-level workhorse behind `digamma()`/`trigamma()`; most code should call `digamma()` etc. directly.

**See also:** [`gammafn()`](#gammafn)

## 19.3 Numerical utilities

Follows [WRE §6.7.3, Numerical utilities](https://cran.r-project.org/doc/manuals/R-exts.html#Numerical-Utilities-1) closely.

Some of these (`log1p`, `expm1`, `cospi`, `sinpi`, `tanpi`) may be provided by the platform’s `math.h` instead of `Rmath.h`; under C++, `math.h` is not included by `Rmath.h`, so declare them yourself or define `__STDC_WANT_IEC_60559_FUNCS_EXT__` before the first inclusion.

### 19.3.1 `R_pow()` (`R_pow_di()`, `pow1p()`)

Exponentiation with R’s edge-case semantics.

``` c
double R_pow(double x, double y);
double R_pow_di(double x, int i);
double pow1p(double x, double y);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

Unlike C’s `pow()`, these give the same result as R’s `^` when `x` or `y` is 0, missing, infinite, or `NaN`. `pow1p(x, y)` computes `(1 + x)^y` accurately for small `|x|`.

### 19.3.2 `log1pmx()` (`log1pexp()`, `log1mexp()`, `lgamma1p()`)

Accurate log computations in numerically delicate regions.

``` c
double log1pmx(double x);
double log1pexp(double x);
double log1mexp(double x);
double lgamma1p(double x);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

Respectively `log(1 + x) - x` (accurate for small `|x|`), `log(1 + exp(x))` (accurate for large `x`), `log(1 - exp(-x))`, and `log(gamma(x + 1))` (accurate for `0 < x < 0.5`). Prefer these over composing the naive expressions.

**See also:** [`logspace_add()`](#logspace_add)

### 19.3.3 `cospi()` (`sinpi()`, `Rtanpi()`, `tanpi()`)

Trigonometric functions of pi \* x, accurate at (half-)integer x.

``` c
double cospi(double x);
double sinpi(double x);
double Rtanpi(double x);
double tanpi(double x);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `cospi()`

Prefer `Rtanpi()` over `tanpi()`: `Rtanpi()` is always R’s own implementation (exactly ±1 at quarter integers, `NaN` at half integers), while `tanpi()` may be the platform’s, with platform-dependent behaviour at half and quarter integers.

### 19.3.4 `logspace_add()` (`logspace_sub()`, `logspace_sum()`)

Add, subtract, or sum values given on the log scale.

``` c
double logspace_add(double logx, double logy);
double logspace_sub(double logx, double logy);
double logspace_sum(const double* logx, int n);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

Compute `log(exp(logx) + exp(logy))` etc. without overflow or unnecessary loss of accuracy — the building blocks for working in log-space.

**See also:** [`log1pmx()`](#log1pmx)

### 19.3.5 `fmax2()` (`fmin2()`, `imax2()`, `imin2()`)

Maximum and minimum of two doubles or ints.

``` c
double fmax2(double x, double y);
double fmin2(double x, double y);
int imax2(int x, int y);
int imin2(int x, int y);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

Unlike C99’s `fmax()`/`fmin()`, these return `NaN` when either argument is `NaN`.

### 19.3.6 `sign()` (`fsign()`)

Signum function and transfer of sign.

``` c
double sign(double x);
double fsign(double x, double y);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `sign()`

`sign()` returns 1, 0, −1, or `NaN` for `NaN`. `fsign(x, y)` is `|x| * sign(y)`.

### 19.3.7 `fround()` (`fprec()`, `ftrunc()`)

Rounding used by R’s round() and signif().

``` c
double fround(double x, double digits);
double fprec(double x, double digits);
double ftrunc(double x);
```

**Status:** API · **Header:** `Rmath.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

`fround()` rounds to `digits` decimal places (as `round()`); `fprec()` rounds to `digits` significant digits (as `signif()`); `ftrunc()` truncates toward zero.

## 19.4 Mathematical constants

Follows [WRE §6.7.4, Mathematical constants](https://cran.r-project.org/doc/manuals/R-exts.html#Mathematical-constants-1) closely.

| Name         | Value    | Name             | Value     |
|--------------|----------|------------------|-----------|
| `M_E`        | e        | `M_SQRT2`        | √2        |
| `M_LOG2E`    | log2(e)  | `M_SQRT1_2`      | 1/√2      |
| `M_LOG10E`   | log10(e) | `M_SQRT_3`       | √3        |
| `M_LN2`      | ln 2     | `M_SQRT_32`      | √32       |
| `M_LN10`     | ln 10    | `M_LOG10_2`      | log10(2)  |
| `M_PI`       | π        | `M_2PI`          | 2π        |
| `M_PI_2`     | π/2      | `M_SQRT_PI`      | √π        |
| `M_PI_4`     | π/4      | `M_1_SQRT_2PI`   | 1/√(2π)   |
| `M_1_PI`     | 1/π      | `M_SQRT_2dPI`    | √(2/π)    |
| `M_2_PI`     | 2/π      | `M_LN_SQRT_PI`   | ln √π     |
| `M_2_SQRTPI` | 2/√π     | `M_LN_SQRT_2PI`  | ln √(2π)  |
|              |          | `M_LN_SQRT_PId2` | ln √(π/2) |

## 19.5 Standalone Rmath

Follows [WRE §6.20, Using these functions in your own C code](https://cran.r-project.org/doc/manuals/R-exts.html#Using-these-functions-in-your-own-C-code) closely.

Everything in this chapter is also available outside R: the same code builds as a standalone library, `libRmath`, for use in programs that don’t link to R at all (define `MATHLIB_STANDALONE` when using it). The library isn’t built by default; see [The standalone Rmath library](https://cran.r-project.org/doc/manuals/R-admin.html#The-standalone-Rmath-library) in R Installation and Administration.

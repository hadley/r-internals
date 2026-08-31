# 18  Random number generation

R’s RNG is private to R: from C you draw from R’s stream, you don’t create your own. The stream state lives in the `.Random.seed` variable in the global environment, so every use from C must be bracketed by `GetRNGstate()` (read the state in, creating it if needed) and `PutRNGstate()` (write it back). Skip the bracket and your draws won’t advance R’s stream — repeated calls return the same values, and `set.seed()` at the R level won’t make your code reproducible.

There is no C API to choose the generator or set the seed; if you need that, evaluate calls to `RNGkind()`/`set.seed()` (see [Evaluation](evaluation.llms.md)). For distributions beyond uniform, normal, and exponential, use the `r*` functions from `Rmath.h` (see [Mathematical functions](math.llms.md)) — they draw from the same stream and need the same bracketing.

### 18.0.1 `GetRNGstate()`, `PutRNGstate()`

throws

**Header:** `R_ext/Random.h`

Read in (or create) `.Random.seed` before generating variates, and write it back after.

``` c
void GetRNGstate(void);
void PutRNGstate(void);
```

Every use of R’s RNG from C must be bracketed by these calls: `GetRNGstate()` reads (or lazily creates) `.Random.seed`, and `PutRNGstate()` writes the updated state back so R-level code sees the stream advance. They can allocate when the seed doesn’t yet exist. These names are never remapped.

``` c
GetRNGstate();
double u = unif_rand();
PutRNGstate();
```

**See also:** [`unif_rand()`](#unif_rand)

### 18.0.2 `unif_rand()`, `norm_rand()`, `exp_rand()`

**Header:** `R_ext/Random.h`

Draw one uniform, standard normal, or unit exponential variate.

``` c
double unif_rand(void);
double norm_rand(void);
double exp_rand(void);
```

**Returns:** One variate: uniform on (0, 1) for `unif_rand()`, standard normal for `norm_rand()`, unit exponential for `exp_rand()`.

Must be called between `GetRNGstate()` and `PutRNGstate()`. The generator kind and seed are chosen at the R level (`RNGkind()`, `set.seed()`); there is no C API to select them. For other distributions, use the `r*` functions from `Rmath.h` (see [Mathematical functions](math.llms.md)) — they need the same bracketing. These names are never remapped.

**See also:** [`GetRNGstate()`](#GetRNGstate), [`R_unif_index()`](#R_unif_index)

### 18.0.3 `R_unif_index()`

**Header:** `R_ext/Random.h`

Draw a uniform index in `[0, n)` for random sampling.

``` c
double R_unif_index(double n);
```

- `n`: upper bound (exclusive) on the returned index.

**Returns:** A uniform draw in `[0, n)`; truncate to an integer type to get an index.

Returns a `double` in `[0, n)`; truncate to `int` or `R_xlen_t` to get an index. Uses the sampling algorithm selected by R’s `sample.kind` option, so results match R-level `sample.int()`. Must be called between `GetRNGstate()` and `PutRNGstate()`.

**See also:** [`unif_rand()`](#unif_rand)

### 18.0.4 `R_sample_kind()`

**Header:** `R_ext/Random.h`

Get the current discrete-sampling algorithm.

``` c
Sampletype R_sample_kind(void);
```

**Returns:** The current sampling algorithm, `ROUNDING` or `REJECTION`.

Returns `ROUNDING` or `REJECTION`, reflecting the `sample.kind` option; only relevant to code implementing its own discrete sampling.

**See also:** [`R_unif_index()`](#R_unif_index)

# 22  R version

### 22.0.1 `Rversion.h`

Used test current version of R

### 22.0.2 `R_Version()` (`R_VERSION()`)

Test the compile-time version of R against a required version.

``` c
#define R_VERSION
#define R_Version(major, minor, patch) \
  (((major) * 65536) + ((minor) * 256) + (patch))
```

**Status:** API · **Header:** `Rversion.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `R.version`

`R_VERSION` is the packed version number of the R being compiled against; `R_Version()` packs a `major.minor.patch` triple into the same format for comparison.

``` c
#include <Rversion.h>

#if defined(R_VERSION) && R_VERSION < R_Version(3, 2, 0)
SEXP Rf_installChar(SEXP x) {
  return Rf_install(CHAR(x));
}
#endif
```

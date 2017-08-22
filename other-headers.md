## Other header files

### `Rversion.h`

Used test current version of R

```c
#include <Rversion.h>

#if defined(R_VERSION) && R_VERSION < R_Version(3, 2, 0)
SEXP Rf_installChar(SEXP x) {
  return Rf_install(CHAR(x));
}
#endif
```

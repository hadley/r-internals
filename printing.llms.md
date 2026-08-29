# 16  Printing and messaging

Never call `printf()` or `fputs(..., stdout)` from package code: the output bypasses R’s console, so it is invisible in GUIs, ignores `sink()` redirection, and is lost on cluster nodes. Use `Rprintf()` (and friends) for output, `R_ShowMessage()` for `message()`-style notifications, and `Rf_PrintValue()` to inspect an arbitrary `SEXP` while debugging.

### 16.0.1 `R_ShowMessage()`

Display a message to the user.

``` c
void R_ShowMessage(const char *s);
```

**Status:** API · **Header:** `R_ext/Error.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `message()`

### 16.0.2 `Rprintf()` (`REprintf()`, `Rvprintf()`, `REvprintf()`)

Print to R’s output or error stream.

``` c
void Rprintf(const char *, ...);
void REprintf(const char *, ...);
void Rvprintf(const char *, R_VA_LIST);
void REvprintf(const char *, R_VA_LIST);
```

**Status:** API · **Header:** `R_ext/Print.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `cat()`

Unlike `printf()`, output goes to R’s console: it respects `sink()` redirection and appears in GUIs and on cluster nodes. Write complete lines (ending in `\n`) before returning to R. The `v` variants take a `va_list`; in C++ code they require C++11 or `R_USE_C99_IN_CXX`.

### 16.0.3 `Rf_PrintValue()`

Print an object like print() would.

``` c
void Rf_PrintValue(SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** `print()`

### 16.0.4 `IndexWidth()`

Compute the character width needed to print a vector index.

``` c
#define IndexWidth    Rf_IndexWidth
```

**Status:** API · **Header:** `R_ext/Utils.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

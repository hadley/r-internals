# 16  Printing and messaging

Never call `printf()` or `fputs(..., stdout)` from package code: the output bypasses R’s console, so it is invisible in GUIs, ignores `sink()` redirection, and is lost on cluster nodes. Use `Rprintf()` (and friends) for output, `R_ShowMessage()` for `message()`-style notifications, and `Rf_PrintValue()` to inspect an arbitrary `SEXP` while debugging.

### 16.0.1 `R_ShowMessage()`

**Header:** `R_ext/Error.h`\
**R equivalent:** `message()`

Display a message to the user.

``` c
void R_ShowMessage(const char *s);
```

### 16.0.2 `Rprintf()`, `REprintf()`, `Rvprintf()`, `REvprintf()`

**Header:** `R_ext/Print.h`\
**R equivalent:** `cat()`

Print to R’s output or error stream.

``` c
void Rprintf(const char *, ...);
void REprintf(const char *, ...);
void Rvprintf(const char *, R_VA_LIST);
void REvprintf(const char *, R_VA_LIST);
```

Unlike `printf()`, output goes to R’s console: it respects `sink()` redirection and appears in GUIs and on cluster nodes. Write complete lines (ending in `\n`) before returning to R. The `v` variants take a `va_list`; in C++ code they require C++11 or `R_USE_C99_IN_CXX`.

### 16.0.3 `Rf_PrintValue()`

throws

**Header:** `Rinternals.h`\
**R equivalent:** `print()`

Print an object like print() would.

``` c
void Rf_PrintValue(SEXP);
```

### 16.0.4 `IndexWidth()`

**Header:** `R_ext/Utils.h`

Compute the character width needed to print a vector index.

``` c
#define IndexWidth    Rf_IndexWidth
```

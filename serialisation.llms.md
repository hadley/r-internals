# 17  Serialisation

R’s serialisation format converts an R object to a byte stream (and back) that can be written to a file, a connection, or a database. From C you can drive the same machinery `serialize()`/`unserialize()` use at the R level, either over a `FILE *` or over a custom byte source/sink you provide.

## 17.1 XDR encoding

XDR is the default binary serialisation format: big-endian and platform-independent, so streams are portable across architectures. These helpers encode and decode individual values when you implement a custom stream.

### 17.1.1 `R_XDR_DOUBLE_SIZE()`, `R_XDR_INTEGER_SIZE()`

**Header:** `Rinternals.h`

Specify the byte sizes of doubles and integers in XDR serialisation format.

``` c
#define R_XDR_DOUBLE_SIZE 8
#define R_XDR_INTEGER_SIZE 4
```

### 17.1.2 `R_XDREncodeDouble()`, `R_XDRDecodeDouble()`, `R_XDREncodeInteger()`, `R_XDRDecodeInteger()`

**Header:** `Rinternals.h`

Encode and decode doubles and integers in XDR format.

``` c
void R_XDREncodeDouble(double d, void *buf);
double R_XDRDecodeDouble(void *buf);
void R_XDREncodeInteger(int i, void *buf);
int R_XDRDecodeInteger(void *buf);
```

**Returns:** `R_XDRDecodeDouble()` and `R_XDRDecodeInteger()` return the value decoded from `buf`.

## 17.2 Persistence streams

A persistence stream pairs a byte source/sink with optional persistence hooks. The hook function (`phook`, with its data `pdata`) is called for objects that can’t be serialised by value — external pointers and weak references — letting you substitute a placeholder on output and reconstruct the object on input; pass `NULL` to refuse such objects with an error. The `version` argument selects the serialisation format version (2, or 3 which supports ALTREP; version 3 output requires R \>= 3.6.0 to read).

Note that WRE describes this framework as **highly experimental** for package use: it may change or be dropped in a future R release. Don’t depend on the fields of the stream structs directly — initialise them with the functions below.

``` c
typedef void *R_pstream_data_t;

typedef enum {
  R_pstream_any_format,
  R_pstream_ascii_format,
  R_pstream_binary_format,
  R_pstream_xdr_format,
  R_pstream_asciihex_format
} R_pstream_format_t;

typedef struct R_outpstream_st *R_outpstream_t;
struct R_outpstream_st {
  R_pstream_data_t data;
  R_pstream_format_t type;
  int version;
  void (*OutChar)(R_outpstream_t, int);
  void (*OutBytes)(R_outpstream_t, void *, int);
  SEXP (*OutPersistHookFunc)(SEXP, SEXP);
  SEXP OutPersistHookData;
};

typedef struct R_inpstream_st *R_inpstream_t;
struct R_inpstream_st {
  R_pstream_data_t data;
  R_pstream_format_t type;
  int (*InChar)(R_inpstream_t);
  void (*InBytes)(R_inpstream_t, void *, int);
  SEXP (*InPersistHookFunc)(SEXP, SEXP);
  SEXP InPersistHookData;
};
```

The connection interface is not available to packages. To allow limited use of connection pointers, defining `NEED_CONNECTION_PSTREAMS` before including `Rinternals.h` defines the opaque pointer type:

``` c
#ifdef NEED_CONNECTION_PSTREAMS
#ifndef HAVE_RCONNECTION_TYPEDEF
typedef struct Rconn  *Rconnection;
#define HAVE_RCONNECTION_TYPEDEF
#endif
#endif
```

### 17.2.1 `R_InitInPStream()`, `R_InitOutPStream()`

experimental

**Header:** `Rinternals.h`

Initialise a custom input or output persistence stream.

``` c
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

### 17.2.2 `R_InitFileInPStream()`, `R_InitFileOutPStream()`

experimental

**Header:** `Rinternals.h`

Initialise a persistence stream that reads from or writes to a file.

``` c
void R_InitFileInPStream(R_inpstream_t stream, FILE *fp,
  R_pstream_format_t type,
  SEXP (*phook)(SEXP, SEXP), SEXP pdata);
void R_InitFileOutPStream(R_outpstream_t stream, FILE *fp,
  R_pstream_format_t type, int version,
  SEXP (*phook)(SEXP, SEXP), SEXP pdata);
```

## 17.3 Serialising objects

With a stream initialised, these two functions do the actual work:

### 17.3.1 `R_Serialize()`, `R_Unserialize()`

experimental needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `serialize()`

Serialise an R object to an output stream, or unserialise it from an input stream.

``` c
void R_Serialize(SEXP s, R_outpstream_t ops);
SEXP R_Unserialize(R_inpstream_t ips);
```

**Returns:** `R_Unserialize()` returns the unserialised object; freshly allocated and unprotected.

The `SEXP` returned by `R_Unserialize()` is freshly allocated and must be protected from garbage collection.

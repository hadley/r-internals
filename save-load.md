# Serialisation

```cpp
/* Save/Load Interface */
#define R_XDR_DOUBLE_SIZE 8
#define R_XDR_INTEGER_SIZE 4

void R_XDREncodeDouble(double d, void *buf);
double R_XDRDecodeDouble(void *buf);
void R_XDREncodeInteger(int i, void *buf);
int R_XDRDecodeInteger(void *buf);

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

void R_InitFileInPStream(R_inpstream_t stream, FILE *fp,
  R_pstream_format_t type,
  SEXP (*phook)(SEXP, SEXP), SEXP pdata);
void R_InitFileOutPStream(R_outpstream_t stream, FILE *fp,
  R_pstream_format_t type, int version,
  SEXP (*phook)(SEXP, SEXP), SEXP pdata);

#ifdef NEED_CONNECTION_PSTREAMS
/* The connection interface is not available to packages.  To
allow limited use of connection pointers this defines the opaque
pointer type. */
#ifndef HAVE_RCONNECTION_TYPEDEF
typedef struct Rconn  *Rconnection;
#define HAVE_RCONNECTION_TYPEDEF
#endif
void R_InitConnOutPStream(R_outpstream_t stream, Rconnection con,
  R_pstream_format_t type, int version,
  SEXP (*phook)(SEXP, SEXP), SEXP pdata);
void R_InitConnInPStream(R_inpstream_t stream,  Rconnection con,
  R_pstream_format_t type,
  SEXP (*phook)(SEXP, SEXP), SEXP pdata);
#endif

void R_Serialize(SEXP s, R_outpstream_t ops);
SEXP R_Unserialize(R_inpstream_t ips);

void R_RestoreHashCount(SEXP rho);
```

# Object oriented programming

`ANYSXP` is used internal in S4 class definitions to flag that any SEXP is ok.

```cpp
Rboolean (Rf_isObject)(SEXP s);
```

## S3

```cpp
Rboolean Rf_inherits(SEXP, const char *);
SEXP Rf_S3Class(SEXP);
int Rf_isBasicClass(const char *);
SEXP Rf_classgets(SEXP, SEXP);
```

## S4 (`S4SXP`)

```cpp
Rboolean Rf_isS4(SEXP);
SEXP Rf_asS4(SEXP, Rboolean, int);
SEXP Rf_allocS4Object(void);
```

```cpp
/* S3-S4 class (inheritance), attrib.c */
SEXP R_S4_extends(SEXP klass, SEXP useTable);

/* class definition, new objects (objects.c) */
SEXP R_do_MAKE_CLASS(const char *what);
SEXP R_getClassDef  (const char *what);
SEXP R_getClassDef_R(SEXP what);
Rboolean R_has_methods_attached(void);
Rboolean R_isVirtualClass(SEXP class_def, SEXP env);
Rboolean R_extends  (SEXP class1, SEXP class2, SEXP env);
SEXP R_do_new_object(SEXP class_def);
/* supporting  a C-level version of  is(., .) : */
int R_check_class_and_super(SEXP x, const char **valid, SEXP rho);
int R_check_class_etc      (SEXP x, const char **valid);
```

### Internals

```cpp
int (IS_S4_OBJECT)(SEXP x);
void (SET_S4_OBJECT)(SEXP x);
void (UNSET_S4_OBJECT)(SEXP x);
```

### Slots

```cpp
SEXP R_do_slot(SEXP obj, SEXP name);
SEXP R_do_slot_assign(SEXP obj, SEXP name, SEXP value);
int R_has_slot(SEXP obj, SEXP name);
```

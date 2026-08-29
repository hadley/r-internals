# 13  Object oriented programming

At the C level, R’s object systems are thin: S3 is just a `class` attribute plus conventions for dispatch, and S4 adds a bit on the object header (making it an `S4SXP`) plus slot attributes. (`ANYSXP` is used internally in S4 class definitions to flag that any SEXP is acceptable.)

## 13.1 Object testing

### 13.1.1 `Rf_isObject()`

Test whether an object is flagged as object-oriented.

``` c
Rboolean (Rf_isObject)(SEXP s);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `is.object()`

Returns non-zero when the `OBJECT` bit is set on `s`, i.e. the object carries a class attribute.

## 13.2 S3

### 13.2.1 `Rf_inherits()`

Test whether an object inherits from a given class.

``` c
Rboolean Rf_inherits(SEXP, const char *);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `inherits()`

Matches the given name against the object’s class attribute.

### 13.2.2 `Rf_S3Class()`

Return the S3 class of an object.

``` c
SEXP Rf_S3Class(SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** never · **Since:** — · **R equivalent:** `class()`

Returns a character vector of class names.

### 13.2.3 `Rf_isBasicClass()`

Test whether a class name is one of the basic classes.

``` c
int Rf_isBasicClass(const char *);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

Basic classes are the built-in pseudo-classes (e.g. `"numeric"`, `"matrix"`) known to the methods package.

### 13.2.4 `Rf_classgets()`

Set the class attribute of an object.

``` c
SEXP Rf_classgets(SEXP, SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** not needed · **Errors:** can throw · **Since:** — · **R equivalent:** `class<-()`

## 13.3 S4 (`S4SXP`)

### 13.3.1 `Rf_isS4()`

Test whether an object is an S4 object.

``` c
Rboolean Rf_isS4(SEXP);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** `isS4()`

Returns non-zero for objects of type `S4SXP`.

### 13.3.2 `Rf_asS4()`

Set or unset the S4 flag on an object.

``` c
SEXP Rf_asS4(SEXP, Rboolean, int);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

### 13.3.3 `Rf_allocS4Object()`

Allocate a new S4 object.

``` c
SEXP Rf_allocS4Object(void);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** —

Allocates a bare S4 object (type `S4SXP`) with the S4 flag set.

### 13.3.4 `R_S4_extends()` (`R_extends()`)

Query S4 class inheritance (extends) relationships.

``` c
SEXP R_S4_extends(SEXP klass, SEXP useTable);
Rboolean R_extends(SEXP class1, SEXP class2, SEXP env);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `extends()`

`R_S4_extends()` returns the extends information for class `klass`; `R_extends()` tests whether `class1` extends `class2` in environment `env`.

### 13.3.5 `R_do_MAKE_CLASS()`

Create a new S4 class definition.

``` c
SEXP R_do_MAKE_CLASS(const char *what);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `setClass()`

### 13.3.6 `R_getClassDef()` (`R_getClassDef_R()`)

Retrieve an S4 class definition by name.

``` c
SEXP R_getClassDef(const char *what);
SEXP R_getClassDef_R(SEXP what);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `getClassDef()`

`R_getClassDef_R()` takes the class name as a `SEXP` rather than a C string.

### 13.3.7 `R_has_methods_attached()`

Test whether methods are currently attached.

``` c
Rboolean R_has_methods_attached(void);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** never · **Since:** — · **R equivalent:** —

### 13.3.8 `R_isVirtualClass()`

Test whether an S4 class definition describes a virtual class.

``` c
Rboolean R_isVirtualClass(SEXP class_def, SEXP env);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** —

### 13.3.9 `R_do_new_object()`

Create a new object from an S4 class definition.

``` c
SEXP R_do_new_object(SEXP class_def);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `new()`

### 13.3.10 `R_check_class_and_super()` (`R_check_class_etc()`)

Check an object against a set of valid classes, a C-level `is()`.

``` c
int R_check_class_and_super(SEXP x, const char **valid, SEXP rho);
int R_check_class_etc(SEXP x, const char **valid);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** n/a · **Errors:** can throw · **Since:** — · **R equivalent:** `is()`

Checks whether `x` matches or extends one of the classes in the `NULL`-terminated array `valid`. `R_check_class_etc()` omits the environment argument.

### 13.3.11 Slots

### 13.3.12 `R_do_slot()` (`R_do_slot_assign()`, `R_has_slot()`)

Get, assign, or test for the presence of an S4 slot.

``` c
SEXP R_do_slot(SEXP obj, SEXP name);
SEXP R_do_slot_assign(SEXP obj, SEXP name, SEXP value);
int R_has_slot(SEXP obj, SEXP name);
```

**Status:** experimental · **Header:** `Rinternals.h` · **Protect:** result · **Errors:** can throw · **Since:** — · **R equivalent:** `slot()`

`R_do_slot()` extracts a slot, `R_do_slot_assign()` assigns it, and `R_has_slot()` tests for its presence.

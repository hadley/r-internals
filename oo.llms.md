# 13  Object oriented programming

At the C level, R’s object systems are thin: S3 is just a `class` attribute plus conventions for dispatch, and S4 adds a bit on the object header (making it an `S4SXP`) plus slot attributes. (`ANYSXP` is used internally in S4 class definitions to flag that any SEXP is acceptable.)

## 13.1 Object testing

### 13.1.1 `Rf_isObject()`

**Header:** `Rinternals.h`\
**R equivalent:** `is.object()`

Test whether an object is flagged as object-oriented.

``` c
Rboolean (Rf_isObject)(SEXP s);
```

**Returns:** `TRUE` if `s` has the object bit set (i.e. carries a class attribute), otherwise `FALSE`.

Returns non-zero when the `OBJECT` bit is set on `s`, i.e. the object carries a class attribute.

## 13.2 S3

### 13.2.1 `Rf_inherits()`

**Header:** `Rinternals.h`\
**R equivalent:** `inherits()`

Test whether an object inherits from a given class.

``` c
Rboolean Rf_inherits(SEXP, const char *);
```

**Returns:** `TRUE` if the object inherits from the named class, otherwise `FALSE`.

Matches the given name against the object’s class attribute.

### 13.2.2 `Rf_S3Class()`

**Header:** `Rinternals.h`\
**R equivalent:** `class()`

Return the S3 class of an object.

``` c
SEXP Rf_S3Class(SEXP);
```

**Returns:** A character vector `SEXP` of the object’s S3 class names.

Returns a character vector of class names.

### 13.2.3 `Rf_isBasicClass()`

throws

**Header:** `Rinternals.h`

Test whether a class name is one of the basic classes.

``` c
int Rf_isBasicClass(const char *);
```

**Returns:** Non-zero if the name is one of the basic classes, zero otherwise.

Basic classes are the built-in pseudo-classes (e.g. `"numeric"`, `"matrix"`) known to the methods package.

### 13.2.4 `Rf_classgets()`

throws

**Header:** `Rinternals.h`\
**R equivalent:** `class<-()`

Set the class attribute of an object.

``` c
SEXP Rf_classgets(SEXP, SEXP);
```

**Returns:** The object with its class attribute set to the second argument.

## 13.3 S4 (`S4SXP`)

### 13.3.1 `Rf_isS4()`

**Header:** `Rinternals.h`\
**R equivalent:** `isS4()`

Test whether an object is an S4 object.

``` c
Rboolean Rf_isS4(SEXP);
```

**Returns:** `TRUE` if the object is an S4 object, otherwise `FALSE`.

Returns non-zero for objects of type `S4SXP`.

### 13.3.2 `Rf_asS4()`

experimental needs protect throws

**Header:** `Rinternals.h`

Set or unset the S4 flag on an object.

``` c
SEXP Rf_asS4(SEXP, Rboolean, int);
```

**Returns:** The (possibly duplicated) object with its S4 flag set or unset.

### 13.3.3 `Rf_allocS4Object()`

experimental needs protect throws

**Header:** `Rinternals.h`

Allocate a new S4 object.

``` c
SEXP Rf_allocS4Object(void);
```

**Returns:** A newly allocated bare S4 object (`S4SXP`).

Allocates a bare S4 object (type `S4SXP`) with the S4 flag set.

### 13.3.4 `R_S4_extends()`, `R_extends()`

needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `extends()`

Query S4 class inheritance (extends) relationships.

``` c
SEXP R_S4_extends(SEXP klass, SEXP useTable);
Rboolean R_extends(SEXP class1, SEXP class2, SEXP env);
```

**Returns:** `R_S4_extends()` returns a `SEXP` describing the superclasses of `klass`; `R_extends()` returns `TRUE` if `class1` extends `class2`, otherwise `FALSE`.

`R_S4_extends()` returns the extends information for class `klass`; `R_extends()` tests whether `class1` extends `class2` in environment `env`.

### 13.3.5 `R_do_MAKE_CLASS()`

experimental needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `setClass()`

Create a new S4 class definition.

``` c
SEXP R_do_MAKE_CLASS(const char *what);
```

**Returns:** The newly created S4 class definition `SEXP`.

### 13.3.6 `R_getClassDef()`, `R_getClassDef_R()`

experimental needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `getClassDef()`

Retrieve an S4 class definition by name.

``` c
SEXP R_getClassDef(const char *what);
SEXP R_getClassDef_R(SEXP what);
```

**Returns:** The S4 class definition `SEXP` for the named class.

`R_getClassDef_R()` takes the class name as a `SEXP` rather than a C string.

### 13.3.7 `R_has_methods_attached()`

**Header:** `Rinternals.h`

Test whether methods are currently attached.

``` c
Rboolean R_has_methods_attached(void);
```

**Returns:** `TRUE` if methods are currently attached, otherwise `FALSE`.

### 13.3.8 `R_isVirtualClass()`

throws

**Header:** `Rinternals.h`

Test whether an S4 class definition describes a virtual class.

``` c
Rboolean R_isVirtualClass(SEXP class_def, SEXP env);
```

**Returns:** `TRUE` if the class definition describes a virtual class, otherwise `FALSE`.

### 13.3.9 `R_do_new_object()`

experimental needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `new()`

Create a new object from an S4 class definition.

``` c
SEXP R_do_new_object(SEXP class_def);
```

**Returns:** A new instance `SEXP` of the S4 class.

### 13.3.10 `R_check_class_and_super()`, `R_check_class_etc()`

throws

**Header:** `Rinternals.h`\
**R equivalent:** `is()`

Check an object against a set of valid classes, a C-level `is()`.

``` c
int R_check_class_and_super(SEXP x, const char **valid, SEXP rho);
int R_check_class_etc(SEXP x, const char **valid);
```

**Returns:** The 0-based index of the matching class in `valid`, or `-1` if `x` matches none of them.

Checks whether `x` matches or extends one of the classes in the `NULL`-terminated array `valid`. `R_check_class_etc()` omits the environment argument.

### 13.3.11 Slots

### 13.3.12 `R_do_slot()`, `R_do_slot_assign()`, `R_has_slot()`

experimental needs protect throws

**Header:** `Rinternals.h`\
**R equivalent:** `slot()`

Get, assign, or test for the presence of an S4 slot.

``` c
SEXP R_do_slot(SEXP obj, SEXP name);
SEXP R_do_slot_assign(SEXP obj, SEXP name, SEXP value);
int R_has_slot(SEXP obj, SEXP name);
```

**Returns:** `R_do_slot()` returns the slot’s value; `R_do_slot_assign()` returns the object with the slot assigned; `R_has_slot()` returns non-zero if the slot exists.

`R_do_slot()` extracts a slot, `R_do_slot_assign()` assigns it, and `R_has_slot()` tests for its presence.

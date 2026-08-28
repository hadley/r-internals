# Plan: a comprehensive, concise guide to R's C API

## Goals and scope

Turn this repo into a Quarto site that documents R's C API for package authors:
comprehensive (every entry point a package author can legitimately use),
concise (reference-style entries, not tutorials), and current (reflecting the
post-R-4.5 API-compliance era: `R_NO_REMAP`, `Rf_`/`R_` prefixes, and the
API/experimental/embedding/non-API classification).

**Audience:** experienced C programmers who are new to R's API specifically.
This is not a book for beginners — we assume fluency in C (pointers, memory
management, calling conventions) and focus on what's *different* about R's
API: SEXPs, protection, longjmp errors, the API-compliance taxonomy. Keep
everything very brief for now; depth can come later.

Three sources feed the content:

1. The existing hand-written chapters (`vectors.md`, `strings.md`, etc.):
   good organisation-by-SEXPTYPE and good editorial voice ("use this, avoid
   that"), but incomplete, stale in places, and inconsistent in format.
2. `r-api.md` (WRE chapter 6, regenerated on demand by `extract-r-api.R`):
   comprehensive on the "utility" API (memory, errors, RNG, math, Fortran,
   condition handling, API compliance) but poorly organised for reference use
   and nearly silent on the SEXP-level API. Treat it as **raw material to mine
   and rewrite**, not text to copy: R's manuals are not freely relicensable,
   and the prose style is wrong for this site anyway.
3. The old Advanced R C-interface chapter (<http://adv-r.had.co.nz/C-interface.html>):
   the model for *foundational* chapters — task-oriented, opinionated, with
   small runnable examples — but outdated (uses `inline`/`pryr`, predates
   mandatory `Rf_` remapping and the API-compliance effort). Its foundational
   concepts (what a SEXP is, protection, modifying in place, input validation,
   finding C source) are exactly what `r-api.md` lacks and this site needs.

Out of scope (state this explicitly in the intro): the `.C`/`.Fortran`
interface as a recommended approach, Fortran interop, embedding R / writing
front-ends, the graphics engine API, and non-API entry points except where
the "compliance" appendix maps them to replacements.

## Chapter organisation

Quarto **book** project (a book is still a website, but gives chapter
numbering, cross-references, and a single logical reading order). Each chapter
is one `.qmd`. Existing files map onto this with modest reshuffling.

### Part I — Foundations (new material; adv-r chapter is the model)

1. `index.qmd` — **Introduction.** What this site is, relationship to WRE /
   R Internals / adv-r; audience and prerequisites (experienced C
   programmers; C basics not explained); conventions used
   throughout (always `R_NO_REMAP` + `Rf_`/`R_` prefixes, C not C++, `.Call`
   only); the API status taxonomy (API / experimental / embedding /
   non-API) and what "don't use non-API" means in practice
   (`R CMD check` NOTEs, CRAN policy); which headers to include and why
   `<Rinternals.h>` is fine. *Sources: README.md, r-api.md preamble, adv-r intro.*
2. `calling-c.qmd` — **Calling C from R.** `.Call` and `.External`, routine
   registration (`R_registerRoutines`, `R_CallMethodDef`, `useDynLib`), the
   contract your C function signs up to: main thread only, may longjmp on
   error, arguments are borrowed references, inputs must not be modified.
   Minimal package skeleton plus how to iterate quickly (cpp11/Rcpp mention,
   `callme`-style workflow) — replaces adv-r's `inline` approach.
   *Mostly new; mine WRE ch. 5.*
3. `sexps.qmd` — **SEXPs.** The uniform object model; complete SEXPTYPE
   table (with which chapter covers each); `TYPEOF()`; the header/data
   layout at a conceptual level; attributes exist on (almost) every object;
   copy-on-modify, `NAMED`/reference counting, and why you must not mutate
   inputs (`MAYBE_SHARED`, `Rf_duplicate`/`Rf_shallow_duplicate`); type
   testing philosophy (prefer `TYPEOF(x) == ...`). *Sources: README.md,
   parts of vectors.md and gc-rc.md, adv-r "C data structures".*
4. `protection.qmd` — **Protection and the garbage collector.** When GC can
   run; `PROTECT`/`UNPROTECT`, `PROTECT_WITH_INDEX`/`REPROTECT`; what needs
   protecting and what doesn't (arguments, symbols, values reachable from
   protected objects); `R_PreserveObject`/`R_ReleaseObject` for
   cross-call lifetimes; common protection bugs and how to find them
   (`gctorture`, rchk). *Source: gc-rc.md, reorganised.*
5. `memory.qmd` — **Memory allocation.** Transient `R_alloc`/`vmaxget`/
   `vmaxset`; `R_Calloc`/`R_Realloc`/`R_Free` and cleanup-on-error
   obligations; alignment; when to prefer a `RAWSXP` instead.
   *Source: r-api.md §6.1.*

### Part II — Objects (one chapter per SEXPTYPE cluster; the existing organisation)

6. `vectors.qmd` — atomic vectors and lists: types, length
   (`R_xlen_t`), creation, data access (`REAL()` etc., `*_ELT`,
   `*_RO` const pointers — add these), missing values (fold in the
   NA/NaN/Inf material from r-api.md §6.4), coercion, tests, scalars.
   Move arrays/matrices/factors/data-frames material to `attributes.qmd`.
   *Source: vectors.md.*
7. `strings.qmd` — character strings, the string pool, encodings (`cetype_t`,
   `Rf_charIsUTF8` etc. from §6.23.6), creating and reading strings,
   translation, plus re-encoding via `Riconv` (r-api.md §6.12).
   *Source: strings.md.*
8. `attributes.qmd` — **promoted to its own chapter** (currently buried in
   pairlists.md): `Rf_getAttrib`/`Rf_setAttrib`, the API-compliant helpers
   from §6.23.7, names/dim/dimnames/class, and the attribute-defined
   structures: matrices/arrays, factors, data frames (from vectors.md).
9. `environments.qmd` — get/set/remove bindings (including the modern
   `R_getVar`/`R_existsVarInFrame` family and binding functions from
   §6.23.3/6.23.8), creation (`R_NewEnv`), locking, active bindings,
   namespaces. *Source: environments.md + r-api.md §6.23.*
10. `symbols.qmd` — `Rf_install` & friends, interning, predefined symbols,
    `R_MissingArg`/`R_UnboundValue`. *Source: symbols.md.*
11. `pairlists.qmd` — pairlists, calls, and `...`; CAR/CDR;
    constructing calls (`Rf_lang1..6`, `R_mkCall*` replacements from
    §6.23.4); walking `...`. *Source: pairlists.md minus attributes.*
12. `functions.qmd` — closures (creation via `R_mkClosure`, §6.23.5),
    builtins/specials, promises, srcrefs. *Source: functions.md.*
13. `external-pointers.qmd` — external pointers, finalizers, plus **weak
    references** (moved from misc.md). *Source: external-pointers.md.*
14. `oo.qmd` — `Rf_isObject`, S3 (`Rf_inherits`, class get/set, dispatch
    helpers), S4 (slots, class checks), brief S7-at-C-level note if
    applicable. *Source: oo.md.*

### Part III — The engine (behaviour, not data)

15. `evaluation.qmd` — `Rf_eval`, `R_tryEval`/`R_tryEvalSilent`,
    `R_forceAndCall`, `Rf_applyClosure`; building and evaluating calls
    end-to-end (worked example). *Source: error-eval.md (split).*
16. `errors.qmd` — signalling (`Rf_error`, `Rf_warning`, `*call` variants);
    the longjmp problem and C++/resource safety; condition handling and
    cleanup (r-api.md §6.13: `R_UnwindProtect`, `R_withCallingErrorHandler`,
    `R_MakeUnwindCont`); interrupts (§6.14, `R_CheckUserInterrupt`);
    C stack checking (§6.15). *Sources: error-eval.md + r-api.md.*
17. `printing.qmd` — `Rprintf`/`REprintf`, `Rf_PrintValue`, `R_ShowMessage`,
    console flushing. Short chapter. *Sources: error-eval.md + r-api.md §6.5.*
18. `serialisation.qmd` — public (un)serialisation, custom pstreams
    (r-api.md §6.16), XDR helpers. *Source: save-load.md.*

### Part IV — Utilities

19. `rng.qmd` — `GetRNGstate`/`PutRNGstate`, `unif_rand` family,
    `R_unif_index`; relationship to `.Random.seed`. *Source: r-api.md §6.3.*
20. `math.qmd` — Rmath: distribution functions (d/p/q/r table),
    mathematical functions (bessel, gamma, beta...), numerical utilities
    (`R_pow`, `fmax2`, `imin2`, `expm1`-style helpers), constants
    (`M_PI` etc.), standalone Rmath usage (§6.20 folded in as a section).
    *Source: r-api.md §6.7, §6.20.*
21. `numerical.qmd` — optimization (§6.8), integration (§6.9), linear
    algebra / BLAS / LAPACK headers and `FCONE` (§6.11), `findInterval`,
    `R_max_col`. *Source: r-api.md + misc.md tail.*
22. `utilities.qmd` — sorting and ordering (`R_qsort`, `R_orderVector`),
    matching (`Rf_match`, `Rf_pmatch`), `R_compute_identical`,
    `Rf_duplicated`/`Rf_any_duplicated`, options (`Rf_GetOption1`),
    numeric parsing (`R_atof`/`R_strtod`), paths and tempfiles
    (`R_ExpandFileName`, `R_tmpnam2`), platform info (§6.17).
    *Sources: misc.md + r-api.md §6.10, §6.17.*
23. `r-version.qmd` — **R version**: `Rversion.h` and the `R_Version`
    version-check macros. *Source: other-headers.md.*

### Appendices

- `compliance.qmd` — **Migrating to API compliance.** The non-API →
  API replacement tables and recipes (r-api.md §6.23), backports, and how
  to check a package (`R CMD check`, `tools::checkFF`-era tooling).
  Likely a high-traffic page; keep it table-heavy.
- `function-index.qmd` — **Function index**: alphabetical table of every
  documented entry point → chapter + anchor + status. *Generated* (see
  below), never hand-edited.

Dropped/parked: internals-only material currently in the .md files
(`SET_ENVFLAGS`, `HASHTAB`, `BCODESXP` internals, `SETLENGTH`, etc.) moves
into clearly-marked "Internals — non-API, do not use in packages" call-out
boxes within the relevant chapter, or is cut. Every retained entry gets an
explicit status so we never again blur API and non-API.

## Function metadata: `functions/*.yaml` + generated entries

Function documentation is **data-driven**. The single source of truth for
per-function metadata is the `functions/` directory — one YAML file per
chapter (`functions/<chapter>.yaml`), one record per
documented entry point (or family of closely-related entry points, e.g.
`Rf_lang1`–`Rf_lang6`). An R function in `tools/` reads the YAML and returns
the canonical markdown entries; chapters call it from knitr `asis` chunks,
so entries are rendered inline at render time and never spliced into or
hand-edited in the `.qmd` source.

### YAML schema

```yaml
- name: Rf_allocVector        # anchor = C identifier; also the heading
  family: []                  # extra functions sharing this entry, if any
  summary: Create a new vector of the given type and length.
  signature: |
    SEXP Rf_allocVector(SEXPTYPE type, R_xlen_t n);
  status: api                 # api | experimental | embedding | non-api
  replacement: ~              # for non-api: name of preferred alternative
  header: Rinternals.h
  protect: result             # result | not needed | n/a (+ note, e.g. "can allocate")
  errors: can-throw           # can-throw | never
  since: ~                    # R version when it matters for portability
  r_equivalent: vector()      # closest R-level function, or ~
  args:                       # only when non-obvious from the signature
    type: any vector `SEXPTYPE` (`LGLSXP`, ..., `VECSXP`, `RAWSXP`, `EXPRSXP`).
    n: number of elements.
  notes: |                    # ≤1 short paragraph; edge cases, gotchas
    Atomic vector contents are uninitialised; `VECSXP`/`EXPRSXP` elements
    are `R_NilValue` and `STRSXP` elements are `""`.
  example: |                  # optional, ≤ ~8 lines
    SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  see_also: [Rf_allocVector3]
  chapter: vectors            # which .qmd the entry is placed in
  section: Create             # which ## section within the chapter
```

### Generated entry format

`tools/render-entries.R` provides `render_entries(chapter, section)`, which
turns each matching record into markdown of this shape. Chapters pull in a
section's entries with an asis chunk:

````markdown
## Create

```{r}
#| results: asis
#| echo: false
render_entries("vectors", "Create")
```
````

Each entry renders as:

````markdown
### `Rf_allocVector()` {#Rf_allocVector}

Create a new vector of the given type and length.

```c
SEXP Rf_allocVector(SEXPTYPE type, R_xlen_t n);
```

**Status:** API · **Header:** `Rinternals.h` · **Protect:** result ·
**Errors:** can throw · **Since:** — · **R equivalent:** `vector()`

- `type`: any vector `SEXPTYPE` ...
- `n`: number of elements.

Atomic vector contents are uninitialised; ...

```c
SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
```

**See also:** [`Rf_allocVector3()`](#Rf_allocVector3) for custom allocators.
````

Rules:

- **Heading**: `### \`name()\` {#name}` — explicit stable anchor equal to the
  C identifier, so links survive re-organisation and LLMs can cite
  `page.html#Rf_allocVector`.
- **Metadata line** — fixed keys in fixed order: Status, Header, Protect,
  Errors, Since, R equivalent. `Protect` says whether the return value needs
  `PROTECT`; `Errors` says whether it can longjmp.
- **Notes**: at most a short paragraph. This is where the editorial voice
  lives — aimed at C programmers, so explain R-specific surprises, not C
  basics.
- **Example**: optional, ≤ ~8 lines, only when usage isn't obvious.

Chapters are prose-plus-entries: each chapter opens with brief conceptual
prose (kept short — the audience knows C), then `##` task-oriented sections
("Create", "Get and set values", "Test") whose entries come from a single
asis chunk call.

Because the metadata is machine-readable YAML, the index, llms.txt, and
coverage audit all read `functions/*.yaml` directly instead of parsing
markdown.

## Quarto conversion

Layout:

```
_quarto.yml
index.qmd, calling-c.qmd, ...           # chapters as above
functions/<chapter>.yaml                # machine-readable metadata for every
                                        #   documented entry point (source of truth),
                                        #   one file per chapter
diagrams/                               # existing pngs (+ regenerate as needed)
tools/
  extract-r-api.R                       # moved; regenerates sources/r-api.md
  render-entries.R                      # render_entries(chapter, section):
                                        #   functions/*.yaml -> markdown, called
                                        #   from asis chunks at render time
  build-index.R                         # reads functions/*.yaml -> function-index.qmd
                                        #   data, functions.json, coverage report
  llms.R                                # post-render: llms.txt, llms-full.txt,
                                        #   per-page .md copies
sources/                                # r-api.md and other mined raw material
                                        #   (gitignored or kept, but NOT rendered)
.github/workflows/publish.yml           # render + publish to gh-pages
```

`_quarto.yml` essentials:

- `project: type: book` (HTML only; no PDF for now), title "R's C API".
- Chapters in Parts I–IV plus appendices, as listed above.
- `format: html`: a stock theme, `code-copy: true`, `toc: true`, full-text
  search on; C syntax highlighting (```` ```c ````, not ```` ```cpp ````).
- `website`/`book` repo config: `repo-url`, `repo-actions: [edit, issue]` so
  every page has an "edit this page" link.
- knitr execution is used only for the `results: asis` chunks that inject
  generated entries from `functions/*.yaml` (via `tools/render-entries.R`,
  sourced from a setup chunk or `_quarto.yml` config). No other code
  execution; C examples are never run. If we later want *verified*
  examples, add a separate CI job that extracts entry examples and compiles
  them against R headers.
- `aliases:` on each page for old filenames (e.g. `gc-rc.html` →
  `protection.html`) once anything external links to the site.

Mechanical steps:

1. `quarto create project book`, move/rename `.md` → `.qmd` per the chapter
   map (git `mv` to preserve history), fix code fences to `c`.
2. Delete stale artifacts: `*.html` snapshots, `.DS_Store`, `.Rhistory`,
   `.Rproj.user`; update `.gitignore` (`/_site`, `/.quarto`).
3. Move `extract-r-api.R` + `r-api.md` under `tools/`/`sources/`; exclude
   from rendering. Keep the script so we can re-diff against future WRE
   releases.
4. GitHub Action: `quarto-dev/quarto-actions` render + publish to
   `gh-pages`; run `tools/build-index.R` pre-render and `tools/llms.R`
   post-render.
5. Rewrite README.md to point at the rendered site and describe the repo
   layout + contribution workflow (including the entry format spec).

## Comprehensiveness and correctness process

- **Coverage audit** (`tools/build-index.R`, run in CI): parse the function
  names declared in the installed headers (`R.home("include")`) and the
  API-status metadata R now publishes (WRE's `@apifun` annotations /
  `tools:::funAPI()` in recent R), diff against `functions/*.yaml`, and
  emit a report: API functions we don't document (gaps), entries we
  document that no longer exist (rot), and status mismatches. CI fails on
  rot, warns on gaps.
- **Migration triage of existing text**: as each chapter is converted,
  verify every claim against current R (e.g. vectors.md's `Rboolean` claim
  for LGLSXP — it's `int`; `Rf_findVarInFrame3` is no longer the
  recommended interface; `UNPROTECT_PTR` is deprecated). Every existing
  entry gets a status assigned or is cut.
- **Sequencing**:
  1. Scaffold the Quarto book + CI with the existing chapters lightly
     renamed (site live early). ✔
  2. Build the metadata pipeline: define `functions/*.yaml` schema, seed it
     with a handful of entries, and write `tools/render-entries.R` so
     chapters can inject entries via asis chunks. Validate end-to-end on
     one chapter before scaling up. ✔
  3. **Assemble a clean `functions/*.yaml`.** Mechanically extract every
     hand-written function definition from the existing chapters into YAML
     records (summary, signature, status, protect/errors, chapter/section),
     replacing each with an asis chunk call. This is a *move*, not a
     rewrite: keep the existing text as-is where it doesn't fit the schema
     (park it in `notes`), don't fix stale claims yet, and don't touch the
     surrounding prose. Goal: one machine-readable inventory of everything
     we currently document.
  4. Clean up `functions/*.yaml` in place: verify signatures against current
     headers, assign/correct statuses, mine r-api.md §6.23 for modern
     replacements, fix stale claims, tighten summaries and notes to the
     brief reference style. Prose in chapters still untouched.
  5. Write Part I foundations (mostly new, brief prose) and revise chapter
     prose around the generated entries.
  6. Write Parts III–IV by reorganising r-api.md content into YAML records.
  7. Turn on the coverage audit; fill gaps until the API-status diff is
     clean.
  8. Add LLM outputs + function index last (they fall out of
     `functions/*.yaml`).

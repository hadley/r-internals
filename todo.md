# Todo: a comprehensive, concise guide to R's C API

Derived from [plan.md](plan.md). Sequencing follows the plan: scaffold first,
then Part I, Part II, Parts III–IV, coverage audit, then index/LLM outputs.

## Phase 1 — Quarto scaffold and repo cleanup ✔ (commit `0ddcd4e`)

- [x] Set up `_quarto.yml`: `project: type: book` (HTML only), title "R's C API", stock theme, `code-copy`, `toc`, search, `repo-url` + `repo-actions: [edit, issue]`, no code execution
- [x] Move/rename existing `.md` chapters to `.qmd` per the chapter map (`git mv`, history preserved)
- [x] Fix code fences to `c` in all converted chapters
- [x] Delete stale artifacts: `*.html` snapshots, `.Rhistory`
- [x] Update `.gitignore`: `/_site`, `/.quarto`, `.DS_Store`
- [x] Move `extract-r-api.R` to `tools/` and `r-api.md` to `sources/` (not rendered)
- [x] Add `aliases:` on renamed pages (`gc-rc.html` → `protection.html`, etc.)
- [x] GitHub Action (`.github/workflows/publish.yml`): render + publish to gh-pages
- [x] Rewrite README.md for the new layout + contribution workflow
- [x] Site renders cleanly (`quarto render`, no warnings); placeholder stubs for all planned chapters
- [ ] Push and verify the site goes live on gh-pages (needs a push to `main`)

## Phase 2 — Part I: Foundations (mostly new prose; adv-r chapter is the model)

- [ ] `index.qmd` — Introduction
  - [ ] What this site is; relationship to WRE / R Internals / adv-r
  - [ ] Audience and prerequisites
  - [ ] Conventions: always `R_NO_REMAP` + `Rf_`/`R_` prefixes, C not C++, `.Call` only
  - [ ] API status taxonomy (API / experimental / embedding / non-API) and what "don't use non-API" means in practice (`R CMD check` NOTEs, CRAN policy)
  - [ ] Which headers to include; why `<Rinternals.h>` is fine
  - [ ] Explicitly state out-of-scope: `.C`/`.Fortran` as a recommended approach, embedding R, graphics engine API, non-API entry points (except compliance appendix)
- [ ] `calling-c.qmd` — Calling C from R
  - [ ] `.Call` and `.External`
  - [ ] Routine registration: `R_registerRoutines`, `R_CallMethodDef`, `useDynLib`
  - [ ] The C function contract: main thread only, may longjmp on error, borrowed references, inputs must not be modified
  - [ ] Minimal package skeleton + fast iteration workflow (cpp11/Rcpp mention, `callme`-style; replaces adv-r's `inline` approach)
  - [ ] Mine WRE ch. 5
- [ ] `sexps.qmd` — SEXPs
  - [ ] The uniform object model; complete SEXPTYPE table (with which chapter covers each)
  - [ ] `TYPEOF()`; header/data layout at a conceptual level
  - [ ] Attributes exist on (almost) every object
  - [ ] Copy-on-modify, `NAMED`/reference counting, why you must not mutate inputs (`MAYBE_SHARED`, `Rf_duplicate`/`Rf_shallow_duplicate`)
  - [ ] Type testing philosophy (prefer `TYPEOF(x) == ...`)
- [ ] `protection.qmd` — Protection and the garbage collector
  - [ ] When GC can run
  - [ ] `PROTECT`/`UNPROTECT`, `PROTECT_WITH_INDEX`/`REPROTECT`
  - [ ] What needs protecting and what doesn't (arguments, symbols, values reachable from protected objects)
  - [ ] `R_PreserveObject`/`R_ReleaseObject` for cross-call lifetimes
  - [ ] Common protection bugs and how to find them (`gctorture`, rchk)
- [ ] `memory.qmd` — Memory allocation
  - [ ] Transient `R_alloc`/`vmaxget`/`vmaxset`
  - [ ] `R_Calloc`/`R_Realloc`/`R_Free` and cleanup-on-error obligations
  - [ ] Alignment; when to prefer a `RAWSXP` instead

## Phase 3 — Part II: Objects (convert to standard entry format; mine r-api.md §6.23 for modern replacements)

- [ ] `vectors.qmd` — atomic vectors + `VECSXP` lists
  - [ ] Types, length (`R_xlen_t`), creation, data access (`REAL()` etc., `*_ELT`, add `*_RO` const pointers)
  - [ ] Missing values (fold in NA/NaN/Inf material from r-api.md §6.4)
  - [ ] Coercion, tests, scalars
  - [ ] Move arrays/matrices/factors/data-frames material to `attributes.qmd`
  - [ ] Fix stale claims (e.g. `Rboolean` for LGLSXP — it's `int`)
- [ ] `strings.qmd` — `CHARSXP`s, string pool, encodings (`cetype_t`, `Rf_charIsUTF8` etc. from §6.23.6), creating/reading strings, translation, re-encoding via `Riconv` (§6.12)
- [ ] `attributes.qmd` — promote to its own chapter (currently buried in pairlists.md)
  - [ ] `Rf_getAttrib`/`Rf_setAttrib`, API-compliant helpers from §6.23.7
  - [ ] names/dim/dimnames/class
  - [ ] Attribute-defined structures: matrices/arrays, factors, data frames (from vectors.md)
- [ ] `environments.qmd` — get/set/remove bindings (modern `R_getVar`/`R_existsVarInFrame` family, binding functions from §6.23.3/6.23.8), creation (`R_NewEnv`), locking, active bindings, namespaces
  - [ ] Fix stale claims (`Rf_findVarInFrame3` no longer recommended)
- [ ] `symbols.qmd` — `Rf_install` & friends, interning, predefined symbols, `R_MissingArg`/`R_UnboundValue`
- [ ] `pairlists.qmd` — `LISTSXP`/`LANGSXP`/`DOTSXP`/`NILSXP`; CAR/CDR; constructing calls (`Rf_lang1..6`, `R_mkCall*` replacements from §6.23.4); walking `...`; remove attributes material
- [ ] `functions.qmd` — closures (creation via `R_mkClosure`, §6.23.5), builtins/specials, promises, srcrefs
- [ ] `external-pointers.qmd` — external pointers, finalizers, weak references (moved from misc.md)
- [ ] `oo.qmd` — `Rf_isObject`, S3 (`Rf_inherits`, class get/set, dispatch helpers), S4 (slots, class checks), brief S7-at-C-level note if applicable

## Phase 4 — Part III: The engine (reorganise r-api.md content into entries)

- [ ] `evaluation.qmd` — `Rf_eval`, `R_tryEval`/`R_tryEvalSilent`, `R_forceAndCall`, `Rf_applyClosure`; building and evaluating calls end-to-end (worked example). Split from error-eval.md
- [ ] `errors.qmd` — signalling (`Rf_error`, `Rf_warning`, `*call` variants); longjmp problem and C++/resource safety; condition handling and cleanup (§6.13: `R_UnwindProtect`, `R_withCallingErrorHandler`, `R_MakeUnwindCont`); interrupts (§6.14, `R_CheckUserInterrupt`); C stack checking (§6.15)
- [ ] `printing.qmd` — `Rprintf`/`REprintf`, `Rf_PrintValue`, `R_ShowMessage`, console flushing (short chapter)
- [ ] `serialisation.qmd` — public (un)serialisation, custom pstreams (§6.16), XDR helpers

## Phase 5 — Part IV: Utilities

- [ ] `rng.qmd` — `GetRNGstate`/`PutRNGstate`, `unif_rand` family, `R_unif_index`; relationship to `.Random.seed`
- [ ] `math.qmd` — Rmath: distribution functions (d/p/q/r table), mathematical functions (bessel, gamma, beta...), numerical utilities (`R_pow`, `fmax2`, `imin2`, `expm1`-style helpers), constants (`M_PI` etc.), standalone Rmath (§6.20 folded in)
- [ ] `numerical.qmd` — optimization (§6.8), integration (§6.9), linear algebra / BLAS / LAPACK headers and `FCONE` (§6.11), `findInterval`, `R_max_col`
- [ ] `utilities.qmd` — sorting/ordering (`R_qsort`, `R_orderVector`), matching (`Rf_match`, `Rf_pmatch`), `R_compute_identical`, `Rf_duplicated`/`Rf_any_duplicated`, options (`Rf_GetOption1`), numeric parsing (`R_atof`/`R_strtod`), paths/tempfiles (`R_ExpandFileName`, `R_tmpnam2`), platform & version info (§6.17, `Rversion.h`)

## Phase 6 — Appendices

- [ ] `A-compliance.qmd` — Migrating to API compliance: non-API → API replacement tables and recipes (§6.23), backports, how to check a package (`R CMD check`, `tools::checkFF`-era tooling). Table-heavy
- [ ] `B-fortran.qmd` — Fortran interop: `F77_CALL`/`F77_SUB`, character strings/`FC_LEN_T`/`FCONE`, LOGICAL, printing and RNG from Fortran (§6.2.1, §6.3.1, §6.5.1, §6.6)
- [ ] `C-headers.qmd` — Header-file map: what each installed header provides, what `R.h` pulls in, inlining (§6.18) and visibility (§6.19) notes
- [ ] Handle internals-only material (`SET_ENVFLAGS`, `HASHTAB`, `BCODESXP` internals, `SETLENGTH`, etc.): move into clearly-marked "Internals — non-API, do not use in packages" call-out boxes, or cut; every retained entry gets an explicit status

## Phase 7 — Tooling, coverage audit, and generated outputs

- [ ] `tools/build-index.R` — parse entries → `D-index.qmd` data, `functions.json`, coverage report
  - [ ] Parse function names declared in installed headers (`R.home("include")`)
  - [ ] Use API-status metadata R publishes (WRE `@apifun` annotations / `tools:::funAPI()`)
  - [ ] Diff against documented entries; emit report: undocumented API functions (gaps), documented entries that no longer exist (rot), status mismatches
  - [ ] Wire into CI: fail on rot, warn on gaps
- [ ] Turn on the coverage audit; fill gaps until the API-status diff is clean
- [ ] `tools/llms.R` — post-render: `llms.txt`, `llms-full.txt`, per-page `.md` copies
- [ ] `D-index.qmd` — generated alphabetical function index (entry point → chapter + anchor + status); never hand-edited
- [ ] (Optional, later) CI job that extracts entry examples and compiles them against R headers

## Cross-cutting (applies to every chapter)

- [ ] Every documented entry point appears in exactly one canonical entry (plus the generated index); closely-related functions share one entry
- [ ] Standard entry format: `### \`name()\` {#name}` heading; one-sentence imperative summary; exact signature block copied from current header; metadata line with fixed keys in fixed order (Status, Header, Protect, Errors, Since, R equivalent); argument bullets only when non-obvious; ≤1 short paragraph of behaviour notes; optional ≤8-line example; See also links
- [ ] Chapters are prose-plus-entries: 1–3 pages of conceptual prose, then `##` task-oriented sections containing canonical entries
- [ ] Verify every claim in migrated text against current R; assign a status to every existing entry or cut it
- [ ] Treat r-api.md as raw material to mine and rewrite, not text to copy (licensing + prose style)

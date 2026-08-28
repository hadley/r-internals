# Todo: a comprehensive, concise guide to R's C API

Derived from [plan.md](plan.md). Sequencing: scaffold ✔, metadata pipeline ✔,
then assemble a clean `functions/*.yaml` from existing content, clean it up,
and only then revise prose and write new chapters.

**Audience reminder:** experienced C programmers, new to R's API. Keep prose
brief; explain R-specific surprises, not C basics.

## Phase 1 — Quarto scaffold and repo cleanup ✔ (commit `0ddcd4e`)

- [x] Set up `_quarto.yml`: `project: type: book` (HTML only), title "R's C API", stock theme, `code-copy`, `toc`, search, `repo-url` + `repo-actions: [edit, issue]`
- [x] Move/rename existing `.md` chapters to `.qmd` per the chapter map (`git mv`, history preserved)
- [x] Fix code fences to `c` in all converted chapters
- [x] Delete stale artifacts: `*.html` snapshots, `.Rhistory`
- [x] Update `.gitignore`: `/_site`, `/.quarto`, `.DS_Store`
- [x] Move `extract-r-api.R` to `tools/` and `r-api.md` to `sources/` (not rendered)
- [x] Add `aliases:` on renamed pages (`gc-rc.html` → `protection.html`, etc.)
- [x] GitHub Action (`.github/workflows/publish.yml`): render + publish to gh-pages
- [x] Rewrite README.md for the new layout + contribution workflow
- [x] Site renders cleanly (`quarto render`, no warnings); placeholder stubs for all planned chapters
- [x] Push and verify the site goes live on gh-pages — live at https://hadley.github.io/r-internals/ (required: orphan `gh-pages` branch + R/knitr/yaml12 in the workflow for the asis chunks)

## Phase 2 — Function metadata pipeline ✔ (branch `function-metadata`)

- [x] Define the `functions/*.yaml` schema (see plan.md: name, family, summary, signature, status, replacement, header, protect, errors, since, r_equivalent, args, notes, example, see_also, chapter, section)
- [x] Seed `functions/*.yaml` with a handful of entries (`Rf_allocVector`, `Rf_allocVector3`, `Rf_xlength`/`Rf_length`, `PROTECT` family) as schema examples
- [x] Write `tools/render-entries.R`: `render_entries(chapter, section)` reads `functions/*.yaml` and returns canonical markdown; chapters call it from `{r} results: asis` chunks (no splicing; generated text never lives in `.qmd` source)
- [x] Wire up knitr so chapters can call `render_entries()` (`_setup.qmd` include + `execute: enabled: true` in `_quarto.yml`)
- [x] Validate end-to-end on one chapter (`vectors.qmd` renders; anchors present in HTML)
- [x] Use the yaml12 package (YAML 1.2) so bare keys like `n`/`y` stay strings — no quoting needed in `args:`

## Phase 3 — Assemble a clean `functions/*.yaml` (extract existing definitions)

Mechanical extraction, **not** a rewrite: move every hand-written function
definition in the existing chapters into `functions/*.yaml` records and replace
each with an asis chunk call. Don't fix stale claims, don't touch surrounding
prose; park text that doesn't fit the schema in `notes`.

All chapters extracted (268 records, one YAML file per chapter in
`functions/<chapter>.yaml`):

- [x] `vectors.qmd` — 44 records (creation, access, coercion, tests, scalars, missing values); seed records superseded
- [x] `strings.qmd` — 20 records (CHARSXP, encodings, creating/reading strings)
- [x] `pairlists.qmd` — 18 records including the attributes material (`Rf_getAttrib`/`Rf_setAttrib`, ATTRIB family)
- [x] `environments.qmd` — 29 records (bindings, creation, locking, namespaces, internals)
- [x] `symbols.qmd` — 40 records (`Rf_install`, 33 predefined symbols, internals)
- [x] `functions.qmd` — 11 records (closures, promises, srcrefs)
- [x] `external-pointers.qmd` — 6 records (external pointers, finalizers)
- [x] `oo.qmd` — 17 records (`Rf_isObject`, S3/S4 helpers)
- [x] `errors.qmd` — 13 records (errors/warnings/printing, evaluation, protected evaluation)
- [x] `serialisation.qmd` — 7 records (pstreams, XDR)
- [x] `utilities.qmd` — 48 records (sorting, matching, misc; weak refs and bytecode included)
- [x] `protection.qmd` — 13 records + existing PROTECT seed
- [x] `r-version.qmd` — 1 record (version macros)
- [x] Every extracted record has `chapter`/`section` matching its current location (reorganisation is Phase 4)
- [x] Whole book renders cleanly with all entries generated from YAML

Known issues from extraction, re-verified after Phase 4:

- [x] Statuses best guesses → fixed via header audit + §6.23 mining
- [x] `bSEXP` typo in `Rf_installS3Signature` → fixed
- [x] `Rf_mkString`/`Rf_ScalarString` duplication → record lives in strings.yaml only
- [x] `R_MissingArg` duplication → record lives in symbols.yaml only
- [x] Stray trailing space in rendered output → no longer reproducible (0/3733 lines)
- [ ] `errors`/`protect` fields are educated guesses in many records — needs a systematic audit against R's behaviour

## Phase 3.5 — Verification against `sources/r-api.md` ✔

Diffed prototype-style function names in r-api.md (95) against
`functions/*.yaml` (268 records / ~700 names incl. families). 48 covered;
46 genuine gaps, mostly content for not-yet-written chapters (Phase 7):

- Memory (→ `memory.qmd`): `R_Calloc`, `R_Realloc`, `R_Free`
- Routine registration (→ `calling-c.qmd`): `R_registerRoutines`, `R_useDynamicSymbols`
- RNG/math/numerical (→ `rng.qmd`, `math.qmd`, `numerical.qmd`): `R_unif_index`, `R_pow`, `Rf_rmultinom`, `Rdqagi`, `Rdqags`, `R_init_stats`
- Conditions/unwind (→ `errors.qmd`): `R_UnwindProtect`, `R_ContinueUnwind`, `R_MakeUnwindCont`, `R_withCallingErrorHandler`, `R_tryCatch`, `R_tryCatchError`
- Modern §6.23 API (→ Part II chapters): `R_mkClosure`, `R_ClosureEnv`, `R_ClosureFormals`, `Rf_allocLang`, `Rf_isDataFrame`, `R_Dots*` (6), binding functions (`R_GetBindingType`, `R_MakeDelayedBinding`, `R_MakeForcedBinding`, `R_MakeMissingBinding`, `R_DelayedBinding*`, `R_DotDelayed*`, `R_ForcedBindingExpression`, `R_findDotsEnv`), `R_envSymbols`, `R_ParentEnv`, `R_class`, `R_mapAttrib`
- Experimental resizable vectors: `R_allocResizableVector`, `R_duplicateAsResizable`, `R_resizeVector`, `SET_GROWABLE_BIT`

## Phase 4 — Clean up `functions/*.yaml` in place

Now that everything is machine-readable, fix the data — prose still untouched.

- [x] Verify names against current installed headers (`R.home("include")`): audited all ~700 names; 22 absent from headers (all internals, confirmed non-api), 5 on `tools:::nonAPI` (flipped: `CONS_NR`, `R_RestoreHashCount`, `Rf_StringFalse` family; `Rf_setSVector` already non-api)
- [x] Assign/correct `status` for every record — done via header audit + §6.23 mining (215 api / 52 non-api / 1 embedding)
- [x] Mine r-api.md §6.23 for modern replacements; recorded in `replacement`/`see_also`/`notes` (23 records updated, 9 flipped to non-api)
- [x] Fix known stale claims (`Rf_findVarInFrame3` → `R_getVar` family note; `UNPROTECT_PTR` already non-api; `bSEXP` typo fixed; `Rboolean`/LGLSXP claim is chapter prose — Phase 6)
- [x] Fix header fields found by audit (`Rf_warning` → `R_ext/Error.h`, `R_ExpandFileName`/`Rf_StringFalse` → `R_ext/Utils.h`, `NA_LOGICAL` → `R_ext/Arith.h`)
- [x] Deduplicate: `R_MissingArg` (symbols only), `Rf_ScalarString`/`Rf_mkString` (strings only)
- [x] Reassign `chapter`/`section` to the final chapter map: attributes (from pairlists + vectors arrays/matrices/factors/data-frames), evaluation + printing (from errors), weak references (utilities → external-pointers); qmd sections moved to match
- [x] Tighten summaries to one imperative sentence; notes to ≤1 short paragraph (done systematically across all 268 records, one `functions/<chapter>.yaml` file at a time)
- [ ] Re-add `since:` fields for APIs introduced in R 4.2 or later (dropped wholesale with pre-4.2 references; only post-4.2 introductions need the field, per the version policy in `index.qmd`)
- [ ] Add records for the §6.23 replacement functions that lack them (list reported by the mining pass: `R_getVar` family, `R_ClosureFormals/Body/Env`, `STRING_PTR_RO`, `R_getAttributes` family, `R_nrow`/`R_ncol`, R 4.6.0 binding/dots API, etc.) — overlaps with the Phase 3.5 gap list; fold into Phase 7

## Phase 5 — Part I: Foundations prose (mostly new; adv-r chapter is the model)

- [ ] `index.qmd` — Introduction
  - [ ] What this site is; relationship to WRE / R Internals / adv-r
  - [ ] Audience and prerequisites: experienced C programmers; C basics not explained
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
  - [ ] What needs protecting and what doesn't (arguments, symbols, values reachable from protected objects)
  - [ ] `R_PreserveObject`/`R_ReleaseObject` for cross-call lifetimes
  - [ ] Common protection bugs and how to find them (`gctorture`, rchk)
- [ ] `memory.qmd` — Memory allocation
  - [ ] Transient `R_alloc`/`vmaxget`/`vmaxset`
  - [ ] `R_Calloc`/`R_Realloc`/`R_Free` and cleanup-on-error obligations
  - [ ] Alignment; when to prefer a `RAWSXP` instead

## Phase 6 — Chapter prose revisions (Part II)

Brief conceptual prose around the generated entries; reorganise sections to
match the final `chapter`/`section` assignments from Phase 4.

- [ ] `vectors.qmd` — move arrays/matrices/factors/data-frames prose to `attributes.qmd`
- [ ] `strings.qmd` — string pool, encodings, translation, re-encoding via `Riconv` (§6.12)
- [ ] `attributes.qmd` — attribute-defined structures: matrices/arrays, factors, data frames
- [ ] `environments.qmd`, `symbols.qmd`, `pairlists.qmd`, `functions.qmd`, `external-pointers.qmd`, `oo.qmd` — brief intros + task-oriented section headings

## Phase 7 — Parts III–IV (reorganise r-api.md content into `functions/*.yaml` records)

- [ ] `evaluation.qmd` — `Rf_eval`, `R_tryEval`/`R_tryEvalSilent`, `R_forceAndCall`, `Rf_applyClosure`; building and evaluating calls end-to-end (worked example)
- [ ] `errors.qmd` — signalling (`Rf_error`, `Rf_warning`, `*call` variants); longjmp problem and C++/resource safety; condition handling and cleanup (§6.13: `R_UnwindProtect`, `R_withCallingErrorHandler`, `R_MakeUnwindCont`); interrupts (§6.14, `R_CheckUserInterrupt`); C stack checking (§6.15)
- [ ] `printing.qmd` — `Rprintf`/`REprintf`, `Rf_PrintValue`, `R_ShowMessage`, console flushing (short chapter)
- [ ] `serialisation.qmd` — public (un)serialisation, custom pstreams (§6.16), XDR helpers
- [ ] `rng.qmd` — `GetRNGstate`/`PutRNGstate`, `unif_rand` family, `R_unif_index`; relationship to `.Random.seed`
- [ ] `math.qmd` — Rmath: distribution functions (d/p/q/r table), mathematical functions (bessel, gamma, beta...), numerical utilities (`R_pow`, `fmax2`, `imin2`, `expm1`-style helpers), constants (`M_PI` etc.), standalone Rmath (§6.20 folded in)
- [ ] `numerical.qmd` — optimization (§6.8), integration (§6.9), linear algebra / BLAS / LAPACK headers and `FCONE` (§6.11), `findInterval`, `R_max_col`
- [ ] `utilities.qmd` — sorting/ordering (`R_qsort`, `R_orderVector`), matching (`Rf_match`, `Rf_pmatch`), `R_compute_identical`, `Rf_duplicated`/`Rf_any_duplicated`, options (`Rf_GetOption1`), numeric parsing (`R_atof`/`R_strtod`), paths/tempfiles (`R_ExpandFileName`, `R_tmpnam2`), platform info (§6.17)
- [ ] Fill the 46 gaps found in the Phase 3.5 r-api.md diff (listed above) as records in the appropriate chapters
- [x] `r-version.qmd` — R version: `Rversion.h` and version-check macros (renamed from other-headers.md; moved to Part IV)

## Phase 8 — Appendices

- [ ] `compliance.qmd` — Migrating to API compliance: non-API → API replacement tables and recipes (§6.23), backports, how to check a package (`R CMD check`, `tools::checkFF`-era tooling). Table-heavy; generate tables from `functions/*.yaml` where possible
- [x] ~~`B-fortran.qmd`~~ — Fortran interop dropped from scope
- [x] ~~`C-headers.qmd`~~ — header-map appendix dropped; other-headers.md renamed to `r-version.qmd` and moved to Part IV
- [ ] Handle internals-only material (`SET_ENVFLAGS`, `HASHTAB`, `BCODESXP` internals, `SETLENGTH`, etc.): records get `status: non-api` and render into clearly-marked "Internals — non-API, do not use in packages" call-outs, or are cut

## Phase 9 — Tooling, coverage audit, and generated outputs

- [ ] `tools/build-index.R` — read `functions/*.yaml` → `function-index.qmd` data, `functions.json`, coverage report
  - [ ] Parse function names declared in installed headers (`R.home("include")`)
  - [ ] Use API-status metadata R publishes (WRE `@apifun` annotations / `tools:::funAPI()`)
  - [ ] Diff against `functions/*.yaml`; emit report: undocumented API functions (gaps), records that no longer exist (rot), status mismatches
  - [ ] Wire into CI: fail on rot, warn on gaps
- [ ] Turn on the coverage audit; fill gaps until the API-status diff is clean
- [ ] `tools/llms.R` — post-render: `llms.txt`, `llms-full.txt`, per-page `.md` copies
- [ ] `function-index.qmd` — generated alphabetical function index (entry point → chapter + anchor + status); never hand-edited
- [ ] (Optional, later) CI job that extracts entry examples and compiles them against R headers

## Cross-cutting (applies to every chapter)

- [ ] Every documented entry point appears in exactly one record in `functions/*.yaml` (plus the generated index); closely-related functions share one record via `family:`
- [ ] Entry format is generated by `tools/render-entries.R` from the YAML schema (see plan.md); chapters inject entries via `results: asis` chunks, never hand-written entry text
- [ ] Chapters are prose-plus-entries: brief conceptual prose (audience knows C — keep it short), then `##` task-oriented sections each with one asis chunk calling `render_entries()`
- [ ] Verify every claim in migrated text against current R; assign a status to every existing entry or cut it
- [ ] Treat r-api.md as raw material to mine and rewrite, not text to copy (licensing + prose style)

# Project conventions

This repo is a Quarto book documenting R's C API for package authors. See
`plan.md` for the full plan and `todo.md` for the current work plan.

## Style

- **Use sentence case for all titles and headings** (capitalize only the
  first word and proper nouns, e.g. "Calling C from R", not
  "Calling C From R").
- Code examples are C, not C++; fences are ` ```c `.
- Always use `R_NO_REMAP` conventions: `Rf_`/`R_` prefixed names.
- `.Call` only; never recommend `.C`/`.Fortran`.
- Fortran interop is not covered.
- Never document non-API (or embedding-only) entry points in the rendered
  chapters. Records with `status: non-api`/`embedding` live only in
  `functions/compliance.yaml` (parked for the compliance appendix); if a
  chapter section loses all its records this way, remove the section.
- To verify a WRE backlink anchor, grep the local `sources/r-api.md` (its
  headings carry the mined `<a href="#anchor">` ids) — do **not** curl the
  CRAN page.
- No prose may follow a `render_entries()` chunk within a section: the
  generated entries end with headings, so trailing text would appear to
  belong to the last entry. Put prose before the chunk or into YAML `notes`.
- When a chapter's content is drawn closely from a mined WRE section (see
  `sources/`), add a backlink at the top of each subsection to the matching
  WRE subsection on the CRAN page (e.g.
  `https://cran.r-project.org/doc/manuals/R-exts.html#Transient-storage-allocation-1`),
  not just once for the whole chapter — verify each anchor resolves before
  adding it.

## Layout

- One `.qmd` per chapter; chapter order lives in `_quarto.yml`.
- `tools/` holds maintenance scripts; `sources/` holds raw mined material
  (never rendered, never copied verbatim).
- `tools/build-index.R` is the coverage audit: diffs `functions/*.yaml`
  against `tools:::funAPI()` + installed headers (0 gaps / 0 rot / 0 status
  mismatches required), writes `functions.json` (gitignored; served at
  /functions.json via CI). `function-index.qmd` is generated at render time
  by `render_function_index()` — never hand-edit.
- YAML files must stay single-document: no `---`/`...` marker lines
  (yaml12 parses only the first document and silently drops the rest).
- `llms-txt: true` is set under a top-level `website:` key (book projects
  accept it there; under `book:` it is ignored).

## R source access

- R's C source comes from the GitHub mirror
  <https://github.com/r-devel/r-svn>. It has **no release tags**, so
  `tools/r-versions.csv` records the commit SHA for each minor release
  (4.2.0+; patch releases don't change the C API). Each SHA is the
  release branch point (parent of the "go to X.(Y+1).0 devel" commit).
- Full source is downloaded on demand into `sources/r-<version>/src`
  (gitignored — never commit it) with `tools/fetch-r-source.sh <version>`
  (or `all`).
- Committed copies of the public headers for each release live in
  `sources/headers/<version>/` (e.g. `sources/headers/4.2.0/`).

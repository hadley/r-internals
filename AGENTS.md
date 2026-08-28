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

## Layout

- One `.qmd` per chapter; chapter order lives in `_quarto.yml`.
- `tools/` holds maintenance scripts; `sources/` holds raw mined material
  (never rendered, never copied verbatim).

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

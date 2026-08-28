# R's C API

A comprehensive, concise guide to R's C API for package authors, reflecting
the post-R-4.5 API-compliance era (`R_NO_REMAP`, `Rf_`/`R_` prefixes, and the
API / experimental / embedding / non-API classification).

This repo is a [Quarto book](https://quarto.org/docs/books/). Render it
locally with:

```sh
quarto render
```

## Repository layout

- `index.qmd`, `calling-c.qmd`, ... — one `.qmd` per chapter, organised into
  Parts I–IV plus appendices (see `_quarto.yml`).
- `diagrams/` — images used by chapters.
- `tools/` — maintenance scripts:
  - `extract-r-api.R` regenerates `sources/r-api.md` (WRE chapter 6) so we
    can re-diff against future WRE releases.
  - `build-index.R` (planned) parses the standardised entries to produce the
    function index, `functions.json`, and a coverage report.
  - `llms.R` (planned) produces `llms.txt`, `llms-full.txt`, and per-page
    markdown copies post-render.
- `sources/` — raw mined material (e.g. `r-api.md`). **Not rendered**; treat
  as source to rewrite, not copy.

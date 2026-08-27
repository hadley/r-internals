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

## Contributing

Every documented C entry point gets exactly one canonical entry in the
standard format (heading with `{#anchor}` equal to the C identifier,
one-sentence summary, signature block, metadata line with Status / Header /
Protect / Errors / Since / R equivalent, behaviour notes, optional short
example, see-also links). See `plan.md` for the full specification, and
`todo.md` for the current work plan.

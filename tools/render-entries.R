# Render function entries from functions/<chapter>.yaml into markdown.
# Chapters call render_entries() from knitr `results: asis` chunks.

read_functions <- function(dir = "functions") {
  # One YAML file per chapter: functions/<chapter>.yaml
  # yaml12 is a YAML 1.2 parser: bare keys like `n`/`y` stay strings
  files <- list.files(dir, pattern = "[.]yaml$", full.names = TRUE)
  unlist(
    lapply(files, function(f) yaml12::parse_yaml(readLines(f, warn = FALSE))),
    recursive = FALSE
  )
}

status_label <- function(status) {
  switch(status,
    api = "API",
    experimental = "experimental",
    embedding = "embedding",
    `non-api` = "non-API",
    stop("Unknown status: ", status)
  )
}

fmt_value <- function(x, dash = "\u2014") {
  if (is.null(x)) dash else as.character(x)
}

render_entry <- function(entry) {
  all_names <- c(entry$name, unlist(entry$family))

  # Metadata line: fixed keys, fixed order
  status <- status_label(entry$status)
  if (!is.null(entry$replacement)) {
    status <- paste0(status, " (use [`", entry$replacement, "()`](#", entry$replacement, "))")
  }
  meta <- paste0(
    "**Status:** ", status,
    " \u00b7 **Header:** `", entry$header, "`",
    " \u00b7 **Protect:** ", gsub("-", " ", fmt_value(entry$protect, "n/a")),
    " \u00b7 **Errors:** ", gsub("-", " ", fmt_value(entry$errors)),
    " \u00b7 **Since:** ", fmt_value(entry$since),
    " \u00b7 **R equivalent:** ",
    if (is.null(entry$r_equivalent)) "\u2014" else paste0("`", entry$r_equivalent, "`")
  )

  args <- NULL
  if (!is.null(entry$args)) {
    args <- paste0("- `", names(entry$args), "`: ", unlist(entry$args), collapse = "\n")
  }

  example <- NULL
  if (!is.null(entry$example)) {
    example <- paste0("```c\n", trimws(entry$example, "right"), "\n```")
  }

  see_also <- NULL
  if (length(entry$see_also) > 0) {
    links <- paste0("[`", entry$see_also, "()`](#", entry$see_also, ")")
    see_also <- paste0("**See also:** ", paste(links, collapse = ", "))
  }

  heading <- paste0(
    "### `", entry$name, "()`",
    if (length(all_names) > 1) {
      paste0(" (", paste(paste0("`", all_names[-1], "()`"), collapse = ", "), ")")
    },
    " {#", entry$name, "}"
  )

  paste(c(
    heading,
    "",
    entry$summary,
    "",
    paste0("```c\n", trimws(entry$signature, "right"), "\n```"),
    "",
    meta,
    "",
    args,
    if (!is.null(args)) "",
    entry$notes,
    "",
    example,
    if (!is.null(example)) "",
    see_also
  ), collapse = "\n")
}

#' Render the alphabetical function index as a markdown table
#'
#' Every documented name (record names and family members) links to the
#' anchor of its record. Call from a knitr chunk with `results: asis`.
render_function_index <- function(dir = "functions") {
  entries <- read_functions(dir)
  rows <- do.call(rbind, lapply(entries, function(e) {
    data.frame(
      name = c(e$name, unlist(e$family)),
      anchor = e$name,
      status = status_label(e$status),
      chapter = e$chapter,
      stringsAsFactors = FALSE
    )
  }))
  rows <- rows[order(tolower(rows$name)), ]
  lines <- paste0(
    "| [`", rows$name, "()`]", "(", rows$chapter, ".qmd#", rows$anchor, ") | ",
    rows$status, " | ", rows$chapter, " |"
  )
  cat(paste(c(
    "| Function | Status | Chapter |",
    "|----------|--------|---------|",
    lines
  ), collapse = "\n"), "\n")
  invisible(rows)
}

#' Render all entries for a chapter section as markdown
#'
#' Call from a knitr chunk with `results: asis`:
#' `render_entries("vectors", "Create")`
render_entries <- function(chapter, section, dir = "functions") {
  entries <- read_functions(dir)
  keep <- vapply(
    entries,
    function(e) {
      # non-API/embedding records are parked for the compliance appendix
      # and must never render in regular chapters
      if (!identical(e$chapter, "compliance") && e$status %in% c("non-api", "embedding")) {
        stop("Non-API record '", e$name, "' must live in functions/compliance.yaml")
      }
      identical(e$chapter, chapter) && identical(e$section, section)
    },
    logical(1)
  )
  if (!any(keep)) {
    warning("No entries for chapter '", chapter, "', section '", section, "'")
    return(invisible(""))
  }
  out <- vapply(entries[keep], render_entry, character(1))
  cat(paste0(paste(out, collapse = "\n\n"), "\n"))
  invisible(out)
}

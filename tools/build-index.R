# Coverage audit + machine-readable outputs for the function metadata.
#
# Usage: Rscript tools/build-index.R   (run from the repo root)
#
# Outputs:
#   functions.json    - all records from functions/*.yaml, as JSON
#   stdout report     - coverage audit: gaps, rot, status mismatches
#
# Exit status is 1 on rot (documented entry points that no longer exist),
# 0 otherwise; gaps and mismatches are warnings only.

source("tools/render-entries.R")

# Headers whose contents we document as tables/families in prose
# (BLAS/LAPACK/Linpack in numerical.qmd, Rmath in math.qmd) rather than
# as per-function records. funAPI() marks every function in these headers
# API via WRE's @apihdr; we cover them by design.
covered_headers <- c(
  "R_ext/BLAS.h", "R_ext/Lapack.h", "R_ext/Linpack.h", "Rmath.h"
)

# Whole topic areas the book deliberately does not cover (see plan.md):
# the graphics engine and X11 image transfer.
out_of_scope_headers <- c(
  "R_ext/GraphicsEngine.h", "R_ext/GraphicsDevice.h", "R_ext/GetX11Image.h"
)

# Our status taxonomy <-> WRE/funAPI apitype
apitype_map <- c(api = "api", eapi = "experimental", emb = "embedding", `for` = "fortran")

all_names <- function(recs) {
  unique(unlist(lapply(recs, function(e) c(e$name, unlist(e$family)))))
}

header_names <- function() {
  inc <- file.path(R.home("include"))
  files <- list.files(inc, pattern = "[.]h$", recursive = TRUE, full.names = TRUE)
  paste(
    vapply(files, function(f) paste(readLines(f, warn = FALSE), collapse = "\n"), character(1)),
    collapse = "\n"
  )
}

audit <- function(recs, fun_api = tools:::funAPI(), htext = header_names()) {
  doc <- all_names(recs)
  # name -> our status (record status applies to the whole family)
  our_status <- list()
  for (e in recs) {
    for (n in c(e$name, unlist(e$family))) our_status[[n]] <- e$status
  }

  # --- Gaps: API entry points we don't document -------------------------
  in_scope <- fun_api[!fun_api$loc %in% c(covered_headers, out_of_scope_headers) &
    !fun_api$apitype %in% c("emb", "for"), ]
  gaps <- in_scope[!in_scope$name %in% doc, ]
  gaps_required <- gaps[gaps$apitype == "api", ]
  gaps_experimental <- gaps[gaps$apitype == "eapi", ]

  # --- Rot: documented names that no longer exist ------------------------
  # funAPI doesn't track macros/inline functions, so a documented name is
  # only rot when it's in neither funAPI nor the installed headers. Records
  # parked in compliance.yaml are expected to be absent from both.
  rot <- character()
  for (e in recs) {
    if (identical(e$chapter, "compliance")) next
    for (n in c(e$name, unlist(e$family))) {
      if (!n %in% fun_api$name && !grepl(paste0("\\b", n, "\\b"), htext)) {
        rot <- c(rot, paste0(n, " (record ", e$name, ", ", e$chapter, ")"))
      }
    }
  }

  # --- Status mismatches --------------------------------------------------
  # Compared on record names only: family members inherit the record's
  # status, and WRE occasionally annotates family members differently.
  rec_status <- vapply(recs, function(e) e$status, character(1))
  names(rec_status) <- vapply(recs, function(e) e$name, character(1))
  both <- intersect(names(rec_status), fun_api$name)
  theirs <- unname(apitype_map[fun_api$apitype[match(both, fun_api$name)]])
  ours <- unname(rec_status[both])
  mism <- data.frame(
    name = both, ours = ours, wre = theirs,
    stringsAsFactors = FALSE
  )
  mism <- mism[mism$ours != mism$wre, ]

  # --- Duplicates: each entry point documented in exactly one record ------
  alln <- unlist(lapply(recs, function(e) c(e$name, unlist(e$family))))
  duplicates <- unique(alln[duplicated(alln)])

  list(gaps_required = gaps_required, gaps_experimental = gaps_experimental,
       rot = rot, mismatches = mism, duplicates = duplicates)
}

print_audit <- function(a) {
  cat("== Coverage audit ==\n\n")

  cat("-- Gaps: API entry points not documented (", nrow(a$gaps_required), ") --\n", sep = "")
  if (nrow(a$gaps_required)) print(a$gaps_required, row.names = FALSE)
  cat("\n")

  cat("-- Known experimental gaps, not required (", nrow(a$gaps_experimental), ") --\n", sep = "")
  if (nrow(a$gaps_experimental)) cat(paste(sort(a$gaps_experimental$name), collapse = ", "), "\n")
  cat("\n")

  cat("-- Rot: documented names absent from funAPI and installed headers (", length(a$rot), ") --\n", sep = "")
  if (length(a$rot)) cat(paste0("  ", a$rot, collapse = "\n"), "\n")
  cat("\n")

  cat("-- Status mismatches vs WRE annotations (", nrow(a$mismatches), ") --\n", sep = "")
  if (nrow(a$mismatches)) print(a$mismatches, row.names = FALSE)
  cat("\n")

  cat("-- Duplicate entry points across records (", length(a$duplicates), ") --\n", sep = "")
  if (length(a$duplicates)) cat(paste0("  ", a$duplicates, collapse = "\n"), "\n")
}

write_functions_json <- function(recs, path = "functions.json") {
  # jsonlite is overkill to require; records are simple enough to hand-roll,
  # but jsonlite is a knitr dependency so it's always available at render time.
  jsonlite::write_json(recs, path, auto_unbox = TRUE, pretty = 2, null = "null")
  cat("Wrote ", path, " (", length(recs), " records)\n", sep = "")
}

main <- function() {
  recs <- read_functions()
  write_functions_json(recs)
  a <- audit(recs)
  print_audit(a)
  if (length(a$rot) || length(a$duplicates)) {
    cat("\nFAIL: rot or duplicates detected\n")
    quit(status = 1)
  }
}

if (sys.nframe() == 0) main()

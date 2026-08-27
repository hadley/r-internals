library(rvest)
library(xml2)

url <- "https://cran.r-project.org/doc/manuals/R-exts.html"
html_file <- "R-exts.html"
section_html <- "r-api.html"
section_md <- "r-api.md"

download.file(url, html_file, quiet = TRUE)

doc <- read_html(html_file)

# Locate the chapter heading and collect it plus siblings up to the next h2
h2 <- html_element(doc, xpath = "//h2[contains(@id, 'The-R-API')]")
stopifnot("Chapter not found" = !inherits(h2, "xml_missing"))

nodes <- list(h2)
sib <- xml_find_first(h2, "following-sibling::*[1]")
while (!inherits(sib, "xml_missing") && xml_name(sib) != "h2") {
  nodes <- c(nodes, list(sib))
  sib <- xml_find_first(sib, "following-sibling::*[1]")
}

# Write a minimal standalone HTML document containing just those nodes
page <- read_html("<html><head><meta charset='utf-8'></head><body></body></html>")
body <- html_element(page, "body")
for (node in nodes) xml_add_child(body, node)
write_html(page, section_html)

system2("pandoc", c(section_html, "-f", "html", "-t", "gfm", "-o", section_md))

message("Wrote ", section_md)

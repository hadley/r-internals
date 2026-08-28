#!/usr/bin/env bash
# Fetch R's C source for a given minor release into sources/r-<version>/.
#
# Usage: tools/fetch-r-source.sh <version|all>   e.g. tools/fetch-r-source.sh 4.2.0
#
# Downloads the tarball for the release's commit SHA (recorded in
# tools/r-versions.csv, since the r-devel/r-svn mirror has no release tags)
# and extracts only src/. The result is gitignored; re-run any time.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ $# -ne 1 ]; then
  echo "usage: $0 <version|all>" >&2
  exit 1
fi

fetch_one() {
  local ver="$1" sha
  sha=$(grep -v '^#' tools/r-versions.csv | tail -n +2 | grep "^$ver," | cut -d, -f2)
  if [ -z "$sha" ]; then
    echo "error: unknown version '$ver' (not in tools/r-versions.csv)" >&2
    return 1
  fi
  if [ -d "sources/r-$ver/src" ]; then
    echo "sources/r-$ver already exists; delete it first to re-fetch"
    return 0
  fi

  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  echo "fetching R $ver ($sha)..."
  curl -sL "https://codeload.github.com/r-devel/r-svn/tar.gz/$sha" -o "$tmp/r.tar.gz"
  mkdir -p "sources/r-$ver"
  tar -xzf "$tmp/r.tar.gz" -C "$tmp" "r-svn-$sha/src"
  mv "$tmp/r-svn-$sha/src" "sources/r-$ver/src"
  echo "extracted to sources/r-$ver/src"
}

if [ "$1" = "all" ]; then
  grep -v '^#' tools/r-versions.csv | tail -n +2 | cut -d, -f1 | while read -r ver; do
    fetch_one "$ver"
  done
else
  fetch_one "$1"
fi

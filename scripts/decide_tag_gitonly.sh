#!/usr/bin/env bash
set -euo pipefail

train="${TRAIN:?}"   # e.g. 2025-09

# Tag is Eclipse-only (plus platform), no plugin versions in it.
tag="eclipse-java-${train}-win64"

if gh release view "$tag" >/dev/null 2>&1; then
  echo "SKIP=true"  >> "$GITHUB_ENV"
else
  echo "SKIP=false" >> "$GITHUB_ENV"
fi

echo "TAG=$tag" >> "$GITHUB_ENV"
echo "tag=$tag" >> "$GITHUB_OUTPUT"

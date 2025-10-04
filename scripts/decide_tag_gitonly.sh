#!/usr/bin/env bash
set -euo pipefail

train="${TRAIN:?}"
sl_ver="${SONARLINT_VERSION:?}"
tag="eclipse-java-${train}-win64-sonarlint-${sl_ver}-dejcup"

if gh release view "$tag" >/dev/null 2>&1; then
  echo "SKIP=true"  >> "$GITHUB_ENV"
else
  echo "SKIP=false" >> "$GITHUB_ENV"
fi

echo "TAG=$tag" >> "$GITHUB_ENV"
echo "tag=$tag" >> "$GITHUB_OUTPUT"

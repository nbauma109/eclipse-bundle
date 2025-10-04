#!/usr/bin/env bash
set -euo pipefail

train="${TRAIN:?}"
mkdir -p win  # already has win/eclipse

out="eclipse-java-${train}-R-win32-x86_64-with-plugins.zip"
( cd win && zip -qr "../$out" eclipse )

echo "WIN_OUT=$out" >> "$GITHUB_ENV"
echo "file=$out"    >> "$GITHUB_OUTPUT"

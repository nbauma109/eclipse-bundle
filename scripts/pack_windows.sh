#!/usr/bin/env bash
set -euo pipefail

train="${TRAIN:?}"
win_zip="${WIN_ZIP:?}"

mkdir -p win && (cd win && unzip -q "../$win_zip")
mkdir -p "win/eclipse/dropins"
cp -r "dropins/custom" "win/eclipse/dropins/"
out="eclipse-java-${train}-R-win32-x86_64-with-plugins.zip"

(cd win && zip -qr "../$out" eclipse)

echo "WIN_OUT=$out" >> "$GITHUB_ENV"
echo "file=$out"    >> "$GITHUB_OUTPUT"

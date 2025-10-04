#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/common.sh"

train="${TRAIN:?}"
base="/technology/epp/downloads/release/${train}/R"
win="eclipse-java-${train}-R-win32-x86_64.zip"

pick_and_download "$base" "$win" "$win"

echo "WIN_ZIP=$win" >> "$GITHUB_ENV"

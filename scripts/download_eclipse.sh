#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/common.sh"

train="${TRAIN:?}"
base="/technology/epp/downloads/release/${train}/R"
win="eclipse-java-${train}-R-win32-x86_64.zip"
lnx="eclipse-java-${train}-R-linux-gtk-x86_64.tar.gz"

pick_and_download "$base" "$win" "$win"
pick_and_download "$base" "$lnx" "$lnx"

echo "WIN_ZIP=$win" >> "$GITHUB_ENV"
echo "LNX_TGZ=$lnx" >> "$GITHUB_ENV"

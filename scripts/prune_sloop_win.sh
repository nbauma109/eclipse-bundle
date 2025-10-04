#!/usr/bin/env bash
set -euo pipefail

plugdir="dropins/custom/eclipse/plugins"
sloop_win="$(ls "$plugdir"/org.sonarlint.eclipse.sloop.windows.x64_*.jar | head -n1 || true)"
[ -n "${sloop_win:-}" ] || { echo "Windows x64 sloop jar not found" >&2; exit 1; }

base="$(basename "$sloop_win")"
target="${plugdir}/${base%.jar}"
mkdir -p "$target"
unzip -q "$sloop_win" -d "$target"
rm -f "$sloop_win"

# delete all other sloop jars (any platform)
find "$plugdir" -maxdepth 1 -type f -name 'org.sonarlint.eclipse.sloop.*.jar' -print -delete || true

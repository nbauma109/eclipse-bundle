#!/usr/bin/env bash
set -euo pipefail

tar -xzf "${LNX_TGZ:?}"
ecl_dir="$(find . -maxdepth 1 -type d -name eclipse | head -n1)"
[ -n "$ecl_dir" ] || { echo "Linux Eclipse dir not found" >&2; exit 1; }

echo "LINUX_ECLIPSE_DIR=$ecl_dir" >> "$GITHUB_ENV"
echo "dir=$ecl_dir"               >> "$GITHUB_OUTPUT"

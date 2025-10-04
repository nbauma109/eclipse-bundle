#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/common.sh"

page="$(curl -fsSL https://www.eclipse.org/downloads/packages/release)"
train="$(printf '%s' "$page" | grep -Eo '[0-9]{4}-[0-9]{2} R' | head -n1 | cut -d' ' -f1)"
[ -n "${train:-}" ] || { err "Could not detect latest train"; exit 1; }

echo "TRAIN=$train" >> "$GITHUB_ENV"
echo "train=$train"  >> "$GITHUB_OUTPUT"
log "Detected Eclipse train: $train"

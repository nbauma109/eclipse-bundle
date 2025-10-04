#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/common.sh"

json="$(curl -fsSL -H "Authorization: Bearer ${GH_TOKEN:-}" https://api.github.com/repos/SonarSource/sonarlint-eclipse/releases/latest)"
ver="$(printf '%s' "$json" | jq -r '.tag_name' | sed 's/^v//')"
[ -n "${ver:-}" ] && [ "$ver" != "null" ] || { err "Failed to get SonarLint version from GitHub"; exit 1; }

echo "SONARLINT_VERSION=$ver" >> "$GITHUB_ENV"
echo "version=$ver"           >> "$GITHUB_OUTPUT"

log "SonarLint version: $ver"

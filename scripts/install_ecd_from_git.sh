#!/usr/bin/env bash
set -euo pipefail

: "${ECLIPSE_ROOT:?}"

PLUGINS_DIR="${ECLIPSE_ROOT%/}/plugins"
FEATURES_DIR="${ECLIPSE_ROOT%/}/features"
mkdir -p "$PLUGINS_DIR" "$FEATURES_DIR"

echo "[INFO] Fetching latest ECD release..."
json="$(curl -fsSL https://api.github.com/repos/nbauma109/ecd/releases/latest)"
version="$(echo "$json" | jq -r .tag_name)"

# Expected asset name format: enhanced-class-decompiler-${version}.zip
url="$(echo "$json" | jq -r ".assets[] | select(.name | test(\"enhanced-class-decompiler-.*\\.zip\")) | .browser_download_url")"

if [[ -z "$url" || "$url" == "null" ]]; then
  echo "[ERROR] Could not find enhanced-class-decompiler zip in latest ECD release"
  exit 1
fi

echo "[INFO] Downloading ECD $version from $url ..."
tmpdir="$(mktemp -d)"
curl -fL --retry 5 -o "$tmpdir/ecd.zip" "$url"

echo "[INFO] Extracting into ${ECLIPSE_ROOT%/} ..."
unzip -q -o "$tmpdir/ecd.zip" 'features/*' -d "${ECLIPSE_ROOT%/}"
unzip -q -o "$tmpdir/ecd.zip" 'plugins/*' -d "${ECLIPSE_ROOT%/}"

rm -rf "$tmpdir"

# Export version for release notes
clean_ver="${version#v}"
echo "ECD_VERSION=$clean_ver" >> "$GITHUB_ENV"

echo "[INFO] ECD $clean_ver installed into ${ECLIPSE_ROOT%/}."

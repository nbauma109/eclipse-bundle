#!/usr/bin/env bash
set -euo pipefail

: "${ECLIPSE_ROOT:?}"

PLUGINS_DIR="${ECLIPSE_ROOT%/}/plugins"
FEATURES_DIR="${ECLIPSE_ROOT%/}/features"
mkdir -p "$PLUGINS_DIR" "$FEATURES_DIR"

echo "[INFO] Detecting latest ECD release..."
latest_url="$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/nbauma109/ecd/releases/latest)"
latest_tag="${latest_url##*/}"

if [[ -z "${latest_tag:-}" ]]; then
  echo "[ERROR] Could not detect latest ECD version tag"
  exit 1
fi

zip_url="https://github.com/nbauma109/ecd/releases/download/${latest_tag}/enhanced-class-decompiler-${latest_tag}.zip"
echo "[INFO] Latest ECD version: $latest_tag"
echo "[INFO] Download URL: $zip_url"

tmpdir="$(mktemp -d)"
curl -fL --retry 5 -o "$tmpdir/ecd.zip" "$zip_url"

echo "[INFO] Extracting into ${ECLIPSE_ROOT%/} ..."
unzip -q -o "$tmpdir/ecd.zip" 'features/*' -d "${ECLIPSE_ROOT%/}"
unzip -q -o "$tmpdir/ecd.zip" 'plugins/*'  -d "${ECLIPSE_ROOT%/}"

rm -rf "$tmpdir"

# Export version for release notes
echo "ECD_VERSION=$latest_tag" >> "$GITHUB_ENV"

echo "[INFO] ECD $latest_tag installed into ${ECLIPSE_ROOT%/}."

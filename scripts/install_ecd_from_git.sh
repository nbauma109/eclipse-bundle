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

echo "[INFO] Latest ECD version: $latest_tag"

# Try .tar.xz first, fallback to .zip (for older releases)
tar_url="https://github.com/nbauma109/ecd/releases/download/${latest_tag}/enhanced-class-decompiler-${latest_tag}.tar.xz"
zip_url="https://github.com/nbauma109/ecd/releases/download/${latest_tag}/enhanced-class-decompiler-${latest_tag}.zip"

tmpdir="$(mktemp -d)"

echo "[INFO] Checking archive type..."
if curl -fsI "$tar_url" >/dev/null 2>&1; then
  echo "[INFO] Using tar.xz archive"
  archive="$tmpdir/ecd.tar.xz"
  curl -fL --retry 5 -o "$archive" "$tar_url"
  echo "[INFO] Extracting ECD tar.xz ..."
  tar -xf "$archive" -C "$tmpdir"

elif curl -fsI "$zip_url" >/dev/null 2>&1; then
  echo "[INFO] Using zip archive"
  archive="$tmpdir/ecd.zip"
  curl -fL --retry 5 -o "$archive" "$zip_url"
  echo "[INFO] Extracting ECD zip ..."
  unzip -q "$archive" -d "$tmpdir"

else
  echo "[ERROR] Neither .tar.xz nor .zip ECD asset found!"
  exit 1
fi

# Clean path: both archives contain "features" and "plugins" at root
echo "[INFO] Copying plugins/features ..."
cp -r "$tmpdir"/features/* "$FEATURES_DIR"/ 2>/dev/null || true
cp -r "$tmpdir"/plugins/* "$PLUGINS_DIR"/   2>/dev/null || true

rm -rf "$tmpdir"

echo "ECD_VERSION=$latest_tag" >> "$GITHUB_ENV"
echo "[INFO] ECD $latest_tag installed into ${ECLIPSE_ROOT%/}."

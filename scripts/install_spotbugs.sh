#!/usr/bin/env bash
set -euo pipefail

: "${ECLIPSE_ROOT:?}"

PLUGINS_DIR="${ECLIPSE_ROOT%/}/plugins"
FEATURES_DIR="${ECLIPSE_ROOT%/}/features"
mkdir -p "$PLUGINS_DIR" "$FEATURES_DIR"

# Find latest release tag from GitHub API
echo "[INFO] Fetching latest SpotBugs release..."
latest_json="$(curl -s https://api.github.com/repos/spotbugs/spotbugs/releases/latest)"
version="$(echo "$latest_json" | jq -r .tag_name)"
url="$(echo "$latest_json" | jq -r '.assets[] | select(.name=="eclipsePlugin.zip") | .browser_download_url')"

if [[ -z "$url" ]]; then
  echo "[ERROR] Could not find eclipsePlugin.zip in latest SpotBugs release"
  exit 1
fi

echo "[INFO] Downloading SpotBugs $version from $url ..."
tmpdir="$(mktemp -d)"
curl -L -o "$tmpdir/eclipsePlugin.zip" "$url"

echo "[INFO] Extracting into ${ECLIPSE_ROOT%/} ..."
unzip -q "$tmpdir/eclipsePlugin.zip" -d "$ECLIPSE_ROOT"

rm -rf "$tmpdir"
echo "[INFO] SpotBugs $version installed into ${ECLIPSE_ROOT%/}."

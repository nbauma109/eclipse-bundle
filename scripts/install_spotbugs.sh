#!/usr/bin/env bash
set -euo pipefail

: "${DROPINS_ROOT:?}"

PLUGINS_DIR="${DROPINS_ROOT%/}/plugins"
FEATURES_DIR="${DROPINS_ROOT%/}/features"
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

echo "[INFO] Extracting into dropins ..."
unzip -q "$tmpdir/eclipsePlugin.zip" -d "$DROPINS_ROOT"

rm -rf "$tmpdir"
echo "[INFO] SpotBugs $version installed into dropins."

#!/usr/bin/env bash
set -euo pipefail

: "${SONARLINT_VERSION:?}"
: "${DROPINS_ROOT:?}"

PLUGINS_DIR="${DROPINS_ROOT%/}/plugins"
FEATURES_DIR="${DROPINS_ROOT%/}/features"
mkdir -p "$PLUGINS_DIR" "$FEATURES_DIR"

ZIP_URL="https://binaries.sonarsource.com/SonarLint-for-Eclipse/releases/org.sonarlint.eclipse.site-${SONARLINT_VERSION}.zip"
echo "[INFO] Downloading SonarLint site zip: $ZIP_URL"
curl -fL --retry 5 -o /tmp/sonarlint.zip "$ZIP_URL"

echo "[INFO] Extracting SonarLint features/plugins into dropins..."
unzip -q -o /tmp/sonarlint.zip 'features/*' -d "$FEATURES_DIR/.."
unzip -q -o /tmp/sonarlint.zip 'plugins/*'  -d "$PLUGINS_DIR/.."

echo "[INFO] Pruning sloop jars and expanding Windows x64..."
# keep only windows.x64 sloop, remove others, and unzip it to folder of same name
find "$PLUGINS_DIR" -maxdepth 1 -type f -name 'org.sonarlint.eclipse.sloop.*.jar' ! -name '*windows.x64*.jar' -print -delete

SLOOP_JAR="$(find "$PLUGINS_DIR" -maxdepth 1 -type f -name 'org.sonarlint.eclipse.sloop.windows.x64_*.jar' | head -n1 || true)"
if [[ -z "$SLOOP_JAR" ]]; then
  echo "[WARN] No windows.x64 sloop jar found; continuing."
else
  SLOOP_DIR="${SLOOP_JAR%.jar}"
  rm -rf "$SLOOP_DIR"
  mkdir -p "$SLOOP_DIR"
  unzip -q -o "$SLOOP_JAR" -d "$SLOOP_DIR"
  rm -f "$SLOOP_JAR"
fi

echo "[INFO] SonarLint ready in dropins."

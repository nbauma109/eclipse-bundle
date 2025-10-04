#!/usr/bin/env bash
set -euo pipefail

: "${DROPINS_ROOT:?}"

PLUGINS_DIR="${DROPINS_ROOT%/}/plugins"
FEATURES_DIR="${DROPINS_ROOT%/}/features"
mkdir -p "$PLUGINS_DIR" "$FEATURES_DIR"

# Update-site repos (contain built features/ & plugins/)
REPOS=(
  "https://github.com/de-jcup/update-site-eclipse-bash-editor"
  "https://github.com/de-jcup/update-site-eclipse-sql-editor"
  "https://github.com/de-jcup/update-site-eclipse-jenkins-editor"
  "https://github.com/de-jcup/update-site-eclipse-yaml-editor"
  "https://github.com/de-jcup/update-site-eclipse-batch-editor"
  "https://github.com/de-jcup/update-site-eclipse-hijson-editor"
  "https://github.com/de-jcup/update-site-egradle"
)

for repo in "${REPOS[@]}"; do
  name="$(basename "$repo")"
  echo "[INFO] Cloning $repo ..."
  tmpdir="$(mktemp -d)"
  git clone --depth 1 "$repo" "$tmpdir" >/dev/null 2>&1

  # most of these repos publish the site in ./update-site/
  site="$tmpdir/update-site"
  if [[ ! -d "$site" ]]; then
    # fallback: sometimes it's directly at repo root
    site="$tmpdir"
  fi

  # copy jars if present
  if [[ -d "$site/plugins" ]]; then
    find "$site/plugins" -maxdepth 1 -type f -name '*.jar' -print -exec cp -f {} "$PLUGINS_DIR/" \;
  else
    echo "[WARN] No plugins/ in $repo"
  fi

  if [[ -d "$site/features" ]]; then
    find "$site/features" -maxdepth 1 -type f -name '*.jar' -print -exec cp -f {} "$FEATURES_DIR/" \;
  else
    echo "[WARN] No features/ in $repo"
  fi

  rm -rf "$tmpdir"
done

echo "[INFO] de.jcup editors copied to dropins."

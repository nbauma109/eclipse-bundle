#!/usr/bin/env bash
set -euo pipefail

: "${DROPINS_ROOT:?}"

PLUGINS_DIR="${DROPINS_ROOT%/}/plugins"
FEATURES_DIR="${DROPINS_ROOT%/}/features"
mkdir -p "$PLUGINS_DIR" "$FEATURES_DIR"

# GitHub repos (update-site projects)
REPOS=(
  "de-jcup/update-site-eclipse-bash-editor"
  "de-jcup/update-site-eclipse-sql-editor"
  "de-jcup/update-site-eclipse-jenkins-editor"
  "de-jcup/update-site-eclipse-yaml-editor"
  "de-jcup/update-site-eclipse-batch-editor"
  "de-jcup/update-site-eclipse-hijson-editor"
  "de-jcup/update-site-egradle"
)

download_and_unzip_repo() {
  local slug="$1"   # e.g., de-jcup/update-site-eclipse-bash-editor
  local tmpdir; tmpdir="$(mktemp -d)"
  # Use default branch tarball (zip)
  local url="https://codeload.github.com/${slug}/zip/refs/heads/main"
  echo "[INFO] Downloading ${slug} (main)..."
  if ! curl -fsSL -o "${tmpdir}/repo.zip" "$url"; then
    # fallback to master if main doesn't exist
    url="https://codeload.github.com/${slug}/zip/refs/heads/master"
    echo "[INFO] Fallback to ${slug} (master)..."
    curl -fsSL -o "${tmpdir}/repo.zip" "$url"
  fi
  unzip -q "${tmpdir}/repo.zip" -d "${tmpdir}"
  # Find the extracted top-level directory
  local top; top="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  echo "$top"
}

pick_latest_and_copy() {
  local SRC_DIR="$1"   # path containing jars
  local DEST_DIR="$2"

  [[ -d "$SRC_DIR" ]] || { echo "[WARN] Missing $SRC_DIR"; return 0; }

  # Build rows: base|version|path (ignore source bundles)
  mapfile -t rows < <(
    find "$SRC_DIR" -maxdepth 1 -type f -name '*.jar' ! -name '*source_*.jar' -printf '%p\n' \
    | awk '
      function bn(p,  n){n=split(p,a,"/");return a[n]}
      {
        f=bn($0)
        if (match(f, /^(.*)_([^_]+)\.jar$/, m)) {
          print m[1] "|" m[2] "|" $0
        }
      }'
  )

  [[ ${#rows[@]} -gt 0 ]] || { echo "[WARN] No jars in $SRC_DIR"; return 0; }

  # Keep the highest version per base
  mapfile -t latest < <(
    printf '%s\n' "${rows[@]}" \
    | sort -t'|' -k1,1 -k2,2V \
    | awk -F'|' '{last[$1]=$0} END{for(k in last)print last[k]}'
  )

  for line in "${latest[@]}"; do
    IFS='|' read -r base ver path <<<"$line"
    echo "[INFO]   + ${base}_${ver}.jar"
    install -D -m 0644 "$path" "${DEST_DIR}/${base}_${ver}.jar"
  done
}

for slug in "${REPOS[@]}"; do
  work="$(download_and_unzip_repo "$slug")"
  # Most of these have update-site under ./update-site
  site="$work/update-site"
  [[ -d "$site" ]] || site="$work"

  echo "[INFO] Processing ${slug} ..."
  pick_latest_and_copy "$site/plugins"  "$PLUGINS_DIR"
  pick_latest_and_copy "$site/features" "$FEATURES_DIR"

  rm -rf "$(dirname "$work")"
done

echo "[INFO] de.jcup editors installed from tarballs."

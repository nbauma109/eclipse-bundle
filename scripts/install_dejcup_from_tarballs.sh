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
  local slug="$1"  # e.g., de-jcup/update-site-eclipse-yaml-editor
  local tmpdir; tmpdir="$(mktemp -d)"
  local zip="$tmpdir/repo.zip"

  local url="https://github.com/${slug}/archive/refs/heads/main.zip"
  echo "[INFO] Downloading ${slug} (main.zip)..."
  curl -fL --retry 5 -o "$zip" "$url"

  unzip -q "$zip" -d "$tmpdir"

  # Find extracted top-level folder: <repo>-main/
  local top
  top="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  if [[ -z "$top" ]]; then
    echo "[ERROR] Could not locate extracted folder for ${slug}"
    rm -rf "$tmpdir"
    exit 1
  fi

  printf '%s\n' "$top"
}

pick_latest_and_copy() {
  local SRC_DIR="$1"   # path containing jars
  local DEST_DIR="$2"
  local label="$3"

  if [[ ! -d "$SRC_DIR" ]]; then
    echo "[ERROR] Missing $label directory: $SRC_DIR"
    return 2
  fi

  # Build rows: base|version|path (ignore source bundles)
  mapfile -t rows < <(
    find "$SRC_DIR" -maxdepth 1 -type f -name '*.jar' ! -name '*source_*.jar' -printf '%p\n' \
    | awk '
      function bn(p,  n){n=split(p,a,"/");return a[n]}
      {
        f=bn($0);
        if (match(f, /^(.*)_([^_]+)\.jar$/, m)) {
          print m[1] "|" m[2] "|" $0
        }
      }'
  )

  if [[ ${#rows[@]} -eq 0 ]]; then
    echo "[ERROR] No JARs found in $SRC_DIR"
    return 3
  fi

  # Keep highest version per artifact (natural version sort)
  mapfile -t latest < <(
    printf '%s\n' "${rows[@]}" \
    | sort -t'|' -k1,1 -k2,2V \
    | awk -F'|' '{last[$1]=$0} END{for (k in last) print last[k]}'
  )

  local copied=0
  for line in "${latest[@]}"; do
    IFS='|' read -r base ver path <<<"$line"
    install -D -m 0644 "$path" "${DEST_DIR}/${base}_${ver}.jar"
    echo "[INFO]   + ${base}_${ver}.jar"
    ((copied++)) || true
  done
  echo "[INFO] Copied $copied JAR(s) from $label."
}

overall_fail=0

for slug in "${REPOS[@]}"; do
  echo "[INFO] Processing ${slug} ..."
  top="$(download_and_unzip_repo "$slug")"

  # Site content is usually under update-site/, sometimes at repo root
  site="$top/update-site"
  [[ -d "$site" ]] || site="$top"

  errcount=0
  pick_latest_and_copy "$site/plugins"  "$PLUGINS_DIR"  "${slug} plugins"  || ((errcount++))
  pick_latest_and_copy "$site/features" "$FEATURES_DIR" "${slug} features" || ((errcount++))

  if [[ $errcount -ge 2 ]]; then
    echo "[ERROR] ${slug}: neither plugins nor features JARs were found."
    overall_fail=1
  fi

  rm -rf "$(dirname "$top")"
done

if [[ $overall_fail -ne 0 ]]; then
  echo "[ERROR] One or more de.jcup update-site archives did not contain features/plugins."
  exit 1
fi

echo "[INFO] de.jcup editors installed from tarballs."

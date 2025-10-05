#!/usr/bin/env bash
set -euo pipefail

: "${ECLIPSE_ROOT:?}"

PLUGINS_DIR="${ECLIPSE_ROOT%/}/plugins"
FEATURES_DIR="${ECLIPSE_ROOT%/}/features"
mkdir -p "$PLUGINS_DIR" "$FEATURES_DIR"

# Update-site repos (contain built features/ & plugins/ across versions)
REPOS=(
  "https://github.com/de-jcup/update-site-eclipse-bash-editor"
  "https://github.com/de-jcup/update-site-eclipse-sql-editor"
  "https://github.com/de-jcup/update-site-eclipse-jenkins-editor"
  "https://github.com/de-jcup/update-site-eclipse-yaml-editor"
  "https://github.com/de-jcup/update-site-eclipse-batch-editor"
  "https://github.com/de-jcup/update-site-eclipse-hijson-editor"
  "https://github.com/de-jcup/update-site-egradle"
)

pick_latest_and_copy() {
  local SRC_DIR="$1"   # e.g. /tmp/site/update-site/plugins
  local DEST_DIR="$2"  # e.g. eclipse/plugins

  [[ -d "$SRC_DIR" ]] || { echo "[WARN] Missing $SRC_DIR"; return 0; }

  # Build a table: base|version|fullpath for non-source jars
  # base = artifact id without trailing _<version>.jar
  mapfile -t rows < <(
    find "$SRC_DIR" -maxdepth 1 -type f -name '*.jar' ! -name '*source_*.jar' -printf '%p\n' \
    | awk '
      function basename(p,  n) { n=split(p,a,"/"); return a[n]; }
      {
        fn=basename($0);
        # match artifactID_version.jar (Eclipse/OSGi style)
        if (match(fn, /^(.*)_([^_]+)\.jar$/, m)) {
          base=m[1]; ver=m[2];
          printf("%s|%s|%s\n", base, ver, $0);
        }
      }' \
  )

  if [[ ${#rows[@]} -eq 0 ]]; then
    echo "[WARN] No jars found in $SRC_DIR"
    return 0
  fi

  # Group by base and keep only the highest version (sort -V compares versions naturally)
  # We sort by base then by version; tail -1 per base gives latest
  mapfile -t latest < <(
    printf '%s\n' "${rows[@]}" \
    | sort -t'|' -k1,1 -k2,2V \
    | awk -F'|' '
        { last[$1]=$0 }             # overwrite with the highest (due to sort)
        END { for (k in last) print last[k] }
      '
  )

  # Copy winners
  for line in "${latest[@]}"; do
    IFS='|' read -r base ver path <<<"$line"
    echo "[INFO]   + ${base}_${ver}.jar"
    install -D -m 0644 "$path" "$DEST_DIR/${base}_${ver}.jar"
  done
}

for repo in "${REPOS[@]}"; do
  name="$(basename "$repo")"
  echo "[INFO] Cloning $repo ..."
  tmpdir="$(mktemp -d)"
  git clone --depth 1 "$repo" "$tmpdir" >/dev/null 2>&1 || {
    echo "[ERROR] clone failed: $repo"
    rm -rf "$tmpdir"
    exit 1
  }

  # Most de-jcup update sites publish under ./update-site/
  site="$tmpdir/update-site"
  [[ -d "$site" ]] || site="$tmpdir"

  echo "[INFO] Scanning latest jars in $name ..."
  pick_latest_and_copy "$site/plugins"  "$PLUGINS_DIR"
  pick_latest_and_copy "$site/features" "$FEATURES_DIR"

  rm -rf "$tmpdir"
done

echo "[INFO] de.jcup editors (latest versions) copied to ${ECLIPSE_ROOT%/}."

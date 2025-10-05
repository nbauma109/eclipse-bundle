#!/usr/bin/env bash
set -euo pipefail

: "${ECLIPSE_ROOT:?}"

PLUGINS_DIR="${ECLIPSE_ROOT%/}/plugins"
FEATURES_DIR="${ECLIPSE_ROOT%/}/features"
mkdir -p "$PLUGINS_DIR" "$FEATURES_DIR"

REPOS=(
  "https://github.com/de-jcup/update-site-eclipse-bash-editor"
  "https://github.com/de-jcup/update-site-eclipse-sql-editor"
  "https://github.com/de-jcup/update-site-eclipse-jenkins-editor"
  "https://github.com/de-jcup/update-site-eclipse-yaml-editor"
  "https://github.com/de-jcup/update-site-eclipse-batch-editor"
  "https://github.com/de-jcup/update-site-eclipse-hijson-editor"
  "https://github.com/de-jcup/update-site-egradle"
)

# label mapping for nice names
label_for() {
  case "$1" in
    update-site-eclipse-bash-editor)     echo "Bash Editor" ;;
    update-site-eclipse-sql-editor)      echo "SQL Editor" ;;
    update-site-eclipse-jenkins-editor)  echo "Jenkins Editor" ;;
    update-site-eclipse-yaml-editor)     echo "YAML Editor" ;;
    update-site-eclipse-batch-editor)    echo "Batch Editor" ;;
    update-site-eclipse-hijson-editor)   echo "HiJSON Editor" ;;
    update-site-egradle)                 echo "eGradle" ;;
    *)                                   echo "$1" ;;
  esac
}

# Accumulate versions per label (avoid duplicates). We’ll print one line per label.
# Using a temp file to avoid bash 3 assoc arrays issues on some runners.
VERS_TMP="$(mktemp)"
trap 'rm -f "$VERS_TMP"' EXIT
# format per line: <label>|<version>

pick_latest_and_copy() {
  local SRC_DIR="$1" DEST_DIR="$2" LABEL="$3"
  [[ -d "$SRC_DIR" ]] || { echo "[WARN] Missing $SRC_DIR"; return 0; }

  mapfile -t rows < <(
    find "$SRC_DIR" -maxdepth 1 -type f -name '*.jar' ! -name '*source_*.jar' -printf '%p\n' \
    | awk '
      function bn(p,  n){ n=split(p,a,"/"); return a[n]; }
      {
        f=bn($0);
        if (match(f, /^(.*)_([^_]+)\.jar$/, m)) {
          base=m[1]; ver=m[2];
          printf("%s|%s|%s\n", base, ver, $0);
        }
      }'
  )

  [[ ${#rows[@]} -gt 0 ]] || { echo "[WARN] No jars in $SRC_DIR"; return 0; }

  mapfile -t latest < <(
    printf '%s\n' "${rows[@]}" \
    | sort -t'|' -k1,1 -k2,2V \
    | awk -F'|' '{ last[$1]=$0 } END{ for(k in last) print last[k] }'
  )

  # Track candidate versions seen for this label in this SRC_DIR
  local seen_versions=()

  for line in "${latest[@]}"; do
    IFS='|' read -r base ver path <<<"$line"
    echo "[INFO]   + ${base}_${ver}.jar"
    install -D -m 0644 "$path" "$DEST_DIR/${base}_${ver}.jar"
    seen_versions+=("$ver")
  done

  # Record *all* versions we saw for this label; we’ll collapse to max later.
  if [[ ${#seen_versions[@]} -gt 0 ]]; then
    for v in "${seen_versions[@]}"; do
      printf '%s|%s\n' "$LABEL" "$v" >> "$VERS_TMP"
    done
  fi
}

for repo in "${REPOS[@]}"; do
  name="$(basename "$repo")"
  label="$(label_for "$name")"

  echo "[INFO] Cloning $repo ..."
  tmpdir="$(mktemp -d)"
  if ! git clone --depth 1 "$repo" "$tmpdir" >/dev/null 2>&1; then
    echo "[ERROR] clone failed: $repo"
    rm -rf "$tmpdir"
    exit 1
  fi

  site="$tmpdir/update-site"
  [[ -d "$site" ]] || site="$tmpdir"

  echo "[INFO] Scanning latest jars in $name ..."
  pick_latest_and_copy "$site/plugins"  "$PLUGINS_DIR"  "$label"
  pick_latest_and_copy "$site/features" "$FEATURES_DIR" "$label"

  rm -rf "$tmpdir"
done

# Collapse to a single highest version per label and export for notes
if [[ -s "$VERS_TMP" ]]; then
  # sort by label then version, keep the highest version per label
  mapfile -t lines < <(
    sort -t'|' -k1,1 -k2,2V "$VERS_TMP" \
    | awk -F'|' '{ last[$1]=$2 } END{ for (k in last) printf "- %s: %s\n", k, last[k] }' \
    | sort
  )
  if [[ ${#lines[@]} -gt 0 ]]; then
    md_joined="$(printf '%s\\n' "${lines[@]}")"
    echo "DEJCUP_VERSION_LINES=$md_joined" >> "$GITHUB_ENV"
  fi
fi

echo "[INFO] de.jcup editors installed."

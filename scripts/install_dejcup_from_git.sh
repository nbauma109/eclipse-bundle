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

# We’ll accumulate pretty markdown lines like:
#   - YAML Editor: de.jcup.yamleditor 1.9.0
MD_LINES=()

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
    printf '%s\n' "${rows[@]}" | sort -t'|' -k1,1 -k2,2V | awk -F'|' '{ last[$1]=$0 } END{ for(k in last) print last[k] }'
  )

  # Track the highest *feature* and *bundle* versions per label (best-effort)
  local feat_ver="" bund_ver=""

  for line in "${latest[@]}"; do
    IFS='|' read -r base ver path <<<"$line"
    echo "[INFO]   + ${base}_${ver}.jar"
    install -D -m 0644 "$path" "$DEST_DIR/${base}_${ver}.jar"

    # heuristics to expose nice versions in notes
    if [[ "$base" == *".feature" || "$base" == *".feature.feature" || "$base" == *".feature.feature.group" ]]; then
      feat_ver="$ver"
    else
      # prefer the main plugin id (often without .feature)
      bund_ver="$ver"
    fi
  done

  # Prefer feature version if present, else a bundle version
  local shown_ver="${feat_ver:-${bund_ver:-}}"
  if [[ -n "$shown_ver" && -n "$LABEL" ]]; then
    MD_LINES+=("- ${LABEL}: ${shown_ver}")
  fi
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

  site="$tmpdir/update-site"
  [[ -d "$site" ]] || site="$tmpdir"

  case "$name" in
    update-site-eclipse-bash-editor)     label="Bash Editor" ;;
    update-site-eclipse-sql-editor)      label="SQL Editor" ;;
    update-site-eclipse-jenkins-editor)  label="Jenkins Editor" ;;
    update-site-eclipse-yaml-editor)     label="YAML Editor" ;;
    update-site-eclipse-batch-editor)    label="Batch Editor" ;;
    update-site-eclipse-hijson-editor)   label="HiJSON Editor" ;;
    update-site-egradle)                 label="eGradle" ;;
    *)                                   label="$name" ;;
  esac

  echo "[INFO] Scanning latest jars in $name ..."
  pick_latest_and_copy "$site/plugins"  "$PLUGINS_DIR"  "$label"
  pick_latest_and_copy "$site/features" "$FEATURES_DIR" "$label"

  rm -rf "$tmpdir"
done

# Export markdown lines for release notes (single-line env, with \n)
if [[ ${#MD_LINES[@]} -gt 0 ]]; then
  # join with literal \n so it survives as an env var
  md_joined="$(printf '%s\\n' "${MD_LINES[@]}")"
  echo "DEJCUP_VERSION_LINES=$md_joined" >> "$GITHUB_ENV"
fi

echo "[INFO] de.jcup editors installed."

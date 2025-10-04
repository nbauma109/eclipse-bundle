#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/common.sh"

eclipse="${LINUX_ECLIPSE_DIR:?}/eclipse"

list_ius() {
  local repo="$1"
  # List available IUs (features) in this repo
  "$eclipse" -nosplash -application org.eclipse.equinox.p2.director \
    -repository "$repo" -list \
    || { err "p2 director -list failed for $repo"; return 1; }
}

find_iu_from_list() {
  # $1 = iu list (stdin), $2.. = patterns to try
  local iu_list; iu_list="$(cat)"
  shift || true
  local pat
  for pat in "$@"; do
    # search safely; don't trip pipefail if no match
    local found
    found="$(printf '%s\n' "$iu_list" \
      | awk '/feature\.group/ {print $1}' \
      | grep -E "^${pat}$" || true)"
    if [[ -n "$found" ]]; then
      printf '%s' "$found" | head -n1
      return 0
    fi
  done
  # If we’re here, not found; print a short debug list
  echo "---- DEBUG: first 50 feature IUs in repo ----" >&2
  printf '%s\n' "$iu_list" \
    | awk '/feature\.group/ {print $1}' \
    | head -n50 >&2 || true
  echo "---- DEBUG END ----" >&2
  return 1
}

# p2 sites (fixed / overridable via env)
BASH_REPO="${BASH_REPO:-https://de-jcup.github.io/update-site-eclipse-bash-editor/update-site/}"
SQL_REPO="${SQL_REPO:-https://de-jcup.github.io/update-site-eclipse-sql-editor/update-site/}"
JENKINS_REPO="${JENKINS_REPO:-https://de-jcup.github.io/update-site-eclipse-jenkins-editor/update-site/}"
YAML_REPO="${YAML_REPO:-https://de-jcup.github.io/update-site-eclipse-yaml-editor/update-site/}"
BAT_REPO="${BAT_REPO:-https://de-jcup.github.io/update-site-eclipse-batch-editor/update-site/}"
HIJSON_REPO="${HIJSON_REPO:-https://de-jcup.github.io/update-site-eclipse-hijson-editor/update-site/}"
EGRADLE_REPO="${EGRADLE_REPO:-https://de-jcup.github.io/update-site-egradle/update-site/}"
SONAR_REPO="${SONAR_REPO:?}"

# Cache the IU lists up front
log "Listing IUs from SonarLint repo..."
SONAR_LIST="$(list_ius "$SONAR_REPO")"

log "Listing IUs from de.jcup repos..."
BASH_LIST="$(list_ius "$BASH_REPO")"
SQL_LIST="$(list_ius "$SQL_REPO")"
JENKINS_LIST="$(list_ius "$JENKINS_REPO")"
YAML_LIST="$(list_ius "$YAML_REPO")"
BAT_LIST="$(list_ius "$BAT_REPO")"
HIJSON_LIST="$(list_ius "$HIJSON_REPO")"
EGRADLE_LIST="$(list_ius "$EGRADLE_REPO")"

# Find IU IDs (try exact → broader patterns)
log "Resolving IU IDs..."

# SonarLint
SONAR_IU="$(
  printf '%s' "$SONAR_LIST" | find_iu_from_list \
    'org\.sonarlint\.eclipse\.feature\.feature\.group' \
    'org\.sonarlint\.eclipse\.feature(\.feature)?\.group'
)"

# de.jcup editors
BASH_IU="$(
  printf '%s' "$BASH_LIST" | find_iu_from_list \
    'de\.jcup\.basheditor\.feature\.group' \
    'de\.jcup\..*basheditor.*feature\.group'
)"
SQL_IU="$(
  printf '%s' "$SQL_LIST" | find_iu_from_list \
    'de\.jcup\.sqleditor\.feature\.group' \
    'de\.jcup\..*sql.*editor.*feature\.group'
)"
JENKINS_IU="$(
  printf '%s' "$JENKINS_LIST" | find_iu_from_list \
    'de\.jcup\.jenkinseditor\.feature\.group' \
    'de\.jcup\..*jenkins.*editor.*feature\.group'
)"
YAML_IU="$(
  printf '%s' "$YAML_LIST" | find_iu_from_list \
    'de\.jcup\.yamleditor\.feature\.group' \
    'de\.jcup\..*yaml.*editor.*feature\.group'
)"
BAT_IU="$(
  printf '%s' "$BAT_LIST" | find_iu_from_list \
    'de\.jcup\.batcheditor\.feature\.group' \
    'de\.jcup\..*(batch|bat).*editor.*feature\.group'
)"
HIJSON_IU="$(
  printf '%s' "$HIJSON_LIST" | find_iu_from_list \
    'de\.jcup\.hijson\.feature\.group' \
    'de\.jcup\..*(hijson|json).*feature\.group'
)"
EGRADLE_IU="$(
  printf '%s' "$EGRADLE_LIST" | find_iu_from_list \
    'de\.jcup\.egradle(\.eclipse)?\.feature\.group' \
    'de\.jcup\..*egradle.*feature\.group'
)"

# Validate and export
for v in SONAR_IU BASH_IU SQL_IU JENKINS_IU YAML_IU BAT_IU HIJSON_IU EGRADLE_IU; do
  if [[ -z "${!v:-}" ]]; then
    err "Failed to resolve $v (see debug above)"
    exit 1
  fi
  echo "$v=${!v}" >> "$GITHUB_ENV"
done

# Also (re)export repos so the next script has them for -repository
echo "SONAR_REPO=$SONAR_REPO"   >> "$GITHUB_ENV"
echo "BASH_REPO=$BASH_REPO"     >> "$GITHUB_ENV"
echo "SQL_REPO=$SQL_REPO"       >> "$GITHUB_ENV"
echo "JENKINS_REPO=$JENKINS_REPO" >> "$GITHUB_ENV"
echo "YAML_REPO=$YAML_REPO"     >> "$GITHUB_ENV"
echo "BAT_REPO=$BAT_REPO"       >> "$GITHUB_ENV"
echo "HIJSON_REPO=$HIJSON_REPO" >> "$GITHUB_ENV"
echo "EGRADLE_REPO=$EGRADLE_REPO" >> "$GITHUB_ENV"

log "Resolved IUs:
  SONAR_IU=$SONAR_IU
  BASH_IU=$BASH_IU
  SQL_IU=$SQL_IU
  JENKINS_IU=$JENKINS_IU
  YAML_IU=$YAML_IU
  BAT_IU=$BAT_IU
  HIJSON_IU=$HIJSON_IU
  EGRADLE_IU=$EGRADLE_IU"

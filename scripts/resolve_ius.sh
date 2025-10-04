#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/common.sh"

eclipse="${LINUX_ECLIPSE_DIR:?}/eclipse"

resolve_iu () {
  local repo="$1" pattern="$2"
  "$eclipse" -nosplash -application org.eclipse.equinox.p2.director \
    -repository "$repo" -list \
  | awk '/feature\.group/ {print $1}' \
  | grep -Ei "$pattern" | head -n1
}

# p2 sites (fixed)
BASH_REPO="${BASH_REPO:-https://de-jcup.github.io/update-site-eclipse-bash-editor/update-site/}"
SQL_REPO="${SQL_REPO:-https://de-jcup.github.io/update-site-eclipse-sql-editor/update-site/}"
JENKINS_REPO="${JENKINS_REPO:-https://de-jcup.github.io/update-site-eclipse-jenkins-editor/update-site/}"
YAML_REPO="${YAML_REPO:-https://de-jcup.github.io/update-site-eclipse-yaml-editor/update-site/}"
BAT_REPO="${BAT_REPO:-https://de-jcup.github.io/update-site-eclipse-batch-editor/update-site/}"
HIJSON_REPO="${HIJSON_REPO:-https://de-jcup.github.io/update-site-eclipse-hijson-editor/update-site/}"
EGRADLE_REPO="${EGRADLE_REPO:-https://de-jcup.github.io/update-site-egradle/update-site/}"

echo "BASH_REPO=$BASH_REPO"       >> "$GITHUB_ENV"
echo "SQL_REPO=$SQL_REPO"         >> "$GITHUB_ENV"
echo "JENKINS_REPO=$JENKINS_REPO" >> "$GITHUB_ENV"
echo "YAML_REPO=$YAML_REPO"       >> "$GITHUB_ENV"
echo "BAT_REPO=$BAT_REPO"         >> "$GITHUB_ENV"
echo "HIJSON_REPO=$HIJSON_REPO"   >> "$GITHUB_ENV"
echo "EGRADLE_REPO=$EGRADLE_REPO" >> "$GITHUB_ENV"

sonar_repo="${SONAR_REPO:?}"
SONAR_IU="$(resolve_iu "$sonar_repo" '^org\.sonarlint\.eclipse\.feature\.feature\.group$')"
BASH_IU="$(resolve_iu "$BASH_REPO" 'basheditor.*feature\.group')"
SQL_IU="$(resolve_iu "$SQL_REPO" 'sqleditor.*feature\.group')"
JENKINS_IU="$(resolve_iu "$JENKINS_REPO" 'jenkins.*editor.*feature\.group')"
YAML_IU="$(resolve_iu "$YAML_REPO" 'yaml.*editor.*feature\.group')"
BAT_IU="$(resolve_iu "$BAT_REPO" '(batch|bat).*editor.*feature\.group')"
HIJSON_IU="$(resolve_iu "$HIJSON_REPO" '(hijson|json).*feature\.group')"
EGRADLE_IU="$(resolve_iu "$EGRADLE_REPO" 'egradle.*feature\.group')"

for v in SONAR_IU BASH_IU SQL_IU JENKINS_IU YAML_IU BAT_IU HIJSON_IU EGRADLE_IU; do
  [ -n "${!v:-}" ] || { err "Failed to resolve $v"; exit 1; }
  echo "$v=${!v}" >> "$GITHUB_ENV"
done

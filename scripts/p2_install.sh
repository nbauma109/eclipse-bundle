#!/usr/bin/env bash
set -euo pipefail

eclipse="${LINUX_ECLIPSE_DIR:?}/eclipse"

# Ensure SIMREL_REPO is present (from get_train.sh)
: "${SIMREL_REPO:?Missing SIMREL_REPO; run scripts/get_train.sh first}"

# Put SimRel first so core deps resolve there; others follow
repos="$(IFS=,; echo \
  "${SIMREL_REPO}",\
"${SONAR_REPO:?}",\
"${BASH_REPO:?}",\
"${SQL_REPO:?}",\
"${JENKINS_REPO:?}",\
"${YAML_REPO:?}",\
"${BAT_REPO:?}",\
"${HIJSON_REPO:?}",\
"${EGRADLE_REPO:?}")"

ius="$(IFS=,; echo \
  "${SONAR_IU:?}",\
"${BASH_IU:?}",\
"${SQL_IU:?}",\
"${JENKINS_IU:?}",\
"${YAML_IU:?}",\
"${BAT_IU:?}",\
"${HIJSON_IU:?}",\
"${EGRADLE_IU:?}")"

"$eclipse" -nosplash -application org.eclipse.equinox.p2.director \
  -repository "$repos" \
  -installIU "$ius" \
  -profile SDKProfile \
  -profileProperties org.eclipse.update.install.features=true \
  -destination "$(dirname "$eclipse")" \
  -roaming

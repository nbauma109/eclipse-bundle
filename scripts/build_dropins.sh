#!/usr/bin/env bash
set -euo pipefail

root="${LINUX_ECLIPSE_DIR:?}"
mkdir -p dropins/custom/eclipse/plugins dropins/custom/eclipse/features
rsync -a "$root/plugins/"  "dropins/custom/eclipse/plugins/"
rsync -a "$root/features/" "dropins/custom/eclipse/features/"
echo "DROPINS_DIR=$(pwd)/dropins" >> "$GITHUB_ENV"

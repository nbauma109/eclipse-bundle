#!/usr/bin/env bash
set -euo pipefail

cat > RELEASE_NOTES.md <<EOF
Eclipse IDE for Java Developers (Windows x64) — bundled via dropins (no p2)

Includes:
- SonarLint ${SONARLINT_VERSION} (from official zipped update site)
- de.jcup editors: Bash, SQL, YAML, Jenkins, Batch (BAT), HiJSON, EGradle
  (copied from their update-site GitHub repos)

Build details:
- Eclipse train: ${TRAIN}

Usage:
- Unzip and run \`eclipse.exe\`
EOF

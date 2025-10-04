#!/usr/bin/env bash
set -euo pipefail

cat > RELEASE_NOTES.md <<EOF
Eclipse IDE for Java Developers (Windows x64) — bundled via dropins

Includes:
- SonarLint ${SONARLINT_VERSION} (versioned p2 repo)
- de.jcup editors: Bash, SQL, YAML, Jenkins, Batch (BAT), HiJSON, EGradle

Build details:
- Eclipse train: ${TRAIN}

Usage:
- Unzip and run \`eclipse.exe\`
EOF

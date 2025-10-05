#!/usr/bin/env bash
set -euo pipefail

: "${TRAIN:?}"
: "${SONARLINT_VERSION:?}"

cat > RELEASE_NOTES.md <<EOF
# Eclipse IDE for Java Developers (Windows x64)

This distribution is built from the Eclipse \`${TRAIN}\` train and bundles a focused set of plugins preinstalled for Java development.

## Included plugins

- **SonarLint** ${SONARLINT_VERSION}
- **SpotBugs**
- **de.jcup editors**:
  - Bash
  - SQL
  - Jenkins
  - YAML
  - Batch (BAT)
  - HiJSON
  - EGradle

## Usage

1. Download the attached ZIP (\`eclipse-java-${TRAIN}-R-win32-x86_64-with-plugins.zip\`).
2. Extract it anywhere on Windows.
3. Run \`eclipse.exe\`.

All listed plugins are included and ready to use.
EOF

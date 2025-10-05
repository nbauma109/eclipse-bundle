#!/usr/bin/env bash
set -euo pipefail

: "${TRAIN:?}"
: "${SONARLINT_VERSION:?}"

# Optional envs (may be empty)
SPOTBUGS_VERSION="${SPOTBUGS_VERSION:-}"
ECD_VERSION="${ECD_VERSION:-}"
DEJCUP_VERSION_LINES="${DEJCUP_VERSION_LINES:-}"

cat > RELEASE_NOTES.md <<EOF
# Eclipse IDE for Java Developers (Windows x64)

This distribution is built from the Eclipse \`${TRAIN}\` train and bundles a focused set of plugins preinstalled for Java development.

## Included plugins (versions)

- **SonarLint** ${SONARLINT_VERSION}
- **SpotBugs** ${SPOTBUGS_VERSION:-(latest)}
- **Enhanced Class Decompiler (ECD)** ${ECD_VERSION:-(latest)}
- **de.jcup editors**
$( if [[ -n "$DEJCUP_VERSION_LINES" ]]; then
     # expand literal '\n' into newlines
     printf '%b' "$(printf '%s' "$DEJCUP_VERSION_LINES" | sed 's/\\n/\n/g' | sed 's/^/  /')"
   else
     echo "  - (versions detected at build time)"
   fi
)

## Usage

1. Download the attached ZIP (\`eclipse-java-${TRAIN}-R-win32-x86_64-with-plugins.zip\`).
2. Extract it anywhere on Windows.
3. Run \`eclipse.exe\`.

All listed plugins are included and ready to use.
EOF

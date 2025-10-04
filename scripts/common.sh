#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

log() { printf "\n[\033[1;36mINFO\033[0m] %s\n" "$*"; }
err() { printf "\n[\033[1;31mERROR\033[0m] %s\n" "$*" >&2; }

pick_and_download () {
  local base="$1" file="$2" out="$3"
  local xml_url="https://www.eclipse.org/downloads/download.php?file=${base}/${file}&format=xml"
  log "Fetching mirrors: $xml_url"
  local mirrors
  mirrors="$(curl -fsSL "$xml_url" | grep -oP '(?<=url=").*?(?=")')" || true
  if [ -z "${mirrors:-}" ]; then err "No mirrors found for ${file}"; return 1; fi
  local url
  for url in $mirrors; do
    log "Trying $url"
    if curl -fSL --retry 3 --connect-timeout 20 "$url" -o "$out"; then
      log "Downloaded $out from $url"
      return 0
    fi
  done
  err "Failed to download $out from all mirrors"
  return 1
}

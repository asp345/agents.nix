#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

manifests=https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests

x64=$(curl -fsSL "$manifests/linux_amd64.json")
arm64=$(curl -fsSL "$manifests/linux_arm64.json")
version=$(jq -r .version <<<"$x64")

if [[ "$version" != "$(jq -r .version <<<"$arm64")" ]]; then
  echo "platform manifests report different versions" >&2
  exit 1
fi

if [[ "$version" == "$(jq -r .version sources.json)" ]]; then
  exit 0
fi

urls='{}'
hashes='{}'
for platform in linux-x64 linux-arm64; do
  case "$platform" in
    linux-x64) manifest=$x64 ;;
    linux-arm64) manifest=$arm64 ;;
  esac
  urls=$(jq --arg platform "$platform" --arg url "$(jq -r .url <<<"$manifest")" '.[$platform] = $url' <<<"$urls")
  sri=$(nix hash convert --hash-algo sha512 --to sri "$(jq -r .sha512 <<<"$manifest")")
  hashes=$(jq --arg platform "$platform" --arg hash "$sri" '.[$platform] = $hash' <<<"$hashes")
done

jq -n --arg version "$version" --argjson urls "$urls" --argjson hashes "$hashes" \
  '{version: $version, urls: $urls, hashes: $hashes}' >sources.json

#!/usr/bin/env bash
set -euo pipefail

version=$(curl -fsSL https://registry.npmjs.org/@earendil-works/pi-coding-agent/latest | jq -r .version)

if [[ "$version" == "$(jq -r .version sources.json)" ]]; then
  exit 0
fi

hashes='{}'
for platform in linux-x64 linux-arm64; do
  hash=$(nix store prefetch-file --json "https://github.com/earendil-works/pi/releases/download/v$version/pi-$platform.tar.gz" | jq -r .hash)
  hashes=$(jq --arg platform "$platform" --arg hash "$hash" '.[$platform] = $hash' <<<"$hashes")
done

jq -n --arg version "$version" --argjson hashes "$hashes" '{version: $version, hashes: $hashes}' >sources.json

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

base=https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases
version=$(curl -fsSL "$base/latest")

if [[ "$version" == "$(jq -r .version sources.json)" ]]; then
  exit 0
fi

manifest=$(curl -fsSL "$base/$version/manifest.json")

hashes='{}'
for platform in linux-x64 linux-arm64; do
  hex=$(jq -r --arg platform "$platform" '.platforms[$platform].checksum' <<<"$manifest")
  hash=$(nix hash convert --hash-algo sha256 --to sri "$hex")
  hashes=$(jq --arg platform "$platform" --arg hash "$hash" '.[$platform] = $hash' <<<"$hashes")
done

jq -n --arg version "$version" --argjson hashes "$hashes" '{version: $version, hashes: $hashes}' >sources.json

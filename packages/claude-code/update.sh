#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

registry=https://registry.npmjs.org/@anthropic-ai
version=$(curl -fsSL "$registry/claude-code/latest" | jq -r .version)

if [[ "$version" == "$(jq -r .version sources.json)" ]]; then
  exit 0
fi

hashes='{}'
for platform in linux-x64 linux-arm64; do
  hash=$(curl -fsSL "$registry/claude-code-$platform/$version" | jq -r .dist.integrity)
  hashes=$(jq --arg platform "$platform" --arg hash "$hash" '.[$platform] = $hash' <<<"$hashes")
done

jq -n --arg version "$version" --argjson hashes "$hashes" '{version: $version, hashes: $hashes}' >sources.json

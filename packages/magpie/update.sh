#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

version=$(curl -fsSL https://api.github.com/repos/yetone/magpie/releases/latest | jq -r .tag_name | sed 's/^v//')

if [[ "$version" == "$(jq -r .version sources.json)" ]]; then
  exit 0
fi

sums=$(curl -fsSL "https://github.com/yetone/magpie/releases/download/v$version/SHA256SUMS")

hashes='{}'
for asset in linux-amd64 linux-arm64; do
  hex=$(awk -v name="magpie-cli-$asset" '$2 == name { print $1 }' <<<"$sums")
  hash=$(nix hash convert --hash-algo sha256 --to sri "$hex")
  hashes=$(jq --arg asset "$asset" --arg hash "$hash" '.[$asset] = $hash' <<<"$hashes")
done

jq -n --arg version "$version" --argjson hashes "$hashes" '{version: $version, hashes: $hashes}' >sources.json

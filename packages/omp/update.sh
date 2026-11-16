#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

auth=()
[[ -n "${GH_TOKEN:-}" ]] && auth=(--oauth2-bearer "$GH_TOKEN")

version=$(curl -fsSL "${auth[@]}" https://api.github.com/repos/can1357/oh-my-pi/releases/latest | jq -r .tag_name | sed 's/^v//')

if [[ "$version" == "$(jq -r .version sources.json)" ]]; then
  exit 0
fi

sums=$(curl -fsSL "https://github.com/can1357/oh-my-pi/releases/download/v$version/SHA256SUMS.txt")

hashes='{}'
for platform in linux-x64 linux-arm64; do
  hex=$(awk -v name="omp-$platform" '$2 == name { print $1 }' <<<"$sums")
  hash=$(nix hash convert --hash-algo sha256 --to sri "$hex")
  hashes=$(jq --arg platform "$platform" --arg hash "$hash" '.[$platform] = $hash' <<<"$hashes")
done

jq -n --arg version "$version" --argjson hashes "$hashes" '{version: $version, hashes: $hashes}' >sources.json

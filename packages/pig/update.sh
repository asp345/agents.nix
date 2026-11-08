#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

release=$(curl -fsSL https://api.github.com/repos/MichaelKinsy/PiG/releases/latest)
version=$(jq -r .tag_name <<<"$release" | sed 's/^v//')

if [[ "$version" == "$(jq -r .version sources.json)" ]]; then
  exit 0
fi

hashes='{}'
for platform in linux-amd64 linux-arm64; do
  digest=$(jq -r --arg name "pig-$version-$platform.tar.gz" '.assets[] | select(.name == $name) | .digest' <<<"$release")
  hash=$(nix hash convert --hash-algo sha256 --to sri "${digest#sha256:}")
  hashes=$(jq --arg platform "$platform" --arg hash "$hash" '.[$platform] = $hash' <<<"$hashes")
done

jq -n --arg version "$version" --argjson hashes "$hashes" '{version: $version, hashes: $hashes}' >sources.json

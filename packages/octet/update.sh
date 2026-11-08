#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

release=$(curl -fsSL https://api.github.com/repos/skaft-software/octet/releases/latest)
version=$(jq -r .tag_name <<<"$release" | sed 's/^v//')

if [[ "$version" == "$(jq -r .version sources.json)" ]]; then
  exit 0
fi

digest=$(jq -r --arg name "octet-$version-x86_64-unknown-linux-gnu.tar.gz" '.assets[] | select(.name == $name) | .digest' <<<"$release")
hash=$(nix hash convert --hash-algo sha256 --to sri "${digest#sha256:}")

jq -n --arg version "$version" --arg hash "$hash" '{version: $version, hash: $hash}' >sources.json

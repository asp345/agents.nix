#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

platforms=(linux-x86_64 linux-arm64)

release=null
for page in {1..10}; do
  releases=$(curl -fsSL "https://api.github.com/repos/trycua/cua/releases?per_page=100&page=$page")
  release=$(jq --args '
    [.[] | select(.draft == false and (.tag_name | test("^cua-driver-rs-v[0-9]+\\.[0-9]+\\.[0-9]+$")))
      | (.tag_name | ltrimstr("cua-driver-rs-v")) as $version
      | select([.assets[].name] | contains($ARGS.positional | map("cua-driver-rs-\($version)-\(.)-binary.tar.gz")))]
    | max_by(.tag_name | ltrimstr("cua-driver-rs-v") | split(".") | map(tonumber))' "${platforms[@]}" <<<"$releases")
  if [[ "$release" != null || "$(jq length <<<"$releases")" -lt 100 ]]; then
    break
  fi
done
[[ "$release" != null ]]

version=$(jq -r '.tag_name | ltrimstr("cua-driver-rs-v")' <<<"$release")

if [[ "$version" == "$(jq -r .version sources.json)" ]]; then
  exit 0
fi

hashes='{}'
for platform in "${platforms[@]}"; do
  digest=$(jq -r --arg name "cua-driver-rs-$version-$platform-binary.tar.gz" '.assets[] | select(.name == $name) | .digest' <<<"$release")
  hash=$(nix hash convert --hash-algo sha256 --to sri "${digest#sha256:}")
  hashes=$(jq --arg platform "$platform" --arg hash "$hash" '.[$platform] = $hash' <<<"$hashes")
done

jq -n --arg version "$version" --argjson hashes "$hashes" '{version: $version, hashes: $hashes}' >sources.json

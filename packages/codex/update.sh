#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

auth=()
[[ -n "${GH_TOKEN:-}" ]] && auth=(--oauth2-bearer "$GH_TOKEN")

release=$(curl --retry 5 --retry-all-errors --retry-delay 10 -fsSL "${auth[@]}" https://api.github.com/repos/openai/codex/releases/latest)
version=$(jq -r .tag_name <<<"$release" | sed 's/^rust-v//')

if [[ "$version" == "$(jq -r .version sources.json)" ]]; then
  exit 0
fi

hashes='{}'
for target in x86_64-unknown-linux-musl aarch64-unknown-linux-musl; do
  digest=$(jq -r --arg name "codex-$target.tar.gz" '.assets[] | select(.name == $name) | .digest' <<<"$release")
  hash=$(nix hash convert --hash-algo sha256 --to sri "${digest#sha256:}")
  hashes=$(jq --arg target "$target" --arg hash "$hash" '.[$target] = $hash' <<<"$hashes")
done

jq -n --arg version "$version" --argjson hashes "$hashes" '{version: $version, hashes: $hashes}' >sources.json

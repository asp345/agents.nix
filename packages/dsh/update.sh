#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

version=$(curl -fsSL https://registry.npmjs.org/@deepseek-ai/dsh | jq -r '.time | del(.created, .modified) | to_entries | max_by(.value) | .key')

if [[ "$version" == "$(jq -r .version sources.json)" ]]; then
  exit 0
fi

jq -n --arg version "$version" '{name: "dsh", private: true, dependencies: {"@deepseek-ai/dsh": $version}}' >package.json
rm -f package-lock.json
nix shell --inputs-from ../.. nixpkgs#nodejs --command npm install --package-lock-only --ignore-scripts --no-audit --no-fund
npmDepsHash=$(nix run --inputs-from ../.. nixpkgs#prefetch-npm-deps -- package-lock.json)

jq -n --arg version "$version" --arg npmDepsHash "$npmDepsHash" '{version: $version, npmDepsHash: $npmDepsHash}' >sources.json

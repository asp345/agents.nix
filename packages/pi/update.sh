#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

version=$(curl --retry 5 --retry-all-errors --retry-delay 10 -fsSL https://registry.npmjs.org/@earendil-works/pi-coding-agent/latest | jq -r .version)

if [[ "$version" == "$(jq -r .version sources.json)" ]]; then
  exit 0
fi

jq -n --arg version "$version" '{name: "pi", private: true, dependencies: {"@earendil-works/pi-coding-agent": $version}}' >package.json
rm -f package-lock.json
nix shell --inputs-from ../.. nixpkgs#nodejs --command npm install --package-lock-only --ignore-scripts --no-audit --no-fund
npmDepsHash=$(nix run --inputs-from ../.. nixpkgs#prefetch-npm-deps -- package-lock.json)

jq -n --arg version "$version" --arg npmDepsHash "$npmDepsHash" '{version: $version, npmDepsHash: $npmDepsHash}' >sources.json

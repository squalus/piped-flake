#!/usr/bin/env bash

set -euo pipefail

scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$scriptDir"

srcDir=$(nix eval --raw -L '..#piped-frontend.src')

echo "srcDir=$srcDir"

tempDir=$(mktemp -d)
cd "$tempDir"
set -x
ln -s "$srcDir"/package.json package.json
npm install --package-lock-only --legacy-peer-deps --ignore-scripts
cp package-lock.json "$scriptDir"
prefetch-npm-deps package-lock.json | tr -d '\n' | jq -R -s '.'> "$scriptDir"/npmDepsHash.json
cat "$scriptDir"/npmDepsHash.json


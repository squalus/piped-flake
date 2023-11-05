#!/usr/bin/env bash

set -euo pipefail

scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$scriptDir"/..

set -x

nix build --print-out-paths -L .#sandboxed-ci-tests
nix build --print-out-paths -L .#unsandboxed-ci-tests --option build-use-sandbox false

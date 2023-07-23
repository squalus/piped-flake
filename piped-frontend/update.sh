#!/usr/bin/env bash

set -euo pipefail

scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$scriptDir"
nix develop "$scriptDir"/.. -L -c "$scriptDir/update-inner.sh"


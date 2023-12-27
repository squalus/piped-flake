flakeRoot="$(pwd)"
pkgRoot="$flakeRoot/piped-frontend"
srcDir=$(nix eval --raw -L '.#piped-frontend.src')

echo "srcDir=$srcDir"

tempDir=$(mktemp -d)
cd "$tempDir"
set -x
ln -s "$srcDir"/package.json package.json
npm install --package-lock-only --legacy-peer-deps --ignore-scripts
cp package-lock.json "$pkgRoot"
prefetch-npm-deps package-lock.json | tr -d '\n' | jq -R -s '.'> "$pkgRoot"/npmDepsHash.json
cat "$pkgRoot"/npmDepsHash.json


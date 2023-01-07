{ stdenv
, lib
, fetchFromGitHub
, fetchYarnDeps
, nodejs
, fixup_yarn_lock
, yarn
, nixosTest
, src
, ...
}:

let

  offlineCacheHash = builtins.fromJSON (builtins.readFile ./offline-cache-hash.json);

  offlineCache = fetchYarnDeps {
    yarnLock = src + "/yarn.lock";
    sha256 = offlineCacheHash;
  };

in
  
stdenv.mkDerivation rec {

  name = "piped-frontend";

  inherit offlineCache src;
  
  nativeBuildInputs = [ nodejs yarn fixup_yarn_lock ];
  
  postConfigure = ''
    export HOME=$PWD/tmp
    mkdir -p $HOME

    fixup_yarn_lock yarn.lock
    yarn config --offline set yarn-offline-mirror $offlineCache
    yarn install --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive
    patchShebangs node_modules

    export PATH=$(pwd)/node_modules/.bin:$PATH
  '';

  buildPhase = ''
    yarn --offline build
  '';

  installPhase = ''
    cp -r dist $out
  '';

  meta = {
    homepage = "https://github.com/TeamPiped/piped";
    license = lib.licenses.agpl3Only;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };

  passthru = {
    inherit offlineCache;
    offlineCacheUpdate = fetchYarnDeps {
      yarnLock = src + "/yarn.lock";
    };
  };
}


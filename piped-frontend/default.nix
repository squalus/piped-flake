{ stdenv
, lib
, fetchFromGitHub
, fetchYarnDeps
, nodejs
, fixup_yarn_lock
, yarn
, nixosTest
, config
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
  
  postPatch = lib.optionalString ((config.piped or null) != null) ''
    substituteInPlace src/main.js \
      --replace "https://pipedapi.kavin.rocks" ${config.piped.backendUrl}
    substituteInPlace src/components/PreferencesPage.vue \
      --replace "https://piped-instances.kavin.rocks/" ${config.piped.backendUrl}
    substituteInPlace src/components/PlaylistPage.vue \
      --replace "https://piped.kavin.rocks" ${config.piped.frontendUrl}
    substituteInPlace public/opensearch.xml \
      --replace "https://pipedapi.kavin.rocks" ${config.piped.backendUrl} \
      --replace "https://piped.kavin.rocks" ${config.piped.frontendUrl}
  '';

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


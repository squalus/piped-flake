{ src
, lib
, buildNpmPackage
, pnpm
}:

let

  pname = "pipedfrontend";

  version = "0.0.1";

  doPnpmDeps = hash: pnpm.fetchDeps {
    fetcherVersion = 2;
    inherit pname version src hash;
  };

  pnpmDeps = doPnpmDeps (builtins.fromJSON (builtins.readFile ./npmDepsHash.json));

in
  
buildNpmPackage {

  inherit pname pnpmDeps src version;

  npmConfigHook = pnpm.configHook;

  npmDeps = pnpmDeps;

  installPhase = ''
    cp dist $out -r
  '';

  passthru.hashUpdate = doPnpmDeps "";

  meta = {
    homepage = "https://github.com/TeamPiped/piped";
    license = lib.licenses.agpl3Only;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };
}


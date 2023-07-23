{ src
, lib
, buildNpmPackage
, writeShellApplication
, nodejs
, prefetch-npm-deps
}:

let

  npmDepsHash = builtins.fromJSON (builtins.readFile ./npmDepsHash.json);

in
  
buildNpmPackage rec {

  pname = "piped-frontend";
  version = "0.0.1";

  inherit src npmDepsHash;

  postPatch = ''
    cp ${./package-lock.json} ./package-lock.json
  '';

  npmFlags = [ "--legacy-peer-deps" ];

  installPhase = ''
    cp -r dist $out
  '';

  passthru.updateScript = writeShellApplication {
    name = "${pname}-update";
    runtimeInputs = [
      nodejs
      prefetch-npm-deps
    ];
    text = builtins.readFile ./update.sh;
  };

  meta = {
    homepage = "https://github.com/TeamPiped/piped";
    license = lib.licenses.agpl3Only;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };
}


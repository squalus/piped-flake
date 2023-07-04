{ src
, lib
, buildNpmPackage
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

  meta = {
    homepage = "https://github.com/TeamPiped/piped";
    license = lib.licenses.agpl3Only;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };
}


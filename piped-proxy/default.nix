{ src, lib, rustPlatform }:

let

  cargoHash = builtins.fromJSON ( builtins.readFile ./cargo-hash.json);

in

rustPlatform.buildRustPackage rec {

  pname = "piped-proxy";

  version = "0.0.1";

  inherit cargoHash src;

  passthru = {
    cargoUpdate = rustPlatform.buildRustPackage {
      inherit pname version src;
      cargoHash = lib.fakeHash;
    };
  };

  meta = {
    homepage = "https://github.com/TeamPiped/piped-proxy";
    license = lib.licenses.agpl3Only;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };

}

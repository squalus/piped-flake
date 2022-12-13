{ src, lib, fetchFromGitHub, rustPlatform, nixosTest }:

let

  cargoSha256 = builtins.fromJSON ( builtins.readFile ./cargo-hash.json);

in

rustPlatform.buildRustPackage rec {

  pname = "piped-proxy";

  version = "0.0.1";

  inherit cargoSha256 src;

  passthru = {
    cargoUpdate = rustPlatform.buildRustPackage {
      inherit pname version src;
      cargoSha256 = lib.fakeSha256;
    };
  };

  meta = {
    homepage = "https://github.com/TeamPiped/piped-proxy";
    license = lib.licenses.agpl3Only;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };

}

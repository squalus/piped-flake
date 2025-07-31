{

  description = "Random packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    systems.url = "github:nix-systems/default-linux";
    flake-utils = {
      url = "flake:flake-utils";
      inputs.systems.follows = "systems";
    };
    piped-frontend-src = {
      url = "github:TeamPiped/Piped";
      flake = false;
    };
    piped-proxy-src = {
      url = "github:TeamPiped/piped-proxy";
      flake = false;
    };
    piped-backend-src = {
      url = "github:TeamPiped/piped-backend";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
  
  {
    nixosModules.default = { ... }: {
      imports = [
        (import ./piped-backend/module.nix { inherit self; })
        (import ./piped-frontend/module.nix { inherit self; })
        (import ./piped-proxy/module.nix { inherit self; })
      ];
    };
  } //
  
  flake-utils.lib.eachDefaultSystem (system:

    let

      pkgs = nixpkgs.legacyPackages."${system}";

    in

    with pkgs;

    rec {
      packages = flake-utils.lib.flattenTree rec {

        piped-proxy = callPackage ./piped-proxy {
          src = inputs.piped-proxy-src;
        };
        piped-proxy-test = nixosTest (import ./piped-proxy/test.nix { inherit self; });
        piped-backend = callPackage ./piped-backend rec {
          src = inputs.piped-backend-src;
          jdk = pkgs.jdk21_headless;
          gradle = pkgs.gradle.override { java = jdk; };
        };
        piped-backend-test = nixosTest (import ./piped-backend/test.nix { inherit self; });
        piped-frontend = callPackage ./piped-frontend {
          src = inputs.piped-frontend-src;
        };
        piped-frontend-test = nixosTest (import ./piped-frontend/test.nix { inherit self; });
        piped-test = nixosTest (import ./piped-test { inherit self; });
      };
      checks = flake-utils.lib.flattenTree {
        inherit (packages) piped-proxy-test piped-backend-test piped-frontend-test;
      };
      devShells.default = mkShell {
        name = "package-update";
        nativeBuildInputs = [
          nodejs
          prefetch-npm-deps
          mitm-cache
        ];
      };
    }
  );
}

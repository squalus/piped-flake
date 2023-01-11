{ self }:
{ config
, pkgs
, lib
, ...
}:

with lib;

let

  cfg = config.services.piped-frontend;

  patched-package = pkgs.callPackage ({ stdenv }: stdenv.mkDerivation {
    name = "piped-frontend-patched";
    src = cfg.package;
    dontBuild = true;
    postPatch = ''
      find ./ -type f -exec sed -i 's,https://piped.kavin.rocks,${cfg.publicFrontendUrl},g' {} \;
    '' + (lib.optionalString (cfg.publicBackendUrl != null) ''
      find ./ -type f -exec sed -i 's,https://pipedapi.kavin.rocks,${cfg.publicBackendUrl},g' {} \;
      find ./ -type f -exec sed -i 's,https://piped-instances.kavin.rocks,${cfg.publicBackendUrl},g' {} \;
    '');
    installPhase = ''
      cp -r . $out
    '';
  }) {};

in

{
  options.services.piped-frontend = {

    enable = mkEnableOption "Whether to enable the piped-frontend service";

    listenHost = mkOption {
      default = "127.0.0.1";
      type = types.str;
    };

    listenPort = mkOption {
      default = 14301;
      type = types.port;
    };

    package = mkOption {
      default = self.packages."${pkgs.stdenv.system}".piped-frontend;
      type = types.package;
    };

    publicFrontendUrl = mkOption {
      type = types.str;
      description = "Public URL of piped-frontend";
    };

    publicBackendUrl = mkOption {
      type = with types; nullOr str;
      description = "Public URL of piped-backend";
    };
  };

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts.piped-frontend = {
        listen = [ { addr = cfg.listenHost; port = cfg.listenPort; ssl = false; }];
        locations."/" = {
          root = patched-package;
          extraConfig = ''
            error_page 404 =200 /index.html;
          '';
        };
      };
    };
  };
}

{ self }:
{ config
, pkgs
, lib
, ...
}:

with lib;

let

  cfg = config.services.piped-frontend;

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
  };

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts.piped-frontend = {
        listen = [ { addr = cfg.listenHost; port = cfg.listenPort; ssl = false; }];
        locations."/" = {
          root = cfg.package; 
          extraConfig = ''
            error_page 404 =200 /index.html;
          '';
        };
      };
    };
  };
}

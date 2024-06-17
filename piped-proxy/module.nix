{ self }:
{ config
, pkgs
, lib
, ...
}:

with lib;

let

  cfg = config.services.piped-proxy;

in

{
  options.services.piped-proxy = {

    enable = mkEnableOption "Whether to enable the piped-proxy service";

    listenAddress = mkOption {
      default = "127.0.0.1:14300";
      type = types.str;
    };

    listenPath = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "/run/piped-proxy/piped-proxy.sock";
      description = "Path for listening on a unix socket. Enabling this ignores `listenAddress`";
    };

    package = mkOption {
      default = self.packages."${pkgs.stdenv.system}".piped-proxy;
      type = types.package;
    };

  };

  config =
    let
      useSocket = cfg.listenPath != null;
    in
    mkIf cfg.enable {

      systemd.sockets.piped-proxy = mkIf useSocket {
        wantedBy = [ "sockets.target" ];
        socketConfig = {
          ListenStream = cfg.listenPath;
        };
      };

      systemd.services.piped-proxy = {
        wantedBy = [ "multi-user.target" ];
        wants = mkIf useSocket [ "piped-proxy.socket" ];
        after = mkIf useSocket [ "piped-proxy.socket" ];
        serviceConfig = {
          ExecStart = "${cfg.package}/bin/piped-proxy";
          Environment = (if useSocket then [ "FD_UNIX=0" ] else [ "BIND=${cfg.listenAddress}" ]);
          RuntimeDirectory = [ "%N" ];
          WorkingDirectory = [ "%t/%N" ];
          DynamicUser = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          ProtectKernelLogs = true;
          ProtectHostname = true;
          ProtectClock = true;
          ProtectProc = "invisible";
          ProcSubset = "pid";
          PrivateTmp = true;
          PrivateUsers = true;
          PrivateDevices = true;
          PrivateIPC = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          CapabilityBoundingSet = "";
          LockPersonality = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
          ];
          RestrictNamespaces = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" ];
          SystemCallErrorNumber = "EPERM";
        };
      };
    };
}

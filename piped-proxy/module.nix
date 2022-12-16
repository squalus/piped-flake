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

    package = mkOption {
      default = self.packages."${pkgs.stdenv.system}".piped-proxy;
      type = types.package;
    };

  };

  config = mkIf cfg.enable {
    systemd.services.piped-proxy = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/piped-proxy";
        Environment = [ "BIND=${cfg.listenAddress}" ];
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
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" ];
        SystemCallErrorNumber = "EPERM";
      };
    };
  };
}

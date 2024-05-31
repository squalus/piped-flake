{ self }:
{ config
, pkgs
, lib
, options
, ...
}:

with lib;

let

  cfg = config.services.piped-backend;

  propsFormat = pkgs.formats.javaProperties {};

  propsFile = propsFormat.generate "piped-backend-config.properties" cfg.settings;

in

{
  options.services.piped-backend = {

    enable = mkEnableOption "Whether to enable the piped-backend service";

    dbUser = mkOption {
      type = types.str;
      default = "piped";
    };

    dbName = mkOption {
      type = types.str;
      default = "piped";
    };

    # https://github.com/TeamPiped/Piped-Backend/blob/master/src/main/java/me/kavin/piped/consts/Constants.java
    settings = mkOption {
      type = types.submodule {
        freeformType = propsFormat.type;
        options = {
          MATRIX_SERVER = mkOption {
            type = types.str;
            default = "";
          };

          COMPROMISED_PASSWORD_CHECK = mkOption {
            type = types.str;
            default = "false";
          };

          PORT = mkOption {
            type = types.port;
            default = 14302;
            description = "Listen port";
            apply = x: builtins.toString x;
          };

          API_URL = mkOption {
            type = types.str;
            default = "http://127.0.0.1:${toString options.services.piped-backend.PORT.default}";
            description = "Public URL of piped-backend";
          };

          FRONTEND_URL = mkOption {
            type = types.str;
            description = "Public URL of piped-frontend";
          };

          PROXY_PART = mkOption {
            type = types.str;
            default = "Public URL of piped-proxy";
          };

          "hibernate.connection.driver_class" = mkOption {
            type = types.str;
            default = "org.postgresql.Driver";
          };

          "hibernate.connection.username" = mkOption {
            type = types.str;
            default = "piped";
          };

          "hibernate.connection.password" = mkOption {
            type = types.str;
            default = "piped";
          };

          "hibernate.connection.url" = mkOption {
            type = types.str;
            default = "jdbc:postgresql://127.0.0.1:${builtins.toString options.services.postgresql.port.default}/${options.services.piped-backend.dbName.default}";
          };

          "hibernate.dialect" = mkOption {
            type = types.str;
            default = "org.hibernate.dialect.PostgreSQLDialect";
          };
        };
      };
      default = {};
    };

    toolOptions = mkOption {
      type = types.str;
      description = "JVM options";
      default = "-Xmx1G -Xaggressive -XX:+UnlockExperimentalVMOptions -XX:+OptimizeStringConcat -XX:+UseStringDeduplication -XX:+UseCompressedOops -XX:+UseNUMA -XX:+IdleTuningGcOnIdle -Xgcpolicy:gencon -Xshareclasses:allowClasspaths -Xtune:virtualized";
    };

    package = mkOption {
      type = types.package;
      default = self.packages."${pkgs.stdenv.system}".piped-backend;
    };

  };

  config = mkIf cfg.enable {
    systemd.services.piped-backend = {
      wantedBy = [ "multi-user.target" ];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/piped-backend";
        Environment = [
          "JVM_TOOL_OPTIONS=\"${cfg.toolOptions}\""
        ];
        RuntimeDirectory = [ "%N" ];
        BindReadOnlyPaths = [
          "${propsFile}:%t/%N/config.properties"
        ];
        WorkingDirectory = [ "%t/%N" ];
        DynamicUser = true;
        User = "piped-backend";
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
        Restart = "always";
        RestartSec = 5;
      };
    };

    services.postgresql = {
      enable = true;
      enableTCPIP = true;
      ensureDatabases = lib.singleton cfg.dbName;
      ensureUsers = lib.singleton {
        name = cfg.settings."hibernate.connection.username";
        ensureDBOwnership = cfg.dbName == cfg.settings."hibernate.connection.username";
      };
    };

  };
}

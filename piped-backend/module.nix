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

  autoProps = {
    PORT = builtins.toString cfg.listenPort;
    API_URL = "http://127.0.0.1:${builtins.toString cfg.listenPort}";
    COMPROMISED_PASSWORD_CHECK = "false";
    MATRIX_SERVER = "";
    "hibernate.connection.url" = "jdbc:postgresql://${cfg.dbHost}:${builtins.toString cfg.dbPort}/${cfg.dbName}";
    "hibernate.connection.driver_class" = "org.postgresql.Driver";
    "hibernate.dialect" = "org.hibernate.dialect.PostgreSQLDialect";
    "hibernate.connection.username" = cfg.dbUser;
    "hibernate.connection.password" = cfg.dbPassword;
  } // (optionalAttrs config.services.piped-frontend.enable {
    FRONTEND_URL = config.services.piped-frontend.publicFrontendUrl;
  }) // (optionalAttrs config.services.piped-proxy.enable {
    PROXY_PART = "http://${config.services.piped-proxy.listenAddress}";
  });

  propsFile = propsFormat.generate "piped-backend-config.properties" (autoProps // cfg.properties);

in

{
  options.services.piped-backend = {

    enable = mkEnableOption "Whether to enable the piped-backend service";

    listenPort = mkOption {
      type = types.int;
      default = 14302;
    };

    dbName = mkOption {
      type = types.str;
      default = "piped";
    };

    dbUser = mkOption {
      type = types.str;
      default = "piped";
    };

    dbPassword = mkOption {
      type = types.str;
      default = "piped";
    };

    dbHost = mkOption {
      type = types.nullOr types.str;
      default = "127.0.0.1";
    };

    dbPort = mkOption {
      type = types.int;
      default = options.services.postgresql.port.default;
    };

    # https://github.com/TeamPiped/Piped-Backend/blob/master/src/main/java/me/kavin/piped/consts/Constants.java
    properties = mkOption {
      inherit (propsFormat) type;
      default = {};
    };

    package = mkOption {
      type = types.package;
      default = self.packages."${pkgs.stdenv.system}".piped-backend;
    };

  };

  config = mkIf cfg.enable {
    systemd.services.piped-backend = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/piped-backend";
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
      };
    };

    services.postgresql = {
      enable = true;
      enableTCPIP = true;
      ensureDatabases = lib.singleton cfg.dbName;
      ensureUsers = lib.singleton {
        name = cfg.dbUser;
        ensurePermissions = {
          "DATABASE ${cfg.dbName}" = "ALL PRIVILEGES";
        };
      };
    };

  };
}

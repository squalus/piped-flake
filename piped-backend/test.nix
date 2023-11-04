{ self }:
{ pkgs, ... }:

let

  listenPort = 14302;

in
{
  name = "piped-backend-test";
  nodes.machine = {
    imports = [
      self.nixosModules.default
    ];
    config = {
      services.piped-backend = {
        enable = true;
        settings = {
          PORT = listenPort;
          API_URL = "http://127.0.0.1:${toString listenPort}";
          PROXY_PART = "http://127.0.0.1:14300";
          FRONTEND_URL = "";
        };
      };
      services.postgresql = {
        initialScript = pkgs.writeText "init-postgres-with-password" ''
          CREATE USER piped WITH PASSWORD 'piped';
          CREATE DATABASE piped;
          GRANT ALL PRIVILEGES ON DATABASE piped TO piped;
          ALTER DATABASE piped OWNER TO piped;
        '';
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("piped-backend")
    machine.wait_until_succeeds("curl http://127.0.0.1:${builtins.toString listenPort}", timeout=45)
  '';

}

# integration test that needs network connectivity

{ self }:
{ pkgs, config, ... }:

let

  proxyListenAddress = "127.0.0.1:14300";

  frontendListenHost = "127.0.0.1";

  frontendListenPort = 14301; 

  backendListenPort = 14302;

in
{
  name = "piped-integration-test";
  nodes.machine = {
    imports = with self.nixosModules; [
      piped-backend
      piped-frontend
      piped-proxy
      "${pkgs.path}/nixos/tests/common/x11.nix"
    ];
    config = {
      environment.systemPackages = [
        pkgs.ungoogled-chromium
      ];
      services.piped-backend = {
        enable = true;
        listenPort = backendListenPort;
      };
      services.piped-frontend = {
        enable = true;
        listenHost = frontendListenHost;
        listenPort = frontendListenPort;
      };
      services.piped-proxy = {
        enable = true;
        listenAddress = proxyListenAddress;
      };
      services.postgresql = {
        initialScript = pkgs.writeText "init-postgres-with-password" ''
          CREATE USER piped WITH PASSWORD 'piped';
          CREATE DATABASE piped;
          GRANT ALL PRIVILEGES ON DATABASE piped TO piped;
        '';
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("postgresql")
    machine.wait_for_unit("piped-backend")
    machine.wait_for_unit("piped-proxy")
    machine.wait_for_unit("nginx")
    machine.wait_for_x()
    machine.execute(
      "xterm -e '${pkgs.ungoogled-chromium}/bin/chromium --no-sandbox http://127.0.0.1:14301/watch?v=YE7VzlLtp-4' >&2 &"
    )
    machine.wait_for_window("Big Buck Bunny")
    machine.shell_interact()
  '';

}

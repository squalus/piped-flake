{ self }:
{ pkgs, ... }:

let

  listenHost = "127.0.0.1";
  listenPort = 14301;

in
{
  name = "piped-frontend-test";
  nodes.machine = {
    imports = [
      self.nixosModules.piped-frontend
    ];
    config.services.piped-frontend = {
      enable = true;
      inherit listenHost listenPort;
    };
  };

  testScript = ''
    machine.wait_for_unit("nginx")
    machine.wait_until_succeeds("curl http://${listenHost}:${toString listenPort}", timeout=45)
  '';

}

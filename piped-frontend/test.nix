{ self }:
{ pkgs, config, ... }:

let

  listenHost = "127.0.0.1";
  listenPort = 14301;
  publicFrontendUrl = "http://${listenHost}:${toString listenPort}";

in
{
  name = "piped-frontend-test";
  nodes.machine = {
    imports = [
      self.nixosModules.default
    ];
    config.services.piped-frontend = {
      enable = true;
      inherit listenHost listenPort publicFrontendUrl;
      publicBackendUrl = "";
    };
  };

  testScript = ''
    machine.wait_for_unit("nginx")
    machine.wait_until_succeeds("curl ${publicFrontendUrl}", timeout=300)
  '';

}

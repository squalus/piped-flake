{ self }:
{ pkgs, ... }:

let

  listenAddress = "127.0.0.1:14300";

in
{
  name = "piped-proxy-test";
  nodes.machine = {
    imports = [
      self.nixosModules.piped-proxy
    ];
    config.services.piped-proxy = {
      enable = true;
      inherit listenAddress;
    };
  };

  testScript = ''
    machine.wait_for_unit("piped-proxy")
    machine.succeed("curl http://${listenAddress}")
  '';

}

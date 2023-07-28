{ lib, pkgs, baseDomain, ... }: {
  cj.deployment.environment = "dev";

  imports = [
    ./hardware-config.nix
    ../../services/mumble.nix
    ../../services/website.nix
    ../../services/vaultwarden.nix
    ../../services/dokuwiki.nix
    ../../services/freescout.nix
  ];

  system.stateVersion = "23.05";
  networking.hostName = "goldberg";
  # Fallback / for the monitoring v(x)lan
  networking.useDHCP = true;

  # We need to configure IPv6 statically, and if we start with that we can just also do it for IPv4
  networking.interfaces.ens3.useDHCP = false;
  networking.interfaces.ens3.ipv4.addresses = [ { address = "5.75.181.252"; prefixLength = 32; } ];
  networking.interfaces.ens3.ipv6.addresses = [ { address = "2a01:4f8:1c1e:9e75::1"; prefixLength = 64; } ];
  networking.defaultGateway = { address = "172.31.1.1"; interface = "ens3"; };
  networking.defaultGateway6 = { address = "fe80::1"; interface = "ens3"; };
  networking.nameservers = [ "213.133.98.98" "213.133.99.99" "213.133.100.100" ];

  services.murmur = {
    registerPassword = lib.mkForce "";
    environmentFile = lib.mkForce null;
  };
}

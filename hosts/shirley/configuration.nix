{ lib, pkgs, config, baseDomain, ... }: {
  imports = [
    ./hardware-config.nix
    ./mumble.nix
  ];

  system.stateVersion = "23.05";
  networking.hostName = "shirley";
  # Fallback / for the monitoring v(x)lan
  networking.useDHCP = true;

  # We need to configure IPv6 statically, and if we start with that we can just also do it for IPv4
  networking.interfaces.ens3.useDHCP = false;
  networking.interfaces.ens3.ipv4.addresses = [ { address = "94.130.107.245"; prefixLength = 32; } ];
  networking.interfaces.ens3.ipv6.addresses = [ { address = "2a01:4f8:c0c:83eb::1"; prefixLength = 64; } ];
  networking.defaultGateway = { address = "172.31.1.1"; interface = "ens3"; };
  networking.defaultGateway6 = { address = "fe80::1"; interface = "ens3"; };
  networking.nameservers = [ "213.133.98.98" "213.133.99.99" "213.133.100.100" ];

  services.nginx = {
    enable = true;
    enableReload = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts.${baseDomain} = {
      default = true;
      enableACME = true;
      forceSSL = true;
      # TODO: Change this to be deployed by some sort of CI + rsync so we don't need to always update the package version
      locations."/".root = pkgs.chaos-jetzt-website-pelican;
    };
  };
}

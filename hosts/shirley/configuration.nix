{ ... }: {
  cj = {
    deployment.environment = "prod";
    monitoring.interface = "ens10";
  };

  imports = [
    ./hardware-config.nix
    ../../services/mumble.nix
    ../../services/website.nix
    ../../services/vaultwarden.nix
    ../../services/dokuwiki.nix
    ../../services/freescout.nix
    ../../services/hedgedoc.nix
    ../../services/pretix.nix
    ../../services/pretalx.nix
  ];

  system.stateVersion = "23.05";
  networking.hostName = "shirley";

  networking = {
    # Fallback / for the monitoring v(x)lan
    useDHCP = true;
    defaultGateway = { address = "172.31.1.1"; interface = "ens3"; };
    defaultGateway6 = { address = "fe80::1"; interface = "ens3"; };
    nameservers = [ "213.133.98.98" "213.133.99.99" "213.133.100.100" ];

    interfaces.ens3 = {
      useDHCP = false;
      ipv4.addresses = [ { address = "94.130.107.245"; prefixLength = 32; } ];
      ipv6.addresses = [ { address = "2a01:4f8:c0c:83eb::1"; prefixLength = 64; } ];
    };
  };
}

{ pkgs, baseDomain, ... }: {
  cj.deployment.environment = "prod";

  imports = [
    ./hardware-config.nix
  ];

  system.stateVersion = "23.05";
  networking.hostName = "hamilton";
  # Added by default by nixos-infect. It seems sensible to keep this
  # For reference: https://wiki.archlinux.org/title/Zram
  zramSwap = {
    enable = true;
    # But limiting to 25% at start to see how high usage will be and to limit the impact on "fast" normal RAM
    memoryPercent = 25;
  };

  networking = {
    # Fallback / for the monitoring v(x)lan
    useDHCP = true;
    defaultGateway = { address = "172.31.1.1"; interface = "ens3"; };
    defaultGateway6 = { address = "fe80::1"; interface = "ens3"; };
    nameservers = [ "213.133.98.98" "213.133.99.99" "213.133.100.100" ];

    interfaces.ens3 = {
      useDHCP = false;
      ipv4.addresses = [ { address = "128.140.1.30"; prefixLength = 32; } ];
      ipv6.addresses = [ { address = "2a01:4f8:1c1e:b564::1"; prefixLength = 64; } ];
    };
  };
}

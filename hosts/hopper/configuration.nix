{ ... }: {
  cj = {
    deployment.environment = "prod";
    monitoring.interface = "enp7s0";
  };

  imports = [
    ./hardware-config.nix
    ../../services/monitoring/server
  ];

  system.stateVersion = "24.11";

  networking = {
    hostName = "hopper";
    # Fallback / for the monitoring v(x)lan
    useDHCP = true;
    defaultGateway = { address = "172.31.1.1"; interface = "enp1s0"; };
    defaultGateway6 = { address = "fe80::1"; interface = "enp1s0"; };
    nameservers = [ "213.133.98.98" "213.133.99.99" "213.133.100.100" ];

    interfaces.enp1s0 = {
      useDHCP = false;
      ipv4.addresses = [ { address = "159.69.87.229"; prefixLength = 32; } ];
      ipv6.addresses = [ { address = "2a01:4f8:c2c:7197::1"; prefixLength = 64; } ];
    };
  };
}

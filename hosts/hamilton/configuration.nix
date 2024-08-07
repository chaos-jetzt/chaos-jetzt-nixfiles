{ config, ... }: {
  cj = {
    deployment.environment = "prod";
    monitoring.interface = "enp7s0";
  };

  imports = [
    ./hardware-config.nix
    ../../services/matrix
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
    defaultGateway = { address = "172.31.1.1"; interface = "enp1s0"; };
    defaultGateway6 = { address = "fe80::1"; interface = "enp1s0"; };
    nameservers = [ "213.133.98.98" "213.133.99.99" "213.133.100.100" ];

    interfaces.enp1s0 = {
      useDHCP = false;
      ipv4.addresses = [ { address = "128.140.1.30"; prefixLength = 32; } ];
      ipv6.addresses = [ { address = "2a01:4f8:1c1e:b564::1"; prefixLength = 64; } ];
    };
  };

  # This is specific to every host!
  systemd.mounts = [{
    what = "/dev/disk/by-id/scsi-0HC_Volume_7628580";
    where = config.services.matrix-synapse.settings.media_store_path;
    type = "ext4";
    options = "discard,nofail,defaults";
    wantedBy = [ "multi-user.target" ];
  }];
}

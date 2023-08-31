{ lib, pkgs, config, ... }: {
  cj.deployment.environment = "dev";

  imports = [
    ./hardware-config.nix
    ../../services/mumble.nix
    ../../services/website.nix
    ../../services/matrix
    ../../services/vaultwarden.nix
    ../../services/dokuwiki.nix
    ../../services/freescout.nix
    ../../services/hedgedoc.nix
  ];

  system.stateVersion = "23.05";
  networking.hostName = "goldberg";

  networking = {
    # Fallback / for the monitoring v(x)lan
    useDHCP = true;
    defaultGateway = { address = "172.31.1.1"; interface = "ens3"; };
    defaultGateway6 = { address = "fe80::1"; interface = "ens3"; };
    nameservers = [ "213.133.98.98" "213.133.99.99" "213.133.100.100" ];

    interfaces.ens3 = {
      useDHCP = false;
      ipv4.addresses = [ { address = "5.75.181.252"; prefixLength = 32; } ];
      ipv6.addresses = [ { address = "2a01:4f8:1c1e:9e75::1"; prefixLength = 64; } ];
    };
  };

  services.murmur = {
    registerPassword = lib.mkForce "";
    environmentFile = lib.mkForce null;
  };

  # This is specific to every host!
  systemd.mounts = [{
    what = "/dev/disk/by-id/scsi-0HC_Volume_27793580";
    where = config.services.matrix-synapse.settings.media_store_path;
    type = "ext4";
    options = "discard,nofail,defaults";
    wantedBy = [ "multi-user.target" ];
  }];
}

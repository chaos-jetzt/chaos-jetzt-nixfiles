{
  config,
  lib,
  ...
}:

{
  imports = [
    ./nginxlog.nix
  ];

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "systemd"
      "logind"
    ];
    # They either don't apply to us or will provide us with metrics not usefull to us
    disabledCollectors = [
      "arp"
      "bcache"
      "bonding"
      "btrfs"
      "cpufreq"
      "edac"
      "entropy"
      "infiniband"
      "rapl"
      "selinux"
      "timex"
      "dmi"
    ];
  };

  networking.firewall.interfaces."${config.cj.monitoring.interface}".allowedTCPPorts = let
    inherit (config.services) prometheus;
    ifEnabled = x: lib.optional x.enable x.port;
  in (
    (ifEnabled prometheus)
    ++ (ifEnabled prometheus.alertmanager)
    ++ (ifEnabled prometheus.exporters.node)
    ++ (ifEnabled prometheus.exporters.nginxlog)
    ++ (ifEnabled prometheus.exporters.blackbox)
    ++ config.cj.monitoring.ports
    ++ config.cj.monitoring.synapse
  );
}

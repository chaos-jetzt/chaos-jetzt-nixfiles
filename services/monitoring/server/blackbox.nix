{
  lib,
  config,
  outputs,
  ...
}:

let
  inherit (lib) attrValues flatten attrNames;

  allTargets = let
    /* Basically a manual list of (legacy) hosts not yet migrated to NixOS
      but on which we'd like to have included in the monitoring. */
    externalTargets = import ./external-targets.nix;
  in
    outputs.nixosConfigurations // externalTargets;

  drop_ssl_chain_info = {
    action = "drop";
    regex = "probe_ssl_last_chain_info";
    source_labels = ["drop"];
  };

  relabel_configs = [
    {
      source_labels = [ "__address__" ];
      target_label = "__param_target";
    }
    {
      source_labels = [ "__param_target" ];
      target_label = "instance";
    }
    {
      target_label = "__address__";
      replacement = "localhost:${toString config.services.prometheus.exporters.blackbox.port}";
    }
    {
      source_labels = [ "__address__" ];
      target_label = "blackbox";
    }
  ];

  modules = {
    "http" = ["http_2xx_v4" "http_2xx_v6"];
    "tcp_tls" = ["tcp_tls_v4" "tcp_tls_v6"];
  };
in {
  services.prometheus.exporters.blackbox = {
    enable = true;
    configFile = ./config/blackbox-config.yml;
  };

  services.prometheus.scrapeConfigs = flatten (map (prober:
    (map (module: {
      inherit relabel_configs;
      job_name = "blackbox_${module}";
      metric_relabel_configs = [drop_ssl_chain_info];
      metrics_path = "/probe";
      params.module = [module];
      scrape_interval = "2m";
      static_configs = builtins.filter (c: c.targets != []) (map (host: {
        targets = host.config.cj.monitoring.blackbox."${prober}" or [];
        labels = {
          environment = host.config.cj.deployment.environment;
          host = host.config.networking.hostName;
        };
      }) (attrValues allTargets));
    }) modules."${prober}"))
  (attrNames modules));
}

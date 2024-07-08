{
  config,
  lib,
  outputs,
  baseDomain,
  ...
}:

let
  inherit (lib) concatStringsSep mapAttrsToList getAttrFromPath hasAttrByPath attrValues singleton;
  inherit (lib) escapeRegex flatten;

  # The domain under which the internal (monitoring network) IPs
  # are to be found (will be <hostname>.mon.<config.networking.domain>)
  monitoringBaseDomain = "mon.${config.networking.domain}";
  publicMonitoringDomain = "monitoring.${baseDomain}";

  allTargets = let
    /* Basically a manual list of (legacy) hosts not yet migrated to NixOS
      but on which we'd like to have included in the monitoring. */
    externalTargets = import ./external-targets.nix;
  in
    outputs.nixosConfigurations // externalTargets;

  /* Group `hosts' by their deployment environment */
  groupByEnv = hosts: builtins.groupBy (host: host.config.cj.deployment.environment) (attrValues hosts);

  /* Given a hostConfig and and a given service configuration
    (e.g. config.service.prometheus.exporters.node) format it like
    <hostname>.<domain>:<port> as a genric formatter for multiple
    exporters. */
  monTarget = service: hostConfig:
    "${hostConfig.networking.hostName}.${monitoringBaseDomain}:${toString service.port}";

  /* Apply monTarget for the exporter service with the given path
    for all of the given hosts. Only does so for hosts where the exporter
    is enabled. */
  targetHosts = servicePath: hosts: let
    service = cfg: if (hasAttrByPath servicePath cfg.config) then (getAttrFromPath servicePath cfg.config) else {};
  in
    map
    (c: monTarget (service c) c.config)
    (builtins.filter (c: (service c).enable or false) hosts);

  /* Convenience function for dropping multiple metrics in a single regex */
  mkDroppedMetrics = extraRegexen: let
    dropRegexen = [ "go_" "promhttp_metric_handler_requests_" ] ++ extraRegexen;
  in
    singleton {
      regex = "(${concatStringsSep "|" dropRegexen}).*";
      source_labels = ["__name__"];
      action = "drop";
    };

  /* relabel_metrics that extracts <hostname> from <hostname>.<domain>:<port>*/
  relabelInstance = {
    source_labels = ["__address__"];
    regex = "(\\w+)\\.${escapeRegex monitoringBaseDomain}\\:\\d*";
    target_label = "host";
  };

  /* All exporers that will be automatically scraped on all hosts when enabled */
  targetExporters = {
    node = {
      path = ["services" "prometheus" "exporters" "node"];
      additional_drops = [];
    };

    prometheus = {
      path = ["services" "prometheus"];
      additional_drops = [
        "prometheus_(sd|tsdb|target)_"
        "prometheus_(engine_query|rule_evaluation)_duration_"
        "prometheus_http_(response_size_bytes|request_duration_seconds)_"
        "net_conntrack_dialer_conn_"
      ];
    };

    alertmanager = {
      path = ["services" "prometheus" "alertmanager"];
      additional_drops = [
        "alertmanager_http_(response_size_bytes|request_duration_seconds)_"
        "alertmanager_notification_latency_seconds_"
        "alertmanager_(nflog|cluster)_"
        "alertmanager_silences_(query_duration_seconds|gc)_"
      ];
    };

    nginxlog = {
      path = ["services" "prometheus" "exporters" "nginxlog"];
      additional_drops = [];
    };

    blackbox = {
      path = ["services" "prometheus" "exporters" "blackbox"];
      additional_drops = [];
    };
  };
in {
  sops.secrets."prometheus/pretix_metrics_password".owner = "prometheus";

  services.prometheus = {
    enable = true;
    webExternalUrl = "https://${publicMonitoringDomain}/prometheus/";
    extraFlags = [
      "--web.route-prefix=\"/\""
    ];
    ruleFiles = [
      ./config/rules.yaml
    ];
    retentionTime = "30d";

    alertmanagers = [{
      static_configs = [{
        targets = [(monTarget config.services.prometheus.alertmanager config)];
      }];
    }];


    globalConfig.scrape_interval = "1m";

    scrapeConfigs = (mapAttrsToList (name: value: {
        job_name = name;
        relabel_configs = [relabelInstance];
        metric_relabel_configs = mkDroppedMetrics (value.additional_drops or []);
        static_configs = mapAttrsToList (environment: hosts: {
          targets = targetHosts (value.path) hosts;
          labels.environment = environment;
        }) (groupByEnv allTargets);
      }) targetExporters) ++ [
        {
          job_name = "pretix";
          relabel_configs = [];
          scheme = "https";
          basic_auth = {
            username = "metrics";
            password_file = config.sops.secrets."prometheus/pretix_metrics_password".path;
          };
          static_configs = builtins.filter (c: c.targets != []) (flatten (
            mapAttrsToList (environment: hosts:
            (map (host: {
              targets = host.config.cj.monitoring.pretix or [];
              labels = {
                inherit environment;
                host = host.config.networking.hostName;
              };
            }) hosts)
          ) (groupByEnv allTargets)
          ));
        }
        {
          job_name = "synapse";
          metrics_path = "/_synapse/metrics";
          relabel_configs = [relabelInstance];
          metric_relabel_configs = mkDroppedMetrics ([]);
          static_configs = builtins.filter (c: c.targets != []) (flatten (
          mapAttrsToList  (environment: hosts: {
            # Doing it this cursed / complicated because that way we can use the automatic host namig thing and don't need to label each host individually
            targets = flatten (map (host: (map (port: monTarget {port = port;} host.config)) host.config.cj.monitoring.synapse or []) hosts);
            labels.environment = environment;
          }) (groupByEnv allTargets)));
        }
      ]
    ;
  };
}

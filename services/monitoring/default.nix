{
  config,
  lib,
  outputs,
  ...
}: let
  inherit (lib) concatStringsSep mapAttrsToList hasAttrByPath getAttrFromPath filterAttrs substring singleton optionalString optional;
  inherit (lib) escapeRegex;
  inherit (config.networking) fqdn hostName;

  # Basically a manual list of (legacy) hosts not yet migrated to NixOS
  # but on which we'd like to have included in the monitoring.
  externalTargets = let
    host = hostName: {
      _module.args.baseDomain = "chaos.jetzt";
      config = {
        networking = {
          inherit hostName;
          domain = "net.chaos.jetzt";
        };
        services.prometheus = {
          enable = true;
          port = 9090;
          alertmanager = {
            enable = true;
            port = 9093;
          };
        };
      };
    };
  in {
    hopper = host "hopper";
    lovelace = host "lovelace";
  };

  monDomain = "mon.${config.networking.domain}";

  isMe = host: host.config.networking.fqdn == fqdn;
  others = filterAttrs (_: !isMe) outputs.nixosConfigurations;
  isDev = host: (substring 0 3 host._module.args.baseDomain) == "dev";
  allHosts = outputs.nixosConfigurations // externalTargets;
  /*
    Right now we only have one non-dev host in our NixOS setup (the ansible hosts don't monitor the NixOS hosts).
    That's why we currently add all hosts to our little monitoring "cluster". As soon as we have two or more production hosts,
    the dev host can be taken out of the equation
  */
  # allTargets = filterAttrs (_: c: (isMe c) || !(isDev c)) allHosts;
  allTargets = allHosts;

  # monFqdn = config: "${config.networking.hostName}.${monDomain}";
  hasEnabled = servicePath: config: let
    path = servicePath ++ ["enable"];
  in
    (hasAttrByPath path config) && (getAttrFromPath path config);

  monTarget = servicePath: config: let
    port = toString (getAttrFromPath (servicePath ++ ["port"]) config);
  in "${config.networking.hostName}.${monDomain}:${port}";

  dropMetrics = {wildcard ? true}: extraRegexen: let
    dropRegexen = [ "go_" "promhttp_metric_handler_requests_" ] ++ extraRegexen;
  in
    singleton {
      inherit (regex);
      regex = "(${concatStringsSep "|" dropRegexen})${optionalString wildcard ".*"}";
      source_labels = ["__name__"];
      action = "drop";
    };

  relabelInstance = {
    source_labels = ["__address__"];
    regex = "(\\w+)\\.${escapeRegex monDomain}\\:\\d*";
    target_label = "instance";
  };

  prometheusPath = ["services" "prometheus"];
  alertmanagerPath = ["services" "prometheus" "alertmanager"];
  targetAllHosts = servicePath:
    mapAttrsToList
    (_: config: monTarget servicePath config.config)
    (filterAttrs (_: c: (hasEnabled servicePath c.config)) (outputs.nixosConfigurations // externalTargets));
in {
  /*
  Steps to edit the monitoring.htpasswd (aka. adding yourself / updating you password):

  1. `sops -d secrets/all/monitoring.htpasswd > /tmp/monitoring.htpasswd`
  2. Use `htpasswd` (from the `apacheHttpd` package) to your hearts content
  3. `sops -e /tmp/monitoring.htpasswd > secrets/all/monitoring.htpasswd`
  4. `rm /tmp/monitoring.htpasswd`
  */
  sops.secrets = {
    "monitoring.htpasswd" = {
      format = "binary";
      owner = config.services.nginx.user;
      sopsFile = ../../secrets/all/monitoring.htpasswd;
    };
    "alertmanager/env" = {
      format = "yaml";
      sopsFile = ../../secrets/all/secrets.yaml;
    };
  };

  services.nginx.virtualHosts."${fqdn}" = let
    monitoring_htpasswd = config.sops.secrets."monitoring.htpasswd".path;
  in {
    enableACME = true;
    forceSSL = true;
    locations."/prometheus/" = {
      basicAuthFile = monitoring_htpasswd;
      proxyPass = "http://127.0.0.1:${builtins.toString config.services.prometheus.port}/";
    };
    locations."/alertmanager/" = {
      basicAuthFile = monitoring_htpasswd;
      proxyPass = "http://127.0.0.1:${builtins.toString config.services.prometheus.alertmanager.port}/";
    };
  };

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = ["systemd"];
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
    ];
  };

  services.prometheus = {
    enable = true;
    webExternalUrl = "https://${fqdn}/prometheus/";
    extraFlags = [
      "--web.route-prefix=\"/\""
      "--web.enable-admin-api"
    ];
    ruleFiles = [
      ./rules.yaml
    ];
    retentionTime = "30d";

    alertmanagers = [{
      static_configs = [{
          targets = [(monTarget alertmanagerPath config)];
      }];
    }];

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [
            # Only scraping to own node-exporter
            (monTarget ["services" "prometheus" "exporters" "node"] config)
          ];
        }];
        relabel_configs = [relabelInstance];
        metric_relabel_configs = dropMetrics {} [];
      }
      {
        job_name = "alertmanager";
        static_configs = [{
          targets = targetAllHosts alertmanagerPath;
        }];
        relabel_configs = [relabelInstance];
        metric_relabel_configs = dropMetrics {} [
          "alertmanager_http_(response_size_bytes|request_duration_seconds)_"
          "alertmanager_notification_latency_seconds_"
          "alertmanager_(nflog|cluster)_"
          "alertmanager_silences_(query_duration_seconds|gc)_"
        ];
      }
      {
        job_name = "prometheus";
        static_configs = [{
          targets = targetAllHosts prometheusPath;
        }];
        relabel_configs = [relabelInstance];
        metric_relabel_configs = dropMetrics {} [
          "prometheus_(sd|tsdb|target)_"
          "prometheus_(engine_query|rule_evaluation)_duration_"
          "prometheus_http_(response_size_bytes|request_duration_seconds)_"
          "net_conntrack_dialer_conn_"
        ];
      }
    ];
  };

  services.prometheus.alertmanager = {
    enable = true;
    extraFlags = ["--web.route-prefix=\"/\"" "--cluster.listen-address="];
    webExternalUrl = "https://${fqdn}/alertmanager/";
    environmentFile = config.sops.secrets."alertmanager/env".path;

    configuration = {
      global = {
        smtp_from = "Chaos-Jetzt Monitoring (${hostName}) <monitoring-${hostName}@chaos.jetzt>";
        smtp_smarthost = "\${SMTP_HOST}:587";
        smtp_auth_username = "\${SMTP_USER}";
        smtp_auth_password = "\${SMTP_PASS}";
        smtp_hello = config.networking.fqdn;
      };

      receivers = [{
        name = "mail";
        email_configs = [
          { to = "jetzt+mon@e1mo.de";
            send_resolved = true; }
          { to = "info@adb.sh";
            send_resolved = true; }
        ];
      }];

      route = {
        receiver = "mail";
        repeat_interval = "16h";
        group_wait = "1m";
        group_by = ["alertname" "instance"];
        routes = [
          {
            match.severiy = "critical";
            receiver = "mail";
            repeat_interval = "6h";
          }
          {
            match.severiy = "error";
            receiver = "mail";
            repeat_interval = "16h";
          }
          {
            match.severiy = "warn";
            receiver = "mail";
            repeat_interval = "28h";
          }
          {
            match.severiy = "info";
            receiver = "mail";
            repeat_interval = "56h";
          }
        ];
      };

      inhibit_rules = [
        {
          target_matchers = ["alertname = ReducedAvailableMemory"];
          source_matchers = ["alertname =~ (Very)LowAvailableMemory"];
          equal = ["instance"];
        }
        {
          target_matchers = ["alertname = LowAvailableMemory"];
          source_matchers = ["alertname = VeryLowAvailableMemory"];
          equal = ["instance"];
        }
        {
          target_matchers = ["alertname = ElevatedLoad"];
          source_matchers = ["alertname =~ (Very)HighLoad"];
          equal = ["instance"];
        }
        {
          target_matchers = ["alertname = HighLoad"];
          source_matchers = ["alertname = VeryHighLoad"];
          equal = ["instance"];
        }
      ];
    };
  };
}

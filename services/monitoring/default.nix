{
  config,
  lib,
  outputs,
  ...
}: let
  inherit (lib) concatStringsSep mapAttrsToList getAttrFromPath filterAttrs singleton optional;
  inherit (lib) escapeRegex;
  inherit (config.networking) fqdn hostName;

  # Absolute hack until https://github.com/chaos-jetzt/chaos-jetzt-nixfiles/pull/29 is merged
  # But needed for us to have a working monitoring on our main matrix server (kinda important)
  # FIXME: Remove when #29 is merged
  monIf = if config.networking.hostName == "hamilton" then "enp7s0" else "ens10";

  # Basically a manual list of (legacy) hosts not yet migrated to NixOS
  # but on which we'd like to have included in the monitoring.
  externalTargets = let
    host = hostName: {
      _module.args = {
        isDev = false;
        baseDomain = "chaos.jetzt";
      };
      config = {
        networking = rec {
          inherit hostName;
          domain = "net.chaos.jetzt";
          fqdn = "${hostName}.${domain}";
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
  isDev_ = getAttrFromPath [ "_module" "args" "isDev" ];
  allHosts = outputs.nixosConfigurations // externalTargets;
  allTargets = filterAttrs (_: c: (isMe c) || !(isDev_ c)) allHosts;

  monTarget = service: config: "${config.networking.hostName}.${monDomain}:${toString service.port}";
  targetAllHosts = servicePath: let
    service = cfg: getAttrFromPath servicePath cfg.config;
  in
    mapAttrsToList
    (_: c: monTarget (service c) c.config)
    (filterAttrs (_: c: (service c).enable or false) allTargets);

  dropMetrics = extraRegexen: let
    dropRegexen = [ "go_" "promhttp_metric_handler_requests_" ] ++ extraRegexen;
  in
    singleton {
      inherit (regex);
      regex = "(${concatStringsSep "|" dropRegexen}).*";
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
in {
  /*
  Steps to edit the monitoring.htpasswd (aka. adding yourself / updating you password):

  1. Use `htpasswd` (from the `apacheHttpd` package) to generate the hashed password
  2. `sops secrets/all/monitoring.htpasswd` and replace/add the specfic lines
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

  services.nginx.enable = lib.mkDefault true;
  services.nginx.virtualHosts."${fqdn}" =  let
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

  networking.firewall.interfaces.${monIf}.allowedTCPPorts = let
    inherit (config.services) prometheus;
    ifEnabled = x: lib.optional x.enable x.port;
  in (
    (ifEnabled prometheus)
    ++ (ifEnabled prometheus.alertmanager)
    ++ (ifEnabled prometheus.exporters.node)
  );

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
        targets = [(monTarget config.services.prometheus.alertmanager config)];
      }];
    }];

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [
            # Only scraping to own node-exporter
            (monTarget config.services.prometheus.exporters.node config)
          ];
        }];
        relabel_configs = [relabelInstance];
        metric_relabel_configs = dropMetrics [];
      }
      {
        job_name = "alertmanager";
        static_configs = [{
          targets = targetAllHosts alertmanagerPath;
        }];
        relabel_configs = [relabelInstance];
        metric_relabel_configs = dropMetrics [
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
        metric_relabel_configs = dropMetrics [
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
          { to = "admin+mon@adb.sh";
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

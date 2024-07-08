{
  config,
  baseDomain,
  ...
}:

let
  inherit (config.networking) fqdn hostName;
  publicMonitoringDomain = "monitoring.${baseDomain}";
in {
  sops.secrets."alertmanager/env" = {
    format = "yaml";
    sopsFile = ../../../secrets/all/secrets.yaml;
  };

  services.prometheus.alertmanager = {
    enable = true;
    webExternalUrl = "https://${publicMonitoringDomain}/alertmanager/";
    extraFlags = [
      "--web.route-prefix=\"/\""
    ];
    environmentFile = config.sops.secrets."alertmanager/env".path;

    configuration = {
      global = {
        smtp_from = "Chaos-Jetzt Monitoring (${hostName}) <monitoring-${hostName}@chaos.jetzt>";
        smtp_smarthost = "\${SMTP_HOST}:587";
        smtp_auth_username = "\${SMTP_USER}";
        smtp_auth_password = "\${SMTP_PASS}";
        smtp_hello = config.networking.fqdn;
      };

      receivers = [
        {
          name = "mail";
          email_configs = [
            { to = "jetzt+mon@e1mo.de";
              send_resolved = true; }
            { to = "admin+mon@adb.sh";
              send_resolved = true; }
          ];
        }
        {
          name = "null";
        }
      ];

      route = {
        receiver = "mail";
        repeat_interval = "16h";
        group_wait = "1m";
        group_by = ["alertname" "instance"];
        routes = [
          {
            match.environment = "dev";
            repeat_interval = "7d";
            group_interval = "15m";
            group_wait = "5m";
            receiver = "null"; # We don't want alerts for the dev server flodding our inboxes.
          }
          {
            match.environment = "prod";
            routes = [
              {
                matchers = ["alertname =~ Blackbox.*"];
                group_by = ["host"];
                group_wait = "5m"; # Due ot the fact, that we do the blackbox checks only every two minutes
              }
              {
                match.severiy = "critical";
                repeat_interval = "6h";
              }
              {
                match.severiy = "error";
                repeat_interval = "16h";
              }
              {
                match.severiy = "warn";
                repeat_interval = "28h";
              }
              {
                match.severiy = "info";
                repeat_interval = "56h";
              }
            ];
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
        {
          target_matchers = ["alertname = BlackboxProbeFaile"];
          source_matchers = ["alertname = InstanceDown"];
          equal = [ "host" ];
        }
        {
          target_matchers = ["alertname = InstanceDownAny"];
          source_matchers = ["alertname = InstanceDown"];
          equal = [ "instance" ];
        }
      ];
    };
  };
}

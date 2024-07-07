{
  config,
  baseDomain,
  ...
}:

let
  domain = "monitoring.${baseDomain}";
in {
  sops.secrets = {
    "grafana/secret_key".owner = "grafana";
    "grafana/smtp_password".owner = "grafana";
    "grafana/smtp_user".owner = "grafana";
    "grafana/smtp_host".owner = "grafana";
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "grafana" ];
    ensureUsers = [
      { name = "grafana";
        ensureDBOwnership = true;
      }
    ];
  };

  services.grafana = {
    enable = true;

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${toString config.services.prometheus.port}/";
          isDefault = true;
          jsonData.timeInterval = config.services.prometheus.globalConfig.scrape_interval;
        }
        {
          name = "Alertmanager";
          type = "alertmanager";
          url = "http://localhost:${toString config.services.prometheus.alertmanager.port}/";
          isDefault = false;
          jsonData.implementation = "prometheus";
        }
      ];
    };

    settings = {
      analytics = {
        reporting_enabled = false;
        feedback_links_enabled = false;
      };
      feature_toggles.displayAnonymousStats = true;
      "auth.anonymous" = {
        enabled = true;
        org_name = "chaos.jetzt";
        org_role = "Viewer";
      };
      database = {
        type = "postgres";
        user = "grafana";
        host = "/run/postgresql";
      };
      security = {
        admin_email = "administration@chaos.jetzt";
        cookie_secure = true;
        secret_key = "$__file{${config.sops.secrets."grafana/secret_key".path}}";
        csrf_trusted_origins = [ domain ];
      };
      server = {
        inherit domain;
        root_url = "https://${domain}/grafana";
        protocol = "socket";
        socket = "/run/grafana/grafana.sock";
        serve_from_sub_path = true;
      };
      smtp = {
        enabled = true;
        host = "$__file{${config.sops.secrets."grafana/smtp_host".path}}";
        user = "$__file{${config.sops.secrets."grafana/smtp_user".path}}";
        password = "$__file{${config.sops.secrets."grafana/smtp_password".path}}";
        ehlo_identity = config.networking.fqdn;
        from_address = "grafana@chaos.jetzt";
      };
      users.viewers_can_edit = false;
      news.news_feed_enabled = false;
    };
  };

  users.users.nginx.extraGroups = [ "grafana" ];
  services.nginx.enable = true;
  services.nginx.virtualHosts.${domain} = {
    locations."/grafana" = {
      proxyPass = "http://unix:${toString config.services.grafana.settings.server.socket}";
      proxyWebsockets = true;
    };
    locations."/".return = "307 /grafana";
    enableACME = true;
    forceSSL = true;
  };

  cj.monitoring.blackbox.http = [ domain ];
}

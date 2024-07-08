{
  baseDomain,
  config,
  ...
}:

let
  domain = "monitoring.${baseDomain}";
in {
  imports = [
    ./alertmanager.nix
    ./prometheus.nix
    ./blackbox.nix
    ./grafana.nix
  ];

  sops.secrets."monitoring.htpasswd" = {
    format = "binary";
    owner = config.services.nginx.user;
    sopsFile = ../../../secrets/all/monitoring.htpasswd;
  };

  users.users.nginx.extraGroups = [ "grafana" ];
  services.nginx.enable = true;
  services.nginx.virtualHosts.${domain} =  let
    monitoring_htpasswd = config.sops.secrets."monitoring.htpasswd".path;
  in {
    enableACME = true;
    forceSSL = true;
    locations."/grafana" = {
      proxyPass = "http://unix:${toString config.services.grafana.settings.server.socket}";
      proxyWebsockets = true;
    };
    locations."/prometheus/" = {
      basicAuthFile = monitoring_htpasswd;
      proxyPass = "http://127.0.0.1:${builtins.toString config.services.prometheus.port}/";
    };
    locations."/alertmanager/" = {
      basicAuthFile = monitoring_htpasswd;
      proxyPass = "http://127.0.0.1:${builtins.toString config.services.prometheus.alertmanager.port}/";
    };
    locations."=/".return = "307 /grafana";
  };

  cj.monitoring.blackbox.http = [ domain ];
}

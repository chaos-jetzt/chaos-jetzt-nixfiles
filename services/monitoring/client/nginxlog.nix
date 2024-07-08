{ config, pkgs, lib, ... }:

with lib;
let
  parameters = [
    "time_local"
    "scheme"
    "server_name"
    "status"
    "body_bytes_sent"
    "request_length"
    "request_time"
    "upstream_response_time"
    "request_uri"
  ];
  logfile = "/var/log/nginx/access.log";
  log_format = concatStringsSep " " (map (p: "${p}=\"\$${p}\"") parameters);
in {
  services.nginx.appendHttpConfig = ''
    log_format nginxlog_exporter '${log_format}';
    access_log '${logfile}' nginxlog_exporter;
  '';

  services.prometheus.exporters.nginxlog = {
    inherit (config.services.nginx) enable group;
    settings.namespaces = [{
      format = log_format;
      metrics_override.prefix = "nginx";
      relabel_configs = [
        {
          target_label = "vhost";
          from = "server_name";
        }
        {
          target_label = "scheme";
          from = "scheme";
          only_counter = true;
        }
        {
          target_label = "status";
          from = "status";
          only_counter = true;
        }
        {
          target_label = "method";
          only_counter = true;
        }
      ];
      source_files = [ logfile ];
    }];
  };

  services.logrotate.settings.nginx = {
    frequency = "daily";
    rotate = "2"; # keep two versions
  };
}

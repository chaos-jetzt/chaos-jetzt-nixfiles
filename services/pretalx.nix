{ config
, lib
, baseDomain
, isDev
,... }:

let
  domain = "pretalx.${baseDomain}";
in {
  sops.secrets."pretalx_env" = {};
  services.pretalx = {
    enable = true;
    plugins = with config.services.pretalx.package.plugins; [
      public-voting
    ];
    settings = {
      site.url = "https://${domain}";
      redis.session = true;
      mail.from = "pretalx${lib.optionalString isDev "-dev"}@chaos.jetzt";
      locale = {
        language_code = "de";
      };
    };
    nginx = {
      inherit domain;
      enable = true;
    };
    database.createLocally = true;
    celery.enable = true;
  };

  systemd.services = let
    envfileConfig = {
      serviceConfig.EnvironmentFile = config.sops.secrets."pretalx_env".path;
    };
  in {
    pretalx-web = envfileConfig;
    pretalx-periodic = envfileConfig;
    pretalx-clear-sessions = envfileConfig;
    pretalx-worker = envfileConfig;
  };

  services.nginx = {
    enable = true;
    virtualHosts."${domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/".recommendedProxySettings = true;
    };
  };

  cj.monitoring.blackbox.http = [ domain ];
}

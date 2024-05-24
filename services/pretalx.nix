{ config, baseDomain, ... }:

let
  domain = "pretalx.${baseDomain}";
in {
  services.pretalx = {
    enable = true;
    settings = {
      site.url = "https://${domain}";
      redis.session = true;
    };
    nginx = {
      inherit domain;
      enable = true;
    };
    database.createLocally = true;
    celery.enable = true;
  };

  services.nginx = {
    enable = true;
    virtualHosts."${domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/".recommendedProxySettings = true;
    };
  };
}

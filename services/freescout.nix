{ pkgs, config, baseDomain, ... }:

let
  domain = "support.${baseDomain}";
in {
  sops.secrets."freescout/app_key" = {
    owner = "freescout";
    format = "yaml";
    sopsFile = ../secrets/all/secrets.yaml;
  };

  services.freescout = {
    inherit domain;
    enable = true;
    phpPackage = pkgs.php82;

    settings = {
      APP_KEY._secret  = config.sops.secrets."freescout/app_key".path;
      APP_ENV = "local";
      APP_DEBUG = true;
    };
    databaseSetup.enable = true;
    nginx = {
      forceSSL = true;
      enableACME = true;
    };
  };

  cj.monitoring.blackbox.http = [ domain ];
}

{ pkgs, config, baseDomain, ... }:

{
  sops.secrets."freescout/app_key" = {
    owner = "freescout";
    format = "yaml";
    sopsFile = ../secrets/all/secrets.yaml;
  };

  services.freescout = {
    enable = true;
    domain = "support.${baseDomain}";
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
}

{
  pkgs,
  config,
  baseDomain,
  modulesPath,
  ...
}:

let
  domain = "support.${baseDomain}";
in
{

  config = {
    sops.secrets."freescout/app_key" = {
      owner = "freescout";
      format = "yaml";
      sopsFile = ../secrets/all/secrets.yaml;
    };

    services.freescout = {
      inherit domain;
      enable = true;
      package = pkgs.freescout.overrideAttrs (oa: {
        version = "1.8.241";
        src = oa.src.overrideAttrs {
          hash = "sha256-iHg9KSSksV4+ZbCn+aC0ubNDt91CbuZDK3K5Bf7qIi4=";
        };
      });
      # It has to be php83 since starting with php84, opcache
      # (which the old freescout-nix-flake assumes to exist)
      # is not included as an plugin anymore.
      phpPackage = pkgs.php83;

      settings = {
        APP_KEY._secret = config.sops.secrets."freescout/app_key".path;
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
  };
}

{ pkgs
, config
, baseDomain
, isDev
, ...
}:

let
  sso_domain = "sso.${baseDomain}";
in {
  imports = [
    ./ldap.nix
  ];

  sops.secrets = {
    "keycloak/db_password" = {};
  };
  services.keycloak = {
    enable = true;
    database = {
      createLocally = true;
      host = "localhost";
      name = "keycloak";
      passwordFile = config.sops.secrets."keycloak/db_password".path;
      type = "postgresql";
    };
    settings = {
      hostname = sso_domain;
      http-host = "127.0.0.1";
      http-relative-path = "/auth";
      http-enabled = true;
      http-port = 8081;
      proxy-headers = "xforwarded";
      spi-connections-jpa-legacy-migration-strategy = "update";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."${sso_domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:${toString config.services.keycloak.settings.http-port}";
      locations."= /".return = "307 ${config.services.keycloak.settings.http-relative-path}/realms/${if !isDev then "chaos-jetzt" else "dev"}/account/";
    };
  };
}

{ lib
, config
, pkgs
, baseDomain
, isDev
, ... }:

let
  vwDbUser = config.users.users.vaultwarden.name;
  vwDbName = config.users.users.vaultwarden.name;
  isDevStr = lib.optionalString isDev;
in {
  sops.secrets = {
    "vaultwarden/env" = {};
  };

  services.nginx.virtualHosts."passwords.${baseDomain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:${builtins.toString config.services.vaultwarden.config.ROCKET_PORT}";
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ vwDbName ];
    ensureUsers = [{
      name = vwDbUser;
      ensurePermissions = {
        "DATABASE ${vwDbName}" = "ALL PRIVILEGES";
      };
    }];
  };

  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    environmentFile = config.sops.secrets."vaultwarden/env".path;
    config = let
      name = "${isDevStr "[dev] "}chaos.jetzt Vaultwarden";
    in {
      # NOTE (@e1mo): I would _realy_ like to disable E-Mail based 2FA
      # _ENABLE_EMAIL_2FA = false;
      DATABASE_URL = "postgresql:///${vwDbName}";
      DOMAIN = "https://passwords.${baseDomain}";
      EVENTS_DAYS_RETAIN = 60;
      # Do we want to keep an event log of who viewed whihc password when?
      # See <https://bitwarden.com/de-DE/help/event-logs/> for reference
      EXTENDED_LOGGING = true;
      HELO_NAME = config.networking.fqdn;
      ICON_BLACKLIST_NON_GLOBAL_IPS = true;
      INCOMPLETE_2FA_TIME_LIMIT = 5;
      INVITATION_ORG_NAME = name;
      INVITATIONS_ALLOWED = true;
      LOG_LEVEL = if isDev then "info" else "warn";
      ORG_EVENTS_ENABLED = false;
      PASSWORD_HINTS_ALLOWED = false;
      ROCKET_ADDRESS = "127.0.0.1"; # Binding to a unix socket (or at least IPv6 _and_ IPv4) would be desirable but is not yet supported in Rocket
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = false;
      SMTP_FROM = "vaultwarden${isDevStr "-dev"}@chaos.jetzt";
      SMTP_FROM_NAME = "${name} Vaultwarden";
      SMTP_SECURITY = "force_tls";
      USE_SYSLOG = true;
    };
  };

  systemd.services.vaultwarden = {
    after = [ "postgresql.service" ];
  };
}

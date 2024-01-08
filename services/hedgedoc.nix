{ config
, baseDomain
, lib
, ...
}:

let
  domain = "md.${baseDomain}";
  isDev = (builtins.substring 0 3 baseDomain) == "dev";
  realm = if isDev then "dev" else "chaos-jetzt";
  sso_url = "https://sso.chaos.jetzt/auth/realms/${realm}/protocol/openid-connect";
  sock_path = "/run/hedgedoc/hedgedoc.sock";
in {
  # Contains CMD_SESSION_SECRET and CMD_OAUTH2_CLIENT_SECRET
  sops.secrets."hedgedoc_env" = {};

  services.hedgedoc = {
    enable = true;
    environmentFile = config.sops.secrets.hedgedoc_env.path;
    settings = {
      inherit domain;

      allowAnonymousEdits = true;
      allowEmailRegister = false;
      allowFreeURL = true;
      requireFreeURLAuthentication = false;
      allowGravatar = false;
      allowOrigin = [ domain ];
      db = {
        dialect = "postgres";
        host = "/run/postgresql";
      };
      email = false;
      path = sock_path;
      protocolUseSSL = true;
      # NOTE(@e1mo): Currently disabled until we decide if we want
      # SSO but left in here as this is a known working config.
      oauth2 = lib.mkIf false {
        baseURL = sso_url;
        userProfileURL = "${sso_url}/userinfo";
        userProfileUsernameAttr = "preferred_username";
        userProfileDisplayNameAttr = "preferred_username";
        userProfileEmailAttr = "email";
        tokenURL = "${sso_url}/token";
        authorizationURL = "${sso_url}/auth";
        clientID = "hedgedoc";
        providerName = if isDev then "SSO (dev)" else "SSO";
      };
      useCDN = false;
      logLevel = "warn";
    };
  };

  services.nginx.virtualHosts."${domain}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://unix:${sock_path}";
      proxyWebsockets = true;
    };
  };


  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hedgedoc" ];
    ensureUsers = [{
      name = "hedgedoc";
      ensureDBOwnership = true;
    }];
  };

  # Required for nginx to be able to access the hedgedoc socket
  users.users.nginx.extraGroups = [ "hedgedoc" ];
}

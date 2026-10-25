{
  config,
  lib,
  baseDomain,
  isDev,
  ...
}:

{
  sops.secrets = {
    "mas/encryption_secret" = { };
    "mas/shared_secret" = { };
    "mas/signing_keys/rsa" = { };
    "mas/signing_keys/prime256v1" = { };
    "mas/signing_keys/secp384r1" = { };
    "mas/signing_keys/secp256k1" = { };
    "mas/email/smtp_pass" = { };
    "mas/upstream/client_secret" = {};
  };
  services.matrix-authentication-service = {
    enable = true;
    createDatabase = true;
    credentials = {
      encryption = config.sops.secrets."mas/encryption_secret".path;
      shared_secret = config.sops.secrets."mas/shared_secret".path;
      signing_rsa = config.sops.secrets."mas/signing_keys/rsa".path;
      signing_prime256v1 = config.sops.secrets."mas/signing_keys/prime256v1".path;
      signing_secp384r1 = config.sops.secrets."mas/signing_keys/secp384r1".path;
      signing_secp256k1 = config.sops.secrets."mas/signing_keys/secp256k1".path;
      oidc_client_secret = config.sops.secrets."mas/upstream/client_secret".path;
      email_password = config.sops.secrets."mas/email/smtp_pass".path;
    };
    settings = {
      http = {
        public_base = "https://${config.cj.matrix.mas.domain}";
        trusted_proxies = [
          "127.0.0.0/8"
          "::1/128"
        ];
        listeners = [
          {
            name = "web";
            resources = [
              { name = "discovery"; }
              { name = "human"; }
              { name = "oauth"; }
              { name = "compat"; }
              { name = "graphql"; }
              { name = "assets"; }
            ];
            binds = [
              {
                # host = "/run/mask-web.sock";
                host = "localhost";
                port = 8080;
              }
            ];
          }
          {
            name = "internal";
            resources = [
              { name = "health"; }
              { name = "prometheus"; }
            ];
            binds = [
              {
                host = "localhost";
                port = 8081;
              }
            ];
          }
        ];
      };
      matrix = {
        homeserver = config.cj.matrix.synapse.domain;
        endpoint = "http://[::1]:${toString config.cj.matrix.synapse.port}";
        kind = "synapse";
        secret_file = "\${CREDENTIALS_DIRECTORY}/shared_secret";
      };
      secrets = {
        encryption_file = "\${CREDENTIALS_DIRECTORY}/encryption";
        keys = [
          {
            key_file = "\${CREDENTIALS_DIRECTORY}/signing_rsa";
          }
          {
            key_file = "\${CREDENTIALS_DIRECTORY}/signing_prime256v1";
          }
          {
            key_file = "\${CREDENTIALS_DIRECTORY}/signing_secp384r1";
          }
          {
            key_file = "\${CREDENTIALS_DIRECTORY}/signing_secp256k1";
          }
        ];
      };
      passwords.enabled = false;
      account = {
        email_change_allowed = false;
        displayname_change_allowed = true;
        password_registration_enabled = false;
      };
      telemetry = {
        metrics.exporter = "prometheus";
      };
      email = {
        # Credentials configured in extraConfigFiles
        mode = "tls";
        from = "\"${baseDomain} matrix\" <matrix${lib.optionalString isDev "-dev"}@chaos.jetzt>";
        reply_to = "\"No reply\" <no-reply@chaos.jetzt>";
        transport = "smtp";
        port = 465;
        hostname = "smtp.mailbox.org";
        username = "mail@chaos.jetzt";
        password_file = "\${CREDENTIALS_DIRECTORY}/email_password";
      };
      upstream_oauth2.providers = [
        {
          id = if isDev then "01M5PR7VSHYSE7HH48H1FZMQWB" else "01M5PR6W6XGHTNNM4HQ50WBYJ5";
          enabled = true;
          issuer = "https://sso.chaos.jetzt/auth/realms/${if isDev then "dev" else "chaos-jetzt"}";
          token_endpoint_auth_method = "client_secret_basic";
          client_id = "matrix-authentication-service";
          client_secret_file = "\${CREDENTIALS_DIRECTORY}/oidc_client_secret";
          scope = "openid profile email";
          claims_imports = {
            localpart = {
              action = "suggest";
              template = "{{ user.preferred_username }}";
            };
            displayname = {
              action = "suggest";
              template = "{{ user.preferred_username }}";
            };
            email = {
              action = "force";
              template = "{{ user.email }}";
            };

          };
          # When password login is disabled and a single upstream provider
          # is configured, signing out of the authentication service redirects
          # to /login, which immediately redirects back to the upstream provider
          # If that provider still has a live session, it will silently sign the
          # user straight back in, making the “sign out” button appear to do nothing.
          # Source: https://element-hq.github.io/matrix-authentication-service/setup/sso.html#forcing-re-authentication-after-sign-out
          additional_authorization_parameters = {
            # Send `prompt=login` only right after the browser signed out.
            prompt = "{% if logged_out %}login{% endif %}";
          };
        }
      ];
    };
  };

  services.nginx.virtualHosts = {
    "mas.${baseDomain}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://localhost:8080";
        recommendedProxySettings = true;
      };
    };
  };
}

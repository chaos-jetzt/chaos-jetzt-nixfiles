{ lib, config, pkgs, baseDomain, ... }:  let
  matrixPort = 8008;
  metricsPort = 8100;
  isDev = (builtins.substring 0 3 baseDomain) == "dev";
  synapseDb = config.services.matrix-synapse.settings.database.args;
  initSynapseDb = ''CREATE DATABASE "${synapseDb.database}" WITH OWNER "${synapseDb.user}" ENCODING "UTF8" TEMPLATE template0 LC_COLLATE = "C" LC_CTYPE = "C";'';

  elementDomain = "chat.${baseDomain}";
  backendDomain = "matrix.${baseDomain}";
in {
  sops.secrets = {
    "coturn_static_auth_secret".owner = "turnserver";
    "synapse/signing_key" = {
      owner = "matrix-synapse";
      path = config.services.matrix-synapse.settings.signing_key_path;
      mode = "0600";
    };
    "synapse/secret_config".owner = "matrix-synapse";
    "synapse/registration_shared_secret".owner = "matrix-synapse";
  };

  imports = [
    ./matrixjoinlink.nix
  ];

  services.nginx = {
    recommendedProxySettings = true;
    virtualHosts = {
      "${elementDomain}" = {
        enableACME = true;
        forceSSL = true;

        root = pkgs.element-web.override {
        # Somewhat duplicate of the stuff in website.nix but I am
        # not sure if we absolutely need to dedup this, just out of complexity perspective
        conf = {
          default_server_config."m.homeserver" = {
            base_url = "https://${backendDomain}/";
            server_name = baseDomain;
          };
          default_country_code = "DE";
        };
      };
    };
    "${backendDomain}"  = {
      enableACME = true;
      forceSSL = true;
      # It's also possible to do a redirect here or something else, this vhost is not
      # needed for Matrix. It's recommended though to *not put* element
      # here, see also the section about Element.
      locations."/".extraConfig = ''
        return 404;
      '';
      # Forward all Matrix API calls to the synapse Matrix homeserver. A trailing slash
      # *must not* be used here.
      locations."/_matrix" = {
        proxyPass = "http://[::1]:${toString matrixPort}";
        recommendedProxySettings = true;
      };
      # Forward requests for e.g. SSO and password-resets.
      locations."/_synapse/client" = {
        proxyPass = "http://[::1]:${toString matrixPort}";
        recommendedProxySettings = true;
      };
      # For blackbox monitoring purposes.
      locations."/health" = {
        proxyPass = "http://[::1]:${toString matrixPort}";
        recommendedProxySettings = true;
      };
      # # Allow public access to the synapse admin API
      # # The docs advise against leaving this open to just everyone. That's why this currently is commented out
      # # if admin things need to be done, it's required to SSH to the server and then direct all admin requests to
      # # localhost:8008/_synapse/admin
      # # Leaving that in here for when I (e1mo) wonder why calls to the admin API don't work in the future
      # locations."/_synapse/admin".proxyPass = "http://[::1]:${toString matrixPort}";
    };
  };
};

  services.postgresql = {
    enable = true;
    ensureUsers = [
      { name = synapseDb.user; }
    ];
  };
  systemd.services.postgresql = {
    postStart = ''
      $PSQL -tAc "SELECT 1 FROM pg_database WHERE datname = 'matrix-synapse'" | grep -q 1 || $PSQL -tAc '${initSynapseDb}'
    '';
  };

  security.acme.certs."turn.${baseDomain}" = {
    group = "turnserver";
    reloadServices = [ "coturn.service" ];
  };
  services.coturn = let
    sslDir = config.security.acme.certs."turn.${baseDomain}".directory;
  in {
    enable = true;
    cert = "${sslDir}/fullchain.pem";
    pkey = "${sslDir}/key.pem";
    static-auth-secret-file = config.sops.secrets."coturn_static_auth_secret".path;
  };

  services.matrix-synapse = {
    enable = true;
    plugins = [
      pkgs.python3Packages.matrix-synapse-saml-mapper
    ];
    settings = {
      server_name = baseDomain;
      public_baseurl = "https://${backendDomain}";
      allow_public_rooms_over_federation = true;
      enable_registration = false;
      registration_shared_secret_path = config.sops.secrets."synapse/registration_shared_secret".path;
      log_config = ./synapse-log_config.yaml;
      database = {
        name = "psycopg2";
        args.database = "matrix-synapse";
      };
      federation_ip_range_blacklist = [
        "127.0.0.0/8"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "100.64.0.0/10"
        "169.254.0.0/16"
        "::1/128"
        "fe80::/64"
        "fc00::/7"
      ];

      admin_contact = "mailto:administration@chaos.jetzt";
      url_preview_enabled = true;
      media_store_path = "/mnt/synapse_media_store";
      turn_uris = let
        turn_base = "turn.${baseDomain}";
        ct = config.services.coturn;
        port = builtins.toString ct.listening-port;
        tlsPort = builtins.toString ct.tls-listening-port;
      in [
        "turn:${turn_base}:${port}?transport=tcp"
        "turn:${turn_base}:${port}?transport=udp"
        "turns:${turn_base}:${tlsPort}?transport=tcp"
        "turns:${turn_base}:${tlsPort}?transport=udp"
      ];
      auto_join_rooms = builtins.map (v: "#${v}:${baseDomain}") [ "grosse_halle" "allgemein" ];
      autocreate_auto_join_rooms = true;
      enable_metrics = true;
      user_directory = {
        enabled = true;
        search_all_users = true;
      };
      saml2_config = {
        enabled = true;
        sp_config.metadata.remote = [{
          url = "https://sso.chaos.jetzt/auth/realms/${if isDev then "dev" else "chaos-jetzt"}/protocol/saml/descriptor";
        }];
        user_mapping_provider.module = "matrix_synapse_saml_mapper.SamlMappingProvider";
      };
      password_config.enabled = "only_for_reauth";
      media_retention = {
        # Since clearing remote media does the trick for now when it comes to purging old media
        # keeping local media for virtually unlimited time (for now, may change in the future).
        local_media_lifetime = "10y";
        remote_media_lifetime = "90d";
      };
    };
    extraConfigFiles = let
      format = (pkgs.formats.yaml {}).generate;
    in [
      # Contains turn_shared_secret, macaroon_secret_key, and form_secret
      config.sops.secrets."synapse/secret_config".path
      # For our saml sso stuff we need to have additional_ressouces, but they are not possible with the NixOS module listener
      (format "additional_ressources.yaml" {
        listeners = [
          {
            bind_addresses = [ "::1" "127.0.0.1" ];
            port = matrixPort;
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [{
              names = [ "client" "federation" ];
              compress = false;
            }];
            additional_resources."/_matrix/saml2/pick_username".module = "matrix_synapse_saml_mapper.pick_username_resource";
          }
          {
            type = "metrics";
            port = 8100;
            # Protected by the firewall
            bind_addresses = ["::"];
            # bind_addresses = ["::1" "127.0.0.1"];
          }
        ];
      })
    ];
  };

  system.activationScripts."synapse-media-store-mnt".text = ''
      mkdir -p ${lib.escapeShellArg config.services.matrix-synapse.settings.media_store_path}
      chown matrix-synapse:matrix-synapse ${lib.escapeShellArg config.services.matrix-synapse.settings.media_store_path}
  '';
  systemd.services.matrix-synapse = {
    unitConfig.RequiresMountsFor = [ config.services.matrix-synapse.settings.media_store_path ];
    serviceConfig.ReadWritePaths = [ config.services.matrix-synapse.settings.media_store_path ];
  };

  cj.monitoring.blackbox.http = [ elementDomain "${backendDomain}/health" ];
  cj.monitoring.synapse = [ metricsPort ];
}

{ baseDomain, isDev, config, ... }:

let
  domain = "pretix.${baseDomain}";
in {
  sops.secrets.pretix_env = {};

  services.pretix = {
    enable = true;
    environmentFile = config.sops.secrets.pretix_env.path;
    settings = {
      pretix = {
        instance_name = domain;
        url = "https://${domain}";
        currency = "EUR";
        loglevel = if isDev then "INFO" else "WARNING";
        plugins_default = "pretix.plugins.sendmail,pretix.plugins.statistics,pretix.plugins.ticketoutputpdf";
        plugins_exclude = "pretix.plugins.paypal,pretix.plugins.paypal2,pretix.plugins.stripe,pretix.plugins.banktransfer";
        audit_comments = true;
        obligatory_2fa = true;
        trust_x_forwarded_for = true;
        trust_x_forwarded_proto = true;
        trust_x_forwarded_host = true;
      };
      locale = {
        default = "de-informal";
        timezone = "Europe/Berlin";
      };
      database = {
        backend = "postgresql";
        name = "pretix";
        user = "pretix";
      };
      mail = {
        from = "pretix@chaos.jetzt";
        # environmentFile contains user, password, host, port, tls and ssl options
        admins = "administration@chaos.jetzt";
      };
      django = {
        # PRETIX_DJANGO_SECRET contained in environmentFile
        debug = false;
      };
      languages = {
        enabled = "en,de-informal";
      };
    };

    database.createLocally = true;
    nginx = {
      inherit domain;
      enable = true;
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."${domain}" = {
      serverAliases = [ "tickets.${baseDomain}" ];
      enableACME = true;
      forceSSL = true;
      locations."/".recommendedProxySettings = true;
      locations."/jetzt5".return = "307 https://tickets.chaostreff-flensburg.de/chaos.jetzt/jetzt5";
    };
  };
}

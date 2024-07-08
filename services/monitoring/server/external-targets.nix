{
  lovelace = {
    _module.args = {
      isDev = false;
      baseDomain = "chaos.jetzt";
    };
    config = {
      cj = {
        deployment.environment = "prod";
        monitoring.blackbox.http = ["sso.chaos.jetzt/health/ready"];
      };
      networking = rec {
        hostName = "lovelace";
        domain = "net.chaos.jetzt";
        fqdn = "${hostName}.${domain}";
      };
      services.prometheus = {
        enable = true;
        port = 9090;
        alertmanager = {
          enable = true;
          port = 9093;
        };
      };
    };
  };
}

{
  config,
  lib,
  baseDomain,
  ...
}:

let
  inherit (lib) mkOption types optionalString;

  cfg = config.cj.deployment;
  isDev = cfg.environment == "dev";
in
{
  options.cj.deployment = {
    environment = mkOption {
      description = "Environment this host will be used for. Affects both colmena deploy groups and the baseDomain";
      type = types.enum [
        "dev"
        "prod"
      ];
    };
  };

  # We need these values both in the mas config and the synapse config
  # Since they are in separate files, this seems like a decent way to
  # ensure they are in sync.
  options.cj.matrix = {
    synapse = {
      domain = mkOption {
        description = "domain [matrix] is available under";
        default = "matrix.${baseDomain}";
        readOnly = true;
        type = types.str;
      };
      port = mkOption {
        description = "Port matrix will listen on";
        default = 8008;
        type = types.port;
        readOnly = true;
      };
    };
    mas.domain = mkOption {
      type = types.str;
      description = "domain matrix authentication service is available under";
      default = "mas.${baseDomain}";
      readOnly = true;
    };
  };

  options.cj.monitoring = {
    interface = mkOption {
      description = "Interface the monitoring network is attached";
      type = types.str;
    };

    blackbox = {
      "http" = mkOption {
        type = with types; listOf str;
        default = [ ];
      };

      "tcp_tls" = mkOption {
        type = with types; listOf str;
        default = [ ];
      };
    };

    pretix = mkOption {
      description = "Prometheus endpoints to scrape";
      type = with types; listOf str;
      default = [ ];
    };

    synapse = mkOption {
      description = "Port where the metrics listener is located";
      type = with types; listOf int;
      default = [ ];
    };

    ports = mkOption {
      description = "List of ports to allow on the monitoring interface (convenience function)";
      type = with types; listOf port;
      default = [ ];
    };
  };

  config = {
    _module.args = {
      inherit isDev;
      baseDomain = "${optionalString isDev "dev."}chaos.jetzt";
    };
  };
}

{ config
, lib
, ... }:

let
  inherit (lib) mkOption types optionalString;

  cfg = config.cj.deployment;
  isDev = cfg.environment == "dev";
in
{
  options.cj.deployment = {
    environment = mkOption {
      description = "Environment this host will be used for. Affects both colmena deploy groups and the baseDomain";
      type = types.enum [ "dev" "prod" ];
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
        default = [];
      };

      "tcp_tls" = mkOption {
        type = with types; listOf str;
        default = [];
      };
    };

    pretix = mkOption {
      description = "Prometheus endpoints to scrape";
      type = with types; listOf str;
      default = [];
    };

    synapse = mkOption {
      description = "Port where the metrics listener is located";
      type = with types; listOf int;
      default = [];
    };

    ports = mkOption {
      description = "List of ports to allow on the monitoring interface (convenience function)";
      type = with types; listOf port;
      default = [];
    };
  };

  config = {
    _module.args = {
      inherit isDev;
      baseDomain = "${optionalString isDev "dev."}chaos.jetzt";
    };
  };
}

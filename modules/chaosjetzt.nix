{ config
, options
, lib
, ... }:

let
  inherit (lib) mkOption types optionalString;

  cfg = config.cj;
  isDev = cfg.deployment.environment == "dev";
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
    ip = mkOption {
      description = "Hosts IP in the monitoring network";
      type = types.str;
    };
  };

  config = {
    _module.args = {
      inherit isDev;
      baseDomain = "${optionalString isDev "dev."}chaos.jetzt";
    };
  };
}

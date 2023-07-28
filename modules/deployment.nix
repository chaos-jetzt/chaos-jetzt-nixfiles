{ config
, options
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

  config = {
    _module.args = {
      inherit isDev;
      baseDomain = "${optionalString isDev "dev."}chaos.jetzt";
    };
  };
}

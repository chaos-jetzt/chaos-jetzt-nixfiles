{ lib, pkgs, config, baseDomain, ...}:
let
  matrixWellKnown = {
    client."m.homeserver".base_url = "https://matrix.${baseDomain}/";
    server."m.server" = "matrix.${baseDomain}:443";
  };
  toJSONFile = name: value: pkgs.writeText name (builtins.toJSON value);
  matrixWellKnownDir = pkgs.linkFarm "matrix-well-known" (builtins.mapAttrs toJSONFile matrixWellKnown);
in {
  services.nginx = {
    enable = true;
    enableReload = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts.${baseDomain} = {
      default = true;
      enableACME = true;
      forceSSL = true;
      serverAliases = [ "www.${baseDomain}" ];
      # TODO: Change this to be deployed by some sort of CI + rsync so we don't need to always update the package version
      locations."/".root = pkgs.chaos-jetzt-website-pelican;
      locations."/.well-known/matrix/".alias =  matrixWellKnownDir + "/";
    };
  };
}
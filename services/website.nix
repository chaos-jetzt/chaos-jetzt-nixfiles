{ pkgs, baseDomain, ...}: {
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
      # TODO: Change this to be deployed by some sort of CI + rsync so we don't need to always update the package version
      locations."/".root = pkgs.chaos-jetzt-website-pelican;
    };
  };
}
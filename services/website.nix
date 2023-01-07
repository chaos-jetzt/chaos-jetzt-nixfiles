{ lib, pkgs, config, baseDomain, ...}:
let
  matrixWellKnown = {
    client."m.homeserver".base_url = "https://matrix.${baseDomain}/";
    server."m.server" = "matrix.${baseDomain}:443";
  };
  toJSONFile = name: value: pkgs.writeText name (builtins.toJSON value);
  matrixWellKnownDir = pkgs.linkFarm "matrix-well-known" (builtins.mapAttrs toJSONFile matrixWellKnown);
  isDev = (builtins.substring 0 3 baseDomain) == "dev";
  webroot = "${config.users.users."web-deploy".home}/public";
  deployPubKey = if isDev then
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINRmpgMjXQCjA/YPNJvaNdKMjr0jnLtwKKbLCIisjeBw dev-deploykey@chaos.jetzt"
  else
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGfluahnK/YEaj97EN5SjOfUw6vHK13cxfCKIj6wafdB prod-deploykey@chaos.jetzt"
  ;
  restrictedPubkey = "command=\"${pkgs.rrsync}/bin/rrsync ${webroot}\" ${deployPubKey}";
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
      locations."/".root = webroot;
      locations."/.well-known/matrix/".alias =  matrixWellKnownDir + "/";
    };
  };

  users.users."web-deploy" = {
    shell = "/bin/sh";
    createHome = true;
    isSystemUser = true;
    # Allow group to read
    home = "/var/lib/website";
    homeMode = "750";
    group = config.services.nginx.group;
    openssh.authorizedKeys.keys = [ restrictedPubkey ];
  };

  system.activationScripts.web-deploy-public = ''
    mkdir -m 0750 -p ${webroot}
    # https://stackoverflow.com/a/17902999
    if  [[ ! $(ls -A ${webroot} ) ]]; then
      echo "${webroot} is empty"
      cp -a ${pkgs.chaos-jetzt-website-pelican}/* ${webroot}/
      chmod -R ${config.users.users."web-deploy".homeMode} ${webroot}
      chown -R web-deploy:${config.services.nginx.group} ${webroot}
    fi
  '';
}

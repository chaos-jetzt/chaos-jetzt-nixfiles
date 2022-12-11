{ config, baseDomain, lib, ... }: {
  sops.secrets."murmur/registry_password".owner = "murmur";
  security.acme.certs."mumble.${baseDomain}" = {
    group = "murmur";
    reloadServices = [ "murmur.service" ];
  };

  services.murmur = let
    sslDir = config.security.acme.certs."mumble.${baseDomain}".directory;
  in {
    enable = true;
    openFirewall = true;
    sslCa = "${sslDir}/chain.pem";
    sslKey = "${sslDir}/key.pem";
    sslCert = "${sslDir}/fullchain.pem";
    welcometext = "Welcome on the ${baseDomain}-mumble server. Enjoy your stay!";
    bandwidth = 128000;
    registerName = baseDomain;
    registerUrl = "https://${baseDomain}/";
    registerPassword = "$MURMURD_REGISTRATION_PASSWORD";
    registerHostname = baseDomain;
    environmentFile = config.sops.secrets."murmur/registry_password".path;
    extraConfig = ''
      # To "randomize" user IP Adresses in logs
      obfuscate=true
    '';
  };
}
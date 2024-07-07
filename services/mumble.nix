{
  config,
  baseDomain,
  ...
}:
let
  domain = "mumble.${baseDomain}";
in {
  sops.secrets."murmur/registry_password".owner = "murmur";
  security.acme.certs."${domain}" = {
    group = "murmur";
    reloadServices = [ "murmur.service" ];
  };

  services.murmur = let
    sslDir = config.security.acme.certs."${domain}".directory;
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

  cj.monitoring.blackbox.tcp_tls = [ "${domain}:${toString config.services.murmur.port}" ];
}

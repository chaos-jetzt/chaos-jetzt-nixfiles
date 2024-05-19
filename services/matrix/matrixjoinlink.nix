{ config
, baseDomain
, ... }:

{
  imports = [
    ../../modules/matrixjoinlink.nix
  ];

  sops.secrets = {
    "matrixjoinlink/password" = {};
    "matrixjoinlink/encryptionKey" = {};
  };

  cj.matrixjoinlink = {
    enable = true;
    password_file = config.sops.secrets."matrixjoinlink/password".path;
    encryptionKey_file = config.sops.secrets."matrixjoinlink/encryptionKey".path;

    settings = {
      prefix = "join";
      baseUrl = config.services.matrix-synapse.settings.public_baseurl;
      username = "joinlink_bot";
      admins = [
        "@e1mo:${baseDomain}"
        "@ruru4143:gemeinsam.jetzt"
        "@adb:adb.sh"
        "@momme:${baseDomain}"
      ];
      users = [
        ":${baseDomain}"
      ];
    };
  };
}

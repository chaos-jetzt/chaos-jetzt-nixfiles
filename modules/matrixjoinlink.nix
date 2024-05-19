{ config
, pkgs
, lib
, ... }:

with lib;

let
  cfg = config.cj.matrixjoinlink;
  json = pkgs.formats.json {};
  hash = builtins.hashString "sha512";
  settings = cfg.settings // {
    password = "SECRET_${hash cfg.password_file}";
    encryptionKey = "SECRET_${hash cfg.encryptionKey_file}";
  };
  configUnsubstituted = json.generate "config.json" settings;
  setupSecrets = pkgs.writeShellScript "setup-secrets" ''
    set -o errexit -o pipefail -o nounset -o errtrace
    shopt -s inherit_errexit
    umask u=rw,g=,o=
    cp ${configUnsubstituted} $CONFIG_PATH
    chmod u+w $CONFIG_PATH
    ${getExe pkgs.replace-secret} "SECRET_${hash cfg.password_file}" "''${CREDENTIALS_DIRECTORY}/password" "''${CONFIG_PATH}"
    ${getExe pkgs.replace-secret} "SECRET_${hash cfg.encryptionKey_file}" "''${CREDENTIALS_DIRECTORY}/encryptionKey" "''${CONFIG_PATH}"
  '';
in {
  options.cj.matrixjoinlink = {
    enable = mkEnableOption "MatrixJoinLink bot";
    package = mkPackageOption pkgs "matrixjoinlink" {};

    password_file = mkOption {
      type = types.path;
      description = "Path to the password of the bot's account";
      example = "/run/secrets/matrixjoinlink/password";
    };

    encryptionKey_file = mkOption {
      type = types.path;
      description = "Path to a symmetric key that will be used to encrypt the event content for the bot";
      example = "/run/secrets/matrixjoinlink/encryptionkey";
    };

    settings = {
      prefix = mkOption {
        type = types.str;
        default = "join";
        description = "The command prefix the bot listens to";
      };

      baseUrl = mkOption {
        type = types.str;
        description = "The base url of the matrix server the bot shall use";
        example = literalExpression "config.services.matrix-synapse.settings.public_baseurl";
      };

      username = mkOption {
        type = types.str;
        description = "The username of the bot's account";
      };

      dataDirectory = mkOption {
        type = types.path;
        description = "The path to the databases and media folder";
        default = "/var/lib/matrixjoinlink/data";
      };

      admins = mkOption {
        type = with types; listOf str;
        description = "The matrix ids of the admins";
        example = literalExpression "[ \"@user:invalid.domain\" ]";
      };

      users = mkOption {
        type = with types; listOf str;
        description = "The matrix ids of the authorized users or servers";
        example = literalExpression "[ \":invalid.domain\" \"@other-user:another-invalid.domain\" ]";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.matrixjoinlink = rec {
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = [
        cfg.package
        pkgs.replace-secret
      ];

      environment.CONFIG_PATH = "%t/${serviceConfig.RuntimeDirectory}/config.json";

      serviceConfig = {
        DynamicUser = true;
        User = "matrixjoinlink";
        RuntimeDirectory = "matrixjoinlink";
        StateDirectory = "matrixjoinlink";
        StateDirectoryMode = "0700";

        Restart = "always";
        RestartSec = "10s";
        RestartSteps = 3;
        RestartMaxDelaySec = "1m";

        LoadCredential = [
          "password:${cfg.password_file}"
          "encryptionKey:${cfg.encryptionKey_file}"
        ];
        ExecStartPre = setupSecrets;
        ExecStart = getExe cfg.package;
      };

      unitConfig = {
        StartLimitIntervalSec = "5m";
        StartLimitBurst = 5;
      };

    };
  };
}

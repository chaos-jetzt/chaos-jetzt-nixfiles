{ config, lib, pkgs, inputs, ... }: {
  imports = [
    ./users.nix
    ../modules/chaosjetzt.nix
    # Monitoring is applicable to all hosts, thus placing it here
    ../services/monitoring/client
  ];

  environment = {
    systemPackages = with pkgs; [
      htop
      vim
      tmux
      rsync
      curl
      wget
      bat
      fd
      ripgrep
    ];
    enableAllTerminfo = true;
  };

  nix = {
    package = pkgs.nixVersions.stable;
    settings.auto-optimise-store = lib.mkDefault true;
    settings.trusted-users = [ "root" "@wheel" ];
    registry.nixpkgs.flake = inputs.nixpkgs;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };
  documentation.nixos.enable = false;
  console.keyMap = "de";
  time.timeZone = "Europe/Berlin";
  i18n = {
    defaultLocale = "de_DE.UTF-8";
    extraLocaleSettings.LC_MESSAGES = "en_US.UTF-8";
  };
  networking.domain = "net.chaos.jetzt";
  networking.firewall = {
    logRefusedConnections = false;
    enable = true;
    allowedTCPPorts = (lib.optionals (config.services.nginx.enable) [ 80 443 ])
      ++ config.services.openssh.ports;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  # That way we can't forget to disable the access logs for each individual website
  security.acme = {
    acceptTerms = true;
    defaults.email = "acme+${config.networking.hostName}@chaos.jetzt";
    defaults.webroot = "/var/lib/acme/acme-challenge";
  };

  sops = {
    defaultSopsFile = lib.mkDefault (../secrets + ("/" + config.networking.hostName) + "/secrets.yaml");
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  users.motd = ''
    ##### #####
    ####   ####    _____ _                         ___      _       _
    ###     ###   /  __ \ |                       |_  |    | |     | |
    ##   #   ##   | /  \/ |__   __ _  ___  ___      | | ___| |_ ___| |_
    #   ###   #   | |   | '_ \ / _` |/ _ \/ __|     | |/ _ \ __|_  / __|
    #    #    #   | \__/\ | | | (_| | (_) \__ \_/\__/ /  __/ |_ / /| |_
    #         #    \____/_| |_|\__,_|\___/|___(_)____/ \___|\__/___|\__|
    ##       ##
    ##  # #  ##
    #  ## ##  #        ${config.networking.fqdn}
    #  ## ##  #
    # ####### #
  '';

  services.journald.extraConfig = ''
    SystemMaxUse=2G
    SystemKeepFree=1G
    MaxRetentionSec=14d
  '';
}

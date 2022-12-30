{
  pkgs,
  config,
  lib,
  baseDomain,
  ...
}: let
  inherit (builtins) any hasAttr isAttrs isBool isInt isList isString;
  inherit (lib) boolToString concatMapStringsSep concatStringsSep escapeShellArg flatten mapAttrsToList;

  cfg = config.services.dokuwiki.sites.${dw_domain};
  fpm_pool = "dokuwiki-${dw_domain}";
  fpm_cfg = config.services.phpfpm.pools.${fpm_pool};
  dw_domain = "wiki.${baseDomain}";

  # Comming from Nextcloud module
  # Using opcache to cache the php-files in a precompiled state and thus better performance
  phpOptions = {
    expose_php = "Off";
    "opcache.interned_strings_buffer" = "8";
    "opcache.max_accelerated_files" = "10000";
    "opcache.memory_consumption" = "64";
    "opcache.revalidate_freq" = "15";
    "opcache.fast_shutdown" = "1";
  };
  phpPackage = pkgs.php81.buildEnv {
    extraConfig = toKeyValue phpOptions;
  };
  toKeyValue = with lib;
    generators.toKeyValue {
      mkKeyValue = generators.mkKeyValueDefault {} " = ";
    };

  # Taken
  mkPHPValue = v: let
    isHasAttr = s: isAttrs v && hasAttr s v;
  in
    if isString v
    then escapeShellArg v
    # NOTE: If any value contains a , (comma) this will not get escaped
    else if isList v && any lib.strings.isCoercibleToString v
    then escapeShellArg (concatMapStringsSep "," toString v)
    else if isInt v
    then toString v
    else if isBool v
    then toString (if v then 1 else 0)
    else if isHasAttr "_file"
    then "trim(file_get_contents(${lib.escapeShellArg v._file}))"
    else abort "The dokuwiki settings value ${lib.generators.toPretty {} v} can not be encoded.";

  # Present until https://github.com/NixOS/nixpkgs/pull/208299 is merged
  # so we can still use RFC42-Style settings in the meantime
  mkPHPAttrVals = v: flatten (mapAttrsToList mkPHPKeyVal v);
  mkPHPKeyVal = k: v: let
    values =
      if (isAttrs v && hasAttr "_file" v) || !isAttrs v
      then [" = ${mkPHPValue v};"]
      else mkPHPAttrVals v;
  in
    map (e: "[${escapeShellArg k}]${e}") (flatten values);
  mkConfigLines = c: map (v: "$conf${v}") (mkPHPAttrVals c);

  dokuwikiLocalConfig = settings: ''
    ${concatStringsSep "\n" (mkConfigLines settings)}
  '';

  acronyms = rec {
    "CCC" = "Chaos Computer Club";
    "PR" = "Pull Request";
    "pr" = PR;
    "GH" = "GitHub";
    "gh" = GH;
    "SSO" = "Single Sign-on";
    "sso" = SSO;
    "CTFL" = "Chaostreff Flensburg e.V.";
    "ctfl" = SSO;
  };

  acronyms_file = pkgs.writeText "acronyms.local.conf" ''
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (short: long: "${short}\t${long}") acronyms)}
  '';
in {
  sops.secrets = let
    dw.owner = fpm_cfg.user; # This is hardcoded to dokuwiki right now, however if that changes we should catch that here
    dw_all = key:
      dw
      // {
        inherit key;
        format = "yaml";
        sopsFile = ../secrets/all/secrets.yaml;
      };
  in {
    "dokuwiki/smtp_pass" = dw_all "smtp/pass";
    "dokuwiki/smtp_user" = dw_all "smtp/user";
    "dokuwiki/smtp_host" = dw_all "smtp/host";
    "dokuwiki/keycloak_key" = dw;
  };

  services.nginx.virtualHosts.${dw_domain} = {
    enableACME = true;
    forceSSL = true;
    # Disable search engine indexing
    # Reasong being that for example a search engine of your choosing can be used to find content
    # in relation to peoples (nick)name and stuff.
    locations."/robots.txt".return = "200 \"User-agent: *\nDisallow: /\"";
  };

  services.phpfpm.pools.${fpm_pool}.phpPackage = lib.mkForce phpPackage;

  services.dokuwiki.sites.${dw_domain} = {
    package = pkgs.dokuwiki.overrideAttrs (oldAttrs: {
      name = "dokuwiki-${dw_domain}-with-acronyms-${oldAttrs.version}";
      postInstall = oldAttrs.postInstall or "" + ''
          ln -s ${acronyms_file} $out/share/dokuwiki/conf/acronyms.local.conf
        '';
    });

    enable = true;
    aclUse = true;

    pluginsConfig = let
      plugins = {
        "tag" = true;
        "pagelist" = true;
        "smtp" = true;
        "sqlite" = true;
        "nspages" = true;
        "move" = true;
        "icalevents" = true;
        "legalnotice" = true;
        "oauth" = true;
        "oauthkeycloak" = true;
        "edittable" = true;
        "anonip" = true;

        "extension" = false;
        "popularity" = false;
        "authad" = false;
        "authldap" = false;
        "authmysql" = false;
        "authpdo" = false;
        "authpgsql" = false;
      };
    in ''
      # Placeholder until https://github.com/NixOS/nixpkgs/pull/208299 is merged
      ${concatStringsSep "\n" (mapAttrsToList (n: v: "$plugins['${n}'] = ${boolToString v};") plugins)};
    '';

    plugins = with pkgs.dokuwikiPlugins; [
      tag
      pagelist
      smtp
      nspages
      move
      icalevents
      oauth
      oauthkeycloak
      edittable
      anonip
    ];

    extraConfig = let
      get_secret = name: {_file = config.sops.secrets.${name}.path;};
      settings = rec {
        title = "${baseDomain} Wiki";
        lang = "de-informal";
        template = "dokuwiki";
        # authtype = "authplain";
        authtype = "oauth";
        subscribers = 1;
        userewrite = 1;
        useslash = 1;
        im_convert = "${pkgs.imagemagick}/bin/convert";
        superuser = "@admin";
        disableactions = "register";
        signature = "--- // [[name:@USER@|@USER@]] @DATE@";

        mailfrom = "\"@USER@\" via ${title} <wiki@chaos.jetzt>}";
        plugin.tag.toolbar_icon = 1;
        plugin.smtp = {
          smtp_host = get_secret "dokuwiki/smtp_host";
          smtp_user = get_secret "dokuwiki/smtp_host";
          smtp_pass = get_secret "dokuwiki/smtp_host";
          smtp_ssl = "ssl";
          smtp_port = 465;
        };
        plugin.icalevents = {
          locationUrlPrefix = "";
          "template:default" = ''
            === {date}: {summary} ===
            **Location**: {location_link}
            {description}'';
          "template:list" = ''
            === {date}: {summary} ===
            **<sup>Location: {location}</sup>**
            {description}'';
          "template:custom1" = ''
            === {date}: {summary} ===
            {description}
            **Wo?**: {location_link}'';
        };
        plugin.oauth = {
          register-on-auth = 1;
          singleService = "Keycloak";
        };
        plugin.oauthkeycloak = {
          key = get_secret "dokuwiki/keycloak_key";
          openidurl = "https://sso.chaos.jetzt/auth/realms/chaos-jetzt/.well-known/openid-configuration";
        };
      };
    in ''
      ${dokuwikiLocalConfig settings}
    '';
  };
}

final: prev:

{
  chaos-jetzt-website-pelican = final.stdenv.mkDerivation {
    name = "chaos-jetzt-website-pelican";

    src = prev.fetchFromGitHub {
      owner = "chaos-jetzt";
      repo = "website_pelican";
      rev = "89b1020678886a07446ac98db275a6db995c53ec";
      hash = "sha256-T3MSxMshlH3nFOttajDdacWGi1g+TkhjFlr+MjQlb/4=";
    };
    installTargets = "build";
    buildFlags = [
      "publish"
    ];
    installPhase = "
      cp -r public/ $out/
    ";
    buildInputs = with final.python3Packages; [
      pelican
      markdown
    ];
  };

  dokuwiki = prev.dokuwiki.overrideAttrs (oldAttrs: {
    installPhase = ''
      ${oldAttrs.installPhase}

      runHook postInstall
    '';
  });

  dokuwikiPlugins = {
    tag = final.stdenv.mkDerivation rec {
      name = "tag";
      pname = "dokuwiki-plugin-tag";
      version = "2022-10-02";
      src = final.fetchFromGitHub {
        owner = "dokufreaks";
        repo = "plugin-tag";
        rev = version;
        hash = "sha256-DVO3ZtXTtF8pBroF5VQiR2Vqa/FPxVzq81Jv9e9Z2EU=";
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    };
    pagelist = final.stdenv.mkDerivation rec {
      name = "pagelist";
      pname = "dokuwiki-plugin-pagelist";
      version = "2022-09-28";
      src = final.fetchFromGitHub {
        owner = "dokufreaks";
        repo = "plugin-pagelist";
        rev = version;
        hash = "sha256-IzedBYePVTS6jzWZeORpebsZiRgrnP+57t9mstQWnMQ=";
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    };
    smtp = final.stdenv.mkDerivation {
      name = "smtp";
      pname = "dokuwiki-plugin-smtp";
      version = "2022-09-11";
      src = final.fetchFromGitHub {
        owner = "splitbrain";
        repo = "dokuwiki-plugin-smtp";
        rev = "31226785e712be0c042f824019c08b7824db90ea";
        hash = "sha256-fwhOePzWGORmjS47/p+MZGhu1YstamlhdTjCxftu9eE=";
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    };
    nspages = final.stdenv.mkDerivation {
      name = "nspages";
      pname = "dokuwiki-plugin-nspages";
      version = "2022-11-27";
      src = final.fetchFromGitHub {
        owner = "gturri";
        repo = "nspages";
        rev = "2aeaf7dff24d8ce62a93477357e34834436634ff";
        hash = "sha256-U/mP8wtT6qE/MqMxePUt8XPD9kkGLErdWW0RCIQZZMI=";
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    };
    move = final.stdenv.mkDerivation rec {
      name = "move";
      pname = "dokuwiki-plugin-move";
      version = "2022-01-23";
      src = final.fetchFromGitHub {
        owner = "michitux";
        repo = "dokuwiki-plugin-move";
        rev = version;
        hash = "sha256-rQmbaRRFXoZhSPZnEYpiQ/sjGwp/Ij4Q9kCFWqbKLTY=";
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    };
    icalevents = final.stdenv.mkDerivation rec {
      name = "icalevents";
      pname = "dokuwiki-plugin-icalevents";
      version = "2017-06-16";
      src = final.fetchzip {
        stripRoot = false;
        url = "https://github.com/real-or-random/dokuwiki-plugin-icalevents/releases/download/${version}/dokuwiki-plugin-icalevents-${version}.zip";
        hash = "sha256-IPs4+qgEfe8AAWevbcCM9PnyI0uoyamtWeg4rEb+9Wc=";
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    };
    oauth = final.stdenv.mkDerivation {
      name = "oauth";
      pname = "dokuwiki-plugin-oauth";
      version = "2022-10-25";
      src = final.fetchFromGitHub {
        owner = "cosmocode";
        repo = "dokuwiki-plugin-oauth";
        rev = "da4733221ed7b4fb3ac0e2429499b14ece3d5f2d"; # 2022-10-25
        hash = "sha256-CNRlaieYm/KCjZ9+OP9pMo5SGjJ4CUrNNdL4iVktCcU=";
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    };
    oauthkeycloak = final.stdenv.mkDerivation {
      name = "oauthkeycloak";
      pname = "dokuwiki-plugin-oauthkeycloak";
      version = "2022-03-17";
      src = final.fetchFromGitHub {
        owner = "YoitoFes";
        repo = "dokuwiki-plugin-oauthkeycloak";
        rev = "28892edb0207d128ddb94fa8a0bd216861a5626b";
        hash = "sha256-nZo61nW9QjJiEo3FpYt1Zt7locuIDQ88AOn/ZnjjYUc=";
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    };
    edittable = final.stdenv.mkDerivation rec {
      name = "edittable";
      pname = "dokuwiki-plugin-edittable";
      version = "2022-01-22";
      src = final.fetchFromGitHub {
        owner = "cosmocode";
        repo = "edittable";
        rev = version;
        hash = "sha256-KzNUcZcK/y4SNdzuQACS+GqrrnaZIJlXFWUcYtfSxWY=";
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    };
    anonip = final.stdenv.mkDerivation rec {
      name = "anonip";
      pname = "dokuwiki-plugin-anonip";
      version = "2016-07-06";
      src = final.fetchFromGitHub {
        owner = "splitbrain";
        repo = "dokuwiki-plugin-anonip";
        rev = version;
        hash = "sha256-11a5vxxPRAPPaT4Qrmdx+LkxnsM/FDwyQr1T5Zcb42k=";
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    };
  };
}

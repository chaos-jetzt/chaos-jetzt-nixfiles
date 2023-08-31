final: prev:

{
  chaos-jetzt-website-pelican = final.stdenv.mkDerivation {
    pname = "chaos-jetzt-website-pelican";
    version = "2023-01-05";

    src = prev.fetchFromGitHub {
      owner = "chaos-jetzt";
      repo = "website_pelican";
      rev = "eb3e32ce87df9a5be3530d57215b997bcac34d81";
      hash = "sha256-PDxdlO1DYbgcz5BpEkpiqxT0hGKi0RSIpA+d2WKt8J0=";
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

  dokuwikiPlugins = {
    tag = final.stdenv.mkDerivation rec {
      name = "tag";
      pname = "dokuwiki-plugin-tag";
      version = "2023-05-25";
      src = final.fetchFromGitHub {
        owner = "dokufreaks";
        repo = "plugin-tag";
        rev = version;
        hash = "sha256-HipMbLK6LSdBfHGW03ekLp3Rvh2JQbAPyVIRRHug4GU=";
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
    smtp = final.stdenv.mkDerivation rec  {
      name = "smtp";
      pname = "dokuwiki-plugin-smtp";
      version = "2023-04-03";
      src = final.fetchFromGitHub {
        owner = "splitbrain";
        repo = "dokuwiki-plugin-smtp";
        rev = version;
        hash = "sha256-nvVsL94jJNu7wvyTL5hwMaSBTKHA3Z3YWg7+QtSZ8ss=";
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    };
    nspages = final.stdenv.mkDerivation {
      name = "nspages";
      pname = "dokuwiki-plugin-nspages";
      version = "2023-05-29";
      src = final.fetchFromGitHub {
        owner = "gturri";
        repo = "nspages";
        rev = "8763b40b3e9c79042055135e7c157aeaed5c078b";
        hash = "sha256-Fa8gtImR8tP8Vnhys9rZdtxl8Ii8cfrXZsTFNC0sD3w=";
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
    oauth = final.stdenv.mkDerivation rec {
      name = "oauth";
      pname = "dokuwiki-plugin-oauth";
      version = "2023-03-27";
      src = final.fetchFromGitHub {
        owner = "cosmocode";
        repo = "dokuwiki-plugin-oauth";
        rev = version;
        hash = "sha256-jyyKEhKp6LyHIq8vmaS1WOc+uyNxwHMt0kmSTSuOGKo=";
      };
      installPhase = "mkdir -p $out; cp -R * $out/";
    };
    oauthkeycloak = final.stdenv.mkDerivation rec {
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
      version = "2023-01-14";
      src = final.fetchFromGitHub {
        owner = "cosmocode";
        repo = "edittable";
        rev = version;
        hash = "sha256-Mns8zgucpJrg1xdEopAhd4q1KH7j83Mz3wxuu4Thgsg=";
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

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [(
    pfinal: pprev: {
      matrix-synapse-saml-mapper = pfinal.buildPythonPackage rec {
        pname = "matrix-synapse-saml-mapper";
        version = "2020-09-21";
        SETUPTOOLS_SCM_PRETEND_VERSION = "0.1+chaos.jetzt.${builtins.substring 0 6 src.rev}.d${builtins.replaceStrings ["-"] [""] version}";

        postPatch = ''
          substituteInPlace setup.py \
            --replace "attr>=0.3.1" "attrs"
        '';

        src = final.fetchFromGitHub {
          owner = "chaos-jetzt";
          repo = "matrix-synapse-saml-mapper";
          rev = "1aca2bfc73568a1a25d4e63a52b7a8ea9bdb7272";
          hash = "sha256-s2AQ92VQOXg7lxjWZKsM5h+4IWnsnLRbOC2mAmr1nZo=";
        };

        # This is absolutely ugly and not nice
        # In theory python should pick up the res as data files (manual bdist_wheel does manage to do so)
        # but somehow this isn't the case with buildPythonPackage
        # FIXME: Make this something more robus and "propper"
        postInstall = ''
          cp -ar $src/matrix_synapse_saml_mapper/res $out/lib/python*/site-packages/*/
        '';

        nativeBuildInputs = with pfinal; [
          setuptools-scm
        ];
        propagatedBuildInputs = with pfinal; [
          pysaml2
          attrs
          final.matrix-synapse-unwrapped
        ];
      };
  })];
}

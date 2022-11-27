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
}

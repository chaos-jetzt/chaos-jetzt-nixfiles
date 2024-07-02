{ lib, fetchpatch, fetchFromGitHub, jre, makeWrapper, maven }:

maven.buildMavenPackage rec {
  pname = "matrixjoinlink";
  version = "0.26.0";

  src = fetchFromGitHub {
    owner = "dfuchss";
    repo = "MatrixJoinLink";
    rev = "v${version}";
    hash = "sha256-HyN4QTyaplc7WDScEH8Xq78IfChpkhjuSdZGrU9ANHI=";
  };

  mvnHash = "sha256-mzZX9DToZF50lhFGJJV93GGmP2hzIh7dOyHfQKikSZU=";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin $out/share/${pname}
    install -Dm644 target/matrixjoinlink-${version}.jar $out/share/${pname}/${pname}.jar
    install -Dm644 target/matrixjoinlink-${version}-jar-with-dependencies.jar $out/share/${pname}/${pname}-with-dependencies.jar

    makeWrapper ${jre}/bin/java $out/bin/${pname} \
      --add-flags "-jar $out/share/${pname}/${pname}-with-dependencies.jar"
  '';

  meta = with lib; {
    description = "This bot allows the creation of join links to non-public rooms in matrix.";
    homepage = "https://fuchss.org/projects/matrix/joinlink/";
    license = licenses.gpl3;
    mainProgram = pname;
  };
}

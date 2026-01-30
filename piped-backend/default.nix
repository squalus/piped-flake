{ src, stdenv, lib, gradle, runtimeShell, jdk
, extraPatches ? []
}:

let
   
  pname = "piped-backend";

  inherit src;

  jar = let self = stdenv.mkDerivation {

    name = "${pname}-jar";

    inherit src;

    nativeBuildInputs = [ gradle ];

    patches = [
      ./0001-run-matrix-loop-conditionally.patch
      ./extractor-version.patch
    ] ++ extraPatches;

    mitmCache = gradle.fetchDeps {
      pkg = self;
      data = ./deps.json;
    };
    gradleBuildTask = "shadowJar";

    postInstall = ''
      mv build/libs/piped-1.0-all.jar $out
    '';
  }; in self;

in

stdenv.mkDerivation {

  name = pname;

  dontBuild = true;

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    echo "#!${runtimeShell}" >> $out/bin/piped-backend
    echo "${jdk}/bin/java -server --enable-preview -jar ${jar}" >> $out/bin/piped-backend
    chmod u+x $out/bin/piped-backend
  '';

  passthru = {
    inherit jar;
  };

  meta = {
    homepage = "https://github.com/TeamPiped/piped-backend";
    license = lib.licenses.agpl3Only;
    sourceProvenance = with lib.sourceTypes; [ fromSource binaryBytecode ];
  };

}

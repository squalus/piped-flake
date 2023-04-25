{ src, stdenv, fetchFromGitHub, lib, gradle, perl, runtimeShell, jdk19_headless, nixosTest }:

let
   
  pname = "piped-backend";

  inherit src;

  # Adds a gradle step that downloads all the dependencies to the gradle cache.
  addResolveStep = ''
    cat >>build.gradle <<HERE
task resolveDependencies {
  doLast {
    project.rootProject.allprojects.each { subProject ->
      subProject.buildscript.configurations.each { configuration ->
        resolveConfiguration(subProject, configuration, "buildscript config \''${configuration.name}")
      }
      subProject.configurations.each { configuration ->
        resolveConfiguration(subProject, configuration, "config \''${configuration.name}")
      }
    }
  }
}
void resolveConfiguration(subProject, configuration, name) {
  if (configuration.canBeResolved) {
    logger.info("Resolving project {} {}", subProject.name, name)
    configuration.resolve()
  }
}
HERE
  '';

  depsHash = builtins.fromJSON (builtins.readFile ./deps-hash.json);

  deps = stdenv.mkDerivation {
    name = "${pname}-deps";
    inherit src;

    postPatch = addResolveStep;

    nativeBuildInputs = [ gradle perl ];
    buildPhase = ''
      export HOME="$NIX_BUILD_TOP/home"
      mkdir -p "$HOME"
      export JAVA_TOOL_OPTIONS="-Duser.home='$HOME'"
      export GRADLE_USER_HOME="$HOME/.gradle"

      # Then, fetch the maven dependencies.
      gradle --no-daemon --info resolveDependencies
    '';
    # perl code mavenizes pathes (com.squareup.okio/okio/1.13.0/a9283170b7305c8d92d25aff02a6ab7e45d06cbe/okio-1.13.0.jar -> com/squareup/okio/okio/1.13.0/okio-1.13.0.jar)
    installPhase = ''
      find $GRADLE_USER_HOME/caches/modules-2 -type f -regex '.*\.\(jar\|pom\)' \
        | perl -pe 's#(.*/([^/]+)/([^/]+)/([^/]+)/[0-9a-f]{30,40}/([^/\s]+))$# ($x = $2) =~ tr|\.|/|; "install -Dm444 $1 \$out/maven/$x/$3/$4/$5" #e' \
        | sh
    '';
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = depsHash;
  };

  jar = stdenv.mkDerivation {

    name = "${pname}-jar";

    inherit src;

    nativeBuildInputs = [ gradle ];

    patches = [ ./0001-run-matrix-loop-conditionally.patch ];

    postPatch = ''
      localRepo="maven { url uri('${deps}/maven') }"
      sed -i settings.gradle -e "1i \
        pluginManagement { repositories { $localRepo } }"
      substituteInPlace build.gradle \
        --replace 'mavenCentral()' "$localRepo"
      sed -i '/jitpack/d' build.gradle
    '';

    buildPhase = ''
      export GRADLE_USER_HOME=$(mktemp -d)
      gradle \
        --offline \
        --no-daemon \
        shadowJar
    '';

    installPhase = ''
      mv build/libs/piped-1.0-all.jar $out
    '';
  };

in

stdenv.mkDerivation {

  name = pname;

  dontBuild = true;

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    echo "#!${runtimeShell}" >> $out/bin/piped-backend
    echo "${jdk19_headless}/bin/java -server --enable-preview -jar ${jar}" >> $out/bin/piped-backend
    chmod u+x $out/bin/piped-backend
  '';

  passthru = {
    inherit deps jar;
    depsUpdate = deps.overrideAttrs (_: { outputHash = lib.fakeHash; });
  };

  meta = {
    homepage = "https://github.com/TeamPiped/piped-backend";
    license = lib.licenses.agpl3Only;
    sourceProvenance = with lib.sourceTypes; [ fromSource binaryBytecode ];
  };

}

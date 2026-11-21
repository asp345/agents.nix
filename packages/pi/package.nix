{
  lib,
  buildNpmPackage,
  autoPatchelfHook,
  makeWrapper,
  nodejs,
  libxcb,
  fd,
  ripgrep,
}:

let
  sources = lib.importJSON ./sources.json;
in
buildNpmPackage {
  pname = "pi";
  inherit (sources) version npmDepsHash;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./package-lock.json
    ];
  };

  inherit nodejs;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [ libxcb ];

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pi $out/bin
    cp -r node_modules $out/lib/pi/
    makeWrapper ${lib.getExe nodejs} $out/bin/pi \
      --add-flags $out/lib/pi/node_modules/@earendil-works/pi-coding-agent/dist/bundle/cli.js \
      --prefix PATH : ${
        lib.makeBinPath [
          fd
          ripgrep
        ]
      } \
      --set-default GIT_EDITOR true \
      --set PI_SKIP_VERSION_CHECK 1 \
      --set PI_TELEMETRY 0

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$($out/bin/pi --version)" = "${sources.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Pi coding agent";
    homepage = "https://pi.dev";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

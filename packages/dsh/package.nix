{
  lib,
  stdenv,
  buildNpmPackage,
  autoPatchelfHook,
  makeWrapper,
  nodejs,
  pnpm_11,
  git,
}:

let
  sources = lib.importJSON ./sources.json;
in
buildNpmPackage {
  pname = "dsh";
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

  buildInputs = [ stdenv.cc.cc.lib ];

  autoPatchelfIgnoreMissingDeps = [
    "libc.musl-x86_64.so.1"
    "libc.musl-aarch64.so.1"
  ];

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/dsh $out/bin
    cp -r node_modules $out/lib/dsh/
    makeWrapper ${lib.getExe nodejs} $out/bin/dsh \
      --add-flags $out/lib/dsh/node_modules/@deepseek-ai/dsh/lib/bin.js \
      --prefix PATH : ${
        lib.makeBinPath [
          pnpm_11
          git
        ]
      } \
      --run 'export DSH_HOME="''${DSH_HOME:-''${XDG_CONFIG_HOME:-$HOME/.config}/dsh}"' \
      --set DSH_TELEMETRY_DISABLED 1

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    HOME=$TMPDIR $out/bin/dsh --version
    runHook postInstallCheck
  '';

  meta = {
    description = "DeepSeek Harness";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    mainProgram = "dsh";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

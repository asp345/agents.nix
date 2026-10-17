{
  lib,
  stdenv,
  buildNpmPackage,
  autoPatchelfHook,
  makeWrapper,
  nodejs,
  pnpm,
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
    # node-addon-require-builtin decodes the machine code of node::PrincipalRealm::builtin_module_require,
    # which fails on nixpkgs Node (zerocallusedregs hardening). Load the internals through --expose-internals.
    # dsh-hmr only takes internalBinding from internal/bootstrap/realm, which --expose-internals does not expose;
    # internal/test/binding returns the same internalBinding("modules") object.
    substituteInPlace \
      $out/lib/dsh/node_modules/@deepseek-ai/dsh-app-boot/lib/index.js \
      $out/lib/dsh/node_modules/@deepseek-ai/dsh-app-boot/lib/worker/profile-resolution-bootstrap.js \
      --replace-fail 'createRequire(import.meta.url)("node-addon-require-builtin")' \
      '{ requireBuiltin: createRequire(import.meta.url) }'
    substituteInPlace $out/lib/dsh/node_modules/@deepseek-ai/dsh-hmr/lib/index.js \
      --replace-fail 'requireInternal("internal/bootstrap/realm")' \
      'requireInternal("internal/test/binding")'
    makeWrapper ${lib.getExe nodejs} $out/bin/dsh \
      --add-flags --expose-internals \
      --add-flags --disable-warning=internal/test/binding \
      --add-flags $out/lib/dsh/node_modules/@deepseek-ai/dsh/lib/bin.js \
      --prefix PATH : ${
        lib.makeBinPath [
          pnpm
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

{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  bubblewrap,
  ripgrep,
}:

let
  sources = lib.importJSON ./sources.json;
  target =
    {
      x86_64-linux = "x86_64-unknown-linux-musl";
      aarch64-linux = "aarch64-unknown-linux-musl";
    }
    .${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "codex";
  inherit (sources) version;

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${sources.version}/codex-${target}.tar.gz";
    hash = sources.hashes.${target};
  };

  sourceRoot = ".";

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 codex-${target} $out/libexec/codex
    makeWrapper $out/libexec/codex $out/bin/codex \
      --prefix PATH : ${
        lib.makeBinPath [
          bubblewrap
          ripgrep
        ]
      }
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME=$TMPDIR
    test "$($out/bin/codex --version)" = "codex-cli ${sources.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "OpenAI Codex CLI";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

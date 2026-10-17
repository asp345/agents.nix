{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  bubblewrap,
  socat,
}:

let
  sources = lib.importJSON ./sources.json;
  platform =
    {
      x86_64-linux = "linux-x64";
      aarch64-linux = "linux-arm64";
    }
    .${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit (sources) version;

  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${sources.version}/${platform}/claude";
    hash = sources.hashes.${platform};
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/libexec/claude
    makeWrapper $out/libexec/claude $out/bin/claude \
      --prefix PATH : ${
        lib.makeBinPath [
          bubblewrap
          socat
        ]
      } \
      --run 'export CLAUDE_CONFIG_DIR="''${CLAUDE_CONFIG_DIR:-''${XDG_CONFIG_HOME:-$HOME/.config}/claude}"' \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    HOME=$TMPDIR $out/bin/claude --version | grep -F "${sources.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Claude Code";
    homepage = "https://claude.com/product/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

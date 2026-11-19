{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
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
  pname = "antigravity-cli";
  inherit (sources) version;

  src = fetchurl {
    url = sources.urls.${platform};
    hash = sources.hashes.${platform};
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 antigravity $out/libexec/antigravity
    makeWrapper $out/libexec/antigravity $out/bin/agy \
      --set AGY_CLI_DISABLE_AUTO_UPDATE true
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    HOME=$TMPDIR $out/bin/agy --version | grep -F "${sources.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Antigravity CLI";
    homepage = "https://antigravity.google/docs/cli/reference";
    license = lib.licenses.unfree;
    mainProgram = "agy";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

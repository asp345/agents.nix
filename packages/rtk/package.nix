{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  libgcc,
}:

let
  sources = lib.importJSON ./sources.json;
  target =
    {
      x86_64-linux = "x86_64-unknown-linux-musl";
      aarch64-linux = "aarch64-unknown-linux-gnu";
    }
    .${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "rtk";
  inherit (sources) version;

  src = fetchurl {
    url = "https://github.com/rtk-ai/rtk/releases/download/v${sources.version}/rtk-${target}.tar.gz";
    hash = sources.hashes.${target};
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isAarch64 [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isAarch64 [ libgcc ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 rtk -t $out/bin
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME=$TMPDIR
    test "$($out/bin/rtk --version)" = "rtk ${sources.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "CLI proxy that reduces LLM token consumption on common dev commands";
    homepage = "https://github.com/rtk-ai/rtk";
    license = with lib.licenses; [
      asl20
      bsl11
    ];
    mainProgram = "rtk";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

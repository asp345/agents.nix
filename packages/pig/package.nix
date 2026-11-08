{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  fd,
  ripgrep,
}:

let
  sources = lib.importJSON ./sources.json;
  platform =
    {
      x86_64-linux = "linux-amd64";
      aarch64-linux = "linux-arm64";
    }
    .${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "pig";
  inherit (sources) version;

  src = fetchurl {
    url = "https://github.com/MichaelKinsy/PiG/releases/download/v${sources.version}/pig-${sources.version}-${platform}.tar.gz";
    hash = sources.hashes.${platform};
  };

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 pig -t $out/libexec/pig
    install -Dm644 -t $out/share/licenses/pig LICENSE NOTICE THIRD_PARTY_NOTICES.md
    cp -r LICENSES $out/share/licenses/pig/LICENSES
    makeWrapper $out/libexec/pig/pig $out/bin/pig \
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
    export HOME=$TMPDIR
    [[ "$($out/bin/pig --version)" == "${sources.version}+"* ]]
    runHook postInstallCheck
  '';

  meta = {
    description = "Go implementation of the Pi coding agent";
    homepage = "https://pi-in-go.dev";
    license = with lib.licenses; [
      mit
      asl20
      bsd3
      blueOak100
      cc-by-40
      isc
      unicode-30
    ];
    mainProgram = "pig";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

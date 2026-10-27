{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  libgcc,
  libx11,
  libxi,
  libxkbcommon,
}:

let
  sources = lib.importJSON ./sources.json;
  platform =
    {
      x86_64-linux = "linux-x86_64";
      aarch64-linux = "linux-arm64";
    }
    .${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "cua-driver";
  inherit (sources) version;

  src = fetchurl {
    url = "https://github.com/trycua/cua/releases/download/cua-driver-rs-v${sources.version}/cua-driver-rs-${sources.version}-${platform}-binary.tar.gz";
    hash = sources.hashes.${platform};
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    libgcc
    libx11
    libxi
    libxkbcommon
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 cua-driver cua-cursor-theme -t $out/bin
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME=$TMPDIR
    $out/bin/cua-driver --version | grep -qx "cua-driver ${sources.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Background computer-use driver for AI agents";
    homepage = "https://github.com/trycua/cua";
    license = lib.licenses.mit;
    mainProgram = "cua-driver";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

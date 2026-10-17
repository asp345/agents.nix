{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  coreutils,
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
  pname = "omp";
  inherit (sources) version;

  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${sources.version}/omp-${platform}";
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
    install -Dm755 $src $out/libexec/omp
    makeWrapper $out/libexec/omp $out/bin/omp \
      --set-default GIT_EDITOR true \
      --run 'export PI_CONFIG_DIR="''${PI_CONFIG_DIR:-$(${coreutils}/bin/realpath -m --relative-to="$HOME" "''${XDG_CONFIG_HOME:-$HOME/.config}/omp")}"' \
      --run 'export PI_NATIVES_DIR="''${PI_NATIVES_DIR:-$HOME/$PI_CONFIG_DIR/natives}"'
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$($out/bin/omp --version)" = "omp/${sources.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Oh My Pi coding agent";
    homepage = "https://github.com/can1357/oh-my-pi";
    license = lib.licenses.mit;
    mainProgram = "omp";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

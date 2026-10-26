{
  lib,
  stdenv,
  fetchurl,
}:

let
  sources = lib.importJSON ./sources.json;
  asset =
    {
      x86_64-linux = "linux-amd64";
      aarch64-linux = "linux-arm64";
    }
    .${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "magpie";
  inherit (sources) version;

  src = fetchurl {
    url = "https://github.com/yetone/magpie/releases/download/v${sources.version}/magpie-cli-${asset}";
    hash = sources.hashes.${asset};
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/magpie
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME=$TMPDIR
    test "$($out/bin/magpie --version)" = "magpie ${sources.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "One place to pick every coding agent's model";
    homepage = "https://github.com/yetone/magpie";
    license = lib.licenses.mit;
    mainProgram = "magpie";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

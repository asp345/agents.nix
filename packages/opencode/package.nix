{
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  makeWrapper,
  patchelf,
  ripgrep,
  wayland,
  libxcb,
}:

let
  sources = lib.importJSON ./sources.json;
  platform =
    {
      x86_64-linux = "linux-x64";
      aarch64-linux = "linux-arm64";
    }
    .${stdenv.hostPlatform.system};
  patchelf' = patchelf.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (fetchpatch {
        url = "https://github.com/NixOS/patchelf/commit/52fd21df79d6631799db20b17c2d23121e1eb176.patch";
        includes = [ "src/patchelf.cc" ];
        hash = "sha256-4Z7TyktsTkl1eDNS9JUErpBMaVZsJ+kvEDNAa6AVZ5Y=";
      })
    ];
  });
in
stdenv.mkDerivation {
  pname = "opencode";
  inherit (sources) version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@opencode/cli-${platform}/-/cli-${platform}-${sources.version}.tgz";
    hash = sources.hashes.${platform};
  };

  sourceRoot = "package";

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/opencode $out/libexec/opencode
    ${lib.getExe patchelf'} \
      --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
      --force-rpath --set-rpath ${
        lib.makeLibraryPath [
          stdenv.cc.cc.lib
          wayland
          libxcb
        ]
      } \
      $out/libexec/opencode
    makeWrapper $out/libexec/opencode $out/bin/opencode \
      --prefix PATH : ${lib.makeBinPath [ ripgrep ]} \
      --set OPENCODE_DISABLE_AUTOUPDATE 1
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    HOME=$TMPDIR $out/bin/opencode --version | grep -F "${sources.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "OpenCode";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
    mainProgram = "opencode";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

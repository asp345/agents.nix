{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libgcc,
  ripgrep,
}:

let
  sources = lib.importJSON ./sources.json;
in
stdenv.mkDerivation {
  pname = "octet";
  inherit (sources) version;

  src = fetchurl {
    url = "https://github.com/skaft-software/octet/releases/download/v${sources.version}/octet-${sources.version}-x86_64-unknown-linux-gnu.tar.gz";
    inherit (sources) hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [ libgcc ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 octet octet-host -t $out/bin
    rm octet octet-host
    mkdir -p $out/share
    cp -r . $out/share/octet
    echo ${sources.version} > $out/share/octet/.octet-version
    wrapProgram $out/bin/octet --prefix PATH : ${lib.makeBinPath [ ripgrep ]}

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME=$TMPDIR
    test "$($out/bin/octet --version)" = "octet ${sources.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Rust coding agent with any-language extensions";
    homepage = "https://skaft.org/octet";
    license = lib.licenses.mit;
    mainProgram = "octet";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

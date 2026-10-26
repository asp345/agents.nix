{
  description = "Coding agent harnesses packaged from upstream releases";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      callPackages = pkgs: {
        pi = pkgs.callPackage ./packages/pi/package.nix { };
        omp = pkgs.callPackage ./packages/omp/package.nix { };
        dsh = pkgs.callPackage ./packages/dsh/package.nix { };
        claude-code = pkgs.callPackage ./packages/claude-code/package.nix { };
        opencode = pkgs.callPackage ./packages/opencode/package.nix { };
        magpie = pkgs.callPackage ./packages/magpie/package.nix { };
        codex = pkgs.callPackage ./packages/codex/package.nix { };
      };
    in
    {
      packages = forAllSystems (
        system:
        callPackages (
          import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg: lib.getName pkg == "claude-code";
          }
        )
      );

      overlays.default = final: _prev: callPackages final;
    };
}

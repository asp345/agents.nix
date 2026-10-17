{
  description = "Coding agent harnesses packaged from upstream releases";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      callPackages = pkgs: {
        pi = pkgs.callPackage ./packages/pi/package.nix { };
        omp = pkgs.callPackage ./packages/omp/package.nix { };
        dsh = pkgs.callPackage ./packages/dsh/package.nix { };
      };
    in
    {
      packages = forAllSystems (system: callPackages nixpkgs.legacyPackages.${system});

      overlays.default = final: _prev: callPackages final;
    };
}

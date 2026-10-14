{
  description = "Pi coding agent binary from upstream releases";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      packages = forAllSystems (system: {
        pi = nixpkgs.legacyPackages.${system}.callPackage ./package.nix { };
        default = self.packages.${system}.pi;
      });

      overlays.default = final: _prev: {
        pi = final.callPackage ./package.nix { };
      };
    };
}
